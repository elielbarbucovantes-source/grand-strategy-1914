class_name MobilizationSystem
extends RefCounted
## Mobilisation progressive des réserves (MIL-01 / MIL-02), phase 2 (15/11/2026).
##
## Décisions appliquées : T-047 (catégories), T-049 (rythme selon les capacités, paramètres
## NATIONAUX), T-051 (échelons ; bloc unique MIL01-P1-D1 si aucun échelon n'est documenté),
## T-053 (postures Paix / Préparatoire / Générale et allocation administration / chemins de fer /
## logistique, SANS coût économique : Q1, Q2), T-056 (mobilisation libre, posture et ouverture
## d'échelon PUBLIQUES, volumes confidentiels : Q3), T-056 bis (communications terrestres, alliés
## compris, mer exclue : Q4, Q5), Q8 (pas de nouvelle armée de réserve dans une région en bataille),
## Q10 (délai minimal entre échelons).
##
## Catégories distinctes, jamais confondues :
##   1. actifs au démarrage      : forces.active_start (constante historique) ;
##   2. réservistes non appelés   : Σ forces.echelons[].pool_by_region ;
##   3. en cours de mobilisation  : forces.mobilizing (cohortes en route) ;
##      dont bloqués              : forces.blocked (voie de communication coupée) ;
##   4. incorporés                : forces.incorporated (cumul) ;
##   5. présents dans les unités  : somme des unités et des services, après pertes ;
##   6. pertes et prisonniers     : ForceLedger.
## Invariant des réserves : non appelés + en cours + bloqués + incorporés = réservoir initial (carte).
## Invariant du personnel : présents + pertes + prisonniers perdus = actifs sur la carte + incorporés.
## Paramètres : data/rules/forces_rules.json (statuts dérivé / PROPOSÉ / PROVISOIRE).

const ORDER := "mobilize"
const POSTURES := ["paix", "preparatoire", "generale"]
const MEANS := ["administration", "rail", "logistics"]


static func forces(state: GameState, nation: String) -> Dictionary:
	return state.nations[nation].get("forces", {})


static func is_historical(state: GameState, nation: String) -> bool:
	return forces(state, nation).get("source_type", "") == "historical"


## Paramètre national (Q7) : valeur nationale si elle existe, sinon base commune.
static func param(mr: Dictionary, nation: String, key: String) -> float:
	var np: Dictionary = mr["national_parameters"].get(nation, {})
	if np.has(key):
		return float(np[key]["value"])
	return float(mr["defaults"][key])


# ------------------------------------------------------------------ validation des ordres
static func _base_check(state: GameState, nation: String) -> String:
	if not state.nations.has(nation):
		return "pays inconnu"
	match forces(state, nation).get("source_type", "unknown"):
		"fictitious":
			return "bac à sable FICTIF : aucune réserve n'est modélisée"
		"unknown":
			return "effectifs et réserves inconnus pour ce pays (données insuffisantes, MIL-01)"
	return ""


## `world` et `rules` (bloc forces) ne sont nécessaires que pour l'échelon suivant.
static func validate(state: GameState, order: Dictionary, world: WorldMap = null, mr: Dictionary = {}) -> String:
	var nation: String = order.get("nation", "")
	var base := _base_check(state, nation)
	if base != "":
		return base
	var f := forces(state, nation)
	match order.get("type", ""):
		Orders.MOBILIZE, Orders.SET_MOBILIZATION_POSTURE:
			var posture: String = order.get("posture", "generale")
			if not posture in POSTURES:
				return "posture inconnue (Paix, Préparatoire ou Générale ; posture accélérée reportée, Q1)"
			if posture == f["posture"]:
				return "posture déjà en vigueur"
			return ""
		Orders.SET_MOBILIZATION_ALLOCATION:
			var a: Dictionary = order.get("allocation", {})
			var total := 0
			for k: String in MEANS:
				if not a.has(k) or int(a[k]) < 0:
					return "allocation incomplète ou négative (administration, chemins de fer, logistique)"
				total += int(a[k])
			if a.size() != MEANS.size():
				return "allocation : trois moyens seulement"
			if total != 100:
				return "allocation : la somme doit faire 100 %% (actuellement %d %%)" % total
			return ""
		Orders.CALL_NEXT_ECHELON:
			return _next_echelon_reason(state, world, mr, nation)
	return "ordre de mobilisation inconnu"


