class_name ConferenceSystem
extends RefCounted
## Phase III.H — conférences internationales : plusieurs participants, plusieurs sujets,
## production d'accords réels par délégation aux systèmes d'alliance et de paix.


static func by_id(state: GameState, cid: String) -> Dictionary:
	for c: Dictionary in state.diplomacy.get("conferences", []):
		if str(c["id"]) == cid:
			return c
	return {}


static func create(state: GameState, proposal: Dictionary, rules: Dictionary) -> Dictionary:
	var parties: Array = (proposal["to"] as Array).duplicate(true)
	parties.append(str(proposal["from"]))
	var term_val: Variant = proposal.get("terms")
	var terms: Dictionary = term_val if term_val is Dictionary else {}
	var topics: Array = terms.get("topics", ["crisis", "alliance"])
	var c := {
		"id": state.new_id("conference"), "opened_turn": state.turn, "participants": parties,
		"topics": topics.duplicate(true), "agreements": [], "status": "active",
		"history": [{"turn": state.turn, "action": "opened", "by": proposal["from"]}]
	}
	(state.diplomacy["conferences"] as Array).append(c)
	state.log_event("conférence", "Conférence %s ouverte avec %s (sujets : %s)." % [
		c["id"], str(parties), str(topics)], parties)
	for p: String in parties:
		for q: String in parties:
			if p != q:
				RelationsSystem.adjust(state, p, q, rules, {"cooperation": 3.0}, "conference")
	return c


static func add_topic(state: GameState, cid: String, topic: String) -> String:
	var c := by_id(state, cid)
	if c.is_empty() or str(c["status"]) != "active":
		return "conférence inactive"
	if not (c["topics"] as Array).has(topic):
		(c["topics"] as Array).append(topic)
	(c["history"] as Array).append({"turn": state.turn, "action": "topic_added", "topic": topic})
	return ""


## Conclut un sujet : délègue au système compétent et enregistre l'accord produit.
static func conclude(state: GameState, cid: String, topic: String, rules: Dictionary) -> Dictionary:
	var c := by_id(state, cid)
	if c.is_empty() or str(c["status"]) != "active" or not (c["topics"] as Array).has(topic):
		return {}
	var parties: Array = c["participants"]
	var result := {}
	match topic:
		"alliance":
			if parties.size() >= 2:
				var synth := {"kind": "alliance", "from": parties[0], "to": [parties[1]], "terms": {}}
				var a := AllianceSystem.create(state, synth, rules)
				if not a.is_empty():
					result = {"type": "alliance", "id": a["id"]}
		"guarantee":
			if parties.size() >= 2:
				var synth := {"kind": "guarantee", "from": parties[0], "to": [parties[1]], "terms": {}}
				var a := AllianceSystem.create(state, synth, rules)
				if not a.is_empty():
					result = {"type": "guarantee", "id": a["id"]}
		"crisis", "peace":
			var crises: Array = state.diplomacy.get("crises", [])
			for cr: Dictionary in crises:
				if str(cr["status"]) == "active":
					CrisisSystem.settle(state, str(cr["id"]), rules)
					result = {"type": "crisis_settled", "id": cr["id"]}
					break
	if result.is_empty():
		result = {"type": "declaration", "topic": topic}
	(c["agreements"] as Array).append({"turn": state.turn, "topic": topic, "result": result})
	(c["history"] as Array).append({"turn": state.turn, "action": "concluded", "topic": topic})
	state.log_event("conférence", "Conférence %s conclut « %s » : %s." % [c["id"], topic, str(result)], parties)
	return result


static func close(state: GameState, cid: String) -> void:
	var c := by_id(state, cid)
	if c.is_empty():
		return
	c["status"] = "closed"
	(c["history"] as Array).append({"turn": state.turn, "action": "closed"})
