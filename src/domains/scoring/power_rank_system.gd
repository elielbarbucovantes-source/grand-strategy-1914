class_name PowerRankSystem
extends RefCounted
## RESTORATION 02 — classement dynamique des puissances.
## Indicateur global explicable, recalculé chaque mois, SÉPARÉ des conditions de victoire :
## un État peut être très puissant sans avoir gagné. Toutes les composantes proviennent de
## données déjà calculées par les systèmes existants (aucune valeur inventée, aucun bonus).


static func cfg(rules: Dictionary) -> Dictionary:
	var c: Variant = rules.get("power")
	return c if c is Dictionary else {}


static func _count_regions(state: GameState) -> Dictionary:
	var out: Dictionary = {}
	for rid: String in state.regions:
		var owner := str((state.regions[rid] as Dictionary).get("controller", ""))
		if owner != "":
			out[owner] = int(out.get(owner, 0)) + 1
	return out


## Score d'un État, normalisé 0-100. `regions_count` évite 22 parcours de la carte par mois.
static func score(state: GameState, nid: String, rules: Dictionary, regions_count: Dictionary = {}) -> Dictionary:
	var c := cfg(rules)
	var w: Dictionary = c.get("weights", {})
	var scales: Dictionary = c.get("scales", {})
	var parts: Dictionary = {}
	var pop := 0.0
	for r: Dictionary in state.economy["regions"].values():
		if str(r["nation"]) == nid:
			pop += float(r.get("population", 0))
	parts["demography"] = clampf(pop / float(scales.get("population_per_point", 2000000.0)) * 100.0, 0.0, 100.0)
	parts["industry"] = clampf(IndustrySystem.capacity(state, nid) / float(scales.get("industry_per_point", 20.0)) * 100.0, 0.0, 100.0)
	var stocks: Dictionary = state.economy["stocks"].get(nid, {})
	var wealth := float(stocks.get("money", 0.0))
	for res: String in ["coal", "iron", "oil", "wood", "grain", "other_ores"]:
		wealth += float(stocks.get(res, 0.0)) * float(scales.get("resource_value", 3.0))
	parts["economy"] = clampf(wealth / float(scales.get("money_per_point", 8000.0)) * 100.0, 0.0, 100.0)
	parts["technology"] = clampf(float((state.tech["known"].get(nid, []) as Array).size()) /
		float(scales.get("tech_for_full_score", 33.0)) * 100.0, 0.0, 100.0)
	var forces: Dictionary = MobilizationSystem.summary(state, nid)
	var soldiers := int(forces.get("present_in_units", 0)) + int(forces.get("present_services", 0))
	parts["military"] = clampf(float(soldiers) / float(scales.get("soldiers_per_point", 60000.0)) * 100.0, 0.0, 100.0)
	var pol: Dictionary = state.politics["states"].get(nid, {})
	parts["stability"] = clampf(float(pol.get("stability", 50.0)), 0.0, 100.0)
	parts["prestige"] = clampf(50.0 + float(state.reputation.get(nid, 0.0)) * 2.0, 0.0, 100.0)
	parts["territory"] = clampf(float(int(regions_count.get(nid, 0))) /
		float(scales.get("regions_for_full_score", 12.0)) * 100.0, 0.0, 100.0)
	var total := 0.0
	var weight_sum := 0.0
	for k: String in parts:
		total += float(parts[k]) * float(w.get(k, 0.0))
		weight_sum += float(w.get(k, 0.0))
	return {"nation": nid, "score": snappedf(total / maxf(0.0001, weight_sum), 0.01), "parts": parts}


static func standings(state: GameState, rules: Dictionary) -> Array:
	var counts := _count_regions(state)
	var list: Array = []
	for nid: String in state.nation_order:
		list.append(score(state, nid, rules, counts))
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a["score"]), float(b["score"])):
			return str(a["nation"]) < str(b["nation"])
		return float(a["score"]) > float(b["score"]))
	var out: Array = []
	for i in list.size():
		var e: Dictionary = (list[i] as Dictionary).duplicate(true)
		e["rank"] = i + 1
		out.append(e)
	return out


static func monthly(state: GameState, rules: Dictionary) -> void:
	var list := standings(state, rules)
	var scores: Dictionary = {}
	var ranks: Dictionary = {}
	var snapshot: Array = []
	for e: Dictionary in list:
		var nid := str(e["nation"])
		scores[nid] = float(e["score"])
		ranks[nid] = int(e["rank"])
		snapshot.append([nid, float(e["score"])])
	state.power["scores"] = scores
	state.power["ranks"] = ranks
	var hist: Array = state.power["history"]
	hist.append({"turn": state.turn, "standings": snapshot})
	var limit := int(cfg(rules).get("history_limit", 120))
	if hist.size() > limit:
		hist.remove_at(0)


## Variation depuis le début de campagne (position initiale = premier snapshot).
static func rank_delta(state: GameState, nid: String) -> int:
	var hist: Array = state.power.get("history", [])
	if hist.is_empty():
		return 0
	var first: Array = (hist[0] as Dictionary).get("standings", [])
	var current: Dictionary = state.power.get("ranks", {})
	if not current.has(nid):
		return 0
	for i in first.size():
		if str((first[i] as Array)[0]) == nid:
			return i + 1 - int(current[nid])
	return 0
