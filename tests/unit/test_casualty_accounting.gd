extends RefCounted
## MIL-01 phase 6, étape 1 : comptabilité ventilée des pertes (tués, blessés, disparus, prisonniers),
## sans modification du volume des pertes ni des règles de combat. Corrections ciblées (solution A) :
## pertes de déroute d'un camp vainqueur ventilées comme ordinaires, origine conservée.

var runner: Object


func _session(player: String = "united_kingdom") -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, 1914)
	return s


func _conserved(s: GameSession, nid: String, label: String) -> void:
	var c := MobilizationSystem.conservation(s.state, nid)
	runner.check(c["reserves_ok"] and c["personnel_ok"], "%s : %s — conservation (personnel %d / %d)" % [nid, label, int(c["personnel_lhs"]), int(c["personnel_rhs"])])


func _present(s: GameSession, nid: String) -> int:
	var sum := MobilizationSystem.summary(s.state, nid)
	return int(sum["present_in_units"]) + int(sum["present_services"])


## Bataille réelle, résolue par l'IA : l'Allemagne attaque la France en Lorraine (observateur britannique).
func _lorraine(s: GameSession) -> Dictionary:
	s.state.wars.append({"id": "w", "a": "german_empire", "b": "france", "since_turn": 0})
	TurnResolver.resolve(s.state, s.world, s.rules, {"german_empire": [Orders.move("german_empire", "army_german_empire_region_035", "region_011")]})
	return s.state.battles[-1]


# 1, 10, 11. Ventilation sans changement du volume ; conservation ; aucun double comptage.
func test_breakdown_preserves_battle_volume() -> void:
	var s := _session()
	var b := _lorraine(s)
	var stats: Dictionary = b["result"]["stats"]
	for side: String in CombatData.SIDES:
		var k: Dictionary = b["casualty_breakdown"][side]
		var total := int(k["killed"]) + int(k["wounded"]) + int(k["missing"]) + int(k["prisoners"])
		runner.check(total == int(stats[side]["lost"]),
			"%s : tués + blessés + disparus + prisonniers = pertes du combat (%d = %d), volume inchangé" % [side, total, int(stats[side]["lost"])])
		runner.check(int(k["killed"]) > 0 and int(k["wounded"]) > int(k["killed"]), "%s : tués et blessés ventilés" % side)
	for nid: String in ["france", "german_empire"]:
		_conserved(s, nid, "après la bataille")
		var sum := MobilizationSystem.summary(s.state, nid)
		var w: Dictionary = sum["wounded"]
		runner.check(int(sum["losses_total"]) == int(sum["killed"]) + int(w["convalescing"]) + int(w["long_term"]) + int(w["unfit"]) + int(sum["missing"]) + int(sum["prisoners_lost"]),
			"%s : catégories mutuellement exclusives, sommées une seule fois" % nid)


# 2, 8, 9. Tués ; disparus ; prisonniers (calcul unitaire exact, paramètres du bloc `casualties`).
# Signature : feu, déroute, reliquat d'unité anéantie, issue, unité survivante.
func test_unit_breakdown_rules() -> void:
	var s := _session()
	var r := ForceLedger.book_battle_losses(s.state, "france", "german_empire", 1000, 0, 0, "won", true, "region_011")
	runner.check(int(r["killed"]) == 250 and int(r["missing"]) == 50 and int(r["wounded"]) == 700 and int(r["prisoners"]) == 0,
		"pertes au feu : 25 % tués, 5 % disparus, 70 % blessés (paramètres provisoires)")
	runner.check(int(r["remained"]) == 48, "blessés légers restés dans l'unité : 10 % des 480 légers (68,6 % des blessés)")
	var retreat := ForceLedger.book_battle_losses(s.state, "france", "german_empire", 0, 1000, 0, "lost_retreat", true, "region_011")
	runner.check(int(retreat["prisoners"]) == 300 and int(retreat["missing"]) == 700 and int(retreat["killed"]) == 0,
		"déroute d'un camp vaincu avec retraite : 30 % de prisonniers, 70 % de disparus")
	var collapse := ForceLedger.book_battle_losses(s.state, "france", "german_empire", 0, 1000, 0, "lost_no_retreat", true, "region_011")
	runner.check(int(collapse["prisoners"]) == 800 and int(collapse["missing"]) == 200, "effondrement (sans retraite) : 80 % de prisonniers")
	var fr := MobilizationSystem.summary(s.state, "france")
	var de := MobilizationSystem.summary(s.state, "german_empire")
	runner.check(int(fr["prisoners_lost"]) == 1100 and int(de["prisoners_held"]) == 1100, "prisonniers chez l'origine et chez le détenteur")
	runner.check(int(de["present_in_units"]) == int(MobilizationSystem.summary(_session().state, "german_empire")["present_in_units"]),
		"les prisonniers ne s'ajoutent jamais aux présents du détenteur")
	runner.check(int(fr["missing"]) == 50 + 700 + 200, "disparus : catégorie distincte, cumulée sans conversion")


