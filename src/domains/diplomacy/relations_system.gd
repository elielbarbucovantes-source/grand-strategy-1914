class_name RelationsSystem
extends RefCounted
## Phase III.A — relations bilatérales multidimensionnelles, historique et réputation.
## Aucune dépendance à l'interface. Tout est déterministe et sérialisable.


static func key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


static func cfg(rules: Dictionary) -> Dictionary:
	var d: Variant = rules.get("diplomacy", {}).get("relations")
	return d if d is Dictionary else {}


static func ensure(state: GameState, a: String, b: String, rules: Dictionary) -> Dictionary:
	if a == b or not state.nations.has(a) or not state.nations.has(b):
		return {}
	var k := key(a, b)
	if not state.relations.has(k):
		var initial: Dictionary = cfg(rules).get("initial", {})
		var rel: Dictionary = {}
		for dim: String in initial:
			rel[dim] = float(initial[dim])
		rel["history"] = []
		state.relations[k] = rel
	return state.relations[k]


static func between(state: GameState, a: String, b: String, rules: Dictionary) -> Dictionary:
	return ensure(state, a, b, rules)


static func adjust(state: GameState, a: String, b: String, rules: Dictionary, changes: Dictionary, reason: String) -> void:
	var rel := ensure(state, a, b, rules)
	if rel.is_empty():
		return
	var c := cfg(rules)
	var lo := float(c.get("min", 0))
	var hi := float(c.get("max", 100))
	for dim: String in changes:
		if rel.has(dim):
			rel[dim] = clampf(float(rel[dim]) + float(changes[dim]), lo, hi)
	var hist: Array = rel["history"]
	hist.append({"turn": state.turn, "by": a, "reason": reason, "changes": changes.duplicate(true)})
	if hist.size() > 120:
		hist.remove_at(0)


## Effet d'un événement mémorisé sur la relation et sur la réputation de l'acteur.
static func record(state: GameState, observer: String, actor: String, kind: String, detail: String, rules: Dictionary) -> void:
	if not state.memory.has(observer):
		state.memory[observer] = []
	(state.memory[observer] as Array).append({"turn": state.turn, "about": actor, "kind": kind, "detail": detail})
	var c := cfg(rules)
	var changes := {}
	match kind:
		"treaty_broken":
			changes = {"trust": float(c.get("treaty_broken_trust", -35)),
				"tensions": float(c.get("treaty_broken_tensions", 20)), "hostility": 12.0}
		"treaty_signed", "proposal_accepted":
			changes = {"trust": float(c.get("treaty_signed_trust", 6)),
				"cooperation": float(c.get("treaty_signed_cooperation", 5)), "tensions": -4.0}
		"treaty_respected":
			changes = {"trust": float(c.get("treaty_respected_trust", 3))}
		"declared_war":
			changes = {"trust": float(c.get("declaration_of_war_trust", -25)),
				"hostility": 20.0, "tensions": 25.0}
		"proposal_rejected":
			changes = {"tensions": float(c.get("proposal_rejected_tensions", 3))}
		"alliance_exit":
			# RESTORATION 02 : quitter un engagement est une action observable et coûteuse.
			changes = {"trust": float(c.get("exit_trust", -8)), "tensions": float(c.get("exit_tensions", 8)),
				"hostility": float(c.get("exit_hostility", 5))}
	if not changes.is_empty():
		adjust(state, observer, actor, rules, changes, kind)


static func monthly(state: GameState, rules: Dictionary) -> void:
	var c := cfg(rules)
	var drift: Dictionary = c.get("monthly_drift", {})
	for k: String in state.relations:
		var parts := k.split("|")
		if parts.size() != 2:
			continue
		var rel: Dictionary = state.relations[k]
		for dim: String in drift:
			if rel.has(dim):
				rel[dim] = clampf(float(rel[dim]) + float(drift[dim]), float(c.get("min", 0)), float(c.get("max", 100)))
		var a := parts[0]
		var b := parts[1]
		if state.at_war(a, b):
			rel["hostility"] = clampf(float(rel.get("hostility", 10)) + float(c.get("war_hostility_per_month", 4)), 0.0, 100.0)
			rel["tensions"] = clampf(float(rel.get("tensions", 0)) + float(c.get("war_tensions_per_month", 6)), 0.0, 100.0)
	for nid: String in state.nation_order:
		state.reputation[nid] = reputation(state, nid, rules)


## Réputation : engagements respectés positifs, trahisons et déclarations négatives.
static func reputation(state: GameState, nid: String, rules: Dictionary) -> float:
	var c := cfg(rules)
	var w := float(c.get("reputation_weight", 0.6))
	var score := 0.0
	var observers: Array = (state.memory as Dictionary).keys()
	observers.sort()
	for observer: String in observers:
		if observer == nid or not (state.memory[observer] is Array):
			continue
		for m: Dictionary in state.memory[observer]:
			if m.get("about", "") != nid:
				continue
			match str(m.get("kind", "")):
				"treaty_broken", "declared_war", "alliance_betrayal":
					score -= 8.0 * w
				"alliance_exit":
					score -= 4.0 * w
				"treaty_signed", "treaty_respected", "proposal_accepted":
					score += 2.0 * w
				"mediation_accepted", "peace_signed":
					score += 3.0 * w
	# RESTORATION 02 : la dégradation liée à un changement de gouvernement est persistante
	# (elle n'est pas écrasée par le recalcul mensuel de la réputation).
	var pol: Dictionary = (state.politics.get("states", {}) as Dictionary).get(nid, {})
	score -= float(pol.get("government_penalty", 0.0))
	return snappedf(clampf(score, -100.0, 100.0), 0.0001)


static func summary(state: GameState, a: String, b: String, rules: Dictionary) -> String:
	var r := between(state, a, b, rules)
	if r.is_empty():
		return "aucune relation"
	return "confiance %.0f | hostilité %.0f | coopération %.0f | rivalité %.0f | tensions %.0f" % [
		float(r.get("trust", 50)), float(r.get("hostility", 10)), float(r.get("cooperation", 20)),
		float(r.get("rivalry", 20)), float(r.get("tensions", 0))]
