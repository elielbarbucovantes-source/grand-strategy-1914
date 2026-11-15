class_name MapView
extends Node2D
## Rendu cartographique interactif (aucune règle métier).
## Coordonnées : 1 unité = 1 km (EPSG:3035), axe y inversé pour l'écran.
## Zoom (molette), déplacement (clic droit ou molette maintenue, ou ZQSD/flèches), sélection (clic gauche).

signal region_clicked(region_id: String)

const SEA_COLOR := Color("#c9dbe3")
const ZONE_COLOR := Color("#b9d0dc")
const BORDER_COLOR := Color("#3a3a3a")
const SELECT_COLOR := Color("#ffd23f")
const NEIGHBOR_TINT := Color(1, 1, 1, 0.28)
const GROUP_ZOOM := 0.35   # en dessous : formations regroupées par région

var session: GameSession
var camera: Camera2D
var fills: Dictionary = {}        # rid -> Array[Polygon2D]
var hatches: Dictionary = {}      # rid -> Array[Polygon2D]
var borders: Array[Line2D] = []
var rings: Dictionary = {}        # rid -> Array[PackedVector2Array] (anneaux extérieurs)
var bounds: Dictionary = {}       # rid -> Rect2
var selected_region := ""
var selected_formation := ""
var visible_formations: Array = []
var _dragging := false
var _stripe: ImageTexture


func setup(s: GameSession) -> void:
	session = s
	for child in get_children():
		child.queue_free()
	fills.clear(); hatches.clear(); borders.clear(); rings.clear(); bounds.clear()
	RenderingServer.set_default_clear_color(SEA_COLOR)
	_stripe = _make_stripe_texture()
	for zid: String in session.world.maritime_zones:
		for polygon: Array in session.world.maritime_zones[zid]["polygons_km"]:
			var p := Polygon2D.new()
			p.polygon = _ring(polygon[0])
			p.color = ZONE_COLOR
			p.z_index = -4
			add_child(p)
	for rid: String in session.world.region_ids:
		fills[rid] = []
		hatches[rid] = []
		rings[rid] = []
		var rect := Rect2()
		var first := true
		for polygon: Array in session.world.regions[rid]["polygons_km"]:
			var outer := _ring(polygon[0])
			(rings[rid] as Array).append(outer)
			var fill := Polygon2D.new()
			fill.polygon = outer
			fill.z_index = -3
			add_child(fill)
			(fills[rid] as Array).append(fill)
			var hatch := Polygon2D.new()
			hatch.polygon = outer
			hatch.texture = _stripe
			hatch.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			hatch.texture_scale = Vector2(0.5, 0.5)
			hatch.visible = false
			hatch.z_index = -2
			add_child(hatch)
			(hatches[rid] as Array).append(hatch)
			for ring_index in polygon.size():
				var line := Line2D.new()
				line.points = _ring(polygon[ring_index])
				line.closed = true
				line.default_color = BORDER_COLOR
				line.width = 1.5
				line.z_index = -1
				add_child(line)
				borders.append(line)
			var r := _rect_of(outer)
			rect = r if first else rect.merge(r)
			first = false
		bounds[rid] = rect
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	center_on(session.state.nations[session.state.player_nation]["capital_region_id"], 0.25)
	refresh()