static func _last_opened(f: Dictionary) -> int:
	var last := -1
	for i in (f["echelons"] as Array).size():
		if f["echelons"][i]["opened_turn"] != null:
			last = i
	return last


static func _next_echelon_reason(state: GameState, world: WorldMap, mr: Dictionary, nation: String) -> String:
	var f := forces(state, nation)
	if f["posture"] != "generale":
		return "l'échelon suivant exige la posture générale"
	var last := _last_opened(f)
	if last < 0:
		return "aucun échelon ouvert"
	if last + 1 >= (f["echelons"] as Array).size():
		return "aucun échelon suivant documenté" + (" (bloc unique : approximation non documentée, aucun sous-échelon)" if f["echelon_mode"] == "bloc_unique" else "")
	var e: Dictionary = f["echelons"][last]
	if state.turn < int(e["opened_turn"]) + int(mr.get("next_echelon_min_delay_months", 1)):
		return "délai minimal entre échelons non écoulé (paramètre provisoire, Q10)"
	if world != null and _callable_pool(state, world, nation, e) > 0:
		return "l'échelon en cours n'est pas encore entièrement appelé"
	return ""


# ------------------------------------------------------------------ application (résolution du mois)
static func apply_order(state: GameState, world: WorldMap, mr: Dictionary, order: Dictionary) -> void:
	var nation: String = order["nation"]
	var f := forces(state, nation)
	match order["type"]:
		Orders.MOBILIZE, Orders.SET_MOBILIZATION_POSTURE:
			set_posture(state, mr, nation, order.get("posture", "generale"))
		Orders.SET_MOBILIZATION_ALLOCATION:
			var a: Dictionary = {}
			for k: String in MEANS:
				a[k] = int(order["allocation"][k])
			f["allocation"] = a
			state.log_event("mobilisation", "%s : moyens de mobilisation répartis (administration %d %%, chemins de fer %d %%, logistique %d %%)." % [
				state.nations[nation]["name_fr"], a["administration"], a["rail"], a["logistics"]], [nation])
		Orders.CALL_NEXT_ECHELON:
			if _next_echelon_reason(state, world, mr, nation) == "":
				_open_echelon(state, nation, _last_opened(f) + 1)


## Changement de posture : PUBLIC (T-056, Q3). Une baisse arrête les nouveaux appels ; les
## cohortes déjà en route terminent leur transit (ce n'est pas une démobilisation, MIL-02 ouvert).
static func set_posture(state: GameState, mr: Dictionary, nation: String, posture: String) -> void:
	var f := forces(state, nation)
	var before: String = f["posture"]
	f["posture"] = posture
	var label: String = mr["postures"][posture]["label_fr"]
	(f["public_record"] as Array).append({"turn": state.turn, "kind": "posture", "value": posture})
	state.log_event("mobilisation publique", "%s adopte la posture de mobilisation « %s » (auparavant « %s »)." % [
		state.nations[nation]["name_fr"], label, mr["postures"][before]["label_fr"]], state.nation_order.duplicate())
	if float(mr["postures"][posture]["call_factor"]) > 0.0 and _last_opened(f) < 0:
		_open_echelon(state, nation, 0)


