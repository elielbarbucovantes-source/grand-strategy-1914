class_name PeaceSystem
extends RefCounted
## Phase III.E — traités de paix fonctionnels : fin réelle des hostilités, conditions négociables,
## cohérence des formations et des ordres, rapatriement des prisonniers et paix universelle.


static func cfg(rules: Dictionary) -> Dictionary:
	var d: Variant = rules.get("diplomacy", {}).get("peace")
	return d if d is Dictionary else {}


static func by_id(state: GameState, tid: String) -> Dictionary:
	for t: Dictionary in state.diplomacy["peace_treaties"]:
		if str(t["id"]) == tid:
			return t
	return {}


static func normalize_terms(terms: Dictionary, rules: Dictionary) -> Dictionary:
	var out := {}
	var allowed: Array = cfg(rules).get("terms", [])
	for k: String in terms:
		if allowed.has(k):
			out[k] = terms[k]
	if not out.has("white"):
		out["white"] = true
	return out


static func propose(state: GameState, order: Dictionary, rules: Dictionary) -> Dictionary:
	var dest: Variant = order.get("to", order.get("target", ""))
	var recipients: Array = dest if dest is Array else [dest]
	var p := {
		"id": state.new_id("proposal"), "turn": state.turn, "from": order["nation"], "to": recipients.duplicate(true),
		"kind": "peace", "status": "pending", "terms": normalize_terms(order.get("terms", {}), rules),
		"channel": "private", "expires_turn": state.turn + int(cfg(rules).get("valid_turns", 3)),
		"counters": [],
		"history": [{"turn": state.turn, "action": "proposed", "by": order["nation"]}]
	}
	state.proposals.append(p)
	state.log_event("paix", "%s propose une paix à %s." % [
		state.nations[order["nation"]]["name_fr"], str(recipients)], recipients)
	return p


static func sign(state: GameState, proposal: Dictionary, rules: Dictionary) -> Dictionary:
	var parties: Array = (proposal["to"] as Array).duplicate(true)
	parties.append(str(proposal["from"]))
	var terms: Dictionary = proposal.get("terms", {"white": true})
	var t := {
		"id": state.new_id("peace_treaty"), "signed_turn": state.turn, "parties": parties,
		"terms": terms.duplicate(true), "status": "active",
		"history": [{"turn": state.turn, "action": "signed"}]
	}
	(state.diplomacy["peace_treaties"] as Array).append(t)
	var white := bool(terms.get("white", false))
	# 1. Fin effective des hostilités entre les parties.
	for a: String in parties:
		for b: String in parties:
			if a == b:
				continue
			state.wars = state.wars.filter(func(w: Dictionary) -> bool:
				return not ((str(w["a"]) == a and str(w["b"]) == b) or (str(w["a"]) == b and str(w["b"]) == a)))
	# 2. Ordres en cours devenus invalides (un ordre offensif contre un ancien ennemi).
	for nid: String in state.nation_order:
		var kept: Array = []
		for o: Dictionary in state.pending_orders.get(nid, []):
			var target := str(o.get("target", o.get("to", "")))
			var invalid := false
			if (o.get("type", "")) == Orders.MOVE:
				for a: String in parties:
					if a != nid and state.regions.has(target) and str(state.regions[target].get("controller", "")) == a:
						invalid = true
			if not invalid:
				kept.append(o)
		state.pending_orders[nid] = kept
	# 3. Territoires : paix blanche = aucun transfert ; sinon transfert borné et documenté.
	if not white and terms.has("territorial"):
		_apply_territorial(state, parties, terms, rules)
	# 4. Aucune téléportation de formation : elles restent où elles sont, avec un statut d'occupation
	#    cohérent avec le nouveau contrôle (le contrôle suit la souveraineté après paix blanche).
	for rid: String in state.regions:
		var r: Dictionary = state.regions[rid]
		if white and parties.has(str(r.get("controller", ""))):
			r["controller"] = str(r.get("sovereign", ""))
	# 5. Prisonniers.
	if not terms.has("no_pow_repatriation"):
		for i: int in parties.size():
			for j: int in parties.size():
				if i == j:
					continue
				PowSystem.repatriate_on_peace(state, str(parties[i]), str(parties[j]), rules)
	# 6. Relations et mémoire.
	for i: int in parties.size():
		for j: int in parties.size():
			if i == j:
				continue
			RelationsSystem.record(state, str(parties[i]), str(parties[j]), "peace_signed", t["id"], rules)
	state.log_event("paix", "Traité de paix %s signé entre %s (blank=%s)." % [
		t["id"], str(parties), str(white)], parties)
	return t


static func _apply_territorial(state: GameState, parties: Array, terms: Dictionary, rules: Dictionary) -> void:
	var maxn := int(cfg(rules).get("territorial_max_regions", 3))
	var winner := str(parties[0])
	var loser := str(parties[1])
	var regions: Array = terms.get("regions", [])
	var moved := 0
	for rid: String in regions:
		if moved >= maxn or not state.regions.has(rid):
			continue
		var r: Dictionary = state.regions[rid]
		if str(r.get("sovereign", "")) != loser or str(r.get("controller", "")) != winner:
			continue
		r["sovereign"] = winner
		r["controller"] = winner
		moved += 1
	terms["transferred_regions"] = moved


static func universal_pact(state: GameState, nations: Array, rules: Dictionary) -> Dictionary:
	var threshold := float(cfg(rules).get("universal_peace_requires_regions", 0.9))
	var total := state.regions.size()
	var controlled := 0
	for rid: String in state.regions:
		var c := str(state.regions[rid].get("controller", ""))
		if nations.has(c) and c == str(state.regions[rid].get("sovereign", "")):
			controlled += 1
	if total == 0 or float(controlled) / float(total) < threshold:
		return {"ok": false, "reason": "contrôle insuffisant pour la paix universelle"}
	var t := {"id": state.new_id("universal_pact"), "signed_turn": state.turn,
		"type": "universal", "members": nations.duplicate(true), "status": "active",
		"note": "Pacte universel — distinct d'un traité bilatéral (condition de victoire diplomatique)."}
	(state.diplomacy["peace_treaties"] as Array).append(t)
	state.wars.clear()
	state.log_event("paix", "Pacte universel d'unité internationale signé par %s." % str(nations), nations)
	return {"ok": true, "treaty": t}
