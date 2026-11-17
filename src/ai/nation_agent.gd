class_name NationAgent
extends RefCounted
## IA nationale — NIVEAU 2 OPÉRATIONNEL (Phase I post-MIL-01, PROPOSÉ).
## Elle décide UNIQUEMENT à partir de la vue nationale filtrée (IntelSystem.view_for)
## et de la géographie publique. Elle n'accède jamais à l'état complet ni aux effectifs
## cachés d'autrui. Tout est strictement déterministe.
##
## Architecture en couches :
##   perception (vue filtrée + rapports de renseignement datés) → mémoire (engagements
##   diplomatiques et estimations militaires) → évaluation (rapports de forces, terrain,
##   fortifications, logistique, valeur stratégique) → décision (postures défensives,
##   offensives avec choix de l'approche, mouvements de concentration, mobilisation).
##
## Ce que fait l'IA :
##   - mobilisation selon la doctrine nationale et la menace perçue (MobilizationAgent, T-052) ;
##   - diplomatie défensive de niveau 1 (réponses selon la mémoire, proposition de paix si occupée) ;
##   - choix dynamique de la posture défensive de chaque armée ("delay", "hold", "hold_at_all_costs") ;
##   - évaluation des régions ennemies (défendues ou non) à partir du renseignement disponible :
##       * renseignement inconnu ou ancien ("unknown" / "stale") → "reconnaissance" ;
##       * rapport de forces défavorable (< 0,85) → maintien en défense, attente de renforts ;
##       * rapport de forces intermédiaire, terrain montagneux ou position fortifiée → "limited_attack" ;
##       * supériorité nette et bon moral → "assault" ;
##   - acheminement des armées de l'intérieur vers les secteurs de front menacés ou offensifs ;
##   - repli prioritaire des formations coupées de leur ravitaillement vers la capitale.
## LIMITES documentées (hors périmètre Phase I) : aucune déclaration de guerre spontanée ni création
## d'alliance (Phase III).

const DEFAULT_OPS := {
	"min_offensive_morale": 38.0,
	"min_recon_morale": 42.0,
	"min_assault_morale": 55.0,
	"min_offensive_soldiers": 8000,
	"min_recon_soldiers": 15000,
	"min_reliable_intel": 0.50,
	"limited_attack_min_ratio": 0.85,
	"assault_min_ratio": 1.35,
	"fortified_assault_min_ratio": 1.75,
	"mountain_assault_min_ratio": 1.60,
	"overwhelming_unscouted_ratio": 2.40,
	"max_offensives_per_turn": 2,
	"max_armies_per_offensive": 1,
	"max_concentrations_per_turn": 1,
	"delay_max_ratio": 0.55,
	"delay_low_morale": 42.0,
	"delay_min_soldiers": 25000,
	"hold_at_all_costs_min_morale": 55.0,
	"hold_at_all_costs_min_soldiers": 35000,
	"fort_defense_mult_per_level": 0.22,
	"unknown_army_default_estimate": 55000,
	"ally_support_weight": 0.30,
	"delay_threatened_min_soldiers": 45000,
	"garrison_unknown_max_soldiers": 65000,
	"level1_fortified_assault_min_ratio": 1.50,
	"stale_ratio_caution": 0.85,
}


static func op_cfg(rules: Dictionary = {}) -> Dictionary:
	var ops: Variant = rules.get("ai_doctrines", {}).get("operations")
	return ops if ops is Dictionary else DEFAULT_OPS


static func decide(view: Dictionary, world: WorldMap, rules: Dictionary) -> Array:
	var orders: Array = []
	var me: String = view["nation"]
	orders.append_array(_answer_proposals(view, me))
	orders.append_array(_peace_initiatives(view, me))
	orders.append_array(_military(view, world, rules, me))
	orders.append_array(MobilizationAgent.decide(view, world, rules))  # T-052 : doctrine nationale
	return orders


# ------------------------------------------------------------------ diplomatie (inchangée, Phase III à venir)
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


