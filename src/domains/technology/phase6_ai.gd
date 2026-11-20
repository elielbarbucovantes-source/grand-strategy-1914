class_name Phase6AI
extends RefCounted
## Phase VI.J — IA technologique : choix de recherche, protection des communications,
## missions aériennes et opérations navales. Bornée, déterministe, sans ressources gratuites.


static func personality(state: GameState, nid: String, rules: Dictionary) -> Dictionary:
	# Accepte soit le bloc phase6, soit le dictionnaire de règles complet.
	var phase6: Dictionary = rules.get("phase6", {})
	var cfg: Dictionary = phase6.get("ai", {}) if phase6.has("ai") else rules.get("ai", {})
	var profiles: Dictionary = cfg.get("personalities", {})
	var id := str(state.tech.get("personalities", {}).get(nid, cfg.get("default_personality", "balanced")))
	var p: Variant = profiles.get(id, profiles.get("balanced", {}))
	return p if p is Dictionary else {}


static func decide(state: GameState, t: TechSystem, rules: Dictionary, nid: String) -> Array:
	var out: Array = []
	var p := personality(state, nid, rules)
	var cfg: Dictionary = (rules.get("phase6", {}) as Dictionary) if rules.has("phase6") else rules
	# 1. Recherche : choisir une technologie réalisable selon la personnalité.
	var max_research := int(cfg.get("ai", {}).get("max_research_projects", 2))
	var active := (state.tech["projects"].get(nid, []) as Array).size()
	var candidates: Array = t.tree.get("technologies", [])
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
	var started := 0
	for tech: Dictionary in candidates:
		if active + started >= max_research:
			break
		var domain := str(tech["domain"])
		var weight := float(p.get(domain, 0.2))
		if weight < 0.15:
			continue
		if TechSystem.can_research(state, t, nid, str(tech["id"])) != "":
			continue
		out.append({"type": Orders.SET_RESEARCH, "nation": nid, "tech": tech["id"]})
		started += 1
	# 2. Protection des communications : passer à un chiffrement supérieur si disponible.
	if TechSystem.known(state, nid, "codebooks"):
		out.append({"type": Orders.SET_COMMS_PROTECTION, "nation": nid, "level": 2})
	# 3. Mission de reconnaissance aérienne vers une région voisine observée.
	var aircraft: Dictionary = state.tech["air"]["aircraft"].get(nid, {})
	var max_air := int(cfg.get("ai", {}).get("max_air_missions", 2))
	if int(aircraft.get("recon", 0)) > 0 and max_air > 0:
		var rid: String = state.nations[nid].get("capital_region_id", "")
		var neighbors: Array = state.world.neighbor_ids(rid, true) if state.world != null else []
		neighbors.sort()
		for nrid: String in neighbors:
			if str(state.regions[nrid].get("controller", "")) != nid:
				out.append({"type": Orders.AIR_RECON, "nation": nid, "region": nrid})
				break
	# 4. Opération navale : patrouille si une flotte existe.
	var fleets: Array = state.tech["naval"]["fleets"].get(nid, [])
	var max_naval := int(cfg.get("ai", {}).get("max_naval_operations", 2))
	if not fleets.is_empty() and max_naval > 0:
		var f: Dictionary = fleets[0]
		out.append({"type": Orders.NAVAL_OPERATION, "nation": nid, "fleet": str(f["id"]),
			"kind": "patrol", "zone": str(f["region"])})
	return out
