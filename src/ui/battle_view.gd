class_name BattleView
extends Node2D
## Interface tactique (aucune règle métier : toutes les actions passent par TacticalOrders,
## GameSession ou des ordres stratégiques). Deux modes :
##  - "battle"   : bataille en cours commandée par le joueur ;
##  - "planning" : préparation des défenses d'une région hors bataille (ordres mensuels).
## Contrôles : clic gauche = sélection (Maj = ajout, glisser = rectangle) ; clic droit = déplacement
## du groupe sélectionné ; molette = zoom ; clic milieu maintenu = déplacement de la vue.

signal closed

const BG := Color("#d9d2b6")
const FIELD := Color("#c8c09a")
const SELECT := Color("#ffd23f")

var session: GameSession
var mode := "battle"
var battle: Dictionary = {}
var region := ""
var me := ""
var side := ""
var selected: Array = []
var tool := ""            # "", "charge", "trench", "machine_gun_nest", "artillery_position", "command_post", "objective"
var trench_start: Variant = null
var speed := 1.0
var _acc := 0.0
var _drag_from: Variant = null
var _panning := false
var camera: Camera2D
var hud: CanvasLayer
var info: RichTextLabel
var status_panel: RichTextLabel
var message: Label
var tool_label: Label
var side_box: VBoxContainer
var result_box: PanelContainer


func setup(s: GameSession, view_mode: String, rid: String = "") -> void:
	session = s
	mode = view_mode
	me = s.state.player_nation
	if mode == "battle":
		battle = s.current_battle()
		region = battle["region"]
		side = TacticalSim.side_of_nation(battle, me)
	else:
		region = rid
		var field := Battlefield.build(s.world, rid, s.rules["combat"])
		battle = {"field": field, "objectives": field["objectives"], "units": {}, "defenses": DefenseSystem.defenses(s.state, rid),
			"fog": {"attackers": {}, "defenders": {}}, "visible": {"attackers": {}, "defenders": {}}, "status": "planning", "tick": 0, "max_ticks": 1}
	RenderingServer.set_default_clear_color(BG)
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	camera.position = Vector2(float(battle["field"]["w"]), float(battle["field"]["h"])) / 2.0 + Vector2(120, 0)
	camera.zoom = Vector2(0.62, 0.62)
	_build_hud()
	refresh()


