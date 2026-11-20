class_name TurnResolver
extends RefCounted
## Résolution simultanée d'un mois (VALIDÉ : ordres secrets, résolution simultanée).
## Ordre des phases PROPOSÉ (TURN-01 ouvert) : validation → diplomatie → industrie et défenses →
## mouvements simultanés → création des batailles tactiques (et sièges des armées encerclées) →
## résolution immédiate des batailles sans joueur humain ; celles d'un joueur restent actives et
## doivent être jouées ou résolues avant le tour suivant (T-029 A) → travaux défensifs,
## encerclement, moral → mobilisation (incorporation puis appel) → logistique → calendrier. Chaque ordre est journalisé.


## `orders_by_nation` : nation -> Array d'ordres. Les ordres invalides sont rejetés et journalisés.
static func resolve(state: GameState, world: WorldMap, rules: Dictionary, orders_by_nation: Dictionary) -> Dictionary:
	var accepted: Array = []
	var rejected: Array = []
	for nid: String in state.nation_order:
		for order: Dictionary in orders_by_nation.get(nid, []):
			if order.get("nation", "") != nid:
				rejected.append({"order": order, "reason": "ordre émis au nom d'un autre pays"})
				continue
			var reason := _validate(state, world, rules, order)
			if reason == "":
				accepted.append(order)
			else:
				rejected.append({"order": order, "reason": reason})
	state.orders_history.append({"turn": state.turn, "date": state.date_label(), "orders": accepted.duplicate(true),
		"rejected": rejected.duplicate(true)})
	DiplomacySystem.resolve(state, accepted, rules)
	for order: Dictionary in accepted:
		if order["type"] == Orders.SET_INDUSTRY_ALLOCATION:
			EconomySystem.apply_allocation(state, order)
		elif order["type"] == Orders.BUILD_DEFENSE and rules.has("combat"):
			DefenseSystem.apply_order(state, rules["combat"], order)
		elif order["type"] in [Orders.MOBILIZE, Orders.SET_MOBILIZATION_POSTURE, Orders.SET_MOBILIZATION_ALLOCATION, Orders.CALL_NEXT_ECHELON]:
			if rules.has("forces"):
				MobilizationSystem.apply_order(state, world, rules["forces"]["mobilization"], order)
		elif order["type"] == Orders.TERRITORIAL_OVERSEAS and rules.has("forces"):
			TerritorialForce.apply_overseas(state, rules["forces"], order)
		elif order["type"] == Orders.SET_DEFENSIVE_POSTURE:
			state.formations[order["army"]]["defensive_posture"] = order["posture"]  # avant les batailles du mois
		elif order["type"] in [Orders.DISRUPT_LINK, Orders.REPAIR_LINK, Orders.SET_PORT_STATUS]:
			TransportSystem.apply(state, rules.get("transport_network"), order)
		elif order["type"] == Orders.TRADE:
			MarketSystem.propose(state, rules.get("transport_network"), rules, order)
		elif order["type"] == Orders.INVEST_RESOURCE:
			ResourceSystem.invest(state, str(order["region"]), str(order["resource"]), float(order["amount"]))
		elif order["type"] == Orders.SET_RESEARCH:
			TechSystem.start_project(state, order["nation"], str(order["tech"]))
		elif order["type"] == Orders.SET_COMMS_PROTECTION:
			CommunicationsSystem.ensure(state, order["nation"])
			state.tech["comms"][order["nation"]]["protection"] = mini(int(order.get("level", 1)), 4)
		elif order["type"] == Orders.INTERCEPT:
			var seed: int = state.turn * 97 + str(order["nation"]).length() * 13 + str(order["target"]).length()
			CommunicationsSystem.attempt_intercept(state, rules.get("tech_tree"), order["nation"],
				str(order["target"]), rules.get("phase6", {}), seed)
		elif order["type"] == Orders.BUILD_AIRBASE:
			AirSystem.build_base(state, order["nation"], str(order["region"]), rules)
		elif order["type"] == Orders.PRODUCE_AIRCRAFT:
			AirSystem.produce(state, order["nation"], str(order["kind"]), int(order["amount"]), rules)
		elif order["type"] == Orders.AIR_RECON:
			AirSystem.reconnaissance(state, rules.get("tech_tree"), order["nation"], str(order["region"]), rules)
		elif order["type"] == Orders.CREATE_FLEET:
			NavalSystem.create_fleet(state, order["nation"], str(order["port"]), order["composition"], rules)
		elif order["type"] == Orders.NAVAL_OPERATION:
			NavalSystem.operation(state, order["nation"], str(order["fleet"]), str(order["kind"]),
				str(order["zone"]), rules.get("phase6", {}))
		elif order["type"] == Orders.POLITICAL_DECISION:
			PoliticalSystem.apply_decision(state, order["nation"], str(order["kind"]), rules.get("phase7", {}))
		elif order["type"] == Orders.CHANGE_GOVERNMENT:
			PoliticalSystem.change_government(state, order["nation"], str(order["kind"]), rules.get("phase7", {}))
		elif order["type"] == Orders.SET_BRIDGE_STATUS:
			CrossingSystem.set_status(state, str(order["bridge"]), str(order["status"]))
		elif order["type"] == Orders.MP_SETUP:
			MultiplayerSystem.setup(state, order["players"], rules.get("phase7", {}))
		elif order["type"] == Orders.MP_SUBMIT_ORDER:
			MultiplayerSystem.submit_order(state, order["nation"], order["order"], rules.get("phase7", {}))
		elif order["type"] == Orders.MP_DISCONNECT:
			MultiplayerSystem.disconnect_player(state, order["nation"])
		elif order["type"] == Orders.MP_RECONNECT:
			MultiplayerSystem.reconnect_player(state, order["nation"])
	# Les mouvements sont revalidés après la diplomatie (une déclaration de guerre du même
	# tour peut autoriser l'entrée ; une paix peut l'interdire). Une formation = un ordre.
	var moves: Array = []
	var moved: Dictionary = {}
	for order: Dictionary in accepted:
		if order["type"] == Orders.MOVE and not moved.has(order["formation"]):
			var reason := MilitarySystem.validate_move(state, world, rules, order)
			if reason == "":
				moves.append(order)
				moved[order["formation"]] = true
			else:
				rejected.append({"order": order, "reason": reason})
	var clashes := MilitarySystem.resolve_moves(state, world, rules, moves)
	clashes.append_array(_siege_clashes(state, clashes))
	var neutral: Array = []
	var tactical := 0
	for clash: Dictionary in clashes:
		var b: Dictionary = BattleManager.create(state, world, rules, rules["combat"], clash) if rules.has("combat") else {}
		if b.is_empty():
			neutral.append(clash)  # effectifs inconnus (campagne, MIL-01) : repli neutre documenté
		else:
			state.active_battles.append(b)
			tactical += 1
	var battles := BattleSystem.create_battles(state, neutral)
	BattleSystem.resolve_all(state, world, rules, battles)
	for b: Dictionary in BattleManager.queue(state):
		if (b["humans"] as Array).is_empty():
			BattleManager.run_to_end(b, rules["combat"], true)
			BattleManager.finish(state, world, rules["combat"], b)
	if rules.has("combat"):
		DefenseSystem.monthly(state, world, rules["combat"])
		BattleManager.monthly_encirclement(state, world, rules["combat"])
		BattleManager.monthly_morale(state, rules["combat"])
	DiplomacySystem.monthly(state, rules)  # Phase III : expiration, relations, crises, alliances
	if rules.has("forces"):
		MobilizationSystem.monthly(state, world, rules["forces"])
		ForceLedger.monthly_recovery(state, world, rules["forces"])  # fin de convalescence (phase 6, étape 1)
		ForceLedger.heal_lightly_wounded(state)  # blessés légers restés dans leur unité (étape 2)
	EconomySystem.monthly(state, world, rules, rules.get("economy_model", {}))  # Phase V : cycle économique
	TechSystem.monthly(state, rules.get("tech_tree"), rules.get("phase6", {}))  # Phase VI : recherche
	for nid: String in state.nation_order:
		AirSystem.monthly(state, nid, rules.get("phase6", {}))
		NavalSystem.monthly(state, nid)
	TransportNetwork.release_month(state)  # Phase IV : flux de capacité mensuel
	LogisticsSystem.update_supply(state, world, rules)
	state.pending_orders = {}
	var finished := state.date_label()
	var nxt := GameCalendar.next(state.year, state.month)
	state.year = nxt.x
	state.month = nxt.y
	state.turn += 1
	return {"resolved_month": finished, "accepted": accepted.size(), "rejected": rejected,
		"battles": battles.size() + tactical, "pending_battles": state.active_battles.size()}


