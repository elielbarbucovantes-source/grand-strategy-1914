class_name IndustrySystem
extends RefCounted
## Phase V.D/E — capacité industrielle régionale limitée, consommation réelle de matières premières
## et de main-d'œuvre, production par catégorie selon les priorités nationales.


static func monthly(state: GameState, rules: Dictionary) -> void:
	var cfg: Dictionary = rules.get("industry_model", {})
	var inputs: Dictionary = cfg.get("inputs", {})
	var work_need := float(cfg.get("workforce_per_capacity", 120))
	for nid: String in state.nation_order:
		var alloc_raw: Dictionary = state.nations[nid].get("industry_allocation", {})
		var alloc := {}
		var mapping := {"industrie_militaire_terrestre": "military", "munitions_et_equipements": "military",
			"industrie_aeronautique": "manufacturing", "industrie_civile": "manufacturing",
			"industrie_navale": "heavy", "military": "military", "heavy": "heavy",
			"manufacturing": "manufacturing", "processing": "processing", "energy": "energy"}
		for key: String in alloc_raw:
			var internal := str(mapping.get(key, "manufacturing"))
			alloc[internal] = float(alloc.get(internal, 0.0)) + float(alloc_raw[key])
		if alloc.is_empty():
			alloc = {"military": 25, "heavy": 25, "manufacturing": 25, "processing": 25}
		var total := 0.0
		for v: float in alloc.values():
			total += v
		if total <= 0.0:
			continue
		var workers := DemographySystem.sector(state, nid, "industry")
		var capacity := 0.0
		for rid: String in state.economy["regions"]:
			var r: Dictionary = state.economy["regions"][rid]
			if str(r["nation"]) == nid:
				capacity += float(r.get("industry_capacity", 0.0))
		var available_work := workers / maxf(1.0, work_need)
		var budget: float = minf(capacity, available_work)
		var stocks: Dictionary = state.economy["stocks"][nid]
		for cat: String in ["military", "heavy", "manufacturing", "processing", "energy"]:
			var share := float(alloc.get(cat, 0.0)) / total
			if share <= 0.0:
				continue
			var need: Dictionary = inputs.get(cat, {})
			var feasible := share * budget
			for res: String in need:
				var required := float(need[res]) * feasible
				if required <= 0.0:
					continue
				var got := ResourceSystem.consume(state, nid, res, required)
				if got + 0.000001 < required:
					feasible *= got / required
			if feasible <= 0.0:
				continue
			var output := feasible * (1.0 - float(cfg.get("maintenance_share", 0.05)))
			var key := "military_goods" if cat == "military" else ("civil_goods" if cat == "manufacturing" else "industrial_" + cat)
			stocks[key] = float(stocks.get(key, 0.0)) + output
			stocks["last_output_" + cat] = output


static func capacity(state: GameState, nid: String) -> float:
	var cap := 0.0
	for rid: String in state.economy["regions"]:
		var r: Dictionary = state.economy["regions"][rid]
		if str(r["nation"]) == nid:
			cap += float(r.get("industry_capacity", 0.0))
	return cap


static func validate_allocation(rules: Dictionary, order: Dictionary) -> String:
	var allowed: Array = rules.get("economy", {}).get("industry_categories", [])
	var total := 0.0
	for key: String in (order.get("allocation", {}) as Dictionary):
		if not allowed.has(key):
			return "catégorie industrielle inconnue : %s" % key
		var v := float(order["allocation"][key])
		if v < 0.0:
			return "part négative"
		total += v
	if total > 100.0001:
		return "la somme des priorités dépasse 100 %"
	return ""
