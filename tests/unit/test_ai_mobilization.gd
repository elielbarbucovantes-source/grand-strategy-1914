extends RefCounted
## MIL-01 phase 3 : mobilisation autonome de l'IA (T-052). Doctrines nationales, réaction aux
## mobilisations publiques, guerre, désescalade, absence d'information secrète, déterminisme et
## conservation des effectifs dans une campagne conduite par l'IA.

var runner: Object

const PLAYABLE := ["austria_hungary", "france", "german_empire", "italy", "ottoman_empire", "russian_empire", "united_kingdom"]


## Le joueur observe (il ne donne aucun ordre) ; toutes les autres puissances sont conduites par l'IA.
func _session(observer: String = "united_kingdom") -> GameSession:
	var s := GameSession.create()
	s.new_game(observer, 1, 1914)
	return s


func _posture(s: GameSession, nid: String) -> String:
	return s.state.nations[nid]["forces"]["posture"]


func _war(s: GameSession, a: String, b: String) -> void:
	s.state.wars.append({"id": "w_%s_%s" % [a, b], "a": a, "b": b, "since_turn": s.state.turn})


func test_doctrines_are_national_and_flagged() -> void:
	var s := _session()
	var d: Dictionary = s.rules["ai_doctrines"]
	var signatures: Dictionary = {}
	for nid: String in PLAYABLE:
		runner.check(d["nations"].has(nid), "%s : doctrine présente" % nid)
		var doc: Dictionary = d["nations"][nid]
		runner.check(doc["status"] == "PROPOSÉ" and str(doc["basis"]).contains("NON sourcée") and str(doc["doctrine_fr"]) != "",
			"%s : doctrine PROPOSÉE, non présentée comme sourcée" % nid)
		signatures[JSON.stringify([doc["preparatory_threshold"], doc["general_threshold"], doc["foreign_mobilization_reaction"], doc["general_tension_factor"], doc["next_echelon_policy"]])] = true
	runner.check(signatures.size() >= 6, "doctrines différenciées (%d profils distincts pour 7 puissances)" % signatures.size())


func test_no_mobilization_without_tension() -> void:
	var s := _session()
	for i in 6:
		s.end_turn()
	for nid: String in PLAYABLE:
		runner.check(_posture(s, nid) == "paix", "%s : aucune mobilisation sans tension (6 mois)" % nid)


func test_reaction_to_public_foreign_mobilization() -> void:
	var s := _session()
	var mr: Dictionary = s.rules["forces"]["mobilization"]
	MobilizationSystem.set_posture(s.state, mr, "russian_empire", "generale")  # mobilisation russe publique
	s.end_turn()
	runner.check(_posture(s, "german_empire") == "generale", "Allemagne : posture générale en réponse à la mobilisation russe frontalière")
	runner.check(_posture(s, "austria_hungary") == "generale", "Autriche-Hongrie : posture générale en réponse")
	runner.check(_posture(s, "france") == "paix", "France : pas encore de réaction (la Russie est son alliée)")
	s.end_turn()
	runner.check(_posture(s, "france") == "generale", "France : posture générale le mois suivant, en réponse à l'Allemagne")
	runner.check(_posture(s, "italy") == "paix", "Italie : ne mobilise pas malgré la tension (doctrine de prudence)")
	runner.check(_posture(s, "united_kingdom") == "paix", "Royaume-Uni (observateur) : inchangé")
	var italy := GameSession.create()
	italy.new_game("france", 1, 1914)
	MobilizationSystem.set_posture(italy.state, mr, "russian_empire", "generale")
	for i in 3:
		italy.end_turn()
	runner.check(_posture(italy, "united_kingdom") == "paix", "Royaume-Uni (IA) : pas de mobilisation en temps de paix")
	runner.check(_posture(italy, "russian_empire") == "generale", "Russie : posture maintenue tant que la menace persiste")


func test_war_triggers_mobilization_and_next_echelon() -> void:
	var s := _session()
	_war(s, "german_empire", "france")
	for i in 3:
		s.end_turn()
	runner.check(_posture(s, "german_empire") == "generale" and _posture(s, "france") == "generale", "belligérants : posture générale")
	var de: Dictionary = s.state.nations["german_empire"]["forces"]
	runner.check(de["echelons"][1]["opened_turn"] != null, "Allemagne en guerre : échelon suivant ouvert par l'IA (après épuisement et délai)")
	runner.check(_posture(s, "russian_empire") == "generale", "Russie : alliée en guerre et Allemagne mobilisée : posture générale")
	runner.check(_posture(s, "italy") == "paix", "Italie : alliée en guerre mais doctrine de prudence : pas de mobilisation")
	runner.check(_posture(s, "united_kingdom") == "paix", "Royaume-Uni (observateur) : inchangé")
	for nid: String in PLAYABLE:
		var c := MobilizationSystem.conservation(s.state, nid)
		runner.check(c["reserves_ok"] and c["personnel_ok"], "%s : conservation des effectifs pendant la mobilisation conduite par l'IA" % nid)