static func _transits(view: Dictionary, me: String) -> Dictionary:
	var out: Dictionary = {}
	for t: Dictionary in view["public_treaties"]:
		if t["type"] == "transit" and t.get("grantee", "") == me:
			out[str(t.get("grantor", ""))] = true
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


# ------------------------------------------------------------------ militaire (Chantier B)
static func _military(view: Dictionary, world: WorldMap, rules: Dictionary, me: String) -> Array:
	var orders: Array = []
	var enemies := _at_war_with(view, me)
	var political: Dictionary = view["political"]
	var own_armies: Array = []
	for f: Dictionary in view["formations"]:
		if f["nation"] == me and not bool(f.get("engaged", false)):
			own_armies.append(f)
	if own_armies.is_empty():
		return orders
	# 1. Postures défensives (évaluées en guerre ou lorsqu'une armée s'écarte de la posture par défaut).
	if not enemies.is_empty():
		for f: Dictionary in own_armies:
			if f.get("soldiers") == null:
				continue
			var wanted := choose_defensive_posture(view, world, rules, me, f)
			var current := str(f.get("defensive_posture", "hold"))
			if wanted != current:
				orders.append(Orders.defensive_posture(me, f["id"], wanted))
	# 2. Hors guerre : repli éventuel des armées situées hors du territoire contrôlé vers la capitale.
	if enemies.is_empty():
		for f: Dictionary in own_armies:
			var here: String = f["region"]
			if political[here]["controller"] != me:
				var step := _step_towards(world, political, me, {}, here, view["capital_region"])
				if step != "" and step != here and _can_army_move_to(view, me, f, step):
					orders.append(Orders.move(me, f["id"], step))
		return orders
	# 3. En guerre : gestion prioritaire des armées coupées de leur ravitaillement.
	var assigned: Dictionary = {}  # fid -> true
	var transits := _transits(view, me)
	for f: Dictionary in own_armies:
		if not bool(f.get("supplied", true)) and not bool(f.get("encircled", false)):
			var step := _step_towards(world, political, me, transits, f["region"], view["capital_region"])
			if step != "" and step != f["region"] and _can_army_move_to(view, me, f, step):
				var ap := "limited_attack" if _region_has_enemy_army(view, enemies, step) else "assault"
				orders.append(Orders.move(me, f["id"], step, ap))
				assigned[f["id"]] = true
	# 4. Détermination des garnisons retenues pour ne pas découvrir la capitale ou créer un croisement T-045.
	var held_garrisons := _compute_garrison_holds(view, world, rules, me, enemies, own_armies, assigned)
	for fid: String in held_garrisons:
		assigned[fid] = true
	# 5. Planification des offensives (régions ennemies non défendues et régions ennemies défendues).
	var avail_armies: Array = own_armies.filter(func(f: Dictionary) -> bool: return not assigned.has(f["id"]))
	var off_orders := _plan_offensives(view, world, rules, me, enemies, avail_armies, assigned)
	orders.append_array(off_orders)
	# 6. Mouvement stratégique des armées de l'intérieur (non engagées sur un front) vers les régions frontalières.
	var rem_armies: Array = own_armies.filter(func(f: Dictionary) -> bool: return not assigned.has(f["id"]))
	var move_orders := _advance_interior_armies(view, world, rules, me, enemies, rem_armies, assigned)
	orders.append_array(move_orders)
	return orders


