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
	if front_n == 0 or avg < float(ai["reserve_commit_frontline_morale"]) or enemy_near_objective:
		var reserves: Array = []
		for uid: String in CombatData.unit_ids(b):
			if b["units"][uid]["nation"] == nation and b["units"][uid]["status"] == CombatData.RESERVE:
				reserves.append(uid)
		if not reserves.is_empty():
			TacticalOrders.commit_reserve(b, rules, nation, reserves)
	if int(b["tick"]) == 0:
		_reinforce(b, rules, nation, side, known)
	# Ordres unité par unité.
	for uid: String in mine:
		var u: Dictionary = b["units"][uid]
		var pos := CombatData.v(u["pos"])
		if float(u["morale"]) < float(ai["withdraw_morale"]):
			TacticalOrders.set_formation(b, rules, nation, [uid], "skirmish_line")
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
		if float(u["morale"]) >= float(ai["charge_min_morale"]) and u["type"] != "artillery":
			for e: Dictionary in known:
				if not e["fresh"] or pos.distance_to(CombatData.v(e["pos"])) > float(ai["charge_range"]):
					continue
				if e["routing"] or int(e["estimate"]) < int(u["soldiers"]) * 0.6:
					weak_target = e
					break
		if not weak_target.is_empty():
			TacticalOrders.set_formation(b, rules, nation, [uid], "assault_column")
			TacticalOrders.charge(b, rules, nation, [uid], weak_target["id"])
			continue
		var range_u := float(rules["unit_types"][u["type"]]["range"])
		if side == CombatData.DEFENDERS:
			var anchor := objective + _spread(uid) * 90.0
			if nd <= range_u:
				_formation_if(b, rules, nation, uid, "entrenched")
				TacticalOrders.hold(b, rules, nation, [uid])
			elif pos.distance_to(anchor) > 60.0:
				_formation_if(b, rules, nation, uid, "assault_column" if pos.distance_to(anchor) > float(ai["column_distance"]) else "skirmish_line")
				TacticalOrders.move(b, rules, nation, [uid], anchor)
			elif known.is_empty() and u["type"] == "infantry" and _side_trench_length(b, side) < 1.0 and int(b["tick"]) < int(b["max_ticks"]) / 3:
				var facing := (CombatData.v(b["sides"][CombatData.ATTACKERS]["entry"]) - objective).normalized()
				var center := objective + facing * 120.0
				var perp := facing.orthogonal() * 110.0
				TacticalOrders.build_trench(b, rules, nation, [uid], center - perp, center + perp)
			else:
				_formation_if(b, rules, nation, uid, "entrenched")
				TacticalOrders.hold(b, rules, nation, [uid])
		else:
			if u["type"] == "artillery":
				var stand := objective.lerp(CombatData.v(u["retreat_point"]), 0.55)
				if nd <= range_u:
					_formation_if(b, rules, nation, uid, "skirmish_line")
					TacticalOrders.hold(b, rules, nation, [uid])
				elif pos.distance_to(stand) > 60.0:
					TacticalOrders.move(b, rules, nation, [uid], stand)
				continue
			if nd <= range_u * 0.9:
				_formation_if(b, rules, nation, uid, "skirmish_line")
				TacticalOrders.move(b, rules, nation, [uid], pos.move_toward(objective, 60.0))
			else:
				_formation_if(b, rules, nation, uid, "assault_column" if nd > float(ai["column_distance"]) else "skirmish_line")
				TacticalOrders.move(b, rules, nation, [uid], objective + _spread(uid) * 70.0)


static func _formation_if(b: Dictionary, rules: Dictionary, nation: String, uid: String, f: String) -> void:
	if b["units"][uid]["formation"] != f:
		TacticalOrders.set_formation(b, rules, nation, [uid], f)


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
		out.append({"id": eid, "pos": m["pos"], "estimate": m["estimate"], "routing": m["routing"],
			"fresh": TacticalSim.is_visible_to(b, side, eid)})
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
	var center := CombatData.v(b["sides"][side]["entry"])
	for o: Dictionary in b["objectives"]:
		var held_by_us: bool = o["controller"] == side
		if side == CombatData.ATTACKERS and held_by_us:
			continue
		var score := float(o["weight"]) * 1000.0 - CombatData.v(o["pos"]).distance_to(center)
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
	var own := 0
	for uid: String in b["units"]:
		var u: Dictionary = b["units"][uid]
		if u["side"] == side and (u["status"] == CombatData.ACTIVE or u["status"] == CombatData.RESERVE):
			own += int(u["soldiers"])
	var enemy := 0
	for e: Dictionary in known:
		enemy += int(e["estimate"])
	# Sans renseignement, l'IA défend prudemment sa région en appelant ses renforts.
	if enemy > 0 and float(own) >= float(enemy) * float(rules["ai"]["reinforce_when_ratio_below"]):
		return
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if u["nation"] == nation and u["status"] == CombatData.AVAILABLE:
			TacticalOrders.call_reinforcement(b, rules, nation, uid)