static func _open_echelon(state: GameState, nation: String, index: int) -> void:
	var f := forces(state, nation)
	var e: Dictionary = f["echelons"][index]
	e["opened_turn"] = state.turn
	(f["public_record"] as Array).append({"turn": state.turn, "kind": "echelon", "value": e["id"]})
	var note := "" if bool(e["documented"]) else " — approximation non documentée historiquement"
	state.log_event("mobilisation publique", "%s ouvre l'échelon de mobilisation « %s »%s." % [
		state.nations[nation]["name_fr"], e["label_fr"], note], state.nation_order.duplicate())


# ------------------------------------------------------------------ communications (T-056 bis)
## Région d'incorporation des réservistes du district `rid`, ou "" si aucune voie :
## `rid` lui-même s'il est contrôlé par la nation et relié à la capitale ; sinon la première région
## de ce type atteinte par voie terrestre (détroits du graphe compris, mer exclue) en ne traversant
## que des régions de la nation ou de ses alliés (parcours en largeur, ordre trié : déterministe).
static func communication(state: GameState, world: WorldMap, nation: String, rid: String, accessible: Dictionary) -> String:
	if state.controller(rid) == nation and accessible.has(rid):
		return rid
	var seen: Dictionary = {rid: true}
	var queue: Array[String] = [rid]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		var nexts: Array = Array(world.neighbor_ids(current, true))
		nexts.sort()
		for nxt: String in nexts:
			if seen.has(nxt) or not LogisticsSystem.friendly(state, nation, nxt):
				continue
			if state.controller(nxt) == nation and accessible.has(nxt):
				return nxt
			seen[nxt] = true
			queue.append(nxt)
	return ""


## Régions reliées à la capitale par un chemin entièrement ferroviaire (liaisons ATTESTÉES de
## l'atlas : présence seulement, aucune capacité) à travers des régions amies.
static func rail_connected(state: GameState, world: WorldMap, nation: String) -> Dictionary:
	var capital: String = state.nations[nation]["capital_region_id"]
	var reached: Dictionary = {}
	if state.controller(capital) != nation:
		return reached
	reached[capital] = true
	var queue: Array[String] = [capital]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		var nexts: Array = Array(world.neighbor_ids(current, true))
		nexts.sort()
		for nxt: String in nexts:
			if not reached.has(nxt) and world.has_rail_link(current, nxt) and LogisticsSystem.friendly(state, nation, nxt):
				reached[nxt] = true
				queue.append(nxt)
	return reached


static func _callable_pool(state: GameState, world: WorldMap, nation: String, e: Dictionary) -> int:
	var accessible := LogisticsSystem.accessible_regions(state, world, nation)
	var total := 0
	for rid: String in e["pool_by_region"]:
		if int(e["pool_by_region"][rid]) > 0 and communication(state, world, nation, rid, accessible) != "":
			total += int(e["pool_by_region"][rid])
	return total


# ------------------------------------------------------------------ étape mensuelle
## Ordre : cohortes bloquées réexaminées → incorporation des cohortes arrivées → nouvel appel.
static func monthly(state: GameState, world: WorldMap, rules: Dictionary) -> void:
	var mr: Dictionary = rules["mobilization"]
	for nation: String in state.nation_order:
		if not is_historical(state, nation):
			continue
		var f := forces(state, nation)
		var accessible := LogisticsSystem.accessible_regions(state, world, nation)
		_unblock(state, world, mr, nation, accessible)
		_incorporate_ready(state, world, rules, nation, accessible)
		_call_up(state, world, mr, nation, accessible)
		_sync_pool(f)
		TerritorialForce.monthly(state, world, rules, nation, accessible)  # T-050 : catégorie distincte


static func _sync_pool(f: Dictionary) -> void:
	var total := 0
	for e: Dictionary in f["echelons"]:
		for rid: String in e["pool_by_region"]:
			total += int(e["pool_by_region"][rid])
	f["reserve_pool"] = total


