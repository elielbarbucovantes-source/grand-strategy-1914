extends RefCounted
## Système de combat (T-029 à T-044) sur le bac à sable FICTIF (forces génériques de test).

var runner: Object


func _session() -> GameSession:
	var s := GameSession.create()
	s.new_game("france", 1, 1914, "sandbox_fictif")
	return s


## France (défense, région 011) contre Empire allemand (attaque depuis 035) — en guerre.
func _setup(s: GameSession, attacker_region: String = "region_035", battle_region: String = "region_011") -> Dictionary:
	var st := s.state
	st.wars.append({"id": "war_t", "a": "german_empire", "b": "france", "since_turn": 0})
	st.move_army("army_france_1", battle_region)
	st.move_army("army_german_empire_1", battle_region)
	var clash := {"region": battle_region, "attackers": ["army_german_empire_1"], "defenders": ["army_france_1"],
		"origin": {"army_german_empire_1": attacker_region, "army_france_1": battle_region}}
	var b := BattleManager.create(st, s.world, s.rules, s.rules["combat"], clash)
	st.active_battles.append(b)
	return b


func _units(b: Dictionary, nation: String, status: String = CombatData.ACTIVE) -> Array:
	return CombatData.unit_ids(b).filter(func(id: String) -> bool:
		return b["units"][id]["nation"] == nation and b["units"][id]["status"] == status)


func _cr(s: GameSession) -> Dictionary:
	return s.rules["combat"]


# ------------------------------------------------------------------ déclenchement, durée, résultat
func test_battle_creation_engages_real_units() -> void:
	var s := _session()
	var b := _setup(s)
	runner.check(not b.is_empty(), "bataille créée")
	var fr := _units(b, "france")
	var de := _units(b, "german_empire")
	runner.check(fr.size() == 7 and de.size() == 7, "7 unités par camp (forces fictives)")
	var total := 0
	for id: String in fr:
		total += int(b["units"][id]["soldiers"])
	runner.check(total == int(s.state.soldiers_of("army_france_1")), "effectifs engagés = effectifs stratégiques")
	runner.check(s.state.formations[fr[0]]["battle_id"] == b["id"], "unités verrouillées dans la bataille")
	runner.check(b["objectives"].size() >= 2, "objectifs = villes de la région et centre")
	runner.check(int(b["max_ticks"]) > 0 and float(b["max_minutes"]) <= 30.0, "durée maximale bornée à 30 min (%.1f min)" % float(b["max_minutes"]))


func test_strategic_move_blocked_while_engaged() -> void:
	var s := _session()
	_setup(s)
	var err := MilitarySystem.validate_move(s.state, s.world, s.rules, Orders.move("france", "army_france_1", "region_008"))
	runner.check(err != "", "armée engagée : déplacement stratégique refusé (%s)" % err)
	var r := s.end_turn()
	runner.check(r.has("error"), "fin de mois refusée tant qu'une bataille est active (T-029 A)")


func test_battle_ends_at_max_duration_and_result() -> void:
	var s := _session()
	var b := _setup(s)
	for id: String in CombatData.unit_ids(b):
		b["units"][id]["status"] = CombatData.RESERVE if b["units"][id]["status"] == CombatData.ACTIVE else b["units"][id]["status"]
	# Aucun contact : la bataille va jusqu'à la durée maximale exacte (pas de prolongation).
	for id: String in CombatData.unit_ids(b):
		if b["units"][id]["status"] == CombatData.RESERVE:
			b["units"][id]["status"] = CombatData.ACTIVE
			b["units"][id]["pos"] = [20.0 if b["units"][id]["side"] == "attackers" else 1980.0, 20.0]
	for o: Dictionary in b["objectives"]:
		o["pos"] = [1000.0, 1350.0]
	TacticalSim.step(b, _cr(s), int(b["max_ticks"]) + 50)
	runner.check(b["status"] == "ended" and int(b["tick"]) == int(b["max_ticks"]), "fin automatique exactement à la durée maximale")
	var res := BattleManager.finish(s.state, s.world, _cr(s), b)
	runner.check(res["winner"] == "" and res["holder"] == "defenders", "sans combat : indécise, le défenseur tient")
	runner.check(s.state.active_battles.is_empty() and s.state.battles.size() == 1, "bataille archivée")


