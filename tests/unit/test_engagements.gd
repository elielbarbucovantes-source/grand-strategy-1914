extends RefCounted
## MIL-01 phase 6, étape 2 : types d'engagement (T-048, T-055), largeur du front, réserves et
## rotations, blessés légers à efficacité réduite. Les tests vérifient des RÈGLES et des
## conséquences observables, pas des volumes de pertes (calibration : étape 3).

var runner: Object

const A_NATION := "german_empire"
const A_ARMY := "army_german_empire_region_035"
const D_NATION := "france"
const D_ARMY := "army_france_region_011"
const TARGET := "region_011"


func _session() -> GameSession:
	var s := GameSession.create()
	s.new_game("united_kingdom", 1, 1914)
	s.state.wars.append({"id": "w", "a": A_NATION, "b": D_NATION, "since_turn": 0})
	return s


## Bataille de Lorraine créée (non jouée) avec l'approche et la posture données.
func _create(s: GameSession, approach: String, posture: String) -> Dictionary:
	s.state.formations[D_ARMY]["defensive_posture"] = posture
	var clashes := MilitarySystem.resolve_moves(s.state, s.world, s.rules, [Orders.move(A_NATION, A_ARMY, TARGET, approach)])
	var b := BattleManager.create(s.state, s.world, s.rules, s.rules["combat"], clashes[0])
	s.state.active_battles.append(b)
	return b


## Bataille complète par la résolution du mois (IA contre IA), clôture et comptabilité comprises.
func _resolve(s: GameSession, approach: String, posture: String) -> Dictionary:
	s.state.formations[D_ARMY]["defensive_posture"] = posture
	TurnResolver.resolve(s.state, s.world, s.rules, {A_NATION: [Orders.move(A_NATION, A_ARMY, TARGET, approach)]})
	return s.state.battles[-1]


func _conserved(s: GameSession, nid: String, label: String) -> void:
	var c := MobilizationSystem.conservation(s.state, nid)
	runner.check(c["reserves_ok"] and c["personnel_ok"], "%s : %s — conservation (personnel %d / %d)" % [nid, label, int(c["personnel_lhs"]), int(c["personnel_rhs"])])


## Unités ACTIVES d'un pays (optionnellement d'un type), ordre déterministe.
func _ids(b: Dictionary, nation: String, kind: String = "") -> Array:
	return CombatData.unit_ids(b).filter(func(id: String) -> bool:
		var u: Dictionary = b["units"][id]
		return u["nation"] == nation and u["status"] == CombatData.ACTIVE and (kind == "" or u["type"] == kind))


func _entered(b: Dictionary, side: String) -> int:
	var n := 0
	for uid: String in b["units"]:
		var u: Dictionary = b["units"][uid]
		if u["side"] == side and u["status"] in [CombatData.ACTIVE, CombatData.ROUTING, CombatData.WITHDRAWN, CombatData.DESTROYED, CombatData.WITHDRAWING]:
			n += int(u["start_soldiers"])
	return n


# ------------------------------------------------------------------ 1. les neuf combinaisons
func test_nine_combinations_rules() -> void:
	var cr: Dictionary = _session().rules["combat"]
	var ec: Dictionary = cr["engagement"]
	for ap: String in Engagement.APPROACHES:
		for po: String in Engagement.POSTURES:
			var s := _session()
			var b := _create(s, ap, po)
			var e: Dictionary = b["engagement"]
			var expected: String = ec["matrix"][ap][po]
			runner.check(e["planned"] == expected and e["approach"] == ap and e["posture"] == po,
				"%s / %s : %s (matrice ; Lorraine sans circonstance particulière)" % [ap, po, Engagement.label(cr, e["planned"])])
			runner.check(float(b["max_minutes"]) <= float(ec["types"][expected]["max_minutes"]), "%s / %s : durée plafonnée par le type" % [ap, po])
			var by_type := {}
			var reserve := 0
			for uid: String in b["units"]:
				var u: Dictionary = b["units"][uid]
				if u["side"] != CombatData.ATTACKERS or u["status"] == CombatData.AVAILABLE:
					continue
				by_type[u["type"]] = int(by_type.get(u["type"], 0)) + 1
				if u["status"] == CombatData.RESERVE:
					reserve += 1
			var expected_reserve := 0
			for kind: String in by_type:
				expected_reserve += int(by_type[kind]) - maxi(1, int(ceil(float(ec["approaches"][ap]["commit_share"]) * float(by_type[kind]))))
			runner.check(reserve == expected_reserve, "%s : %d unités gardées en réserve (part engagée %.0f %%)" % [ap, reserve, 100.0 * float(ec["approaches"][ap]["commit_share"])])
			var dt := Engagement.disengage_threshold(b, cr, CombatData.DEFENDERS)
			runner.check((po == "hold_at_all_costs") == (dt == INF), "%s : seuil de rupture du défenseur %s" % [po, "aucun" if dt == INF else "%.0f %%" % (100.0 * dt)])


