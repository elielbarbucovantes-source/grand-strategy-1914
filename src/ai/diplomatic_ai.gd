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
		+ ControlledVariation.from_view(view, "diplo", str(view["nation"]) + "|" + other) * 1.5 \
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
			# RESTORATION 02 : un accord commercial est moins engageant qu'une alliance
			# defensive ; son seuil d'acceptation est assoupli, pas supprime.
			var threshold := accept_th - (float(c.get("trade_accept_bonus", 15.0)) if kind == "trade" else 0.0)
			accept = score >= threshold and not hostile
		var counter := {}
		if not accept and score >= counter_th and (prop.get("counters", []) as Array).size() < 2 \
			and kind != "peace":
			counter = {"duration": 18, "reciprocal": true, "note": "contre-proposition automatique"}
		out.append(Orders.respond_agreement(me, str(prop["id"]), accept, counter))
		responses += 1

	# 2. Initiatives diplomatiques.
	# RESTORATION 01/02 : réévaluation des engagements AVANT toute autre initiative, avec un
	# budget dédié. Les motifs sont réels (confiance, rivalité, gouvernement, dépendance,
	# divergence stratégique) et filtrés par la personnalité — aucun aléa.
	var reviewed := _review_commitments(view, rules, p)
	if not reviewed.is_empty():
		out.append_array(reviewed)
		initiatives += 1
	# RESTORATION 01 : évaluation de la guerre / désescalade en priorité, budget dédié.
	var war := war_decision(view, rules, me)
	if not (war["orders"] as Array).is_empty():
		out.append_array(war["orders"])
		initiatives += 1
	# 2a. Paix si la guerre devient défavorable (effectifs propres faibles).
	if initiatives < max_init:
		var enemies := _enemies(view)
		enemies.sort()
		if not enemies.is_empty() and _weak(view, rules):
			enemies.sort()
			out.append(Orders.propose_peace(me, [enemies[0]], {"white": true}))
			initiatives += 1
	# 2b. Alliance défensive avec un voisin de confiance, si aucune alliance active.
	# RESTORATION 01 : cooldown GLOBAL par État — sans lui, un État propose chaque tour à une
	# cible différente et contourne le cooldown par cible (source du spam observé).
	var global_cooldown := int(c.get("alliance_proposal_cooldown_turns", 6))
	var recent_proposals := 0
	for prop: Dictionary in view.get("proposals", []):
		if str(prop["from"]) == me and int(view["turn"]) - int(prop.get("turn", 0)) < global_cooldown:
			recent_proposals += 1
	if initiatives < max_init and _allies(view, me).is_empty() and recent_proposals == 0:
		var best := ""
		var best_score := -1000.0
		var candidates: Array = (view.get("reputation", {}) as Dictionary).keys()
		candidates.sort()
		for other: String in candidates:
			if other == me or at_war(view, other):
				continue
			var cooldown := int(c.get("proposal_cooldown_turns", 6))
			var recently_refused := false
			for prop: Dictionary in view.get("proposals", []):
				# Tout envoi récent vers la même cible bloque une re-proposition, y compris
				# les propositions expirées ou contre-proposées (principale source de bruit).
				if str(prop["from"]) == me and (prop["to"] as Array).has(other) \
					and int(view["turn"]) - int(prop.get("turn", 0)) < cooldown:
					recently_refused = true
					break
			if recently_refused:
				continue
			var s := _score(view, other, rules)
			if s > best_score and s >= accept_th - 15.0:
				best = other
				best_score = s
		if best != "":
			# RESTORATION 02 : un partenaire de confiance et réputé peut recevoir une offre de
			# coopération scientifique plutôt qu'une alliance, sans multiplier les ordres.
			var kind := "alliance"
			var tcfg: Dictionary = c.get("tech_initiative", {})
			if not _in_tech_cooperation(view, best) \
				and float(p.get("reputation_value", 0.5)) >= float(tcfg.get("min_reputation", 0.8)) \
				and _score(view, best, rules) >= float(tcfg.get("min_score", 50.0)) \
				and ControlledVariation.from_view(view, "tech_offer", me + "|" + best) > 0.35:
				kind = "tech"
			out.append(Orders.propose_agreement(me, [best], kind, {"defensive": kind == "alliance"}))
			initiatives += 1
	# 2b-bis. RESTORATION 02 — accord commercial avec un partenaire de confiance lorsque
	# l'État manque d'une ressource stratégique. Le commerce n'est plus une fin en soi.
	if initiatives < max_init and recent_proposals == 0 and _has_trade_deficit(view, rules):
		var tcfg: Dictionary = c.get("trade_initiative", {})
		# RESTORATION 02 : cooldown dédié plus long pour les accords économiques afin d'éviter
		# qu'un État propose systématiquement tous les six tours.
		var trade_cooldown := int(tcfg.get("cooldown_turns", 12))
		var recent_trade_offer := false
		for prop: Dictionary in view.get("proposals", []):
			if str(prop["from"]) == me and str(prop.get("kind", "")) == "trade" \
				and int(view["turn"]) - int(prop.get("turn", 0)) < trade_cooldown:
				recent_trade_offer = true
				break
		if recent_trade_offer:
			return out
		var best_trade := ""
		var best_trade_score := -1000.0
		for other: String in (view.get("reputation", {}) as Dictionary).keys():
			if other == me or at_war(view, other) or _allies(view, me).has(other):
				continue
			if _has_active_kind(view, other, "trade"):
				continue
			var cooldown := int(c.get("proposal_cooldown_turns", 6))
			var refused := false
			for prop: Dictionary in view.get("proposals", []):
				if str(prop["from"]) == me and (prop["to"] as Array).has(other) \
					and int(view["turn"]) - int(prop.get("turn", 0)) < cooldown:
					refused = true
					break
			if refused:
				continue
			if float(_rel(view, me, other).get("trust", 50)) < float(tcfg.get("min_trust", 55)):
				continue
			var s := _score(view, other, rules)
			# Un partenaire voisin offre une route commerciale réellement praticable.
			if _is_neighbor(view, world, other):
				s += 30.0
			if s > best_trade_score and s >= accept_th - 30.0:
				best_trade = other
				best_trade_score = s
		if best_trade != "":
			out.append(Orders.propose_agreement(me, [best_trade], "trade", {"commercial": true}))
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
	return out


