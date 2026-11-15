extends RefCounted
## MIL-01 phase 2 : échelons (T-051, MIL01-P1-D1), postures et allocation (T-053, Q1, Q2), rythme
## national (T-049, Q7), information publique (T-056, Q3), communications et réservistes occupés
## (T-056 bis, Q4, Q5), batailles en cours (Q8), délai entre échelons (Q10), comptabilité des pertes
## et des prisonniers (Q6), sauvegardes (Q9), conservation et déterminisme.

var runner: Object

const PLAYABLE := ["austria_hungary", "france", "german_empire", "italy", "ottoman_empire", "russian_empire", "united_kingdom"]


func _session(player: String = "france") -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, 1914)
	return s


func _mr(s: GameSession) -> Dictionary:
	return s.rules["forces"]["mobilization"]


func _check_conservation(s: GameSession, nid: String, label: String) -> void:
	var c := MobilizationSystem.conservation(s.state, nid)
	runner.check(c["reserves_ok"], "%s : %s — réserves : non appelés + en cours + bloqués + incorporés = initial (%d / %d)" % [nid, label, int(c["reserves_lhs"]), int(c["reserves_rhs"])])
	runner.check(c["personnel_ok"], "%s : %s — personnel : présents + pertes + prisonniers = actifs + incorporés (%d / %d)" % [nid, label, int(c["personnel_lhs"]), int(c["personnel_rhs"])])


func _called(f: Dictionary, region: String = "") -> int:
	var n := 0
	for c: Dictionary in f["mobilizing"]:
		if region == "" or c["region"] == region:
			n += int(c["soldiers"])
	return n


# ------------------------------------------------------------------ données et échelons
func test_echelons_match_historical_database() -> void:
	var s := _session()
	var db := GameSession.load_json("res://data/history/military_forces_1914.json")
	for nid: String in PLAYABLE:
		var f: Dictionary = s.state.nations[nid]["forces"]
		var total := 0
		for e: Dictionary in f["echelons"]:
			total += int(e["pool_initial"])
			var by := 0
			for rid: String in e["pool_by_region"]:
				by += int(e["pool_by_region"][rid])
			runner.check(by == int(e["pool_initial"]), "%s/%s : répartition par district exacte" % [nid, e["id"]])
			runner.check(e["opened_turn"] == null, "%s/%s : aucun échelon ouvert au départ" % [nid, e["id"]])
		runner.check(total == int(f["reserve_pool_initial"]), "%s : échelons = réservoir sur la carte" % nid)
		var documented: Array = (db["nations"][nid]["mobilization_echelons"]["echelons"] as Array).filter(func(e: Dictionary) -> bool: return e["value"] != null)
		if documented.is_empty():
			runner.check(f["echelon_mode"] == "bloc_unique" and (f["echelons"] as Array).size() == 1 and not bool(f["echelons"][0]["documented"]),
				"%s : bloc unique, signalé non documenté (MIL01-P1-D1)" % nid)
			runner.check(str(f["echelon_status_fr"]).contains("APPROXIMATION NON DOCUMENTÉE"), "%s : approximation affichée" % nid)
		else:
			runner.check(f["echelon_mode"] == "documented" and (f["echelons"] as Array).size() == documented.size(),
				"%s : échelons documentés repris tels quels, aucun échelon introuvable créé" % nid)
			for i in documented.size():
				runner.check(int(f["echelons"][i]["pool_initial"]) == int(documented[i]["value"]), "%s/%s : valeur de la base" % [nid, documented[i]["id"]])
		runner.check(f["posture"] == "paix", "%s : posture de paix au départ" % nid)


func test_national_parameters_are_explicit() -> void:
	var s := _session()
	var np: Dictionary = _mr(s)["national_parameters"]
	for nid: String in PLAYABLE:
		runner.check(np.has(nid), "%s : paramètres nationaux présents (Q7)" % nid)
		for k: String in ["call_share_per_month", "transit_months", "administrative_capacity", "rail_gap_months", "detour_months"]:
			var p: Dictionary = np[nid][k]
			runner.check(p["status"] in ["dérivé", "PROVISOIRE"] and str(p["note"]) != "", "%s/%s : statut et justification explicites" % [nid, k])
	runner.check(np["german_empire"]["call_share_per_month"]["status"] == "dérivé", "Allemagne : rythme dérivé d'une source (repère allemand)")
	runner.check(np["france"]["call_share_per_month"]["status"] == "PROVISOIRE", "France : rythme provisoire (aucune source)")
	runner.check(not _mr(s)["postures"].has("acceleree"), "posture accélérée reportée (Q1)")


