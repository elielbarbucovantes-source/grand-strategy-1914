extends SceneTree
## Simulations exploratoires des types d'engagement (MIL-01, phase 6, étape 2) — PAS un équilibrage :
##   godot --headless --path . --script tests/engagement_report.gd
## Batailles IA contre IA, campagne de janvier 1914, graine fixe. Pour chaque cas : type prévu et
## réalisé, secteur de front, pic de soldats en ligne et capacité du front, rotations, durée, fin,
## pertes (% de l'effectif entré sur le terrain), vainqueur.

const LORRAINE := ["german_empire", "army_german_empire_region_035", "region_011", "france", "army_france_region_011"]


func _initialize() -> void:
	print("## A. Les neuf combinaisons (Lorraine : Allemagne 035 → France 011)\n")
	_header()
	for ap: String in Engagement.APPROACHES:
		for po: String in Engagement.POSTURES:
			_run("%s / %s" % [ap, po], LORRAINE, ap, po, Callable())
	print("\n## A2. Les neuf combinaisons (Lorraine inversée : France 011 → Allemagne 035, défenseur plus faible)\n")
	_header()
	for ap: String in Engagement.APPROACHES:
		for po: String in Engagement.POSTURES:
			_run("%s / %s" % [ap, po], ["france", "army_france_region_011", "region_035", "german_empire", "army_german_empire_region_035"], ap, po, Callable())
	print("\n## B. Scénarios représentatifs\n")
	_header()
	_run("1. Reconnaissance en force contre défense retranchée (tranchées niv. 2)", LORRAINE, "reconnaissance", "hold", _trenches)
	_run("2. Attaque limitée contre défense normale", LORRAINE, "limited_attack", "hold", Callable())
	_run("3. Assaut contre position fortifiée (tranchées niv. 2 + nids)", LORRAINE, "assault", "hold", _fortified)
	_run("4. Assaut contre défense qui retarde", LORRAINE, "assault", "delay", Callable())
	_run("5. Assaut contre défense à tout prix", LORRAINE, "assault", "hold_at_all_costs", Callable())
	_run("6. Terrain ouvert (France du Nord, plaines et collines ; secteur synthétique)", ["france", "army_france_region_011", "region_007", "german_empire", "army_german_empire_region_035"], "assault", "hold", _somme)
	_run("7. Terrain difficile (Vénétie : montagnes, collines, forêts)", ["italy", "army_italy_region_081", "region_037", "austria_hungary", "army_austria_hungary_region_037"], "assault", "hold", Callable())
	_run("8. Grande ampleur (Lorraine après trois mois de mobilisation)", LORRAINE, "assault", "hold", _mobilized)
	_run("9. Renforts progressifs (Galicie : renforts voisins des deux camps)", ["russian_empire", "army_russian_empire_region_058", "region_040", "austria_hungary", "army_austria_hungary_region_040"], "assault", "hold", Callable())
	_run("10. Unités éprouvées (Lorraine, seconde bataille le mois suivant)", LORRAINE, "assault", "hold", _previous_battle)
	quit()


func _header() -> void:
	print("| Cas | Type prévu → réalisé | Front (km) | Pic en ligne A / D (capacité inf. + art.) | Rotations | Durée | Fin | Pertes A / D (% entrés) | Vainqueur |")
	print("|---|---|---|---|---|---|---|---|---|")