# Correction A : déroute d'un camp vainqueur = pertes ordinaires ; origine conservée ; aucune capture.
func test_winner_routing_booked_as_ordinary() -> void:
	var s := _session()
	var r := ForceLedger.book_battle_losses(s.state, "france", "german_empire", 0, 1000, 0, "won", true, "region_011")
	runner.check(int(r["killed"]) == 250 and int(r["missing"]) == 50 and int(r["wounded"]) == 700 and int(r["prisoners"]) == 0,
		"déroute du vainqueur : 25 % tués, 5 % disparus, 70 % blessés, aucun prisonnier (au lieu de 100 % de disparus)")
	runner.check(int(r["origin_routing"]) == 1000 and int(r["routing_as_ordinary"]) == 1000 and int(r["origin_fire"]) == 0,
		"origine conservée : 1 000 pertes de déroute, inscrites comme telles (non converties en pertes au feu)")
	var o: Dictionary = ForceLedger.ledger(s.state, "france")["losses_by_origin"]
	runner.check(int(o["routing"]) == 1000 and int(o["fire"]) == 0 and int(o["routing_as_ordinary"]) == 1000, "registre national : origine des pertes tracée")
	var ind := ForceLedger.book_battle_losses(s.state, "france", "german_empire", 0, 1000, 0, "indecisive", true, "region_011")
	runner.check(int(ind["prisoners"]) == 0 and int(ind["missing"]) == 1000 and int(ind["routing_as_ordinary"]) == 0,
		"issue indécise : aucune capture ; traitement inchangé (question ouverte au directeur)")


# Unités réellement anéanties : traitement distinct (reliquat), capture seulement en cas de défaite.
func test_annihilated_unit_remnant() -> void:
	var s := _session()
	var w := ForceLedger.book_battle_losses(s.state, "france", "german_empire", 0, 0, 1000, "won", false, "region_011")
	runner.check(int(w["missing"]) == 1000 and int(w["prisoners"]) == 0 and int(w["remained"]) == 0 and int(w["origin_remnant"]) == 1000,
		"unité anéantie d'un camp vainqueur : reliquat disparu, aucun prisonnier, personne ne « reste dans l'unité »")
	var l := ForceLedger.book_battle_losses(s.state, "france", "german_empire", 0, 0, 1000, "lost_no_retreat", false, "region_011")
	runner.check(int(l["prisoners"]) == 800 and int(l["missing"]) == 200, "unité anéantie d'un camp effondré : capture (80 %)")
	var c: Dictionary = ForceLedger.cfg()["annihilated_unit_routing_as_ordinary"]
	var dr := ForceLedger.book_battle_losses(s.state, "france", "german_empire", 0, 1000, 0, "won", false, "region_011")
	runner.check(bool(c["value"]) and int(dr["routing_as_ordinary"]) == 1000 and int(dr["remained"]) == 0,
		"unité anéantie d'un vainqueur : déroute ordinaire (paramètre à valider), aucun blessé resté dans l'unité")
	c["value"] = false
	var dr2 := ForceLedger.book_battle_losses(s.state, "france", "german_empire", 0, 1000, 0, "won", false, "region_011")
	c["value"] = true
	runner.check(int(dr2["missing"]) == 1000 and int(dr2["prisoners"]) == 0 and int(dr2["routing_as_ordinary"]) == 0,
		"paramètre désactivé : déroute d'une unité anéantie disparue, sans capture inventée")
	var mix := ForceLedger.book_battle_losses(s.state, "france", "german_empire", 500, 300, 200, "won", false, "region_011")
	runner.check(int(mix["killed"]) + int(mix["wounded"]) + int(mix["missing"]) + int(mix["prisoners"]) == 1000 and int(mix["remained"]) == 0,
		"feu, déroute et reliquat : somme exacte, aucun soldat créé ni perdu")


