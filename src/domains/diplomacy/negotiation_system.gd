class_name NegotiationSystem
extends RefCounted
## Phase III.B — propositions, acceptation, refus, contre-propositions, retrait, expiration,
## communications publiques/privées/de groupe et historique des échanges.


static func cfg(rules: Dictionary) -> Dictionary:
	var d: Variant = rules.get("diplomacy", {}).get("proposals")
	return d if d is Dictionary else {}


static func validate(state: GameState, order: Dictionary, rules: Dictionary) -> String:
	var nation: String = order["nation"]
	var c := cfg(rules)
	match order["type"]:
		Orders.PROPOSE_TREATY, Orders.PROPOSE_AGREEMENT:
			var kind := str(order.get("kind", ""))
			if not (c.get("kinds", []) as Array).has(kind):
				return "type d'accord inconnu"
			var dest: Variant = order.get("to", order.get("target", ""))
			var recipients: Array = []
			if dest is Array:
				recipients = dest
			elif dest is String:
				recipients = [dest]
			if recipients.is_empty():
				return "destinataire manquant"
			for d: String in recipients:
				if not state.nations.has(d) or d == nation:
					return "destinataire invalide"
			if kind == "peace":
				var at_war := false
				for d: String in recipients:
					if state.at_war(nation, d):
						at_war = true
				if not at_war:
					return "pas en guerre"
			if _count_pending(state, nation) >= int(c.get("max_per_nation_per_turn", 3)):
				return "nombre maximal de propositions atteint"
		Orders.RESPOND_PROPOSAL, Orders.RESPOND_AGREEMENT:
			var p := by_id(state, str(order.get("proposal", "")))
			if p.is_empty() or str(p["status"]) != "pending":
				return "proposition inconnue ou close"
			if not (p["to"] as Array).has(nation):
				return "proposition non adressée à ce pays"
		Orders.WITHDRAW_PROPOSAL:
			var p := by_id(state, str(order.get("proposal", "")))
			if p.is_empty() or str(p["status"]) != "pending" or str(p["from"]) != nation:
				return "proposition non retirable"
		Orders.SEND_MESSAGE:
			if not Orders.CHANNELS.has(str(order.get("channel", ""))):
				return "canal inconnu"
	return ""


static func _count_pending(state: GameState, nation: String) -> int:
	var n := 0
	var current := state.turn
	for p: Dictionary in state.proposals:
		if str(p["from"]) == nation and str(p["status"]) == "pending" and int(p.get("turn", 0)) == current:
			n += 1
	return n


static func by_id(state: GameState, pid: String) -> Dictionary:
	for p: Dictionary in state.proposals:
		if str(p["id"]) == pid:
			return p
	return {}


static func propose(state: GameState, order: Dictionary, rules: Dictionary) -> Dictionary:
	var c := cfg(rules)
	var dest: Variant = order.get("to", order.get("target", ""))
	var recipients: Array = dest if dest is Array else [dest]
	var term_val: Variant = order.get("terms")
	var terms: Dictionary = term_val if term_val is Dictionary else {}
	var p := {
		"id": state.new_id("proposal"), "turn": state.turn, "from": order["nation"], "to": recipients.duplicate(true),
		"kind": order.get("kind", ""), "status": "pending", "terms": terms.duplicate(true),
		"channel": order.get("channel", "private"), "expires_turn": state.turn + int(c.get("valid_turns", 3)),
		"counters": [], "history": [{"turn": state.turn, "action": "proposed", "by": order["nation"]}]
	}
	state.proposals.append(p)
	RelationsSystem.record(state, order["nation"], str(recipients[0]), "proposal_sent", p["kind"], rules)
	state.log_event("diplomatie", "%s propose « %s » à %s." % [
		state.nations[order["nation"]]["name_fr"], p["kind"], str(recipients)], recipients)
	var neg: Dictionary = state.diplomacy["negotiations"]
	neg[p["id"]] = {"opened": state.turn, "proposal": p["id"], "rounds": 1}
	return p


static func respond(state: GameState, order: Dictionary, rules: Dictionary) -> Dictionary:
	var p := by_id(state, str(order.get("proposal", "")))
	if p.is_empty() or str(p["status"]) != "pending":
		return {}
	var nation := str(order["nation"])
	var accept := bool(order.get("accept", false))
	var counter: Dictionary = order.get("counter_terms", {})
	var hist: Array = p["history"]
	if not counter.is_empty():
		var maxc := int(cfg(rules).get("max_counter_per_proposal", 2))
		if (p["counters"] as Array).size() >= maxc:
			return {}
		(p["counters"] as Array).append({"turn": state.turn, "by": nation, "terms": counter.duplicate(true)})
		hist.append({"turn": state.turn, "action": "countered", "by": nation})
		p["terms"] = counter.duplicate(true)
		p["turn"] = state.turn
		p["expires_turn"] = state.turn + int(cfg(rules).get("valid_turns", 3))
		var old_from := str(p["from"])
		p["from"] = nation
		p["to"] = [old_from]
		state.log_event("diplomatie", "%s contre-propose sur « %s »." % [state.nations[nation]["name_fr"], p["kind"]], [nation])
		return p
	p["status"] = "accepted" if accept else "rejected"
	hist.append({"turn": state.turn, "action": "accepted" if accept else "rejected", "by": nation})
	RelationsSystem.record(state, nation, str(p["from"]), "proposal_accepted" if accept else "proposal_rejected", p["kind"], rules)
	state.log_event("diplomatie", "%s %s « %s » de %s." % [
		state.nations[nation]["name_fr"], "accepte" if accept else "refuse", p["kind"],
		state.nations[str(p["from"])]["name_fr"]], [nation, str(p["from"])])
	return p


static func withdraw(state: GameState, order: Dictionary) -> void:
	var p := by_id(state, str(order.get("proposal", "")))
	if p.is_empty():
		return
	p["status"] = "withdrawn"
	(p["history"] as Array).append({"turn": state.turn, "action": "withdrawn", "by": order["nation"]})


static func expire(state: GameState) -> void:
	for p: Dictionary in state.proposals:
		if str(p["status"]) == "pending" and state.turn > int(p.get("expires_turn", 9999)):
			p["status"] = "expired"
			(p["history"] as Array).append({"turn": state.turn, "action": "expired", "by": "system"})


static func message(state: GameState, order: Dictionary) -> void:
	var to: Variant = order.get("to", [])
	var recipients: Array = to if to is Array else [to]
	state.messages.append({"turn": state.turn, "channel": order.get("channel", "public"),
		"from": order["nation"], "to": recipients.duplicate(true), "text": str(order.get("text", ""))})


static func visible_messages(state: GameState, nation: String) -> Array:
	return state.messages.filter(func(m: Dictionary) -> bool:
		return str(m["channel"]) == "public" or str(m["from"]) == nation or (m["to"] as Array).has(nation))


static func pending_for(state: GameState, nation: String) -> Array:
	return state.proposals.filter(func(p: Dictionary) -> bool:
		return str(p["status"]) == "pending" and (p["to"] as Array).has(nation))