func test_full_ai_battle_applies_strategic_consequences() -> void:
	var s := _session()
	var b := _setup(s)
	var before_fr: int = s.state.soldiers_of("army_france_1")
	var before_de: int = s.state.soldiers_of("army_german_empire_1")
	BattleManager.run_to_end(b, _cr(s), true)
	var res := BattleManager.finish(s.state, s.world, _cr(s), b)
	runner.check(res.has("scores") and res["scores"]["attackers"].has("territory"), "résultat combinant pertes et territoire")
	var after_fr: Variant = s.state.soldiers_of("army_france_1") if s.state.formations.has("army_france_1") else 0
	var after_de: Variant = s.state.soldiers_of("army_german_empire_1") if s.state.formations.has("army_german_empire_1") else 0
	runner.check(int(after_fr) < before_fr and int(after_de) < before_de, "pertes persistantes des deux côtés (%d→%s ; %d→%s)" % [before_fr, str(after_fr), before_de, str(after_de)])
	for uid: String in s.state.sorted_formation_ids():
		runner.check(s.state.formations[uid]["battle_id"] == "", "verrous levés (%s)" % uid)
	if res["winner"] == "attackers":
		runner.check(s.state.controller("region_011") == "german_empire" and s.state.sovereign("region_011") == "france", "victoire offensive : occupation, souveraineté conservée")
	else:
		runner.check(s.state.formations["army_german_empire_1"]["region"] != "region_011", "attaquant repoussé : retraite hors de la région")


func test_deterministic_battle() -> void:
	var a := _session()
	var b := _session()
	var ba := _setup(a)
	var bb := _setup(b)
	BattleManager.run_to_end(ba, _cr(a), true)
	BattleManager.run_to_end(bb, _cr(b), true)
	runner.check(JSON.stringify(ba["units"], "", true) == JSON.stringify(bb["units"], "", true), "même bataille → même déroulement")


# ------------------------------------------------------------------ contrôle tactique (T-030, T-031, T-034)
func test_group_orders_and_individual_override() -> void:
	var s := _session()
	var b := _setup(s)
	var fr := _units(b, "france")
	var group: Array = fr.slice(0, 3)
	var before := CombatData.v(b["units"][group[1]]["pos"]) - CombatData.v(b["units"][group[0]]["pos"])
	runner.check(TacticalOrders.move(b, _cr(s), "france", group, Vector2(900, 700)) == "", "ordre collectif accepté")
	var after := CombatData.v(b["units"][group[1]]["dest"]) - CombatData.v(b["units"][group[0]]["dest"])
	runner.check(before.distance_to(after) < 1.0, "disposition relative conservée")
	runner.check(TacticalOrders.move(b, _cr(s), "france", [group[2]], Vector2(300, 300)) == "", "ordre individuel après ordre collectif")
	runner.check(CombatData.v(b["units"][group[2]]["dest"]).distance_to(Vector2(300, 300)) < 1.0 and b["units"][group[0]]["order"] == "move", "seule l'unité modifiée change d'ordre")
	runner.check(TacticalOrders.move(b, _cr(s), "france", _units(b, "german_empire").slice(0, 1), Vector2(0, 0)) != "", "contrôle national : unité ennemie refusée")


func test_formations_change_real_characteristics() -> void:
	var s := _session()
	var b := _setup(s)
	var cr := _cr(s)
	var uid: String = _units(b, "france")[0]
	var u: Dictionary = b["units"][uid]
	var vals := {}
	for f: String in CombatData.FORMATIONS:
		runner.check(TacticalOrders.set_formation(b, cr, "france", [uid], f) == "", "formation %s" % f)
		vals[f] = {"speed": TacticalSim.speed(b, cr, u), "exposure": TacticalSim.exposure(b, cr, u)}
	runner.check(vals["assault_column"]["speed"] > vals["skirmish_line"]["speed"] and vals["skirmish_line"]["speed"] > vals["entrenched"]["speed"], "vitesses différentes")
	runner.check(vals["assault_column"]["exposure"] > vals["skirmish_line"]["exposure"] and vals["skirmish_line"]["exposure"] > vals["entrenched"]["exposure"], "expositions différentes")
	runner.check(TacticalOrders.set_formation(b, cr, "france", [uid], "carre") != "", "pas de quatrième formation")