## Choix de la posture défensive d'une armée ("delay", "hold", "hold_at_all_costs") selon la valeur
## stratégique de la région, les fortifications, le ravitaillement, la retraite possible et le rapport de forces.
static func choose_defensive_posture(view: Dictionary, world: WorldMap, rules: Dictionary, me: String, army: Dictionary) -> String:
	var op := op_cfg(rules)
	var here: String = army["region"]
	var political: Dictionary = view["political"]
	var enemies := _at_war_with(view, me)
	var partners := _partners(view, me)
	var is_capital := (here == str(view.get("capital_region", "")))
	if is_capital:
		return "hold_at_all_costs"
	var own_soldiers := _own_soldiers_in(view, me, here)
	var morale := float(army.get("morale", 70.0)) if army.get("morale") != null else 70.0
	var supplied := bool(army.get("supplied", true))
	var encircled := bool(army.get("encircled", false))
	var fort_level := int(view.get("own_defenses", {}).get(here, 0))
	var can_retreat := false
	var enemy_neighbors := 0
	var enemy_threat := 0
	var nearby_friends := 0
	for n: String in world.neighbor_ids(here, true):
		var ctrl: String = political[n]["controller"]
		var has_enemy := _region_has_enemy_army(view, enemies, n)
		if (ctrl == me or partners.has(ctrl)) and not has_enemy:
			can_retreat = true
			nearby_friends += _own_soldiers_in(view, me, n)
		if enemies.has(ctrl) or has_enemy:
			enemy_neighbors += 1
			enemy_threat += _estimated_enemy_in(view, rules, enemies, n)
	# Place forte nationale bien garnie et au moral solide, ou position fortifiée sans retraite possible.
	if political[here]["sovereign"] == me and fort_level >= 2 and supplied \
			and own_soldiers >= int(op["hold_at_all_costs_min_soldiers"]) \
			and morale >= float(op["hold_at_all_costs_min_morale"]):
		return "hold_at_all_costs"
	if (encircled or not can_retreat) and fort_level >= 1 and morale >= 50.0:
		return "hold_at_all_costs"
	# Posture « retarder » : préserver l'armée dans une région secondaire si une retraite existe.
	if can_retreat and not encircled and fort_level < 2:
		if not supplied or morale < float(op["delay_low_morale"]):
			return "delay"
		if enemy_threat > 0:
			var eff_own := float(own_soldiers) * (1.0 + float(op["fort_defense_mult_per_level"]) * float(fort_level)) \
				+ float(op["ally_support_weight"]) * float(nearby_friends)
			if eff_own / float(enemy_threat) < float(op["delay_max_ratio"]):
				return "delay"
			if own_soldiers < int(op["delay_min_soldiers"]) and enemy_threat >= int(op["delay_min_soldiers"]) * 2:
				return "delay"
		if enemy_neighbors >= 3 and own_soldiers < int(op["delay_threatened_min_soldiers"]):
			return "delay"
	return "hold"