# ------------------------------------------------------------------ interface
func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hud.add_child(top)
	var bar := HBoxContainer.new()
	top.add_child(bar)
	var title := Label.new()
	title.text = ("Bataille : " if mode == "battle" else "Préparation des défenses : ") + battle["field"]["name_fr"]
	title.add_theme_font_size_override("font_size", 17)
	bar.add_child(title)
	tool_label = Label.new()
	bar.add_child(tool_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	if mode == "battle":
		_btn(bar, "⏸ Pause", _on_pause)
		_btn(bar, "×1", func() -> void: speed = 1.0)
		_btn(bar, "×4", func() -> void: speed = 4.0)
		_btn(bar, "×16", func() -> void: speed = 16.0)
		_btn(bar, "Résolution automatique", _on_auto)
	_btn(bar, "Retour à la carte", _on_close)
	var left := PanelContainer.new()
	left.anchor_top = 0.0; left.anchor_bottom = 1.0
	left.offset_top = 44; left.offset_bottom = -30; left.offset_right = 330
	hud.add_child(left)
	var lbox := VBoxContainer.new()
	left.add_child(lbox)
	info = RichTextLabel.new()
	info.bbcode_enabled = true
	info.custom_minimum_size = Vector2(320, 300)
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbox.add_child(info)
	var grid := GridContainer.new()
	grid.columns = 2
	lbox.add_child(grid)
	if mode == "battle":
		for f: String in CombatData.FORMATIONS:
			_btn(grid, session.rules["combat"]["formations"][f]["label_fr"], func() -> void: _order(TacticalOrders.set_formation(battle, session.rules["combat"], me, selected, f)))
		_btn(grid, "Charge (cliquer un ennemi)", func() -> void: _set_tool("charge"))
		_btn(grid, "Tenir la position", func() -> void: _order(TacticalOrders.hold(battle, session.rules["combat"], me, selected)))
	_btn(grid, "Tranchée (2 clics)", func() -> void: _set_tool("trench"))
	for kind: String in CombatData.INSTALLATIONS:
		_btn(grid, session.rules["combat"]["construction"]["types"][kind]["label_fr"], func() -> void: _set_tool(kind))
	if mode == "battle":
		_btn(grid, "Fixer l'objectif commun", func() -> void: _set_tool("objective"))
	var right := PanelContainer.new()
	right.anchor_left = 1.0; right.anchor_right = 1.0; right.anchor_top = 0.0; right.anchor_bottom = 1.0
	right.offset_left = -360; right.offset_top = 44; right.offset_bottom = -30
	hud.add_child(right)
	var scroll := ScrollContainer.new()
	right.add_child(scroll)
	side_box = VBoxContainer.new()
	side_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(side_box)
	status_panel = RichTextLabel.new()
	status_panel.bbcode_enabled = true
	status_panel.fit_content = true
	status_panel.custom_minimum_size.x = 340
	message = Label.new()
	message.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	message.offset_top = -26
	message.add_theme_color_override("font_color", Color("#1b1b1b"))
	hud.add_child(message)


func _btn(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func say(text: String) -> void:
	message.text = text


func _set_tool(t: String) -> void:
	tool = "" if tool == t else t
	trench_start = null
	var labels := {"charge": "Charge : cliquez une unité ennemie repérée", "trench": "Tranchée : cliquez le début puis la fin",
		"objective": "Objectif commun : cliquez un objectif", "machine_gun_nest": "Cliquez l'emplacement du nid de mitrailleuses",
		"artillery_position": "Cliquez l'emplacement de la position d'artillerie", "command_post": "Cliquez l'emplacement du poste de commandement"}
	tool_label.text = "   Outil : " + labels.get(tool, "sélection")


func _order(err: String) -> void:
	say("Ordre exécuté." if err == "" else "Refusé : " + err)
	refresh()


## Rafraîchit les panneaux (sélection, état de la bataille, réserves, renforts, journal).
func refresh() -> void:
	queue_redraw()
	if info == null:
		return
	var cr: Dictionary = session.rules["combat"]
	var t := ""
	if selected.is_empty():
		t = "[i]Aucune unité sélectionnée.[/i]\nClic gauche : sélectionner (Maj : ajouter ; glisser : rectangle). Clic droit : déplacer la sélection."
	for uid: String in selected:
		var u: Dictionary = battle["units"].get(uid, {})
		if u.is_empty():
			continue
		var state_txt: String = {"active": "active", "routing": "[color=#c0392b]EN DÉROUTE[/color]", "withdrawn": "retirée",
			"destroyed": "anéantie", "reserve": "en réserve", "arriving": "en route", "available": "disponible"}.get(u["status"], u["status"])
		if TacticalSim.is_disorganized(cr, u):
			state_txt = "[color=#d35400]désorganisée[/color]"
		t += "[b]%s[/b] — %s\n  %d / %d soldats ; moral %.0f\n  %s ; ordre : %s ; %s\n" % [u["name_fr"], cr["unit_types"][u["type"]]["label_fr"],
			int(u["soldiers"]), int(u["start_soldiers"]), float(u["morale"]), cr["formations"][u["formation"]]["label_fr"], u["order"], state_txt]
	info.text = t
	for c in side_box.get_children():
		if c != status_panel:
			c.queue_free()
	if status_panel.get_parent() == null:
		side_box.add_child(status_panel)
	if mode == "planning":
		_planning_panel()
		return
	var b := battle
	var elapsed := int(b["tick"]) * float(cr["tick_seconds"])
	var total := int(b["max_ticks"]) * float(cr["tick_seconds"])
	var s := "[b]Temps[/b] %s / %s (durée maximale, sans prolongation)%s\n" % [_mmss(elapsed), _mmss(total), "  [color=#c0392b]EN PAUSE[/color]" if b["paused"] else ""]
	var mine: Dictionary = b["sides"][side]
	var other: Dictionary = b["sides"][CombatData.other(side)]
	s += "[b]Commandant de votre camp[/b] : %s (%s)\n" % [_n(mine["commander"]["nation"]), mine["commander"]["basis"]]
	s += "Objectif commun : %s\n" % _objective_name(mine["primary_objective"])
	var own := 0
	for uid: String in b["units"]:
		var u: Dictionary = b["units"][uid]
		if u["side"] == side and (u["status"] == CombatData.ACTIVE or u["status"] == CombatData.ROUTING):
			own += int(u["soldiers"])
	var est := 0
	for eid: String in b["fog"][side]:
		est += int(b["fog"][side][eid]["estimate"])
	s += "Vos forces sur le terrain : %d ; ennemis repérés (estimation) : ~%d\n[b]Objectifs[/b]\n" % [own, est]
	for o: Dictionary in b["objectives"]:
		var who: String = "vous" if o["controller"] == side else ("ennemi" if o["controller"] == CombatData.other(side) else "—")
		s += "  %s %s (poids %.1f) : %s\n" % ["★" if o["kind"] == "capital" else "⚑", o["name_fr"], float(o["weight"]), who]
	status_panel.text = s
	var res_title := Label.new()
	res_title.text = "Réserves et renforts"
	side_box.add_child(res_title)
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if u["nation"] != me:
			continue
		if u["status"] == CombatData.RESERVE:
			var row := HBoxContainer.new()
			side_box.add_child(row)
			var l := Label.new(); l.text = "%s (%d)" % [u["name_fr"], int(u["soldiers"])]; row.add_child(l)
			_btn(row, "Engager", func() -> void: _order(TacticalOrders.commit_reserve(b, cr, me, [uid])))
		elif u["status"] == CombatData.AVAILABLE:
			var row := HBoxContainer.new()
			side_box.add_child(row)
			var l := Label.new(); l.text = "%s depuis %s (%s)" % [u["name_fr"], session.world.regions[u["source_region"]]["name_fr"], _mmss(int(u["eta_ticks"]) * float(cr["tick_seconds"]))]; row.add_child(l)
			_btn(row, "Appeler", func() -> void: _order(TacticalOrders.call_reinforcement(b, cr, me, uid)))
		elif u["status"] == CombatData.ARRIVING:
			var l := Label.new(); l.text = "→ %s arrive dans %s" % [u["name_fr"], _mmss((int(u["arrive_tick"]) - int(b["tick"])) * float(cr["tick_seconds"]))]
			side_box.add_child(l)
	var log_title := Label.new()
	log_title.text = "Journal"
	side_box.add_child(log_title)
	for e: Dictionary in (b["log"] as Array).slice(-8):
		var l := Label.new()
		l.text = "[%s] %s" % [_mmss(int(e["tick"]) * float(cr["tick_seconds"])), e["text"]]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.custom_minimum_size.x = 330
		side_box.add_child(l)


func _planning_panel() -> void:
	var d: Dictionary = battle["defenses"]
	var s := "[b]Ouvrages de la région[/b] (travaux mensuels selon les soldats présents)\n"
	for t: Dictionary in d["trenches"]:
		s += "  Tranchée (%s) : niveau %d/%d, avancement %.0f %%\n" % [_n(t["owner"]), int(t["level"]), int(t["target_level"]), 100.0 * float(t["progress"]) / maxf(1.0, float(t["work_needed"]))]
	for i: Dictionary in d["installations"]:
		s += "  %s (%s) : %s\n" % [session.rules["combat"]["construction"]["types"][i["type"]]["label_fr"], _n(i["owner"]),
			"achevé" if i["complete"] else "%.0f %%" % (100.0 * float(i["progress"]) / maxf(1.0, float(i["work_needed"])))]
	s += "\nSoldats présents : %d. Coût en ressources : OUVERT (R-03)." % DefenseSystem.soldiers_present(session.state, me, region)
	status_panel.text = s


func _mmss(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _n(nid: Variant) -> String:
	return "—" if nid == null else session.state.nations[nid]["name_fr"]


func _objective_name(oid: String) -> String:
	for o: Dictionary in battle["objectives"]:
		if o["id"] == oid:
			return o["name_fr"]
	return "non fixé"


# ------------------------------------------------------------------ déroulement
func _process(delta: float) -> void:
	if mode != "battle" or battle.is_empty() or battle["status"] != "active" or battle["paused"]:
		return
	_acc += delta * speed / float(session.rules["combat"]["tick_seconds"])
	var n := int(_acc)
	if n <= 0:
		return
	_acc -= n
	var res := session.advance_battle(n)
	if not res.is_empty():
		_show_result(res)
	refresh()


func _show_result(res: Dictionary) -> void:
	result_box = PanelContainer.new()
	result_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hud.add_child(result_box)
	var box := VBoxContainer.new()
	result_box.add_child(box)
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.custom_minimum_size = Vector2(520, 0)
	var who: String = res["winner"]
	var verdict := "Bataille indécise : le défenseur conserve la région." if who == "" else ("[b]Victoire[/b]" if who == side else "[b]Défaite[/b]")
	l.text = "%s\nPertes : vous %d, adversaire %d.\nScores : pertes et état des forces %.2f, territoire %.2f (vous).\nFin : %s.\n[i]Pondérations provisoires (T-037).[/i]" % [verdict,
		int(res["stats"][side]["lost"]), int(res["stats"][CombatData.other(side)]["lost"]),
		float(res["scores"][side]["losses"]), float(res["scores"][side]["territory"]), res["end_reason"]]
	box.add_child(l)
	_btn(box, "Retour à la carte", _on_close)


func _on_pause() -> void:
	var paused := BattleManager.request_pause(battle, me, not bool(battle["paused"]))
	say("Bataille en pause." if paused else "Reprise.")
	refresh()


func _on_auto() -> void:
	var res := session.auto_resolve_battle()
	if not res.is_empty():
		_show_result(res)
	refresh()


func _on_close() -> void:
	if mode == "battle" and battle.get("status", "") == "active":
		say("La bataille doit être jouée ou résolue avant de quitter (T-029 A). Utilisez « Résolution automatique ».")
		return
	closed.emit()


# ------------------------------------------------------------------ entrées
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var pos := get_global_mouse_position()
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var before := pos
			camera.zoom *= 1.12 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12
			camera.zoom = camera.zoom.clamp(Vector2(0.2, 0.2), Vector2(4, 4))
			camera.position += before - get_global_mouse_position()
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_from = pos
			else:
				click_at(pos, mb.shift_pressed, _drag_from)
				_drag_from = null
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and mode == "battle":
			command_move(pos)
	elif event is InputEventMouseMotion:
		if _panning:
			camera.position -= (event as InputEventMouseMotion).relative / camera.zoom.x
		if _drag_from != null:
			queue_redraw()


## Clic gauche (utilisable par les tests) : outil actif, sinon sélection / rectangle.
func click_at(pos: Vector2, additive: bool = false, drag_from: Variant = null) -> void:
	var cr: Dictionary = session.rules["combat"]
	match tool:
		"trench":
			if trench_start == null:
				trench_start = pos
				say("Début de tranchée posé : cliquez la fin.")
			else:
				var a: Vector2 = trench_start
				trench_start = null
				tool = ""
				_build(func() -> String: return TacticalOrders.build_trench(battle, cr, me, selected, a, pos),
					Orders.build_trench(me, region, a, pos))
			return
		"machine_gun_nest", "artillery_position", "command_post":
			var kind := tool
			tool = ""
			_build(func() -> String: return TacticalOrders.build_installation(battle, cr, me, selected, kind, pos),
				Orders.build_installation(me, region, kind, pos))
			return
		"charge":
			tool = ""
			var target := unit_at(pos, true)
			_order("aucune unité ennemie repérée à cet endroit" if target == "" else TacticalOrders.charge(battle, cr, me, selected, target))
			return
		"objective":
			tool = ""
			for o: Dictionary in battle["objectives"]:
				if CombatData.v(o["pos"]).distance_to(pos) < 60.0:
					_order(TacticalOrders.set_primary_objective(battle, me, o["id"]))
					return
			say("Aucun objectif à cet endroit.")
			return
	if drag_from != null and (drag_from as Vector2).distance_to(pos) > 15.0:
		select_rect(Rect2(drag_from, pos - drag_from).abs(), additive)
		return
	var uid := unit_at(pos, false)
	if uid == "":
		if not additive:
			selected.clear()
	elif additive:
		if selected.has(uid):
			selected.erase(uid)
		else:
			selected.append(uid)
	else:
		selected = [uid]
	refresh()


func _build(in_battle: Callable, strategic: Dictionary) -> void:
	if mode == "battle":
		_order(in_battle.call())
	else:
		var err := session.queue_order(strategic)
		say("Ouvrage commandé (avance chaque mois)." if err == "" else "Refusé : " + err)
		refresh()


func select_rect(rect: Rect2, additive: bool = false) -> void:
	if not additive:
		selected.clear()
	for uid: String in CombatData.unit_ids(battle):
		var u: Dictionary = battle["units"][uid]
		if u["nation"] == me and u["status"] == CombatData.ACTIVE and rect.has_point(CombatData.v(u["pos"])) and not selected.has(uid):
			selected.append(uid)
	refresh()


func command_move(pos: Vector2) -> void:
	if selected.is_empty():
		say("Sélectionnez d'abord des unités.")
		return
	_order(TacticalOrders.move(battle, session.rules["combat"], me, selected, pos))


## Unité sous le curseur : les siennes (ou un ennemi REPÉRÉ si `enemy`).
func unit_at(pos: Vector2, enemy: bool) -> String:
	var best := ""
	var bd := 34.0 / camera.zoom.x
	for uid: String in CombatData.unit_ids(battle):
		var u: Dictionary = battle["units"][uid]
		if not CombatData.is_on_field(u):
			continue
		if enemy:
			if u["side"] == side or not TacticalSim.is_visible_to(battle, side, uid):
				continue
		elif u["nation"] != me:
			continue
		var d := CombatData.v(u["pos"]).distance_to(pos)
		if d < bd:
			bd = d
			best = uid
	return best


# ------------------------------------------------------------------ rendu
func _draw() -> void:
	if battle.is_empty():
		return
	var k := 1.0 / camera.zoom.x
	var poly := PackedVector2Array()
	for p: Array in battle["field"]["polygon"]:
		poly.append(CombatData.v(p))
	draw_colored_polygon(poly, FIELD)
	poly.append(poly[0])
	draw_polyline(poly, Color("#6b5d3a"), 2.0 * k)
	for t: Dictionary in battle["defenses"]["trenches"]:
		var col := Color("#5a3e1b") if int(t["level"]) > 0 else Color("#5a3e1b", 0.45)
		draw_line(CombatData.v(t["a"]), CombatData.v(t["b"]), col, (3.0 + 3.0 * int(t["level"])) * k)
		if not t["complete"]:
			draw_string(ThemeDB.fallback_font, CombatData.v(t["site"]) + Vector2(0, -8) * k, "%.0f %%" % (100.0 * float(t["progress"]) / maxf(1.0, float(t["work_needed"]))), HORIZONTAL_ALIGNMENT_CENTER, -1, int(11 * k))
	for i: Dictionary in battle["defenses"]["installations"]:
		var p := CombatData.v(i["pos"])
		var c := Color("#333333", 1.0 if i["complete"] else 0.4)
		match i["type"]:
			"machine_gun_nest": draw_arc(p, 12.0 * k, PI, TAU, 12, c, 4.0 * k)
			"artillery_position": draw_rect(Rect2(p - Vector2(12, 8) * k, Vector2(24, 16) * k), c, false, 3.0 * k)
			"command_post": draw_colored_polygon(PackedVector2Array([p + Vector2(0, -14) * k, p + Vector2(12, 8) * k, p + Vector2(-12, 8) * k]), c)
	for o: Dictionary in battle["objectives"]:
		var p := CombatData.v(o["pos"])
		var col := Color("#7f8c8d")
		if o["controller"] == side:
			col = Color("#27ae60")
		elif o["controller"] != "":
			col = Color("#c0392b")
		draw_arc(p, float(session.rules["combat"]["victory"]["objective_radius"]), 0, TAU, 48, Color(col, 0.35), 2.0 * k)
		draw_line(p, p + Vector2(0, -26) * k, Color.BLACK, 2.0 * k)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -26) * k, p + Vector2(16, -20) * k, p + Vector2(0, -14) * k]), col)
		draw_string(ThemeDB.fallback_font, p + Vector2(4, 14) * k, o["name_fr"], HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * k), Color.BLACK)
	if mode != "battle":
		return
	var cr: Dictionary = session.rules["combat"]
	# Ennemis repérés et mémoire (estompée, « ? » quand elle vieillit).
	for eid: String in battle["fog"][side]:
		var m: Dictionary = battle["fog"][side][eid]
		if TacticalSim.is_visible_to(battle, side, eid):
			continue
		var age := int(battle["tick"]) - int(m["tick"])
		var alpha := clampf(1.0 - float(age) / float(cr["fog"]["forget_ticks"]), 0.15, 0.6)
		var p := CombatData.v(m["pos"])
		draw_circle(p, 10.0 * k, Color(session.state.nations[m["nation"]]["color"], alpha))
		if age > int(cr["fog"]["stale_ticks"]):
			draw_string(ThemeDB.fallback_font, p + Vector2(-4, 5) * k, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * k), Color(0, 0, 0, alpha))
	for uid: String in CombatData.unit_ids(battle):
		var u: Dictionary = battle["units"][uid]
		if not CombatData.is_on_field(u):
			continue
		if u["side"] != side and not TacticalSim.is_visible_to(battle, side, uid):
			continue  # brouillard : jamais de vision omnisciente
		_draw_unit(u, k, cr)
	for uid: String in selected:
		var u: Dictionary = battle["units"].get(uid, {})
		if not u.is_empty() and u["dest"] != null:
			draw_dashed_line(CombatData.v(u["pos"]), CombatData.v(u["dest"]), Color(SELECT, 0.8), 2.0 * k, 10.0 * k)
	for uid: String in battle["units"]:
		var u: Dictionary = battle["units"][uid]
		if u["nation"] == me and u["status"] == CombatData.ARRIVING:
			var e := CombatData.v(u["entry"])
			draw_circle(e, 14.0 * k, Color("#2980b9", 0.5))
			draw_string(ThemeDB.fallback_font, e + Vector2(16, 0) * k, "renfort", HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * k))
	if _drag_from != null:
		var r := Rect2(_drag_from, get_global_mouse_position() - (_drag_from as Vector2)).abs()
		draw_rect(r, Color(SELECT, 0.15), true)
		draw_rect(r, SELECT, false, 1.5 * k)


