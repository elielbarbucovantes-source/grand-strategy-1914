class_name SaveRepository
extends RefCounted
## Sauvegarde et chargement. Enveloppe versionnée et contrôlée :
## format et version, version des règles, empreinte des données cartographiques, empreinte
## SHA-256 de l'état canonique. Détecte une sauvegarde corrompue (empreinte), incompatible
## (format, version, carte différente) ou tronquée (JSON invalide).

const FORMAT := "gs1914.save"
const FORMAT_VERSION := 1
const ENGINE := "Godot 4.7.2"


static func envelope(state: GameState, world: WorldMap, rules: Dictionary) -> Dictionary:
	return {
		"format": FORMAT, "format_version": FORMAT_VERSION, "engine": ENGINE,
		"rules_format_version": int(rules.get("format_version", 0)),
		"world_sha256": world.source_sha256, "scenario_id": state.scenario_id,
		"date": state.date_label(), "turn": state.turn, "player_nation": state.player_nation,
		"state_sha256": state.checksum(), "state": state.to_dict(),
	}


static func save(path: String, state: GameState, world: WorldMap, rules: Dictionary) -> String:
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "écriture impossible : %s" % error_string(FileAccess.get_open_error())
	file.store_string(JSON.stringify(envelope(state, world, rules), "", true))
	file.close()
	return ""


## Retourne {"state": GameState} ou {"error": String}.
static func load_save(path: String, world: WorldMap, rules: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"error": "fichier introuvable"}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		return {"error": "sauvegarde corrompue (JSON invalide)"}
	var env: Dictionary = data
	if env.get("format", "") != FORMAT:
		return {"error": "format inconnu"}
	if int(env.get("format_version", -1)) != FORMAT_VERSION:
		return {"error": "version de sauvegarde incompatible (%s)" % str(env.get("format_version"))}
	if int(env.get("rules_format_version", -1)) != int(rules.get("format_version", 0)):
		return {"error": "version des règles incompatible"}
	if env.get("world_sha256", "") != world.source_sha256:
		return {"error": "données cartographiques différentes de celles de la sauvegarde"}
	if not (env.get("state") is Dictionary):
		return {"error": "état absent"}
	var state := GameState.from_dict(env["state"])
	if state.checksum() != env.get("state_sha256", ""):
		return {"error": "sauvegarde corrompue (empreinte de l'état invalide)"}
	return {"state": state}


static func list_saves(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for name in dir.get_files():
		if name.ends_with(".json"):
			out.append(dir_path.path_join(name))
	out.sort()
	return out