static func _admin_factor(mr: Dictionary, f: Dictionary, nation: String) -> float:
	var al: Dictionary = mr["allocation"]
	var share := float(f["allocation"]["administration"]) / float(al["admin_reference_share"])
	return clampf(share, float(al["admin_factor_min"]), float(al["admin_factor_max"])) * param(mr, nation, "administrative_capacity")


## Délai d'une cohorte (mois) : transit national, plus le délai ferroviaire (présence seulement),
## plus le détour d'un district occupé (T-056 bis). Effets de l'allocation : voir forces_rules.json.
static func transit_for(mr: Dictionary, f: Dictionary, nation: String, origin: String, dest: String, rails: Dictionary) -> int:
	var al: Dictionary = mr["allocation"]
	var months := int(param(mr, nation, "transit_months"))
	if int(f["allocation"]["rail"]) < int(al["rail_minimum_share"]):
		months += 1
	elif not rails.has(dest) and int(f["allocation"]["rail"]) < int(al["rail_priority_share"]):
		months += int(param(mr, nation, "rail_gap_months"))
	if dest != origin:
		months += int(param(mr, nation, "detour_months"))
		if int(f["allocation"]["logistics"]) < int(al["logistics_minimum_share"]):
			months += 1
	return maxi(1, months)


static func _call_up(state: GameState, world: WorldMap, mr: Dictionary, nation: String, accessible: Dictionary) -> void:
	var f := forces(state, nation)
	var posture: Dictionary = mr["postures"][f["posture"]]
	var factor := float(posture["call_factor"]) * float(param(mr, nation, "call_share_per_month")) * _admin_factor(mr, f, nation)
	if factor <= 0.0:
		return
	var rails := rail_connected(state, world, nation)
	var called := 0
	var skipped := 0
	for i in (f["echelons"] as Array).size():
		var e: Dictionary = f["echelons"][i]
		if e["opened_turn"] == null or i >= int(posture["max_echelon"]):
			continue
		var regions: Array = (e["pool_by_region"] as Dictionary).keys()
		regions.sort()
		for rid: String in regions:
			var pool := int(e["pool_by_region"][rid])
			if pool <= 0:
				continue
			var dest := communication(state, world, nation, rid, accessible)
			if dest == "":
				skipped += pool  # Q4 : district sans voie de communication, ses réservistes ne sont pas appelés
				continue
			var n := mini(pool, int(ceil(float(e["pool_initial_by_region"][rid]) * factor)))
			e["pool_by_region"][rid] = pool - n
			(f["mobilizing"] as Array).append({"region": rid, "dest": dest, "soldiers": n, "echelon": e["id"],
				"ready_turn": state.turn + transit_for(mr, f, nation, rid, dest, rails)})
			called += n
	if called > 0:
		# Volume CONFIDENTIEL (Q3) : visible du seul pays concerné.
		state.log_event("mobilisation", "%s : %d réservistes rappelés." % [state.nations[nation]["name_fr"], called], [nation])
	if skipped > 0:
		state.log_event("mobilisation", "%s : %d réservistes de districts occupés sans voie de communication ne peuvent pas être appelés." % [
			state.nations[nation]["name_fr"], skipped], [nation])


static func _region_has_battle(state: GameState, rid: String) -> bool:
	for b: Dictionary in state.active_battles:
		if b["region"] == rid:
			return true
	return false


static func _unblock(state: GameState, world: WorldMap, mr: Dictionary, nation: String, accessible: Dictionary) -> void:
	var f := forces(state, nation)
	var still: Array = []
	for c: Dictionary in f["blocked"]:
		var dest := communication(state, world, nation, c["region"], accessible)
		if dest == "":
			still.append(c)
			continue
		var extra := int(param(mr, nation, "detour_months")) if dest != c["region"] else 0
		(f["mobilizing"] as Array).append({"region": c["region"], "dest": dest, "soldiers": int(c["soldiers"]),
			"echelon": c["echelon"], "ready_turn": state.turn + extra})
		state.log_event("mobilisation", "%s : %d réservistes bloqués reprennent leur route vers %s." % [
			state.nations[nation]["name_fr"], int(c["soldiers"]), dest], [nation])
	f["blocked"] = still


