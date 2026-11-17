class_name GameState
extends RefCounted
## État complet et sérialisable d'une partie. Aucune dépendance à l'interface.
## Toutes les collections sont des Dictionary/Array JSON-compatibles, pour la
## sauvegarde, le rejeu déterministe et l'évolution multijoueur.

const FORMAT := "gs1914.state"
const FORMAT_VERSION := 4  # 2 : échelons et pertes (phase 2) ; 3 : Territorial Force (phase 4) ; 4 : pertes ventilées (phase 6, étape 1)

var scenario_id: String = ""
var year: int = 1914
var month: int = 1
var start_year: int = 1914
var start_month: int = 1
var turn: int = 0
var seed_value: int = 0
var player_nation: String = ""
var nations: Dictionary = {}       # id -> Dictionary (scénario + champs dynamiques)
var nation_order: Array = []       # ordre stable des nations
var regions: Dictionary = {}       # id -> {"sovereign", "controller", "economy"}
var formations: Dictionary = {}    # id -> Dictionary
var treaties: Array = []           # {"id","type","members","status",...}
var proposals: Array = []          # propositions diplomatiques en attente
var wars: Array = []               # {"id","a","b","since_turn"} (a déclare la guerre à b)
var messages: Array = []           # {"turn","channel","from","to","text"}
var memory: Dictionary = {}        # nation -> Array[{turn, about, kind, detail}]
var battles: Array = []            # historique des batailles
var events: Array = []             # journal {"turn","date","category","text","nations"}
var orders_history: Array = []     # {"turn","date","orders"}
var pending_orders: Dictionary = {}  # nation -> Array[Dictionary]
var next_id: int = 1
var active_battles: Array = []     # batailles tactiques en cours (sauvegardées ; bloquent le tour suivant)
var human_nations: Array = []      # pays commandés par des humains (solo : le joueur)
var defense_orders: Array = []     # constructions défensives stratégiques en cours

# Index hiérarchique en mémoire (non sérialisé) : évite le recalcul quadratique de descendants().
var _hierarchy_dirty: bool = true
var _indexed_size: int = -1
var _sorted_ids: Array = []
var _top_level_ids: Array = []
var _children_of: Dictionary = {}        # fid -> Array[String] (enfants directs triés)
var _descendants_cache: Dictionary = {}  # fid -> Array[String] (tous les descendants triés)
var _units_cache: Dictionary = {}        # fid -> Array[String] (descendants d'échelon "unit" triés)


static func from_scenario(scenario: Dictionary, start_month_value: int, player: String, seed_in: int) -> GameState:
	var s := GameState.new()
	s.scenario_id = scenario["id"]
	s.start_year = int(scenario["start"]["year"])
	s.start_month = start_month_value
	s.year = s.start_year
	s.month = start_month_value
	s.seed_value = seed_in
	s.player_nation = player
	s.nation_order = (scenario["nation_order"] as Array).duplicate()
	s.nations = (scenario["nations"] as Dictionary).duplicate(true)
	for nid: String in s.nation_order:
		var n: Dictionary = s.nations[nid]
		n["industry_allocation"] = {}  # priorités gouvernementales (catégories validées), vides au départ
		n["research"] = {"projects": [], "status": "OUVERT : arbre technologique non défini"}
		s.memory[nid] = []
	s.regions = (scenario["regions"] as Dictionary).duplicate(true)
	s.human_nations = [player]
	for f: Dictionary in scenario["formations"]:
		var copy: Dictionary = f.duplicate(true)
		copy["supplied"] = true
		copy["planned_target"] = ""
		copy["battle_id"] = ""
		copy["encircled"] = false
		copy["reserve"] = false
		if copy["echelon"] == "army" and copy.get("morale") == null:
			copy["morale"] = null  # moral d'armée : fixé à la première bataille (valeur de règle provisoire)
		s.formations[copy["id"]] = copy
	for t: Dictionary in scenario["treaties"]:
		s.treaties.append(t.duplicate(true))
	s.wars = (scenario["wars"] as Array).duplicate(true)
	return s


func new_id(prefix: String) -> String:
	var value := "%s_%d" % [prefix, next_id]
	next_id += 1
	return value


func date_label() -> String:
	return GameCalendar.label(year, month)