# 3. Blessés légers restés dans leur unité : présents, jamais en convalescence en même temps.
func test_light_wounded_remain_in_unit_not_double_counted() -> void:
	var s := _session()
	var b := _lorraine(s)
	var fr := MobilizationSystem.summary(s.state, "france")
	var w: Dictionary = fr["wounded"]
	runner.check(int(w["remained_in_unit"]) > 0, "des blessés légers restent dans leur unité (%d)" % int(w["remained_in_unit"]))
	var conv := 0
	for c: Dictionary in ForceLedger.ledger(s.state, "france")["convalescence"]:
		conv += int(c["soldiers"])
	runner.check(conv == int(w["convalescing"]), "convalescence = somme des cohortes")
	runner.check(int(w["convalescing"]) + int(w["remained_in_unit"]) == int(b["casualty_breakdown"]["defenders"]["wounded"]),
		"blessés = convalescents + restés dans l'unité, sans recouvrement")
	_conserved(s, "france", "blessés légers restés")


# 4, 5, 6, 7. Convalescence ; retours à un et trois mois ; inaptes ; longue durée.
func test_convalescence_and_returns() -> void:
	var s := _session()
	var st := s.state
	var t0 := st.turn
	# Comme à la clôture d'une bataille : 1 000 hommes quittent réellement une unité, puis sont ventilés.
	var unit := ""
	for fid: String in st.sorted_formation_ids():
		if st.formations[fid]["nation"] == "france" and st.formations[fid]["echelon"] == "unit" and st.formations[fid]["region"] == "region_011":
			unit = fid
			break
	st.formations[unit]["soldiers"] = int(st.formations[unit]["soldiers"]) - 1000
	var booked := ForceLedger.book_battle_losses(st, "france", "german_empire", 1000, 0, 0, "won", true, "region_011")
	st.formations[unit]["soldiers"] = int(st.formations[unit]["soldiers"]) + int(booked["remained"])
	var l := ForceLedger.ledger(st, "france")
	runner.check(int(l["wounded"]["convalescing"]) == 652, "652 blessés en convalescence (432 légers, 220 autres)")
	var kinds := {}
	for c: Dictionary in l["convalescence"]:
		kinds[c["kind"]] = int(c["return_turn"]) - t0
	runner.check(kinds.get("light") == 1 and kinds.get("other") == 3, "échéances : 1 mois (légers), 3 mois (autres)")
	var present0 := _present(s, "france")
	var incorporated0 := int(st.nations["france"]["forces"]["incorporated"])
	_conserved(s, "france", "convalescence")
	st.turn = t0 + 1
	ForceLedger.monthly_recovery(st, s.world, s.rules["forces"])
	runner.check(int(l["wounded"]["returned"]) == 240 and _present(s, "france") == present0 + 240,
		"après un mois : 240 légers guéris (55,6 %) redeviennent présents")
	runner.check(int(l["wounded"]["unfit"]) == 73 and int(l["wounded"]["long_term"]) == 432 - 240 - 73, "inaptes 17 % ; le reste en convalescence de longue durée")
	runner.check(int(st.nations["france"]["forces"]["incorporated"]) == incorporated0, "un blessé rendu n'est pas compté comme un nouveau soldat incorporé")
	_conserved(s, "france", "après un mois")
	st.turn = t0 + 2
	ForceLedger.monthly_recovery(st, s.world, s.rules["forces"])
	runner.check(int(l["wounded"]["returned"]) == 240, "deux mois : les blessés plus graves sont encore en convalescence")
	st.turn = t0 + 3
	ForceLedger.monthly_recovery(st, s.world, s.rules["forces"])
	runner.check(int(l["wounded"]["returned"]) == 240 + 122 and int(l["wounded"]["unfit"]) == 73 + 37, "après trois mois : 122 retours et 37 inaptes de plus")
	runner.check((l["convalescence"] as Array).is_empty() and int(l["wounded"]["convalescing"]) == 0, "cohortes soldées")
	_conserved(s, "france", "après trois mois")
	st.turn = t0 + 12
	ForceLedger.monthly_recovery(st, s.world, s.rules["forces"])
	runner.check(int(l["wounded"]["unfit"]) == 110 and int(l["missing_total"]) == 50, "inaptes et disparus définitifs : aucune conversion ultérieure")
	# Convalescence de longue durée : ni délai de retour, ni inaptitude, comptée hors des rangs.
	var long_term := int(l["wounded"]["long_term"])
	runner.check(long_term == 652 - 362 - 110, "convalescence de longue durée : les 27 %% restants (%d)" % long_term)
	st.turn = t0 + 60
	ForceLedger.monthly_recovery(st, s.world, s.rules["forces"])
	runner.check(int(l["wounded"]["long_term"]) == long_term and int(l["wounded"]["unfit"]) == 110 and int(l["wounded"]["returned"]) == 362,
		"cinq ans plus tard : aucun retour ni inaptitude inventés pour la longue durée")
	runner.check(int(MobilizationSystem.summary(st, "france")["wounded"]["long_term"]) == long_term, "longue durée comptée dans les effectifs nationaux hors des rangs")
	_conserved(s, "france", "longue durée")


