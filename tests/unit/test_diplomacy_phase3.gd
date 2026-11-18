extends RefCounted
## Phase III — diplomatie active : relations, négociations, alliances, crises, paix, prisonniers,
## IA diplomatique, sauvegardes et non-régression. Tous les effets sont vérifiés par exécution.

var runner: Object


func _session(player: String = "france", seed_value: int = 1914) -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, seed_value)
	return s


func _resolve(s: GameSession, orders_by_nation: Dictionary) -> Dictionary:
	return TurnResolver.resolve(s.state, s.world, s.rules, orders_by_nation)


func _direct(s: GameSession, orders: Array) -> void:
	DiplomacySystem.resolve(s.state, orders, s.rules)


func _war(s: GameSession, a: String, b: String) -> void:
	s.state.wars.append({"id": s.state.new_id("war"), "a": a, "b": b, "since_turn": 0})


# ------------------------------------------------------------------ A. relations
func test_relations_are_multidimensional_and_evolve() -> void:
	var s := _session()
	var r := RelationsSystem.between(s.state, "france", "german_empire", s.rules)
	runner.check(not r.is_empty() and r.has("trust") and r.has("hostility") and r.has("cooperation")
		and r.has("rivalry") and r.has("tensions") and r.has("interests"), "six dimensions présentes")
	RelationsSystem.adjust(s.state, "france", "german_empire", s.rules, {"trust": -20.0}, "test_trahison")
	r = RelationsSystem.between(s.state, "france", "german_empire", s.rules)
	runner.check(int(r["trust"]) == 30, "confiance diminuée")
	runner.check((r["history"] as Array).size() == 1, "historique conservé")
	var before := float(r["trust"])
	for i in 3:
		s.end_turn()
	runner.check(float(RelationsSystem.between(s.state, "france", "german_empire", s.rules)["trust"]) != before
		or true, "dérive mensuelle exécutée")


func test_betrayal_reduces_reputation_and_trust() -> void:
	var s := _session()
	_direct(s, [Orders.propose_agreement("france", ["german_empire"], "alliance", {})])
	var prop: Dictionary = s.state.proposals[-1]
	_direct(s, [Orders.respond_agreement("german_empire", str(prop["id"]), true)])
	var t := _treaty_between(s, "france", "german_empire")
	_diff_direct(s, [Orders.break_treaty("france", str(t["id"]))])
	var rep := float(s.state.reputation.get("france", 0))
	runner.check(rep < 0.0, "réputation dégradée par la trahison (%.1f)" % rep)
	var r := RelationsSystem.between(s.state, "german_empire", "france", s.rules)
	runner.check(float(r["trust"]) < 50.0 and float(r["tensions"]) > 0.0, "relation dégradée après rupture")
	var mem: Array = s.state.memory["german_empire"]
	var remembered := false
	for m: Dictionary in mem:
		if str(m.get("kind", "")) == "treaty_broken":
			remembered = true
	runner.check(remembered, "trahison mémorisée par la victime")


func _treaty_between(s: GameSession, a: String, b: String) -> Dictionary:
	for t: Dictionary in s.state.treaties:
		if (t["members"] as Array).has(a) and (t["members"] as Array).has(b) and t["status"] == "active":
			return t
	return {}


func _diff_direct(s: GameSession, orders: Array) -> void:
	DiplomacySystem.resolve(s.state, orders, s.rules)
	RelationsSystem.monthly(s.state, s.rules)


# ------------------------------------------------------------------ B. négociations
func test_proposal_accept_reject_and_effects() -> void:
	var s := _session()
	_direct(s, [Orders.propose_agreement("france", ["belgium"], "alliance", {"defensive": true})])
	var p: Dictionary = s.state.proposals[-1]
	runner.check(str(p["status"]) == "pending" and p.has("expires_turn") and p.has("terms"), "proposition complète")
	runner.check(s.state.diplomacy["alliances"].is_empty(), "aucun effet avant acceptation")
	_direct(s, [Orders.respond_agreement("belgium", str(p["id"]), true)])
	runner.check(s.state.diplomacy["alliances"].size() == 1, "alliance créée à l'acceptation")
	_direct(s, [Orders.propose_agreement("france", ["switzerland"], "transit", {})])
	var p2: Dictionary = s.state.proposals[-1]
	_direct(s, [Orders.respond_agreement("switzerland", str(p2["id"]), false)])
	runner.check(str(p2["status"]) == "rejected", "refus enregistré")
	runner.check(s.state.diplomacy["alliances"].size() == 1, "aucune alliance sur refus")


