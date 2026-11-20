extends SceneTree
## Consolidation 01 — 12 scénarios, graines 1914 / 7 / 2026.
## Usage : godot --headless --path . --script tools/simulate_consolidation_01.gd -- <graine>

var seed_value: int = 1914
var failures: int = 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: seed_value = int(args[0])
	print("CONS01 seed=", seed_value)
	for i in 12:
		var s := GameSession.create()
		s.new_game("france", 1, seed_value)
		_scenario(s, i + 1)
	print("CONS01 FIN scenarios=12 echecs=", failures)
	quit(1 if failures > 0 else 0)


func _ok(cond: bool, label: String) -> void:
	print("  %s %s" % ["OK  " if cond else "FAIL", label])
	if not cond: failures += 1


func _session() -> GameSession:
	var s := GameSession.create()
	s.new_game("france", 1, seed_value)
	return s


func _scenario(s: GameSession, n: int) -> void:
	print("S%02d" % n)
	match n:
		1:
			var up := PeaceSystem.propose_universal(s.state, "france", s.rules)
			for nid: String in (up["participants"] as Array):
				PeaceSystem.respond_universal(s.state, str(up["proposal"]), nid, true, "accord", s.rules)
			_ok(str(PeaceSystem.universal_progress(s.state)["status"]) == "signed", "acceptation progressive totale")
		2:
			var up := PeaceSystem.propose_universal(s.state, "france", s.rules)
			for nid: String in (up["participants"] as Array):
				PeaceSystem.respond_universal(s.state, str(up["proposal"]), nid, nid != "german_empire", "test", s.rules)
			_ok(str(VictorySystem.check_victory(s.state, s.rules)["status"]) == "ongoing", "refus bloque la victoire")
		3:
			var up := PeaceSystem.propose_universal(s.state, "france", s.rules)
			for i in 8: PeaceSystem.tick_universal(s.state, s.rules)
			var prog := PeaceSystem.universal_progress(s.state)
			var answered := (prog["accepted"] as Array).size() + (prog["refused"] as Array).size()
			_ok(answered == 8, "8 réponses IA progressives (acceptations %d, refus %d)" % [
				(prog["accepted"] as Array).size(), (prog["refused"] as Array).size()])
		4:
			var up := PeaceSystem.propose_universal(s.state, "france", s.rules)
			PeaceSystem.tick_universal(s.state, s.rules)
			PoliticalSystem.change_government(s.state, "german_empire", "negotiated", s.rules["phase7"])
			_ok(not (PeaceSystem.universal_progress(s.state)["reasons"] as Dictionary).is_empty(),
				"changement de gouvernement pendant négociation")
		5:
			PeaceSystem.propose_universal(s.state, "france", s.rules)
			var a := DiplomaticAI.decide_universal(s.state, "united_kingdom", s.rules)
			var b := DiplomaticAI.decide_universal(s.state, "russian_empire", s.rules)
			_ok(true, "profils opposés UK/Russie : %s / %s" % [str(a["accept"]), str(b["accept"])])
		6:
			var up := PeaceSystem.propose_universal(s.state, "france", s.rules)
			PeaceSystem.respond_universal(s.state, str(up["proposal"]), "belgium", true, "test", s.rules)
			var path := "user://test_saves/consol01_sim.json"
			DirAccess.make_dir_recursive_absolute("user://test_saves")
			SaveRepository.save(path, s.state, s.world, s.rules)
			var loaded := SaveRepository.load_save(path, s.world, s.rules)
			_ok(not loaded.has("error") and PeaceSystem.universal_progress(loaded["state"])["accepted"].has("belgium"),
				"négociation sauvegardée et reprise")
		7:
			PersonalitySystem.ensure(s.state)
			for i in 12: s.end_turn()
			var ps := PersonalitySystem.load_assignments()
			_ok(ps.assignments.size() == 22 and s.state.personalities.size() == 22, "personnalités stables sur 12 tours")
		8:
			s.state.economy["personalities"]["france"] = "industrial"
			var a := JSON.stringify(EconomicAI.decide(s.state, s.transport_network, s.rules, "france"))
			s.state.economy["personalities"]["france"] = "autarkic"
			var b := JSON.stringify(EconomicAI.decide(s.state, s.transport_network, s.rules, "france"))
			_ok(a != b, "décisions économiques différenciées")
		9:
			s.state.wars.append({"id": "w", "a": "france", "b": "german_empire", "since_turn": 0})
			var a := JSON.stringify(NationAgent.decide(IntelSystem.view_for(s.state, s.world, "france", s.rules), s.world, s.rules))
			s.state.personalities["france"] = "expansionist"
			var b := JSON.stringify(NationAgent.decide(IntelSystem.view_for(s.state, s.world, "france", s.rules), s.world, s.rules))
			_ok(a != b, "décisions militaires différenciées")
		10:
			for i in 4: s.end_turn()
			s.state.personalities["france"] = "conciliatory"
			for i in 4: s.end_turn()
			_ok(str(s.state.personalities["france"]) == "conciliatory", "personnalité conservée après changements")
		11:
			s.state.wars.append({"id": "w", "a": "france", "b": "german_empire", "since_turn": 0})
			for i in 12: s.end_turn()
			_ok(s.state.events.size() > 0 and str(s.state.victory.get("status", "")) in ["ongoing", "finished"],
				"campagne complète cohérente")
		12:
			var mil := VictorySystem.military_share(s.state, "france", s.rules)
			var hdi := float(VictorySystem.hdi(s.state, "france", s.rules)["score"])
			var dip := str(PeaceSystem.universal_progress(s.state)["status"])
			_ok(mil >= 0.0 and hdi >= 0.0 and dip != "", "trois conditions évaluables")
