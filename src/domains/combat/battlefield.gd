class_name Battlefield
extends RefCounted
## Construit le champ de bataille tactique d'une région :
## - forme : plus grand polygone de la région (export NP-0), normalisé dans un cadre abstrait ;
## - terrain : moyenne des modificateurs des catégories de relief de la région ;
## - objectifs : villes de la région (capitale pondérée) et centre ;
## - points d'entrée : bord du champ orienté vers la région d'origine de chaque camp.


static func build(world: WorldMap, rid: String, rules: Dictionary) -> Dictionary:
	var region: Dictionary = world.regions[rid]
	var cfg: Dictionary = rules["battlefield"]
	var largest: Array = []
	var best_area := -1.0
	for polygon: Array in region["polygons_km"]:
		var ring := PackedVector2Array()
		for p: Array in polygon[0]:
			ring.append(Vector2(p[0], -p[1]))
		var area := absf(_area(ring))
		if area > best_area:
			best_area = area
			largest = polygon[0]
	var pts := PackedVector2Array()
	for p: Array in largest:
		pts.append(Vector2(p[0], -p[1]))
	var bbox := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		bbox = bbox.expand(p)
	var margin := float(cfg["edge_margin"])
	var w := float(cfg["width"])
	var h := float(cfg["height"])
	var scale := minf((w - 2.0 * margin) / maxf(bbox.size.x, 1.0), (h - 2.0 * margin) / maxf(bbox.size.y, 1.0))
	var offset := Vector2(w, h) / 2.0 - bbox.get_center() * scale
	var polygon: Array = []
	for p in pts:
		polygon.append(CombatData.a(p * scale + offset))
	var objectives: Array = []
	for cid: String in region["city_ids"]:
		var c: Dictionary = world.cities[cid]
		var pos := Vector2(c["position_km"][0], -c["position_km"][1]) * scale + offset
		var kind := "capital" if c["is_capital"] else "city"
		objectives.append({"id": cid, "name_fr": c["name_fr"], "kind": kind, "pos": CombatData.a(_clamp(pos, w, h, margin)),
			"weight": float(rules["victory"]["objective_weights"][kind]), "controller": ""})
	var centre: Vector2 = world.label_point(rid)
	objectives.append({"id": "centre_" + rid, "name_fr": "Centre de " + region["name_fr"], "kind": "centre",
		"pos": CombatData.a(_clamp(Vector2(centre.x, -centre.y) * scale + offset, w, h, margin)),
		"weight": float(rules["victory"]["objective_weights"]["centre"]), "controller": ""})
	return {
		"region": rid, "name_fr": region["name_fr"], "w": w, "h": h, "km_per_unit": 1.0 / scale,
		"polygon": polygon, "relief": region["relief_categories"], "terrain": terrain_profile(region["relief_categories"], rules),
		"objectives": objectives,
	}


static func terrain_profile(relief: Array, rules: Dictionary) -> Dictionary:
	var keys := ["speed", "cover", "dig", "spot"]
	var out := {"speed": 0.0, "cover": 0.0, "dig": 0.0, "spot": 0.0}
	var n := 0
	for r: String in relief:
		if (rules["terrain"] as Dictionary).has(r):
			for k: String in keys:
				out[k] += float(rules["terrain"][r][k])
			n += 1
	if n == 0:
		return {"speed": 1.0, "cover": 0.0, "dig": 1.0, "spot": 1.0}
	for k: String in keys:
		out[k] = out[k] / n
	return out


## Point d'entrée d'un camp : sur le bord du cadre, dans la direction de la région source.
static func entry_point(world: WorldMap, field: Dictionary, source_rid: String) -> Vector2:
	var w := float(field["w"])
	var h := float(field["h"])
	var center := Vector2(w, h) / 2.0
	var dir := Vector2.ZERO
	if source_rid != "" and source_rid != field["region"] and world.has_region(source_rid):
		var a := world.label_point(field["region"])
		var b := world.label_point(source_rid)
		dir = Vector2(b.x - a.x, -(b.y - a.y)).normalized()
	if dir == Vector2.ZERO:
		return center
	var t := minf((w / 2.0 - 40.0) / maxf(absf(dir.x), 0.001), (h / 2.0 - 40.0) / maxf(absf(dir.y), 0.001))
	return center + dir * t


static func _clamp(p: Vector2, w: float, h: float, margin: float) -> Vector2:
	return Vector2(clampf(p.x, margin, w - margin), clampf(p.y, margin, h - margin))


static func _area(ring: PackedVector2Array) -> float:
	var s := 0.0
	for i in ring.size():
		var j := (i + 1) % ring.size()
		s += ring[i].x * ring[j].y - ring[j].x * ring[i].y
	return s / 2.0
