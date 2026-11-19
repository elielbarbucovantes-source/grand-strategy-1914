class_name EconomicAI
extends RefCounted
## Phase V.J — IA économique : priorités par personnalité, réaction aux pénuries, décisions bornées
## et déterministes. Aucune ressource fictive, aucune allocation contradictoire.


static func personality(state: GameState, nid: String, rules: Dictionary) -> Dictionary:
	var model: Dictionary = rules.get("economy_model", {})
	var profiles: Dictionary = model.get("ai", {}).get("personalities", {})
	var id := str(state.economy.get("personalities", {}).get(nid, model.get("ai", {}).get("default_personality", "stability")))
	var p: Variant = profiles.get(id, profiles.get("stability", {}))
	return p if p is Dictionary else {}


static func decide(state: GameState, net: TransportNetwork, rules: Dictionary, nid: String) -> Array:
	var out: Array = []
	var model: Dictionary = rules.get("economy_model", {})
	var p := personality(state, nid, rules)
	var cfg: Dictionary = model.get("ai", {})
	var max_alloc := int(cfg.get("max_allocation_changes_per_month", 1))
	var max_trade := int(cfg.get("max_trade_orders_per_month", 2))
	var current: Dictionary = state.nations[nid].get("industry_allocation", {})
	var target: Dictionary = {}
	# Les catégories VALIDÉES sont celles de game_rules.economy (noms français).
	var mil := float(p.get("military", 0.2))
	var heavy := float(p.get("heavy", 0.2))
	var civ := float(p.get("manufacturing", 0.2)) + float(p.get("agriculture", 0.2))
	var weights := {"industrie_militaire_terrestre": mil + heavy * 0.5,
		"munitions_et_equipements": mil * 0.5 + heavy * 0.3,
		"industrie_civile": civ + 0.1,
		"industrie_aeronautique": heavy * 0.2 + 0.05,
		"industrie_navale": 0.05}
	# Réaction à une pénurie de grain : renforcer l'industrie civile ( transformation agricole ).
	var stocks: Dictionary = state.economy["stocks"].get(nid, {})
	if float(stocks.get("grain", 0.0)) < 10.0:
		weights["industrie_civile"] = float(weights["industrie_civile"]) + 0.2
	var total := 0.0
	for v: float in weights.values():
		total += v
	for cat: String in weights:
		target[cat] = roundf(100.0 * float(weights[cat]) / maxf(0.0001, total))
	var changed := false
	for cat: String in target:
		if absf(float(current.get(cat, -1)) - float(target[cat])) > 2.0:
			changed = true
	if changed and max_alloc > 0:
		out.append({"type": Orders.SET_INDUSTRY_ALLOCATION, "nation": nid, "allocation": target})
	# Commerce : importer la ressource la plus déficitaire depuis un partenaire non belligérant.
	var trade_orders := 0
	var resources: Array = model.get("resources", [])
	resources.sort()
	for res: String in resources:
		if trade_orders >= max_trade:
			break
		if float(stocks.get(res, 0.0)) >= 5.0:
			continue
		var candidates: Array = state.nation_order.duplicate()
		candidates.sort()
		for other: String in candidates:
			if other == nid or state.at_war(nid, other):
				continue
			if float(state.economy["stocks"].get(other, {}).get(res, 0.0)) < 10.0:
				continue
			var order := {"type": Orders.TRADE, "nation": nid, "from": other, "to": nid,
				"resource": res, "amount": 5.0}
			if MarketSystem.validate(state, net, rules, order) == "":
				out.append(order)
				trade_orders += 1
			break
	return out