## Conséquences observées sur des batailles jouées : chaque choix change le déroulement.
func test_choices_have_consequences() -> void:
	var cr: Dictionary = _session().rules["combat"]
	var entered := {}
	for ap: String in Engagement.APPROACHES:
		var c := _create(_session(), ap, "hold")
		var committed := 0
		for uid: String in c["units"]:
			if c["units"][uid]["side"] == CombatData.ATTACKERS and c["units"][uid]["status"] == CombatData.ACTIVE:
				committed += int(c["units"][uid]["soldiers"])
		entered[ap] = committed
		var s := _session()
		var b := _resolve(s, ap, "hold")
		var charged := false
		for e: Dictionary in b["log"]:
			if str(e["text"]).contains(" charge "):
				charged = charged or e["side"] == CombatData.ATTACKERS
		if ap == "reconnaissance":
			runner.check(not charged, "reconnaissance : aucune charge de l'attaquant")
			runner.check(s.state.controller(TARGET) == D_NATION, "reconnaissance : la région n'est pas prise (défense non effondrée)")
			runner.check(s.state.regions[TARGET].get("recon_reports", {}).has(A_NATION), "reconnaissance : renseignement enregistré pour l'attaquant")
		runner.check(int(b["tick"]) <= int(ceil(float(cr["engagement"]["types"][b["engagement"]["planned"]]["max_minutes"]) * 30.0)),
			"%s : durée dans le plafond du type (%d pas)" % [ap, int(b["tick"])])
		for side: String in CombatData.SIDES:
			var k: Dictionary = b["casualty_breakdown"][side]
			runner.check(int(k["killed"]) + int(k["wounded"]) + int(k["missing"]) + int(k["prisoners"]) == int(b["result"]["stats"][side]["lost"]),
				"%s : comptabilité de l'étape 1 intacte (%s)" % [ap, side])
		for nid: String in [A_NATION, D_NATION]:
			_conserved(s, nid, ap)
	runner.check(int(entered["reconnaissance"]) < int(entered["limited_attack"]) and int(entered["limited_attack"]) < int(entered["assault"]),
		"effectifs engagés d'emblée : reconnaissance %d < attaque limitée %d < assaut %d" % [entered["reconnaissance"], entered["limited_attack"], entered["assault"]])
	# Postures (Lorraine inversée : le défenseur allemand est le plus faible).
	var out := {}
	for po: String in Engagement.POSTURES:
		var s := GameSession.create()
		s.new_game("united_kingdom", 1, 1914)
		s.state.wars.append({"id": "w", "a": D_NATION, "b": A_NATION, "since_turn": 0})
		s.state.formations[A_ARMY]["defensive_posture"] = po
		TurnResolver.resolve(s.state, s.world, s.rules, {D_NATION: [Orders.move(D_NATION, D_ARMY, "region_035", "assault")]})
		var b: Dictionary = s.state.battles[-1]
		out[po] = {"disengaged": (b["engagement"]["disengaged"] as Dictionary).keys(), "lost": int(b["result"]["stats"]["defenders"]["lost"]),
			"tick": int(b["tick"]), "controller": s.state.controller("region_035")}
		for nid: String in [A_NATION, D_NATION]:
			_conserved(s, nid, po)
	runner.check(out["delay"]["disengaged"] == ["defenders"] and out["delay"]["controller"] == D_NATION,
		"retarder : le défenseur rompt le combat et cède la région (pertes %d)" % out["delay"]["lost"])
	runner.check(not (out["hold_at_all_costs"]["disengaged"] as Array).has("defenders"), "tenir à tout prix : le défenseur ne rompt jamais le combat")
	runner.check(int(out["delay"]["lost"]) < int(out["hold"]["lost"]) and int(out["hold"]["lost"]) <= int(out["hold_at_all_costs"]["lost"]),
		"pertes du défenseur : retarder %d < tenir %d ≤ à tout prix %d" % [out["delay"]["lost"], out["hold"]["lost"], out["hold_at_all_costs"]["lost"]])


