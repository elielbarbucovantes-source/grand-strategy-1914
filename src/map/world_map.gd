class_name WorldMap
extends RefCounted
## Modèle cartographique immuable chargé depuis data/game/world_map.json (NP-0).
## Fournit régions, villes, voisinages (terre et détroits), liens maritimes et
## recherche de chemins. Aucune règle de jeu ici.

const DEFAULT_PATH := "res://data/game/world_map.json"

var regions: Dictionary = {}            # id -> Dictionary (copie de l'export)
var cities: Dictionary = {}             # id -> Dictionary
var region_ids: PackedStringArray = []  # ordre stable (tri par identifiant)
var neighbors: Dictionary = {}          # id -> Array[Dictionary] {"to": String, "kind": "land"|"strait"}
var maritime_links: Dictionary = {}     # region id -> Array[String] (zones)
var maritime_zones: Dictionary = {}     # zone id -> Dictionary
var source_sha256: String = ""


static func load_from(path: String = DEFAULT_PATH) -> WorldMap:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("WorldMap : fichier introuvable ou vide : %s" % path)
		return null
	var data: Variant = JSON.parse_string(text)
	if not (data is Dictionary) or data.get("format", "") != "gs1914.world_map":
		push_error("WorldMap : format invalide : %s" % path)
		return null
	var world := WorldMap.new()
	world.source_sha256 = text.sha256_text()
	world._ingest(data)
	return world


func _ingest(data: Dictionary) -> void:
	for region: Dictionary in data["regions"]:
		regions[region["id"]] = region
		neighbors[region["id"]] = []
		maritime_links[region["id"]] = []
	var ids := regions.keys()
	ids.sort()
	region_ids = PackedStringArray(ids)
	for city: Dictionary in data["cities"]:
		cities[city["id"]] = city
	for zone: Dictionary in data["maritime_zones"]:
		maritime_zones[zone["id"]] = zone
	var graph: Dictionary = data["graph"]
	for edge: Dictionary in graph["land_edges"]:
		_link(edge["a"], edge["b"], "land")
	for strait: Dictionary in graph["strait_crossings"]:
		_link(strait["a"], strait["b"], "strait")
	for link: Dictionary in graph["region_maritime_links"]:
		(maritime_links[link["region"]] as Array).append(link["zone"])
	for rid: String in region_ids:
		(neighbors[rid] as Array).sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x["to"] < y["to"])


func _link(a: String, b: String, kind: String) -> void:
	(neighbors[a] as Array).append({"to": b, "kind": kind})
	(neighbors[b] as Array).append({"to": a, "kind": kind})


func has_region(rid: String) -> bool:
	return regions.has(rid)


func neighbor_ids(rid: String, allow_straits: bool = true) -> PackedStringArray:
	var out := PackedStringArray()
	for n: Dictionary in neighbors.get(rid, []):
		if allow_straits or n["kind"] == "land":
			out.append(n["to"])
	return out


func connection_kind(a: String, b: String) -> String:
	for n: Dictionary in neighbors.get(a, []):
		if n["to"] == b:
			return n["kind"]
	return ""


## Plus court chemin (en nombre de régions) entre a et b ; `passable` filtre les régions
## traversables (Callable(rid: String) -> bool). Retourne [] si inaccessible.
func shortest_path(a: String, b: String, passable: Callable = Callable(), allow_straits: bool = true) -> PackedStringArray:
	if a == b:
		return PackedStringArray([a])
	var previous: Dictionary = {a: ""}
	var queue: Array[String] = [a]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for next: String in neighbor_ids(current, allow_straits):
			if previous.has(next):
				continue
			if next != b and passable.is_valid() and not passable.call(next):
				continue
			previous[next] = current
			if next == b:
				var path := PackedStringArray([b])
				var step: String = current
				while step != "":
					path.insert(0, step)
					step = previous[step]
				return path
			queue.append(next)
	return PackedStringArray()


func label_point(rid: String) -> Vector2:
	var p: Array = regions[rid]["label_point_km"]
	return Vector2(p[0], p[1])
