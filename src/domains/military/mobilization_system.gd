class_name MobilizationSystem
extends RefCounted
## Mobilisation progressive des réserves (MIL-01 / MIL-02).
##
## Modèle VALIDÉ (mission du 15/11/2026) : l'armée active est présente au départ ; les réserves
## sont disponibles mais NON incorporées ; la mobilisation les fait rejoindre progressivement.
## Cinq catégories distinctes, jamais confondues :
##   1. actifs au démarrage      : forces.active_start (donnée historique, constante) ;
##   2. réserves disponibles      : forces.reserve_pool (diminue à chaque appel) ;
##   3. en cours de mobilisation  : forces.mobilizing (cohortes appelées, pas encore incorporées) ;
##   4. incorporés                : forces.incorporated (cumul des réservistes versés aux unités) ;
##   5. présents dans les unités  : somme des effectifs des unités (+ services), après pertes.
## Invariant de conservation : reserve_pool + Σ mobilizing + incorporated = reserve_pool_initial.
## Aucun soldat n'est créé sans provenir du réservoir ; un actif n'est jamais compté en réserve.
## Paramètres : data/rules/forces_rules.json (PROPOSÉS, identiques pour toutes les nations).

const ORDER := "mobilize"


static func forces(state: GameState, nation: String) -> Dictionary:
	return state.nations[nation].get("forces", {})


static func is_historical(state: GameState, nation: String) -> bool:
	return forces(state, nation).get("source_type", "") == "historical"


static func validate(state: GameState, order: Dictionary) -> String:
	var nation: String = order.get("nation", "")
	if not state.nations.has(nation):
		return "pays inconnu"
	var f := forces(state, nation)
	match f.get("source_type", "unknown"):
		"fictitious":
			return "bac à sable FICTIF : aucune réserve n'est modélisée"
		"unknown":
			return "effectifs et réserves inconnus pour ce pays (données insuffisantes, MIL-01)"
	if bool(f["mobilization"]["declared"]):
		return "mobilisation générale déjà décrétée"
	return ""


## Décret de mobilisation générale (ordre secret, appliqué à la résolution du mois).
static func declare(state: GameState, nation: String) -> void:
	var f := forces(state, nation)
	f["mobilization"] = {"declared": true, "turn": state.turn}
	state.log_event("mobilisation", "%s décrète la mobilisation générale (%d réservistes disponibles sur la carte)." % [
		state.nations[nation]["name_fr"], int(f["reserve_pool"])], [nation])


## Étape mensuelle : incorporation des cohortes arrivées, puis appel d'une nouvelle tranche.
## L'appel du mois M n'est incorporé qu'au mois M + transit : rien n'apparaît instantanément.
static func monthly(state: GameState, world: WorldMap, rules: Dictionary) -> void:
	var mr: Dictionary = rules["mobilization"]
	for nation: String in state.nation_order:
		if not is_historical(state, nation):
			continue
		var f := forces(state, nation)
		if not bool(f["mobilization"]["declared"]):
			continue
		_incorporate_ready(state, world, rules, nation)
		_call_up(state, mr, nation)


static func _call_up(state: GameState, mr: Dictionary, nation: String) -> void:
	var f := forces(state, nation)
	var pool := int(f["reserve_pool"])
	if pool <= 0:
		return
	var share := float(mr["national_overrides"].get(nation, {}).get("call_share_per_month", mr["call_share_per_month"]))
	var called := mini(pool, int(ceil(float(f["reserve_pool_initial"]) * share)))
	var weights: Dictionary = f["district_pool_weights"]
	var regions := weights.keys()
	regions.sort()
	var parts := split(called, regions.map(func(r: String) -> float: return float(weights[r])))
	var ready := state.turn + int(mr["transit_months"])
	for i in regions.size():
		if parts[i] > 0:
			(f["mobilizing"] as Array).append({"region": regions[i], "soldiers": parts[i], "ready_turn": ready})
	f["reserve_pool"] = pool - called
	state.log_event("mobilisation", "%s : %d réservistes rappelés (incorporation prévue dans %d mois)." % [
		state.nations[nation]["name_fr"], called, int(mr["transit_months"])], [nation])


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