func log_event(category: String, text: String, involved: Array = []) -> void:
	events.append({"turn": turn, "date": date_label(), "category": category, "text": text, "nations": involved})


func remember(nation: String, about: String, kind: String, detail: String) -> void:
	if memory.has(nation):
		(memory[nation] as Array).append({"turn": turn, "about": about, "kind": kind, "detail": detail})


# ------------------------------------------------------------------ requêtes
func controller(rid: String) -> String:
	return regions[rid]["controller"]


func sovereign(rid: String) -> String:
	return regions[rid]["sovereign"]


func is_occupied(rid: String) -> bool:
	return controller(rid) != sovereign(rid)


func at_war(a: String, b: String) -> bool:
	for w: Dictionary in wars:
		if (w["a"] == a and w["b"] == b) or (w["a"] == b and w["b"] == a):
			return true
	return false


func active_treaties_between(a: String, b: String, kind: String = "") -> Array:
	var out: Array = []
	for t: Dictionary in treaties:
		if t["status"] != "active" or (kind != "" and t["type"] != kind):
			continue
		var members: Array = t["members"]
		if members.has(a) and members.has(b):
			out.append(t)
	return out


## Autorisation de passage : `grantee` peut entrer sur le territoire contrôlé par `grantor`.
func has_transit(grantee: String, grantor: String) -> bool:
	for t: Dictionary in treaties:
		if t["status"] == "active" and t["type"] == "transit" and t.get("grantor", "") == grantor and t.get("grantee", "") == grantee:
			return true
	return false


func formations_in(rid: String) -> Array:
	var out: Array = []
	for fid: String in sorted_formation_ids():
		if formations[fid]["region"] == rid:
			out.append(formations[fid])
	return out


func formations_of(nation: String) -> Array:
	var out: Array = []
	for fid: String in sorted_formation_ids():
		if formations[fid]["nation"] == nation:
			out.append(formations[fid])
	return out


func sorted_formation_ids() -> Array:
	_ensure_hierarchy()
	return _sorted_ids.duplicate()


## Ajoute une nouvelle formation à l'état en mettant à jour l'index hiérarchique incrémentalement.
func register_formation(f: Dictionary) -> void:
	var id: String = f["id"]
	var existed := formations.has(id)
	formations[id] = f
	if existed or _hierarchy_dirty or formations.size() != _indexed_size + 1:
		_hierarchy_dirty = true
		return
	_sorted_ids.insert(_sorted_ids.bsearch(id), id)
	_indexed_size += 1
	var direct_parent: Variant = f.get("parent")
	_children_of[id] = []
	_descendants_cache[id] = []
	_units_cache[id] = []
	if direct_parent == null or not formations.has(direct_parent):
		_top_level_ids.insert(_top_level_ids.bsearch(id), id)
		return
	var ch: Array = _children_of[direct_parent]
	ch.insert(ch.bsearch(id), id)
	var is_unit: bool = f.get("echelon", "") == "unit"
	var visited: Dictionary = {}
	var p: Variant = direct_parent
	while p != null and formations.has(p) and not visited.has(p):
		visited[p] = true
		var dc: Array = _descendants_cache[p]
		dc.insert(dc.bsearch(id), id)
		if is_unit:
			var uc: Array = _units_cache[p]
			uc.insert(uc.bsearch(id), id)
		p = formations[p].get("parent")


## Invalide l'index hiérarchique en mémoire (appelé lors des ajouts, suppressions ou changements de parent).
func invalidate_hierarchy() -> void:
	_hierarchy_dirty = true


## Modifie le parent d'une formation et invalide l'index hiérarchique.
func set_formation_parent(fid: String, parent_id: Variant) -> void:
	if formations.has(fid):
		formations[fid]["parent"] = parent_id
		_hierarchy_dirty = true


func _ensure_hierarchy(_check_fid: String = "") -> void:
	# Détection O(1) des ajouts/suppressions directs. Les changements de parent ou
	# d'échelon hors API exigent un invalidate_hierarchy() explicite du appelant :
	# une validation O(n) à chaque lecture détruirait le bénéfice du cache (banc
	# phase 1 : descendants ×10 0,8 ms → 35 ms, view_for ×10 115 ms → 941 ms).
	if _hierarchy_dirty or formations.size() != _indexed_size:
		_rebuild_hierarchy()


