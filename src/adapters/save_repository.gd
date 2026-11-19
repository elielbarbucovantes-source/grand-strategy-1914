class_name SaveRepository
extends RefCounted
## Sauvegarde et chargement. Enveloppe versionnée et contrôlée :
## format et version, version des règles, empreinte des données cartographiques, empreinte
## SHA-256 de l'état canonique. Détecte une sauvegarde corrompue (empreinte), incompatible
## (format, version, carte différente) ou tronquée (JSON invalide).

const FORMAT := "gs1914.save"
## Version 2 (MIL-01 phase 2, 15/11/2026) : échelons de mobilisation, postures, allocation, cohortes
## bloquées, comptabilité des pertes et des prisonniers. Version 1 refusée (Q9) : aucune migration
## fiable n'est possible (réservoir non échelonné, base historique corrigée en phase 1 : réservoirs
## allemand et italien, sièges russes ; pertes antérieures non comptabilisées).
## Version 3 (phase 4) : Territorial Force (catégorie distincte). Version 2 refusée : sauvegardes de
## développement des phases 2 et 3 seulement, sans Territorial Force (son incorporation ne pourrait pas
## être reconstituée de façon certaine si la posture générale était déjà adoptée).
## Version 4 (phase 6, étape 1) : pertes ventilées (tués, blessés en convalescence, inaptes, disparus,
## prisonniers). Version 3 MIGRÉE : les pertes « non ventilées » anciennes sont conservées telles
## quelles dans `legacy_unventilated` (aucune ventilation après coup) ; attrition et services perdus
## deviennent des disparus avec leur cause (ForceLedger.migrate_v1).
## Version 5 (Phase III) : relations, réputation, personnalités et structures diplomatiques.
## Version 4 MIGRÉE sans perte : les champs absents sont initialisés à vide ; traités, propositions,
## messages, wars et mémoire existants sont conservés tels quels.
## Version 6 (Phase IV) : état du réseau de transport (conditions, flux, réparations).
## Version 5 MIGRÉE sans perte : le champ absent est initialisé à vide, tout le reste est conservé.
const FORMAT_VERSION := 6  # 6 : réseau de transport Phase IV ; 5 : diplomatie Phase III
const ENGINE := "Godot 4.7.2"

## T3 : l'analyseur décimal de Godot 4.7 n'est pas correctement arrondi (p.ex. la chaîne
## "433.90000000000003" relit 433.9, à 1 ULP près). Une sauvegarde JSON perd donc des bits
## de flottants sans que l'empreinte canonique (elle aussi JSON) ne le détecte. Les flottants
## sont sérialisés sous forme de motif binaire 64 bits en hexadécimal, ce qui garantit une
## restauration bit pour bit. Les anciennes sauvegardes (nombres JSON nus) restent lisibles.
const FLOAT_KEY := "__gs1914_f64__"
const HEX := "0123456789abcdef"


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
	file.store_string(JSON.stringify(_encode_floats(envelope(state, world, rules)), "", true, true))
	file.close()
	return ""


static func _encode_floats(v: Variant) -> Variant:
	if v is Dictionary:
		var out := {}
		for k in v.keys():
			out[k] = _encode_floats(v[k])
		return out
	if v is Array:
		var out: Array = []
		for item in v:
			out.append(_encode_floats(item))
		return out
	if v is float:
		var raw: PackedByteArray = var_to_bytes(v)
		var hex := ""
		for b in raw:
			var x := int(b)
			hex += HEX[x >> 4] + HEX[x & 15]
		return {FLOAT_KEY: hex}
	return v


static func _decode_floats(v: Variant) -> Variant:
	if v is Dictionary:
		if v.size() == 1 and v.has(FLOAT_KEY) and v[FLOAT_KEY] is String:
			var h: String = v[FLOAT_KEY]
			var ba := PackedByteArray()
			var i := 0
			while i + 1 < h.length():
				ba.append(HEX.find(h.substr(i, 1)) * 16 + HEX.find(h.substr(i + 1, 1)))
				i += 2
			var decoded: Variant = bytes_to_var(ba)
			return decoded if decoded is float else v
		var out := {}
		for k in v.keys():
			out[k] = _decode_floats(v[k])
		return out
	if v is Array:
		var out: Array = []
		for item in v:
			out.append(_decode_floats(item))
		return out
	return v


