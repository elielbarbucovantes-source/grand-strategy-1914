extends SceneTree
## Simulations représentatives avec les effectifs historiques (campagne, MIL-01) :
##   godot --headless --path . --script tests/balance_report.gd
## Mesure, pour chaque cas : effectifs engagés, pertes, durée, vainqueur, renforts arrivés, temps de
## calcul. Toutes les batailles sont jouées IA contre IA (résolution automatique), graine fixe.

const CASES := [
	# [libellé, attaquant, armée attaquante, région d'origine, défenseur, armée défenseure, région de bataille, variante]
	["Lorraine : DE 035 → FR 011 (défense retranchée par défaut)", "german_empire", "army_german_empire_region_035", "region_035", "france", "army_france_region_011", "region_011", "default"],
	["Lorraine : idem, défenseur en ligne de tirailleurs", "german_empire", "army_german_empire_region_035", "region_035", "france", "army_france_region_011", "region_011", "skirmish"],
	["Lorraine : idem, tranchées préparées (niveau 2) devant chaque unité", "german_empire", "army_german_empire_region_035", "region_035", "france", "army_france_region_011", "region_011", "trenches"],
	["Lorraine inversée : FR 011 → DE 035", "france", "army_france_region_011", "region_011", "german_empire", "army_german_empire_region_035", "region_035", "default"],
	["Prusse-Orientale : RU 056 → DE 026", "russian_empire", "army_russian_empire_region_056", "region_056", "german_empire", "army_german_empire_region_026", "region_026", "default"],
	["Galicie : RU 058 → AH 040", "russian_empire", "army_russian_empire_region_058", "region_058", "austria_hungary", "army_austria_hungary_region_040", "region_040", "default"],
	["Vénétie : IT 081 → AH 037", "italy", "army_italy_region_081", "region_081", "austria_hungary", "army_austria_hungary_region_037", "region_037", "default"],
]


func _initialize() -> void:
	print("| Cas | Effectifs A / D | Pertes A | Pertes D | Durée (min) | Vainqueur | Renforts arrivés A/D | Tranchées D (nb, niveau max) | Calcul |")
	print("|---|---|---|---|---|---|---|---|---|")
	for c: Array in CASES:
		_run(c)
	_mobilization()
	_mobilized_battle()
	quit()


## Bataille de Lorraine après mobilisation complète des deux camps (3 mois) : échelle et performance.
func _mobilized_battle() -> void:
	var s := GameSession.create()
	s.new_game("france", 1, 1914)
	var st := s.state
	st.human_nations = []
	for nid: String in ["france", "german_empire"]:
		_general(s, nid)
	for m in 3:
		MobilizationSystem.monthly(st, s.world, s.rules["forces"])
		_next_echelons(s, ["france", "german_empire"])
		st.turn += 1
	st.wars.append({"id": "w", "a": "german_empire", "b": "france", "since_turn": 0})
	var attackers: Array = st.armies_in("region_035").map(func(a: Dictionary) -> String: return a["id"])
	var defenders: Array = st.armies_in("region_011").map(func(a: Dictionary) -> String: return a["id"])
	var origin := {}
	for a: String in attackers:
		st.move_army(a, "region_011")
		origin[a] = "region_035"
	for d: String in defenders:
		origin[d] = "region_011"
	var b := BattleManager.create(st, s.world, s.rules, s.rules["combat"], {"region": "region_011", "attackers": attackers, "defenders": defenders, "origin": origin})
	var start := {"attackers": 0, "defenders": 0}
	for uid: String in CombatData.unit_ids(b):
		if b["units"][uid]["status"] != CombatData.AVAILABLE:
			start[b["units"][uid]["side"]] += int(b["units"][uid]["soldiers"])
	var t0 := Time.get_ticks_msec()
	BattleManager.run_to_end(b, s.rules["combat"], true)
	var res := BattleResult.compute(b, s.rules["combat"])
	print("\nLorraine après mobilisation (DE 035 → FR 011) : %d / %d soldats, %d unités ; pertes A %d (%.0f %%), D %d (%.0f %%) ; %.1f min ; vainqueur %s ; calcul %.1f s" % [
		start["attackers"], start["defenders"], CombatData.unit_ids(b).size(),
		int(res["stats"]["attackers"]["lost"]), 100.0 * float(res["stats"]["attackers"]["lost"]) / maxf(1, float(res["stats"]["attackers"]["start"])),
		int(res["stats"]["defenders"]["lost"]), 100.0 * float(res["stats"]["defenders"]["lost"]) / maxf(1, float(res["stats"]["defenders"]["start"])),
		float(b["tick"]) * 2.0 / 60.0, res["winner"] if res["winner"] != "" else "indécise", (Time.get_ticks_msec() - t0) / 1000.0])


