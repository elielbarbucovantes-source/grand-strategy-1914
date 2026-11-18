class_name PowSystem
extends RefCounted
## Phase III.F — prisonniers de guerre : enregistrement, attribution, échange, rapatriement.
## S'appuie sur ForceLedger (MIL-01) : aucune catégorie parallèle, aucun double comptage.


static func cfg(rules: Dictionary) -> Dictionary:
	var d: Variant = rules.get("diplomacy", {}).get("pow")
	return d if d is Dictionary else {}


static func held_by(state: GameState, captor: String, origin: String = "") -> int:
	var l: Dictionary = ForceLedger.ledger(state, captor)
	if origin.is_empty():
		return int(l.get("prisoners_held", 0))
	return int((l.get("prisoners_held_by_origin", {}) as Dictionary).get(origin, 0))


static func lost_by(state: GameState, origin: String) -> int:
	return int(ForceLedger.ledger(state, origin).get("prisoners_lost", 0))


## Transfère un nombre de prisonniers du détenteur vers leur puissance d'origine.
static func release(state: GameState, captor: String, origin: String, amount: int, reason: String) -> int:
	if amount <= 0 or captor == origin or not state.nations.has(origin):
		return 0
	var available := held_by(state, captor, origin)
	var n := mini(amount, available)
	if n <= 0:
		return 0
	var c: Dictionary = ForceLedger.ledger(state, captor)
	c["prisoners_held"] = int(c.get("prisoners_held", 0)) - n
	var by_origin: Dictionary = c["prisoners_held_by_origin"]
	by_origin[origin] = int(by_origin.get(origin, 0)) - n
	var o: Dictionary = ForceLedger.ledger(state, origin)
	o["repatriated"] = int(o.get("repatriated", 0)) + n
	o["released"] = int(o.get("released", 0)) + n
	var ex: Dictionary = state.diplomacy["pow"]
	(ex["exchanges"] as Array).append({"turn": state.turn, "captor": captor, "origin": origin,
		"soldiers": n, "reason": reason})
	state.log_event("prisonniers", "%s rapatrie %d prisonniers de %s (%s)." % [
		state.nations[origin]["name_fr"], n, state.nations[captor]["name_fr"], reason], [origin, captor])
	return n


static func exchange(state: GameState, a: String, b: String, rules: Dictionary) -> Dictionary:
	var ratio := float(cfg(rules).get("exchange_ratio", 1.0))
	var maxn := int(cfg(rules).get("max_exchanges_per_turn", 4))
	var done := 0
	for e: Dictionary in state.diplomacy["pow"]["exchanges"]:
		if int(e.get("turn", -1)) == state.turn and str(e.get("reason", "")) == "exchange":
			done += 1
	if done >= maxn:
		return {"a": 0, "b": 0, "error": "nombre maximal d'échanges atteint"}
	var held_b := held_by(state, b, a)
	var held_a := held_by(state, a, b)
	var na := int(min(float(held_b), float(held_a) * ratio))
	var nb := int(min(float(held_a), float(held_b) * ratio))
	na = release(state, b, a, na, "exchange")
	nb = release(state, a, b, nb, "exchange")
	var ex: Dictionary = state.diplomacy["pow"]
	(ex["holders"] as Dictionary)[a + "|" + b] = {"turn": state.turn, "from_a": na, "from_b": nb}
	RelationsSystem.adjust(state, a, b, rules, {"trust": 5.0, "cooperation": 4.0}, "pow_exchange")
	return {"a": na, "b": nb}


static func repatriate_on_peace(state: GameState, a: String, b: String, rules: Dictionary) -> Dictionary:
	if not bool(cfg(rules).get("repatriation_on_peace", true)):
		return {"a": 0, "b": 0}
	var na := release(state, b, a, held_by(state, b, a), "peace")
	var nb := release(state, a, b, held_by(state, a, b), "peace")
	return {"a": na, "b": nb}


static func summary(state: GameState, nation: String) -> String:
	return "détenus %d | perdus %d | rapatriés %d" % [
		held_by(state, nation), lost_by(state, nation),
		int(ForceLedger.ledger(state, nation).get("repatriated", 0))]