# ------------------------------------------------------------------ postures et rythme
func test_postures_and_national_rhythm() -> void:
	var s := _session()
	var st := s.state
	var mr := _mr(s)
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	runner.check(_called(st.nations["france"]["forces"]) == 0, "posture de paix : aucun appel")
	MobilizationSystem.set_posture(st, mr, "france", "preparatoire")
	MobilizationSystem.set_posture(st, mr, "german_empire", "generale")
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	var fr: Dictionary = st.nations["france"]["forces"]
	var de: Dictionary = st.nations["german_empire"]["forces"]
	var fr_initial := int(fr["echelons"][0]["pool_initial"])
	# France : 0,5 (provisoire) × 0,5 (préparatoire) × 1,02 (administration 34 %) ≈ 25,5 % du bloc.
	runner.check(_called(fr) > fr_initial / 5 and _called(fr) < fr_initial * 3 / 10, "préparatoire : environ un quart du bloc français en un mois")
	# Allemagne : repère « août 1914 » : premier échelon entier en un mois en posture générale.
	runner.check(_called(de) == int(de["echelons"][0]["pool_initial"]), "Allemagne, posture générale : premier échelon appelé en un mois (repère Bundesarchiv)")
	runner.check(de["echelons"][1]["opened_turn"] == null and _called(de) < int(de["reserve_pool_initial"]), "échelon suivant non appelé sans ordre")
	# Baisse de posture : arrêt des nouveaux appels, les cohortes en route continuent.
	MobilizationSystem.set_posture(st, mr, "france", "paix")
	var en_route := _called(fr)
	st.turn += 1
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	runner.check(int(fr["incorporated"]) + _called(fr) == en_route and int(fr["incorporated"]) > 0,
		"retour à la paix : aucun nouvel appel, cohortes en route incorporées (pas de démobilisation)")
	runner.check(MobilizationSystem.validate(st, Orders.mobilization_posture("france", "acceleree")) != "", "posture accélérée refusée (Q1)")
	_check_conservation(s, "france", "postures")
	_check_conservation(s, "german_empire", "postures")


func test_next_echelon_rules() -> void:
	var s := _session("german_empire")
	var st := s.state
	var mr := _mr(s)
	var o := Orders.call_next_echelon("german_empire")
	runner.check(MobilizationSystem.validate(st, o, s.world, mr) != "", "échelon suivant refusé en posture de paix")
	MobilizationSystem.set_posture(st, mr, "german_empire", "preparatoire")
	runner.check(MobilizationSystem.validate(st, o, s.world, mr).contains("générale"), "échelon suivant refusé en posture préparatoire")
	MobilizationSystem.set_posture(st, mr, "german_empire", "generale")
	runner.check(MobilizationSystem.validate(st, o, s.world, mr).contains("délai"), "délai minimal d'un mois (Q10)")
	st.turn += 1
	runner.check(MobilizationSystem.validate(st, o, s.world, mr).contains("entièrement appelé"), "premier échelon non épuisé : refus")
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	runner.check(MobilizationSystem.validate(st, o, s.world, mr) == "", "premier échelon appelé et délai écoulé : échelon suivant permis")
	MobilizationSystem.apply_order(st, s.world, mr, o)
	var de: Dictionary = st.nations["german_empire"]["forces"]
	runner.check(int(de["echelons"][1]["opened_turn"]) == st.turn, "échelon suivant ouvert")
	runner.check(MobilizationSystem.validate(st, o, s.world, mr).contains("aucun échelon suivant"), "aucun échelon au-delà des échelons documentés (résiduel introuvable)")
	st.turn += 1
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	runner.check(int(de["echelons"][1]["pool_by_region"].values().reduce(func(a: int, b: int) -> int: return a + b, 0)) < int(de["echelons"][1]["pool_initial"]),
		"échelon suivant effectivement appelé")
	var fr := _session("france")
	MobilizationSystem.set_posture(fr.state, mr, "france", "generale")
	fr.state.turn += 3
	for i in 3:
		MobilizationSystem.monthly(fr.state, fr.world, fr.rules["forces"])
	runner.check(MobilizationSystem.validate(fr.state, Orders.call_next_echelon("france"), fr.world, mr).contains("bloc unique"),
		"bloc unique : aucun sous-échelon (MIL01-P1-D1)")
	_check_conservation(s, "german_empire", "échelons")