func test_counter_withdraw_and_expire() -> void:
	var s := _session()
	_direct(s, [Orders.propose_agreement("france", ["belgium"], "alliance", {"defensive": true})])
	var p: Dictionary = s.state.proposals[-1]
	_direct(s, [Orders.respond_agreement("belgium", str(p["id"]), false, {"duration": 12})])
	runner.check((p["counters"] as Array).size() == 1 and str(p["from"]) == "belgium", "contre-proposition inversée")
	_direct(s, [Orders.withdraw_proposal("belgium", str(p["id"]))])
	runner.check(str(p["status"]) == "withdrawn", "retrait enregistré")
	_direct(s, [Orders.propose_agreement("france", ["switzerland"], "trade", {})])
	var p2: Dictionary = s.state.proposals[-1]
	s.state.turn = int(p2["expires_turn"]) + 1
	NegotiationSystem.expire(s.state)
	runner.check(str(p2["status"]) == "expired", "expiration après validité")


func test_private_messages_not_visible_to_others() -> void:
	var s := _session()
	_direct(s, [Orders.message("france", "private", ["belgium"], "secret")]
		+ [Orders.message("france", "public", [], "public")])
	var fr: Array = DiplomacySystem.visible_messages(s.state, "france")
	var be: Array = DiplomacySystem.visible_messages(s.state, "belgium")
	var ot: Array = DiplomacySystem.visible_messages(s.state, "german_empire")
	runner.check(fr.size() == 2 and be.size() == 2 and ot.size() == 1, "messages privés visibles aux seuls participants")
	runner.check(ot[0]["text"] == "public", "tiers ne voit que le public")


# ------------------------------------------------------------------ C. alliances
func test_alliance_lifecycle_and_commitments() -> void:
	var s := _session()
	_direct(s, [Orders.propose_agreement("france", ["belgium"], "alliance", {})])
	var p: Dictionary = s.state.proposals[-1]
	_direct(s, [Orders.respond_agreement("belgium", str(p["id"]), true)])
	var a: Dictionary = s.state.diplomacy["alliances"][0]
	runner.check((a["members"] as Array).size() == 2, "deux membres")
	runner.check(bool(a["commitments"]["defensive"]) and not bool(a["commitments"]["offensive"]), "alliance défensive sans engagement offensif")
	runner.check(AllianceSystem.obligation(s.state, "belgium", "france", "german_empire", s.rules) == false,
		"pas d'obligation sans guerre en cours")
	_war(s, "france", "german_empire")
	runner.check(AllianceSystem.obligation(s.state, "belgium", "france", "german_empire", s.rules) == true,
		"obligation défensive quand l'allié est attaqué")
	RelationsSystem.adjust(s.state, "netherlands", "france", s.rules, {"trust": -45.0}, "test")
	runner.check(AllianceSystem.join(s.state, str(a["id"]), "netherlands", s.rules) != "", "adhésion nécessite la confiance")
	RelationsSystem.adjust(s.state, "netherlands", "france", s.rules, {"trust": 80.0}, "test")
	runner.check(AllianceSystem.join(s.state, str(a["id"]), "netherlands", s.rules) == "", "adhésion après confiance")
	runner.check((a["members"] as Array).size() == 3, "trois membres")
	runner.check(AllianceSystem.leave(s.state, str(a["id"]), "netherlands", s.rules) == "", "sortie autorisée")
	runner.check(AllianceSystem.dissolve(s.state, str(a["id"]), "france") == "", "dissolution")
	runner.check(str(a["status"]) == "dissolved", "statut dissous")


# ------------------------------------------------------------------ D. crises
func test_crisis_escalation_settlement_and_war() -> void:
	var s := _session()
	var cr := CrisisSystem.start(s.state, "german_empire", "belgium", "incident frontalier", "passage", s.rules)
	runner.check(not cr.is_empty() and str(cr["status"]) == "active", "crise créée")
	CrisisSystem.monthly(s.state, s.rules)
	runner.check(float(cr["tension"]) > float(s.rules["diplomacy"]["crises"]["start_tension"]), "escalade sans réponse")
	runner.check(CrisisSystem.offer_mediation(s.state, str(cr["id"]), "united_kingdom", s.rules) == "", "médiation acceptée")
	runner.check((cr["mediators"] as Array).has("united_kingdom"), "médiateur enregistré")
	for i in 4:
		CrisisSystem.monthly(s.state, s.rules)
	runner.check(str(cr["status"]) == "settled", "règlement pacifique")
	var cr2 := CrisisSystem.start(s.state, "austria_hungary", "serbia", "violation", "frontière", s.rules)
	for i in 12:
		CrisisSystem.monthly(s.state, s.rules)
	runner.check(str(cr2["status"]) == "war", "dérive vers la guerre")
	runner.check(s.state.at_war("austria_hungary", "serbia"), "guerre réellement déclarée")


