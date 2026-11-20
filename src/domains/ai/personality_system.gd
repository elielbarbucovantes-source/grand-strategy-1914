class_name PersonalitySystem
extends RefCounted
## Consolidation 01 — attribution operationnelle des profils IA aux 22 États.
## Charge data/game/personality_assignments.json et alimente les quatre domains deja existants
## (diplomatique, economique, technologique, politique). Aucun nouveau parametre de comportement.

const ASSIGNMENTS_PATH := "res://data/game/personality_assignments.json"

var assignments: Dictionary = {}


static func load_assignments() -> PersonalitySystem:
	var p := PersonalitySystem.new()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ASSIGNMENTS_PATH))
	if data is Dictionary:
		p.assignments = data.get("assignments", {})
	return p


static func ensure(state: GameState) -> void:
	if not (state.politics is Dictionary):
		state.politics = {"states": {}, "decisions": [], "crises": [], "history": []}
	if not state.politics.has("states"):
		state.politics["states"] = {}
	if not (state.economy is Dictionary):
		state.economy = {}
	if not state.economy.has("personalities"):
		state.economy["personalities"] = {}
	if not (state.tech is Dictionary):
		state.tech = {}
	var ps := load_assignments()
	for nid: String in state.nation_order:
		var a: Dictionary = ps.assignments.get(nid, {})
		if a.is_empty():
			continue
		if not state.personalities.has(nid) or str(state.personalities[nid]) == "cautious":
			# N'ecrase pas une personnalite explicitement fixee par une simulation.
			state.personalities[nid] = str(a.get("diplomatic", "cautious"))
		if not state.economy["personalities"].has(nid) or str(state.economy["personalities"][nid]) == "stability":
			state.economy["personalities"][nid] = str(a.get("economic", "stability"))
		if not state.tech.has("personalities"):
			state.tech["personalities"] = {}
		if not state.tech["personalities"].has(nid):
			state.tech["personalities"][nid] = str(a.get("technological", "balanced"))
		if not state.politics["states"].has(nid):
			continue
		var pol: Dictionary = state.politics["states"][nid]
		if not pol.has("ai_personality") or str(pol["ai_personality"]) == "":
			pol["ai_personality"] = str(a.get("political", "pragmatic"))


static func profile(nid: String, domain: String) -> String:
	var ps := load_assignments()
	var a: Dictionary = ps.assignments.get(nid, {})
	return str(a.get(domain, ""))


static func note(nid: String) -> String:
	var ps := load_assignments()
	var a: Dictionary = ps.assignments.get(nid, {})
	return str(a.get("note", ""))
