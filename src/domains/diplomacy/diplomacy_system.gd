class_name DiplomacySystem
extends RefCounted
## Phase III — point d'entrée unique de la diplomatie. Délègue aux sous-systèmes :
## relations, négociations, alliances, crises, paix et prisonniers.
## Les canaux public/privé/groupe, les traités existants et la mémoire restent compatibles.


static func validate(state: GameState, order: Dictionary, rules: Dictionary = {}) -> String:
	var nation: String = order["nation"]
	match order["type"]:
		Orders.DECLARE_WAR:
			var target: String = order.get("target", "")
			if not state.nations.has(target) or target == nation:
				return "cible invalide"
			if state.at_war(nation, target):
				return "déjà en guerre"
		Orders.PROPOSE_TREATY, Orders.PROPOSE_AGREEMENT:
			return NegotiationSystem.validate(state, order, rules)
		Orders.PROPOSE_PEACE:
			var dest: Variant = order.get("to", order.get("target", ""))
			var recipients: Array = dest if dest is Array else [dest]
			if recipients.is_empty():
				return "destinataire manquant"
			for d: String in recipients:
				if not state.nations.has(d) or d == nation:
					return "destinataire invalide"
				if not state.at_war(nation, d):
					return "pas en guerre avec " + d
		Orders.RESPOND_PROPOSAL, Orders.RESPOND_AGREEMENT, Orders.WITHDRAW_PROPOSAL:
			return NegotiationSystem.validate(state, order, rules)
		Orders.BREAK_TREATY:
			var t := _treaty(state, order.get("treaty", ""))
			if t.is_empty() or not (t["members"] as Array).has(nation) or t["status"] != "active":
				return "traité inconnu, inactif ou dont ce pays n'est pas membre"
		Orders.SEND_MESSAGE:
			if not Orders.CHANNELS.has(order.get("channel", "")):
				return "canal inconnu"
		Orders.START_CRISIS:
			if not state.nations.has(order.get("target", "")) or order["target"] == nation:
				return "cible de crise invalide"
			if str(order.get("motive", "")) == "":
				return "motif manquant"
		Orders.CRISIS_RESPONSE, Orders.OFFER_MEDIATION:
			if CrisisSystem.by_id(state, str(order.get("crisis", ""))).is_empty():
				return "crise inconnue"
		Orders.EXCHANGE_POW:
			if not state.nations.has(order.get("other", "")):
				return "adversaire d'échange inconnu"
		Orders.JOIN_ALLIANCE, Orders.LEAVE_ALLIANCE, Orders.DISSOLVE_ALLIANCE:
			if AllianceSystem.by_id(state, str(order.get("alliance", ""))).is_empty():
				return "alliance inconnue"
		Orders.UNIVERSAL_PACT:
			var mem: Array = order.get("members", [])
			if mem.size() < 2:
				return "membres insuffisants"
		Orders.CONCLUDE_CONFERENCE:
			if ConferenceSystem.by_id(state, str(order.get("conference", ""))).is_empty():
				return "conférence inconnue"
	return ""


## Résolution diplomatique du tour (avant les mouvements).
static func resolve(state: GameState, orders: Array, rules: Dictionary = {}) -> void:
	for order: Dictionary in orders:
		match order["type"]:
			Orders.SEND_MESSAGE:
				NegotiationSystem.message(state, order)
			Orders.BREAK_TREATY:
				_break(state, order, rules)
			Orders.WITHDRAW_PROPOSAL:
				NegotiationSystem.withdraw(state, order)
			Orders.START_CRISIS:
				CrisisSystem.start(state, order["nation"], order["target"], str(order.get("motive", "")),
					str(order.get("stake", "")), rules)
			Orders.CRISIS_RESPONSE:
				CrisisSystem.respond(state, str(order["crisis"]), order["nation"], str(order.get("action", "protest")), rules)
			Orders.OFFER_MEDIATION:
				CrisisSystem.offer_mediation(state, str(order["crisis"]), order["nation"], rules)
			Orders.EXCHANGE_POW:
				PowSystem.exchange(state, order["nation"], order["other"], rules)
			Orders.JOIN_ALLIANCE:
				AllianceSystem.join(state, str(order["alliance"]), order["nation"], rules)
			Orders.LEAVE_ALLIANCE:
				AllianceSystem.leave(state, str(order["alliance"]), order["nation"], rules)
			Orders.DISSOLVE_ALLIANCE:
				AllianceSystem.dissolve(state, str(order["alliance"]), order["nation"])
			Orders.UNIVERSAL_PACT:
				PeaceSystem.universal_pact(state, order["members"], rules)
			Orders.CONCLUDE_CONFERENCE:
				ConferenceSystem.conclude(state, str(order["conference"]), str(order.get("topic", "crisis")), rules)
	# Réponses avant propositions (une réponse peut clore une proposition du même tour).
	for order: Dictionary in orders:
		if order["type"] in [Orders.RESPOND_PROPOSAL, Orders.RESPOND_AGREEMENT]:
			var p := NegotiationSystem.respond(state, order, rules)
			if not p.is_empty() and str(p["status"]) == "accepted":
				_apply_accepted(state, p, rules)
	for order: Dictionary in orders:
		if order["type"] == Orders.PROPOSE_TREATY:
			_legacy_proposal(state, order, rules)
		elif order["type"] == Orders.PROPOSE_AGREEMENT:
			NegotiationSystem.propose(state, order, rules)
		elif order["type"] == Orders.PROPOSE_PEACE:
			PeaceSystem.propose(state, order, rules)
	for order: Dictionary in orders:
		if order["type"] == Orders.DECLARE_WAR and not state.at_war(order["nation"], order["target"]):
			state.wars.append({"id": state.new_id("war"), "a": order["nation"], "b": order["target"], "since_turn": state.turn})
			state.log_event("guerre", "%s déclare la guerre à %s." % [_n(state, order["nation"]), _n(state, order["target"])],
				[order["nation"], order["target"]])
			for nid: String in state.nation_order:
				RelationsSystem.record(state, nid, order["nation"], "declared_war", order["target"], rules)


