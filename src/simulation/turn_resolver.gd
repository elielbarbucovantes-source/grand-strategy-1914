class_name TurnResolver
extends RefCounted
## Résolution simultanée d'un mois (VALIDÉ : ordres secrets, résolution simultanée).
## Ordre des phases PROPOSÉ (TURN-01 ouvert) : validation → diplomatie → industrie →
## mouvements simultanés → batailles (toutes closes avant le tour suivant, T-029) →
## logistique → calendrier. Chaque ordre est journalisé (rejeu et multijoueur).


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
	DiplomacySystem.resolve(state, accepted)
	for order: Dictionary in accepted:
		if order["type"] == Orders.SET_INDUSTRY_ALLOCATION:
			EconomySystem.apply_allocation(state, order)
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
	var battles := BattleSystem.create_battles(state, clashes)
	BattleSystem.resolve_all(state, world, rules, battles)
	LogisticsSystem.update_supply(state, world)
	state.pending_orders = {}
	var finished := state.date_label()
	var nxt := GameCalendar.next(state.year, state.month)
	state.year = nxt.x
	state.month = nxt.y
	state.turn += 1
	return {"resolved_month": finished, "accepted": accepted.size(), "rejected": rejected, "battles": battles.size()}


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
		Orders.DECLARE_WAR, Orders.PROPOSE_TREATY, Orders.RESPOND_PROPOSAL, Orders.BREAK_TREATY, Orders.SEND_MESSAGE:
			return DiplomacySystem.validate(state, order)
	return "type d'ordre inconnu"