func _run(label: String, c: Array, approach: String, posture: String, setup: Callable) -> void:
	var s := GameSession.create()
	s.new_game("united_kingdom", 1, 1914)
	var st := s.state
	st.wars.append({"id": "w", "a": c[0], "b": c[3], "since_turn": 0})
	if setup.is_valid():
		setup.call(s, c)
	st.formations[c[4]]["defensive_posture"] = posture
	var t0 := Time.get_ticks_msec()
	TurnResolver.resolve(st, s.world, s.rules, {c[0]: [Orders.move(c[0], c[1], c[2], approach)]})
	var b: Dictionary = st.battles[-1]
	var e: Dictionary = b.get("engagement", {})
	var res: Dictionary = b["result"]
	var cap := float(e["front_km"]) * 1000.0 + float(e["artillery_front_km"]) * 250.0
	var entered := {"attackers": 0, "defenders": 0}
	for uid: String in b["units"]:
		var u: Dictionary = b["units"][uid]
		if u["status"] in [CombatData.ACTIVE, CombatData.ROUTING, CombatData.WITHDRAWN, CombatData.DESTROYED, CombatData.WITHDRAWING]:
			entered[u["side"]] += int(u["start_soldiers"])
	var lost := {"attackers": int(res["stats"]["attackers"]["lost"]), "defenders": int(res["stats"]["defenders"]["lost"])}
	var w: String = res["winner"]
	print("| %s | %s → %s | %.1f | %d / %d (%d) | %d | %.1f min | %s | %d (%.1f %%) / %d (%.1f %%) | %s |" % [label,
		Engagement.label(s.rules["combat"], e["planned"]), Engagement.label(s.rules["combat"], e["realized"]), float(e["front_km"]),
		int(e["peak_line"]["attackers"]), int(e["peak_line"]["defenders"]), int(cap), int(e["rotations"]),
		float(b["tick"]) * 2.0 / 60.0, res["end_reason"], lost["attackers"], 100.0 * lost["attackers"] / maxf(1.0, entered["attackers"]),
		lost["defenders"], 100.0 * lost["defenders"] / maxf(1.0, entered["defenders"]),
		"attaquants" if w == "attackers" else ("défenseurs" if w == "defenders" else "indécise")])
	if Time.get_ticks_msec() - t0 > 60000:
		print("   (calcul %.1f s)" % ((Time.get_ticks_msec() - t0) / 1000.0))


func _trenches(s: GameSession, c: Array) -> void:
	var d := DefenseSystem.defenses(s.state, c[2])
	(d["trenches"] as Array).append({"id": "tr_r1", "owner": c[3], "a": [700.0, 600.0], "b": [1300.0, 600.0], "site": [1000.0, 600.0],
		"level": 2, "target_level": 2, "progress": 0.0, "work_needed": 8000.0, "complete": true, "condition": 1.0})


func _fortified(s: GameSession, c: Array) -> void:
	_trenches(s, c)
	var d := DefenseSystem.defenses(s.state, c[2])
	for i in 3:
		(d["installations"] as Array).append({"id": "mg_%d" % i, "type": "machine_gun_nest", "owner": c[3], "pos": [800.0 + 200.0 * i, 620.0],
			"site": [800.0 + 200.0 * i, 620.0], "progress": 6000.0, "work_needed": 6000.0, "complete": true, "condition": 1.0})


func _somme(s: GameSession, c: Array) -> void:
	s.state.move_army("army_german_empire_region_035", "region_007")
	s.state.regions["region_007"]["controller"] = "german_empire"


func _mobilized(s: GameSession, c: Array) -> void:
	var st := s.state
	for nid: String in [c[0], c[3]]:
		MobilizationSystem.set_posture(st, s.rules["forces"]["mobilization"], nid, "generale")
	for m in 3:
		MobilizationSystem.monthly(st, s.world, s.rules["forces"])
		for nid: String in [c[0], c[3]]:
			var o := Orders.call_next_echelon(nid)
			if MobilizationSystem.validate(st, o, s.world, s.rules["forces"]["mobilization"]) == "":
				MobilizationSystem.apply_order(st, s.world, s.rules["forces"]["mobilization"], o)
		st.turn += 1


## Une première bataille (assaut contre tenir) puis, le mois suivant, les mêmes armées se battent de
## nouveau : unités réduites, blessés légers restés dans leurs unités.
func _previous_battle(s: GameSession, c: Array) -> void:
	var st := s.state
	st.formations[c[4]]["defensive_posture"] = "hold"
	TurnResolver.resolve(st, s.world, s.rules, {c[0]: [Orders.move(c[0], c[1], c[2], "assault")]})
	var lw := 0
	for nid: String in [c[0], c[3]]:
		for f: Dictionary in st.formations_of(nid):
			lw += int(f.get("lightly_wounded", 0))
	print("   (première bataille : %s ; blessés légers restés dans les unités des deux camps : %d)" % [st.battles[-1]["result"]["end_reason"], lw])
	# l'attaquant battu s'est replié dans sa région d'origine : il peut attaquer de nouveau.
	if st.formations.has(c[1]) and st.formations[c[1]]["region"] == c[2]:
		st.move_army(c[1], "region_035")
