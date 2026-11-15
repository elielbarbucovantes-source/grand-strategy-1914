extends SceneTree
## Rapport (NON probatoire) : comportement de mobilisation de l'IA par puissance (MIL-01 phase 3).
## Le joueur (Royaume-Uni) observe sans donner d'ordre, sauf mention ; toutes les autres puissances
## sont conduites par l'IA. Affiche, mois par mois, la posture et le score de menace de chaque puissance.
##   godot --headless --path . --script tests/ai_mobilization_report.gd

const P := ["german_empire", "france", "russian_empire", "austria_hungary", "italy", "ottoman_empire", "united_kingdom"]
const SHORT := {"paix": "Pa", "preparatoire": "Pr", "generale": "Gé"}


func _initialize() -> void:
	_scenario("A. Europe calme (aucune guerre, aucune mobilisation initiale)", "united_kingdom", func(_s: GameSession, _m: int) -> void: pass, 8)
	_scenario("B. La Russie décrète la mobilisation générale au mois 1 (posture publique), puis revient à la paix au mois 2", "united_kingdom",
		func(s: GameSession, m: int) -> void:
			if m == 0:
				MobilizationSystem.set_posture(s.state, s.rules["forces"]["mobilization"], "russian_empire", "generale")
			elif m == 1:
				MobilizationSystem.set_posture(s.state, s.rules["forces"]["mobilization"], "russian_empire", "paix"), 8)
	_scenario("C. Guerres franco-allemande et austro-russe au mois 1, paix générale au mois 4", "united_kingdom",
		func(s: GameSession, m: int) -> void:
			if m == 0:
				s.state.wars.append({"id": "w1", "a": "german_empire", "b": "france", "since_turn": 0})
				s.state.wars.append({"id": "w2", "a": "austria_hungary", "b": "russian_empire", "since_turn": 0})
			elif m == 3:
				s.state.wars.clear(), 12)
	_scenario("D. Guerre anglo-allemande seule au mois 1 (joueur : France, observateur)", "france",
		func(s: GameSession, m: int) -> void:
			if m == 0:
				s.state.wars.append({"id": "w3", "a": "german_empire", "b": "united_kingdom", "since_turn": 0}), 6)
	quit()


func _scenario(title: String, observer: String, script: Callable, months: int) -> void:
	var s := GameSession.create()
	s.new_game(observer, 1, 1914)
	print("\n### %s\n" % title)
	print("Observateur (sans ordre) : %s. Pa = paix, Pr = préparatoire, Gé = générale ; entre parenthèses, score de menace perçu ; « +é » = échelon suivant ouvert.\n" % observer)
	print("| Mois | " + " | ".join(P) + " |")
	print("|---|" + "---|".repeat(P.size()))
	var t0 := Time.get_ticks_msec()
	for m in months:
		script.call(s, m)
		s.end_turn()
		var cells: Array = []
		for nid: String in P:
			var f: Dictionary = s.state.nations[nid]["forces"]
			var a := MobilizationAgent.assess(IntelSystem.view_for(s.state, s.world, nid), s.world, s.rules["ai_doctrines"])
			var extra := " +é" if (f["echelons"] as Array).size() > 1 and f["echelons"][1]["opened_turn"] != null else ""
			cells.append("%s (%.0f)%s" % [SHORT[f["posture"]], float(a["score"]), extra])
		print("| %s | %s |" % [s.state.date_label(), " | ".join(cells)])
	var ok := true
	for nid: String in P:
		var c := MobilizationSystem.conservation(s.state, nid)
		ok = ok and bool(c["reserves_ok"]) and bool(c["personnel_ok"])
	print("\nConservation des effectifs (7 puissances) : %s ; calcul : %d ms pour %d mois." % ["vérifiée" if ok else "ÉCHEC", Time.get_ticks_msec() - t0, months])
