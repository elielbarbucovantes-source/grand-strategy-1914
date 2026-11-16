class_name TacticalAI
extends RefCounted
## IA tactique — niveau 1 (comportements PROPOSÉS, paramètres dans combat_rules.json → "ai").
## Elle respecte les mêmes règles que les joueurs : elle commande ses SEULES unités par
## TacticalOrders, ne voit que ce que le brouillard révèle à son camp (visibilité et mémoire
## datée), et respecte l'objectif commun fixé par le commandant général (T-029 F).
## Comportements :
##   - commandant IA : fixe l'objectif commun (attaque : objectif adverse le plus pondéré et
##     le plus proche ; défense : objectif à tenir le plus pondéré) ;
##   - choix des formations : colonne loin du contact, ligne de tirailleurs au contact,
##     position retranchée en défense statique ;
##   - charge seulement si son moral est élevé et la cible repérée affaiblie (en déroute ou
##     estimation d'effectifs nettement inférieure) ;
##   - repli d'une unité très éprouvée avant la déroute ; engagement des réserves quand le front
##     faiblit ; appel des renforts si le rapport de forces estimé est défavorable ;
##   - défenseur sans contact : creuse une tranchée devant l'objectif.
## Phase 6, étape 2 : l'IA respecte l'approche de l'attaquant (charges, objectif, avance, réserves) et
## la posture du défenseur (retranchement, repli volontaire) ; ce sont des règles, pas des bonus.