# ------------------------------------------------------------------ 2. classification
func test_classification_circumstances() -> void:
	var s := _session()
	var cr: Dictionary = s.rules["combat"]
	var ec: Dictionary = cr["engagement"]
	var b := _create(s, "assault", "hold")
	var ctx := {"approach": "assault", "posture": "hold", "encircled": false, "attacker_morale": 70.0, "defender_morale": 70.0}
	# Ampleur : au-delà du seuil, l'assaut frontal devient une grande bataille.
	var big := b.duplicate(true)
	for uid: String in big["units"]:
		big["units"][uid]["soldiers"] = int(big["units"][uid]["soldiers"]) * 2
	Engagement.setup(big, cr, ctx)
	runner.check(Engagement.engaged_soldiers(big) >= int(ec["major_battle_soldiers"]) and big["engagement"]["planned"] == "major",
		"%d hommes engagés : grande bataille" % Engagement.engaged_soldiers(big))
	runner.check(float(big["engagement"]["front_km"]) > float(b["engagement"]["front_km"]), "grande bataille : secteur plus large")
	# Terrain cloisonné : pas de grande bataille.
	big["field"]["relief"] = ["mountains", "marshes"]
	Engagement.setup(big, cr, ctx)
	runner.check(big["engagement"]["planned"] == "frontal", "montagnes et marais : l'ampleur ne suffit pas, assaut frontal")
	# Faibles effectifs.
	var small := b.duplicate(true)
	for uid: String in small["units"]:
		small["units"][uid]["soldiers"] = 500
	Engagement.setup(small, cr, ctx)
	runner.check(small["engagement"]["planned"] == "limited", "faibles effectifs : engagement limité au plus")
	# Moral de l'attaquant.
	var tired := b.duplicate(true)
	Engagement.setup(tired, cr, {"approach": "assault", "posture": "hold", "encircled": false, "attacker_morale": 30.0, "defender_morale": 70.0})
	runner.check(tired["engagement"]["planned"] == "limited", "moral de l'attaquant trop bas : pas d'assaut frontal")
	# Encerclement : impossible de retarder.
	var enc := b.duplicate(true)
	Engagement.setup(enc, cr, {"approach": "assault", "posture": "delay", "encircled": true, "attacker_morale": 70.0, "defender_morale": 70.0})
	runner.check(enc["engagement"]["posture"] == "hold" and enc["engagement"]["planned"] == "frontal", "défenseur encerclé : il tient (assaut frontal)")
	# Fortifications : une attaque limitée contre une position fortifiée est un assaut frontal.
	var fort := b.duplicate(true)
	(fort["defenses"]["trenches"] as Array).append({"id": "t", "owner": D_NATION, "a": [900.0, 700.0], "b": [1100.0, 700.0], "level": 2})
	Engagement.setup(fort, cr, {"approach": "limited_attack", "posture": "hold", "encircled": false, "attacker_morale": 70.0, "defender_morale": 70.0})
	runner.check(fort["engagement"]["planned"] == "frontal", "attaque limitée contre tranchées de niveau 2 : assaut frontal")
	runner.check(not (fort["engagement"]["reasons"] as Array).is_empty(), "critères retenus consignés (%d)" % (fort["engagement"]["reasons"] as Array).size())


## Classification réalisée : renforts (assaut frontal → grande bataille) ; rupture précoce (un cran).
func test_realized_classification() -> void:
	var s := _session()
	var cr: Dictionary = s.rules["combat"]
	var b := _create(s, "assault", "hold")
	for uid: String in b["units"]:
		var u: Dictionary = b["units"][uid]
		if u["status"] == CombatData.AVAILABLE:
			u["soldiers"] = 40000
			u["start_soldiers"] = 40000
			u["status"] = CombatData.ACTIVE
	var km := float(b["engagement"]["front_km"])
	Engagement.on_arrival(b, cr)
	runner.check(b["engagement"]["type"] == "major" and float(b["engagement"]["front_km"]) > km, "renforts arrivés au-delà du seuil : grande bataille, front élargi")
	var d := _create(_session(), "assault", "hold")
	Engagement.disengage(d, cr, CombatData.DEFENDERS, "test")
	Engagement.finalize(d, cr)
	runner.check(d["engagement"]["realized"] == "limited", "rupture dès le premier tiers : assaut frontal réalisé en engagement limité")


