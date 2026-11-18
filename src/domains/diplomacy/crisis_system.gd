class_name CrisisSystem
extends RefCounted
## Phase III.D — crises internationales : déclenchement, escalade, réponses diplomatiques,
## médiation, règlement pacifique ou dérive vers la guerre. Aucune guerre automatique.


static func cfg(rules: Dictionary) -> Dictionary:
	var d: Variant = rules.get("diplomacy", {}).get("crises")
	return d if d is Dictionary else {}


static func by_id(state: GameState, cid: String) -> Dictionary:
	for c: Dictionary in state.diplomacy["crises"]:
		if str(c["id"]) == cid:
			return c
	return {}


static func start(state: GameState, initiator: String, target: String, motive: String,
		stake: String, rules: Dictionary) -> Dictionary:
	var c := cfg(rules)
	var active := 0
	for x: Dictionary in state.diplomacy["crises"]:
		if str(x["status"]) == "active":
			active += 1
	if active >= int(c.get("max_crises_at_once", 6)):
		return {}
	var crisis := {
		"id": state.new_id("crisis"), "initiator": initiator, "target": target,
		"parties": [initiator, target], "motive": motive, "stake": stake,
		"started_turn": state.turn, "tension": float(c.get("start_tension", 35)),
		"status": "active", "history": [{"turn": state.turn, "action": "started", "by": initiator, "detail": motive}],
		"mediators": [], "responses": []
	}
	(state.diplomacy["crises"] as Array).append(crisis)
	RelationsSystem.adjust(state, initiator, target, rules, {"tensions": 15.0, "hostility": 5.0}, "crisis:" + motive)
	state.log_event("crise", "Crise « %s » entre %s et %s (enjeu : %s)." % [
		motive, state.nations[initiator]["name_fr"], state.nations[target]["name_fr"], stake], [initiator, target])
	return crisis


static func respond(state: GameState, cid: String, nation: String, action: String, rules: Dictionary) -> String:
	var cr := by_id(state, cid)
	if cr.is_empty() or str(cr["status"]) != "active":
		return "crise inactive"
	if not (cr["parties"] as Array).has(nation) and not (cr["mediators"] as Array).has(nation):
		return "pays non impliqué"
	var c := cfg(rules)
	var reduction := 0.0
	var detail := ""
	match action:
		"protest":
			reduction = float(c.get("protest_reduction", 4))
			detail = "protestation"
		"negotiate":
			reduction = float(c.get("concession_reduction", 12)) * 0.5
			detail = "ouverture de négociation"
		"concede":
			reduction = float(c.get("concession_reduction", 12))
			detail = "concession"
		"guarantee":
			reduction = float(c.get("guarantee_reduction", 10))
			detail = "garantie proposée"
		"mediate":
			if (cr["mediators"] as Array).has(nation):
				reduction = float(c.get("mediation_reduction", 20))
				detail = "médiation"
			else:
				return "médiateur non reconnu"
		"sanction":
			reduction = -6.0
			detail = "sanctions diplomatiques"
		"mobilize":
			reduction = -8.0
			detail = "mobilisation politique"
		_:
			return "réponse inconnue"
	cr["tension"] = clampf(float(cr["tension"]) - reduction, 0.0, 100.0)
	(cr["responses"] as Array).append({"turn": state.turn, "by": nation, "action": action})
	(cr["history"] as Array).append({"turn": state.turn, "action": action, "by": nation, "detail": detail})
	RelationsSystem.record(state, nation, str(cr["initiator"]), "crisis_response", action, rules)
	state.log_event("crise", "%s : %s dans la crise %s (tension %.0f)." % [
		state.nations[nation]["name_fr"], detail, cr["id"], float(cr["tension"])], cr["parties"])
	return ""


static func offer_mediation(state: GameState, cid: String, mediator: String, rules: Dictionary) -> String:
	var cr := by_id(state, cid)
	if cr.is_empty() or str(cr["status"]) != "active":
		return "crise inactive"
	if (cr["parties"] as Array).has(mediator) or (cr["mediators"] as Array).has(mediator):
		return "médiateur invalide"
	(cr["mediators"] as Array).append(mediator)
	(cr["history"] as Array).append({"turn": state.turn, "action": "mediation_offered", "by": mediator})
	state.log_event("crise", "%s propose sa médiation dans %s." % [state.nations[mediator]["name_fr"], cid], cr["parties"])
	return respond(state, cid, mediator, "mediate", rules)


static func settle(state: GameState, cid: String, rules: Dictionary) -> void:
	var cr := by_id(state, cid)
	if cr.is_empty():
		return
	cr["status"] = "settled"
	cr["settled_turn"] = state.turn
	(cr["history"] as Array).append({"turn": state.turn, "action": "settled"})
	for p: String in cr["parties"]:
		RelationsSystem.adjust(state, str(cr["target"]), p, rules, {"tensions": -12.0, "trust": 4.0}, "crisis_settled")
	state.log_event("crise", "Crise %s réglée pacifiquement." % cr["id"], cr["parties"])


static func to_war(state: GameState, cid: String, rules: Dictionary) -> void:
	var cr := by_id(state, cid)
	if cr.is_empty():
		return
	cr["status"] = "war"
	cr["ended_turn"] = state.turn
	(cr["history"] as Array).append({"turn": state.turn, "action": "became_war"})
	var a := str(cr["initiator"])
	var b := str(cr["target"])
	if not state.at_war(a, b):
		state.wars.append({"id": state.new_id("war"), "a": a, "b": b, "since_turn": state.turn})
	RelationsSystem.record(state, a, b, "declared_war", "crisis:" + str(cr["motive"]), rules)
	state.log_event("guerre", "La crise %s dégénère en guerre entre %s et %s." % [
		cr["id"], state.nations[a]["name_fr"], state.nations[b]["name_fr"]], [a, b])


static func monthly(state: GameState, rules: Dictionary) -> void:
	var c := cfg(rules)
	for cr: Dictionary in state.diplomacy["crises"]:
		if str(cr["status"]) != "active":
			continue
		var last_actions: Array = cr["responses"]
		var appeased := false
		for r: Dictionary in last_actions:
			if int(r.get("turn", -1)) >= state.turn - 1 and str(r.get("action", "")) in ["concede", "mediate", "negotiate", "guarantee"]:
				appeased = true
		if appeased:
			cr["tension"] = clampf(float(cr["tension"]) - float(c.get("monthly_deescalation", 5)), 0.0, 100.0)
		else:
			cr["tension"] = clampf(float(cr["tension"]) + float(c.get("monthly_escalation", 6)), 0.0, 100.0)
		if float(cr["tension"]) >= float(c.get("war_threshold", 85)):
			to_war(state, str(cr["id"]), rules)
		elif float(cr["tension"]) <= float(c.get("settle_threshold", 20)):
			settle(state, str(cr["id"]), rules)
