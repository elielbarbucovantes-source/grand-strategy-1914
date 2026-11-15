extends SceneTree
## Capture d'écran de démonstration (nécessite un affichage) :
##   godot --path . --script tests/screenshot.gd -- <sortie.png> [zoom]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://capture.png"
	var main: Node = load("res://src/ui/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.session.new_game("france", 1)
	main._start_game()
	await process_frame
	var mv: MapView = main.map_view
	if args.size() > 1:
		mv.camera.zoom = Vector2.ONE * float(args[1])
	mv.region_clicked.emit("region_008")
	mv.selected_formation = "army_france_1"
	mv.region_clicked.emit("region_007")
	mv.selected_formation = ""
	main.session.state.regions["region_035"]["controller"] = "france"  # démonstration visuelle de l'occupation hachurée
	main.game_ui.refresh()
	for i in 10:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out)
	print("capture : ", out)
	quit()