# ------------------------------------------------------------------ 3. largeur du front
func test_front_width_limits_simultaneous_combatants() -> void:
	var s := _session()
	var cr: Dictionary = s.rules["combat"]
	var fc: Dictionary = cr["engagement"]["front"]
	var b := _create(s, "assault", "hold")
	var cap := float(b["engagement"]["front_km"]) * float(fc["infantry_per_km"])
	var over := 0
	var waited := false
	var max_used := 0.0
	while b["status"] == "active":
		BattleManager.advance(b, cr, 1, true)
		for side: String in CombatData.SIDES:
			var used := 0.0
			for uid: String in b["units"]:
				var u: Dictionary = b["units"][uid]
				if u["side"] == side and u["type"] != "artillery" and float(u.get("front_share", 0.0)) > 0.0:
					used += float(u["soldiers"]) * float(u["front_share"]) * Engagement.frontage(b, cr, u)
			max_used = maxf(max_used, used)
			if used > cap + 1.0:
				over += 1
			waited = waited or int(b["engagement"]["waiting"][side]) > 0
	runner.check(over == 0, "front de %.1f km : la place occupée en ligne ne dépasse jamais la capacité (max %.0f / %.0f)" % [float(b["engagement"]["front_km"]), max_used, cap])
	runner.check(max_used > 0.5 * cap, "le front est réellement occupé (%.0f / %.0f)" % [max_used, cap])
	runner.check(waited, "des unités au contact attendent faute de place sur le front")
	# Le front dépend du type, de la géométrie et du terrain.
	var fronts := {}
	for ap: String in ["reconnaissance", "assault"]:
		fronts[ap] = float(_create(_session(), ap, "hold")["engagement"]["front_km"])
	runner.check(float(fronts["reconnaissance"]) < float(fronts["assault"]), "escarmouche %.1f km < assaut frontal %.1f km" % [fronts["reconnaissance"], fronts["assault"]])
	var v := GameSession.create()
	v.new_game("united_kingdom", 1, 1914)
	v.state.wars.append({"id": "w", "a": "italy", "b": "austria_hungary", "since_turn": 0})
	var vc := MilitarySystem.resolve_moves(v.state, v.world, v.rules, [Orders.move("italy", "army_italy_region_081", "region_037", "assault")])
	var vb := BattleManager.create(v.state, v.world, v.rules, v.rules["combat"], vc[0])
	runner.check(float(vb["engagement"]["terrain_frontage"]) < float(b["engagement"]["terrain_frontage"]) and float(vb["engagement"]["front_km"]) < float(b["engagement"]["front_km"]),
		"Vénétie (montagnes) : front %.1f km < Lorraine %.1f km" % [float(vb["engagement"]["front_km"]), float(b["engagement"]["front_km"])])
	# Formations : la colonne tient plus de soldats sur un même front que la ligne de tirailleurs.
	var u: Dictionary = b["units"][CombatData.unit_ids(b)[0]].duplicate()
	u["formation"] = "assault_column"
	var col := Engagement.frontage(b, cr, u)
	u["formation"] = "skirmish_line"
	runner.check(col < Engagement.frontage(b, cr, u), "colonne %.2f < tirailleurs %.2f (place par soldat)" % [col, Engagement.frontage(b, cr, u)])


## Unités en attente : elles ne tirent pas, sont moins exposées, récupèrent et relèvent les unités épuisées.
func test_waiting_units_and_rotation() -> void:
	var s := _session()
	var cr: Dictionary = s.rules["combat"]
	var b := _create(s, "assault", "hold")
	b["engagement"]["front_km"] = 6.0
	var fr := _ids(b, D_NATION, "infantry")
	var de := _ids(b, A_NATION, "infantry")
	for id: String in b["units"]:
		b["units"][id]["pos"] = [10.0, 10.0] if b["units"][id]["side"] == CombatData.DEFENDERS else [1990.0, 1390.0]
	b["units"][de[0]]["pos"] = [1000.0, 600.0]
	b["units"][fr[0]]["pos"] = [1000.0, 800.0]
	b["units"][fr[1]]["pos"] = [1000.0, 820.0]
	for id: String in [fr[0], fr[1]]:
		b["units"][id]["formation"] = "skirmish_line"
	TacticalSim.update_fog(b, cr)
	var losses := TacticalSim._fire_and_melee(b, cr)
	var a: Dictionary = b["units"][fr[0]]
	var w: Dictionary = b["units"][fr[1]]
	runner.check(a["front_status"] == "line" and w["front_status"] == "waiting", "6 km de front : une unité en ligne, l'autre en attente")
	runner.check(int(w["engaged_ticks"]) == 0 and int(a["engaged_ticks"]) == 1, "l'unité en attente ne tire pas")
	runner.check(Engagement.exposure_factor(cr, w) < Engagement.exposure_factor(cr, a), "l'unité en attente est moins exposée")
	# Rotation : l'unité en ligne s'épuise, l'unité fraîche la relève ; la fatigue se résorbe en attente.
	a["morale"] = 30.0
	a["engaged_ticks"] = 500
	TacticalSim._fire_and_melee(b, cr)
	runner.check(w["front_status"] == "line" and a["front_status"] == "waiting" and int(b["engagement"]["rotations"]) >= 1, "rotation : l'unité épuisée passe derrière")
	runner.check(int(a["engaged_ticks"]) < 500, "fatigue en récupération pendant l'attente (%d)" % int(a["engaged_ticks"]))