func test_allocation_effects_without_cost() -> void:
	var mr := {}
	var results := {}
	for alloc: Array in [[34, 33, 33], [60, 30, 10], [10, 80, 10], [10, 10, 80]]:
		var s := _session()
		mr = _mr(s)
		var st := s.state
		runner.check(MobilizationSystem.validate(st, Orders.mobilization_allocation("france", alloc[0], alloc[1], alloc[2])) == "", "allocation %s valide" % str(alloc))
		MobilizationSystem.apply_order(st, s.world, mr, Orders.mobilization_allocation("france", alloc[0], alloc[1], alloc[2]))
		MobilizationSystem.set_posture(st, mr, "france", "generale")
		var budget_before: Variant = st.nations["france"].get("budget")
		MobilizationSystem.monthly(st, s.world, s.rules["forces"])
		var f: Dictionary = st.nations["france"]["forces"]
		var max_transit := 0
		for c: Dictionary in f["mobilizing"]:
			max_transit = maxi(max_transit, int(c["ready_turn"]) - st.turn)
		results[str(alloc)] = {"called": _called(f), "transit": max_transit}
		runner.check(st.nations["france"].get("budget") == budget_before, "aucun coût économique appliqué (Q1, Q2)")
		_check_conservation(s, "france", "allocation %s" % str(alloc))
	runner.check(int(results["[60, 30, 10]"]["called"]) > int(results["[34, 33, 33]"]["called"]), "administration : plus de réservistes appelés")
	runner.check(int(results["[10, 80, 10]"]["called"]) < int(results["[34, 33, 33]"]["called"]), "administration réduite : moins d'appelés")
	runner.check(int(results["[10, 10, 80]"]["transit"]) > int(results["[34, 33, 33]"]["transit"]), "chemins de fer < 15 % : transit allongé")
	runner.check(int(results["[10, 80, 10]"]["transit"]) == 1, "priorité aux chemins de fer : aucun délai supplémentaire (présence des liaisons seulement)")
	var st0 := _session().state
	runner.check(MobilizationSystem.validate(st0, Orders.mobilization_allocation("france", 50, 50, 10)) != "", "somme différente de 100 : refus")
	runner.check(MobilizationSystem.validate(st0, Orders.mobilization_allocation("france", 110, -5, -5)) != "", "valeur négative : refus")


# ------------------------------------------------------------------ information publique (T-056, Q3)
func test_public_information_without_volumes() -> void:
	var s := _session()
	var st := s.state
	runner.check(s.queue_order(Orders.mobilization_posture("france", "generale")) == "", "ordre de posture accepté")
	var view_before: Dictionary = IntelSystem.view_for(st, s.world, "german_empire")
	runner.check(view_before["public_mobilization"]["france"]["posture"] == "paix", "ordre secret : rien de public avant la résolution")
	s.end_turn()
	var view: Dictionary = IntelSystem.view_for(st, s.world, "german_empire")
	var pub: Dictionary = view["public_mobilization"]["france"]
	runner.check(pub["posture"] == "generale" and (pub["opened_echelons"] as Array).size() == 1, "posture et échelon ouvert publics pour l'Allemagne")
	runner.check(not JSON.stringify(pub).contains("soldiers") and not JSON.stringify(pub).contains("pool"), "aucun volume dans l'information publique")
	var seen := false
	var volume_leak := false
	for ev: Dictionary in st.events:
		if ev["category"] == "mobilisation publique" and (ev["nations"] as Array).has("german_empire"):
			seen = true
		if ev["category"] == "mobilisation" and str(ev["text"]).contains("rappelés") and (ev["nations"] as Array).has("german_empire"):
			volume_leak = true
	runner.check(seen, "événement public visible de toutes les puissances")
	runner.check(not volume_leak, "volumes appelés confidentiels (journal réservé au pays concerné)")
	runner.check(st.wars.is_empty(), "aucune pénalité ni conséquence diplomatique automatique (T-056)")