static func _incorporate_ready(state: GameState, world: WorldMap, rules: Dictionary, nation: String, accessible: Dictionary) -> void:
	var f := forces(state, nation)
	var keep: Array = []
	var by_dest: Dictionary = {}
	for c: Dictionary in f["mobilizing"]:
		if int(c["ready_turn"]) > state.turn:
			keep.append(c)
			continue
		var dest: String = c["dest"]
		if not (state.controller(dest) == nation and accessible.has(dest)):
			dest = communication(state, world, nation, c["region"], accessible)
		if dest == "":
			(f["blocked"] as Array).append({"region": c["region"], "soldiers": int(c["soldiers"]), "echelon": c["echelon"], "since_turn": state.turn})
			state.log_event("mobilisation", "%s : %d réservistes bloqués (voie de communication coupée depuis %s)." % [
				state.nations[nation]["name_fr"], int(c["soldiers"]), c["region"]], [nation])
			continue
		if _region_has_battle(state, dest):
			c["dest"] = dest
			keep.append(c)  # Q8 : incorporation reportée tant qu'une bataille se déroule dans la région
			continue
		var key := "%s|%s" % [dest, c["region"]]
		if not by_dest.has(key):
			by_dest[key] = {"dest": dest, "origin": c["region"], "soldiers": 0, "echelon": c["echelon"]}
		by_dest[key]["soldiers"] = int(by_dest[key]["soldiers"]) + int(c["soldiers"])
	var keys := by_dest.keys()
	keys.sort()
	var exhausted := int(f["reserve_pool"]) == 0
	for key: String in keys:
		var g: Dictionary = by_dest[key]
		var carry := incorporate(state, rules, nation, g["dest"], int(g["soldiers"]), exhausted and keep.is_empty(), g["dest"] == g["origin"])
		if carry > 0:
			keep.append({"region": g["origin"], "dest": g["dest"], "soldiers": carry, "echelon": g["echelon"], "ready_turn": state.turn})
	f["mobilizing"] = keep


## Répartition entière exacte (plus forts restes, ordre stable).
static func split(total: int, weights: Array) -> Array:
	var s := 0.0
	for w: float in weights:
		s += w
	var out: Array = []
	var fracs: Array = []
	var used := 0
	for i in weights.size():
		var raw := float(total) * float(weights[i]) / s if s > 0.0 else 0.0
		out.append(int(floor(raw)))
		fracs.append([-(raw - floor(raw)), i])
		used += int(floor(raw))
	fracs.sort()
	for k in total - used:
		out[int(fracs[k][1])] += 1
	return out