func test_ai_uses_only_accessible_information() -> void:
	var s := _session()
	var st := s.state
	_war(s, "german_empire", "france")
	var view := IntelSystem.view_for(st, s.world, "german_empire")
	var before := JSON.stringify(NationAgent.decide(view, s.world, s.rules))
	# Les données confidentielles et les ordres secrets d'autrui ne doivent rien changer.
	var fr: Dictionary = st.nations["france"]["forces"]
	fr["echelons"][0]["pool_by_region"]["region_011"] = 1
	fr["mobilizing"].append({"region": "region_011", "dest": "region_011", "soldiers": 999999, "echelon": "bloc_unique", "ready_turn": 99})
	st.pending_orders["russian_empire"] = [Orders.mobilization_posture("russian_empire", "generale")]
	var view2 := IntelSystem.view_for(st, s.world, "german_empire")
	runner.check(JSON.stringify(NationAgent.decide(view2, s.world, s.rules)) == before,
		"décision allemande identique : volumes français et ordres russes secrets ignorés")
	var pub: Dictionary = view2["public_mobilization"]["france"]
	runner.check(not JSON.stringify(pub).contains("soldiers") and not JSON.stringify(pub).contains("pool"), "vue : aucun volume étranger")
	var foreign_numbers := false
	for f: Dictionary in view2["formations"]:
		if f["nation"] != "german_empire" and f["soldiers"] != null:
			foreign_numbers = true
	runner.check(not foreign_numbers, "vue : effectifs des formations étrangères inconnus")
	runner.check(view2["own_forces"]["posture"] == st.nations["german_empire"]["forces"]["posture"], "vue : propres effectifs disponibles")
	runner.check(not view2.has("pending_orders"), "vue : aucun ordre en attente d'autrui")


func test_escalation_spiral_between_rival_blocs() -> void:
	# Comportement OBSERVÉ et documenté (limite) : une fois deux blocs rivaux mobilisés, chacun
	# réagit à la posture publique de l'autre ; aucun ne désescalade (dilemme de sécurité).
	var s := _session()
	var mr: Dictionary = s.rules["forces"]["mobilization"]
	MobilizationSystem.set_posture(s.state, mr, "russian_empire", "generale")
	s.end_turn()
	MobilizationSystem.set_posture(s.state, mr, "russian_empire", "paix")
	for i in 6:
		s.end_turn()
	runner.check(_posture(s, "german_empire") == "generale" and _posture(s, "france") == "generale" and _posture(s, "russian_empire") == "generale",
		"spirale : Allemagne, France et Russie restent mobilisées (la Russie remobilise en réponse à l'Allemagne)")


func test_stand_down_when_threat_disappears() -> void:
	# L'Empire ottoman mobilise sous l'effet de la tension générale (guerres en cours), puis
	# désescalade d'un niveau à la fois quand la paix revient et que la menace retombe sous ses seuils.
	var s := _session()
	# RESTORATION 01 : isoler la désescalade ; une nouvelle guerre autonome réintroduirait
	# une tension générale et empêcherait le retour à la paix testé ici.
	s.rules["diplomacy"]["ai"]["allow_automatic_war"] = false
	_war(s, "german_empire", "france")
	_war(s, "austria_hungary", "russian_empire")
	for i in 3:
		s.end_turn()
	var during := _posture(s, "ottoman_empire")
	runner.check(during != "paix", "Empire ottoman : mobilisation sous la tension générale (%s), sans être en guerre" % during)
	s.state.wars.clear()
	var seen: Array = []
	for i in 10:
		s.end_turn()
		seen.append(_posture(s, "ottoman_empire"))
	var a := MobilizationAgent.assess(IntelSystem.view_for(s.state, s.world, "ottoman_empire"), s.world, s.rules["ai_doctrines"])
	runner.check(seen[-1] == "paix" and not seen.slice(0, 1).has("paix"),
		"Empire ottoman : maintien quelques mois, puis retour à la paix (postures : %s ; menace finale %.0f)" % [str(seen), float(a["score"])])
	runner.check(float(a["score"]) < float(s.rules["ai_doctrines"]["nations"]["ottoman_empire"]["preparatory_threshold"]),
		"menace ottomane retombée sous le seuil préparatoire")
	var c := MobilizationSystem.conservation(s.state, "ottoman_empire")
	runner.check(c["reserves_ok"] and c["personnel_ok"], "conservation après désescalade (pas de démobilisation : les incorporés restent)")


func test_ai_campaign_is_deterministic() -> void:
	var runs: Array = []
	for r in 2:
		var s := _session()
		_war(s, "german_empire", "france")
		_war(s, "austria_hungary", "russian_empire")
		for i in 5:
			s.end_turn()
		runs.append(s.state.checksum())
	runner.check(runs[0] == runs[1], "campagne conduite par l'IA : déterministe")