# ------------------------------------------------------------------ 4. réserves et renforts
func test_reserves_and_reinforcements() -> void:
	var s := _session()
	var cr: Dictionary = s.rules["combat"]
	var b := _create(s, "reconnaissance", "hold")
	var reserves: Array = CombatData.unit_ids(b).filter(func(id: String) -> bool: return b["units"][id]["status"] == CombatData.RESERVE)
	runner.check(not reserves.is_empty(), "reconnaissance : %d unités en réserve" % reserves.size())
	BattleManager.run_to_end(b, cr, true)
	var fired := false
	for id: String in reserves:
		fired = fired or int(b["units"][id]["engaged_ticks"]) > 0 or b["units"][id]["status"] == CombatData.ACTIVE
	runner.check(not fired, "reconnaissance : l'IA n'engage pas ses réserves, qui ne combattent pas")
	# Engagement manuel d'une réserve : délai, jamais instantané.
	var s2 := _session()
	var b2 := _create(s2, "limited_attack", "hold")
	var r2: Array = CombatData.unit_ids(b2).filter(func(id: String) -> bool: return b2["units"][id]["status"] == CombatData.RESERVE)
	runner.check(TacticalOrders.commit_reserve(b2, cr, A_NATION, [r2[0]]) == "", "attaque limitée : réserve engagée sur ordre")
	runner.check(b2["units"][r2[0]]["status"] == CombatData.ARRIVING and int(b2["units"][r2[0]]["arrive_tick"]) > int(b2["tick"]), "délai d'engagement des réserves conservé")
	# Renforts : délai conservé ; jamais dans deux batailles.
	var av: Array = CombatData.unit_ids(b2).filter(func(id: String) -> bool: return b2["units"][id]["status"] == CombatData.AVAILABLE and b2["units"][id]["nation"] == D_NATION)
	runner.check(not av.is_empty(), "renforts voisins disponibles pour le défenseur (%d)" % av.size())
	var eta := int(b2["units"][av[0]]["eta_ticks"])
	runner.check(TacticalOrders.call_reinforcement(b2, cr, D_NATION, av[0]) == "" and int(b2["units"][av[0]]["arrive_tick"]) == int(b2["tick"]) + eta,
		"renfort appelé : arrivée après %d pas" % eta)
	runner.check(s2.state.formations[av[0]]["battle_id"] == b2["id"], "le renfort est verrouillé pour cette bataille")
	var army_of_av := s2.state.army_of(av[0])
	var other := BattleManager.create(s2.state, s2.world, s2.rules, cr, {"region": s2.state.formations[army_of_av]["region"],
		"attackers": [A_ARMY], "defenders": [army_of_av], "origin": {}, "approach": {}})
	var dup := not other.is_empty() and (other["units"] as Dictionary).has(av[0])
	runner.check(not dup, "une unité réservée à une bataille ne combat pas sur un autre front")


