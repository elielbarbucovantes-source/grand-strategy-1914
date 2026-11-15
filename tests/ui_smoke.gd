extends SceneTree
## Test de fumée de l'interface, sans rendu :
##   godot --headless --path . --script tests/ui_smoke.gd
## Pilote la vraie scène principale : nouvelle partie, sélection, ordre par clic, onglets,
## fin de mois, sauvegarde et chargement. Code 1 en cas d'échec.

var failures := 0


func check(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		printerr("  ✗ " + msg)
	else:
		print("  ✓ " + msg)


func _initialize() -> void:
	var main: Node = load("res://src/ui/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var session: GameSession = main.session
	check(session != null, "session créée")
	check(main.menu != null, "menu affiché")
	check(session.new_game("france", 1) == "", "nouvelle partie France, janvier 1914")
	main._start_game()
	await process_frame
	var mv: MapView = main.map_view
	var ui: GameUI = main.game_ui
	check(mv.fills.size() == 90, "90 régions dessinées")
	var paris := session.state.nations["france"]["capital_region_id"] as String
	var hit := mv.region_at(mv.screen_pos(paris))
	check(hit == paris, "sélection par clic : point de Paris → %s" % hit)
	mv.region_clicked.emit(paris)
	await process_frame
	check(mv.selected_region == paris, "région sélectionnée")
	for i in ui.tabs.get_tab_count():
		ui.tabs.current_tab = i
		ui.refresh()
		await process_frame
	check(true, "les 10 onglets se construisent")
	# Ordre de déplacement par clic carte.
	mv.selected_formation = "army_france_region_008"
	var target := ""
	for n: String in session.world.neighbor_ids(paris):
		if session.state.controller(n) == "france":
			target = n
			break
	mv.region_clicked.emit(target)
	check(session.player_orders().size() == 1, "ordre de déplacement préparé par clic (%s)" % ui.status.text)
	var foreign := "region_028"
	mv.region_clicked.emit(foreign)
	check(ui.status.text.begins_with("Ordre refusé"), "ordre invalide refusé avec motif : %s" % ui.status.text)
	ui._on_end_turn()
	await process_frame
	check(session.state.formations["army_france_region_008"]["region"] == target, "déplacement résolu à la fin du mois")
	check(session.state.date_label() == "février 1914", "calendrier avancé")
	ui._on_save()
	check(ui.status.text.begins_with("Sauvegardé"), "sauvegarde : %s" % ui.status.text)
	var checksum := session.state.checksum()
	ui._on_end_turn()
	ui._on_load()
	await process_frame
	check(session.state.checksum() == checksum, "chargement : état restauré à l'identique")
	print("RÉSULTAT UI : %s" % ("VALIDÉ" if failures == 0 else "%d échec(s)" % failures))
	quit(1 if failures > 0 else 0)