## Incorpore `soldiers` réservistes dans la région `rid`. Les services reçoivent leur part ; si
## `complete_units`, les unités du district sont d'abord complétées jusqu'à l'effectif de guerre ;
## le reste forme de nouvelles unités de réserve. Retourne le reliquat non incorporé (trop petit
## pour former une unité), qui reste en cours de mobilisation. `flush` : former aussi les petits reliquats.
## `count_incorporated` = false pour des blessés guéris : ils redeviennent présents sans être comptés
## comme de nouveaux soldats incorporés (phase 6, étape 1).
static func incorporate(state: GameState, rules: Dictionary, nation: String, rid: String, soldiers: int, flush: bool = false, complete_units: bool = true, count_incorporated: bool = true) -> int:
	var f := forces(state, nation)
	var gen: Dictionary = rules["unit_generation"]
	var mr: Dictionary = rules["mobilization"]
	var shares: Dictionary = f["arm_shares"]
	var kinds: Array = shares.keys().filter(func(k: String) -> bool: return k != "services" and float(shares[k]) > 0.0)
	kinds.sort()
	var weights: Array = kinds.map(func(k: String) -> float: return float(shares[k]))
	weights.append(float(shares.get("services", 0.0)))
	var parts := split(soldiers, weights)
	var services: int = parts[-1]
	f["services_mobilized"] = int(f.get("services_mobilized", 0)) + services
	var placed := services
	var carry := 0
	for i in kinds.size():
		var kind: String = kinds[i]
		var amount: int = parts[i]
		# 1. Compléter les unités du district (non engagées, armée non encerclée) jusqu'à l'effectif de guerre.
		if complete_units:
			for uid: String in _district_units(state, nation, rid, kind):
				if amount <= 0:
					break
				var u: Dictionary = state.formations[uid]
				var cap := int(u.get("war_cap", int(round(float(u.get("establishment", u["soldiers"])) * float(mr["war_establishment_mult"])))))
				u["war_cap"] = cap
				var add := mini(amount, maxi(0, cap - int(u["soldiers"])))
				u["soldiers"] = int(u["soldiers"]) + add
				amount -= add
				placed += add
		# 2. Nouvelles unités de réserve.
		var size := int(mr["new_unit_soldiers"])
		while amount >= size or (amount > 0 and (amount >= int(gen["min_unit_soldiers"]) or flush)):
			var n := mini(amount, size)
			_new_reserve_unit(state, nation, rid, kind, n)
			amount -= n
			placed += n
		carry += amount
	if count_incorporated:
		f["incorporated"] = int(f["incorporated"]) + placed
		if placed > 0:
			state.log_event("mobilisation", "%s : %d réservistes incorporés (%s)." % [state.nations[nation]["name_fr"], placed, rid], [nation])
	return carry


## Unités d'un type, rattachées à un district de la région, disponibles pour être complétées.
static func _district_units(state: GameState, nation: String, rid: String, kind: String) -> Array:
	var out: Array = []
	for uid: String in state.sorted_formation_ids():
		var u: Dictionary = state.formations[uid]
		if u["echelon"] != "unit" or u["nation"] != nation or u.get("unit_type", "") != kind:
			continue
		if u.get("battle_id", "") != "" or u.get("soldiers") == null:
			continue
		var div: Variant = u.get("parent")
		if div == null or not state.formations.has(div) or state.formations[div].get("district_region", state.formations[div]["region"]) != rid:
			continue
		var army: Dictionary = state.formations[state.army_of(uid)]
		if army.get("encircled", false) or army["region"] != rid:
			continue  # l'unité a quitté son district : ses réservistes forment de nouvelles unités
		out.append(uid)
	return out


static func _reserve_army(state: GameState, nation: String, rid: String) -> String:
	var k := 1
	while true:
		var aid := "army_%s_%s_res%d" % [nation, rid, k]
		if not state.formations.has(aid):
			state.formations[aid] = {"id": aid, "nation": nation, "echelon": "army",
				"name_fr": "Formations de réserve n° %d" % k, "region": rid, "parent": null,
				"soldiers": null, "equipment": null, "morale": null, "supplied": true, "planned_target": "",
				"battle_id": "", "encircled": false, "reserve": false,
				"status": "MOBILISATION : réservistes incorporés (réservoir historique sourcé)"}
			return aid
		var a: Dictionary = state.formations[aid]
		if a["region"] == rid and not state.is_engaged(aid) and not a.get("encircled", false):
			return aid
		k += 1
	return ""


