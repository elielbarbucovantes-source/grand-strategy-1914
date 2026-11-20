class_name CrossingSystem
extends RefCounted
## Phase VII.F/G — rivières, ponts et franchissements. S'intègre à MIL-01 et à la logistique
## Phase IV sans créer de second système de combat : fournit un facteur de difficulté abstrait.

const BRIDGES_PATH := "res://data/game/bridges.json"

var bridges: Dictionary = {}


static func load_bridges() -> CrossingSystem:
	var c := CrossingSystem.new()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(BRIDGES_PATH))
	if data is Dictionary:
		for b: Dictionary in data.get("bridges", []):
			c.bridges[str(b["id"])] = b
	return c


static func init_state(state: GameState) -> void:
	if state.bridges.is_empty():
		var c := load_bridges()
		state.bridges = c.bridges.duplicate(true)


static func crossing_for(state: GameState, rid: String) -> Dictionary:
	for bid: String in state.bridges:
		var b: Dictionary = state.bridges[bid]
		if str(b["region"]) == rid:
			return b
	return {}


## Facteur de difficulté d'un déplacement (1.0 = sans obstacle).
static func difficulty(state: GameState, rid: String, rules: Dictionary) -> float:
	var cfg: Dictionary = rules.get("bridges", {})
	var b := crossing_for(state, rid)
	if b.is_empty():
		return 1.0
	var status := str(b.get("status", "operational"))
	if status == "interrupted" or status == "repairing":
		return 1.0 + float(cfg.get("none_penalty", 1.0))
	var kind := str(b.get("crossing_type", "none"))
	match kind:
		"bridge": return 1.0 + float(cfg.get("bridge_penalty", 0.05))
		"ford": return 1.0 + float(cfg.get("ford_penalty", 0.2))
		"improvis": return 1.0 + float(cfg.get("improvis_penalty", 0.45))
	return 1.0 + float(cfg.get("base_crossing_penalty", 0.35))


static func set_status(state: GameState, bid: String, status: String) -> String:
	if not state.bridges.has(bid):
		return "franchissement inconnu"
	if status not in ["operational", "degraded", "interrupted", "repairing"]:
		return "état invalide"
	state.bridges[bid]["status"] = status
	state.log_event("franchissement", "Pont %s : %s." % [bid, status], [])
	return ""


static func logistics_factor(state: GameState, rid: String, rules: Dictionary) -> float:
	var cfg: Dictionary = rules.get("bridges", {})
	var b := crossing_for(state, rid)
	if b.is_empty() or str(b.get("status", "operational")) == "operational":
		return 1.0
	return float(cfg.get("interruption_logistics_factor", 0.5))
