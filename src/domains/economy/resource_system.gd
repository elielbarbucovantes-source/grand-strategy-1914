class_name ResourceSystem
extends RefCounted
## Phase V.C — dépôts, exploitation et stocks. Un dépôt n'est pas un stock : la production
## consomme main-d'œuvre et infrastructure et alimente le stock national, sans double comptage.


static func monthly(state: GameState, rules: Dictionary) -> void:
	var cfg: Dictionary = rules.get("resources_model", {})
	var eco: Dictionary = state.economy
	for nid: String in state.nation_order:
		if not eco["stocks"].has(nid):
			eco["stocks"][nid] = {}
	for rid: String in eco["regions"]:
		var r: Dictionary = eco["regions"][rid]
		var nation := str(r["nation"])
		var stocks: Dictionary = eco["stocks"][nation]
		var infra := float(r.get("industry_capacity", 0.1))
		var miners := float(r.get("sectors", {}).get("mines", 0))
		for res: String in r.get("deposits", {}):
			var deposit := float(r["deposits"][res])
			if deposit <= 0.0:
				continue
			var rate := float(r.get("exploitation", {}).get(res, 0.0))
			var potential := rate * float(cfg.get("investment_effect", 0.15))
			var labor := clampf(miners / maxf(1.0, deposit), 0.0, 1.0) * float(cfg.get("workforce_effect", 0.5))
			var inf := clampf(infra, float(cfg.get("minimum_infrastructure", 0.1)), 1.0) * float(cfg.get("infrastructure_effect", 0.35))
			var extracted := deposit * clampf(potential + labor + inf, 0.0, float(cfg.get("exploitation_cap_per_month", 0.02)))
			extracted = minf(extracted, deposit)
			if extracted <= 0.0:
				continue
			r["deposits"][res] = deposit - extracted
			r["exploitation"][res] = rate
			stocks[res] = float(stocks.get(res, 0.0)) + extracted
			if not (r.has("last_extracted_by_resource")):
				r["last_extracted_by_resource"] = {}
			(r["last_extracted_by_resource"] as Dictionary)[res] = {"amount": extracted, "turn": state.turn}


static func validate_invest(state: GameState, rid: String, res: String, amount: float) -> String:
	if not state.economy["regions"].has(rid):
		return "région inconnue"
	if not (state.economy["regions"][rid] as Dictionary)["deposits"].has(res):
		return "ressource absente"
	if amount <= 0.0:
		return "investissement non positif"
	return ""


static func invest(state: GameState, rid: String, res: String, amount: float) -> String:
	if not state.economy["regions"].has(rid):
		return "région inconnue"
	var r: Dictionary = state.economy["regions"][rid]
	if not r["deposits"].has(res):
		return "ressource absente"
	if amount <= 0.0:
		return "investissement non positif"
	r["exploitation"][res] = clampf(float(r["exploitation"].get(res, 0.0)) + amount, 0.0, 1.0)
	return ""


static func available(state: GameState, nation: String, res: String) -> float:
	return float(state.economy.get("stocks", {}).get(nation, {}).get(res, 0.0))


static func consume(state: GameState, nation: String, res: String, amount: float) -> float:
	var stocks: Dictionary = state.economy["stocks"][nation]
	var have := float(stocks.get(res, 0.0))
	var used := minf(have, maxf(0.0, amount))
	stocks[res] = have - used
	return used


static func summary(state: GameState, nation: String) -> Dictionary:
	return (state.economy.get("stocks", {}).get(nation, {}) as Dictionary).duplicate(true)
