extends SceneTree
## Démonstration reproductible sans interface :
##   godot --headless --path . --script tests/demo_campaign.gd
## Le joueur (Empire allemand) déclare la guerre à la France et marche sur Paris ;
## les 21 autres pays sont joués par l'IA de niveau 1 (vue filtrée).

func _initialize() -> void:
	var s := GameSession.create()
	s.new_game("german_empire", 1)
	s.queue_order(Orders.declare_war("german_empire", "france"))
	var army := "army_german_empire_region_028"
	var goal := s.state.nations["france"]["capital_region_id"] as String
	for month in 8:
		var here: String = s.state.formations[army]["region"]
		var path := s.world.shortest_path(here, goal,
			func(rid: String) -> bool: return MilitarySystem.can_enter(s.state, "german_empire", rid))
		if path.size() > 1:
			var err := s.queue_order(Orders.move("german_empire", army, path[1]))
			if err != "":
				print("  (ordre refusé : %s)" % err)
		var rep := s.end_turn()
		print("== %s : %d ordres exécutés, %d bataille(s)" % [rep["resolved_month"], rep["accepted"], rep["battles"]])
		for e: Dictionary in s.state.events:
			if e["turn"] == s.state.turn - 1 and e["category"] != "armée":
				print("   • [%s] %s" % [e["category"], e["text"]])
		print("   armée allemande : %s ; contrôle allemand : %.1f %%" % [s.world.regions[s.state.formations[army]["region"]]["name_fr"], 100.0 * s.territorial_share("german_empire")])
	print("empreinte de l'état : %s" % s.state.checksum().substr(0, 16))
	quit()
