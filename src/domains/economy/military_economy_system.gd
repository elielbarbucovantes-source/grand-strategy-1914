class_name MilitaryEconomySystem
extends RefCounted
## Phase V.H/I — ravitaillement militaire et remplacement progressif des pertes.
## Aucune catégorie de pertes MIL-01 n'est modifiée ; aucun soldat n'est créé sans ressources.


static func monthly_supply(state: GameState, rules: Dictionary) -> void:
	var cfg: Dictionary = rules.get("military_supply", {})
	var needs: Dictionary = cfg.get("needs_per_soldier", {})
	var all_ids: Array = state.formations.keys()
	all_ids.sort()
	for nid: String in state.nation_order:
		var stocks: Dictionary = state.economy["stocks"][nid]
		var total_need := 0.0
		var total_got := 0.0
		for fid: String in all_ids:
			var f: Dictionary = state.formations[fid]
			if str(f["nation"]) != nid or f["echelon"] != "unit":
				continue
			var soldiers := maxi(0, int(f.get("soldiers", 0)))
			total_need += float(soldiers)
			for res: String in needs:
				total_got += ResourceSystem.consume(state, nid, res, float(needs[res]) * float(soldiers))
		var ratio := 1.0
		if total_need > 0.0:
			ratio = snappedf(clampf(total_got / maxf(0.0001, float(needs.size()) * total_need), 0.0, 1.0), 0.000001)
		for fid: String in all_ids:
			var f: Dictionary = state.formations[fid]
			if str(f["nation"]) != nid or f["echelon"] != "unit":
				continue
			f["supply_ratio"] = ratio
			f["logistics_modifier"] = _modifier(ratio, cfg)


static func _modifier(ratio: float, cfg: Dictionary) -> float:
	if ratio >= float(cfg.get("well_supplied_threshold", 0.9)):
		return 0.0
	if ratio >= float(cfg.get("strained_threshold", 0.6)):
		return float(cfg.get("strained_morale_modifier", -2.0))
	return float(cfg.get("shortage_morale_modifier", -5.0))


static func monthly_replacement(state: GameState, rules: Dictionary) -> void:
	var cfg: Dictionary = rules.get("replacement", {})
	for nid: String in state.nation_order:
		var q: Dictionary = state.economy["replacement"].get(nid, {"queued": 0.0, "in_training": 0.0})
		var reserves: Dictionary = state.nations[nid].get("forces", {})
		var reservists := int(reserves.get("reserve_pool", 0))
		var workers := DemographySystem.sector(state, nid, "agriculture") + DemographySystem.sector(state, nid, "services")
		if reservists <= 0 or workers < int(cfg.get("min_workforce_pool", 5000)):
			state.economy["replacement"][nid] = q
			continue
		var want := minf(float(reservists), float(reservists) * float(cfg.get("monthly_fraction_of_reserves", 0.04)) + float(q.get("queued", 0.0)))
		var materials: Dictionary = cfg.get("materials_per_soldier", {})
		var feasible := want
		for res: String in materials:
			var need := float(materials[res]) * feasible
			if need <= 0.0:
				continue
			var got := ResourceSystem.consume(state, nid, res, need)
			if got + 0.000001 < need:
				feasible *= got / need
		var goods := ResourceSystem.consume(state, nid, "military_goods", feasible * 0.01)
		feasible = minf(feasible, goods / 0.01) if goods > 0.0 else 0.0
		feasible = maxi(0.0, floorf(feasible))
		if feasible <= 0.0:
			q["queued"] = want
			state.economy["replacement"][nid] = q
			continue
		# Prélèvement dans les réserves historiques (MIL-01) sans modifier les pertes enregistrées.
		reserves["reserve_pool"] = reservists - int(feasible)
		reserves["incorporated"] = int(reserves.get("incorporated", 0)) + int(feasible)
		q["replacement_total"] = float(q.get("replacement_total", 0.0)) + feasible
		q["queued"] = 0.0
		state.economy["replacement"][nid] = q
		state.log_event("remplacement", "%s : %d hommes pris sur les réserves (production limitée)." % [
			state.nations[nid]["name_fr"], int(feasible)], [nid])


static func summary(state: GameState, nid: String) -> Dictionary:
	var q: Dictionary = state.economy.get("replacement", {}).get(nid, {})
	return q.duplicate(true)