## Évalue une région ennemie cible `target` et détermine si une offensive est pertinente ainsi que
## l'approche à adopter ("reconnaissance", "limited_attack" ou "assault").
static func evaluate_target(view: Dictionary, world: WorldMap, rules: Dictionary, me: String,
		target: String, candidate_armies: Array) -> Dictionary:
	var op := op_cfg(rules)
	var political: Dictionary = view["political"]
	var enemies := _at_war_with(view, me)
	var owner: String = political[target]["controller"]
	if not enemies.has(owner) or candidate_armies.is_empty():
		return {"can_attack": false, "defended": false, "approach": "", "ratio": 0.0, "armies": [], "reason": "cible non hostile ou aucune armée"}
	var valid_armies: Array = []
	var unknown_own_armies: Array = []
	var total_own := 0
	var weighted_morale := 0.0
	for f: Dictionary in candidate_armies:
		if not _can_army_move_to(view, me, f, target):
			continue
		if not bool(f.get("supplied", true)):
			continue
		if f.get("soldiers") == null:
			unknown_own_armies.append(f)
			continue
		var m := float(f.get("morale", 70.0)) if f.get("morale") != null else 70.0
		var s := int(f.get("operational_soldiers", f["soldiers"]))
		if m < float(op["min_offensive_morale"]) or s < int(op["min_offensive_soldiers"]):
			continue
		valid_armies.append(f)
		total_own += s
		weighted_morale += m * float(s)
	var ri: Dictionary = view.get("region_intel", {}).get(target, {})
	var st_code: String = ri.get("status", "unknown")
	var armies_seen := int(ri["armies_seen"]) if ri.get("armies_seen") != null else _count_enemy_armies(view, enemies, target)
	var defended := armies_seen > 0 and st_code != "confirmed_clear"
	# Cas 0 : armées d'États hors MIL-01 (effectifs inconnus, `soldiers == null`) -> seulement régions non défendues.
	if valid_armies.is_empty():
		if not defended and not unknown_own_armies.is_empty():
			return {"can_attack": true, "defended": false, "approach": "assault", "ratio": 1.0,
				"armies": [unknown_own_armies[0]["id"]], "score": _strategic_value(view, world, me, target),
				"reason": "occupation de région non défendue"}
		return {"can_attack": false, "defended": defended, "approach": "", "ratio": 0.0, "armies": [], "reason": "aucune armée apte à l'offensive"}
	var avg_morale := weighted_morale / maxf(1.0, float(total_own))
	valid_armies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa := int(a.get("operational_soldiers", a["soldiers"]))
		var sb := int(b.get("operational_soldiers", b["soldiers"]))
		return sa > sb if sa != sb else str(a["id"]) < str(b["id"]))
	var base_score := _strategic_value(view, world, me, target)
	# Cas 1 : région ennemie observée vide (`confirmed_clear` ou aucune armée présente).
	if not defended:
		var enemy_adj := _has_adjacent_enemy_army(view, world, enemies, target)
		var ap := "limited_attack" if (enemy_adj and avg_morale < float(op["min_assault_morale"])) else "assault"
		return {"can_attack": true, "defended": false, "approach": ap, "ratio": 99.0,
			"armies": [valid_armies[0]["id"]], "score": base_score + 35.0,
			"reason": "région ennemie observée sans défense"}
	# Facteurs de terrain de la région cible.
	var reliefs: Array = world.regions[target].get("relief_categories", [])
	var terrain_mult := _terrain_defense_mult(reliefs)
	var is_mountain := reliefs.has("high_mountain") or reliefs.has("mountain")
	var rel := float(ri.get("reliability", 0.0))
	# Cas 2 : région défendue avec renseignement INCONNU ou ANCIEN (`unknown` ou `stale` ou fiabilité < seuil).
	if st_code == "unknown" or st_code == "stale" or rel < float(op["min_reliable_intel"]) or ri.get("estimated_soldiers") == null:
		# Si un rapport ancien (`stale`) indique déjà une force ennemie très supérieure à la nôtre, on s'abstient.
		if st_code == "stale" and ri.get("estimated_soldiers") != null:
			var stale_est := float(ri["estimated_soldiers"]) * terrain_mult
			if float(total_own) / maxf(1.0, stale_est) < float(op["limited_attack_min_ratio"]) * float(op["stale_ratio_caution"]):
				return {"can_attack": false, "defended": true, "approach": "", "ratio": float(total_own) / maxf(1.0, stale_est),
					"armies": [], "score": -999.0, "reason": "rapport ancien défavorable : attente de renforts"}
		var lead: Dictionary = valid_armies[0]
		var lead_s := int(lead.get("operational_soldiers", lead["soldiers"]))
		var lead_m := float(lead.get("morale", 70.0)) if lead.get("morale") != null else 70.0
		if lead_s >= int(op["min_recon_soldiers"]) and lead_m >= float(op["min_recon_morale"]):
			return {"can_attack": true, "defended": true, "approach": "reconnaissance",
				"ratio": float(lead_s) / float(maxi(1, armies_seen) * int(op["unknown_army_default_estimate"])),
				"armies": [lead["id"]], "score": base_score + 10.0,
				"reason": "renseignement %s : reconnaissance en force" % st_code}
		return {"can_attack": false, "defended": true, "approach": "", "ratio": 0.0, "armies": [],
			"reason": "effectif ou moral insuffisant pour une reconnaissance en force"}
	# Cas 3 : région défendue avec renseignement RÉCENT et FIABLE (`estimated`).
	var est_enemy := maxi(1000, int(ri["estimated_soldiers"]))
	var fort := int(ri.get("fortification_level", 0))
	var fort_mult := 1.0 + float(op["fort_defense_mult_per_level"]) * float(fort)
	var caution_mult := 1.0 + 0.20 * (1.0 - rel)
	var effective_enemy := maxf(2000.0, float(est_enemy) * terrain_mult * fort_mult * caution_mult)
	var ratio := float(total_own) / effective_enemy
	if ratio < float(op["limited_attack_min_ratio"]):
		return {"can_attack": false, "defended": true, "approach": "", "ratio": ratio, "armies": [],
			"score": -999.0, "reason": "rapport de forces estimé défavorable (%.2f)" % ratio}
	var assault_req := float(op["assault_min_ratio"])
	if fort >= 2:
		assault_req = maxf(assault_req, float(op["fortified_assault_min_ratio"]))
	elif fort == 1:
		assault_req = maxf(assault_req, float(op["level1_fortified_assault_min_ratio"]))
	if is_mountain:
		assault_req = maxf(assault_req, float(op["mountain_assault_min_ratio"]))
	var chosen_approach := "limited_attack"
	var target_ratio := 1.15
	if ratio >= assault_req and avg_morale >= float(op["min_assault_morale"]):
		chosen_approach = "assault"
		target_ratio = assault_req
	var chosen_ids: Array = []
	var acc_soldiers := 0
	for f: Dictionary in valid_armies:
		chosen_ids.append(f["id"])
		acc_soldiers += int(f.get("operational_soldiers", f["soldiers"]))
		if float(acc_soldiers) >= target_ratio * effective_enemy and chosen_approach == "limited_attack":
			break
	return {
		"can_attack": true, "defended": true, "approach": chosen_approach, "ratio": ratio,
		"armies": chosen_ids, "score": base_score + 20.0 * minf(3.0, ratio),
		"reason": "offensive (%s) avec ratio estimé %.2f (ennemi ~%d, fort niv. %d)" % [chosen_approach, ratio, est_enemy, fort],
	}


