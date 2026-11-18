class_name DiplomaticAI
extends RefCounted
## Phase III.G — IA diplomatique autonome. Décide depuis la vue filtrée uniquement :
## personnalité, mémoire des trahisons, relations, réputation publique et menace perçue.
## Déterministe (pas d'aléa), avec un nombre maximal d'initiatives et de réponses par tour.


static func cfg(rules: Dictionary) -> Dictionary:
	var d: Variant = rules.get("diplomacy", {}).get("ai")
	return d if d is Dictionary else {}


static func personality(view: Dictionary, rules: Dictionary) -> Dictionary:
	var c := cfg(rules)
	var profiles: Dictionary = c.get("personalities", {})
	var id := str(view.get("personality", c.get("default_personality", "cautious")))
	var p: Variant = profiles.get(id, profiles.get(str(c.get("default_personality", "cautious")), {}))
	return p if p is Dictionary else {}


static func _rel(view: Dictionary, a: String, b: String) -> Dictionary:
	var k := a + "|" + b if a < b else b + "|" + a
	var all: Dictionary = view.get("relations", {})
	var r: Variant = all.get(k)
	return r if r is Dictionary else {}


static func _betrayed(view: Dictionary, other: String) -> bool:
	for m: Dictionary in view.get("memory", []):
		if str(m.get("about", "")) == other and str(m.get("kind", "")) in ["treaty_broken", "declared_war", "alliance_betrayal"]:
			return true
	return false


static func _score(view: Dictionary, other: String, rules: Dictionary) -> float:
	var r := _rel(view, str(view["nation"]), other)
	var p := personality(view, rules)
	var rep: Dictionary = view.get("reputation", {})
	return float(r.get("trust", 50)) - float(r.get("hostility", 10)) * 0.7 \
		- float(r.get("tensions", 0)) * 0.4 + float(r.get("cooperation", 20)) * 0.3 \
		+ float(rep.get(other, 0)) * 0.15 \
		+ float(p.get("trust_bias", 0)) - float(p.get("hostility_bias", 0)) * 0.5 \
		- (25.0 if _betrayed(view, other) else 0.0)


static func at_war(view: Dictionary, other: String) -> bool:
	for w: Dictionary in view.get("wars", []):
		if (str(w["a"]) == str(view["nation"]) and str(w["b"]) == other) \
			or (str(w["b"]) == str(view["nation"]) and str(w["a"]) == other):
			return true
	return false


