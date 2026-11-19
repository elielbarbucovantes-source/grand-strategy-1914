class_name CommunicationsSystem
extends RefCounted
## Phase VI.D/E — communications, protection, détection, interception et décryptage abstrait.
## Détecter n'est pas intercepter ; intercepter n'est pas comprendre.


static func ensure(state: GameState, nid: String) -> void:
	if not state.tech["comms"].has(nid):
		state.tech["comms"][nid] = {"protection": 0, "intercepts": [], "decryption": {}, "intel": {}}
	if not state.tech["intel"].has(nid):
		state.tech["intel"][nid] = []


static func protection(state: GameState, t: TechSystem, nid: String, rules: Dictionary) -> int:
	var cfg: Dictionary = rules.get("communications", {})
	var p := int(cfg.get("base_protection", 0))
	for tech_id: String in state.tech["known"].get(nid, []):
		var tech: Dictionary = t.by_id.get(tech_id, {})
		p += int((tech.get("effects", {}) as Dictionary).get("comms_protection", 0))
	return mini(p, int(cfg.get("max_protection", 4)))


## Tente d'intercepter une communication adverse. Retourne un niveau : none/detected/intercepted/partial/decrypted.
static func attempt_intercept(state: GameState, t: TechSystem, observer: String, target: String,
		rules: Dictionary, rng_seed: int) -> Dictionary:
	ensure(state, observer)
	var cfg: Dictionary = rules.get("communications", {})
	var raw := float((rng_seed % 1000)) / 1000.0
	var skill := float(cfg.get("intercept_base", 0.2)) + TechSystem.effect(state, observer, "interception") * 0.1
	var defend := float(protection(state, t, target, rules)) * 0.08
	var chance := clampf(skill - defend, 0.0, 1.0)
	var level := "none"
	if raw < chance * float(cfg.get("detection_base", 0.3)) * 3.0:
		level = "detected"
	if raw < chance:
		level = "intercepted"
	var partial := float(cfg.get("partial_comprehension", 0.5)) + TechSystem.effect(state, observer, "intel_accuracy") * 0.1
	if level == "intercepted" and raw < chance * partial:
		level = "partial"
	var full := float(cfg.get("full_comprehension", 0.85))
	if level == "partial" and raw < chance * full:
		level = "decrypted"
	var result := {"level": level, "reliability": 0.0, "turn": state.turn, "target": target}
	match level:
		"detected": result["reliability"] = 0.1
		"intercepted": result["reliability"] = 0.25
		"partial": result["reliability"] = float(cfg.get("intel_reliability_low", 0.4))
		"decrypted": result["reliability"] = 0.9
	if level != "none":
		(state.tech["comms"][observer]["intercepts"] as Array).append(result)
	return result


## Décryptage abstrait : progresse avec la science et le temps, jamais instantané.
static func advance_decryption(state: GameState, observer: String, target: String, rules: Dictionary) -> void:
	ensure(state, observer)
	var cfg: Dictionary = rules.get("communications", {})
	var d: Dictionary = state.tech["comms"][observer]["decryption"]
	var key := target
	var progress := float(d.get(key, 0.0))
	progress += float(cfg.get("decrypt_progress_per_turn", 0.08))
	progress += TechSystem.effect(state, observer, "decryption") * float(cfg.get("decrypt_bonus_with_codebooks", 0.12))
	d[key] = minf(1.0, progress)
	if progress >= 1.0:
		state.log_event("renseignement", "%s déchiffre le trafic de %s (abstrait)." % [
			state.nations[observer]["name_fr"], state.nations[target]["name_fr"]], [observer])


static func technical_intel(state: GameState, observer: String, target: String, rules: Dictionary) -> Dictionary:
	ensure(state, observer)
	var cfg: Dictionary = rules.get("communications", {})
	var intercepts: Array = state.tech["comms"][observer]["intercepts"]
	var best_reliability := 0.0
	var last_turn := -99
	for i: Dictionary in intercepts:
		if str(i["target"]) == target:
			best_reliability = maxf(best_reliability, float(i["reliability"]))
			last_turn = maxi(last_turn, int(i["turn"]))
	var stale := state.turn - last_turn > int(cfg.get("intel_stale_turns", 3))
	if stale:
		best_reliability *= 0.5
	var decrypt := float(state.tech["comms"][observer]["decryption"].get(target, 0.0))
	return {
		"target": target, "reliability": clampf(best_reliability + decrypt * 0.5, 0.0, 1.0),
		"stale": stale,
		"industry": IndustrySystem.capacity(state, target) * (0.8 + 0.4 * best_reliability),
		"technologies": (state.tech["known"].get(target, []) as Array).size() if best_reliability > 0.6 else -1,
	}