## Retient en garnison les armées indispensables à la protection de la capitale ou d'une frontière
## tenue par une seule armée modérée qui attend un renfort voisin immédiat face à l'inconnu.
static func _compute_garrison_holds(view: Dictionary, world: WorldMap, rules: Dictionary, me: String,
		enemies: Array, own_armies: Array, assigned: Dictionary) -> Dictionary:
	var holds: Dictionary = {}
	var op := op_cfg(rules)
	var by_region: Dictionary = {}
	for f: Dictionary in own_armies:
		if assigned.has(f["id"]):
			continue
		if not by_region.has(f["region"]):
			by_region[f["region"]] = []
		(by_region[f["region"]] as Array).append(f)
	for rid: String in by_region:
		var list: Array = by_region[rid]
		list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var sa := int(a.get("operational_soldiers", a["soldiers"])) if a.get("soldiers") != null else 0
			var sb := int(b.get("operational_soldiers", b["soldiers"])) if b.get("soldiers") != null else 0
			return sa < sb if sa != sb else str(a["id"]) < str(b["id"]))
		var enemy_adj_regions: Array = []
		var stronger_adj_friend := false
		var own_here := _own_soldiers_in(view, me, rid)
		for n: String in world.neighbor_ids(rid, true):
			if _region_has_enemy_army(view, enemies, n):
				enemy_adj_regions.append(n)
			elif view["political"][n]["controller"] == me and _own_soldiers_in(view, me, n) > own_here:
				stronger_adj_friend = true
		if enemy_adj_regions.is_empty():
			continue
		# 1. Capitale menacée par plusieurs secteurs ennemis : conserver au moins une armée en garnison.
		if rid == str(view.get("capital_region", "")) and (enemy_adj_regions.size() >= 2 or list.size() >= 2):
			holds[list[0]["id"]] = true
			continue
		# 2. Région avec plusieurs armées amies au contact de l'ennemi : si l'une part en reconnaissance,
		#    garder la plus petite en couverture si d'autres armées ennemies bordent la région.
		if list.size() >= 2 and enemy_adj_regions.size() >= 2:
			holds[list[0]["id"]] = true
			continue
		# 3. Couverture frontalière prudente : une armée unique d'effectif modéré (< 65 000 h) faisant face
		#    à une armée ennemie d'effectif INCONNU tient la frontière si un renfort ami plus puissant est
		#    immédiatement adjacent ou si elle compte moins de 35 000 hommes.
		if list.size() == 1 and list[0].get("soldiers") != null:
			var s := int(list[0].get("operational_soldiers", list[0]["soldiers"]))
			var all_unknown := true
			for en_rid: String in enemy_adj_regions:
				var ri: Dictionary = view.get("region_intel", {}).get(en_rid, {})
				if ri.get("status", "unknown") == "estimated" and float(ri.get("reliability", 0.0)) >= float(op["min_reliable_intel"]):
					all_unknown = false
			if all_unknown and s < int(op["garrison_unknown_max_soldiers"]) \
					and (s < int(op["hold_at_all_costs_min_soldiers"]) or stronger_adj_friend):
				holds[list[0]["id"]] = true
	return holds


