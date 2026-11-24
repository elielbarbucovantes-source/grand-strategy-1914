class_name MarketSystem
extends RefCounted
## Phase V.F/H + RESTORATION 02 — commerce entre États via les réseaux de Phase IV.
## Une expédition retire le stock de l'exportateur immédiatement, paie l'exportateur, engage
## la capacité du réseau et ne crédite l'importateur qu'après le délai de transport.
## Le chemin réellement emprunté est conservé dans l'expédition : une livraison ne peut pas
## être certifiée sans traversée effective du réseau. Aucune duplication, aucune livraison
## instantanée, aucune ressource gratuite.


static func cfg(rules: Dictionary) -> Dictionary:
	var model: Dictionary = rules.get("economy_model", {})
	var c: Variant = model.get("trade")
	if not (c is Dictionary):
		c = rules.get("trade", {})
	return c if c is Dictionary else {}


static func unit_price(res: String, rules: Dictionary) -> float:
	var c := cfg(rules)
	var prices: Dictionary = c.get("prices", {})
	return float(prices.get(res, c.get("default_price", 1.0)))


## RESTORATION 02 — prix effectif : un accord commercial actif ouvre un tarif préférentiel.
static func effective_price(state: GameState, res: String, rules: Dictionary, from: String, to: String) -> float:
	var price := unit_price(res, rules)
	var c := cfg(rules)
	var discount := float(c.get("preferred_partner_discount", 0.1))
	var preferred := state.active_treaties_between(from, to, "trade")
	preferred.append_array(state.active_treaties_between(from, to, "transit"))
	if not preferred.is_empty():
		price *= maxf(0.0, 1.0 - discount)
	return price


static func _arrived_this_turn(state: GameState, nation: String) -> int:
	var n := 0
	for t: Dictionary in state.economy["trade"]:
		if str(t["to"]) == nation and int(t["turn"]) == state.turn:
			n += 1
	return n


## Itinéraire commercial réel (capitales). Conservé dans l'expédition pour auditabilité.
static func route_for(state: GameState, net: TransportNetwork, rules: Dictionary, order: Dictionary,
		cache: Dictionary = {}) -> Dictionary:
	var from := str(order.get("from", order.get("nation", "")))
	var to := str(order.get("to", ""))
	var key := str(state.turn) + "|" + from + "|" + to
	if cache.has(key):
		return cache[key]
	var cap := str(state.nations[from].get("capital_region_id", ""))
	var dest := str(state.nations[to].get("capital_region_id", ""))
	var r := TransportRouter.route(net, state, cap, dest, from, 1)
	cache[key] = r
	return r


## STABILIZATION 01 — consentement commercial authentifié.
## L'exportateur crée un engagement dans l'état ; la transaction ne peut être exécutée que
## si un engagement ACTIF correspond EXACTEMENT aux parties, ressource, quantité et prix.
static func open_transaction(state: GameState, order: Dictionary, rules: Dictionary) -> String:
	var from := str(order.get("nation", ""))
	var to := str(order.get("to", ""))
	var res := str(order.get("resource", ""))
	var amount := float(order.get("amount", 0))
	if not state.nations.has(from) or not state.nations.has(to) or from == to:
		return "parties commerciales invalides"
	if amount <= 0.0:
		return "volume non positif"
	var id := str(order.get("transaction", "")) if str(order.get("transaction", "")) != "" else state.new_id("commerce")
	var price := effective_price(state, res, rules, from, to)
	var consents: Dictionary = state.economy["trade_consents"]
	consents[id] = {"id": id, "from": from, "to": to, "resource": res, "amount": amount,
		"price": price, "turn": state.turn, "expires_turn": state.turn + int(cfg(rules).get("consent_valid_turns", 6)),
		"status": "pending", "executed": false}
	return id


static func approve_transaction(state: GameState, transaction: String, nation: String, rules: Dictionary) -> String:
	var consents: Dictionary = state.economy["trade_consents"]
	if not consents.has(transaction):
		return "transaction inconnue"
	var c: Dictionary = consents[transaction]
	if str(c["from"]) != nation:
		return "seul l'exportateur peut consentir"
	if str(c["status"]) != "pending":
		return "transaction déjà traitée"
	if state.turn > int(c["expires_turn"]):
		c["status"] = "expired"
		return "transaction expirée"
	c["status"] = "approved"
	return ""