static func _legacy_proposal(state: GameState, order: Dictionary, rules: Dictionary) -> void:
	if order["kind"] == "peace":
		PeaceSystem.propose(state, order, rules)
		return
	NegotiationSystem.propose(state, {
		"type": Orders.PROPOSE_AGREEMENT, "nation": order["nation"], "to": [order["to"]],
		"kind": order["kind"], "terms": {}, "channel": "private"}, rules)


static func _apply_accepted(state: GameState, p: Dictionary, rules: Dictionary) -> void:
	match str(p["kind"]):
		"peace":
			PeaceSystem.sign(state, p, rules)
		"alliance", "coalition", "guarantee", "transit", "neutrality":
			AllianceSystem.create(state, p, rules)
		"trade":
			AllianceSystem.create(state, p, rules)
			# RESTORATION 03 : une demande d'achat acceptée devient une expédition RÉELLE,
			# émise par l'exportateur après validation économique et logistique. Aucun transfert
			# n'est effectué par l'interface ni sans le consentement du partenaire.
			var terms: Dictionary = p.get("terms", {})
			if str(terms.get("request", "")) == "purchase":
				var exporter := str((p["to"] as Array)[0])
				var importer := str(p["from"])
				var res := str(terms.get("resource", ""))
				var amount := float(terms.get("amount", 0))
				var order := {"type": Orders.TRADE, "nation": exporter, "from": exporter,
					"to": importer, "resource": res, "amount": amount}
				# STABILIZATION 01 : l'acceptation de la proposition vaut consentement de
				# l'exportateur, authentifié par le contexte de simulation.
				var tid := MarketSystem.open_transaction(state, order, rules)
				order["transaction"] = tid
				MarketSystem.approve_transaction(state, tid, exporter, rules)
				var net: TransportNetwork = rules.get("transport_network")
				var err := MarketSystem.validate(state, net, rules, order)
				if err == "":
					MarketSystem.propose(state, net, rules, order)
				else:
					state.log_event("commerce", "Demande d'achat %s → %s (%s %.1f) non exécutée : %s" % [
						importer, exporter, res, amount, err], [importer, exporter])
		"tech":
			TechSystem.register_cooperation(state, p, rules)
		"pow_exchange":
			var to: Array = p["to"]
			if not to.is_empty():
				PowSystem.exchange(state, str(p["from"]), str(to[0]), rules)
		"conference":
			ConferenceSystem.create(state, p, rules)


static func _break(state: GameState, order: Dictionary, rules: Dictionary) -> void:
	var t := _treaty(state, order.get("treaty", ""))
	if t.is_empty() or t["status"] != "active":
		return
	t["status"] = "broken"
	t["broken_by"] = order["nation"]
	t["broken_turn"] = state.turn
	for member: String in t["members"]:
		if member != order["nation"]:
			RelationsSystem.record(state, member, order["nation"], "treaty_broken", t["id"], rules)
	# Une rupture d'alliance active est une trahison enregistrée dans la mémoire de tous.
	for a: Dictionary in state.diplomacy.get("alliances", []):
		if str(a["id"]) == str(t["id"]):
			a["status"] = "broken"
			for member: String in a["members"]:
				if member != order["nation"]:
					RelationsSystem.record(state, member, order["nation"], "alliance_betrayal", str(a["id"]), rules)
	state.log_event("diplomatie", "%s rompt le traité %s (%s)." % [_n(state, order["nation"]), t["id"], t["type"]], t["members"])


## Appel mensuel : expiration des propositions, mise à jour des relations, crises et alliances.
static func monthly(state: GameState, rules: Dictionary) -> void:
	NegotiationSystem.expire(state)
	RelationsSystem.monthly(state, rules)
	CrisisSystem.monthly(state, rules)
	AllianceSystem.monthly(state, rules)


static func visible_messages(state: GameState, nation: String) -> Array:
	return NegotiationSystem.visible_messages(state, nation)


static func pending_for(state: GameState, nation: String) -> Array:
	return NegotiationSystem.pending_for(state, nation)


static func _proposal(state: GameState, pid: String) -> Dictionary:
	return NegotiationSystem.by_id(state, pid)


static func _treaty(state: GameState, tid: String) -> Dictionary:
	for t: Dictionary in state.treaties:
		if str(t["id"]) == tid:
			return t
	return {}


static func _n(state: GameState, nid: String) -> String:
	return str(state.nations[nid]["name_fr"])
