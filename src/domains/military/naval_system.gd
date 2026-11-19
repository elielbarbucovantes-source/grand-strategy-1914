class_name NavalSystem
extends RefCounted
## Phase VI.G/H/I — marine stratégique abstraite : flottes, zones maritimes, opérations.


static func ensure(state: GameState, nid: String) -> void:
	if not state.tech["naval"]["fleets"].has(nid):
		state.tech["naval"]["fleets"][nid] = []


static func create_fleet(state: GameState, nid: String, port_city: String, composition: Dictionary, rules: Dictionary) -> String:
	ensure(state, nid)
	var net: TransportNetwork = rules.get("transport_network") as TransportNetwork
	var port: Dictionary = net.ports.get(port_city, {}) if net != null else {}
	if port.is_empty():
		return "port inconnu"
	if not state.regions.has(str(port.get("region_id", ""))) or state.controller(str(port["region_id"])) != nid:
		return "port hors contrôle"
	var cfg: Dictionary = (rules.get("phase6", {}) as Dictionary).get("naval", {}) if rules.has("phase6") else rules.get("naval", {})
	if cfg.is_empty() and rules.has("production_cost"):
		cfg = rules
	for cat: String in composition:
		var costs: Dictionary = cfg.get("production_cost", {}).get(cat, {})
		var n := int(composition[cat])
		for res: String in costs:
			if ResourceSystem.available(state, nid, res) < float(costs[res]) * float(n):
				return "ressource insuffisante : " + res
	for cat: String in composition:
		var costs: Dictionary = cfg.get("production_cost", {}).get(cat, {})
		for res: String in costs:
			ResourceSystem.consume(state, nid, res, float(costs[res]) * float(composition[cat]))
	(state.tech["naval"]["fleets"][nid] as Array).append({"id": state.new_id("fleet"), "owner": nid,
		"port": port_city, "region": port["region_id"], "composition": composition.duplicate(true),
		"status": "operational", "autonomy": int(cfg.get("base_autonomy", 3)), "created": state.turn})
	return ""


static func operation(state: GameState, nid: String, fleet_id: String, kind: String, target_zone: String, rules: Dictionary) -> Dictionary:
	ensure(state, nid)
	var cfg: Dictionary = rules.get("naval", {})
	var fleet: Dictionary = {}
	for f: Dictionary in state.tech["naval"]["fleets"][nid]:
		if str(f["id"]) == fleet_id:
			fleet = f
			break
	if fleet.is_empty() or str(fleet["status"]) != "operational":
		return {"ok": false, "reason": "flotte indisponible"}
	var allowed := ["patrol", "reconnaissance", "escort", "intercept", "blockade", "transport", "amphibious"]
	if not allowed.has(kind):
		return {"ok": false, "reason": "opération inconnue"}
	if int(fleet["autonomy"]) <= 0:
		return {"ok": false, "reason": "autonomie épuisée"}
	fleet["autonomy"] = int(fleet["autonomy"]) - 1
	var result := {"ok": true, "kind": kind, "zone": target_zone, "fleet": fleet_id, "turn": state.turn}
	(state.tech["naval"]["operations"] as Array).append(result)
	match kind:
		"escort":
			result["effect"] = "trade_losses_reduction"
		"blockade":
			result["effect"] = "trade_reduction"
		"transport", "amphibious":
			result["effect"] = "transport_capacity"
	state.log_event("marine", "%s : opération %s en %s." % [
		state.nations[nid]["name_fr"], kind, target_zone], [nid])
	return result


static func escort_benefit(state: GameState, nid: String, rules: Dictionary) -> float:
	var cfg: Dictionary = rules.get("naval", {})
	var benefit := 0.0
	for o: Dictionary in state.tech["naval"]["operations"]:
		if str(o.get("kind", "")) == "escort" and int(o.get("turn", -1)) == state.turn:
			benefit += float(cfg.get("escort_effectiveness", 1.0)) * 0.1
	return benefit


static func blockade_penalty(state: GameState, target: String, rules: Dictionary) -> float:
	var cfg: Dictionary = rules.get("naval", {})
	var penalty := 0.0
	for o: Dictionary in state.tech["naval"]["operations"]:
		if str(o.get("kind", "")) == "blockade" and int(o.get("turn", -1)) == state.turn:
			penalty += float(cfg.get("blockade_trade_reduction", 0.4))
	return clampf(penalty, 0.0, 0.8)


static func monthly(state: GameState, nid: String) -> void:
	ensure(state, nid)
	for f: Dictionary in state.tech["naval"]["fleets"][nid]:
		if str(f["status"]) == "operational":
			f["autonomy"] = int(f.get("autonomy", 0)) + 1  # ravitaillement au port ralenti
