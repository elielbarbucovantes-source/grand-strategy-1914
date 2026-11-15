extends Node
## Point d'entrée : menu (nouvelle partie, chargement), puis écran de jeu (carte et panneaux).

var session: GameSession
var map_view: MapView
var game_ui: GameUI
var battle_view: BattleView
var menu: CanvasLayer


func _ready() -> void:
	get_window().title = "Grand Strategy-1914 — prototype"
	session = GameSession.create()
	if session == null:
		push_error("Données de jeu introuvables (data/game, data/rules, data/scenarios).")
		return
	_show_menu()


func _show_menu() -> void:
	for n in [map_view, game_ui, menu]:
		if n != null:
			n.queue_free()
	map_view = null
	game_ui = null
	menu = CanvasLayer.new()
	add_child(menu)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(520, 0)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Grand Strategy-1914"
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "« Le joueur dirige son pays, mais ne dirige pas le monde. »\nPrototype technique : voir docs/project/PROTOTYPE_STATUS.md"
	box.add_child(sub)
	var nation := OptionButton.new()
	for nid: String in session.playable_nations():
		nation.add_item(session.scenario["nations"][nid]["name_fr"])
		nation.set_item_metadata(nation.item_count - 1, nid)
	box.add_child(_row("Puissance :", nation))
	var month := OptionButton.new()
	for i in 12:
		month.add_item(GameCalendar.MONTHS_FR[i] + " 1914")
	box.add_child(_row("Mois de départ (R-13 ouvert) :", month))
	var scen := OptionButton.new()
	scen.add_item("Campagne historique 1914 (effectifs sourcés des 7 puissances, MIL-01 ; répartition estimée)")
	scen.add_item("Bac à sable FICTIF (forces génériques de test, combat jouable)")
	box.add_child(_row("Scénario :", scen))
	var start := Button.new()
	start.text = "Nouvelle partie"
	start.pressed.connect(func() -> void:
		var err := session.new_game(nation.get_item_metadata(nation.selected), month.selected + 1, 1914,
			"sandbox_fictif" if scen.selected == 1 else "campaign_1914")
		if err == "":
			_start_game())
	box.add_child(start)
	var saves := SaveRepository.list_saves(GameSession.SAVE_DIR)
	if not saves.is_empty():
		var load := Button.new()
		load.text = "Charger la dernière sauvegarde"
		load.pressed.connect(func() -> void:
			if session.load_game(saves[saves.size() - 1]) == "":
				_start_game())
		box.add_child(load)
	var credits := Label.new()
	credits.text = "Données cartographiques : REGIS (CC BY-NC 4.0), © OpenStreetMap contributors (ODbL), etc. — voir NOTICE."
	credits.add_theme_font_size_override("font_size", 11)
	box.add_child(credits)


func _row(text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = 230
	row.add_child(l)
	row.add_child(control)
	return row


func _start_game() -> void:
	menu.queue_free()
	menu = null
	map_view = MapView.new()
	add_child(map_view)
	map_view.setup(session)
	game_ui = GameUI.new()
	add_child(game_ui)
	game_ui.setup(session, map_view)
	game_ui.request_menu.connect(_show_menu)
	game_ui.request_battle.connect(open_battle)
	game_ui.request_planning.connect(open_planning)


## Bataille du joueur (une seule à la fois) : la carte stratégique est masquée.
func open_battle() -> void:
	if session.current_battle().is_empty():
		return
	_open_tactical("battle", "")


func open_planning(rid: String) -> void:
	_open_tactical("planning", rid)


func _open_tactical(view_mode: String, rid: String) -> void:
	map_view.visible = false
	map_view.set_process_unhandled_input(false)
	game_ui.visible = false
	battle_view = BattleView.new()
	add_child(battle_view)
	battle_view.setup(session, view_mode, rid)
	battle_view.closed.connect(close_tactical)


func close_tactical() -> void:
	if battle_view != null:
		battle_view.queue_free()
		battle_view = null
	map_view.visible = true
	map_view.set_process_unhandled_input(true)
	map_view.camera.make_current()
	game_ui.visible = true
	RenderingServer.set_default_clear_color(MapView.SEA_COLOR)
	game_ui.refresh()
	if not session.current_battle().is_empty():
		open_battle.call_deferred()
