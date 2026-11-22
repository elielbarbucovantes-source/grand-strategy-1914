class_name AllianceSystem
extends RefCounted
## Phase III.C — alliances et coalitions avec engagements réels, adhésion, sortie, dissolution
## et conséquences diplomatiques des violations. Aucune alliance n'est permanente par défaut.


static func cfg(rules: Dictionary) -> Dictionary:
	var d: Variant = rules.get("diplomacy", {}).get("alliances")
	return d if d is Dictionary else {}


static func type_cfg(rules: Dictionary, kind: String) -> Dictionary:
	var all: Dictionary = cfg(rules).get("types", {})
	var v: Variant = all.get(kind, {})
	return v if v is Dictionary else {}


static func by_id(state: GameState, aid: String) -> Dictionary:
	for a: Dictionary in state.diplomacy["alliances"]:
		if str(a["id"]) == aid:
			return a
	return {}


static func can_create(state: GameState, proposal: Dictionary, rules: Dictionary) -> bool:
	var members: Array = (proposal["to"] as Array).duplicate(true)
	members.append(str(proposal["from"]))
	var limit := int(cfg(rules).get("max_alliances_per_nation", 4))
	for m: String in members:
		var count := 0
		for a: Dictionary in state.diplomacy.get("alliances", []):
			if str(a["status"]) == "active" and (a["members"] as Array).has(m):
				count += 1
		if count >= limit:
			return false
	return true


static func create(state: GameState, proposal: Dictionary, rules: Dictionary) -> Dictionary:
	if not can_create(state, proposal, rules):
		state.log_event("diplomatie", "Alliance refusée : limite d'engagements atteinte pour %s." % str(proposal["to"]), proposal["to"])
		return {}
	var kind := str(proposal["kind"])
	var tcfg := type_cfg(rules, kind)
	var duration := int(tcfg.get("duration_turns", cfg(rules).get("default_duration_turns", 24)))
	var members: Array = (proposal["to"] as Array).duplicate(true)
	members.append(str(proposal["from"]))
	var term_val: Variant = proposal.get("terms")
	var terms: Dictionary = term_val if term_val is Dictionary else {}
	var a := {
		"id": state.new_id("alliance"), "type": kind, "members": members,
		"created_turn": state.turn, "expires_turn": state.turn + duration, "status": "active",
		"commitments": {"defensive": bool(tcfg.get("defensive", false)), "offensive": bool(tcfg.get("offensive", false)),
			"transit": bool(tcfg.get("transit", false))},
		"terms": terms.duplicate(true),
		"history": [{"turn": state.turn, "action": "created", "members": members.duplicate(true)}]
	}
	(state.diplomacy["alliances"] as Array).append(a)
	# Compatibilité : l'alliance est aussi enregistrée comme traité actif, afin que
	# Orders.break_treaty, active_treaties_between et les outils existants la voient.
	var legacy := {"id": a["id"], "type": kind, "members": members.duplicate(true), "status": "active",
		"signed": state.date_label(), "terms": a["terms"].duplicate(true),
		"terms_status": "Phase III : engagements %s" % str(a["commitments"])}
	if kind == "transit":
		legacy["grantor"] = str(proposal["to"][0])
		legacy["grantee"] = str(proposal["from"])
	state.treaties.append(legacy)
	for m: String in members:
		RelationsSystem.record(state, m, str(proposal["from"]), "treaty_signed", kind, rules)
	state.log_event("diplomatie", "Alliance « %s » conclue entre %s." % [kind, str(members)], members)
	return a


static func join(state: GameState, aid: String, nation: String, rules: Dictionary) -> String:
	var a := by_id(state, aid)
	if a.is_empty() or str(a["status"]) != "active":
		return "alliance inactive"
	if (a["members"] as Array).has(nation):
		return "déjà membre"
	if not bool(cfg(rules).get("join_requires_consent", true)):
		return "consentement requis"
	var limit := int(cfg(rules).get("max_alliances_per_nation", 4))
	var count := 0
	for x: Dictionary in state.diplomacy.get("alliances", []):
		if str(x["status"]) == "active" and (x["members"] as Array).has(nation):
			count += 1
	if count >= limit:
		return "limite d'engagements atteinte"
	for m: String in a["members"]:
		var r := RelationsSystem.between(state, nation, m, rules)
		if float(r.get("trust", 0)) < 30.0:
			return "confiance insuffisante de %s" % m
	(a["members"] as Array).append(nation)
	(a["history"] as Array).append({"turn": state.turn, "action": "joined", "member": nation})
	state.log_event("diplomatie", "%s rejoint l'alliance %s." % [state.nations[nation]["name_fr"], aid], a["members"])
	return ""


