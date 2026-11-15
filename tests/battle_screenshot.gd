extends SceneTree
## Capture de l'écran de bataille (nécessite un affichage) :
##   godot --path . --script tests/battle_screenshot.gd -- <png> [pas]
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var main: Node = load("res://src/ui/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var s: GameSession = main.session
	s.new_game("france", 1, 1914, "sandbox_fictif")
	main._start_game()
	var st := s.state
	st.wars.append({"id": "w", "a": "german_empire", "b": "france", "since_turn": 0})
	st.move_army("army_german_empire_1", "region_011")
	st.move_army("army_france_1", "region_011")
	var b := BattleManager.create(st, s.world, s.rules, s.rules["combat"], {"region": "region_011",
		"attackers": ["army_german_empire_1"], "defenders": ["army_france_1"],
		"origin": {"army_german_empire_1": "region_035", "army_france_1": "region_011"}})
	st.active_battles.append(b)
	main.open_battle()
	await process_frame
	var bv: BattleView = main.battle_view
	if bv == null:
		printerr("aucune vue de bataille")
		quit(1)
		return
	s.advance_battle(int(args[1]) if args.size() > 1 else 120)
	bv.select_rect(Rect2(0, 0, 2000, 1400))
	bv.refresh()
	for i in 8:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(args[0] if args.size() > 0 else "user://battle.png")
	quit()
