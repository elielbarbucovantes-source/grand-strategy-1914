class_name DemographySystem
extends RefCounted
## Phase V.B — démographie régionale et main-d'œuvre. Données de base historiques (niveau
## indiqué par source), répartition régionale estimée. Aucune simulation individuelle.


static func init_from_baseline(state: GameState, baseline: Dictionary, rules: Dictionary) -> void:
	var cfg: Dictionary = rules.get("economy_model", {})
	var regions: Dictionary = baseline.get("regions", {})
	state.economy["regions"] = regions.duplicate(true)
	for nid: String in state.nation_order:
		state.economy["workforce"][nid] = {}
	for rid: String in regions:
		var r: Dictionary = regions[rid]
		var nation := str(r["nation"])
		var sectors: Dictionary = state.economy["workforce"][nation]
		for s: String in r["sectors"]:
			sectors[s] = float(sectors.get(s, 0.0)) + float(r["sectors"][s])


static func monthly(state: GameState, rules: Dictionary) -> void:
	var cfg: Dictionary = rules.get("population", {})
	var active := float(cfg.get("active_share", 0.52))
	var mobilized: Dictionary = {}
	for nid: String in state.nation_order:
		var f: Dictionary = state.nations[nid].get("forces", {})
		mobilized[nid] = int(f.get("incorporated", 0)) + int(f.get("present_in_units", 0))
	for rid: String in state.economy["regions"]:
		var r: Dictionary = state.economy["regions"][rid]
		var pop := float(r["population"])
		var birth := float(cfg.get("birth_rate_per_1000", 24)) / 1000.0
		var death := float(cfg.get("death_rate_per_1000", 18)) / 1000.0
		var factor := 1.0
		var food: float = float(r.get("food_ratio", 1.0))
		if food < 1.0:
			factor = 0.6 + 0.4 * food
			death += (1.0 - food) * 0.02
		var growth := clampf((birth - death) * factor, -float(cfg.get("growth_cap_per_month", 0.004)),
			float(cfg.get("growth_cap_per_month", 0.004)))
		r["population"] = maxi(1, int(pop * (1.0 + growth)))
		var work := float(r["population"]) * active
		var mob: float = float(mobilized.get(str(r["nation"]), 0))
		var nat_pop := 0
		for rr: Dictionary in state.economy["regions"].values():
			if str(rr["nation"]) == str(r["nation"]):
				nat_pop += int(rr["population"])
		var mob_share := clampf(mob / maxf(1.0, float(nat_pop)), 0.0, 0.35)
		var factor_mob := 1.0 - mob_share * (1.0 - float(cfg.get("mobilization_workforce_factor", 0.75)))
		r["workforce"] = int(work * factor_mob)
		var sectors: Dictionary = r["sectors"]
		var sum_parts := 0.0
		for s: String in sectors:
			sum_parts += float(sectors[s])
		if sum_parts <= 0.0:
			continue
		for s: String in sectors:
			sectors[s] = int(float(r["workforce"]) * float(sectors[s]) / sum_parts)
	for nid: String in state.nation_order:
		var total: Dictionary = {}
		for rid: String in state.economy["regions"]:
			var r2: Dictionary = state.economy["regions"][rid]
			if str(r2["nation"]) != nid:
				continue
			for s: String in r2["sectors"]:
				total[s] = float(total.get(s, 0.0)) + float(r2["sectors"][s])
		state.economy["workforce"][nid] = total


static func sector(state: GameState, nation: String, name: String) -> float:
	return float(state.economy.get("workforce", {}).get(nation, {}).get(name, 0.0))


static func summary(state: GameState, nation: String) -> Dictionary:
	var pop := 0
	for r: Dictionary in state.economy.get("regions", {}).values():
		if str(r["nation"]) == nation:
			pop += int(r["population"])
	return {"population": pop, "workforce": state.economy.get("workforce", {}).get(nation, {})}
