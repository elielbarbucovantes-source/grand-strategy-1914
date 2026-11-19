class_name TechSystem
extends RefCounted
## Phase VI.B/C — arbre technologique, recherche financée par l'économie, diffusion.
## Toute découverte est un choix : projet actif, coût réel, prérequis et délai.

const TREE_PATH := "res://data/game/technology_tree.json"

var tree: Dictionary = {}
var by_id: Dictionary = {}


static func load_tree() -> TechSystem:
	var t := TechSystem.new()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(TREE_PATH))
	if data is Dictionary:
		t.tree = data
		for tech: Dictionary in data.get("technologies", []):
			t.by_id[str(tech["id"])] = tech
	return t


static func ensure(state: GameState, nid: String) -> void:
	if not state.tech["known"].has(nid):
		state.tech["known"][nid] = []
	if not state.tech["projects"].has(nid):
		state.tech["projects"][nid] = []


static func known(state: GameState, nid: String, tech_id: String) -> bool:
	return (state.tech["known"].get(nid, []) as Array).has(tech_id)


static func can_research(state: GameState, t: TechSystem, nid: String, tech_id: String) -> String:
	if not t.by_id.has(tech_id):
		return "technologie inconnue"
	if known(state, nid, tech_id):
		return "déjà connue"
	var tech: Dictionary = t.by_id[tech_id]
	if int(tech.get("year", 1914)) > state.year + 1:
		return "avant son époque"
	for pre: String in tech.get("prerequisites", []):
		if not known(state, nid, pre):
			return "prérequis manquant : " + pre
	for p: Dictionary in state.tech["projects"].get(nid, []):
		if str(p["tech"]) == tech_id:
			return "projet déjà en cours"
	return ""


static func start_project(state: GameState, nid: String, tech_id: String) -> String:
	ensure(state, nid)
	var cfg: Dictionary = state.tech  # la configuration détaillée vient des règles
	var limit := 3
	var r: Variant = cfg.get("rules", {})
	if r is Dictionary:
		limit = int((r as Dictionary).get("max_projects_per_nation", 3))
	if (state.tech["projects"][nid] as Array).size() >= limit:
		return "nombre maximal de projets atteint"
	(state.tech["projects"][nid] as Array).append({"tech": tech_id, "progress": 0.0, "status": "en cours"})
	return ""


static func monthly(state: GameState, t: TechSystem, rules: Dictionary) -> void:
	var cfg: Dictionary = rules.get("research", {})
	for nid: String in state.nation_order:
		ensure(state, nid)
		var projects: Array = state.tech["projects"][nid]
		if projects.is_empty():
			continue
		var capacity := IndustrySystem.capacity(state, nid)
		var workers := DemographySystem.sector(state, nid, "industry")
		var points := float(cfg.get("science_per_turn_base", 0.5))
		points += capacity * float(cfg.get("science_from_industry", 0.15))
		points += workers * float(cfg.get("science_from_workforce", 0.00002))
		for tech_id: String in state.tech["known"][nid]:
			var tech: Dictionary = t.by_id.get(tech_id, {})
			points *= 1.0 + float((tech.get("effects", {}) as Dictionary).get("research_bonus", 0.0))
		points = minf(points, float(cfg.get("max_progress_per_turn", 20.0)))
		# Coût économique réel (Phase V) : chaque point consomme charbon/fer.
		var costs: Dictionary = cfg.get("resource_cost_per_point", {})
		var affordable := points
		for res: String in costs:
			var need := float(costs[res]) * points
			var got := ResourceSystem.consume(state, nid, res, need)
			if got + 0.000001 < need:
				affordable = minf(affordable, points * (got / maxf(need, 0.0001)))
		if affordable <= 0.0:
			continue
		var share := affordable / float(projects.size())
		for p: Dictionary in projects:
			var tech: Dictionary = t.by_id.get(str(p["tech"]), {})
			var cost := float(tech.get("cost", 100))
			p["progress"] = minf(cost, float(p["progress"]) + share)
			if float(p["progress"]) >= cost:
				p["status"] = "terminé"
				if not known(state, nid, str(p["tech"])):
					(state.tech["known"][nid] as Array).append(p["tech"])
					state.log_event("technologie", "%s achève la recherche « %s »." % [
						state.nations[nid]["name_fr"], tech.get("id", p["tech"])], [nid])
		state.tech["projects"][nid] = projects.filter(func(p: Dictionary) -> bool: return str(p["status"]) != "terminé")


static func effect(state: GameState, nid: String, key: String) -> float:
	var t := load_tree()
	var total := 0.0
	for tech_id: String in state.tech["known"].get(nid, []):
		var tech: Dictionary = t.by_id.get(tech_id, {})
		var v: Variant = (tech.get("effects", {}) as Dictionary).get(key)
		if v is float or v is int:
			total += float(v)
	return total


static func has_multiplier(state: GameState, nid: String, key: String) -> float:
	var t := load_tree()
	var mult := 1.0
	for tech_id: String in state.tech["known"].get(nid, []):
		var tech: Dictionary = t.by_id.get(tech_id, {})
		var v: Variant = (tech.get("effects", {}) as Dictionary).get(key)
		if v is float or v is int:
			mult *= float(v)
	return mult