static func _new_reserve_unit(state: GameState, nation: String, rid: String, kind: String, soldiers: int) -> void:
	assert(not _region_has_battle(state, rid), "Q8 : aucune armée de réserve dans une région en bataille")
	var army := _reserve_army(state, nation, rid)
	var uid := state.new_id("%s_res_%s" % [nation, kind.substr(0, 3)])
	var label: String = {"infantry": "Infanterie", "cavalry": "Cavalerie", "artillery": "Artillerie"}.get(kind, kind)
	state.formations[uid] = {"id": uid, "nation": nation, "echelon": "unit", "unit_type": kind,
		"name_fr": "%s de réserve n° %d" % [label, state.next_id - 1],
		"region": rid, "parent": army, "soldiers": soldiers, "establishment": soldiers, "war_cap": soldiers,
		"equipment": null, "morale": null, "supplied": true, "planned_target": "", "battle_id": "",
		"encircled": false, "reserve": false,
		"status": "MOBILISATION : réservistes incorporés (réservoir historique sourcé)"}


# ------------------------------------------------------------------ lecture : catégories et contrôles
static func summary(state: GameState, nation: String) -> Dictionary:
	var f := forces(state, nation)
	var present := 0
	var services := int(f.get("services_mobilized", 0)) + int(f.get("services_regrouped", 0))
	var tf := TerritorialForce.summary(state, nation)
	services += int(tf.get("services", 0))
	# Sommes indépendantes de l'ordre : parcours direct, sans tri (appelé pour chaque vue nationale).
	for x: Dictionary in state.formations.values():
		if x["nation"] != nation:
			continue
		if x["echelon"] == "unit" and x.get("soldiers") != null:
			present += int(x["soldiers"])
		services += int(x.get("services_soldiers", 0))
	var mobilizing := 0
	for c: Dictionary in f.get("mobilizing", []):
		mobilizing += int(c["soldiers"])
	var blocked := 0
	for c: Dictionary in f.get("blocked", []):
		blocked += int(c["soldiers"])
	var echelons: Array = []
	var pool := 0
	for e: Dictionary in f.get("echelons", []):
		var p := 0
		for rid: String in e["pool_by_region"]:
			p += int(e["pool_by_region"][rid])
		pool += p
		echelons.append({"id": e["id"], "label_fr": e["label_fr"], "status": e["status"], "documented": e["documented"],
			"pool": p, "pool_initial": int(e["pool_initial"]), "opened": e["opened_turn"] != null})
	# Lecture seule : le registre n'est créé qu'à la première inscription (aucun effet de bord ici).
	var l: Dictionary = state.nations[nation].get("military_ledger", {}) if state.nations.has(nation) else {}
	return {"source_type": f.get("source_type", "unknown"), "data_status": f.get("data_status", ""),
		"active_start": f.get("active_start"), "active_on_map": f.get("active_on_map"), "active_off_map": f.get("active_off_map"),
		"reserve_pool": pool if f.has("echelons") else f.get("reserve_pool"), "reserve_pool_initial": f.get("reserve_pool_initial"),
		"reserves_off_map": f.get("reserves_off_map"), "echelons": echelons, "echelon_mode": f.get("echelon_mode", ""),
		"echelon_status_fr": f.get("echelon_status_fr", ""),
		"mobilizing": mobilizing, "blocked": blocked, "incorporated": f.get("incorporated"),
		"present_in_units": present, "present_services": services,
		# Phase 6, étape 1 : catégories mutuellement exclusives des hommes hors des rangs.
		"losses_total": ForceLedger.out_of_ranks(l),
		"killed": l.get("killed", 0),
		"wounded": (l.get("wounded", {"remained_in_unit": 0, "convalescing": 0, "long_term": 0, "returned": 0, "unfit": 0}) as Dictionary).duplicate(),
		"missing": l.get("missing_total", 0), "missing_by_cause": (l.get("missing", {}) as Dictionary).duplicate(),
		"legacy_unventilated": l.get("legacy_unventilated", 0),
		"prisoners_lost": l.get("prisoners_lost", 0), "prisoners_held": l.get("prisoners_held", 0),
		"rejoined": l.get("rejoined", 0),
		"released": l.get("released", 0), "repatriated": l.get("repatriated", 0),
		"posture": f.get("posture", "paix"), "allocation": f.get("allocation", {}),
		"public_record": (f.get("public_record", []) as Array).duplicate(true),
		"territorial_force": tf,
		"declared": f.get("posture", "paix") != "paix"}