func _run(c: Array) -> void:
	var s := GameSession.create()
	s.new_game("france", 1, 1914)
	var st := s.state
	st.human_nations = []
	st.wars.append({"id": "w", "a": c[1], "b": c[4], "since_turn": 0})
	var region: String = c[6]
	st.move_army(c[2], region)
	if st.formations[c[5]]["region"] != region:
		st.move_army(c[5], region)
	var b := BattleManager.create(st, s.world, s.rules, s.rules["combat"], {"region": region,
		"attackers": [c[2]], "defenders": [c[5]], "origin": {c[2]: c[3], c[5]: region}})
	if b.is_empty():
		print("| %s | bataille non créée | | | | | | |" % c[0])
		return
	var cr: Dictionary = s.rules["combat"]
	if c[7] == "skirmish":
		for uid: String in CombatData.unit_ids(b):
			if b["units"][uid]["side"] == CombatData.DEFENDERS and b["units"][uid]["status"] == CombatData.ACTIVE:
				b["units"][uid]["formation"] = "skirmish_line"
				b["units"][uid]["lock_formation"] = true
	if c[7] == "trenches":
		# Ligne de tranchées achevée (niveau 2) devant chaque unité défenseure : préparation hors bataille.
		for uid: String in CombatData.unit_ids(b):
			var u: Dictionary = b["units"][uid]
			if u["side"] == CombatData.DEFENDERS and u["status"] == CombatData.ACTIVE:
				var p := CombatData.v(u["pos"])
				(b["defenses"]["trenches"] as Array).append({"id": "t_" + uid, "owner": c[4], "a": [p.x - 60, p.y], "b": [p.x + 60, p.y],
					"site": [p.x, p.y], "level": 2, "target_level": 2, "progress": 1.0, "work_needed": 1.0, "complete": true, "condition": 1.0})
	var start := {"attackers": 0, "defenders": 0}
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if u["status"] != CombatData.AVAILABLE:
			start[u["side"]] += int(u["soldiers"])
	var t0 := Time.get_ticks_msec()
	BattleManager.run_to_end(b, cr, true)
	var ms := Time.get_ticks_msec() - t0
	var arrived := {"attackers": 0, "defenders": 0}
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if bool(u["reinforcement"]) and u["status"] != CombatData.AVAILABLE:
			arrived[u["side"]] += 1
	var trenches := 0
	var top := 0
	for t: Dictionary in b["defenses"]["trenches"]:
		if t["owner"] == c[4] and int(t["level"]) > 0:
			trenches += 1
			top = maxi(top, int(t["level"]))
	var res := BattleResult.compute(b, cr)
	var la := int(res["stats"]["attackers"]["lost"])
	var ld := int(res["stats"]["defenders"]["lost"])
	var sa := int(res["stats"]["attackers"]["start"])
	var sd := int(res["stats"]["defenders"]["start"])
	print("| %s | %d / %d | %d (%.0f %%) | %d (%.0f %%) | %.1f / %.1f max | %s | %d / %d | %d, %d | %.1f s, %d unités |" % [c[0], start["attackers"], start["defenders"],
		la, 100.0 * la / maxf(1, sa), ld, 100.0 * ld / maxf(1, sd), float(b["tick"]) * float(cr["tick_seconds"]) / 60.0, float(b["max_minutes"]),
		res["winner"] if res["winner"] != "" else "indécise", arrived["attackers"], arrived["defenders"], trenches, top, ms / 1000.0, CombatData.unit_ids(b).size()])


func _mobilization() -> void:
	print("\nMobilisation générale décrétée en janvier 1914 par les sept puissances (aucune guerre) :")
	print("| Pays | Actifs sur carte | Réservoir sur carte | Mois 1 : en cours / incorporés | Mois 2 | Mois 3 | Mois 4 | Présents au mois 4 |")
	print("|---|---|---|---|---|---|---|---|")
	var s := GameSession.create()
	s.new_game("france", 1, 1914)
	var st := s.state
	var rows := {}
	for nid: String in ["united_kingdom", "france", "german_empire", "austria_hungary", "russian_empire", "italy", "ottoman_empire"]:
		_general(s, nid)
		rows[nid] = []
	var t0 := Time.get_ticks_msec()
	for m in 4:
		MobilizationSystem.monthly(st, s.world, s.rules["forces"])
		for nid: String in rows:
			var x := MobilizationSystem.summary(st, nid)
			(rows[nid] as Array).append("%d / %d" % [int(x["mobilizing"]), int(x["incorporated"])])
		_next_echelons(s, rows.keys())
		st.turn += 1
	for nid: String in rows:
		var x := MobilizationSystem.summary(st, nid)
		print("| %s | %d | %d | %s | %d |" % [nid, int(x["active_on_map"]), int(x["reserve_pool_initial"]), " | ".join(rows[nid]),
			int(x["present_in_units"]) + int(x["present_services"])])
	var units := 0
	for fid: String in st.formations:
		if st.formations[fid]["echelon"] == "unit":
			units += 1
	print("Unités sur la carte après mobilisation complète : %d (calcul de 4 mois : %d ms)" % [units, Time.get_ticks_msec() - t0])


## Posture générale (T-053) : rythme national complet, échelons ouverts dès que possible.
func _general(s: GameSession, nid: String) -> void:
	MobilizationSystem.set_posture(s.state, s.rules["forces"]["mobilization"], nid, "generale")


func _next_echelons(s: GameSession, nations: Array) -> void:
	var mr: Dictionary = s.rules["forces"]["mobilization"]
	for nid: String in nations:
		var o := Orders.call_next_echelon(nid)
		if MobilizationSystem.validate(s.state, o, s.world, mr) == "":
			MobilizationSystem.apply_order(s.state, s.world, mr, o)