## Armées encerclées au contact d'armées ennemies : elles continuent de combattre (T-044).
static func _siege_clashes(state: GameState, existing: Array) -> Array:
	var out: Array = []
	var taken: Array = existing.map(func(c: Dictionary) -> String: return c["region"])
	var ids := state.regions.keys()
	ids.sort()
	for rid: String in ids:
		if taken.has(rid):
			continue
		var encircled: Array = []
		var besiegers: Array = []
		for army: Dictionary in state.armies_in(rid):
			if army.get("encircled", false):
				encircled.append(army["id"])
		if encircled.is_empty():
			continue
		var victim: String = state.formations[encircled[0]]["nation"]
		for army: Dictionary in state.armies_in(rid):
			if state.at_war(army["nation"], victim) and not army.get("encircled", false):
				besiegers.append(army["id"])
		if not besiegers.is_empty():
			var origin: Dictionary = {}
			for a: String in besiegers + encircled:
				origin[a] = rid
			out.append({"region": rid, "attackers": besiegers, "defenders": encircled, "origin": origin})
	return out


static func _validate(state: GameState, world: WorldMap, rules: Dictionary, order: Dictionary) -> String:
	match order.get("type", ""):
		Orders.MOVE:
			# Contrôle structurel seulement : la validation complète (souveraineté, guerre,
			# autorisations) a lieu après la phase diplomatique du même tour.
			if not state.formations.has(order.get("formation", "")):
				return "formation inconnue"
			if state.formations[order["formation"]]["nation"] != order["nation"]:
				return "commandement national seulement"
			if not world.has_region(order.get("target", "")):
				return "région inconnue"
			return ""
		Orders.SET_INDUSTRY_ALLOCATION:
			return EconomySystem.validate_allocation(rules, order)
		Orders.BUILD_DEFENSE:
			return DefenseSystem.validate(state, rules["combat"], order) if rules.has("combat") else "règles de combat absentes"
		Orders.MOBILIZE, Orders.SET_MOBILIZATION_POSTURE, Orders.SET_MOBILIZATION_ALLOCATION, Orders.CALL_NEXT_ECHELON:
			return MobilizationSystem.validate(state, order, world, rules.get("forces", {}).get("mobilization", {}))
		Orders.TERRITORIAL_OVERSEAS:
			return TerritorialForce.validate_overseas(state, rules["forces"], order) if rules.has("forces") else "règles des forces absentes"
		Orders.SET_DEFENSIVE_POSTURE:
			return MilitarySystem.validate_posture(state, order)
		Orders.DECLARE_WAR, Orders.PROPOSE_TREATY, Orders.RESPOND_PROPOSAL, Orders.BREAK_TREATY, Orders.SEND_MESSAGE, \
		Orders.PROPOSE_AGREEMENT, Orders.RESPOND_AGREEMENT, Orders.WITHDRAW_PROPOSAL, Orders.PROPOSE_PEACE, \
		Orders.START_CRISIS, Orders.CRISIS_RESPONSE, Orders.OFFER_MEDIATION, Orders.EXCHANGE_POW, \
		Orders.JOIN_ALLIANCE, Orders.LEAVE_ALLIANCE, Orders.DISSOLVE_ALLIANCE, Orders.UNIVERSAL_PACT, Orders.CONCLUDE_CONFERENCE:
			return DiplomacySystem.validate(state, order, rules)
		Orders.DISRUPT_LINK, Orders.REPAIR_LINK, Orders.SET_PORT_STATUS:
			return TransportSystem.validate(state, rules.get("transport_network"), order)
		Orders.TRADE:
			return MarketSystem.validate(state, rules.get("transport_network"), rules, order)
		Orders.INVEST_RESOURCE:
			return ResourceSystem.validate_invest(state, str(order.get("region", "")),
				str(order.get("resource", "")), float(order.get("amount", 0)))
		Orders.SET_RESEARCH:
			return TechSystem.can_research(state, rules.get("tech_tree"), order["nation"], str(order["tech"]))
		Orders.BUILD_AIRBASE, Orders.AIR_RECON:
			if not state.regions.has(str(order.get("region", ""))):
				return "région inconnue"
			return ""
		Orders.PRODUCE_AIRCRAFT, Orders.CREATE_FLEET, Orders.NAVAL_OPERATION, Orders.INTERCEPT, Orders.SET_COMMS_PROTECTION:
			return ""
		Orders.POLITICAL_DECISION:
			var costs: Dictionary = rules.get("phase7", {}).get("politics", {}).get("decisions", {}).get("costs", {})
			return "" if costs.has(str(order.get("kind", ""))) else "décision inconnue"
		Orders.CHANGE_GOVERNMENT:
			return ""
		Orders.SET_BRIDGE_STATUS:
			return "" if state.bridges.has(str(order.get("bridge", ""))) else "franchissement inconnu"
		Orders.MP_SETUP, Orders.MP_SUBMIT_ORDER, Orders.MP_DISCONNECT, Orders.MP_RECONNECT:
			return ""
	return "type d'ordre inconnu"