## Contrôle des deux invariants (tests ; nation historique).
static func conservation(state: GameState, nation: String) -> Dictionary:
	var s := summary(state, nation)
	var reserves_lhs := int(s["reserve_pool"]) + int(s["mobilizing"]) + int(s["blocked"]) + int(s["incorporated"])
	# `losses_total` = tués + convalescence (y compris longue durée) + inaptes + disparus + prisonniers perdus
	# (+ pertes non ventilées héritées) : catégories exclusives (ForceLedger.out_of_ranks).
	var personnel_lhs := int(s["present_in_units"]) + int(s["present_services"]) + int(s["losses_total"])
	var tf: Dictionary = s["territorial_force"]
	# T-050 : la Territorial Force a son propre invariant et entre dans le personnel par ses incorporés.
	var personnel_rhs := int(s["active_on_map"]) + int(s["incorporated"]) + int(tf.get("incorporated", 0))
	var tf_ok := tf.is_empty() or int(tf["pool"]) + int(tf["mobilizing"]) + int(tf["blocked"]) + int(tf["incorporated"]) == int(tf["pool_initial"])
	return {"reserves_ok": reserves_lhs == int(s["reserve_pool_initial"]) and tf_ok, "reserves_lhs": reserves_lhs,
		"reserves_rhs": int(s["reserve_pool_initial"]), "territorial_ok": tf_ok,
		"personnel_ok": personnel_lhs == personnel_rhs, "personnel_lhs": personnel_lhs, "personnel_rhs": personnel_rhs}


## Informations PUBLIQUES (T-056, Q3) : posture et échelons ouverts ; jamais les volumes.
static func public_view(state: GameState, mr: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for nid: String in state.nation_order:
		if not is_historical(state, nid):
			continue
		var f := forces(state, nid)
		var opened: Array = []
		for e: Dictionary in f["echelons"]:
			if e["opened_turn"] != null:
				opened.append({"id": e["id"], "label_fr": e["label_fr"], "documented": e["documented"], "since_turn": int(e["opened_turn"])})
		out[nid] = {"posture": f["posture"], "posture_fr": mr["postures"][f["posture"]]["label_fr"] if not mr.is_empty() else f["posture"],
			"opened_echelons": opened, "record": (f["public_record"] as Array).duplicate(true)}
	return out


static func normalize(state: GameState) -> void:
	for nid: String in state.nations:
		var fo: Dictionary = state.nations[nid].get("forces", {})
		for key: String in ["active_start", "active_on_map", "active_off_map", "services_active", "reserves_total",
				"reserves_off_map", "reserve_pool_initial", "reserve_pool", "incorporated", "services_mobilized", "services_regrouped",
				"districts_total", "districts_on_map"]:
			if fo.get(key) != null:
				fo[key] = int(fo[key])
		for c: Dictionary in fo.get("mobilizing", []) + fo.get("blocked", []):
			c["soldiers"] = int(c["soldiers"])
			for k: String in ["ready_turn", "since_turn"]:
				if c.has(k):
					c[k] = int(c[k])
		for e: Dictionary in fo.get("echelons", []):
			e["pool_initial"] = int(e["pool_initial"])
			for d: String in ["pool_by_region", "pool_initial_by_region"]:
				for rid: String in e[d]:
					e[d][rid] = int(e[d][rid])
			if e["opened_turn"] != null:
				e["opened_turn"] = int(e["opened_turn"])
		for r: Dictionary in fo.get("public_record", []):
			r["turn"] = int(r["turn"])
		if fo.has("allocation"):
			for k: String in fo["allocation"]:
				fo["allocation"][k] = int(fo["allocation"][k])
		TerritorialForce.normalize(fo)
