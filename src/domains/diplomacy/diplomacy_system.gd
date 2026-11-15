class_name DiplomacySystem
extends RefCounted
## Fondations diplomatiques : traités, propositions et réponses, ruptures, déclarations de
## guerre, canaux de communication (public, privé, groupe), mémoire des engagements.
## VALIDÉ : passage en territoire étranger accordé par accord (dossier §5.3).
## OUVERT (DIP-01/02) : conditions de formation et effets des alliances, garanties, accords
## commerciaux et coalitions. Ces traités sont ENREGISTRÉS sans effet mécanique ; seule
## l'autorisation de passage a un effet, celui-là validé.


static func validate(state: GameState, order: Dictionary) -> String:
	var nation: String = order["nation"]
	match order["type"]:
		Orders.DECLARE_WAR:
			var target: String = order.get("target", "")
			if not state.nations.has(target) or target == nation:
				return "cible invalide"
			if state.at_war(nation, target):
				return "déjà en guerre"
		Orders.PROPOSE_TREATY:
			if not Orders.TREATY_KINDS.has(order.get("kind", "")):
				return "type de traité inconnu"
			if not state.nations.has(order.get("to", "")) or order["to"] == nation:
				return "destinataire invalide"
			if order["kind"] != "peace" and state.at_war(nation, order["to"]):
				return "impossible en guerre (seule la paix peut être proposée)"
			if order["kind"] == "peace" and not state.at_war(nation, order["to"]):
				return "pas en guerre"
		Orders.RESPOND_PROPOSAL:
			var p := _proposal(state, order.get("proposal", ""))
			if p.is_empty() or p["to"] != nation:
				return "proposition inconnue ou non adressée à ce pays"
		Orders.BREAK_TREATY:
			var t := _treaty(state, order.get("treaty", ""))
			if t.is_empty() or not (t["members"] as Array).has(nation) or t["status"] != "active":
				return "traité inconnu, inactif ou dont ce pays n'est pas membre"
		Orders.SEND_MESSAGE:
			if not Orders.CHANNELS.has(order.get("channel", "")):
				return "canal inconnu"
	return ""


## Résolution diplomatique du tour (avant les mouvements ; ordre des phases PROPOSÉ, TURN-01 ouvert).
static func resolve(state: GameState, orders: Array) -> void:
	for order: Dictionary in orders:
		match order["type"]:
			Orders.SEND_MESSAGE:
				state.messages.append({"turn": state.turn, "channel": order["channel"], "from": order["nation"],
					"to": order["to"], "text": order["text"]})
			Orders.BREAK_TREATY:
				_break(state, order)
	for order: Dictionary in orders:
		if order["type"] == Orders.RESPOND_PROPOSAL:
			_respond(state, order)
	for order: Dictionary in orders:
		if order["type"] == Orders.PROPOSE_TREATY:
			var pid := state.new_id("proposal")
			state.proposals.append({"id": pid, "turn": state.turn, "from": order["nation"], "to": order["to"],
				"kind": order["kind"], "status": "pending"})
			state.log_event("diplomatie", "%s propose « %s » à %s." % [_n(state, order["nation"]), order["kind"], _n(state, order["to"])],
				[order["nation"], order["to"]])
	for order: Dictionary in orders:
		if order["type"] == Orders.DECLARE_WAR and not state.at_war(order["nation"], order["target"]):
			state.wars.append({"id": state.new_id("war"), "a": order["nation"], "b": order["target"], "since_turn": state.turn})
			state.log_event("guerre", "%s déclare la guerre à %s." % [_n(state, order["nation"]), _n(state, order["target"])],
				[order["nation"], order["target"]])
			for nid: String in state.nation_order:
				state.remember(nid, order["nation"], "declared_war", order["target"])


static func _respond(state: GameState, order: Dictionary) -> void:
	var p := _proposal(state, order["proposal"])
	if p.is_empty() or p["status"] != "pending":
		return
	p["status"] = "accepted" if order["accept"] else "rejected"
	state.remember(p["from"], p["to"], "proposal_" + p["status"], p["kind"])
	if not order["accept"]:
		state.log_event("diplomatie", "%s refuse « %s » proposé par %s." % [_n(state, p["to"]), p["kind"], _n(state, p["from"])], [p["from"], p["to"]])
		return
	if p["kind"] == "peace":
		state.wars = state.wars.filter(func(w: Dictionary) -> bool:
			return not ((w["a"] == p["from"] and w["b"] == p["to"]) or (w["a"] == p["to"] and w["b"] == p["from"])))
		state.log_event("paix", "Paix entre %s et %s (conditions : OUVERTES)." % [_n(state, p["from"]), _n(state, p["to"])], [p["from"], p["to"]])
		return
	var treaty := {"id": state.new_id("treaty"), "type": p["kind"], "members": [p["from"], p["to"]], "status": "active",
		"signed": state.date_label(), "terms": null, "terms_status": "OUVERTE (DIP-02)"}
	if p["kind"] == "transit":
		treaty["grantor"] = p["to"]
		treaty["grantee"] = p["from"]
		treaty["terms_status"] = "VALIDÉ : autorise le passage de %s sur le territoire de %s" % [p["from"], p["to"]]
	state.treaties.append(treaty)
	state.remember(p["to"], p["from"], "treaty_signed", p["kind"])
	state.log_event("diplomatie", "%s et %s signent : %s." % [_n(state, p["from"]), _n(state, p["to"]), p["kind"]], [p["from"], p["to"]])


static func _break(state: GameState, order: Dictionary) -> void:
	var t := _treaty(state, order["treaty"])
	if t.is_empty() or t["status"] != "active":
		return
	t["status"] = "broken"
	t["broken_by"] = order["nation"]
	t["broken_turn"] = state.turn
	for member: String in t["members"]:
		if member != order["nation"]:
			state.remember(member, order["nation"], "treaty_broken", t["id"])
	state.log_event("diplomatie", "%s rompt le traité %s (%s)." % [_n(state, order["nation"]), t["id"], t["type"]], t["members"])


## Messages visibles par une nation : publics, ceux qu'elle envoie et ceux qui lui sont adressés.
static func visible_messages(state: GameState, nation: String) -> Array:
	return state.messages.filter(func(m: Dictionary) -> bool:
		return m["channel"] == "public" or m["from"] == nation or (m["to"] as Array).has(nation))


static func pending_for(state: GameState, nation: String) -> Array:
	return state.proposals.filter(func(p: Dictionary) -> bool: return p["to"] == nation and p["status"] == "pending")


static func _proposal(state: GameState, pid: String) -> Dictionary:
	for p: Dictionary in state.proposals:
		if p["id"] == pid:
			return p
	return {}


static func _treaty(state: GameState, tid: String) -> Dictionary:
	for t: Dictionary in state.treaties:
		if t["id"] == tid:
			return t
	return {}


static func _n(state: GameState, nid: String) -> String:
	return state.nations[nid]["name_fr"]
