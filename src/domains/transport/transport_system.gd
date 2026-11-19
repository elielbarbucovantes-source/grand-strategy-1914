class_name TransportSystem
extends RefCounted
## Phase IV — ordres d'exploitation des infrastructures. Un État ne peut agir que sur une
## liaison ou un port qu'il contrôle (ou dont il contrôle une extrémité). Aucune destruction
## détaillée : seulement des états stratégiques (dégradé / interrompu / en réparation).


static func controls(state: GameState, nation: String, a: String, b: String = "") -> bool:
	if state.controller(a) == nation:
		return true
	return b != "" and state.controller(b) == nation


static func validate(state: GameState, net: TransportNetwork, order: Dictionary) -> String:
	if net == null:
		return "réseau non chargé"
	var nation := str(order["nation"])
	match str(order["type"]):
		Orders.DISRUPT_LINK:
			var l: Dictionary = net.links.get(str(order.get("link", "")), {})
			if l.is_empty():
				return "liaison inconnue"
			if not controls(state, nation, str(l["a"]), str(l["b"])) \
				and not (str(l.get("owner", "")) == state.nations[nation]["name_fr"]):
				return "liaison hors de contrôle"
			if not ["degraded", "interrupted"].has(str(order.get("condition", ""))):
				return "état invalide"
		Orders.REPAIR_LINK:
			var l: Dictionary = net.links.get(str(order.get("link", "")), {})
			if l.is_empty():
				return "liaison inconnue"
			if not controls(state, nation, str(l["a"]), str(l["b"])):
				return "liaison hors de contrôle"
			if TransportNetwork.condition(state, str(order["link"])) == "operational":
				return "liaison déjà opérationnelle"
		Orders.SET_PORT_STATUS:
			var p: Dictionary = net.ports.get(str(order.get("port", "")), {})
			if p.is_empty():
				return "port inconnu"
			if not controls(state, nation, str(p["region_id"])):
				return "port hors de contrôle"
			if not ["operational", "degraded", "interrupted"].has(str(order.get("status", ""))):
				return "état de port invalide"
	return ""


static func apply(state: GameState, net: TransportNetwork, order: Dictionary) -> void:
	match str(order["type"]):
		Orders.DISRUPT_LINK:
			TransportNetwork.set_condition(state, str(order["link"]), str(order["condition"]), order["nation"])
		Orders.REPAIR_LINK:
			TransportNetwork.begin_repair(state, str(order["link"]), int(order.get("turns", 2)))
		Orders.SET_PORT_STATUS:
			var p: Dictionary = net.ports[str(order["port"])].duplicate(true)
			p["status"] = str(order["status"])
			net.ports[str(order["port"])] = p
			state.log_event("transport", "Port %s : %s." % [p["name_fr"], p["status"]], [order["nation"]])
