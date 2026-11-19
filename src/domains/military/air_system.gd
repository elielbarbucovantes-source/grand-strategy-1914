class_name AirSystem
extends RefCounted
## Phase VI.F/H/I — aviation stratégique abstraite : bases, appareils, missions de renseignement.


static func ensure(state: GameState, nid: String) -> void:
	if not state.tech["air"]["bases"].has(nid):
		state.tech["air"]["bases"][nid] = []
	if not state.tech["air"]["aircraft"].has(nid):
		state.tech["air"]["aircraft"][nid] = {"recon": 0, "fighter": 0, "bomber": 0, "multipurpose": 0}


static func build_base(state: GameState, nid: String, rid: String, rules: Dictionary) -> String:
	ensure(state, nid)
	if not state.regions.has(rid) or state.controller(rid) != nid:
		return "région hors contrôle"
	var cfg: Dictionary = (rules.get("phase6", {}) as Dictionary).get("aviation", {}) if rules.has("phase6") else rules.get("aviation", {})
	for b: Dictionary in state.tech["air"]["bases"][nid]:
		if str(b["region"]) == rid:
			return "base déjà présente"
	(state.tech["air"]["bases"][nid] as Array).append({"id": state.new_id("airbase"), "region": rid,
		"capacity": int(cfg.get("base_capacity", 40)), "status": "operational", "created": state.turn})
	state.log_event("aviation", "%s construit une base aérienne en %s." % [state.nations[nid]["name_fr"], rid], [nid])
	return ""


static func produce(state: GameState, nid: String, kind: String, amount: int, rules: Dictionary) -> String:
	ensure(state, nid)
	var aircraft: Dictionary = state.tech["air"]["aircraft"][nid]
	if not aircraft.has(kind):
		return "catégorie inconnue"
	# Accès technologique
	var tech_key := {"recon": "air_recon", "fighter": "air_fighters", "bomber": "air_bombers", "multipurpose": "air_capacity"}
	var required := 1.0 if kind == "recon" else 1.0
	if TechSystem.effect(state, nid, str(tech_key.get(kind, "air_recon"))) < required:
		return "technologie manquante"
	var cfg: Dictionary = (rules.get("phase6", {}) as Dictionary).get("aviation", {}) if rules.has("phase6") else rules.get("aviation", {})
	var costs: Dictionary = cfg.get("production_cost_per_aircraft", {})
	for res: String in costs:
		var need := float(costs[res]) * float(amount)
		if ResourceSystem.available(state, nid, res) < need:
			return "ressource insuffisante : " + res
	for res: String in costs:
		ResourceSystem.consume(state, nid, res, float(costs[res]) * float(amount))
	aircraft[kind] = int(aircraft[kind]) + amount
	state.log_event("aviation", "%s produit %d appareil(s) %s." % [state.nations[nid]["name_fr"], amount, kind], [nid])
	return ""


static func reconnaissance(state: GameState, t: TechSystem, nid: String, target_rid: String, rules: Dictionary) -> Dictionary:
	ensure(state, nid)
	var cfg: Dictionary = (rules.get("phase6", {}) as Dictionary).get("aviation", {}) if rules.has("phase6") else rules.get("aviation", {})
	var aircraft: Dictionary = state.tech["air"]["aircraft"][nid]
	var available := int(aircraft.get("recon", 0)) + int(aircraft.get("multipurpose", 0))
	if available <= 0:
		return {"ok": false, "reason": "aucun appareil de reconnaissance"}
	var bases: Array = state.tech["air"]["bases"][nid]
	if bases.is_empty():
		return {"ok": false, "reason": "aucune base aérienne"}
	var range := float(cfg.get("base_range_km", 150)) + TechSystem.effect(state, nid, "air_range")
	var accuracy := float(cfg.get("recon_accuracy", 0.3)) + minf(float(available) * float(cfg.get("recon_per_aircraft", 0.02)), 0.3)
	var target_nation := str(state.regions[target_rid]["controller"])
	# Renseignement daté et imparfait, injecté dans le système existant.
	if not state.tech["intel"].has(nid):
		state.tech["intel"][nid] = []
	(state.tech["intel"][nid] as Array).append({"turn": state.turn, "region": target_rid,
		"nation": target_nation, "accuracy": clampf(accuracy, 0.0, 1.0), "source": "air_recon"})
	return {"ok": true, "region": target_rid, "range": range, "accuracy": accuracy}


static func monthly(state: GameState, nid: String, rules: Dictionary) -> void:
	ensure(state, nid)
	var cfg: Dictionary = (rules.get("phase6", {}) as Dictionary).get("aviation", {}) if rules.has("phase6") else rules.get("aviation", {})
	var aircraft: Dictionary = state.tech["air"]["aircraft"][nid]
	var total := 0
	for k: String in aircraft:
		total += int(aircraft[k])
	var loss := float(total) * float(cfg.get("maintenance_share", 0.08)) * 0.1
	if loss >= 1.0 and total > 0:
		# Entretien imparfait : quelques appareils retirés, jamais de stock négatif.
		for k: String in aircraft:
			if int(aircraft[k]) > 0:
				aircraft[k] = maxi(0, int(aircraft[k]) - 1)
				break