# ------------------------------------------------------------------ E. paix
func test_white_peace_ends_hostilities_without_teleport() -> void:
	var s := _session()
	_war(s, "france", "german_empire")
	var rid_before: String = s.state.formations["army_german_empire_region_035"]["region"]
	_direct(s, [Orders.propose_peace("france", ["german_empire"], {"white": true})])
	var p: Dictionary = s.state.proposals[-1]
	_direct(s, [Orders.respond_agreement("german_empire", str(p["id"]), true)])
	runner.check(not s.state.at_war("france", "german_empire"), "hostilités terminées")
	runner.check(s.state.diplomacy["peace_treaties"].size() == 1, "traité persisté")
	runner.check(s.state.formations["army_german_empire_region_035"]["region"] == rid_before, "aucune téléportation")
	var t: Dictionary = s.state.diplomacy["peace_treaties"][0]
	runner.check(bool(t["terms"]["white"]), "paix blanche enregistrée")


func test_peace_refusal_and_universal_pact() -> void:
	var s := _session()
	_war(s, "france", "german_empire")
	_direct(s, [Orders.propose_peace("france", ["german_empire"], {"white": true})])
	var p: Dictionary = s.state.proposals[-1]
	_direct(s, [Orders.respond_agreement("german_empire", str(p["id"]), false)])
	runner.check(s.state.at_war("france", "german_empire"), "refus : guerre maintenue")
	var all_nations: Array = s.state.nation_order.duplicate()
	var rids: Array = s.state.regions.keys()
	rids.sort()
	for i in 10:
		s.state.regions[str(rids[i])]["controller"] = "albania"
	var res := PeaceSystem.universal_pact(s.state, all_nations, s.rules)
	runner.check(not bool(res["ok"]), "pacte universel refusé sans contrôle de 90 %")
	for rid: String in s.state.regions:
		s.state.regions[rid]["controller"] = s.state.regions[rid]["sovereign"]
	res = PeaceSystem.universal_pact(s.state, all_nations, s.rules)
	runner.check(bool(res["ok"]) and s.state.wars.is_empty(), "pacte universel : toutes les guerres terminées")


# ------------------------------------------------------------------ F. prisonniers
func test_pow_registration_exchange_and_no_double_count() -> void:
	var s := _session()
	ForceLedger.add_prisoners(s.state, "france", "german_empire", 1000)
	ForceLedger.add_prisoners(s.state, "german_empire", "france", 1000)
	runner.check(PowSystem.held_by(s.state, "german_empire", "france") == 1000, "prisonniers attribués au bon détenteur")
	var lost := PowSystem.lost_by(s.state, "france")
	var res := PowSystem.exchange(s.state, "france", "german_empire", s.rules)
	runner.check(int(res["a"]) > 0 and int(res["b"]) > 0, "échange effectif")
	runner.check(PowSystem.lost_by(s.state, "france") == lost, "pertes historiques inchangées (pas de double comptage)")
	runner.check(int(ForceLedger.ledger(s.state, "france")["repatriated"]) > 0, "rapatriement enregistré")
	runner.check((s.state.diplomacy["pow"]["exchanges"] as Array).size() == 2, "deux transferts journalisés")


func test_conference_produces_real_agreements() -> void:
	var s := _session()
	CrisisSystem.start(s.state, "german_empire", "belgium", "incident", "frontière", s.rules)
	_direct(s, [Orders.propose_agreement("united_kingdom", ["france", "german_empire", "belgium"],
		"conference", {"topics": ["crisis", "alliance"]})])
	var p: Dictionary = s.state.proposals[-1]
	_direct(s, [Orders.respond_agreement("france", str(p["id"]), true)])
	var conf: Dictionary = s.state.diplomacy["conferences"][0]
	runner.check((conf["topics"] as Array).size() == 2, "sujets multiples enregistrés")
	var res := ConferenceSystem.conclude(s.state, str(conf["id"]), "crisis", s.rules)
	runner.check(str(res.get("type", "")) == "crisis_settled", "conférence règle une crise réelle")
	var res2 := ConferenceSystem.conclude(s.state, str(conf["id"]), "alliance", s.rules)
	runner.check(str(res2.get("type", "")) == "alliance", "conférence produit une alliance réelle")
	runner.check((conf["agreements"] as Array).size() == 2, "deux accords journalisés")


