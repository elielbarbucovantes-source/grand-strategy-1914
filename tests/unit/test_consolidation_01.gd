extends RefCounted
## Consolidation 01 — traité universel accessible, personnalités opérationnelles, textes UI.

var runner: Object


func _session(player: String = "france") -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, 1914)
	return s


# ------------------------------------------------------------------ traité universel
func test_universal_proposal_and_progressive_signatures() -> void:
	var s := _session()
	var up := PeaceSystem.propose_universal(s.state, "france", s.rules)
	runner.check(str(up["status"]) == "negotiating", "négociation ouverte")
	runner.check((up["participants"] as Array).size() == 21, "21 États participants requis")
	runner.check(PeaceSystem.universal_progress(s.state)["pending"].size() == 21, "tous en attente")
	# Une réponse IA par tour.
	PeaceSystem.tick_universal(s.state, s.rules)
	var prog := PeaceSystem.universal_progress(s.state)
	runner.check(prog["pending"].size() == 20, "une réponse par tour (progressivité)")
	# Acceptance contrôlée de tous les États restants via l'API fonctionnelle.
	for nid: String in (prog["pending"] as Array).duplicate():
		PeaceSystem.respond_universal(s.state, str(up["proposal"]), nid, true, "test", s.rules)
	var final := PeaceSystem.universal_progress(s.state)
	runner.check(final["accepted"].size() == 21 and final["refused"].is_empty(), "tous ont accepté")
	runner.check(str(final["status"]) == "signed", "victoire diplomatique signée")
	runner.check(str(VictorySystem.check_victory(s.state, s.rules)["condition"]) == "diplomatic",
		"condition de victoire déclenchée")


func test_single_refusal_blocks_victory() -> void:
	var s := _session()
	var up := PeaceSystem.propose_universal(s.state, "france", s.rules)
	for nid: String in (up["participants"] as Array):
		var accept := nid != "german_empire"
		PeaceSystem.respond_universal(s.state, str(up["proposal"]), nid, accept, "test", s.rules)
	runner.check(str(PeaceSystem.universal_progress(s.state)["status"]) == "rejected", "refus enregistré")
	runner.check(str(VictorySystem.check_victory(s.state, s.rules)["status"]) == "ongoing",
		"un seul refus empêche la victoire")


func test_pending_blocks_and_withdraw_renew() -> void:
	var s := _session()
	var up := PeaceSystem.propose_universal(s.state, "france", s.rules)
	for nid: String in (up["participants"] as Array):
		if nid == "belgium":
			continue
		PeaceSystem.respond_universal(s.state, str(up["proposal"]), nid, true, "test", s.rules)
	runner.check(str(VictorySystem.check_victory(s.state, s.rules)["status"]) == "ongoing",
		"absence de réponse empêche la victoire")
	runner.check(PeaceSystem.withdraw_universal(s.state) == "", "retrait autorisé")
	runner.check(str(PeaceSystem.universal_progress(s.state)["status"]) == "withdrawn", "statut retiré")
	var up2 := PeaceSystem.propose_universal(s.state, "france", s.rules)
	runner.check(str(up2["status"]) == "negotiating" and (up2["responses"] as Dictionary).is_empty(),
		"renouvellement repart de zéro")


func test_universal_save_and_bilateral_distinction() -> void:
	var s := _session()
	var up := PeaceSystem.propose_universal(s.state, "france", s.rules)
	PeaceSystem.respond_universal(s.state, str(up["proposal"]), "belgium", true, "test", s.rules)
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/consol01_treaty.json"
	SaveRepository.save(path, s.state, s.world, s.rules)
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "rechargement")
	var st2: GameState = loaded["state"]
	var prog := PeaceSystem.universal_progress(st2)
	runner.check(prog["accepted"].has("belgium"), "signature persistée")
	runner.check(prog["pending"].size() == 20, "négociation en cours persistée")
	# Une paix bilatérale ne doit pas devenir une victoire diplomatique.
	var s2 := _session()
	s2.state.diplomacy["peace_treaties"].append({"id": "p", "type": "bilateral",
		"members": ["france", "german_empire"], "status": "active"})
	runner.check(str(VictorySystem.check_victory(s2.state, s2.rules)["status"]) == "ongoing",
		"paix bilatérale distincte")
	runner.check(str(PeaceSystem.universal_progress(s2.state)["status"]) == "none",
		"aucune négociation universelle implicite")