static func _plan_offensives(view: Dictionary, world: WorldMap, rules: Dictionary, me: String,
		enemies: Array, avail_armies: Array, assigned: Dictionary) -> Array:
	var orders: Array = []
	var political: Dictionary = view["political"]
	# Plafonds opérationnels PROPOSÉS (ai_doctrines.operations) : une nation ne concentre pas
	# indéfiniment toutes ses armées sur le même mois. Sans ces bornes, chaque armée disponible
	# reçoit un ordre d'assaut et la résolution tactique devient quadratique en nombre d'unités.
	var op := op_cfg(rules)
	var max_offensives := maxi(1, int(op.get("max_offensives_per_turn", 2)))
	var max_armies := maxi(1, int(op.get("max_armies_per_offensive", 2)))
	var launched := 0
	# Recenser toutes les régions ennemies adjacentes à nos armées disponibles.
	var targets_map: Dictionary = {}
	for f: Dictionary in avail_armies:
		for n: String in world.neighbor_ids(f["region"], true):
			if enemies.has(political[n]["controller"]) and _can_army_move_to(view, me, f, n):
				if not targets_map.has(n):
					targets_map[n] = []
				(targets_map[n] as Array).append(f)
	var proposals: Array = []
	var target_ids := targets_map.keys()
	target_ids.sort()
	for target: String in target_ids:
		var ev := evaluate_target(view, world, rules, me, target, targets_map[target])
		if bool(ev.get("can_attack", false)):
			ev["target"] = target
			proposals.append(ev)
	proposals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa := float(a.get("score", 0.0))
		var sb := float(b.get("score", 0.0))
		return sa > sb if not is_equal_approx(sa, sb) else str(a["target"]) < str(b["target"]))
	for p: Dictionary in proposals:
		if launched >= max_offensives:
			break
		var target: String = p["target"]
		var still_avail: Array = []
		for f: Dictionary in targets_map[target]:
			if not assigned.has(f["id"]):
				still_avail.append(f)
		if still_avail.is_empty():
			continue
		var candidates: Array = still_avail
		if candidates.size() > max_armies:
			candidates = candidates.slice(0, max_armies)
		var re_ev := evaluate_target(view, world, rules, me, target, candidates)
		if not bool(re_ev.get("can_attack", false)):
			continue
		var ap: String = re_ev["approach"]
		for fid: String in re_ev["armies"]:
			orders.append(Orders.move(me, fid, target, ap))
			assigned[fid] = true
		launched += 1
	return orders


## Fait converger les armées situées à l'intérieur du territoire vers les régions frontalières en guerre.
static func _advance_interior_armies(view: Dictionary, world: WorldMap, rules: Dictionary, me: String,
		enemies: Array, rem_armies: Array, assigned: Dictionary) -> Array:
	var orders: Array = []
	if rem_armies.is_empty():
		return orders
	var political: Dictionary = view["political"]
	var transits := _transits(view, me)
	var op := op_cfg(rules)
	var max_concentrations := maxi(0, int(op.get("max_concentrations_per_turn", 4)))
	var moved := 0
	# Identifier les régions frontalières amies (adjacentes à une région contrôlée par un ennemi).
	var front_regions: Array = []
	var rids := political.keys()
	rids.sort()
	for rid: String in rids:
		if political[rid]["controller"] != me:
			continue
		for n: String in world.neighbor_ids(rid, true):
			if enemies.has(political[n]["controller"]):
				front_regions.append(rid)
				break
	if front_regions.is_empty():
		return orders
	for f: Dictionary in rem_armies:
		if moved >= max_concentrations:
			break
		var here: String = f["region"]
		if front_regions.has(here):
			continue  # déjà sur le front
		if not bool(f.get("supplied", true)):
			continue
		var best_front := ""
		var best_dist := 1 << 30
		for fr: String in front_regions:
			var path := world.shortest_path(here, fr, func(rid: String) -> bool:
				var c: String = political[rid]["controller"]
				return c == me or transits.has(c))
			if path.size() > 1 and path.size() < best_dist:
				best_dist = path.size()
				best_front = path[1]
		if best_front != "" and best_front != here and _can_army_move_to(view, me, f, best_front):
			orders.append(Orders.move(me, f["id"], best_front, "assault"))
			assigned[f["id"]] = true
			moved += 1
	return orders


