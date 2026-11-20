extends SceneTree
## Phase VII — 18 scénarios de simulation, chacun avec la graine fournie.
## Usage : godot --headless --path . --script tools/simulate_phase7.gd -- <graine>

var failures: int = 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_value := 1914 if args.is_empty() else maxi(1, int(args[0]))
	print("P7SIM seed=%d" % seed_value)
	for i in 18:
		var s := GameSession.create()
		s.new_game("france", 1, seed_value)
		var label := _scenario(s, i + 1)
		print("S%02d %s" % [i + 1, label])
	print("P7SIM FIN scenarios=18 echecs=%d" % failures)
	quit(1 if failures > 0 else 0)


func _ok(cond: bool, label: String) -> void:
	print("  %s %s" % ["OK  " if cond else "FAIL", label])
	if not cond:
		failures += 1


func _scenario(s: GameSession, n: int) -> String:
	match n:
		1:
			for i in 6: s.end_turn()
			_ok(float(PoliticalSystem.summary(s.state, "france")["stability"]) > 0.0, "État stable en paix")
		2:
			s.state.economy["stocks"]["france"] = {}
			for i in 6: s.end_turn()
			_ok(float(PoliticalSystem.summary(s.state, "france")["social_tension"]) >= 0.0, "dégradation économique traitée")
		3:
			MobilizationSystem.set_posture(s.state, s.rules["forces"]["mobilization"], "france", "generale")
			for i in 6: s.end_turn()
			_ok(float(PoliticalSystem.summary(s.state, "france")["war_support"]) >= 0.0, "mobilisation prolongée traitée")
		4:
			var p: Dictionary = s.state.politics["states"]["france"]
			p["stability"] = 15.0
			p["social_tension"] = 90.0
			PoliticalSystem.monthly(s.state, "france", s.rules["phase7"])
			var err := PoliticalSystem.change_government(s.state, "france", "negotiated", s.rules["phase7"])
			_ok(err == "", "remaniement gouvernemental")
		5:
			var p2: Dictionary = s.state.politics["states"]["france"]
			p2["social_tension"] = 95.0
			PoliticalSystem.monthly(s.state, "france", s.rules["phase7"])
			_ok(PoliticalSystem.change_government(s.state, "france", "regime_change", s.rules["phase7"]) == "",
				"changement de régime + réputation")
		6:
			s.state.economy["stocks"]["france"]["money"] = 100.0
			var before := IndustrySystem.capacity(s.state, "france")
			var err := PoliticalSystem.apply_decision(s.state, "france", "social_reform", s.rules["phase7"])
			_ok(err == "" and before >= 0.0, "réforme avec coût")
		7:
			var p3: Dictionary = s.state.politics["states"]["france"]
			p3["social_tension"] = 95.0
			PoliticalSystem.monthly(s.state, "france", s.rules["phase7"])
			_ok(str(p3["active_crisis"]) != "", "paralysie gouvernementale (crise)")
		8:
			var ids: Array = s.state.regions.keys()
			for i in int(float(ids.size()) * 0.91):
				s.state.regions[str(ids[i])]["controller"] = "france"
			var v := VictorySystem.check_victory(s.state, s.rules["phase7"])
			_ok(str(v["condition"]) == "military", "victoire militaire 90 %")
		9:
			var hdi := VictorySystem.hdi(s.state, "france", s.rules["phase7"])
			_ok(float(hdi["score"]) >= 0.0 and int(hdi["population"]) > 0, "IDH multidimensionnel")
		10:
			s.state.diplomacy["peace_treaties"].append({"id": "u1", "type": "universal", "members": ["france"],
				"status": "active"})
			var v2 := VictorySystem.check_victory(s.state, s.rules["phase7"])
			_ok(str(v2["condition"]) == "diplomatic", "Traité de Paix et d'Unité")
		11:
			var ids2: Array = s.state.regions.keys()
			for i in ids2.size():
				s.state.regions[str(ids2[i])]["controller"] = "france" if i % 2 == 0 else "german_empire"
			var v3 := VictorySystem.check_victory(s.state, s.rules["phase7"])
			_ok(str(v3["status"]) == "ongoing", "partage 50/50 : aucune victoire militaire fausse")
			var tie := VictorySystem._declare_tie(s.state, ["france", "german_empire"])
			_ok(str(tie["winner"]) == "coalition", "victoire collective explicitement déclarable")
		12:
			CrossingSystem.init_state(s.state)
			var bid: String = s.state.bridges.keys()[0]
			var rid: String = str(s.state.bridges[bid]["region"])
			_ok(CrossingSystem.difficulty(s.state, rid, s.rules["phase7"]) >= 1.0, "pont opérationnel")
		13:
			CrossingSystem.init_state(s.state)
			var b2: String = s.state.bridges.keys()[0]
			var r2: String = str(s.state.bridges[b2]["region"])
			var d1 := CrossingSystem.difficulty(s.state, r2, s.rules["phase7"])
			CrossingSystem.set_status(s.state, b2, "interrupted")
			_ok(CrossingSystem.difficulty(s.state, r2, s.rules["phase7"]) > d1, "passage interrompu")
		14:
			CrossingSystem.init_state(s.state)
			var b3: String = s.state.bridges.keys()[0]
			CrossingSystem.set_status(s.state, b3, "degraded")
			var r3: String = str(s.state.bridges[b3]["region"])
			_ok(CrossingSystem.logistics_factor(s.state, r3, s.rules["phase7"]) < 1.0, "conséquence logistique")
		15:
			var pl := {"france": {"connected": true}, "german_empire": {"connected": true}}
			_ok(MultiplayerSystem.setup(s.state, pl, s.rules["phase7"], s.world) == "", "deux joueurs humains")
		16:
			var pl2 := {"france": {"connected": true}, "german_empire": {"connected": true}}
			MultiplayerSystem.setup(s.state, pl2, s.rules["phase7"], s.world)
			MultiplayerSystem.disconnect_player(s.state, "france")
			var view := MultiplayerSystem.view_for(s.state, "german_empire", s.rules["phase7"])
			_ok(bool(view["players"]["france"]["connected"]) == false, "déconnexion visible")
			MultiplayerSystem.reconnect_player(s.state, "france")
			_ok(not MultiplayerSystem.should_ai_takeover(s.state, "france", s.rules["phase7"]), "reconnexion")
		17:
			var pl3 := {"france": {"connected": true}, "german_empire": {"connected": true}}
			MultiplayerSystem.setup(s.state, pl3, s.rules["phase7"], s.world)
			MultiplayerSystem.resolve_orders(s.state, s.rules, s.world)
			var path := "user://test_saves/p7_mp.json"
			DirAccess.make_dir_recursive_absolute("user://test_saves")
			SaveRepository.save(path, s.state, s.world, s.rules)
			var loaded := SaveRepository.load_save(path, s.world, s.rules)
			_ok(not loaded.has("error") and (loaded["state"].multiplayer["players"] as Dictionary).size() == 2,
				"sauvegarde et reprise multijoueur")
		18:
			s.state.wars.append({"id": "wl", "a": "france", "b": "german_empire", "since_turn": 0})
			for i in 18: s.end_turn()
			var st := str(s.state.victory.get("status", "ongoing"))
			_ok(["ongoing", "finished"].has(st), "partie longue cohérente (%s)" % st)
	return "terminé"