## Consolidation 01 — décision d'un État sur le Traité de Paix et d'Unité Internationale.
## Fondée sur la situation réelle et la personnalité diplomatique ; déterministe.
static func decide_universal(state: GameState, nation: String, rules: Dictionary) -> Dictionary:
	var up: Dictionary = state.diplomacy.get("universal_pact", {})
	var proposer := str(up.get("proposer", ""))
	var rel := RelationsSystem.between(state, nation, proposer, rules.get("diplomacy", {}))
	var trust := float(rel.get("trust", 50))
	var hostility := float(rel.get("hostility", 10))
	var rep := float(state.reputation.get(proposer, 0.0))
	var pol: Dictionary = {}
	if state.politics is Dictionary and (state.politics.get("states", {}) as Dictionary).has(nation):
		pol = state.politics["states"][nation]
	var stability := float(pol.get("stability", 65))
	var tension := float(pol.get("social_tension", 25))
	var at_war := false
	for w: Dictionary in state.wars:
		if (str(w["a"]) == nation and str(w["b"]) == proposer) or (str(w["b"]) == nation and str(w["a"]) == proposer):
			at_war = true
	var score := trust * 0.4 - hostility * 0.3 + rep * 0.2 + stability * 0.1 - tension * 0.1
	var dcfg: Dictionary = (rules.get("diplomacy", {}) as Dictionary).get("ai", {})
	var profiles: Dictionary = dcfg.get("personalities", {})
	var pid := str(state.personalities.get(nation, dcfg.get("default_personality", "cautious")))
	var p: Dictionary = profiles.get(pid, {}) if profiles.get(pid) is Dictionary else {}
	var bias := float(p.get("trust_bias", 0)) * 0.3 - float(p.get("hostility_bias", 0)) * 0.2
	if pid == "honourable":
		bias += 6.0
	if str(state.personalities.get(nation, "")) == "expansionist":
		bias -= 10.0
	if at_war:
		bias -= 20.0
	score += bias
	var accept := score >= 25.0
	var reason := "confiance suffisante" if accept else "méfiance ou situation défavorable"
	if at_war and not accept:
		reason = "guerre en cours avec le proposant"
	elif tension > 70.0 and not accept:
		reason = "instabilité intérieure"
	return {"accept": accept, "reason": reason, "score": score}