static func _strategic_value(view: Dictionary, world: WorldMap, me: String, target: String) -> float:
	var political: Dictionary = view["political"]
	var owner: String = political[target]["controller"]
	var score := 0.0
	if political[target]["sovereign"] == me:
		score += 45.0  # libération prioritaire du territoire national occupé
	if view.get("capitals", {}).get(owner, "") == target:
		score += 50.0  # capitale adverse
	var cities: Array = world.regions[target].get("city_ids", [])
	score += float(cities.size()) * 4.0
	var enemy_cap: String = view.get("capitals", {}).get(owner, "")
	if enemy_cap != "":
		var d := world.shortest_path(target, enemy_cap).size()
		if d > 0:
			score += maxf(0.0, 20.0 - float(d) * 3.0)
	return score


static func _terrain_defense_mult(reliefs: Array) -> float:
	if reliefs.has("high_mountain"):
		return 1.40
	if reliefs.has("mountain"):
		return 1.25
	if reliefs.has("forest") or reliefs.has("marsh") or reliefs.has("hills"):
		return 1.12
	return 1.0


static func _can_army_move_to(view: Dictionary, me: String, f: Dictionary, target: String) -> bool:
	if bool(f.get("home_service_only", false)) and view["political"][target]["sovereign"] != me:
		return false
	var ctrl: String = view["political"][target]["controller"]
	if ctrl == me:
		return true
	if _at_war_with(view, me).has(ctrl):
		return true
	return _transits(view, me).has(ctrl)


static func _own_soldiers_in(view: Dictionary, me: String, rid: String) -> int:
	var total := 0
	for f: Dictionary in view["formations"]:
		if f["nation"] == me and f["region"] == rid and f.get("soldiers") != null:
			total += int(f.get("operational_soldiers", f["soldiers"]))
	return total


static func _region_has_enemy_army(view: Dictionary, enemies: Array, rid: String) -> bool:
	for f: Dictionary in view["formations"]:
		if f["region"] == rid and enemies.has(f["nation"]):
			return true
	return false


static func _count_enemy_armies(view: Dictionary, enemies: Array, rid: String) -> int:
	var n := 0
	for f: Dictionary in view["formations"]:
		if f["region"] == rid and enemies.has(f["nation"]):
			n += 1
	return n


static func _has_adjacent_enemy_army(view: Dictionary, world: WorldMap, enemies: Array, rid: String) -> bool:
	for n: String in world.neighbor_ids(rid, true):
		if _region_has_enemy_army(view, enemies, n):
			return true
	return false


static func _estimated_enemy_in(view: Dictionary, rules: Dictionary, enemies: Array, rid: String) -> int:
	var op := op_cfg(rules)
	var ri: Dictionary = view.get("region_intel", {}).get(rid, {})
	if ri.get("estimated_soldiers") != null and int(ri["estimated_soldiers"]) > 0:
		return int(ri["estimated_soldiers"])
	var count := _count_enemy_armies(view, enemies, rid)
	return count * int(op["unknown_army_default_estimate"])


static func _step_towards(world: WorldMap, political: Dictionary, me: String, transits: Dictionary, here: String, goal: String) -> String:
	var path := world.shortest_path(here, goal, func(rid: String) -> bool:
		var c: String = political[rid]["controller"]
		return c == me or transits.has(c))
	return path[1] if path.size() > 1 else ""
