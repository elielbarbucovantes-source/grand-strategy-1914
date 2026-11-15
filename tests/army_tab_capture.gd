extends SceneTree
## Vérification VISUELLE de l'onglet Armée (MIL-01 phases 2 et 3). Non probatoire : produit des
## captures à inspecter à l'écran. Nécessite un affichage (pas de --headless) :
##   godot --path . --script tests/army_tab_capture.gd -- <dossier de sortie>

var out_dir := ""


func _shot(name: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw  # sinon l'image peut précéder le dernier rendu
	root.get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("capture ", name)


func _army(ui: GameUI) -> void:
	for i in ui.tabs.get_tab_count():
		if ui.tabs.get_tab_title(i) == "Armée":
			ui.tabs.current_tab = i
	ui.refresh()


func _find(node: Node, prefix: String) -> Button:
	if node is Button and (node as Button).text.begins_with(prefix):
		return node
	for c: Node in node.get_children():
		var r := _find(c, prefix)
		if r:
			return r
	return null


func _initialize() -> void:
	out_dir = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var main: Node = load("res://src/ui/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	# France (bloc unique) : départ, posture générale par le vrai bouton, deux mois, bataille.
	var session: GameSession = main.session
	session.new_game("france", 1)
	main._start_game()
	await process_frame
	var ui: GameUI = main.game_ui
	_army(ui)
	await _shot("01_france_depart")
	var b := _find(ui.pages["Armée"], "Posture : Générale")
	if b:
		b.pressed.emit()
	ui._on_end_turn()
	ui._on_end_turn()
	_army(ui)
	await _shot("02_france_deux_mois")
	session.queue_order(Orders.declare_war("france", "german_empire"))
	session.end_turn()
	TurnResolver.resolve(session.state, session.world, session.rules,
		{"german_empire": [Orders.move("german_empire", "army_german_empire_region_035", "region_011")]})
	session.auto_resolve_battle()
	_army(ui)
	await _shot("03_france_apres_bataille")
	# Allemagne (deux échelons documentés) : nouvelle scène principale.
	main.queue_free()
	await process_frame
	main = load("res://src/ui/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	session = main.session
	session.new_game("german_empire", 1)
	main._start_game()
	await process_frame
	ui = main.game_ui
	session.queue_order(Orders.mobilization_posture("german_empire", "generale"))
	ui._on_end_turn()
	ui._on_end_turn()
	_army(ui)
	await _shot("04_allemagne_echelons")
	# Royaume-Uni (Territorial Force, phase 4) : posture générale, deux mois, puis défilement vers les armées.
	main.queue_free()
	await process_frame
	main = load("res://src/ui/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	session = main.session
	session.new_game("united_kingdom", 1)
	main._start_game()
	await process_frame
	ui = main.game_ui
	session.queue_order(Orders.mobilization_posture("united_kingdom", "generale"))
	ui._on_end_turn()
	ui._on_end_turn()
	_army(ui)
	await _shot("05_royaume_uni_territorial_force")
	var scroll: ScrollContainer = ui.pages["Armée"].get_parent()
	scroll.scroll_vertical = 900
	await _shot("06_royaume_uni_armees")
	quit()