## Retourne {"state": GameState} ou {"error": String}.
static func load_save(path: String, world: WorldMap, rules: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"error": "fichier introuvable"}
	var data: Variant = _decode_floats(JSON.parse_string(FileAccess.get_file_as_string(path)))
	if not (data is Dictionary):
		return {"error": "sauvegarde corrompue (JSON invalide)"}
	var env: Dictionary = data
	if env.get("format", "") != FORMAT:
		return {"error": "format inconnu"}
	if int(env.get("format_version", -1)) == 1:
		return {"error": "sauvegarde de l'ancien format (version 1, antérieure à la refonte de la mobilisation) : "
			+ "migration impossible de façon fiable (réservoirs non échelonnés, données historiques corrigées, pertes non comptabilisées). "
			+ "Commencez une nouvelle partie."}
	if int(env.get("format_version", -1)) == 5:
		return _load_v5(env, world, rules)
	if int(env.get("format_version", -1)) == 4:
		return _load_v4(env, world, rules)
	if int(env.get("format_version", -1)) == 3:
		return _load_v3(env, world, rules)
	if int(env.get("format_version", -1)) == 2:
		return {"error": "sauvegarde de la version 2 (développement, sans Territorial Force) : migration non fiable. Commencez une nouvelle partie."}
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


## Sauvegardes triées de la plus ancienne à la plus récente (date de modification, puis nom).
static func list_saves(dir_path: String) -> PackedStringArray:
	var entries: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return PackedStringArray()
	for name in dir.get_files():
		if name.ends_with(".json"):
			var path := dir_path.path_join(name)
			entries.append([FileAccess.get_modified_time(path), path])
	entries.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0] if x[0] != y[0] else x[1] < y[1])
	var out := PackedStringArray()
	for e: Array in entries:
		out.append(e[1])
	return out


## Migration v5 -> v6 (Phase IV) : mêmes contrôles, empreinte calculée sans le champ transport.
static func _load_v5(env: Dictionary, world: WorldMap, rules: Dictionary) -> Dictionary:
	if int(env.get("rules_format_version", -1)) != int(rules.get("format_version", 0)):
		return {"error": "version des règles incompatible"}
	if env.get("world_sha256", "") != world.source_sha256:
		return {"error": "données cartographiques différentes de celles de la sauvegarde"}
	if not (env.get("state") is Dictionary):
		return {"error": "état absent"}
	var state := GameState.from_dict(env["state"])
	var d := state.to_dict()
	d["format_version"] = 5
	d.erase("transport")
	var once := JSON.stringify(d, "", true, true)
	if JSON.stringify(JSON.parse_string(once), "", true, true).sha256_text() != env.get("state_sha256", ""):
		return {"error": "sauvegarde corrompue (empreinte de l'état invalide)"}
	return {"state": state, "migrated_from": 5}


## Migration v4 -> v5 (Phase III) : contrôles d'intégrité identiques, calcul de l'empreinte sur
## l'état d'ORIGINE (format 4). GameState.from_dict initialise les champs diplomatiques absents.
static func _load_v4(env: Dictionary, world: WorldMap, rules: Dictionary) -> Dictionary:
	if int(env.get("rules_format_version", -1)) != int(rules.get("format_version", 0)):
		return {"error": "version des règles incompatible"}
	if env.get("world_sha256", "") != world.source_sha256:
		return {"error": "données cartographiques différentes de celles de la sauvegarde"}
	if not (env.get("state") is Dictionary):
		return {"error": "état absent"}
	var state := GameState.from_dict(env["state"])
	var d := state.to_dict()
	d["format_version"] = 4
	# L'empreinte d'origine a été calculée avant l'ajout des champs Phase III.
	for k: String in ["relations", "reputation", "personalities", "diplomacy"]:
		d.erase(k)
	var once := JSON.stringify(d, "", true, true)
	if JSON.stringify(JSON.parse_string(once), "", true, true).sha256_text() != env.get("state_sha256", ""):
		return {"error": "sauvegarde corrompue (empreinte de l'état invalide)"}
	return {"state": state, "migrated_from": 4}


## Migration d'une sauvegarde de format 3 : contrôles d'intégrité identiques (carte, règles, empreinte
## calculée sur l'état d'ORIGINE), puis conversion du registre des pertes.
static func _load_v3(env: Dictionary, world: WorldMap, rules: Dictionary) -> Dictionary:
	if int(env.get("rules_format_version", -1)) != int(rules.get("format_version", 0)):
		return {"error": "version des règles incompatible"}
	if env.get("world_sha256", "") != world.source_sha256:
		return {"error": "données cartographiques différentes de celles de la sauvegarde"}
	if not (env.get("state") is Dictionary):
		return {"error": "état absent"}
	var state := GameState.from_dict(env["state"])
	# L'empreinte d'origine a été calculée avec le numéro de format 3 de l'état.
	var d := state.to_dict()
	d["format_version"] = 3
	var once := JSON.stringify(d, "", true, true)
	if JSON.stringify(JSON.parse_string(once), "", true, true).sha256_text() != env.get("state_sha256", ""):
		return {"error": "sauvegarde corrompue (empreinte de l'état invalide)"}
	ForceLedger.migrate_state(state)
	return {"state": state, "migrated_from": 3}
