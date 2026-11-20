class_name PoliticalAI
extends RefCounted
## Phase VII.J — IA politique : décisions gouvernementales et réaction aux crises intérieures.
## Bornée, déterministe, cohérente avec les ressources et la situation connue.


static func personality(state: GameState, nid: String, rules: Dictionary) -> Dictionary:
	var cfg: Dictionary = rules.get("ai", {})
	var profiles: Dictionary = cfg.get("personalities", {})
	var id := str(state.politics["states"].get(nid, {}).get("ai_personality", cfg.get("default_personality", "pragmatic")))
	var p: Variant = profiles.get(id, profiles.get("pragmatic", {}))
	return p if p is Dictionary else {}


static func decide(state: GameState, nid: String, rules: Dictionary) -> Array:
	var out: Array = []
	var cfg: Dictionary = rules
	var p := personality(state, nid, cfg)
	var pol: Dictionary = PoliticalSystem.ensure(state, nid, cfg)
	var max_d := int(cfg.get("ai", {}).get("max_decisions_per_turn", 2))
	var stability := float(pol.get("stability", 65))
	var tension := float(pol.get("social_tension", 25))
	var decision := ""
	if tension > float(cfg.get("politics", {}).get("crisis", {}).get("tension_threshold", 75)) * 0.6:
		decision = "cohesion_campaign" if float(p.get("cohesion", 0.3)) >= 0.3 else "political_concession"
	elif stability < 40.0:
		decision = "public_spending"
	elif float(p.get("reform", 0.3)) > 0.5:
		decision = "social_reform"
	if decision != "":
		out.append(Orders.political_decision(nid, decision))
	# Changement de gouvernement uniquement en crise justifiée.
	if str(pol.get("active_crisis", "")) != "" and stability < 20.0 and max_d > 1:
		out.append(Orders.change_government(nid, "negotiated"))
	return out
