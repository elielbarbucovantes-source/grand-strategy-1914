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
	var inv_cfg: Dictionary = (model.get("resources_model", {}) as Dictionary).get("investment", {})
	var max_invest := int(inv_cfg.get("max_investments_per_nation_per_turn", 2))
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
	# RESTORATION 01 — investissement autonome dans l'extraction.
	# Une nation prospère investit davantage ; une nation pauvre limite ses dépenses.
	var funds := float(stocks.get("money", 0.0))
	var focus: Array = []
	if float(p.get("military", 0.2)) >= 0.3:
		focus = ["coal", "iron"]
	elif float(p.get("trade", 0.1)) >= 0.3:
		focus = ["grain", "oil"]
	if funds >= float(inv_cfg.get("money_per_rate_point", 8.0)) and max_invest > 0:
		var choice := ResourceSystem.best_investment(state, nid, model, focus)
		if not choice.is_empty():
			var rate := 0.15
			if float(p.get("heavy", 0.2)) >= 0.28:
				rate = 0.25
			elif funds < 30.0:
				rate = 0.08
			out.append({"type": Orders.INVEST_RESOURCE, "nation": nid,
				"region": choice["region"], "resource": choice["resource"], "amount": rate})
	# RESTORATION 02 — commerce : demande calculée, partenaires fiables, tous les fournisseurs
	# testés (plus de break prématuré). Le profil commercial arbitre davantage, l'autarkique jamais.
	var trade_orders := 0
	var trade_weight := float(p.get("trade", 0.1))
	var trade_cfg: Dictionary = model.get("trade", {})
	var resources: Array = (model.get("resources", []) as Array).duplicate()
	resources.sort()
	var route_cache: Dictionary = {}
	var needs: Array = []
	for res: String in resources:
		var reserve := _reserve(state, nid, res, model, target, current)
		var deficit := reserve - float(stocks.get(res, 0.0))
		if deficit > 1.0 and trade_weight > 0.0:
			needs.append([res, deficit])
	needs.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) > float(b[1]))
	for entry: Array in needs:
		if trade_orders >= max_trade:
			break
		var res := str(entry[0])
		var amount := minf(float(entry[1]) * trade_weight, 8.0)
		if amount < 1.0:
			continue
		# Calculer les scores UNE fois (le tri ne doit pas les recalculer).
		var scored: Array = []
		for cand: String in state.nation_order:
			scored.append([cand, _partner_score(state, nid, cand, res, rules)])
		scored.sort_custom(func(a: Array, b: Array) -> bool:
			if is_equal_approx(float(a[1]), float(b[1])):
				return str(a[0]) < str(b[0])
			return float(a[1]) > float(b[1]))
		for cand_entry: Array in scored:
			var other := str(cand_entry[0])
			if other == nid or state.at_war(nid, other):
				continue
			if float(state.economy["stocks"].get(other, {}).get(res, 0.0)) < amount + 2.0:
				continue
			var order := {"type": Orders.TRADE, "nation": nid, "from": other, "to": nid,
				"resource": res, "amount": amount}
			# Essayer tous les partenaires : un refus de route n'empêche pas le suivant.
			if MarketSystem.validate(state, net, rules, order, route_cache) == "":
				out.append(order)
				trade_orders += 1
				break
	return out


## Réserve stratégique : intrants industriels réels + stock de sécurité. Crée une demande
## récurrente et mesurable, sans inventer de production.
static func _reserve(state: GameState, nid: String, res: String, model: Dictionary,
		allocation: Dictionary, current: Dictionary) -> float:
	var inputs: Dictionary = model.get("industry_model", {}).get("inputs", {})
	var capacity := IndustrySystem.capacity(state, nid)
	var total := 0.0
	for cat: String in inputs:
		total += float(allocation.get(cat, current.get(cat, 0.0)))
	var need := 0.0
	for cat: String in inputs:
		var share := float(allocation.get(cat, current.get(cat, 0.0))) / maxf(1.0, total)
		need += float((inputs[cat] as Dictionary).get(res, 0.0)) * share * capacity
	return need * 3.0 + 5.0


## Préférence de partenaire : confiance, coopération et accords commerciaux existants.
static func _partner_score(state: GameState, nid: String, other: String, res: String, rules: Dictionary) -> float:
	var rel := RelationsSystem.between(state, nid, other, rules)
	var score := float(rel.get("trust", 50)) + float(rel.get("cooperation", 20)) * 0.5
	for t: Dictionary in state.treaties:
		if str(t.get("status", "")) != "active":
			continue
		if (t["members"] as Array).has(nid) and (t["members"] as Array).has(other):
			if str(t.get("kind", "")) in ["trade", "transit", "alliance"]:
				score += 20.0
	return score