# Taux de retour par pays : britannique sourcé, approximation ailleurs, dérogation possible.
func test_national_return_rates() -> void:
	var s := _session()
	var c: Dictionary = s.rules["forces"]["casualties"]
	runner.check(c["national_overrides"]["united_kingdom"]["return_share"]["status"] == "sourcé", "Royaume-Uni : taux de retour sourcé (WO 1922 p. 246)")
	runner.check(str(c["return_share"]["status"]).contains("approximation"), "autres puissances : approximation britannique signalée")
	c["national_overrides"]["france"] = {"return_share": {"value": 0.5, "status": "test", "note": "test"}}
	runner.check(is_equal_approx(ForceLedger.param("france", "return_share"), 0.5) and is_equal_approx(ForceLedger.param("italy", "return_share"), 0.556),
		"dérogation nationale prise en compte, les autres pays inchangés")
	c["national_overrides"].erase("france")


# 12. Mobilisation et renforts pendant la convalescence.
func test_mobilization_during_convalescence() -> void:
	var s := _session()
	var b := _lorraine(s)
	MobilizationSystem.set_posture(s.state, s.rules["forces"]["mobilization"], "france", "generale")
	for i in 4:
		s.end_turn()
	var fr := MobilizationSystem.summary(s.state, "france")
	runner.check(int(fr["incorporated"]) > 0 and int(fr["wounded"]["returned"]) > 0, "mobilisation et retours de blessés coexistent")
	_conserved(s, "france", "mobilisation + convalescence")
	_conserved(s, "german_empire", "après quatre mois")