func _draw_unit(u: Dictionary, k: float, cr: Dictionary) -> void:
	var p := CombatData.v(u["pos"])
	var col := Color(session.state.nations[u["nation"]]["color"])
	var outline := Color.BLACK
	if u["status"] == CombatData.ROUTING:
		outline = Color("#c0392b")
	elif TacticalSim.is_disorganized(cr, u):
		outline = Color("#e67e22")
	if selected.has(u["id"]):
		draw_circle(p, 26.0 * k, Color(SELECT, 0.45))
	var size: Vector2 = {"skirmish_line": Vector2(40, 12), "assault_column": Vector2(16, 34), "entrenched": Vector2(34, 16)}[u["formation"]] * k
	draw_rect(Rect2(p - size / 2.0, size), col)
	draw_rect(Rect2(p - size / 2.0, size), outline, false, 2.0 * k)
	var glyph: String = {"infantry": "I", "cavalry": "C", "artillery": "A"}[u["type"]]
	draw_string(ThemeDB.fallback_font, p + Vector2(-4, 5) * k, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * k), Color.WHITE)
	if u["side"] == side:
		var frac := clampf(float(u["morale"]) / 100.0, 0.0, 1.0)
		draw_rect(Rect2(p + Vector2(-20, 14) * k, Vector2(40, 4) * k), Color("#333333"))
		draw_rect(Rect2(p + Vector2(-20, 14) * k, Vector2(40 * frac, 4) * k), Color("#27ae60").lerp(Color("#c0392b"), 1.0 - frac))