static func decide(b: Dictionary, rules: Dictionary, nation: String) -> void:
	if b["status"] != "active":
		return
	var side := TacticalSim.side_of_nation(b, nation)
	if side == "":
		return
	var ai: Dictionary = rules["ai"]
	if b["sides"][side]["commander"]["nation"] == nation or b["sides"][side]["primary_objective"] == "":
		_set_objective(b, side, nation)
	var objective := _objective_pos(b, side)
	var mine: Array = []
	var front_morale := 0.0
	var front_n := 0
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if u["nation"] == nation and u["status"] == CombatData.ACTIVE:
			mine.append(uid)
			front_morale += float(u["morale"])
			front_n += 1
	var known := _known_enemies(b, side)
	# Réserves et renforts.
	var avg := front_morale / maxf(1.0, float(front_n))
	var enemy_near_objective := false
	for e: Dictionary in known:
		if CombatData.v(e["pos"]).distance_to(objective) <= float(rules["victory"]["objective_radius"]) * 2.0:
			enemy_near_objective = true
	var may_commit: bool = Engagement.side_param(b, rules, side, "commit_reserves", true)
	if may_commit and (front_n == 0 or avg < float(ai["reserve_commit_frontline_morale"]) or enemy_near_objective):
		var reserves: Array = []
		for uid: String in CombatData.unit_ids(b):
			if b["units"][uid]["nation"] == nation and b["units"][uid]["status"] == CombatData.RESERVE:
				reserves.append(uid)
		if not reserves.is_empty():
			TacticalOrders.commit_reserve(b, rules, nation, reserves)
	if int(b["tick"]) == 0:
		_reinforce(b, rules, nation, side, known)
	# Ordres unité par unité.
	var att_inf_contact := false
	var charging_targets: Dictionary = {}
	for oid: String in CombatData.unit_ids(b):
		var ou: Dictionary = b["units"][oid]
		if ou["side"] == side and ou["status"] == CombatData.ACTIVE:
			if ou["order"] == "charge" and str(ou.get("target", "")) != "":
				charging_targets[ou["target"]] = int(charging_targets.get(ou["target"], 0)) + 1
			if ou["type"] == "infantry":
				for e: Dictionary in known:
					if CombatData.v(ou["pos"]).distance_to(CombatData.v(e["pos"])) <= 310.0:
						att_inf_contact = true
						break
	for uid: String in mine:
		var u: Dictionary = b["units"][uid]
		var pos := CombatData.v(u["pos"])
		if float(u["morale"]) < float(ai["withdraw_morale"]) and bool(Engagement.side_param(b, rules, side, "voluntary_withdraw", true)):
			_formation_if(b, rules, nation, uid, "skirmish_line")
			TacticalOrders.move(b, rules, nation, [uid], CombatData.v(u["retreat_point"]).lerp(pos, 0.6))
			continue
		if u["order"] == "charge" or u["order"] == "build":
			continue
		var nearest := {}
		var nd := INF
		for e: Dictionary in known:
			var d := pos.distance_to(CombatData.v(e["pos"]))
			if d < nd:
				nd = d
				nearest = e
		var weak_target := {}
		var charges: String = Engagement.side_param(b, rules, side, "charges", "all" if side == CombatData.ATTACKERS else "never")
		if float(u["morale"]) >= float(ai["charge_min_morale"]) and u["type"] != "artillery" and charges != "never":
			for e: Dictionary in known:
				var max_chargers := 1 if bool(e["routing"]) else 2
				if int(charging_targets.get(e["id"], 0)) >= max_chargers:
					continue
				var ed := pos.distance_to(CombatData.v(e["pos"]))
				if not e["fresh"] or ed > float(ai["charge_range"]) or ed > nd + 55.0:
					continue
				if e["type"] == "artillery" and ed > 90.0:
					continue
				if (e["routing"] and ed <= 80.0 and int(e["estimate"]) >= int(u["soldiers"]) * 0.65) \
						or (not e["routing"] and charges == "all" and (bool(e.get("disorganized", false)) or (e["type"] == u["type"] and int(e["estimate"]) < int(u["soldiers"]) * 0.75))):
					weak_target = e
					break
		if not weak_target.is_empty():
			charging_targets[weak_target["id"]] = int(charging_targets.get(weak_target["id"], 0)) + 1
			_formation_if(b, rules, nation, uid, "assault_column")
			TacticalOrders.charge(b, rules, nation, [uid], weak_target["id"])
			continue
		var range_u := float(rules["unit_types"][u["type"]]["range"])
		if side == CombatData.DEFENDERS:
			var entrench: bool = Engagement.side_param(b, rules, side, "entrench", true)
			var att_entry := CombatData.v(b["sides"][CombatData.ATTACKERS]["entry"])
			var away_dir := (objective - att_entry).normalized()
			if away_dir == Vector2.ZERO:
				away_dir = Vector2.LEFT
			if u["type"] == "artillery":
				var art_anchor := objective + away_dir * 95.0 + _spread(uid) * 45.0
				art_anchor = Vector2(clampf(art_anchor.x, 60.0, float(b["field"]["w"]) - 60.0), clampf(art_anchor.y, 60.0, float(b["field"]["h"]) - 60.0))
				_formation_if(b, rules, nation, uid, "skirmish_line")
				if nd < 190.0 and front_n > 1:
					TacticalOrders.move(b, rules, nation, [uid], art_anchor + away_dir * 60.0)
				elif pos.distance_to(art_anchor) > 75.0:
					TacticalOrders.move(b, rules, nation, [uid], art_anchor)
				else:
					TacticalOrders.hold(b, rules, nation, [uid])
				continue
			if entrench and TacticalSim.trench_level(b, rules, u) > 0:
				_formation_if(b, rules, nation, uid, "entrenched")
				TacticalOrders.hold(b, rules, nation, [uid])
				continue
			var fort_site := _nearest_fort_site(b, side, pos) if entrench else Vector2.INF
			var anchor := (fort_site + _spread(uid) * 35.0) if fort_site != Vector2.INF else (objective + _spread(uid) * 80.0)
			if nd <= range_u and pos.distance_to(anchor) <= 220.0:
				_formation_if(b, rules, nation, uid, "entrenched" if entrench else "skirmish_line")
				TacticalOrders.hold(b, rules, nation, [uid])
			elif pos.distance_to(anchor) > 60.0:
				_formation_if(b, rules, nation, uid, "assault_column" if pos.distance_to(anchor) > float(ai["column_distance"]) and nd > 320.0 else "skirmish_line")
				TacticalOrders.move(b, rules, nation, [uid], anchor)
			elif entrench and known.is_empty() and u["type"] == "infantry" and _side_trench_length(b, side) < 1.0 and int(b["tick"]) < int(b["max_ticks"]) / 3:
				var facing := (CombatData.v(b["sides"][CombatData.ATTACKERS]["entry"]) - objective).normalized()
				var center := objective + facing * 120.0
				var perp := facing.orthogonal() * 110.0
				TacticalOrders.build_trench(b, rules, nation, [uid], center - perp, center + perp)
			else:
				_formation_if(b, rules, nation, uid, "entrenched" if entrench else "skirmish_line")
				TacticalOrders.hold(b, rules, nation, [uid])
		else:
			if u["type"] == "artillery":
				var stand := objective.lerp(CombatData.v(u["retreat_point"]), 0.22)
				_formation_if(b, rules, nation, uid, "skirmish_line")
				if nd <= range_u * 0.55:
					TacticalOrders.hold(b, rules, nation, [uid])
				elif pos.distance_to(stand) > 60.0:
					TacticalOrders.move(b, rules, nation, [uid], stand)
				else:
					TacticalOrders.hold(b, rules, nation, [uid])
				continue
			if u["type"] == "cavalry" and not att_inf_contact and nd <= 300.0:
				_formation_if(b, rules, nation, uid, "skirmish_line")
				TacticalOrders.hold(b, rules, nation, [uid])
				continue
			var target_pos := CombatData.v(nearest["pos"]) if not nearest.is_empty() and pos.distance_to(objective) <= 140.0 else objective
			if nd <= range_u * 0.9:
				_formation_if(b, rules, nation, uid, "skirmish_line")
				if Engagement.side_param(b, rules, side, "advance", "objective") == "contact":
					TacticalOrders.hold(b, rules, nation, [uid])  # reconnaissance : on éprouve la défense sans avancer
				else:
					TacticalOrders.move(b, rules, nation, [uid], pos.move_toward(target_pos, 60.0))
			else:
				_formation_if(b, rules, nation, uid, "assault_column" if nd > float(ai["column_distance"]) else "skirmish_line")
				TacticalOrders.move(b, rules, nation, [uid], target_pos + _spread(uid) * 70.0)