# ------------------------------------------------------------------ 5. blessés légers
func test_lightly_wounded_reduce_capacity() -> void:
	var s := _session()
	var cr: Dictionary = s.rules["combat"]
	var eff := float(cr["engagement"]["lightly_wounded_efficiency"])
	var u := {"soldiers": 10000, "lightly_wounded": 1000}
	runner.check(is_equal_approx(Engagement.operational(cr, u), 10000.0 - 1000.0 * (1.0 - eff)), "capacité opérationnelle %.0f pour 10 000 hommes dont 1 000 blessés légers" % Engagement.operational(cr, u))
	runner.check(int(u["soldiers"]) == 10000, "effectif administratif inchangé")
	# Feu : proportionnel à la capacité opérationnelle.
	var b := _create(s, "assault", "hold")
	var shooter: String = _ids(b, D_NATION, "infantry")[0]
	var target: String = _ids(b, A_NATION, "infantry")[0]
	for id: String in b["units"]:
		b["units"][id]["pos"] = [10.0, 10.0] if b["units"][id]["side"] == CombatData.DEFENDERS else [1990.0, 1390.0]
	b["units"][shooter]["pos"] = [1000.0, 800.0]
	b["units"][target]["pos"] = [1000.0, 600.0]
	TacticalSim.update_fog(b, cr)
	var full := float(TacticalSim._fire_and_melee(b, cr).get(target, 0.0))
	b["units"][shooter]["lightly_wounded"] = int(b["units"][shooter]["soldiers"]) / 2
	b["units"][shooter]["engaged_ticks"] = 0
	b["units"][target]["engaged_ticks"] = 0
	var hurt := float(TacticalSim._fire_and_melee(b, cr).get(target, 0.0))
	runner.check(full > 0.0 and is_equal_approx(hurt / full, Engagement.operational(cr, b["units"][shooter]) / float(b["units"][shooter]["soldiers"])),
		"feu réduit dans le rapport capacité / effectif (%.3f)" % (hurt / maxf(full, 0.001)))
	# Pertes : les blessés légers en font partie au prorata, sans double comptage.
	var v := {"soldiers": 9000, "lightly_wounded": 900}
	Engagement.on_losses(v, 1000, 10000)
	runner.check(int(v["lightly_wounded"]) == 810, "1 000 pertes sur 10 000 : 90 blessés légers parmi elles (810 restent)")
	# Après une bataille : blessés légers inscrits dans l'unité, guérison au bout d'un mois, présents inchangés.
	var s3 := _session()
	var bb := _resolve(s3, "assault", "hold")
	var lw := 0
	for f: Dictionary in s3.state.formations_of(D_NATION):
		lw += int(f.get("lightly_wounded", 0))
	var remained := int(bb["casualty_breakdown"]["defenders"]["remained"])
	runner.check(lw > 0 and lw == remained, "blessés légers restés dans les unités françaises : %d (= %d ventilés)" % [lw, remained])
	var present := int(MobilizationSystem.summary(s3.state, D_NATION)["present_in_units"])
	s3.state.turn += 1
	ForceLedger.heal_lightly_wounded(s3.state)
	var lw2 := 0
	for f: Dictionary in s3.state.formations_of(D_NATION):
		lw2 += int(f.get("lightly_wounded", 0))
	runner.check(lw2 == 0 and int(MobilizationSystem.summary(s3.state, D_NATION)["present_in_units"]) == present, "guérison après un mois : capacité rétablie, présents inchangés")
	_conserved(s3, D_NATION, "blessés légers")
	# État des forces (T-037) : calculé sur la capacité opérationnelle.
	var c0 := float(BattleResult.compute(b, cr)["stats"]["defenders"]["capacity"])
	for id: String in b["units"]:
		if b["units"][id]["side"] == CombatData.DEFENDERS:
			b["units"][id]["lightly_wounded"] = int(b["units"][id]["soldiers"])
	runner.check(float(BattleResult.compute(b, cr)["stats"]["defenders"]["capacity"]) < c0, "état des forces : capacité opérationnelle prise en compte")


# ------------------------------------------------------------------ 6. moral, formations, fortifications
func test_compatibility_morale_formations_fortifications() -> void:
	var s := _session()
	var cr: Dictionary = s.rules["combat"]
	var b := _create(s, "assault", "hold_at_all_costs")
	var d: Dictionary = b["units"][_ids(b, D_NATION, "infantry")[0]]
	var a: Dictionary = b["units"][_ids(b, A_NATION, "infantry")[0]]
	runner.check(Engagement.rout_threshold(b, cr, d) < Engagement.rout_threshold(b, cr, a), "tenir à tout prix : seuil de déroute abaissé pour le défenseur seulement")
	var h := _create(_session(), "assault", "hold")
	var hd: Dictionary = h["units"][_ids(h, D_NATION, "infantry")[0]]
	runner.check(is_equal_approx(Engagement.rout_threshold(h, cr, hd), float(cr["rout"]["threshold"])), "tenir : seuil de déroute inchangé (T-039)")
	# Tranchée : un soldat retranché tient plus de front.
	(b["defenses"]["trenches"] as Array).append({"id": "t", "owner": D_NATION, "a": [900.0, 700.0], "b": [1100.0, 700.0], "site": [1000.0, 700.0],
		"level": 2, "target_level": 2, "progress": 0.0, "work_needed": 1.0, "complete": true, "condition": 1.0})
	d["pos"] = [1000.0, 705.0]
	d["formation"] = "entrenched"
	var in_trench := Engagement.frontage(b, cr, d)
	d["pos"] = [200.0, 200.0]
	runner.check(in_trench < Engagement.frontage(b, cr, d), "tranchée achevée : place par soldat réduite (%.2f)" % in_trench)
	# Retarder : l'IA ne se retranche pas.
	var dl := _create(_session(), "assault", "delay")
	BattleManager.advance(dl, cr, 60, true)
	var trenches := 0
	for t: Dictionary in dl["defenses"]["trenches"]:
		if t["owner"] == D_NATION:
			trenches += 1
	var entrenched := 0
	for id: String in dl["units"]:
		if dl["units"][id]["side"] == CombatData.DEFENDERS and dl["units"][id]["formation"] == "entrenched":
			entrenched += 1
	runner.check(trenches == 0 and entrenched == 0, "retarder : ni tranchée ni position retranchée")


