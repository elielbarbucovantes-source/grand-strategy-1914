class_name VictorySystem
extends RefCounted
## Phase VII.E — trois conditions de victoire : militaire (90 % contrôle), développement humain
## (IDH relatif) et diplomatique (Traité de Paix et d'Unité Internationale). Fin de partie.


static func cfg(rules: Dictionary) -> Dictionary:
	return rules.get("victory", {})


static func military_share(state: GameState, nid: String, rules: Dictionary) -> float:
	var total := state.regions.size()
	if total == 0:
		return 0.0
	var controlled := 0
	for rid: String in state.regions:
		var r: Dictionary = state.regions[rid]
		if str(r["controller"]) == nid:
			controlled += 1
	return float(controlled) / float(total)


static func hdi(state: GameState, nid: String, rules: Dictionary) -> Dictionary:
	var cfg_hdi: Dictionary = cfg(rules).get("hdi", {})
	var regions: Dictionary = state.economy.get("regions", {})
	var pop := 0
	var industry := IndustrySystem.capacity(state, nid)
	var food := 0.0
	for rid: String in regions:
		var r: Dictionary = regions[rid]
		if str(r["nation"]) == nid:
			pop += int(r.get("population", 0))
			food += float(r.get("food_ratio", 1.0))
	var avg_food := 1.0
	var n := 0
	for rid: String in regions:
		if str(regions[rid]["nation"]) == nid:
			avg_food += float(regions[rid].get("food_ratio", 1.0))
			n += 1
	if n > 0:
		avg_food = avg_food / float(n)
	var p: Dictionary = PoliticalSystem.ensure(state, nid, rules.get("politics", {}))
	var life := 45.0 + avg_food * 10.0 + float(p["stability"]) * 0.1
	var education := 0.2 + float(state.tech["known"].get(nid, []).size()) * 0.01
	# Revenu PAR HABITANT : un stock monétaire brut ne doit pas donner une victoire artificielle.
	var income := (industry * 0.5 + float(state.economy["stocks"].get(nid, {}).get("money", 0.0)) * 0.001) \
		/ maxf(1.0, float(pop) / 1000000.0)
	var score := (clampf(life / 85.0, 0.0, 1.0) + clampf(education, 0.0, 1.0)
		+ clampf(income / 2.0, 0.0, 1.0) + clampf(avg_food, 0.0, 1.2) / 1.2
		+ float(p["institution_trust"]) / 100.0) / 5.0
	return {"score": score, "population": pop, "industry": industry, "food": avg_food}


static func check_victory(state: GameState, rules: Dictionary) -> Dictionary:
	if str(state.victory.get("status", "ongoing")) != "ongoing":
		return state.victory.duplicate(true)
	var cfg_v: Dictionary = cfg(rules)
	# 1. Militaire : > 90 % de régions contrôlées, occupation ≠ souveraineté.
	var mil: Dictionary = cfg_v.get("military", {})
	var threshold := float(mil.get("threshold", 0.9))
	for nid: String in state.nation_order:
		if military_share(state, nid, rules) >= threshold:
			return _declare(state, nid, "military")
	# 2. IDH relatif maintenu sur la durée.
	var hdi_cfg: Dictionary = cfg_v.get("hdi", {})
	var rel := float(hdi_cfg.get("relative_threshold", 1.25))
	var duration := int(hdi_cfg.get("duration_months", 6))
	for nid: String in state.nation_order:
		var mine := hdi(state, nid, rules)
		if int(mine["population"]) < int(hdi_cfg.get("min_population", 5000000)) or float(mine["industry"]) < float(hdi_cfg.get("min_industry", 0.3)):
			continue
		var others: Array = []
		for oid: String in state.nation_order:
			if oid != nid:
				others.append(float(hdi(state, oid, rules)["score"]))
		others.sort()
		var median := 0.5
		if others.size() > 0:
			median = float(others[others.size() / 2])
		if median > 0.0 and float(mine["score"]) / median >= rel:
			var streak_key := nid + "_hdi_streak"
			var streak := int(state.victory.get(streak_key, 0)) + 1
			state.victory[streak_key] = streak
			if streak >= duration:
				return _declare(state, nid, "human_development")
		else:
			state.victory[nid + "_hdi_streak"] = 0
	# 3. Diplomatique : pacte universel (Phase III).
	for t: Dictionary in state.diplomacy.get("peace_treaties", []):
		if str(t.get("type", "")) == "universal" and str(t.get("status", "")) == "active":
			return _declare(state, str((t.get("members", []) as Array)[0]) if not (t.get("members", []) as Array).is_empty() else "", "diplomatic")
	# Égalité militaire : plusieurs États au-dessus du seuil simultanément (rare).
	var leaders: Array = []
	for nid: String in state.nation_order:
		if military_share(state, nid, rules) >= threshold:
			leaders.append(nid)
	if leaders.size() > 1:
		return _declare_tie(state, leaders)
	return state.victory.duplicate(true)


static func _declare(state: GameState, winner: String, condition: String) -> Dictionary:
	state.victory = {"status": "finished", "winner": winner, "condition": condition,
		"turn": state.turn, "history": (state.victory.get("history", []) as Array).duplicate(true)}
	(state.victory["history"] as Array).append({"turn": state.turn, "winner": winner, "condition": condition})
	state.log_event("victoire", "Victoire %s de %s." % [condition, winner], [winner] if winner != "" else [])
	return state.victory.duplicate(true)


static func _declare_tie(state: GameState, leaders: Array) -> Dictionary:
	state.victory = {"status": "finished", "winner": "coalition", "condition": "military_tie",
		"leaders": leaders.duplicate(true), "turn": state.turn,
		"history": (state.victory.get("history", []) as Array).duplicate(true)}
	state.log_event("victoire", "Victoire militaire collective : %s." % str(leaders), leaders)
	return state.victory.duplicate(true)


static func final_summary(state: GameState, rules: Dictionary) -> Dictionary:
	var standings: Array = []
	for nid: String in state.nation_order:
		standings.append({"nation": nid, "military": military_share(state, nid, rules),
			"hdi": hdi(state, nid, rules)["score"],
			"stability": PoliticalSystem.summary(state, nid)["stability"]})
	standings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["military"]) > float(b["military"]))
	return {"victory": state.victory.duplicate(true), "turn": state.turn,
		"major_events": (state.events as Array).slice(-12), "standings": standings}