static func _consent_error(state: GameState, order: Dictionary, rules: Dictionary) -> String:
	var tid := str(order.get("transaction", ""))
	if tid == "":
		return "consentement absent"
	var consents: Dictionary = state.economy["trade_consents"]
	if not consents.has(tid):
		return "consentement falsifié ou inconnu"
	var c: Dictionary = consents[tid]
	if str(c.get("status", "")) != "approved":
		return "consentement non approuvé"
	if bool(c.get("executed", false)):
		return "transaction déjà exécutée"
	if state.turn > int(c.get("expires_turn", 0)):
		return "consentement expiré"
	var from := str(order.get("from", order.get("nation", "")))
	if str(order.get("nation", "")) != from or str(c.get("from", "")) != from:
		return "exportateur non authentifié"
	if str(c.get("to", "")) != str(order.get("to", "")):
		return "partenaire non conforme à l'accord"
	if str(c.get("resource", "")) != str(order.get("resource", "")):
		return "ressource non conforme à l'accord"
	if float(order.get("amount", 0)) > float(c.get("amount", 0)) + 0.000001:
		return "quantité supérieure à celle acceptée"
	var expected := float(c.get("price", 0.0)) * float(order.get("amount", 0))
	var paid := effective_price(state, str(order.get("resource", "")), rules, from, str(order.get("to", ""))) * float(order.get("amount", 0))
	if not is_equal_approx(expected, paid):
		return "prix non conforme à l'accord"
	return ""


## Validation d'une DEMANDE d'achat : aucune ressource n'est débitée ici ; le consentement
## sera vérifié au moment de l'expédition par l'exportateur.
static func validate_request(state: GameState, net: TransportNetwork, rules: Dictionary,
		order: Dictionary, cache: Dictionary = {}) -> String:
	var to := str(order.get("nation", ""))
	var terms: Dictionary = order.get("terms", {})
	var from := str((order["to"] as Array)[0])
	var res := str(terms.get("resource", ""))
	var amount := float(terms.get("amount", 0))
	if not state.nations.has(from) or not state.nations.has(to) or from == to or amount <= 0.0:
		return "demande commerciale invalide"
	if ResourceSystem.available(state, from, res) < amount:
		return "stock insuffisant chez l'exportateur"
	if not (state.economy.get("resources", []) as Array).has(res) and not ((rules.get("economy_model", {}) as Dictionary).get("resources", []) as Array).has(res):
		return "ressource inconnue"
	var fake := {"nation": from, "from": from, "to": to, "resource": res, "amount": amount}
	return validate_core(state, net, rules, fake, cache)


static func validate_core(state: GameState, net: TransportNetwork, rules: Dictionary,
		order: Dictionary, cache: Dictionary = {}) -> String:
	var from := str(order.get("from", order.get("nation", "")))
	var to := str(order.get("to", ""))
	var res := str(order.get("resource", ""))
	var amount := float(order.get("amount", 0))
	if not state.nations.has(from) or not state.nations.has(to) or from == to:
		return "parties commerciales invalides"
	if amount <= 0.0:
		return "volume non positif"
	if not (state.economy.get("resources", []) as Array).has(res) and not ((rules.get("economy_model", {}) as Dictionary).get("resources", []) as Array).has(res):
		return "ressource inconnue"
	if ResourceSystem.available(state, from, res) < amount:
		return "stock insuffisant chez l'exportateur"
	if state.at_war(from, to):
		return "commerce impossible en guerre sans accord"
	var cfg := cfg(rules)
	var imports := _arrived_this_turn(state, to)
	if imports >= int(cfg.get("max_imports_per_nation_per_month", 6)):
		return "quota d'importations atteint"
	var cost := effective_price(state, res, rules, from, to) * amount
	var buyer: Dictionary = state.economy["stocks"].get(to, {})
	if float(buyer.get("money", 0.0)) + 0.000001 < cost:
		return "fonds insuffisants pour l'importation"
	if bool(cfg.get("require_transport_route", true)):
		var r := route_for(state, net, rules, order, cache)
		if not bool(r.get("ok", false)):
			return "aucun itinéraire commercial disponible"
	return ""


static func validate(state: GameState, net: TransportNetwork, rules: Dictionary, order: Dictionary,
		cache: Dictionary = {}) -> String:
	var consent_err := _consent_error(state, order, rules)
	if consent_err != "":
		return consent_err
	return validate_core(state, net, rules, order, cache)


