class_name DefenseSystem
extends RefCounted
## Construction défensive HORS bataille (T-032/T-033). Le joueur dessine des segments de tranchée
## et place des installations dans le cadre tactique de la région (mêmes coordonnées que le champ
## de bataille). Les travaux progressent chaque MOIS selon les soldats présents du pays, le
## terrain et le type d'unité, sans jamais être instantanés. L'étendue du réseau de tranchées est
## limitée par le nombre de soldats présents (T-033, T-040 C). Coût en ressources : OUVERT (R-03).
## Les ouvrages existants sont intégrés automatiquement aux batailles (T-041).


static func defenses(state: GameState, rid: String) -> Dictionary:
	if not state.regions[rid].has("defenses"):
		state.regions[rid]["defenses"] = {"trenches": [], "installations": []}
	return state.regions[rid]["defenses"]


static func soldiers_present(state: GameState, nation: String, rid: String) -> int:
	var total := 0
	for army: Dictionary in state.armies_in(rid):
		if army["nation"] == nation:
			var s: Variant = state.soldiers_of(army["id"])
			if s != null:
				total += int(s)
	return total


## Ordre : {"type": "build_defense", "nation", "region", "kind", "a", "b"} (tranchée) ou {"pos"} (installation).
static func validate(state: GameState, cr: Dictionary, order: Dictionary) -> String:
	var rid: String = order.get("region", "")
	if not state.regions.has(rid):
		return "région inconnue"
	if state.controller(rid) != order["nation"]:
		return "construction possible seulement dans une région contrôlée"
	var present := soldiers_present(state, order["nation"], rid)
	if present <= 0:
		return "aucune troupe aux effectifs connus dans la région (les travaux exigent des soldats présents)"
	var kind: String = order.get("kind", "")
	if kind == "trench_segment":
		var length := CombatData.v(order["a"]).distance_to(CombatData.v(order["b"]))
		if length < 20.0:
			return "segment trop court"
		var network := 0.0
		for t: Dictionary in defenses(state, rid)["trenches"]:
			if t["owner"] == order["nation"]:
				network += CombatData.v(t["a"]).distance_to(CombatData.v(t["b"]))
		if network + length > present * float(cr["construction"]["trench_capacity_per_soldier"]):
			return "réseau trop étendu pour les effectifs présents"
	elif not CombatData.INSTALLATIONS.has(kind):
		return "ouvrage inconnu"
	return ""


static func apply_order(state: GameState, cr: Dictionary, order: Dictionary) -> void:
	var d := defenses(state, order["region"])
	if order["kind"] == "trench_segment":
		var pa := CombatData.v(order["a"])
		var pb := CombatData.v(order["b"])
		(d["trenches"] as Array).append({"id": state.new_id("trench"), "owner": order["nation"], "a": CombatData.a(pa), "b": CombatData.a(pb),
			"site": CombatData.a((pa + pb) / 2.0), "level": 0, "target_level": 1, "progress": 0.0,
			"work_needed": pa.distance_to(pb) / 100.0 * float(cr["construction"]["types"]["trench_segment"]["work_per_100_length"]),
			"complete": false, "condition": 1.0})
	else:
		(d["installations"] as Array).append({"id": state.new_id("inst"), "type": order["kind"], "owner": order["nation"],
			"pos": CombatData.a(CombatData.v(order["pos"])), "site": CombatData.a(CombatData.v(order["pos"])), "progress": 0.0,
			"work_needed": float(cr["construction"]["types"][order["kind"]]["work"]), "complete": false, "condition": 1.0})


## Progression mensuelle : le travail disponible (soldats présents × taux × terrain) est réparti
## sur les ouvrages inachevés du pays, dans l'ordre de commande.
static func monthly(state: GameState, world: WorldMap, cr: Dictionary) -> void:
	var rids := state.regions.keys()
	rids.sort()
	for rid: String in rids:
		if not state.regions[rid].has("defenses"):
			continue
		var d: Dictionary = state.regions[rid]["defenses"]
		var dig := float(Battlefield.terrain_profile(world.regions[rid]["relief_categories"], cr)["dig"])
		var budget: Dictionary = {}
		for job: Dictionary in d["trenches"] + d["installations"]:
			if job["complete"]:
				continue
			var owner: String = job["owner"]
			if state.controller(rid) != owner:
				continue
			if not budget.has(owner):
				budget[owner] = float(soldiers_present(state, owner, rid)) * float(cr["construction"]["work_per_soldier_per_month"]) * dig
			var need := float(job["work_needed"]) - float(job["progress"])
			var used := minf(need, float(budget[owner]))
			budget[owner] = float(budget[owner]) - used
			job["progress"] = float(job["progress"]) + used
			if float(job["progress"]) >= float(job["work_needed"]) - 0.001:
				if job.has("level"):
					job["level"] = int(job["level"]) + 1
					job["progress"] = 0.0
					job["complete"] = int(job["level"]) >= int(job["target_level"])
				else:
					job["complete"] = true
				state.log_event("défenses", "%s : ouvrage achevé en %s." % [state.nations[owner]["name_fr"], world.regions[rid]["name_fr"]], [owner])