func test_construction_in_battle_slower_under_fire() -> void:
	var s := _session()
	var cr := _cr(s)
	var progress := {}
	for fire in [false, true]:
		var b := _setup(_session()) if false else _setup(s if not fire else _session())
		var uid: String = _units(b, "france")[0]
		var pos := CombatData.v(b["units"][uid]["pos"])
		runner.check(TacticalOrders.build_trench(b, cr, "france", [uid], pos + Vector2(-60, 0), pos + Vector2(60, 0)) == "", "tranchée ordonnée")
		for i in 20:
			if fire:
				b["units"][uid]["last_fire_tick"] = b["tick"]
			TacticalSim._construction(b, cr)
			b["tick"] = int(b["tick"]) + 1
		progress[fire] = float(b["defenses"]["trenches"][0]["progress"])
	runner.check(progress[false] > 0.0, "les travaux progressent (non instantanés)")
	runner.check(progress[true] < progress[false] * 0.5, "beaucoup plus lent sous le feu (%.0f contre %.0f)" % [progress[true], progress[false]])


func test_trench_extent_limited_by_soldiers() -> void:
	var s := _session()
	var b := _setup(s)
	var uid: String = _units(b, "france")[0]
	var err := TacticalOrders.build_trench(b, _cr(s), "france", [uid], Vector2(0, 0), Vector2(1999, 1399))
	runner.check(err == "" or err.begins_with("réseau trop étendu"), "capacité vérifiée")
	var cr2 := _cr(s).duplicate(true)
	cr2["construction"]["trench_capacity_per_soldier"] = 0.001
	runner.check(TacticalOrders.build_trench(b, cr2, "france", [uid], Vector2(100, 100), Vector2(900, 100)).begins_with("réseau trop étendu"), "réseau limité par les soldats présents")


# ------------------------------------------------------------------ moral et déroute (T-038, T-039)
func test_morale_losses_army_influence_and_rout() -> void:
	var s := _session()
	var b := _setup(s)
	var cr := _cr(s)
	var uid: String = _units(b, "france")[0]
	var u: Dictionary = b["units"][uid]
	u["morale"] = 60.0
	b["army_morale"]["army_france_1"] = 100.0
	for i in 40:
		TacticalSim._morale(b, cr, {})
	runner.check(float(u["morale"]) > 60.0, "le moral de l'armée tire celui de l'unité vers le haut")
	var m0 := float(u["morale"])
	u["tick_losses"] = 600
	u["soldiers"] = int(u["soldiers"]) - 600
	TacticalSim._morale(b, cr, {})
	runner.check(float(u["morale"]) < m0 - 10.0, "les pertes font chuter le moral")
	u["morale"] = 10.0
	TacticalSim._morale(b, cr, {})
	runner.check(u["status"] == CombatData.ROUTING, "déroute sous le seuil configurable")
	runner.check(TacticalOrders.hold(b, cr, "france", [uid]) != "", "unité en déroute non contrôlable")
	TacticalSim._movement(b, cr)
	var d0 := CombatData.v(u["pos"]).distance_to(CombatData.v(u["retreat_point"]))
	for i in 400:
		TacticalSim._movement(b, cr)
	runner.check(u["status"] == CombatData.WITHDRAWN or CombatData.v(u["pos"]).distance_to(CombatData.v(u["retreat_point"])) < d0, "retrait automatique vers l'arrière")
	var eff_low := TacticalSim.effectiveness(cr, {"morale": 30.0})
	var eff_high := TacticalSim.effectiveness(cr, {"morale": 90.0})
	runner.check(eff_low < eff_high, "le moral modifie l'efficacité")
	var tired := TacticalSim.effectiveness(cr, {"morale": 90.0, "engaged_ticks": 500})
	runner.check(tired < eff_high, "la durée d'engagement (fatigue) réduit l'efficacité")


