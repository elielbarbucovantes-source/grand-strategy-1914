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
	if not (state.tech.get("cooperation", []) is Array):
		state.tech["cooperation"] = []
	if not (state.tech.get("transfers", []) is Array):
		state.tech["transfers"] = []


## RESTORATION 02 — enregistrer un accord de coopération scientifique accepté.
static func register_cooperation(state: GameState, proposal: Dictionary, rules: Dictionary) -> void:
	ensure(state, str(proposal["from"]))
	var members: Array = (proposal["to"] as Array).duplicate()
	members.append(str(proposal["from"]))
	var types: Dictionary = rules.get("diplomacy", {}).get("alliances", {}).get("types", {})
	var tcfg: Dictionary = types.get("tech", {})
	var duration := int(tcfg.get("duration_turns", 24))
	(state.tech["cooperation"] as Array).append({
		"id": state.new_id("coop"), "turn": state.turn, "members": members,
		"expires_turn": state.turn + duration, "status": "active"
	})
	RelationsSystem.record(state, str(proposal["from"]), str(members[0]), "treaty_signed", "tech", rules)
	state.log_event("technologie", "Coopération scientifique conclue entre %s." % str(members), members)


static func has_cooperation(state: GameState, a: String, b: String) -> bool:
	for c: Dictionary in state.tech.get("cooperation", []):
		if str(c.get("status", "")) != "active" or state.turn > int(c.get("expires_turn", 0)):
			continue
		if (c["members"] as Array).has(a) and (c["members"] as Array).has(b):
			return true
	return false


static func partners_of(state: GameState, nid: String) -> Array:
	var out: Array = []
	for c: Dictionary in state.tech.get("cooperation", []):
		if str(c.get("status", "")) != "active" or state.turn > int(c.get("expires_turn", 0)):
			continue
		for m: String in c["members"]:
			if m != nid and not out.has(m):
				out.append(m)
	return out


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


## RESTORATION 02 — transfert consensuel : une technologie déjà découverte par un partenaire
## peut être acquise à coût réduit et après délai. Jamais de copie gratuite ou universelle.
static func _diffraction(state: GameState, t: TechSystem, rules: Dictionary) -> void:
	var cfg: Dictionary = rules.get("research", {})
	var factor := float(cfg.get("diffusion_cost_factor", 0.6))
	var delay := int(cfg.get("transfer_months", 2))
	var donor_share := float(cfg.get("donor_share", 0.5))
	var min_industry := float(cfg.get("min_industry_for_transfer", 2.0))
	# 1. Livraison des transferts arrivés à échéance.
	for tr: Dictionary in state.tech.get("transfers", []):
		if str(tr.get("status", "")) != "in_transit" or state.turn < int(tr.get("arrival_turn", 0)):
			continue
		var recipient := str(tr["to"])
		var tid := str(tr["tech"])
		if not known(state, recipient, tid):
			(state.tech["known"][recipient] as Array).append(tid)
			state.log_event("technologie", "%s reçoit « %s » par coopération avec %s." % [
				state.nations[recipient]["name_fr"], tid, state.nations[str(tr["from"])]["name_fr"]], [recipient, str(tr["from"])])
		tr["status"] = "delivered"
		tr["delivered_turn"] = state.turn
	# 2. Nouveaux transferts : un seul en cours par couple et par accord.
	for coop: Dictionary in state.tech.get("cooperation", []):
		if str(coop.get("status", "")) != "active" or state.turn > int(coop.get("expires_turn", 0)):
			continue
		var members: Array = coop["members"]
		if members.size() < 2:
			continue
		for d: int in [0, 1]:
			var donor := str(members[d])
			var recipient := str(members[1 - d])
			if IndustrySystem.capacity(state, recipient) < min_industry:
				continue
			var busy := false
			for tr: Dictionary in state.tech.get("transfers", []):
				if str(tr["from"]) == donor and str(tr["to"]) == recipient and str(tr["status"]) == "in_transit":
					busy = true
					break
			if busy:
				continue
			var choices: Array = []
			for tid: String in state.tech["known"].get(donor, []):
				if known(state, recipient, tid):
					continue
				var data: Dictionary = t.by_id.get(tid, {})
				if int(data.get("year", 9999)) > state.year + 1:
					continue
				var prereqs: Array = data.get("prerequisites", [])
				var ok := true
				for pre: String in prereqs:
					if not known(state, recipient, pre):
						ok = false
						break
				if ok:
					choices.append(tid)
			if choices.is_empty():
				continue
			choices.sort_custom(func(a: String, b: String) -> bool:
				return float((t.by_id[a] as Dictionary).get("cost", 100)) < float((t.by_id[b] as Dictionary).get("cost", 100)))
			var tid2 := str(choices[0])
			var cost := float((t.by_id[tid2] as Dictionary).get("cost", 100)) * factor
			var buyer: Dictionary = state.economy["stocks"].get(recipient, {})
			if float(buyer.get("money", 0.0)) + 0.000001 < cost:
				continue
			ResourceSystem.consume(state, recipient, "money", cost)
			var seller: Dictionary = state.economy["stocks"].get(donor, {})
			seller["money"] = float(seller.get("money", 0.0)) + cost * donor_share
			(state.tech["transfers"] as Array).append({
				"id": state.new_id("transfer"), "tech": tid2, "from": donor, "to": recipient,
				"turn": state.turn, "arrival_turn": state.turn + delay, "cost": cost,
				"cooperation": str(coop["id"]), "status": "in_transit"
			})


static func monthly(state: GameState, t: TechSystem, rules: Dictionary) -> void:
	var cfg: Dictionary = rules.get("research", {})
	_diffraction(state, t, rules)
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
		# Coût économique réel (Phase V + RESTORATION 02) : chaque point consomme des fonds.
		# RESTORATION 02 : un projet déjà connu d'un partenaire coopérant coûte moins cher.
		var discount := 1.0
		var partners: Array = partners_of(state, nid)
		if not partners.is_empty():
			var discounted := 0
			for pr: Dictionary in projects:
				for partner: String in partners:
					if known(state, partner, str(pr["tech"])):
						discounted += 1
						break
			if discounted > 0:
				discount = 1.0 - (1.0 - float(cfg.get("diffusion_cost_factor", 0.6))) \
					* float(discounted) / float(projects.size())
		var costs: Dictionary = cfg.get("resource_cost_per_point", {})
		var affordable := points
		for res: String in costs:
			var need := float(costs[res]) * points * discount
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
