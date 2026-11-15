class_name MilitarySystem
extends RefCounted
## Formations, déplacements, souveraineté, occupation.
## Règles appliquées :
## - VALIDÉ : hiérarchie soldats/équipements → unités → régiments → divisions → armées ;
## - VALIDÉ : entrée en territoire étranger seulement en guerre ou avec une autorisation de passage
##   (dossier §5.3). Une entrée non autorisée est REFUSÉE à la validation, car la règle de
##   crise n'est pas définie ;
## - VALIDÉ : occupation ≠ souveraineté (une région occupée garde son souverain) ;
## - PROPOSÉ (configurable) : portée de `regions_per_month` régions par mois ; occupation
##   d'une région ennemie dépourvue de formation adverse.

const ECHELONS: PackedStringArray = ["unit", "regiment", "division", "army"]


static func can_enter(state: GameState, nation: String, rid: String) -> bool:
	var owner := state.controller(rid)
	if owner == nation:
		return true
	if state.at_war(nation, owner):
		return true
	return state.has_transit(nation, owner)


## Retourne "" si l'ordre est valide, sinon le motif du refus.
static func validate_move(state: GameState, world: WorldMap, rules: Dictionary, order: Dictionary) -> String:
	var fid: String = order.get("formation", "")
	if not state.formations.has(fid):
		return "formation inconnue"
	var f: Dictionary = state.formations[fid]
	if f["nation"] != order["nation"]:
		return "commandement national seulement : cette formation n'appartient pas à %s" % order["nation"]
	var target: String = order.get("target", "")
	if not world.has_region(target):
		return "région inconnue"
	if target == f["region"]:
		return "la formation est déjà dans cette région"
	var mv: Dictionary = rules["movement"]
	var path := world.shortest_path(f["region"], target,
		func(rid: String) -> bool: return can_enter(state, order["nation"], rid), bool(mv["allow_straits"]))
	if path.is_empty():
		return "aucun itinéraire autorisé (connexions, souveraineté, autorisations de passage)"
	if path.size() - 1 > int(mv["regions_per_month"]):
		return "trop loin pour un mois (%d régions, portée provisoire %d)" % [path.size() - 1, int(mv["regions_per_month"])]
	if not can_enter(state, order["nation"], target):
		return "entrée non autorisée : ni guerre ni autorisation de passage avec %s" % state.controller(target)
	return ""


## Résolution simultanée des déplacements. Retourne la liste des affrontements à traiter.
static func resolve_moves(state: GameState, world: WorldMap, rules: Dictionary, moves: Array) -> Array:
	var origin: Dictionary = {}
	for order: Dictionary in moves:
		var f: Dictionary = state.formations[order["formation"]]
		origin[f["id"]] = f["region"]
	# 1. Tous les mouvements valides sont appliqués en même temps.
	for order: Dictionary in moves:
		var f: Dictionary = state.formations[order["formation"]]
		f["region"] = order["target"]
		f["planned_target"] = ""
		state.log_event("armée", "%s (%s) : %s → %s" % [f["name_fr"], state.nations[f["nation"]]["name_fr"],
			world.regions[origin[f["id"]]]["name_fr"], world.regions[order["target"]]["name_fr"]], [f["nation"]])
	# 2. Contacts entre belligérants dans une même région -> affrontements.
	var clashes: Array = []
	var ids := state.regions.keys()
	ids.sort()
	for rid: String in ids:
		var present := state.formations_in(rid)
		var hostile_pairs := false
		for i in present.size():
			for j in range(i + 1, present.size()):
				if state.at_war(present[i]["nation"], present[j]["nation"]):
					hostile_pairs = true
		if hostile_pairs:
			# Camps : le défenseur est le camp du contrôleur de la région (avec les formations
			# qui ne lui sont pas hostiles) ; l'attaquant, les formations en guerre avec lui.
			# Si le contrôleur est un tiers, le camp du premier entrant (ordre stable) attaque.
			var anchor := state.controller(rid)
			var anchored := false
			for f: Dictionary in present:
				if f["nation"] == anchor or state.at_war(f["nation"], anchor):
					anchored = true
			if not anchored:
				for f: Dictionary in present:
					if origin.has(f["id"]) and origin[f["id"]] != rid:
						anchor = _first_enemy_of(state, present, f["nation"])
						break
			var attackers: Array = []
			var defenders: Array = []
			for f: Dictionary in present:
				if f["nation"] != anchor and state.at_war(f["nation"], anchor):
					attackers.append(f["id"])
				else:
					defenders.append(f["id"])
			if attackers.is_empty() or defenders.is_empty():
				continue
			clashes.append({"region": rid, "attackers": attackers, "defenders": defenders, "origin": origin})
	# 3. Occupation des régions ennemies sans adversaire présent.
	var occ: Dictionary = rules["occupation"]
	if bool(occ["occupy_if_undefended"]):
		var clash_regions: Array = clashes.map(func(c: Dictionary) -> String: return c["region"])
		for order: Dictionary in moves:
			var f: Dictionary = state.formations[order["formation"]]
			var rid: String = f["region"]
			if clash_regions.has(rid):
				continue
			var owner := state.controller(rid)
			if owner != f["nation"] and state.at_war(f["nation"], owner):
				var previous := owner
				state.regions[rid]["controller"] = f["nation"]
				var verb := "libère" if state.sovereign(rid) == f["nation"] else "occupe"
				state.log_event("occupation", "%s %s %s (souveraineté : %s)" % [state.nations[f["nation"]]["name_fr"], verb,
					world.regions[rid]["name_fr"], state.nations[state.sovereign(rid)]["name_fr"]], [f["nation"], previous])
				state.remember(previous, f["nation"], "region_lost", rid)
	return clashes


static func _first_enemy_of(state: GameState, present: Array, nation: String) -> String:
	for f: Dictionary in present:
		if state.at_war(f["nation"], nation):
			return f["nation"]
	return nation