## RESTORATION 01 — décision autonome de guerre ou de désescalade.
## Retourne {"orders":[...], "used":bool}. Plusieurs garde-fous empêchent une cascade :
##  - maturité (pas de guerre dans les premiers mois) ;
##  - capacité réelle : seules les puissances à forces historiques et fonds suffisants décident ;
##  - rivalité stable et documentée (la rivalité n'est pas gonflée par les déclarations) ;
##  - cooldown par État et risque d'escalade pris en compte.
static func war_decision(view: Dictionary, rules: Dictionary, nid: String) -> Dictionary:
	var cfg: Dictionary = rules.get("diplomacy", {}).get("ai", {})
	if bool(cfg.get("allow_automatic_war", true)) == false:
		return {"orders": [], "used": false}
	var p := personality(view, rules)
	var likelihood := float(p.get("war_likelihood", 0.3))
	var mining: Dictionary = cfg.get("war_thresholds", {})
	# 1. Maturité : une crise mûrit avant de dégénérer (juillet 1914, pas janvier).
	var turn := int(view.get("turn", 0))
	if turn < int(mining.get("earliest_war_turn", 7)):
		return {"orders": [], "used": false}
	# 2. Capacité réelle : pas de guerre sans forces modélisées et sans trésorerie.
	var own_forces: Dictionary = view.get("own_forces", {})
	if str(own_forces.get("source_type", "")) != "historical":
		return {"orders": [], "used": false}
	var soldiers := int(own_forces.get("present_in_units", 0)) + int(own_forces.get("present_services", 0))
	var money := float(view.get("own_money", 0.0))
	if soldiers < int(mining.get("min_soldiers", 30000)) or money < float(mining.get("min_money", 50.0)):
		return {"orders": [], "used": false}
	# 3. Cooldown : au plus une nouvelle guerre par État sur une période donnée.
	var cooldown := int(mining.get("war_cooldown_turns", 6))
	for w: Dictionary in view.get("wars", []):
		if (str(w["a"]) == nid or str(w["b"]) == nid) and turn - int(w.get("since_turn", 0)) < cooldown:
			return {"orders": [], "used": false}
	var stability := float(view.get("own_stability", 65.0))
	if stability < float(mining.get("min_stability", 40.0)):
		return {"orders": [], "used": false}
	var tension_need := float(mining.get("tension", 65.0)) - likelihood * 15.0
	var hostility_need := float(mining.get("hostility", 55.0)) - likelihood * 10.0
	var rivalry_need := float(mining.get("rivalry", 55.0))
	var ids: Array = (view.get("nation_order", []) as Array).duplicate()
	ids.sort()
	var best := ""
	var best_score := -1.0
	for other: String in ids:
		if other == nid or at_war(view, other):
			continue
		var rel := _rel(view, nid, other)
		var tension := float(rel.get("tensions", 0))
		var hostility := float(rel.get("hostility", 10))
		var rivalry := float(rel.get("rivalry", 20))
		if tension < tension_need or hostility < hostility_need or rivalry < rivalry_need:
			continue
		if _allies(view, nid).has(other):
			continue  # un engagement empêche l'agression, sauf trahison explicite
		var allies := _allies(view, other).size()
		var risk := 1.0 + float(allies) * 0.35
		var noise := ControlledVariation.from_view(view, "war", nid + "|" + other) * 8.0
		var score := rivalry * 0.6 + tension * 0.25 + hostility * 0.15 \
			+ likelihood * 20.0 + noise - risk * 9.0
		if score > best_score:
			best = other
			best_score = score
	if best == "" or best_score < float(mining.get("min_score", 60.0)):
		# Désescalade crédible : les profils qui valorisent leur réputation proposent une médiation.
		if float(p.get("reputation_value", 0.5)) >= 0.7:
			for cr: Dictionary in view.get("crises", []):
				if (cr["parties"] as Array).has(nid) and not (cr["mediators"] as Array).has(nid):
					return {"orders": [Orders.offer_mediation(nid, str(cr["id"]))], "used": true}
		return {"orders": [], "used": false}
	return {"orders": [Orders.declare_war(nid, best)], "used": true}


## RESTORATION 02 — réévaluation déterministe des engagements. Retourne un motif ou "".
static func _betrayal_reason(view: Dictionary, rules: Dictionary, p: Dictionary, me: String, other: String) -> String:
	var c := cfg(rules)
	var r: Dictionary = cfg(rules).get("commitment_review", {})
	var rel := _rel(view, me, other)
	var trust := float(rel.get("trust", 50))
	var threshold := float(c.get("betrayal_trust_threshold", 25))
	var reputation := float(p.get("reputation_value", 0.5))
	var warlike := float(p.get("war_likelihood", 0.3))
	# Motif 1 : confiance effondrée — valable pour toutes les personnalités.
	if trust < threshold:
		return "confiance effondrée"
	# Les profils qui valorisent leur réputation honorent leurs accords sauf cas extrême.
	if reputation >= float(r.get("loyal_reputation", 1.0)):
		return ""
	if warlike < float(r.get("min_war_likelihood", 0.4)) and reputation >= 0.7:
		return ""
	# Motif 2 : nouvelle rivalité avec un allié.
	if float(rel.get("rivalry", 20)) >= float(r.get("rivalry", 70)) \
		and float(rel.get("tensions", 0)) >= float(r.get("tensions", 60)) and warlike >= 0.6:
		return "rivalité devenue insoluble"
	# Motif 3 : changement de gouvernement récent — réexamen des engagements.
	var gov := int(view.get("own_government_turn", -1))
	if gov >= 0 and int(view["turn"]) - gov <= int(r.get("government_window", 6)) \
		and trust < float(r.get("government_trust", 45)) and warlike >= 0.5:
		return "changement de gouvernement"
	# Motif 4 : dépendance commerciale dangereuse — diversification des partenaires.
	var dep: Dictionary = view.get("own_dependence", {})
	var total := 0.0
	for v: float in dep.values():
		total += v
	if total > 0.0 and float(dep.get(other, 0.0)) / total >= float(r.get("dependence_share", 0.6)) \
		and reputation < 0.7 and warlike >= 0.5:
		return "dépendance commerciale excessive"
	# Motif 5 : divergence stratégique — l'allié combat un État en qui j'ai confiance.
	for w: Dictionary in view.get("wars", []):
		var other_party := ""
		if str(w["a"]) == other:
			other_party = str(w["b"])
		elif str(w["b"]) == other:
			other_party = str(w["a"])
		if other_party != "" and other_party != me \
			and float(_rel(view, me, other_party).get("trust", 50)) >= float(r.get("friend_trust", 65)):
			return "divergence stratégique"
	return ""