func test_ai_universal_decision_uses_situation() -> void:
	var s := _session()
	PeaceSystem.propose_universal(s.state, "france", s.rules)
	RelationsSystem.adjust(s.state, "france", "belgium", s.rules, {"trust": -60.0, "hostility": 80.0}, "test")
	var hostile := DiplomaticAI.decide_universal(s.state, "belgium", s.rules)
	RelationsSystem.adjust(s.state, "france", "belgium", s.rules, {"trust": 90.0, "hostility": -60.0}, "test2")
	var friendly := DiplomaticAI.decide_universal(s.state, "belgium", s.rules)
	runner.check(float(friendly["score"]) > float(hostile["score"]), "décision sensible aux relations")
	runner.check(str(friendly["reason"]) != "", "motif explicable")
	runner.check(JSON.stringify(DiplomaticAI.decide_universal(s.state, "belgium", s.rules))
		== JSON.stringify(DiplomaticAI.decide_universal(s.state, "belgium", s.rules)), "déterminisme")


# ------------------------------------------------------------------ personnalités
func test_all_22_states_have_profiles() -> void:
	var s := _session()
	var ps := PersonalitySystem.load_assignments()
	runner.check(ps.assignments.size() == 22, "22 attributions")
	for nid: String in s.state.nation_order:
		runner.check(ps.assignments.has(nid), "profil défini : " + nid)
		runner.check(str(s.state.personalities[nid]) != "", "diplomatique : " + nid)
		runner.check(str(s.state.economy["personalities"][nid]) != "", "économique : " + nid)
		runner.check(str(s.state.tech["personalities"].get(nid, "")) != "", "technologique : " + nid)
		runner.check(str(s.state.politics["states"][nid].get("ai_personality", "")) != "", "politique : " + nid)
	var diplomatiques := {}
	var economies := {}
	for nid: String in s.state.nation_order:
		diplomatiques[str(s.state.personalities[nid])] = true
		economies[str(s.state.economy["personalities"][nid])] = true
	runner.check(diplomatiques.size() >= 5, "différenciation diplomatique (%d profils)" % diplomatiques.size())
	runner.check(economies.size() >= 3, "différenciation économique (%d profils)" % economies.size())


func test_personalities_change_behavior() -> void:
	var s := _session()
	# Deux profils économiques opposés sur la même situation.
	s.state.economy["personalities"]["france"] = "industrial"
	var ind := EconomicAI.decide(s.state, s.transport_network, s.rules, "france")
	s.state.economy["personalities"]["france"] = "stability"
	var sta := EconomicAI.decide(s.state, s.transport_network, s.rules, "france")
	runner.check(JSON.stringify(ind) != JSON.stringify(sta), "décisions économiques différenciées")
	# Deux profils politiques opposés.
	s.state.politics["states"]["france"]["ai_personality"] = "militarist"
	var mil := PoliticalAI.decide(s.state, "france", s.rules["phase7"])
	s.state.politics["states"]["france"]["ai_personality"] = "reformer"
	var ref := PoliticalAI.decide(s.state, "france", s.rules["phase7"])
	runner.check(JSON.stringify(mil) != JSON.stringify(ref), "décisions politiques différenciées")
	# Profils diplomatiques : tolérance au risque différente.
	var cautious: String = str(PersonalitySystem.load_assignments().assignments["france"]["diplomatic"])
	runner.check(cautious != "", "profil diplomatique chargé")


func test_personalities_persist() -> void:
	var s := _session()
	s.state.personalities["france"] = "honourable"
	s.state.economy["personalities"]["france"] = "commercial"
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/consol01_personalities.json"
	SaveRepository.save(path, s.state, s.world, s.rules)
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	var st2: GameState = loaded["state"]
	runner.check(str(st2.personalities["france"]) == "honourable", "profil diplomatique persisté")
	runner.check(str(st2.economy["personalities"]["france"]) == "commercial", "profil économique persisté")