func _rebuild_hierarchy() -> void:
	_sorted_ids = formations.keys()
	_sorted_ids.sort()
	_indexed_size = _sorted_ids.size()
	_top_level_ids.clear()
	_children_of.clear()
	_descendants_cache.clear()
	_units_cache.clear()
	for id: String in _sorted_ids:
		var f: Dictionary = formations[id]
		var direct_parent: Variant = f.get("parent")
		if direct_parent == null or not formations.has(direct_parent):
			_top_level_ids.append(id)
		_children_of[id] = []
		_descendants_cache[id] = []
		_units_cache[id] = []
	for id: String in _sorted_ids:
		var direct_parent: Variant = formations[id].get("parent")
		if direct_parent != null and formations.has(direct_parent):
			(_children_of[direct_parent] as Array).append(id)
		var is_unit: bool = formations[id].get("echelon", "") == "unit"
		var visited: Dictionary = {}
		var p: Variant = direct_parent
		while p != null and formations.has(p) and not visited.has(p):
			visited[p] = true
			(_descendants_cache[p] as Array).append(id)
			if is_unit:
				(_units_cache[p] as Array).append(id)
			p = formations[p].get("parent")
	_hierarchy_dirty = false


# ------------------------------------------------------------------ hiérarchie militaire
## Hiérarchie VALIDÉE : soldats et équipements → unités → régiments → divisions → armées.
func is_top_level(f: Dictionary) -> bool:
	return f.get("parent") == null or not formations.has(f.get("parent"))


func top_level_formation_ids() -> Array:
	_ensure_hierarchy()
	return _top_level_ids.duplicate()


func armies_in(rid: String) -> Array:
	_ensure_hierarchy()
	var out: Array = []
	for fid: String in _top_level_ids:
		if formations.has(fid) and formations[fid]["region"] == rid:
			out.append(formations[fid])
	return out


func army_of(fid: String) -> String:
	var current := fid
	while formations.has(current) and not is_top_level(formations[current]):
		current = formations[current]["parent"]
	return current


func descendants(fid: String) -> Array:
	if not formations.has(fid):
		return []
	_ensure_hierarchy(fid)
	return (_descendants_cache.get(fid, []) as Array).duplicate()


## Unités combattantes (échelon « unit ») d'une armée ou d'une formation.
func units_of(army_id: String) -> Array:
	if not formations.has(army_id):
		return []
	_ensure_hierarchy(army_id)
	return (_units_cache.get(army_id, []) as Array).duplicate()


## Effectif d'une formation : somme des unités ; sans unité, effectif déclaré de la formation
## (null si inconnu : États hors MIL-01).
func soldiers_of(fid: String) -> Variant:
	var f: Dictionary = formations[fid]
	if f["echelon"] == "unit":
		return f.get("soldiers")
	_ensure_hierarchy(fid)
	var units: Array = _units_cache.get(fid, [])
	if units.is_empty():
		return f.get("soldiers")
	var total := 0
	for uid: String in units:
		if formations[uid].get("soldiers") == null:
			return null
		total += int(formations[uid]["soldiers"])
	return total


func is_engaged(army_id: String) -> bool:
	if formations[army_id].get("battle_id", "") != "":
		return true
	_ensure_hierarchy(army_id)
	for uid: String in _descendants_cache.get(army_id, []):
		if formations[uid].get("battle_id", "") != "":
			return true
	return false


## Déplace une armée et toutes ses formations subordonnées (même région).
func move_army(army_id: String, rid: String) -> void:
	formations[army_id]["region"] = rid
	_ensure_hierarchy(army_id)
	for uid: String in _descendants_cache.get(army_id, []):
		formations[uid]["region"] = rid


## Retire une formation détruite ou capturée (et ses subordonnées) ; vide l'armée si nécessaire.
func remove_formation(fid: String) -> void:
	for child: String in descendants(fid):
		formations.erase(child)
	formations.erase(fid)
	_hierarchy_dirty = true


func regions_controlled_by(nation: String) -> Array:
	var out: Array = []
	var ids := regions.keys()
	ids.sort()
	for rid: String in ids:
		if regions[rid]["controller"] == nation:
			out.append(rid)
	return out