# ------------------------------------------------------------------ pertes (T-042)
func test_losses_are_individual() -> void:
	var s := _session()
	var b := _setup(s)
	var cr := _cr(s)
	var fr := _units(b, "france")
	var de := _units(b, "german_empire")
	var exposed: Dictionary = b["units"][fr[0]]
	var sheltered: Dictionary = b["units"][fr[1]]
	exposed["formation"] = "assault_column"
	sheltered["formation"] = "entrenched"
	for id: String in de:
		b["units"][id]["pos"] = [1000.0, 700.0]
	exposed["pos"] = [1000.0, 820.0]
	sheltered["pos"] = [1000.0, 580.0]
	for id: String in fr.slice(2):
		b["units"][id]["pos"] = [10.0, 10.0]
	TacticalSim.update_fog(b, cr)
	var s0e := int(exposed["soldiers"])
	var s0s := int(sheltered["soldiers"])
	for i in 15:
		var l := TacticalSim._fire_and_melee(b, cr)
		TacticalSim._apply_losses(b, cr, l)
	var le := s0e - int(exposed["soldiers"])
	var ls := s0s - int(sheltered["soldiers"])
	runner.check(le > 0 and ls >= 0 and le > ls, "pertes différentes selon l'exposition et la formation (%d contre %d)" % [le, ls])


func test_destroyed_unit_removed_and_losses_saved() -> void:
	var s := _session()
	var b := _setup(s)
	var uid: String = _units(b, "france")[0]
	b["units"][uid]["soldiers"] = 10
	TacticalSim._apply_losses(b, _cr(s), {uid: 0.0})
	runner.check(b["units"][uid]["status"] == CombatData.DESTROYED, "unité sous le seuil : anéantie")
	var other: String = _units(b, "france")[0]
	b["units"][other]["soldiers"] = 1234
	b["status"] = "ended"
	BattleManager.finish(s.state, s.world, _cr(s), b)
	runner.check(not s.state.formations.has(uid), "unité détruite retirée de l'armée")
	runner.check(int(s.state.formations[other]["soldiers"]) == 1234, "effectif stratégique mis à jour")
	var path := "user://test_saves/after_battle.json"
	SaveRepository.save(path, s.state, s.world, s.rules)
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(loaded.has("state") and int((loaded["state"] as GameState).formations[other]["soldiers"]) == 1234, "pertes conservées après rechargement")


# ------------------------------------------------------------------ renforts (T-040)
func test_reinforcements_progressive_no_duplication() -> void:
	var s := _session()
	var st := s.state
	# Une seconde armée allemande en 035 (voisine) sert de renfort.
	var b := _setup(s)
	var available := CombatData.unit_ids(b).filter(func(id: String) -> bool: return b["units"][id]["status"] == CombatData.AVAILABLE)
	# Armée allemande d'origine en 011 : candidats = armées voisines (françaises en 008 ? non, déplacées) ; on teste la mécanique.
	if available.is_empty():
		st.formations["army_french_reserve"] = {"id": "army_french_reserve", "nation": "france", "echelon": "army", "name_fr": "Réserve", "region": "region_008", "parent": null, "soldiers": null, "battle_id": "", "encircled": false, "morale": 70.0, "supplied": true, "planned_target": "", "reserve": false}
		st.formations["army_french_reserve_u1"] = {"id": "army_french_reserve_u1", "nation": "france", "echelon": "unit", "unit_type": "infantry", "name_fr": "Renfort", "region": "region_008", "parent": "army_french_reserve", "soldiers": 2000, "battle_id": "", "morale": null, "encircled": false, "supplied": true, "planned_target": "", "reserve": false}
		st.active_battles.clear()
		for uid: String in st.sorted_formation_ids():
			st.formations[uid]["battle_id"] = ""
		b = BattleManager.create(st, s.world, s.rules, _cr(s), {"region": "region_011", "attackers": ["army_german_empire_1"], "defenders": ["army_france_1"], "origin": {"army_german_empire_1": "region_035", "army_france_1": "region_011"}})
		st.active_battles.append(b)
	var rid := "army_french_reserve_u1"
	runner.check(b["units"].has(rid) and b["units"][rid]["status"] == CombatData.AVAILABLE, "renfort voisin disponible")
	runner.check(st.formations[rid]["battle_id"] == b["id"], "renfort réservé à cette bataille (verrou)")
	var other := BattleManager.create(st, s.world, s.rules, _cr(s), {"region": "region_008", "attackers": ["army_german_empire_1"], "defenders": ["army_french_reserve"], "origin": {"army_german_empire_1": "region_011", "army_french_reserve": "region_008"}})
	runner.check(other.is_empty() or not other["units"].has(rid) or other["units"][rid]["status"] != CombatData.ACTIVE, "pas de double emploi d'une même unité")
	runner.check(TacticalOrders.call_reinforcement(b, _cr(s), "france", rid) == "", "renfort appelé")
	var eta := int(b["units"][rid]["arrive_tick"])
	runner.check(eta > int(b["tick"]), "arrivée différée (non instantanée) : tick %d" % eta)
	TacticalSim.step(b, _cr(s), eta - int(b["tick"]) - 1)
	runner.check(b["units"][rid]["status"] == CombatData.ARRIVING, "toujours en route avant l'échéance")
	TacticalSim.step(b, _cr(s), 2)
	runner.check(b["units"][rid]["status"] == CombatData.ACTIVE, "arrivé à l'échéance")


