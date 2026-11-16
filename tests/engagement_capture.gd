extends SceneTree
## Vérification VISUELLE des interfaces de l'étape 2 (types d'engagement, front, blessés légers).
## Non probatoire : captures à inspecter. Nécessite un affichage (pas de --headless) :
##   godot --path . --script tests/engagement_capture.gd -- <dossier> <largeur>x<hauteur>
## L'interface est rendue dans un SubViewport de la taille demandée (rendu réel, hors fenêtre) : la
## fenêtre ne peut pas dépasser l'écran disponible (1280 × 1024 sur le poste de vérification).

var out_dir := ""
var suffix := ""
var vp: SubViewport


func _shot(name: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(out_dir.path_join("%s_%s.png" % [name, suffix]))
	print("capture ", name, " ", vp.size)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else "user://"
	suffix = args[1] if args.size() > 1 else "x"
	var wh := suffix.split("x")
	vp = SubViewport.new()
	vp.size = Vector2i(int(wh[0]), int(wh[1])) if wh.size() == 2 else Vector2i(1600, 900)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	root.add_child(vp)
	var main: Node = load("res://src/ui/main.tscn").instantiate()
	vp.add_child(main)
	await process_frame
	var s: GameSession = main.session
	s.new_game("france", 1, 1914)
	main._start_game()
	await process_frame
	var ui: GameUI = main.game_ui
	for i in ui.tabs.get_tab_count():
		if ui.tabs.get_tab_title(i) == "Armée":
			ui.tabs.current_tab = i
	ui.map_view.selected_formation = "army_france_region_011"
	ui.refresh()
	# Panneau défilé jusqu'aux contrôles d'engagement.
	var scroll: ScrollContainer = ui.pages["Armée"].get_parent()
	await process_frame
	scroll.scroll_vertical = 700
	await _shot("10_armee_engagement")
	scroll.scroll_vertical = 1000
	await _shot("10b_armee_postures")
	# Bataille du joueur : l'Allemagne attaque la Lorraine (assaut), la France tient.
	s.state.wars.append({"id": "w", "a": "german_empire", "b": "france", "since_turn": 0})
	s.state.formations["army_france_region_011"]["defensive_posture"] = "hold"
	TurnResolver.resolve(s.state, s.world, s.rules, {"german_empire": [Orders.move("german_empire", "army_german_empire_region_035", "region_011", "assault")]})
	main.open_battle()
	await process_frame
	var bv: BattleView = main.battle_view
	s.advance_battle(140)
	var b: Dictionary = bv.battle
	for uid: String in CombatData.unit_ids(b):
		if b["units"][uid]["nation"] == "france" and b["units"][uid].get("front_status", "") == "waiting":
			bv.selected = [uid]
			break
	if bv.selected.is_empty():
		for uid: String in CombatData.unit_ids(b):
			if b["units"][uid]["nation"] == "france" and b["units"][uid]["status"] == CombatData.ACTIVE:
				bv.selected = [uid]
				break
	bv.refresh()
	await _shot("11_bataille_front")
	bv._on_auto()
	await _shot("12_resultat_engagement")
	bv._on_close()
	await process_frame
	ui.map_view.selected_formation = "army_france_region_011"
	ui.refresh()
	await process_frame
	var lw := 0
	for uid: String in s.state.units_of("army_france_region_011"):
		lw += int(s.state.formations[uid].get("lightly_wounded", 0))
	print("blessés légers dans l'armée : ", lw)
	await process_frame
	var target := _label_with(ui.pages["Armée"], "blessés légers (capacité")
	if target != null:
		scroll.ensure_control_visible(target)
	await _shot("13_armee_blesses_legers")
	scroll.scroll_vertical = 0
	await _shot("14_armee_bilan_pertes")
	quit()


func _label_with(node: Node, text: String) -> Control:
	if node is Label and (node as Label).text.contains(text):
		return node
	for c: Node in node.get_children():
		var r := _label_with(c, text)
		if r != null:
			return r
	return null

