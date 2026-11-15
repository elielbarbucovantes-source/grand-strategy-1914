extends SceneTree
## Démonstration reproductible d'une bataille tactique IA contre IA (bac à sable FICTIF) :
##   godot --headless --path . --script tests/demo_battle.gd
func _initialize() -> void:
	var s := GameSession.create()
	s.new_game("france", 1, 1914, "sandbox_fictif")
	var st := s.state
	st.wars.append({"id": "w", "a": "german_empire", "b": "france", "since_turn": 0})
	st.move_army("army_german_empire_1", "region_011")
	st.move_army("army_france_1", "region_011")
	var b := BattleManager.create(st, s.world, s.rules, s.rules["combat"], {"region": "region_011",
		"attackers": ["army_german_empire_1"], "defenders": ["army_france_1"],
		"origin": {"army_german_empire_1": "region_035", "army_france_1": "region_011"}})
	st.active_battles.append(b)
	print("Bataille de %s : durée maximale %.1f min (%d pas) ; commandants : %s / %s" % [b["field"]["name_fr"], float(b["max_minutes"]), int(b["max_ticks"]),
		b["sides"]["attackers"]["commander"]["nation"], b["sides"]["defenders"]["commander"]["nation"]])
	var t0 := Time.get_ticks_msec()
	BattleManager.run_to_end(b, s.rules["combat"], true)
	var ms := Time.get_ticks_msec() - t0
	var counts := {}
	for e: Dictionary in b["log"]:
		var k: String = e["text"].split(" ")[-1]
		counts[k] = int(counts.get(k, 0)) + 1
	for e: Dictionary in (b["log"] as Array).slice(0, 12):
		print("  [%4ds] %s" % [int(e["tick"]) * 2, e["text"]])
	var res := BattleManager.finish(st, s.world, s.rules["combat"], b)
	print("Fin au pas %d (%s) en %d ms de calcul." % [int(res["tick"]), res["end_reason"], ms])
	print("Pertes : attaquants %d / %d ; défenseurs %d / %d" % [int(res["stats"]["attackers"]["lost"]), int(res["stats"]["attackers"]["start"]),
		int(res["stats"]["defenders"]["lost"]), int(res["stats"]["defenders"]["start"])])
	print("Scores : A %.3f (pertes %.2f, terr. %.2f) ; D %.3f (pertes %.2f, terr. %.2f) ; vainqueur : %s" % [
		float(res["scores"]["attackers"]["total"]), float(res["scores"]["attackers"]["losses"]), float(res["scores"]["attackers"]["territory"]),
		float(res["scores"]["defenders"]["total"]), float(res["scores"]["defenders"]["losses"]), float(res["scores"]["defenders"]["territory"]),
		res["winner"] if res["winner"] != "" else "aucun (indécise)"])
	print("Contrôle de la région : %s ; armée allemande en %s" % [st.controller("region_011"), st.formations["army_german_empire_1"]["region"] if st.formations.has("army_german_empire_1") else "détruite"])
	for e: Dictionary in st.events.slice(-3):
		print("  • " + e["text"])
	quit()