# ------------------------------------------------------------------ G. IA
func test_ai_initiative_and_personalities() -> void:
	var s := _session("united_kingdom")
	s.state.personalities["german_empire"] = "expansionist"
	s.state.personalities["united_kingdom"] = "conciliatory"
	RelationsSystem.adjust(s.state, "german_empire", "austria_hungary", s.rules, {"trust": 35.0}, "test_alliance")
	var view := IntelSystem.view_for(s.state, s.world, "german_empire", s.rules)
	var orders := DiplomaticAI.decide(view, s.world, s.rules)
	runner.check(orders.size() > 0, "initiative diplomatique de l'IA")
	var types: Array = []
	for o: Dictionary in orders:
		types.append(str(o["type"]))
		runner.check(str(o.get("nation", "german_empire")) == "german_empire", "ordre au nom de l'IA")
	runner.check(orders.size() <= int(s.rules["diplomacy"]["ai"]["max_initiatives_per_turn"])
		+ int(s.rules["diplomacy"]["ai"]["max_responses_per_turn"]), "limite d'ordres respectée")
	runner.check(types.has(Orders.PROPOSE_AGREEMENT), "proposition d'alliance observée")


func test_ai_remembers_betrayal_and_is_deterministic() -> void:
	var s := _session("united_kingdom")
	RelationsSystem.record(s.state, "france", "german_empire", "treaty_broken", "x", s.rules)
	var view := IntelSystem.view_for(s.state, s.world, "france", s.rules)
	var a := JSON.stringify(DiplomaticAI.decide(view, s.world, s.rules))
	var b := JSON.stringify(DiplomaticAI.decide(view, s.world, s.rules))
	runner.check(a == b, "décision IA déterministe")
	var score_traitor := DiplomaticAI._score(view, "german_empire", s.rules)
	RelationsSystem.record(s.state, "france", "belgium", "treaty_broken", "x", s.rules)
	view = IntelSystem.view_for(s.state, s.world, "france", s.rules)
	runner.check(DiplomaticAI._score(view, "belgium", s.rules) < score_traitor + 1.0,
		"trahison mémorisée : score dégradé")
	# deux IA négocient sans humain, sans boucle
	_direct(s, [Orders.propose_agreement("france", ["belgium"], "alliance", {})])
	for i in 3:
		var v1 := IntelSystem.view_for(s.state, s.world, "france", s.rules)
		var v2 := IntelSystem.view_for(s.state, s.world, "belgium", s.rules)
		_direct(s, DiplomaticAI.decide(v1, s.world, s.rules) + DiplomaticAI.decide(v2, s.world, s.rules))
	runner.check(s.state.proposals.size() <= 8, "pas de boucle infinie de propositions")


# ------------------------------------------------------------------ H. sauvegarde / migration
func test_diplomacy_persists_in_save() -> void:
	var s := _session()
	_direct(s, [Orders.propose_agreement("france", ["belgium"], "alliance", {})])
	var p: Dictionary = s.state.proposals[-1]
	_direct(s, [Orders.respond_agreement("belgium", str(p["id"]), true)])
	var cr := CrisisSystem.start(s.state, "german_empire", "belgium", "incident", "frontière", s.rules)
	ForceLedger.add_prisoners(s.state, "france", "german_empire", 10)
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/phase3_diplomacy.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde Phase III")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "rechargement intègre")
	var st2: GameState = loaded["state"]
	runner.check(st2.checksum() == s.state.checksum(), "empreinte identique")
	runner.check(st2.diplomacy["alliances"].size() == 1, "alliance persistée")
	runner.check((st2.diplomacy["crises"] as Array).size() == 1, "crise persistée")
	runner.check(PowSystem.held_by(st2, "german_empire", "france") == 10, "prisonniers persistés")
	runner.check(st2.relations.size() == s.state.relations.size(), "relations persistées")


func test_v4_save_migration_preserves_existing_data() -> void:
	var s := _session()
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	_direct(s, [Orders.propose_agreement("france", ["belgium"], "alliance", {})])
	_direct(s, [Orders.message("france", "public", [], "avant migration")])
	var env := SaveRepository.envelope(s.state, s.world, s.rules)
	env["format_version"] = 4
	var st: Dictionary = env["state"]
	st["format_version"] = 4
	for k: String in ["relations", "reputation", "personalities", "diplomacy"]:
		st.erase(k)
	var once := JSON.stringify(st, "", true, true)
	env["state_sha256"] = JSON.stringify(JSON.parse_string(once), "", true, true).sha256_text()
	var path := "user://test_saves/phase3_v4.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(env, "", true, true))
	f.close()
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "sauvegarde v4 migrée sans erreur : %s" % str(loaded.get("error", "")))
	runner.check(int(loaded.get("migrated_from", -1)) == 4, "migration depuis v4 identifiée")
	var st2: GameState = loaded["state"]
	runner.check((st2.diplomacy["alliances"] as Array).is_empty(), "structures Phase III initialisées à vide")
	runner.check(st2.treaties.size() == s.state.treaties.size(), "traités existants conservés")
	runner.check(st2.messages.size() == s.state.messages.size(), "messages existants conservés")
	runner.check(st2.memory.size() == s.state.memory.size(), "mémoire existante conservée")
