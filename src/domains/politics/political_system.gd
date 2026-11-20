class_name PoliticalSystem
extends RefCounted
## Phase VII.B/C/D — politique intérieure : indicateurs, groupes d'influence, décisions,
## crises intérieures et changements de gouvernement. Effets concrets, déterministes.


static func ensure(state: GameState, nid: String, rules: Dictionary) -> Dictionary:
	var cfg: Dictionary = rules.get("politics", {})
	if not (state.politics is Dictionary) or not state.politics.has("states"):
		state.politics = {"states": {}, "decisions": [], "crises": [], "history": []}
	if not state.politics["states"].has(nid):
		var groups: Dictionary = {}
		for gid: String in cfg.get("groups", {}):
			var g: Dictionary = cfg["groups"][gid]
			groups[gid] = {"influence": float(g.get("influence", 10)), "satisfaction": float(g.get("satisfaction", 50)),
				"interests": (g.get("interests", []) as Array).duplicate(true)}
		state.politics["states"][nid] = {
			"stability": float(cfg.get("stability_start", 65)),
			"cohesion": float(cfg.get("cohesion_start", 60)),
			"popularity": float(cfg.get("popularity_start", 55)),
			"social_tension": float(cfg.get("social_tension_start", 25)),
			"war_support": float(cfg.get("war_support_start", 50)),
			"institution_trust": float(cfg.get("institution_trust_start", 60)),
			"groups": groups, "regime": "government", "government_turn": state.turn,
			"active_crisis": "", "history": []
		}
	return state.politics["states"][nid]


static func _clamp(v: float, cfg: Dictionary) -> float:
	return clampf(v, float(cfg.get("min", 0)), float(cfg.get("max", 100)))


static func monthly(state: GameState, nid: String, rules: Dictionary) -> void:
	var cfg: Dictionary = rules.get("politics", {})
	var p := ensure(state, nid, rules)
	# Dérive naturelle vers la stabilité, mais dégradation si tensions élevées.
	var tension := float(p["social_tension"])
	var drift := float(cfg.get("monthly_regression", 0.5))
	p["stability"] = _clamp(float(p["stability"]) + drift - tension * 0.01, cfg)
	p["social_tension"] = _clamp(tension - drift * 0.5, cfg)
	# Guerre : soutien à l'effort de guerre lié aux pertes et au moral économique.
	var at_war := false
	for w: Dictionary in state.wars:
		if str(w["a"]) == nid or str(w["b"]) == nid:
			at_war = true
	if at_war:
		p["war_support"] = _clamp(float(p["war_support"]) - 0.5, cfg)
		p["social_tension"] = _clamp(float(p["social_tension"]) + 0.4, cfg)
	# Satisfaction des groupes influencée par la stabilité et la tensions.
	for gid: String in p["groups"]:
		var g: Dictionary = p["groups"][gid]
		var target := 50.0 + (float(p["stability"]) - 50.0) * 0.4 - tension * 0.2
		g["satisfaction"] = _clamp(float(g["satisfaction"]) * 0.8 + target * 0.2, cfg)
	# Crise intérieure.
	_update_crisis(state, nid, p, cfg)