static func leave(state: GameState, aid: String, nation: String, rules: Dictionary) -> String:
	var a := by_id(state, aid)
	if a.is_empty() or str(a["status"]) != "active" or not (a["members"] as Array).has(nation):
		return "alliance inactive ou pays non membre"
	(a["members"] as Array).erase(nation)
	(a["history"] as Array).append({"turn": state.turn, "action": "left", "member": nation})
	for m: String in a["members"]:
		# RESTORATION 02 : la sortie est mémorisée et dégrade la réputation, pas seulement la confiance.
		RelationsSystem.record(state, m, nation, "alliance_exit", aid, rules)
	state.log_event("diplomatie", "%s quitte l'alliance %s." % [state.nations[nation]["name_fr"], aid], a["members"])
	if (a["members"] as Array).size() < 2:
		a["status"] = "dissolved"
	return ""


static func dissolve(state: GameState, aid: String, nation: String) -> String:
	var a := by_id(state, aid)
	if a.is_empty() or str(a["status"]) != "active" or not (a["members"] as Array).has(nation):
		return "alliance inactive ou pays non membre"
	a["status"] = "dissolved"
	(a["history"] as Array).append({"turn": state.turn, "action": "dissolved", "by": nation})
	state.log_event("diplomatie", "Alliance %s dissoute par %s." % [aid, state.nations[nation]["name_fr"]], a["members"])
	return ""


## Vérifie si `ally` est tenu de soutenir `member` dans une guerre. Dépend des termes
## et de la confiance : un membre d'alliance n'entre PAS automatiquement en guerre.
static func obligation(state: GameState, ally: String, member: String, enemy: String, rules: Dictionary) -> bool:
	if ally == member or state.at_war(ally, enemy):
		return false
	for a: Dictionary in state.diplomacy["alliances"]:
		if str(a["status"]) != "active":
			continue
		var mem: Array = a["members"]
		if not (mem.has(ally) and mem.has(member)):
			continue
		var com: Dictionary = a["commitments"]
		if state.at_war(member, enemy) and bool(com.get("defensive", false)):
			var r := RelationsSystem.between(state, ally, member, rules)
			return float(r.get("trust", 0)) >= float(cfg(rules).get("defense_obligation_min_trust", 40))
		if bool(com.get("offensive", false)):
			return true
	return false


static func allies_of(state: GameState, nation: String) -> Array:
	var out: Array = []
	for a: Dictionary in state.diplomacy["alliances"]:
		if str(a["status"]) == "active" and (a["members"] as Array).has(nation):
			for m: String in a["members"]:
				if m != nation and not out.has(m):
					out.append(m)
	return out


static func has_transit(state: GameState, grantee: String, grantor: String) -> bool:
	for a: Dictionary in state.diplomacy["alliances"]:
		if str(a["status"]) != "active" or not bool((a.get("commitments", {}) as Dictionary).get("transit", false)):
			continue
		var mem: Array = a["members"]
		if mem.has(grantee) and mem.has(grantor):
			return true
	# compatibilité : traités historiques de passage
	for t: Dictionary in state.treaties:
		if str(t["type"]) == "transit" and str(t["status"]) == "active" and str(t.get("grantee", "")) == grantee \
				and str(t.get("grantor", "")) == grantor:
			return true
	return false


static func monthly(state: GameState, rules: Dictionary) -> void:
	for a: Dictionary in state.diplomacy["alliances"]:
		if str(a["status"]) == "active" and state.turn > int(a.get("expires_turn", 9999)):
			a["status"] = "expired"
			(a["history"] as Array).append({"turn": state.turn, "action": "expired"})
			for m: String in a["members"]:
				# Correction RESTORATION 02 : le second argument est une nation, pas l'identifiant
				# de l'alliance (la pénalité était silencieusement ignorée auparavant).
				RelationsSystem.adjust(state, m, m, rules, {"trust": -2.0}, "alliance_expired")