# 13, 14. Retraites, encerclements (attrition = disparus) et capitulation (prisonniers).
func test_encirclement_and_surrender_categories() -> void:
	var s := _session("united_kingdom")
	var st := s.state
	var army := "army_france_region_011"
	for n: String in s.world.neighbor_ids("region_011", true):
		st.regions[n]["controller"] = "german_empire"
	st.regions["region_011"]["controller"] = "german_empire"
	st.formations[army]["encircled"] = true
	st.formations[army]["morale"] = 0.0
	BattleManager.monthly_encirclement(st, s.world, s.rules["combat"])
	var fr := MobilizationSystem.summary(st, "france")
	runner.check(int(fr["missing_by_cause"]["encirclement_attrition"]) > 0 and int(fr["killed"]) == 0, "attrition d'encerclement : disparus (sort inconnu), pas de tués inventés")
	runner.check(int(fr["prisoners_lost"]) > 0, "capitulation : prisonniers")
	_conserved(s, "france", "encerclement et capitulation")
	var s2 := _session()
	_lorraine(s2)
	_conserved(s2, "german_empire", "après retraite")


# Batailles réelles : vainqueur (déroute ordinaire) et vaincu (captures partielles) ; origines tracées.
func test_battle_winner_and_loser_routing() -> void:
	for case: Array in [["german_empire", "army_german_empire_region_035", "region_011", "france"],
			["italy", "army_italy_region_081", "region_037", "austria_hungary"]]:
		var s := _session()
		s.state.wars.append({"id": "w", "a": case[0], "b": case[3], "since_turn": 0})
		TurnResolver.resolve(s.state, s.world, s.rules, {case[0]: [Orders.move(case[0], case[1], case[2])]})
		var b: Dictionary = s.state.battles[-1]
		var winner: String = b["result"]["winner"]
		runner.check(winner != "", "%s : bataille décisive (%s)" % [case[2], winner])
		var w: Dictionary = b["casualty_breakdown"][winner]
		var lo: Dictionary = b["casualty_breakdown"][CombatData.other(winner)]
		for k: Dictionary in [w, lo]:
			runner.check(int(k["origin_fire"]) + int(k["origin_routing"]) + int(k["origin_remnant"]) == int(k["killed"]) + int(k["wounded"]) + int(k["missing"]) + int(k["prisoners"]),
				"%s : origines (feu, déroute, reliquat) = catégories, volume inchangé" % case[2])
		runner.check(int(w["origin_routing"]) > 0 and int(w["routing_as_ordinary"]) == int(w["origin_routing"]) and int(w["prisoners"]) == 0,
			"%s : vainqueur — %d pertes de déroute ventilées comme ordinaires, aucun prisonnier" % [case[2], int(w["origin_routing"])])
		var wtot := int(w["killed"]) + int(w["wounded"]) + int(w["missing"])
		runner.check(float(w["missing"]) <= 0.05 * float(wtot) + float(w["origin_remnant"]) + 1.0,
			"%s : vainqueur — disparus limités aux 5 %% ordinaires et aux unités anéanties (%d sur %d)" % [case[2], int(w["missing"]), wtot])
		var rout_lo := int(lo["origin_routing"]) + int(lo["origin_remnant"])
		runner.check(int(lo["routing_as_ordinary"]) == 0 and int(lo["prisoners"]) > 0 and int(lo["prisoners"]) < rout_lo,
			"%s : vaincu — captures partielles seulement (%d prisonniers sur %d pertes de déroute)" % [case[2], int(lo["prisoners"]), rout_lo])
		for nid: String in [case[0], case[3]]:
			_conserved(s, nid, "%s, après la bataille" % case[2])


# 15. Sauvegarde et chargement avec cohortes de convalescence.
func test_save_load_with_convalescence() -> void:
	var s := _session()
	_lorraine(s)
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/casualties_v4.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde (format 4)")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error") and (loaded["state"] as GameState).checksum() == s.state.checksum(), "rechargement identique")
	var r := GameSession.create()
	r.state = loaded["state"]
	for i in 3:
		s.end_turn()
		r.end_turn()
	runner.check(r.state.checksum() == s.state.checksum(), "partie rechargée et originale évoluent à l'identique (retours compris)")
	_conserved(r, "france", "après rechargement et retours")