# ------------------------------------------------------------------ communications (T-056 bis, Q4, Q5)
func test_occupied_district_with_route_and_blocking() -> void:
	var s := _session()
	var st := s.state
	var mr := _mr(s)
	var f: Dictionary = st.nations["france"]["forces"]
	# 011 occupée, mais une voisine française reste reliée : appel possible, détour.
	st.regions["region_011"]["controller"] = "german_empire"
	var acc := LogisticsSystem.accessible_regions(st, s.world, "france")
	var dest := MobilizationSystem.communication(st, s.world, "france", "region_011", acc)
	runner.check(dest != "" and dest != "region_011" and st.controller(dest) == "france", "district occupé avec voie : incorporation dans une région française (%s)" % dest)
	MobilizationSystem.set_posture(st, mr, "france", "generale")
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	var c011: Dictionary = {}
	for c: Dictionary in f["mobilizing"]:
		if c["region"] == "region_011":
			c011 = c
	runner.check(not c011.is_empty() and c011["dest"] == dest, "réservistes de 011 appelés vers %s" % dest)
	runner.check(int(c011["ready_turn"]) - st.turn >= 2, "détour : délai supplémentaire")
	# La voie se ferme pendant le transit (tout le territoire, capitale comprise : toute région
	# française touche le Bassin parisien) : cohortes bloquées, sans perte.
	var saved: Dictionary = {}
	for rid: String in st.regions:
		if st.controller(rid) == "france":
			saved[rid] = true
			st.regions[rid]["controller"] = "german_empire"
	st.turn += 3
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	var blocked := 0
	for c: Dictionary in f["blocked"]:
		blocked += int(c["soldiers"])
	runner.check(blocked > 0, "voie coupée : réservistes en route bloqués")
	_check_conservation(s, "france", "blocage")
	# Libération : la voie réapparaît, les bloqués reprennent leur route puis sont incorporés.
	for rid: String in saved:
		st.regions[rid]["controller"] = "france"
	st.turn += 1
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	runner.check((f["blocked"] as Array).is_empty(), "libération : plus aucun réserviste bloqué")
	st.turn += 2
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	_check_conservation(s, "france", "après libération")


func test_allied_territory_route() -> void:
	# Q5 : district allemand 034 occupé, ainsi que ses voisines allemandes 031 et 033 ; la seule voie
	# terrestre passe par l'Autriche-Hongrie (038) vers la région allemande 030 (Double Alliance).
	var s := _session("german_empire")
	var st := s.state
	for rid: String in ["region_034", "region_031", "region_033"]:
		st.regions[rid]["controller"] = "france"
	var acc := LogisticsSystem.accessible_regions(st, s.world, "german_empire")
	var dest := MobilizationSystem.communication(st, s.world, "german_empire", "region_034", acc)
	runner.check(dest != "" and st.controller(dest) == "german_empire" and acc.has(dest),
		"voie terrestre par territoire allié (Autriche-Hongrie) jusqu'à %s" % dest)
	for t: Dictionary in st.treaties:
		if t["type"] == "alliance" and (t["members"] as Array).has("german_empire") and (t["members"] as Array).has("austria_hungary"):
			t["status"] = "broken"
	runner.check(MobilizationSystem.communication(st, s.world, "german_empire", "region_034", acc) == "",
		"sans alliance : territoire étranger infranchissable, aucune voie (district non mobilisable)")


# ------------------------------------------------------------------ batailles en cours (Q8)
func test_no_reserve_army_in_battle_region() -> void:
	var s := _session()
	var st := s.state
	var f: Dictionary = st.nations["france"]["forces"]
	st.active_battles.append({"id": "b_test", "region": "region_011", "status": "active"})
	f["mobilizing"].append({"region": "region_011", "dest": "region_011", "soldiers": 50000, "echelon": "bloc_unique", "ready_turn": st.turn})
	f["echelons"][0]["pool_by_region"]["region_011"] = int(f["echelons"][0]["pool_by_region"]["region_011"]) - 50000
	var before := st.formations.size()
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	runner.check(st.formations.size() == before and _called(f, "region_011") == 50000, "bataille en cours : incorporation reportée, aucune armée de réserve créée (Q8)")
	st.active_battles.clear()
	st.turn += 1
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	runner.check(_called(f, "region_011") == 0 and int(f["incorporated"]) >= 50000, "bataille terminée : incorporation effectuée")
	_check_conservation(s, "france", "report pour bataille")


