class_name GameState
extends RefCounted
## État complet et sérialisable d'une partie. Aucune dépendance à l'interface.
## Toutes les collections sont des Dictionary/Array JSON-compatibles, pour la
## sauvegarde, le rejeu déterministe et l'évolution multijoueur.

const FORMAT := "gs1914.state"
const FORMAT_VERSION := 1

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
	for f: Dictionary in scenario["formations"]:
		var copy: Dictionary = f.duplicate(true)
		copy["supplied"] = true
		copy["planned_target"] = ""
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
	var ids := formations.keys()
	ids.sort()
	return ids


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


func canonical_json() -> String:
	return JSON.stringify(to_dict(), "", true)


func checksum() -> String:
	return canonical_json().sha256_text()
