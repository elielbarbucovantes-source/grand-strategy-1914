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
	if not state.is_top_level(f):
		return "seules les armées se déplacent sur la carte stratégique (les unités suivent leur armée)"
	if state.is_engaged(fid):
		return "formation engagée dans une bataille en cours : déplacement impossible"
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
	return TerritorialForce.move_restriction(state, f, target)  # T-054 : service intérieur


## Résolution simultanée des déplacements (T-045). Retourne la liste des affrontements à traiter.
## - Tous les mouvements valides sont appliqués EN MÊME TEMPS, puis les contacts sont évalués sur
##   les positions FINALES : deux armées ennemies qui échangent leurs positions (A→B et B→A) se
##   croisent sans combattre (décision T-045). Aucune bataille n'est créée « en chemin ».
## - Une bataille naît seulement si des armées ennemies se trouvent dans la même région à la fin
##   des mouvements (règle territoriale normale, inchangée).
## - Aucun départage ne dépend de l'ordre technique des pays ou des identifiants : les cas
##   symétriques utilisent un tirage déterministe dérivé de la graine (TURN-03, TURN-04).
static func resolve_moves(state: GameState, world: WorldMap, rules: Dictionary, moves: Array) -> Array:
	var origin: Dictionary = {}
	for order: Dictionary in moves:
		var f: Dictionary = state.formations[order["formation"]]
		origin[f["id"]] = f["region"]
	# 1. Tous les mouvements valides sont appliqués en même temps.
	for order: Dictionary in moves:
		var f: Dictionary = state.formations[order["formation"]]
		state.move_army(f["id"], order["target"])
		f["planned_target"] = ""
		state.log_event("armée", "%s (%s) : %s → %s" % [f["name_fr"], state.nations[f["nation"]]["name_fr"],
			world.regions[origin[f["id"]]]["name_fr"], world.regions[order["target"]]["name_fr"]], [f["nation"]])
	# 2. Contacts entre belligérants dans une même région -> affrontements.
	var clashes: Array = []
	var ids := state.regions.keys()
	ids.sort()
	for rid: String in ids:
		var present := state.armies_in(rid)
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
				# Contrôleur tiers : défend le camp déjà présent ; si tous viennent d'entrer
				# (rencontre), tirage neutre entre les pays présents.
				var stayers: Array = []
				var all_nations: Array = []
				for f: Dictionary in present:
					if not all_nations.has(f["nation"]):
						all_nations.append(f["nation"])
					if (not origin.has(f["id"]) or origin[f["id"]] == rid) and not stayers.has(f["nation"]):
						stayers.append(f["nation"])
				anchor = neutral_pick(state, "anchor:" + rid, stayers if not stayers.is_empty() else all_nations)
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
	# 3. Occupation des régions ennemies sans adversaire présent. Si plusieurs pays co-belligérants
	#    y entrent ensemble, le contrôle revient à celui qui y amène le plus de soldats ; égalité ou
	#    effectifs inconnus : tirage neutre (jamais l'ordre des pays).
	var occ: Dictionary = rules["occupation"]
	if bool(occ["occupy_if_undefended"]):
		var clash_regions: Array = clashes.map(func(c: Dictionary) -> String: return c["region"])
		var entrants: Dictionary = {}  # région -> {nation: soldats}
		for order: Dictionary in moves:
			var f: Dictionary = state.formations[order["formation"]]
			var rid: String = f["region"]
			var owner := state.controller(rid)
			if clash_regions.has(rid) or owner == f["nation"] or not state.at_war(f["nation"], owner):
				continue
			if not entrants.has(rid):
				entrants[rid] = {}
			var s: Variant = state.soldiers_of(f["id"])
			entrants[rid][f["nation"]] = int(entrants[rid].get(f["nation"], 0)) + (0 if s == null else int(s))
		var occ_regions := entrants.keys()
		occ_regions.sort()
		for rid: String in occ_regions:
			var top := -1
			var best: Array = []
			for n: String in entrants[rid]:
				if int(entrants[rid][n]) > top:
					top = int(entrants[rid][n])
					best = [n]
				elif int(entrants[rid][n]) == top:
					best.append(n)
			var occupant := neutral_pick(state, "occupy:" + rid, best)
			var previous := state.controller(rid)
			state.regions[rid]["controller"] = occupant
			var verb := "libère" if state.sovereign(rid) == occupant else "occupe"
			state.log_event("occupation", "%s %s %s (souveraineté : %s)" % [state.nations[occupant]["name_fr"], verb,
				world.regions[rid]["name_fr"], state.nations[state.sovereign(rid)]["name_fr"]], [occupant, previous])
			state.remember(previous, occupant, "region_lost", rid)
	return clashes


## Choix neutre et reproductible parmi des candidats symétriques : dépend de la graine de la partie,
## du tour et du contexte, jamais de l'ordre des pays ni des identifiants (TURN-03).
static func neutral_pick(state: GameState, context: String, candidates: Array) -> String:
	if candidates.is_empty():
		return ""
	var sorted := candidates.duplicate()
	sorted.sort()
	if sorted.size() == 1:
		return sorted[0]
	var h := ("%d|%d|%s" % [state.seed_value, state.turn, context]).sha256_text()
	return sorted[h.substr(0, 8).hex_to_int() % sorted.size()]