# ------------------------------------------------------------------ pertes et prisonniers (Q6)
func test_war_losses_are_accounted() -> void:
	var s := _session()
	var st := s.state
	MobilizationSystem.set_posture(st, _mr(s), "france", "generale")
	MobilizationSystem.set_posture(st, _mr(s), "german_empire", "generale")
	s.queue_order(Orders.declare_war("france", "german_empire"))
	s.end_turn()
	s.end_turn()
	_check_conservation(s, "france", "après mobilisation")
	var fr_present0 := int(MobilizationSystem.summary(st, "france")["present_in_units"])
	var orders := {"german_empire": [Orders.move("german_empire", "army_german_empire_region_035", "region_011")]}
	TurnResolver.resolve(st, s.world, s.rules, orders)
	_check_conservation(s, "france", "bataille en cours")
	_check_conservation(s, "german_empire", "bataille en cours")
	s.auto_resolve_battle()
	for nid: String in ["france", "german_empire"]:
		_check_conservation(s, nid, "après la bataille")
		var sum := MobilizationSystem.summary(st, nid)
		runner.check(int(sum["losses_total"]) > 0 and sum["dead"] == null and sum["wounded"] == null,
			"%s : pertes inscrites, non ventilées (tués et blessés non modélisés : aucun ratio inventé)" % nid)
	var zero_units := 0
	for fid: String in st.formations:
		var u: Dictionary = st.formations[fid]
		if u["echelon"] == "unit" and u.get("soldiers") != null and int(u["soldiers"]) <= 0:
			zero_units += 1
	runner.check(zero_units == 0, "aucune unité détruite ne reste comptée comme opérationnelle")
	runner.check(int(MobilizationSystem.summary(st, "france")["present_in_units"]) != fr_present0, "les pertes modifient bien les présents")


func test_surrender_creates_prisoners_not_deaths() -> void:
	var s := _session()
	var st := s.state
	var army := "army_france_region_011"
	for n: String in s.world.neighbor_ids("region_011", true):
		st.regions[n]["controller"] = "german_empire"
	st.regions["region_011"]["controller"] = "german_empire"
	st.formations[army]["encircled"] = true
	st.formations[army]["morale"] = 0.0
	var people := int(ForceLedger.personnel_of(st, army))
	BattleManager.monthly_encirclement(st, s.world, s.rules["combat"])
	runner.check(not st.formations.has(army), "armée encerclée capitulée et retirée")
	var fr := MobilizationSystem.summary(st, "france")
	var de := MobilizationSystem.summary(st, "german_empire")
	var attrition := int(fr["losses"]["encirclement_attrition"])
	runner.check(int(fr["prisoners_lost"]) + attrition == people, "personnel de l'armée = prisonniers + attrition (services compris)")
	runner.check(int(fr["prisoners_lost"]) > 0 and int(de["prisoners_held"]) == int(fr["prisoners_lost"]), "prisonniers comptés chez l'origine et chez le détenteur")
	runner.check(int(fr["losses"]["combat"]) == 0, "les prisonniers ne sont pas des morts")
	_check_conservation(s, "france", "après capitulation")


func _strip_units(s: GameSession, army: String) -> void:
	# Simule la destruction de toutes les unités combattantes (pertes de combat inscrites).
	var st := s.state
	for uid: String in st.units_of(army):
		ForceLedger.add_losses(st, "france", int(st.formations[uid]["soldiers"]), "combat")
		st.remove_formation(uid)


func test_annihilated_army_survivors() -> void:
	# MIL01-P2-D2 : pertes, prisonniers et survivants ayant rejoint leur territoire sont distingués.
	var cr: Dictionary = {}
	# Cas 1 : retraite sûre disponible : les services rejoignent le territoire et restent présents.
	var s := _session()
	cr = s.rules["combat"]
	var army := "army_france_region_011"
	var services := int(ForceLedger.personnel_of(s.state, army)) - int(s.state.soldiers_of(army))
	runner.check(services > 0, "l'armée a des services non combattants (%d)" % services)
	_strip_units(s, army)
	var present_before := int(MobilizationSystem.summary(s.state, "france")["present_services"])
	BattleManager._dissolve_annihilated(s.state, s.world, cr, army, "region_011")
	var fr := MobilizationSystem.summary(s.state, "france")
	runner.check(not s.state.formations.has(army), "armée anéantie retirée")
	runner.check(int(fr["rejoined"]) == services and int(fr["present_services"]) == present_before,
		"retraite sûre : les survivants rejoignent leur territoire et restent présents")
	runner.check(int(fr["prisoners_lost"]) == 0 and int(fr["losses"]["annihilated_services"]) == 0, "ni prisonniers ni pertes pour les survivants rapatriés")
	_check_conservation(s, "france", "armée anéantie, survivants rapatriés")
	# Cas 2 : aucune retraite (région et voisines aux mains de l'ennemi) : sort inconnu, pertes, PAS prisonniers.
	var s2 := _session()
	for n: String in s2.world.neighbor_ids("region_011", true):
		s2.state.regions[n]["controller"] = "german_empire"
	s2.state.regions["region_011"]["controller"] = "german_empire"
	_strip_units(s2, army)
	BattleManager._dissolve_annihilated(s2.state, s2.world, cr, army, "region_011")
	var fr2 := MobilizationSystem.summary(s2.state, "france")
	runner.check(int(fr2["losses"]["annihilated_services"]) == services and int(fr2["prisoners_lost"]) == 0 and int(fr2["rejoined"]) == 0,
		"sans retraite ni capture établie : survivants comptés en pertes (disparus), jamais en prisonniers")
	_check_conservation(s2, "france", "armée anéantie sans retraite")