# ------------------------------------------------------------------ 7. ordres, IA, reproductibilité, sauvegarde
func test_orders_and_ai_defaults() -> void:
	var s := _session()
	runner.check(MilitarySystem.validate_move(s.state, s.world, s.rules, Orders.move(A_NATION, A_ARMY, TARGET, "blitz")) == "approche offensive inconnue", "approche inconnue refusée")
	var g := GameSession.create()
	g.new_game("france", 1, 1914)
	runner.check(g.queue_order(Orders.defensive_posture("france", D_ARMY, "delay")) == "", "posture défensive : ordre du joueur accepté")
	runner.check(g.queue_order(Orders.defensive_posture("france", A_ARMY, "delay")) != "", "posture d'une armée étrangère refusée")
	runner.check(g.queue_order(Orders.defensive_posture("france", D_ARMY, "panique")) != "", "posture inconnue refusée")
	g.end_turn()
	runner.check(g.state.formations[D_ARMY]["defensive_posture"] == "delay", "posture appliquée à la résolution du mois")
	var capital_army := ""
	for fid: String in s.state.sorted_formation_ids():
		var f: Dictionary = s.state.formations[fid]
		if capital_army == "" and s.state.is_top_level(f) and f["region"] == s.state.nations[f["nation"]]["capital_region_id"]:
			capital_army = fid
	runner.check(capital_army != "" and TacticalAI.default_posture(s.state, capital_army) == "hold_at_all_costs",
		"IA : tenir à tout prix dans la région de la capitale (%s)" % capital_army)
	runner.check(TacticalAI.default_posture(s.state, A_ARMY) == "hold", "IA : tenir ailleurs")


func test_reproducibility_and_save_mid_battle() -> void:
	var a := _session()
	var b := _session()
	var ba := _resolve(a, "limited_attack", "delay")
	var bb := _resolve(b, "limited_attack", "delay")
	runner.check(JSON.stringify(ba["engagement"]) == JSON.stringify(bb["engagement"]) and JSON.stringify(ba["result"]["stats"]) == JSON.stringify(bb["result"]["stats"]),
		"même bataille, même résultat (engagement et pertes)")
	# Sauvegarde en pleine bataille : la reprise donne exactement la même suite.
	var s := GameSession.create()
	s.new_game("france", 1, 1914)
	s.state.wars.append({"id": "w", "a": A_NATION, "b": D_NATION, "since_turn": 0})
	s.state.formations[D_ARMY]["defensive_posture"] = "hold"
	s.state.formations[D_ARMY]["lightly_wounded"] = 0
	TurnResolver.resolve(s.state, s.world, s.rules, {A_NATION: [Orders.move(A_NATION, A_ARMY, TARGET, "assault")]})
	var cur := s.current_battle()
	runner.check(not cur.is_empty() and cur.has("engagement"), "bataille du joueur active, avec son type d'engagement")
	BattleManager.advance(cur, s.rules["combat"], 150, true)
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	runner.check(SaveRepository.save("user://test_saves/engagement_mid.json", s.state, s.world, s.rules) == "", "sauvegarde en cours de bataille")
	var loaded := SaveRepository.load_save("user://test_saves/engagement_mid.json", s.world, s.rules)
	runner.check(not loaded.has("error"), "chargement (%s)" % str(loaded.get("error", "")))
	var r := GameSession.create()
	r.state = loaded["state"]
	var lb := r.current_battle()
	BattleManager.run_to_end(cur, s.rules["combat"], true)
	BattleManager.run_to_end(lb, r.rules["combat"], true)
	runner.check(JSON.stringify(cur["engagement"]) == JSON.stringify(lb["engagement"]) and int(cur["tick"]) == int(lb["tick"]),
		"suite identique après rechargement (type, front, rotations, durée)")


## Bataille en cours d'une sauvegarde antérieure à l'étape 2 (sans type d'engagement) : elle se termine
## avec les anciennes règles (toute l'unité au feu, aucune rupture automatique), sans erreur.
func test_legacy_battle_without_engagement() -> void:
	var s := _session()
	var cr: Dictionary = s.rules["combat"]
	var b := _create(s, "assault", "hold")
	b.erase("engagement")
	for uid: String in b["units"]:
		if b["units"][uid]["status"] == CombatData.RESERVE and b["units"][uid]["side"] == CombatData.ATTACKERS:
			b["units"][uid]["status"] = CombatData.ACTIVE
	BattleManager.run_to_end(b, cr, true)
	var full := true
	for uid: String in b["units"]:
		full = full and is_equal_approx(float(b["units"][uid].get("front_share", 1.0)), 1.0)
	runner.check(b["status"] == "ended" and full, "bataille sans type d'engagement : anciennes règles, terminée (%s)" % b.get("end_reason", ""))
	var res := BattleManager.finish(s.state, s.world, cr, b)
	runner.check(not res.has("engagement") and res.has("winner"), "clôture sans type d'engagement")
	for nid: String in [A_NATION, D_NATION]:
		_conserved(s, nid, "bataille héritée")