func _ring(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Array in points:
		out.append(Vector2(p[0], -p[1]))
	return out


func _rect_of(points: PackedVector2Array) -> Rect2:
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	return r


func _make_stripe_texture() -> ImageTexture:
	var size := 16
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			img.set_pixel(x, y, Color(1, 1, 1, 1) if (x + y) % size < 5 else Color(1, 1, 1, 0))
	return ImageTexture.create_from_image(img)


func screen_pos(rid: String) -> Vector2:
	var p := session.world.label_point(rid)
	return Vector2(p.x, -p.y)


func center_on(rid: String, zoom_value: float = -1.0) -> void:
	if zoom_value > 0.0:
		camera.zoom = Vector2(zoom_value, zoom_value)
	# Décalage pour que la région reste visible à gauche du panneau latéral (440 px).
	camera.position = screen_pos(rid) + Vector2(220.0, 0.0) / camera.zoom.x


## Recolore la carte depuis l'état (contrôle, occupation, sélection) et la vue du joueur.
func refresh() -> void:
	var st := session.state
	var neighbors: PackedStringArray = session.world.neighbor_ids(selected_region) if selected_region != "" else PackedStringArray()
	for rid: String in fills:
		var owner := st.controller(rid)
		var sovereign := st.sovereign(rid)
		var base := Color(st.nations[sovereign]["color"])
		if neighbors.has(rid):
			base = base.lerp(Color.WHITE, NEIGHBOR_TINT.a)
		if rid == selected_region:
			base = base.lerp(SELECT_COLOR, 0.35)
		for poly: Polygon2D in fills[rid]:
			poly.color = base
		for hatch: Polygon2D in hatches[rid]:
			hatch.visible = owner != sovereign
			hatch.color = Color(st.nations[owner]["color"]).darkened(0.1)
	var view := IntelSystem.view_for(st, session.world, st.player_nation)
	visible_formations = view["formations"]
	_update_line_widths()
	queue_redraw()


func _update_line_widths() -> void:
	if camera == null:
		return
	var w := clampf(1.3 / camera.zoom.x, 0.4, 12.0)
	for line in borders:
		line.width = w


func region_at(world_pos: Vector2) -> String:
	for rid: String in rings:
		if not (bounds[rid] as Rect2).has_point(world_pos):
			continue
		for ring: PackedVector2Array in rings[rid]:
			if Geometry2D.is_point_in_polygon(world_pos, ring):
				return rid
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if camera == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var factor := 1.15 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15
			var before := get_global_mouse_position()
			camera.zoom = (camera.zoom * factor).clamp(Vector2(0.08, 0.08), Vector2(6.0, 6.0))
			camera.position += before - get_global_mouse_position()
			_update_line_widths()
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var rid := region_at(get_global_mouse_position())
			if rid != "":
				region_clicked.emit(rid)
	elif event is InputEventMouseMotion and _dragging:
		camera.position -= (event as InputEventMouseMotion).relative / camera.zoom.x


func _process(delta: float) -> void:
	if camera == null:
		return
	var move := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if move != Vector2.ZERO:
		camera.position += move * 900.0 * delta / camera.zoom.x


func _draw() -> void:
	if session == null or camera == null:
		return
	var k := 1.0 / camera.zoom.x
	var st := session.state
	if selected_region != "" and rings.has(selected_region):
		for ring: PackedVector2Array in rings[selected_region]:
			var closed := ring.duplicate()
			closed.append(ring[0])
			draw_polyline(closed, SELECT_COLOR, 3.5 * k)
	# Villes et capitales (étoiles), noms des capitales toujours visibles (MAP-DEC-41).
	for cid: String in session.world.cities:
		var c: Dictionary = session.world.cities[cid]
		var p := Vector2(c["position_km"][0], -c["position_km"][1])
		if c["is_capital"]:
			draw_colored_polygon(_star(p, 9.0 * k), Color("#1d1d1d"))
			draw_colored_polygon(_star(p, 6.5 * k), Color("#f5d142"))
			draw_string(ThemeDB.fallback_font, p + Vector2(10, -6) * k, c["name_fr"], HORIZONTAL_ALIGNMENT_LEFT, -1, int(13 * k), Color.BLACK)
		elif camera.zoom.x > 0.5:
			draw_circle(p, 3.0 * k, Color("#2b2b2b"))
			draw_string(ThemeDB.fallback_font, p + Vector2(5, -4) * k, c["name_fr"], HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * k), Color("#2b2b2b"))
	# Formations visibles (figurines) ; regroupement automatique selon le zoom.
	var by_region: Dictionary = {}
	for f: Dictionary in visible_formations:
		if not by_region.has(f["region"]):
			by_region[f["region"]] = []
		(by_region[f["region"]] as Array).append(f)
	for rid: String in by_region:
		var group: Array = by_region[rid]
		var base := screen_pos(rid) + Vector2(0, 18) * k
		if camera.zoom.x < GROUP_ZOOM and group.size() > 1:
			_draw_figurine(base, Color(st.nations[group[0]["nation"]]["color"]), k, "×%d" % group.size(), false)
			continue
		for i in group.size():
			var f: Dictionary = group[i]
			var pos := base + Vector2((i - (group.size() - 1) / 2.0) * 26.0, 0) * k
			var full: Dictionary = st.formations.get(f["id"], {})
			_draw_figurine(pos, Color(st.nations[f["nation"]]["color"]), k, "", f["id"] == selected_formation)
			# Flèche d'ordre (formations du joueur seulement).
			if f["nation"] == st.player_nation and full.get("planned_target", "") != "":
				_draw_arrow(pos, screen_pos(full["planned_target"]), k)


func _draw_figurine(p: Vector2, color: Color, k: float, label: String, selected: bool) -> void:
	# Figurine stylisée : tête, corps, socle (pas de symbole OTAN).
	var s := 9.0 * k
	if selected:
		draw_circle(p, s * 2.0, Color(SELECT_COLOR, 0.6))
	draw_rect(Rect2(p + Vector2(-s, s * 0.8), Vector2(2 * s, s * 0.5)), Color("#222222"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.7, s * 0.8), p + Vector2(s * 0.7, s * 0.8),
		p + Vector2(s * 0.5, -s * 0.4), p + Vector2(-s * 0.5, -s * 0.4)]), color)
	draw_circle(p + Vector2(0, -s * 0.8), s * 0.45, color.darkened(0.25))
	draw_line(p + Vector2(s * 0.55, s * 0.6), p + Vector2(s * 0.9, -s * 1.4), Color("#222222"), maxf(1.0, s * 0.18))
	if label != "":
		draw_string(ThemeDB.fallback_font, p + Vector2(s * 1.2, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * k), Color.BLACK)


func _draw_arrow(from: Vector2, to: Vector2, k: float) -> void:
	var col := Color("#c0392b")
	var dir := (to - from).normalized()
	var tip := to - dir * 12.0 * k
	draw_line(from, tip, col, 4.0 * k)
	var side := dir.orthogonal() * 7.0 * k
	draw_colored_polygon(PackedVector2Array([to, tip + side, tip - side]), col)


func _star(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var radius := r if i % 2 == 0 else r * 0.45
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * radius)
	return pts