static func _review_commitments(view: Dictionary, rules: Dictionary, p: Dictionary) -> Array:
	var out: Array = []
	var me := str(view["nation"])
	for a: Dictionary in view.get("alliances", []):
		if str(a.get("status", "")) != "active" or not (a["members"] as Array).has(me):
			continue
		for m: String in a["members"]:
			if m == me:
				continue
			var reason := _betrayal_reason(view, rules, p, me, m)
			if reason == "":
				continue
			var politics := str(a.get("type", a.get("kind", "")))
			if float(p.get("reputation_value", 0.5)) < 0.6 and politics != "":
				# Trahison mémorisée et pénalité de réputation, si un traité existe réellement.
				var found := false
				for t: Dictionary in view.get("public_treaties", []):
					if str(t["id"]) == str(a["id"]) and str(t["status"]) == "active":
						found = true
						break
				if found:
					out.append(Orders.break_treaty(me, str(a["id"])))
				else:
					out.append(Orders.leave_alliance(me, str(a["id"])))
			else:
				out.append(Orders.leave_alliance(me, str(a["id"])))
			return out  # au plus une rupture par État et par tour
	return out



## RESTORATION 02 — coopération scientifique déjà active avec un partenaire.
static func _in_tech_cooperation(view: Dictionary, other: String) -> bool:
	var me := str(view["nation"])
	for co: Dictionary in view.get("tech_cooperation", []):
		if str(co.get("status", "")) != "active" or int(view["turn"]) > int(co.get("expires_turn", 0)):
			continue
		if (co["members"] as Array).has(me) and (co["members"] as Array).has(other):
			return true
	return false


## RESTORATION 02 — voisinage territorial depuis la vue politique publique (aucun secret).
static func _is_neighbor(view: Dictionary, world: WorldMap, other: String) -> bool:
	var me := str(view["nation"])
	var mine: Array = []
	var theirs: Dictionary = {}
	for rid: String in view.get("political", {}):
		var owner := str((view["political"][rid] as Dictionary).get("controller", ""))
		if owner == me:
			mine.append(rid)
		elif owner == other:
			theirs[rid] = true
	if theirs.is_empty():
		return false
	for rid: String in mine:
		for n: String in world.neighbor_ids(rid, true):
			if theirs.has(n):
				return true
	return false


## RESTORATION 02 — un État cherche un accord commercial s'il manque d'une ressource stratégique.
static func _has_trade_deficit(view: Dictionary, rules: Dictionary) -> bool:
	var tcfg: Dictionary = cfg(rules).get("trade_initiative", {})
	var stocks: Dictionary = view.get("own_stocks", {})
	var threshold := float(tcfg.get("min_stock", 5.0))
	for res: String in tcfg.get("resources", ["coal", "iron", "grain", "oil", "wood"]):
		if float(stocks.get(res, 0.0)) < threshold:
			return true
	return false


static func _has_active_kind(view: Dictionary, other: String, kind: String) -> bool:
	for t: Dictionary in view.get("public_treaties", []):
		if str(t.get("status", "")) != "active" or str(t.get("kind", t.get("type", ""))) != kind:
			continue
		if (t["members"] as Array).has(str(view["nation"])) and (t["members"] as Array).has(other):
			return true
	for a: Dictionary in view.get("alliances", []):
		if str(a.get("status", "")) != "active" or str(a.get("type", "")) != kind:
			continue
		if (a["members"] as Array).has(str(view["nation"])) and (a["members"] as Array).has(other):
			return true
	return false


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