# ------------------------------------------------------------------ sérialisation
func to_dict() -> Dictionary:
	return {
		"format": FORMAT, "format_version": FORMAT_VERSION, "scenario_id": scenario_id,
		"year": year, "month": month, "start_year": start_year, "start_month": start_month,
		"turn": turn, "seed": seed_value, "player_nation": player_nation,
		"nation_order": nation_order, "nations": nations, "regions": regions, "formations": formations,
		"treaties": treaties, "proposals": proposals, "wars": wars, "messages": messages,
		"memory": memory, "battles": battles, "events": events, "orders_history": orders_history,
		"pending_orders": pending_orders, "next_id": next_id,
		"active_battles": active_battles, "human_nations": human_nations, "defense_orders": defense_orders,
	}


static func from_dict(d: Dictionary) -> GameState:
	var s := GameState.new()
	s.scenario_id = d["scenario_id"]
	s.year = int(d["year"]); s.month = int(d["month"])
	s.start_year = int(d["start_year"]); s.start_month = int(d["start_month"])
	s.turn = int(d["turn"]); s.seed_value = int(d["seed"]); s.next_id = int(d["next_id"])
	s.player_nation = d["player_nation"]
	s.nation_order = d["nation_order"]
	s.nations = d["nations"]; s.regions = d["regions"]; s.formations = d["formations"]
	s.treaties = d["treaties"]; s.proposals = d["proposals"]; s.wars = d["wars"]
	s.messages = d["messages"]; s.memory = d["memory"]; s.battles = d["battles"]
	s.events = d["events"]; s.orders_history = d["orders_history"]; s.pending_orders = d["pending_orders"]
	s.active_battles = d.get("active_battles", []); s.human_nations = d.get("human_nations", [s.player_nation])
	s.defense_orders = d.get("defense_orders", [])
	_normalize_numbers(s)
	return s


## JSON relit les entiers comme des flottants : on rétablit les champs entiers.
static func _normalize_numbers(s: GameState) -> void:
	for coll: Array in [s.events, s.messages, s.battles, s.orders_history]:
		for item: Dictionary in coll:
			if item.has("turn"):
				item["turn"] = int(item["turn"])
	for w: Dictionary in s.wars:
		w["since_turn"] = int(w["since_turn"])
	for p: Dictionary in s.proposals:
		p["turn"] = int(p["turn"])
	for nid: String in s.memory:
		for m: Dictionary in s.memory[nid]:
			m["turn"] = int(m["turn"])
	for fid: String in s.formations:
		var f: Dictionary = s.formations[fid]
		for key: String in ["soldiers", "services_soldiers", "establishment", "war_cap", "lightly_wounded", "lightly_wounded_turn"]:
			if f.get(key) != null:
				f[key] = int(f[key])
	for nid: String in s.nations:
		var fo: Dictionary = s.nations[nid].get("forces", {})
		for key: String in ["active_start", "active_on_map", "active_off_map", "services_active", "reserves_total",
				"reserves_off_map", "reserve_pool_initial", "reserve_pool", "incorporated", "services_mobilized",
				"districts_total", "districts_on_map"]:
			if fo.get(key) != null:
				fo[key] = int(fo[key])
	for b: Dictionary in s.active_battles + s.battles:
		CombatData.normalize_battle(b)
	for rid: String in s.regions:
		var r: Dictionary = s.regions[rid]
		if r.has("recon_reports"):
			for nid: String in r["recon_reports"]:
				var rep: Dictionary = r["recon_reports"][nid]
				for k: String in ["turn", "units_seen", "confirmed_units", "armies_seen", "spotted_estimate", "estimate", "fortification_level"]:
					if rep.has(k) and rep[k] != null:
						rep[k] = int(rep[k])
	ForceLedger.normalize(s)
	MobilizationSystem.normalize(s)


## Forme canonique stable : la relecture JSON transforme les entiers en flottants ; on applique
## donc ce même aller-retour (précision complète) avant de calculer l'empreinte.
func canonical_json() -> String:
	var once := JSON.stringify(to_dict(), "", true, true)
	return JSON.stringify(JSON.parse_string(once), "", true, true)


func checksum() -> String:
	return canonical_json().sha256_text()