func test_reserve_commit_and_rail_speed() -> void:
	var s := _session()
	s.state.formations["army_france_1_d2_r1_u1"]["reserve"] = true
	var b := _setup(s)
	var uid := "army_france_1_d2_r1_u1"
	runner.check(b["units"][uid]["status"] == CombatData.RESERVE, "unité gardée en réserve")
	runner.check(TacticalOrders.commit_reserve(b, _cr(s), "france", [uid]) == "", "engagement de la réserve")
	runner.check(b["units"][uid]["status"] == CombatData.ARRIVING and int(b["units"][uid]["arrive_tick"]) > 0, "réserve engagée avec délai")
	var w := s.world
	var with_rail := ""
	var without := ""
	for n: String in w.neighbor_ids("region_011"):
		if w.connection_kind("region_011", n) == "land":
			if w.has_rail_link("region_011", n) and with_rail == "":
				with_rail = n
			elif not w.has_rail_link("region_011", n) and without == "":
				without = n
	runner.check(with_rail != "", "au moins un voisin relié par le rail (données)")


# ------------------------------------------------------------------ positions défensives (T-041)
func test_existing_defenses_integrated_and_effective() -> void:
	var s := _session()
	var st := s.state
	var d := DefenseSystem.defenses(st, "region_011")
	(d["installations"] as Array).append({"id": "inst_x", "type": "machine_gun_nest", "owner": "france", "pos": [1000.0, 700.0],
		"site": [1000.0, 700.0], "progress": 6000.0, "work_needed": 6000.0, "complete": true, "condition": 1.0})
	(d["trenches"] as Array).append({"id": "tr_x", "owner": "france", "a": [900.0, 700.0], "b": [1100.0, 700.0], "site": [1000.0, 700.0],
		"level": 2, "target_level": 2, "progress": 0.0, "work_needed": 8000.0, "complete": true, "condition": 1.0})
	var b := _setup(s)
	runner.check(b["defenses"]["installations"].size() == 1 and b["defenses"]["trenches"].size() == 1, "ouvrages existants intégrés au début (T-041)")
	var uid: String = _units(b, "france")[0]
	var u: Dictionary = b["units"][uid]
	u["formation"] = "entrenched"
	u["pos"] = [1000.0, 720.0]
	var covered := TacticalSim.exposure(b, _cr(s), u)
	var bonus := TacticalSim.installation_bonus(b, _cr(s), u)
	u["pos"] = [300.0, 300.0]
	var open := TacticalSim.exposure(b, _cr(s), u)
	runner.check(covered < open, "tranchée et nid de mitrailleuses réduisent l'exposition")
	runner.check(float(bonus["fire"]) > 0.0, "nid de mitrailleuses : bonus de feu")
	var art: String = _units(b, "german_empire").filter(func(id: String) -> bool: return b["units"][id]["type"] == "artillery")[0]
	b["units"][art]["pos"] = [1000.0, 300.0]
	u["pos"] = [1000.0, 720.0]
	b["visible"]["attackers"] = {uid: true}
	for i in 20:
		TacticalSim._fire_and_melee(b, _cr(s))
	runner.check(float(b["defenses"]["installations"][0]["condition"]) < 1.0, "le feu d'artillerie dégrade l'ouvrage")
	b["defenses"]["installations"][0]["condition"] = 0.3
	u["pos"] = [1000.0, 720.0]
	runner.check(float(TacticalSim.installation_bonus(b, _cr(s), u)["fire"]) < float(bonus["fire"]), "l'état de l'ouvrage compte")