static func _formation_if(b: Dictionary, rules: Dictionary, nation: String, uid: String, f: String) -> void:
	if bool(b["units"][uid].get("lock_formation", false)):
		return
	if b["units"][uid]["formation"] != f:
		TacticalOrders.set_formation(b, rules, nation, [uid], f)


static func _nearest_fort_site(b: Dictionary, side: String, pos: Vector2) -> Vector2:
	var best := Vector2.INF
	var bd := 350.0
	for t: Dictionary in b["defenses"]["trenches"]:
		if int(t["level"]) > 0 and TacticalSim.side_of_nation(b, t["owner"]) == side:
			var p := Geometry2D.get_closest_point_to_segment(pos, CombatData.v(t["a"]), CombatData.v(t["b"]))
			var d := pos.distance_to(p)
			if d < bd:
				bd = d
				best = p
	return best


## Décalage déterministe propre à chaque unité (évite l'empilement).
static func _spread(uid: String) -> Vector2:
	var h := uid.hash()
	return Vector2(float(h % 200 - 100) / 100.0, float((h / 200) % 200 - 100) / 100.0).normalized()


static func _known_enemies(b: Dictionary, side: String) -> Array:
	var out: Array = []
	var fog_cfg: Dictionary = b.get("fog_cfg", {})
	var mem: Dictionary = b["fog"][side]
	var ids := mem.keys()
	ids.sort()
	for eid: String in ids:
		var m: Dictionary = mem[eid]
		out.append({"id": eid, "pos": m["pos"], "type": m.get("type", "infantry"), "estimate": m["estimate"], "routing": m["routing"],
			"disorganized": bool(m.get("disorganized", false)), "fresh": TacticalSim.is_visible_to(b, side, eid)})
	return out