static func propose(state: GameState, net: TransportNetwork, rules: Dictionary, order: Dictionary) -> String:
	# Un seul calcul de route, AVANT toute modification d'état.
	var route_cache: Dictionary = {}
	var err := validate(state, net, rules, order, route_cache)
	if err != "":
		return err
	var r: Dictionary = route_for(state, net, rules, order, route_cache)
	if not bool(r.get("ok", false)):
		return "itinéraire devenu indisponible"
	var cfg := cfg(rules)
	var from := str(order.get("from", order.get("nation", "")))
	var to := str(order["to"])
	var res := str(order["resource"])
	var amount := float(order["amount"])
	var cost := effective_price(state, res, rules, from, to) * amount
	# Paiement réel : la trésorerie de l'importateur alimente celle de l'exportateur.
	var buyer: Dictionary = state.economy["stocks"][to]
	var seller: Dictionary = state.economy["stocks"][from]
	buyer["money"] = float(buyer.get("money", 0.0)) - cost
	seller["money"] = float(seller.get("money", 0.0)) + cost
	ResourceSystem.consume(state, from, res, amount)  # retiré du stock dès l'expédition
	# STABILIZATION 01 : verrou anti-réexécution — une transaction signée ne sert qu'une fois.
	var tid := str(order.get("transaction", ""))
	if tid != "" and (state.economy["trade_consents"] as Dictionary).has(tid):
		(state.economy["trade_consents"][tid] as Dictionary)["executed"] = true
	# RESTORATION 02 : route réelle conservée et capacité effectivement engagée.
	var need := maxi(1, int(ceil(amount * float(cfg.get("route_capacity_share", 0.25)))))
	var committed := TransportRouter.commit(net, state, r, need)
	if not committed:
		# Restaurer les fonds et le stock : aucun prélèvement sans livraison possible.
		buyer["money"] = float(buyer.get("money", 0.0)) + cost
		seller["money"] = float(seller.get("money", 0.0)) - cost
		ResourceSystem.release_reserved(state, from, res, amount)
		return "capacité de transport insuffisante"
	(state.economy["trade"] as Array).append({
		"id": state.new_id("trade"), "turn": state.turn, "from": from, "to": to,
		"resource": res, "amount": amount, "cost": cost,
		"arrival_turn": state.turn + int(cfg.get("transfer_months", 1)),
		"status": "in_transit", "path": (r.get("path", []) as Array).duplicate(),
		"links": (r.get("links", []) as Array).duplicate(),
		"modes": (r.get("modes", []) as Array).duplicate(),
		"route_time": float(r.get("time", 0.0)), "bottleneck": str(r.get("bottleneck", "")),
		"capacity_committed": need if committed else 0, "delays": 0
	})
	state.log_event("commerce", "%s expédie %.1f %s vers %s via %d liaison(s) (coût %.1f)." % [
		state.nations[from]["name_fr"], amount, res, state.nations[to]["name_fr"],
		(r.get("links", []) as Array).size(), cost], [from, to])
	return ""


static func _route_interrupted(state: GameState, t: Dictionary) -> bool:
	var cond: Dictionary = state.transport.get("conditions", {})
	for lid: String in (t.get("links", []) as Array):
		if str(cond.get(lid, "operational")) != "operational":
			return true
	return false


static func monthly(state: GameState, rules: Dictionary = {}) -> void:
	var cfg := cfg(rules)
	var arrived := 0.0
	for t: Dictionary in state.economy["trade"]:
		if str(t["status"]) != "in_transit" or state.turn < int(t["arrival_turn"]):
			continue
		# RESTORATION 02 : une interruption du réseau retarde la livraison, elle n'est pas
		# créditée tant que le chemin n'a pas été réellement praticable.
		if _route_interrupted(state, t):
			t["arrival_turn"] = int(t["arrival_turn"]) + maxi(1, int(cfg.get("delay_on_interrupted_link", 1)))
			t["delays"] = int(t.get("delays", 0)) + 1
			state.log_event("commerce", "Livraison retardée (%s → %s) : liaison interrompue." % [
				str(t["from"]), str(t["to"])], [str(t["from"]), str(t["to"])])
			continue
		var dest: Dictionary = state.economy["stocks"][str(t["to"])]
		var res := str(t["resource"])
		dest[res] = float(dest.get(res, 0.0)) + float(t["amount"])
		t["status"] = "delivered"
		t["delivered_turn"] = state.turn
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


## Volume importé en provenance d'un partenaire donné (hors expéditions livrées).
static func dependence_on(state: GameState, nation: String, partner: String) -> float:
	var total := 0.0
	for t: Dictionary in state.economy["trade"]:
		if str(t["to"]) == nation and str(t["from"]) == partner and str(t["status"]) == "in_transit":
			total += float(t["amount"])
	return total