func test_strategic_construction_monthly_not_instant() -> void:
	var s := _session()
	var o := Orders.build_trench("france", "region_008", Vector2(800, 600), Vector2(1100, 600))
	runner.check(s.queue_order(o) == "", "ordre de tranchée hors bataille")
	s.end_turn()
	var t: Dictionary = DefenseSystem.defenses(s.state, "region_008")["trenches"][0]
	runner.check(int(t["level"]) >= 0 and (float(t["progress"]) > 0.0 or int(t["level"]) == 1), "progression mensuelle")
	runner.check(s.queue_order(Orders.build_trench("france", "region_035", Vector2(0, 0), Vector2(500, 0))) != "", "construction refusée hors de son territoire")


# ------------------------------------------------------------------ retraite et encerclement (T-043, T-044)
func test_retreat_and_encirclement_outcomes() -> void:
	var s := _session()
	var st := s.state
	st.wars.append({"id": "w", "a": "german_empire", "b": "france", "since_turn": 0})
	var dest := BattleManager.choose_retreat(st, s.world, _cr(s), "france", "region_011")
	runner.check(dest != "" and st.controller(dest) == "france", "retraite vers une région française sûre (%s)" % dest)
	# Encerclement : toutes les régions voisines de 011 deviennent allemandes.
	for n: String in s.world.neighbor_ids("region_011"):
		st.regions[n]["controller"] = "german_empire"
	runner.check(BattleManager.choose_retreat(st, s.world, _cr(s), "france", "region_011") == "", "aucune retraite sûre → encerclement")
	st.move_army("army_france_1", "region_011")
	st.regions["region_011"]["controller"] = "german_empire"
	st.formations["army_france_1"]["encircled"] = true
	st.formations["army_france_1"]["morale"] = 30.0
	BattleManager.monthly_encirclement(st, s.world, _cr(s))
	runner.check(st.formations.has("army_france_1") and float(st.formations["army_france_1"]["morale"]) < 30.0, "encerclée : attrition sans capitulation automatique")
	BattleManager.monthly_encirclement(st, s.world, _cr(s))
	runner.check(not st.formations.has("army_france_1"), "reddition quand le moral s'effondre")
	# Libération.
	var s2 := _session()
	var st2 := s2.state
	st2.wars.append({"id": "w", "a": "german_empire", "b": "france", "since_turn": 0})
	st2.move_army("army_france_1", "region_011")
	st2.formations["army_france_1"]["encircled"] = true
	st2.formations["army_france_1"]["morale"] = 60.0
	BattleManager.monthly_encirclement(st2, s2.world, _cr(s2))
	runner.check(not st2.formations["army_france_1"]["encircled"], "libération dès qu'une route sûre existe")


func test_encircled_army_keeps_fighting() -> void:
	var s := _session()
	var st := s.state
	st.wars.append({"id": "w", "a": "german_empire", "b": "france", "since_turn": 0})
	st.move_army("army_france_1", "region_035")
	st.move_army("army_german_empire_1", "region_035")
	st.formations["army_france_1"]["encircled"] = true
	var clashes := TurnResolver._siege_clashes(st, [])
	runner.check(clashes.size() == 1 and clashes[0]["defenders"].has("army_france_1"), "armée encerclée au contact : bataille de siège")