static func _region_ok(state: GameState, world: WorldMap, rules: Dictionary, nation: String, rid: String, accessible: Dictionary) -> bool:
	var mr: Dictionary = rules["mobilization"]
	if bool(mr["requires_controlled_region"]) and state.controller(rid) != nation:
		return false
	if bool(mr["requires_supply_link"]) and not accessible.has(rid):
		return false
	return true


static func _incorporate_ready(state: GameState, world: WorldMap, rules: Dictionary, nation: String) -> void:
	var f := forces(state, nation)
	var accessible := LogisticsSystem.accessible_regions(state, world, nation)
	var keep: Array = []
	var by_region: Dictionary = {}
	for c: Dictionary in f["mobilizing"]:
		if int(c["ready_turn"]) <= state.turn and _region_ok(state, world, rules, nation, c["region"], accessible):
			by_region[c["region"]] = int(by_region.get(c["region"], 0)) + int(c["soldiers"])
		else:
			keep.append(c)  # pas encore arrivés, ou district occupé / coupé : restent en cours de mobilisation
	var regions := by_region.keys()
	regions.sort()
	var exhausted := int(f["reserve_pool"]) == 0
	for rid: String in regions:
		var carry := incorporate(state, rules, nation, rid, int(by_region[rid]), exhausted and keep.is_empty())
		if carry > 0:
			keep.append({"region": rid, "soldiers": carry, "ready_turn": state.turn})
	f["mobilizing"] = keep


## Incorpore `soldiers` réservistes dans la région de district `rid`. Les services reçoivent leur
## part ; les unités du district sont d'abord complétées jusqu'à l'effectif de guerre, puis de
## nouvelles unités de réserve sont formées. Retourne le reliquat non incorporé (trop petit pour
## former une unité), qui reste en cours de mobilisation. `flush` : former aussi les petits reliquats.
static func incorporate(state: GameState, rules: Dictionary, nation: String, rid: String, soldiers: int, flush: bool = false) -> int:
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
				"name_fr": "Formations de réserve %d — %s" % [k, rid], "region": rid, "parent": null,
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
	var army := _reserve_army(state, nation, rid)
	var uid := state.new_id("%s_res_%s" % [nation, kind.substr(0, 3)])
	var label: String = {"infantry": "Infanterie", "cavalry": "Cavalerie", "artillery": "Artillerie"}.get(kind, kind)
	state.formations[uid] = {"id": uid, "nation": nation, "echelon": "unit", "unit_type": kind,
		"name_fr": "%s de réserve n° %d" % [label, state.next_id - 1],
		"region": rid, "parent": army, "soldiers": soldiers, "establishment": soldiers, "war_cap": soldiers,
		"equipment": null, "morale": null, "supplied": true, "planned_target": "", "battle_id": "",
		"encircled": false, "reserve": false,
		"status": "MOBILISATION : réservistes incorporés (réservoir historique sourcé)"}


## Les cinq catégories, pour l'interface et les tests.
static func summary(state: GameState, nation: String) -> Dictionary:
	var f := forces(state, nation)
	var present := 0
	var services := int(f.get("services_mobilized", 0))
	for fid: String in state.sorted_formation_ids():
		var x: Dictionary = state.formations[fid]
		if x["nation"] != nation:
			continue
		if x["echelon"] == "unit" and x.get("soldiers") != null:
			present += int(x["soldiers"])
		services += int(x.get("services_soldiers", 0))
	var mobilizing := 0
	for c: Dictionary in f.get("mobilizing", []):
		mobilizing += int(c["soldiers"])
	return {"source_type": f.get("source_type", "unknown"), "data_status": f.get("data_status", ""),
		"active_start": f.get("active_start"), "active_on_map": f.get("active_on_map"), "active_off_map": f.get("active_off_map"),
		"reserve_pool": f.get("reserve_pool"), "reserve_pool_initial": f.get("reserve_pool_initial"),
		"reserves_off_map": f.get("reserves_off_map"), "mobilizing": mobilizing, "incorporated": f.get("incorporated"),
		"present_in_units": present, "present_services": services,
		"declared": bool(f.get("mobilization", {}).get("declared", false))}