static func _update_crisis(state: GameState, nid: String, p: Dictionary, cfg: Dictionary) -> void:
	var ccfg: Dictionary = cfg.get("crisis", {})
	var trigger := float(p["social_tension"]) >= float(ccfg.get("tension_threshold", 75)) \
		or float(p["stability"]) <= float(ccfg.get("stability_threshold", 25)) \
		or float(p["popularity"]) <= float(ccfg.get("popularity_threshold", 20))
	if str(p["active_crisis"]) == "" and trigger:
		var cid := state.new_id("internal_crisis")
		p["active_crisis"] = cid
		(state.politics["crises"] as Array).append({"id": cid, "nation": nid, "turn": state.turn,
			"reason": "tensions internes", "status": "active", "intensity": 50.0})
		(p["history"] as Array).append({"turn": state.turn, "event": "crisis_started", "id": cid})
		state.log_event("politique", "Crise intérieure en %s." % state.nations[nid]["name_fr"], [nid])
	elif str(p["active_crisis"]) != "":
		for cr: Dictionary in state.politics["crises"]:
			if str(cr["id"]) == str(p["active_crisis"]) and str(cr["status"]) == "active":
				if float(p["social_tension"]) < 50.0 and float(p["stability"]) > 40.0:
					cr["status"] = "resolved"
					cr["resolved_turn"] = state.turn
					p["active_crisis"] = ""
					(p["history"] as Array).append({"turn": state.turn, "event": "crisis_resolved"})
				else:
					cr["intensity"] = clampf(float(cr["intensity"]) + float(ccfg.get("escalation_per_turn", 3)), 0, 100)


static func apply_decision(state: GameState, nid: String, kind: String, rules: Dictionary) -> String:
	var cfg: Dictionary = rules.get("politics", {})
	var p := ensure(state, nid, rules)
	var costs: Dictionary = cfg.get("decisions", {}).get("costs", {})
	if not costs.has(kind):
		return "décision inconnue"
	var n_done := 0
	for d: Dictionary in state.politics["decisions"]:
		if str(d["nation"]) == nid and int(d["turn"]) == state.turn:
			n_done += 1
	if n_done >= int(cfg.get("decisions", {}).get("max_per_turn", 2)):
		return "nombre maximal de décisions atteint"
	var effects: Dictionary = costs[kind]
	var stocks: Dictionary = state.economy["stocks"].get(nid, {})
	if effects.has("money") and float(stocks.get("money", 0.0)) < float(effects["money"]):
		return "fonds insuffisants"
	for key: String in effects:
		if key == "money":
			stocks["money"] = float(stocks.get("money", 0.0)) - float(effects[key])
		elif p.has(key):
			p[key] = _clamp(float(p[key]) + float(effects[key]), cfg)
	(state.politics["decisions"] as Array).append({"turn": state.turn, "nation": nid, "kind": kind})
	(p["history"] as Array).append({"turn": state.turn, "event": "decision", "kind": kind})
	return ""


static func change_government(state: GameState, nid: String, kind: String, rules: Dictionary) -> String:
	var cfg: Dictionary = rules.get("politics", {})
	var p := ensure(state, nid, rules)
	var ccfg: Dictionary = cfg.get("crisis", {})
	if kind not in ["reshuffle", "regime_change", "negotiated"]:
		return "type de changement inconnu"
	if str(p["active_crisis"]) == "" and kind != "negotiated":
		return "aucune crise justifiant un changement"
	var loss := float(ccfg.get("government_change_stability", 20)) if kind != "regime_change" \
		else float(ccfg.get("regime_change_stability", 10))
	p["stability"] = _clamp(float(p["stability"]) - loss, cfg)
	p["regime"] = "new_" + kind
	p["government_turn"] = state.turn
	p["active_crisis"] = ""
	(p["history"] as Array).append({"turn": state.turn, "event": "government_change", "kind": kind})
	# Effet diplomatique : la réputation du pays est dégradée, sans effacer l'historique.
	state.reputation[nid] = float(state.reputation.get(nid, 0.0)) - 5.0
	state.log_event("politique", "Changement de gouvernement en %s (%s)." % [
		state.nations[nid]["name_fr"], kind], [nid])
	return ""


static func summary(state: GameState, nid: String) -> Dictionary:
	var p: Dictionary = ensure(state, nid, {})
	return {"stability": p["stability"], "cohesion": p["cohesion"], "popularity": p["popularity"],
		"social_tension": p["social_tension"], "war_support": p["war_support"],
		"trust": p["institution_trust"], "regime": p["regime"], "crisis": p["active_crisis"]}