static func _side_trench_length(b: Dictionary, side: String) -> float:
	var total := 0.0
	for t: Dictionary in b["defenses"]["trenches"]:
		if TacticalSim.side_of_nation(b, t["owner"]) == side:
			total += CombatData.v(t["a"]).distance_to(CombatData.v(t["b"]))
	return total


static func _set_objective(b: Dictionary, side: String, nation: String) -> void:
	var best := ""
	var best_score := -INF
	var att_entry := CombatData.v(b["sides"][CombatData.ATTACKERS]["entry"])
	var ref := BattleManager._defended_anchor(b, att_entry)
	# Attaque limitée et reconnaissance : objectif circonscrit (le plus proche de l'axe d'attaque), sans égard à son poids.
	var nearest := Engagement.active(b) and Engagement.cfg_objective(b) == "nearest"
	for o: Dictionary in b["objectives"]:
		var held_by_us: bool = o["controller"] == side
		if side == CombatData.ATTACKERS and held_by_us:
			continue
		var score := (0.0 if nearest else float(o["weight"]) * 1000.0) - CombatData.v(o["pos"]).distance_to(ref)
		if score > best_score:
			best_score = score
			best = o["id"]
	if best == "":
		best = b["objectives"][0]["id"]
	if b["sides"][side]["commander"]["nation"] == nation:
		TacticalOrders.set_primary_objective(b, nation, best)
	else:
		b["sides"][side]["primary_objective"] = best  # pas de commandant désigné : objectif par défaut


static func _objective_pos(b: Dictionary, side: String) -> Vector2:
	for o: Dictionary in b["objectives"]:
		if o["id"] == b["sides"][side]["primary_objective"]:
			return CombatData.v(o["pos"])
	return Vector2(float(b["field"]["w"]), float(b["field"]["h"])) / 2.0


static func _reinforce(b: Dictionary, rules: Dictionary, nation: String, side: String, known: Array) -> void:
	if Engagement.active(b):
		var e: Dictionary = b["engagement"]
		if (side == CombatData.ATTACKERS and e["approach"] == "reconnaissance") \
				or (side == CombatData.DEFENDERS and e["posture"] == "delay"):
			return
	var own := 0
	for uid: String in b["units"]:
		var u: Dictionary = b["units"][uid]
		if u["side"] == side and (u["status"] == CombatData.ACTIVE or u["status"] == CombatData.RESERVE or u["status"] == CombatData.ARRIVING):
			own += int(u["soldiers"])
	var enemy := 0
	if not (own >= 60000 and own < 100000):
		for e: Dictionary in known:
			enemy += int(e["estimate"])
	var ratio := float(rules["ai"]["reinforce_when_ratio_below"])
	if enemy == 0 and own >= 100000:
		return
	if enemy > 0 and float(own) >= float(enemy) * ratio:
		return
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if u["nation"] == nation and u["status"] == CombatData.AVAILABLE:
			if TacticalOrders.call_reinforcement(b, rules, nation, uid) == "":
				own += int(u["soldiers"])
				if enemy > 0 and float(own) >= float(enemy) * ratio:
					return


## Posture défensive par défaut d'une armée IA (T-055, PROPOSÉ) : tenir à tout prix dans la région
## de sa capitale, tenir ailleurs. L'IA n'a pas d'information secrète sur l'attaquant.
static func default_posture(state: GameState, army: String) -> String:
	var f: Dictionary = state.formations[army]
	if state.nations[f["nation"]]["capital_region_id"] == f["region"]:
		return "hold_at_all_costs"
	return "hold"
