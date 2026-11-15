class_name NationAgent
extends RefCounted
## IA nationale — NIVEAU 1 (PROPOSÉ ; heuristiques techniques, non validées comme comportement
## définitif). Elle décide UNIQUEMENT à partir de la vue nationale filtrée (IntelSystem.view_for)
## et de la géographie publique. Elle n'accède jamais à l'état complet. Tout est déterministe.
##
## Architecture en couches :
##   perception (vue filtrée) → mémoire (engagements et comportements passés) → évaluation
##   (menaces, intérêts) → décision (ordres).
##
## Ce que fait le niveau 1 :
##   - mobilisation selon la doctrine nationale et la menace perçue (MobilizationAgent, T-052) ;
##   - répond aux propositions selon la mémoire (traité rompu ou guerre déclarée contre elle → refus) ;
##   - en guerre : défend son territoire, reprend ses régions occupées, occupe les régions
##     ennemies voisines non défendues en se rapprochant de la capitale adverse ;
##   - propose la paix à un pays qui occupe une de ses régions ;
##   - formation coupée de sa capitale → repli vers la capitale.
## LIMITES documentées : aucune déclaration de guerre spontanée (les critères relèvent du
## directeur) ; aucune coalition ; aucune gestion économique (données absentes) ; pas de
## mensonge ni de manipulation (canaux disponibles, stratégie non définie).


static func decide(view: Dictionary, world: WorldMap, rules: Dictionary) -> Array:
	var orders: Array = []
	var me: String = view["nation"]
	orders.append_array(_answer_proposals(view, me))
	orders.append_array(_peace_initiatives(view, me))
	orders.append_array(_military(view, world, rules, me))
	orders.append_array(MobilizationAgent.decide(view, world, rules))  # T-052 : doctrine nationale
	return orders


# ------------------------------------------------------------------ diplomatie
static func _hostile_memory(view: Dictionary, other: String) -> bool:
	for m: Dictionary in view["memory"]:
		if m["about"] == other and (m["kind"] == "treaty_broken" or (m["kind"] == "declared_war" and m["detail"] == view["nation"])):
			return true
	return false


static func _partners(view: Dictionary, me: String) -> Dictionary:
	var out: Dictionary = {}
	for t: Dictionary in view["public_treaties"]:
		if (t["members"] as Array).has(me) and (t["type"] == "alliance" or t["type"] == "entente"):
			for m: String in t["members"]:
				if m != me:
					out[m] = true
	return out


static func _at_war_with(view: Dictionary, me: String) -> Array:
	var out: Array = []
	for w: Dictionary in view["wars"]:
		if w["a"] == me and not out.has(w["b"]):
			out.append(w["b"])
		elif w["b"] == me and not out.has(w["a"]):
			out.append(w["a"])
	out.sort()
	return out


static func _answer_proposals(view: Dictionary, me: String) -> Array:
	var orders: Array = []
	var partners := _partners(view, me)
	for p: Dictionary in view["pending_proposals"]:
		var accept := false
		if _hostile_memory(view, p["from"]):
			accept = false
		elif p["kind"] == "peace":
			accept = _occupies_my_regions(view, me, p["from"])  # perdre du terrain incite à la paix
		elif p["kind"] == "transit" or p["kind"] == "alliance" or p["kind"] == "guarantee":
			accept = partners.has(p["from"])
		elif p["kind"] == "trade":
			accept = not _at_war_with(view, me).has(p["from"])
		orders.append(Orders.respond(me, p["id"], accept))
	return orders


static func _occupies_my_regions(view: Dictionary, me: String, other: String) -> bool:
	for rid: String in view["political"]:
		var r: Dictionary = view["political"][rid]
		if r["sovereign"] == me and r["controller"] == other:
			return true
	return false


static func _peace_initiatives(view: Dictionary, me: String) -> Array:
	var orders: Array = []
	for enemy: String in _at_war_with(view, me):
		if _occupies_my_regions(view, me, enemy):
			var already := false
			for p: Dictionary in view["pending_proposals"] + view["sent_proposals"]:
				if p["kind"] == "peace" and (p["from"] == enemy or p["to"] == enemy):
					already = true
			if not already:
				orders.append(Orders.propose_treaty(me, enemy, "peace"))
	return orders


# ------------------------------------------------------------------ militaire
static func _military(view: Dictionary, world: WorldMap, rules: Dictionary, me: String) -> Array:
	var orders: Array = []
	var enemies := _at_war_with(view, me)
	var political: Dictionary = view["political"]
	var claimed: Dictionary = {}  # régions déjà visées par une autre formation ce tour
	var enemy_presence: Dictionary = {}
	for f: Dictionary in view["formations"]:
		if enemies.has(f["nation"]):
			enemy_presence[f["region"]] = true
	for f: Dictionary in view["formations"]:
		if f["nation"] != me:
			continue
		var here: String = f["region"]
		var target := ""
		if not enemies.is_empty():
			target = _war_target(view, world, me, enemies, here, enemy_presence, claimed)
		elif political[here]["controller"] != me:
			target = _step_towards(world, political, me, here, view["capital_region"])
		if target != "" and target != here:
			claimed[target] = true
			orders.append(Orders.move(me, f["id"], target))
	return orders


static func _war_target(view: Dictionary, world: WorldMap, me: String, enemies: Array, here: String,
		enemy_presence: Dictionary, claimed: Dictionary) -> String:
	var political: Dictionary = view["political"]
	# 1. Défense : une formation ennemie visible menace-t-elle cette région ? Alors on tient la position.
	for n: String in world.neighbor_ids(here, true):
		if enemy_presence.has(n) and political[here]["controller"] == me:
			return ""
	# 2. Reprise d'une de ses régions occupées, puis occupation d'une région ennemie non défendue.
	var best := ""
	var best_score := 1 << 30
	for n: String in world.neighbor_ids(here, true):
		var owner: String = political[n]["controller"]
		if not enemies.has(owner) or enemy_presence.has(n) or claimed.has(n):
			continue
		var score := 0 if political[n]["sovereign"] == me else 1000
		var enemy_capital: String = view["capitals"][owner]
		score += world.shortest_path(n, enemy_capital).size()
		if score < best_score or (score == best_score and n < best):
			best_score = score
			best = n
	return best


static func _step_towards(world: WorldMap, political: Dictionary, me: String, here: String, goal: String) -> String:
	var path := world.shortest_path(here, goal, func(rid: String) -> bool: return political[rid]["controller"] == me)
	return path[1] if path.size() > 1 else ""
