class_name MarketSystem
extends RefCounted
## Phase V.F/H — commerce entre États via les réseaux de Phase IV. Une expédition retire le
## stock de l'exportateur immédiatement et ne le crédite à l'importateur qu'après le délai de
## transport : aucune duplication, aucune livraison instantanée.


static func validate(state: GameState, net: TransportNetwork, rules: Dictionary, order: Dictionary) -> String:
	var from := str(order.get("from", order.get("nation", "")))
	var to := str(order.get("to", ""))
	var res := str(order.get("resource", ""))
	var amount := float(order.get("amount", 0))
	if not state.nations.has(from) or not state.nations.has(to) or from == to:
		return "parties commerciales invalides"
	if amount <= 0.0:
		return "volume non positif"
	if ResourceSystem.available(state, from, res) < amount:
		return "stock insuffisant chez l'exportateur"
	if state.at_war(from, to):
		return "commerce impossible en guerre sans accord"
	var cfg: Dictionary = rules.get("trade", {})
	if bool(cfg.get("require_transport_route", true)):
		var cap := str(state.nations[from].get("capital_region_id", ""))
		var dest := str(state.nations[to].get("capital_region_id", ""))
		var r := TransportRouter.route(net, state, cap, dest, from, 1)
		if not bool(r.get("ok", false)):
			return "aucun itinéraire commercial disponible"
	return ""


static func propose(state: GameState, net: TransportNetwork, rules: Dictionary, order: Dictionary) -> String:
	var err := validate(state, net, rules, order)
	if err != "":
		return err
	var cfg: Dictionary = rules.get("trade", {})
	var from := str(order.get("from", order.get("nation", "")))
	var to := str(order["to"])
	var res := str(order["resource"])
	var amount := float(order["amount"])
	ResourceSystem.consume(state, from, res, amount)  # retiré du stock dès l'expédition
	(state.economy["trade"] as Array).append({
		"id": state.new_id("trade"), "turn": state.turn, "from": from, "to": to,
		"resource": res, "amount": amount,
		"arrival_turn": state.turn + int(cfg.get("transfer_months", 1)),
		"status": "in_transit"
	})
	state.log_event("commerce", "%s expédie %.1f %s vers %s." % [
		state.nations[from]["name_fr"], amount, res, state.nations[to]["name_fr"]], [from, to])
	return ""


static func monthly(state: GameState) -> void:
	var arrived := 0.0
	for t: Dictionary in state.economy["trade"]:
		if str(t["status"]) == "in_transit" and state.turn >= int(t["arrival_turn"]):
			var dest: Dictionary = state.economy["stocks"][str(t["to"])]
			var res := str(t["resource"])
			dest[res] = float(dest.get(res, 0.0)) + float(t["amount"])
			t["status"] = "delivered"
			arrived += float(t["amount"])
	if arrived > 0.0:
		state.log_event("commerce", "Marchandises livrées ce mois : %.1f" % arrived, [])


static func dependencies(state: GameState, nation: String) -> Dictionary:
	var out := {}
	for t: Dictionary in state.economy["trade"]:
		if str(t["to"]) != nation or str(t["status"]) != "in_transit":
			continue
		var res := str(t["resource"])
		out[res] = float(out.get(res, 0.0)) + float(t["amount"])
	return out