# 16. Ancienne sauvegarde (format 3, pertes non ventilées) : migration sûre et conservation.
func test_old_save_migration() -> void:
	var s := _session()
	var st := s.state
	# Registre de format 3 cohérent : 5 000 pertes non ventilées et 700 d'attrition retirées d'unités.
	var u1 := ""
	for fid: String in st.sorted_formation_ids():
		if st.formations[fid]["nation"] == "france" and st.formations[fid]["echelon"] == "unit" and int(st.formations[fid]["soldiers"]) > 6000:
			u1 = fid
			break
	st.formations[u1]["soldiers"] = int(st.formations[u1]["soldiers"]) - 5700
	st.nations["france"]["military_ledger"] = {"losses": {"combat": 5000, "encirclement_attrition": 700, "annihilated_services": 0},
		"losses_total": 5700, "dead": null, "wounded": null, "missing": null, "rejoined": 0, "prisoners_lost": 0,
		"prisoners_lost_by_captor": {}, "prisoners_held": 0, "prisoners_held_by_origin": {}, "released": 0, "repatriated": 0}
	var env := SaveRepository.envelope(st, s.world, s.rules)
	env["format_version"] = 3
	var d: Dictionary = env["state"]
	d["format_version"] = 3
	env["state_sha256"] = JSON.stringify(JSON.parse_string(JSON.stringify(d, "", true, true)), "", true, true).sha256_text()
	var f := FileAccess.open("user://test_saves/v3.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(env))
	f.close()
	var loaded := SaveRepository.load_save("user://test_saves/v3.json", s.world, s.rules)
	runner.check(not loaded.has("error") and int(loaded.get("migrated_from", 0)) == 3, "sauvegarde de format 3 migrée (%s)" % str(loaded.get("error", "")))
	var st2: GameState = loaded["state"]
	var l: Dictionary = st2.nations["france"]["military_ledger"]
	runner.check(int(l["legacy_unventilated"]) == 5000 and int(l["missing"]["encirclement_attrition"]) == 700 and int(l["killed"]) == 0,
		"pertes anciennes conservées sans ventilation après coup ; attrition en disparus")
	var r := GameSession.create()
	r.state = st2
	_conserved(r, "france", "après migration")
	var bad := SaveRepository.envelope(st, s.world, s.rules)
	bad["format_version"] = 3
	bad["state_sha256"] = "0"
	f = FileAccess.open("user://test_saves/v3_bad.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(bad))
	f.close()
	runner.check(SaveRepository.load_save("user://test_saves/v3_bad.json", s.world, s.rules).has("error"), "format 3 altéré : refusé (intégrité contrôlée avant migration)")


# Supplémentaires : déterminisme ; bac à sable (forces fictives) sans retour ; règles de combat intactes.
func test_determinism_and_sandbox() -> void:
	var a := _session()
	var b := _session()
	runner.check(JSON.stringify(_lorraine(a)["casualty_breakdown"]) == JSON.stringify(_lorraine(b)["casualty_breakdown"]), "ventilation déterministe")
	var sb := GameSession.create()
	sb.new_game("france", 1, 1914, "sandbox_fictif")
	ForceLedger.book_battle_losses(sb.state, "france", "german_empire", 1000, 0, 0, "won", true, "region_011")
	sb.state.turn += 3
	ForceLedger.monthly_recovery(sb.state, sb.world, sb.rules["forces"])
	runner.check(int(ForceLedger.ledger(sb.state, "france")["wounded"]["returned"]) == 0, "bac à sable : aucune réserve modélisée, les convalescents ne sont pas rendus (documenté)")
	runner.check(not (a.rules["combat"] as Dictionary).has("casualties"), "paramètres de ventilation hors des règles de combat")