static func decide(view: Dictionary, world: WorldMap, rules: Dictionary) -> Array:
	var me := str(view["nation"])
	var c := cfg(rules)
	var p := personality(view, rules)
	var out: Array = []
	var responses := 0
	var initiatives := 0
	var max_resp := int(c.get("max_responses_per_turn", 3))
	var max_init := int(c.get("max_initiatives_per_turn", 2))
	var accept_th := float(c.get("accept_trust_threshold", 55))
	var refuse_th := float(c.get("refuse_hostility_threshold", 60))
	var counter_th := float(c.get("counter_probability_threshold", 55))

	# 1. Réponses aux propositions reçues (ordonnées par identifiant : déterministe).
	var pend: Array = (view.get("pending_proposals", []) as Array).duplicate(true)
	pend.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
	for prop: Dictionary in pend:
		if responses >= max_resp:
			break
		var from := str(prop["from"])
		var kind := str(prop.get("kind", ""))
		var score := _score(view, from, rules)
		var hostile := float(_rel(view, me, from).get("hostility", 10)) >= refuse_th
		var accept := false
		if kind == "peace":
			accept = at_war(view, from) and (score > 30.0 or float(p.get("war_likelihood", 0.5)) < 0.5)
		elif at_war(view, from) and kind != "pow_exchange":
			accept = false
		elif _betrayed(view, from):
			accept = score > accept_th + 20.0 and float(p.get("reputation_value", 0.5)) < 0.6
		else:
			accept = score >= accept_th and not hostile
		var counter := {}
		if not accept and score >= counter_th and (prop.get("counters", []) as Array).size() < 2 \
			and kind != "peace":
			counter = {"duration": 18, "reciprocal": true, "note": "contre-proposition automatique"}
		out.append(Orders.respond_agreement(me, str(prop["id"]), accept, counter))
		responses += 1

	# 2. Initiatives diplomatiques.
	# 2a. Paix si la guerre devient défavorable (effectifs propres faibles).
	if initiatives < max_init:
		var enemies := _enemies(view)
		enemies.sort()
		if not enemies.is_empty() and _weak(view, rules):
			enemies.sort()
			out.append(Orders.propose_peace(me, [enemies[0]], {"white": true}))
			initiatives += 1
	# 2b. Alliance défensive avec un voisin de confiance, si aucune alliance active.
	if initiatives < max_init and _allies(view, me).is_empty():
		var best := ""
		var best_score := -1000.0
		var candidates: Array = (view.get("reputation", {}) as Dictionary).keys()
		candidates.sort()
		for other: String in candidates:
			if other == me or at_war(view, other):
				continue
			var s := _score(view, other, rules)
			if s > best_score and s >= accept_th - 5.0:
				best = other
				best_score = s
		if best != "":
			out.append(Orders.propose_agreement(me, [best], "alliance", {"defensive": true}))
			initiatives += 1
	# 2c. Échange de prisonniers avantageux.
	if initiatives < max_init and int(view.get("pow", {}).get("held", 0)) > 0:
		for other: String in _enemies(view) + _allies(view, me):
			out.append(Orders.exchange_pow(me, other))
			initiatives += 1
			break
	# 2d. Réponse à une crise : modérée ou ferme selon la personnalité.
	if initiatives < max_init:
		var crises: Array = view.get("crises", [])
		crises.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
		for cr: Dictionary in crises:
			if initiatives >= max_init:
				break
			var parties: Array = cr["parties"]
			if parties.has(me):
				var action := "protest"
				if float(p.get("war_likelihood", 0.5)) < 0.5 and float(cr.get("tension", 0)) > 45.0:
					action = "concede"
				elif float(cr.get("tension", 0)) > 65.0 and float(p.get("war_likelihood", 0.5)) > 0.7:
					action = "mobilize"
				out.append(Orders.crisis_response(me, str(cr["id"]), action))
				initiatives += 1
			elif not (cr["mediators"] as Array).has(me) and float(p.get("reputation_value", 0.5)) >= 0.7:
				out.append(Orders.offer_mediation(me, str(cr["id"])))
				initiatives += 1
	# 2e. Trahison calculée : quitter une alliance devenue hostile (pas de guerre automatique).
	if initiatives < max_init and float(p.get("war_likelihood", 0.5)) >= 0.8:
		var alls: Array = view.get("alliances", [])
		for a: Dictionary in alls:
			if str(a.get("status", "")) != "active" or not (a["members"] as Array).has(me):
				continue
			for m: String in a["members"]:
				if m != me and float(_rel(view, me, m).get("trust", 50)) < float(c.get("betrayal_trust_threshold", 25)):
					out.append(Orders.leave_alliance(me, str(a["id"])))
					initiatives += 1
					break
			if initiatives >= max_init:
				break
	return out


static func _enemies(view: Dictionary) -> Array:
	var out: Array = []
	var me := str(view["nation"])
	for w: Dictionary in view.get("wars", []):
		if str(w["a"]) == me and not out.has(str(w["b"])):
			out.append(str(w["b"]))
		elif str(w["b"]) == me and not out.has(str(w["a"])):
			out.append(str(w["a"]))
	out.sort()
	return out


static func _allies(view: Dictionary, me: String) -> Array:
	var out: Array = []
	for a: Dictionary in view.get("alliances", []):
		if str(a.get("status", "")) == "active" and (a["members"] as Array).has(me):
			for m: String in a["members"]:
				if m != me and not out.has(m):
					out.append(m)
	out.sort()
	return out


static func _weak(view: Dictionary, rules: Dictionary) -> bool:
	var own: Dictionary = view.get("own_forces", {})
	var present := int(own.get("present_in_units", 0)) + int(own.get("present_services", 0))
	var hostile := 0
	for f: Dictionary in view.get("formations", []):
		if str(f.get("nation", "")) != str(view["nation"]) and at_war(view, str(f.get("nation", ""))):
			hostile += 1
	return present < 40000 or hostile > 2