# ------------------------------------------------------------------ sauvegarde et déterminisme
func _scripted_campaign(order_variant: int) -> GameSession:
	var s := _session()
	var a := [Orders.mobilization_posture("france", "generale"), Orders.mobilization_allocation("france", 50, 30, 20), Orders.declare_war("france", "german_empire")]
	if order_variant == 1:
		a.reverse()
	for o: Dictionary in a:
		s.queue_order(o)
	MobilizationSystem.set_posture(s.state, _mr(s), "german_empire", "generale")
	s.end_turn()
	s.state.regions["region_011"]["controller"] = "german_empire"
	for i in 3:
		s.end_turn()
	return s


func test_save_load_and_determinism() -> void:
	var s1 := _scripted_campaign(0)
	var s2 := _scripted_campaign(0)
	var s3 := _scripted_campaign(1)
	runner.check(s1.state.checksum() == s2.state.checksum(), "déterminisme : deux exécutions identiques")
	# Le journal suit l'ordre de saisie ; l'état militaire et territorial n'en dépend pas.
	var military := func(st: GameState) -> String:
		return JSON.stringify([st.nations, st.formations, st.regions, st.wars])
	runner.check(military.call(s1.state) == military.call(s3.state), "état militaire indépendant de l'ordre de saisie des ordres")
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/mobilization_phase2.json"
	runner.check(SaveRepository.save(path, s1.state, s1.world, s1.rules) == "", "sauvegarde pendant la mobilisation par échelons")
	var loaded := SaveRepository.load_save(path, s1.world, s1.rules)
	runner.check(not loaded.has("error"), "rechargement intègre")
	var st2: GameState = loaded["state"]
	runner.check(st2.checksum() == s1.state.checksum(), "empreinte identique après rechargement")
	var r := GameSession.create()
	r.state = st2
	for i in 2:
		s1.end_turn()
		r.end_turn()
	runner.check(r.state.checksum() == s1.state.checksum(), "partie rechargée et originale évoluent à l'identique")
	_check_conservation(r, "france", "après rechargement")
	# Ancien format (version 1) : refus explicite (migration non fiable, Q9).
	var env := SaveRepository.envelope(s1.state, s1.world, s1.rules)
	env["format_version"] = 1
	var f := FileAccess.open("user://test_saves/v1.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(env))
	f.close()
	var old := SaveRepository.load_save("user://test_saves/v1.json", s1.world, s1.rules)
	runner.check(old.has("error") and str(old["error"]).contains("migration"), "sauvegarde version 1 refusée avec un message explicite")


func test_full_mobilization_conservation_all_powers() -> void:
	var s := _session()
	var st := s.state
	var mr := _mr(s)
	for nid: String in PLAYABLE:
		MobilizationSystem.set_posture(st, mr, nid, "generale")
	for m in 8:
		MobilizationSystem.monthly(st, s.world, s.rules["forces"])
		for nid: String in PLAYABLE:
			var o := Orders.call_next_echelon(nid)
			if MobilizationSystem.validate(st, o, s.world, mr) == "":
				MobilizationSystem.apply_order(st, s.world, mr, o)
		st.turn += 1
	for nid: String in PLAYABLE:
		_check_conservation(s, nid, "mobilisation complète")
		var sum := MobilizationSystem.summary(st, nid)
		runner.check(int(sum["reserve_pool"]) == 0 and int(sum["mobilizing"]) == 0 and int(sum["incorporated"]) == int(sum["reserve_pool_initial"]),
			"%s : réservoir entièrement incorporé, jamais dépassé" % nid)
	runner.check(int(MobilizationSystem.summary(st, "german_empire")["present_in_units"]) + int(MobilizationSystem.summary(st, "german_empire")["present_services"]) == 4610000,
		"Allemagne : 4 610 000 présents après les deux échelons (total de la source, lecture provisoire)")
