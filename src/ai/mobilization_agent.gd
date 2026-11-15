class_name MobilizationAgent
extends RefCounted
## Mobilisation autonome de l'IA (T-052, choix D ; MIL-01 phase 3).
##
## Perception : UNIQUEMENT la vue du gouvernement (IntelSystem.view_for) :
##   - publiques : guerres, traités actifs, carte politique (contrôle et souveraineté), postures et
##     échelons ouverts des autres puissances (T-056, sans volumes) ;
##   - formations étrangères visibles dans les régions voisines (sans effectifs) ;
##   - propres effectifs (`own_forces`), propres à ce gouvernement.
## Jamais : ordres secrets en attente, volumes appelés ou réservoirs des autres puissances.
##
## Décision (déterministe) : score de menace → posture selon la doctrine nationale
## (data/rules/ai_doctrines.json, valeurs PROPOSÉES), échelon suivant selon la politique de la
## doctrine, allocation situationnelle, désescalade après une période calme.

const LEVELS := ["paix", "preparatoire", "generale"]


## Score de menace et sa décomposition (pour les tests et l'explication des décisions).
static func assess(view: Dictionary, world: WorldMap, doctrines: Dictionary) -> Dictionary:
	var me: String = view["nation"]
	var w: Dictionary = doctrines["threat_weights"]
	var doc: Dictionary = doctrines["nations"].get(me, {})
	var partners := _partners(view, me)
	var enemies := _at_war_with(view, me)
	var political: Dictionary = view["political"]
	var mine: Dictionary = {}
	for rid: String in political:
		if political[rid]["controller"] == me:
			mine[rid] = true
	var border: Dictionary = {}
	for rid: String in mine:
		for n: String in world.neighbor_ids(rid, true):
			var owner: String = political[n]["controller"]
			if owner != me:
				border[owner] = true
	var parts: Dictionary = {"foreign_postures": 0.0, "wars": 0.0, "allies_at_war": 0.0, "enemy_armies": 0.0,
		"occupied": 0.0, "general_tension": 0.0}
	var react := float(doc.get("foreign_mobilization_reaction", 1.0))
	var pub: Dictionary = view.get("public_mobilization", {})
	var keys := pub.keys()
	keys.sort()
	for other: String in keys:
		if other == me or partners.has(other):
			continue
		var value := float(w["posture_value"][pub[other]["posture"]])
		parts["foreign_postures"] += value * float(w["bordering_rival"] if border.has(other) else w["distant_rival"]) * react
	parts["wars"] = float(enemies.size()) * float(w["at_war"])
	for ally: String in partners:
		if not _at_war_with(view, ally).is_empty():
			parts["allies_at_war"] += float(w["ally_at_war"])
	for f: Dictionary in view["formations"]:
		if enemies.has(f["nation"]):
			for n: String in world.neighbor_ids(f["region"], true):
				if mine.has(n):
					parts["enemy_armies"] += float(w["enemy_army_adjacent"])
					break
	for rid: String in political:
		if political[rid]["sovereign"] == me and political[rid]["controller"] != me:
			parts["occupied"] += float(w["occupied_region"])
	parts["general_tension"] = float(_great_power_wars(view)) * float(w["general_tension_per_war"]) * float(doc.get("general_tension_factor", 1.0))
	var total := 0.0
	for k: String in parts:
		total += float(parts[k])
	return {"score": total, "parts": parts, "at_war": not enemies.is_empty()}


static func decide(view: Dictionary, world: WorldMap, rules: Dictionary) -> Array:
	var me: String = view["nation"]
	var own: Dictionary = view.get("own_forces", {})
	var doctrines: Dictionary = rules.get("ai_doctrines", {})
	if own.get("source_type", "") != "historical" or not doctrines.get("nations", {}).has(me):
		return []  # aucune réserve modélisée (bac à sable, États hors MIL-01) : rien à décider
	var doc: Dictionary = doctrines["nations"][me]
	var a := assess(view, world, doctrines)
	var score := float(a["score"])
	var current: String = own["posture"]
	var target := "paix"
	if score >= float(doc["general_threshold"]):
		target = "generale"
	elif score >= float(doc["preparatory_threshold"]):
		target = "preparatoire"
	var orders: Array = []
	var cur_i := LEVELS.find(current)
	var tgt_i := LEVELS.find(target)
	if tgt_i > cur_i:
		orders.append(Orders.mobilization_posture(me, target))  # escalade immédiate
	elif tgt_i < cur_i and not bool(a["at_war"]) and _months_since_posture(view, own) >= int(doc["stand_down_months"]):
		orders.append(Orders.mobilization_posture(me, LEVELS[cur_i - 1]))  # désescalade progressive, d'un niveau
	# Échelon suivant : selon la politique de la doctrine (guerre, ou menace double du seuil général).
	var wants_next: bool = (doc["next_echelon_policy"] == "war" and bool(a["at_war"])) \
		or (doc["next_echelon_policy"] == "threat" and score >= 2.0 * float(doc["general_threshold"]))
	if wants_next and current == "generale" and _has_closed_echelon(own):
		orders.append(Orders.call_next_echelon(me))  # validé à la résolution (échelon épuisé, délai)
	# Allocation situationnelle (identique pour tous) : logistique si des réservistes sont bloqués
	# ou si un district est occupé.
	var policy: Dictionary = doctrines["allocation_policy"]
	var want: Dictionary = policy["occupied_or_blocked"] if (int(own.get("blocked", 0)) > 0 or float(a["parts"]["occupied"]) > 0.0) else policy["default"]
	var have: Dictionary = own.get("allocation", {})
	var differs := false
	for k: String in ["administration", "rail", "logistics"]:
		if int(have.get(k, -1)) != int(want[k]):
			differs = true
	if differs and (current != "paix" or not orders.is_empty()):
		orders.append(Orders.mobilization_allocation(me, int(want["administration"]), int(want["rail"]), int(want["logistics"])))
	return orders


static func _has_closed_echelon(own: Dictionary) -> bool:
	for e: Dictionary in own.get("echelons", []):
		if not bool(e["opened"]):
			return true
	return false


static func _months_since_posture(view: Dictionary, own: Dictionary) -> int:
	var last := -1
	for r: Dictionary in own.get("public_record", []):
		if r["kind"] == "posture":
			last = maxi(last, int(r["turn"]))
	return 1 << 20 if last < 0 else int(view["turn"]) - last


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


## Guerres publiques impliquant au moins une grande puissance dotée de forces historiques.
static func _great_power_wars(view: Dictionary) -> int:
	var powers: Dictionary = view.get("public_mobilization", {})
	var n := 0
	for w: Dictionary in view["wars"]:
		if powers.has(w["a"]) or powers.has(w["b"]):
			n += 1
	return n