## Étape 3 : calibration des pertes (infanterie majoritaire, artillerie non dominante, survie des unités
## en déroute, respect des seuils de rupture, effondrement de la défense à tout prix).
func test_step3_calibration_and_collapse() -> void:
	# 1. Engagement limité : l'infanterie subit l'essentiel des pertes, l'artillerie ne domine plus.
	var sl := _session()
	var bl := _resolve(sl, "limited_attack", "hold")
	var inf_lost := 0
	var art_lost := 0
	var tot_lost := 0
	for uid: String in bl["units"]:
		var u: Dictionary = bl["units"][uid]
		if u["status"] in [CombatData.ACTIVE, CombatData.ROUTING, CombatData.WITHDRAWN, CombatData.DESTROYED, CombatData.WITHDRAWING]:
			var l := int(u["start_soldiers"]) - int(u["soldiers"])
			tot_lost += l
			if u["type"] == "infantry":
				inf_lost += l
			elif u["type"] == "artillery":
				art_lost += l
	runner.check(inf_lost > int(0.65 * float(tot_lost)) and art_lost < int(0.15 * float(tot_lost)),
		"engagement limité : infanterie majoritaire dans les pertes (%d / %d, artillerie %d)" % [inf_lost, tot_lost, art_lost])
	# 2. Assaut contre défense normale : rupture sous le seuil de 35 % et absence d'annihilation d'unités en déroute.
	var sa := _session()
	var ba := _resolve(sa, "assault", "hold")
	var destroyed := 0
	var att_entered := 0
	for uid: String in ba["units"]:
		var u: Dictionary = ba["units"][uid]
		if u["status"] == CombatData.DESTROYED:
			destroyed += 1
		if u["side"] == CombatData.ATTACKERS and u["status"] in [CombatData.ACTIVE, CombatData.ROUTING, CombatData.WITHDRAWN, CombatData.DESTROYED, CombatData.WITHDRAWING]:
			att_entered += int(u["start_soldiers"])
	var att_loss_pct := 100.0 * float(ba["result"]["stats"]["attackers"]["lost"]) / maxf(1.0, float(att_entered))
	runner.check(att_loss_pct < 30.0 and destroyed == 0,
		"assaut / tenir : pertes de l'attaquant modérées avant rupture (%.1f %%), aucune unité anéantie" % att_loss_pct)
	# 3. Défense à tout prix submergée (Lorraine inversée : FR 011 -> DE 035) : plus longue et plus coûteuse
	#    que « tenir », mais finit par effondrement de la défense sans annihilation totale.
	var sh := GameSession.create()
	sh.new_game("united_kingdom", 1, 1914)
	sh.state.wars.append({"id": "w", "a": D_NATION, "b": A_NATION, "since_turn": 0})
	sh.state.formations[A_ARMY]["defensive_posture"] = "hold"
	TurnResolver.resolve(sh.state, sh.world, sh.rules, {D_NATION: [Orders.move(D_NATION, D_ARMY, "region_035", "assault")]})
	var bh: Dictionary = sh.state.battles[-1]
	var sc := GameSession.create()
	sc.new_game("united_kingdom", 1, 1914)
	sc.state.wars.append({"id": "w", "a": D_NATION, "b": A_NATION, "since_turn": 0})
	sc.state.formations[A_ARMY]["defensive_posture"] = "hold_at_all_costs"
	TurnResolver.resolve(sc.state, sc.world, sc.rules, {D_NATION: [Orders.move(D_NATION, D_ARMY, "region_035", "assault")]})
	var bc: Dictionary = sc.state.battles[-1]
	var def_lost_h := int(bh["result"]["stats"]["defenders"]["lost"])
	var def_lost_c := int(bc["result"]["stats"]["defenders"]["lost"])
	var att_lost_h := int(bh["result"]["stats"]["attackers"]["lost"])
	var att_lost_c := int(bc["result"]["stats"]["attackers"]["lost"])
	runner.check(int(bc["tick"]) > int(bh["tick"]) and def_lost_c > def_lost_h and att_lost_c > att_lost_h,
		"tenir à tout prix submergé : résiste plus longtemps (%d > %d pas) et coûte plus cher aux deux camps" % [int(bc["tick"]), int(bh["tick"])])
	runner.check(str(bc["result"]["end_reason"]).find("effondrement de la défense") >= 0 and float(def_lost_c) < 0.40 * 57819.0,
		"tenir à tout prix submergé : fin par effondrement de la défense (%s, %.1f %% de pertes) sans annihilation totale" % [str(bc["result"]["end_reason"]), 100.0 * float(def_lost_c) / 57819.0])