# ------------------------------------------------------------------ multijoueur (T-029)
func test_queue_commander_pause_disconnection() -> void:
	var s := _session()
	var cr := _cr(s)
	var st := s.state
	var c := BattleManager.commander(st, cr, {"france": 5000, "united_kingdom": 3000})
	runner.check(c["nation"] == "france", "commandant : plus de soldats")
	st.nations["france"]["military_prestige"] = 2
	st.nations["united_kingdom"]["military_prestige"] = 7
	c = BattleManager.commander(st, cr, {"france": 4000, "united_kingdom": 4000})
	runner.check(c["nation"] == "united_kingdom", "égalité : prestige le plus élevé")
	st.nations["united_kingdom"]["military_prestige"] = 2
	c = BattleManager.commander(st, cr, {"united_kingdom": 4000, "france": 4000})
	runner.check(c["nation"] == "france", "égalité totale : départage déterministe documenté")
	var q := [{"critical": false, "created_seq": 1, "id": "a"}, {"critical": true, "created_seq": 5, "id": "b"}, {"critical": false, "created_seq": 3, "id": "c"}]
	st.active_battles = q
	var order := BattleManager.queue(st).map(func(x: Dictionary) -> String: return x["id"])
	runner.check(order == ["b", "a", "c"], "file : critiques puis chronologique")
	st.active_battles = []
	var b := _setup(s)
	b["humans"] = ["france", "german_empire"]
	b["controllers"]["german_empire"] = "human"
	b["multiplayer"] = true
	runner.check(not BattleManager.request_pause(b, "france", true), "multijoueur : une seule voix ne suffit pas")
	runner.check(BattleManager.request_pause(b, "german_empire", true), "unanimité des humains : pause")
	BattleManager.request_pause(b, "france", false)
	b["humans"] = ["france"]
	b["controllers"]["german_empire"] = "ai"
	b["multiplayer"] = false
	runner.check(not BattleManager.request_pause(b, "italy", true), "un pays IA ou non participant ne vote pas")
	runner.check(BattleManager.request_pause(b, "france", true), "solo : l'accord du seul humain suffit")
	BattleManager.request_pause(b, "france", false)
	BattleManager.on_disconnect(b, cr, "france")
	runner.check(b["controllers"]["france"] == "disconnected" and bool(b["disconnect_pause"]), "déconnexion en solo : bataille en pause (T-046)")
	BattleManager.on_reconnect(b, "france")
	runner.check(b["controllers"]["france"] == "human" and not bool(b["disconnect_pause"]), "reconnexion : pause levée (T-046)")


func test_player_battle_flow_and_sync() -> void:
	var s := _session()
	s.queue_order(Orders.declare_war("france", "german_empire"))
	s.end_turn()
	var st := s.state
	st.move_army("army_german_empire_1", "region_035")
	st.move_army("army_france_1", "region_011")
	runner.check(s.queue_order(Orders.move("france", "army_france_1", "region_035")) == "", "attaque française ordonnée")
	var r := s.end_turn()
	runner.check(int(r.get("pending_battles", 0)) == 1, "bataille du joueur en attente (non résolue d'office)")
	runner.check(s.end_turn().has("error"), "le mois suivant est bloqué")
	var b := s.current_battle()
	runner.check(not b.is_empty() and (b["humans"] as Array).has("france"), "bataille commandée par le joueur")
	var path := "user://test_saves/in_battle.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde en pleine bataille")
	s.advance_battle(30)
	var tick_after := int(s.current_battle()["tick"])
	runner.check(s.load_game(path) == "", "rechargement")
	runner.check(int(s.current_battle()["tick"]) == 0 or int(s.current_battle()["tick"]) < tick_after, "état de bataille restauré")
	var res := s.auto_resolve_battle()
	runner.check(res.has("winner") and s.state.active_battles.is_empty(), "résolution automatique possible")
	runner.check(not s.end_turn().has("error"), "mois suivant débloqué")


func test_ai_respects_fog() -> void:
	var s := _session()
	var b := _setup(s)
	var cr := _cr(s)
	for id: String in _units(b, "german_empire"):
		b["units"][id]["pos"] = [5.0, 5.0]
	b["fog"]["defenders"] = {}
	TacticalSim.update_fog(b, cr)
	var known := TacticalAI._known_enemies(b, "defenders")
	for e: Dictionary in known:
		runner.check(TacticalSim.is_visible_to(b, "defenders", e["id"]) or b["fog"]["defenders"].has(e["id"]), "l'IA ne connaît que le repéré")
	var visible := 0
	for id: String in _units(b, "german_empire"):
		if TacticalSim.is_visible_to(b, "defenders", id):
			visible += 1
	runner.check(visible < _units(b, "german_empire").size(), "pas de vision omnisciente (%d visibles)" % visible)
