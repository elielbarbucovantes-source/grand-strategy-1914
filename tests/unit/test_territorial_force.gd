extends RefCounted
## MIL-01 phase 4 : Territorial Force britannique (T-050, T-054). Catégorie distincte, incorporation
## propre, service intérieur, volontariat outre-mer, conservation, absence de double comptage,
## sauvegarde, comportement de l'IA.

var runner: Object

const UK := "united_kingdom"


func _session(player: String = UK) -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, 1914)
	return s


func _tf(s: GameSession) -> Dictionary:
	return MobilizationSystem.summary(s.state, UK)["territorial_force"]


func _conserved(s: GameSession, label: String) -> void:
	var c := MobilizationSystem.conservation(s.state, UK)
	runner.check(c["territorial_ok"], "%s : Territorial Force, non incorporés + en cours + bloqués + incorporés = 268 777" % label)
	runner.check(c["reserves_ok"] and c["personnel_ok"], "%s : réserves et personnel conservés (%d / %d)" % [label, int(c["personnel_lhs"]), int(c["personnel_rhs"])])


func _tf_armies(s: GameSession, service: String) -> Array:
	var out: Array = []
	for f: Dictionary in s.state.formations_of(UK):
		if s.state.is_top_level(f) and TerritorialForce.is_territorial(f) and f.get("service", "home") == service:
			out.append(f["id"])
	return out


func test_distinct_category_in_data_and_scenario() -> void:
	var s := _session()
	var f: Dictionary = s.state.nations[UK]["forces"]
	var tf: Dictionary = f["territorial_force"]
	runner.check(int(tf["pool_initial"]) == 268777, "effectif propre : 268 777 (WO 1922 p. 30)")
	runner.check(int(f["reserve_pool_initial"]) == 145347 + 63933 and int(f["active_start"]) == 247432,
		"réserves (Army Reserve + Special Reserve) et armée régulière inchangées : aucune confusion")
	var by := 0
	for rid: String in tf["pool_by_region"]:
		by += int(tf["pool_by_region"][rid])
		runner.check(rid in ["region_001", "region_002", "region_003", "region_004"], "%s : région de Grande-Bretagne (aucune division en Irlande)" % rid)
	runner.check(by == 268777, "répartition par région exacte")
	for e: Dictionary in f["echelons"]:
		runner.check(int(e["pool_initial"]) == 209280, "le réservoir (échelons) n'inclut pas la Territorial Force")
	for nid: String in ["france", "german_empire", "russian_empire", "austria_hungary", "italy", "ottoman_empire"]:
		runner.check(s.state.nations[nid]["forces"].get("territorial_force") == null, "%s : pas de Territorial Force" % nid)
	runner.check(_tf(s)["present_home"] == 0 and not bool(_tf(s)["embodied"]), "au départ : aucune unité territoriale présente (force non incorporée)")


func test_embodiment_only_with_general_posture() -> void:
	var s := _session()
	var mr: Dictionary = s.rules["forces"]["mobilization"]
	MobilizationSystem.set_posture(s.state, mr, UK, "preparatoire")
	MobilizationSystem.monthly(s.state, s.world, s.rules["forces"])
	runner.check(int(_tf(s)["pool"]) == 268777, "posture préparatoire : Territorial Force non incorporée")
	MobilizationSystem.set_posture(s.state, mr, UK, "generale")
	MobilizationSystem.monthly(s.state, s.world, s.rules["forces"])
	runner.check(int(_tf(s)["mobilizing"]) == 268777 and int(_tf(s)["present_home"]) == 0, "posture générale : appel intégral, aucune apparition instantanée")
	_conserved(s, "pendant l'incorporation")
	s.state.turn += 1
	MobilizationSystem.monthly(s.state, s.world, s.rules["forces"])
	var t := _tf(s)
	runner.check(int(t["incorporated"]) == 268777 and int(t["present_home"]) + int(t["services"]) == 268777,
		"un mois plus tard : 268 777 incorporés (unités + services), en service intérieur")
	for aid: String in _tf_armies(s, "home"):
		for uid: String in s.state.units_of(aid):
			runner.check(TerritorialForce.is_territorial(s.state.formations[uid]) and s.state.formations[uid]["service"] == "home",
				"%s : unité territoriale distincte, service intérieur" % uid)
	_conserved(s, "après incorporation")


func test_no_double_counting_after_full_mobilization() -> void:
	var s := _session()
	MobilizationSystem.set_posture(s.state, s.rules["forces"]["mobilization"], UK, "generale")
	for i in 5:
		MobilizationSystem.monthly(s.state, s.world, s.rules["forces"])
		s.state.turn += 1
	var sum := MobilizationSystem.summary(s.state, UK)
	var present := int(sum["present_in_units"]) + int(sum["present_services"])
	runner.check(present == 126309 + 209280 + 268777,
		"présents = actifs sur la carte (126 309) + réservistes (209 280) + Territorial Force (268 777), sans double comptage (%d)" % present)
	runner.check(int(sum["incorporated"]) == 209280 and int(_tf(s)["incorporated"]) == 268777, "compteurs distincts : réservistes et Territorial Force")
	_conserved(s, "mobilisation complète")


func test_home_service_restriction_and_overseas_volunteers() -> void:
	var s := _session()
	var st := s.state
	MobilizationSystem.set_posture(st, s.rules["forces"]["mobilization"], UK, "generale")
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	st.turn += 1
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	# Autorisation de passage britannique en France : une armée régulière peut entrer, la Territorial Force non.
	st.treaties.append({"id": "t_transit_test", "type": "transit", "members": [UK, "france"], "grantor": "france", "grantee": UK, "status": "active"})
	var home := ""
	for aid: String in _tf_armies(s, "home"):
		if st.formations[aid]["region"] == "region_001":
			home = aid
	runner.check(home != "", "armée territoriale en Angleterre du Sud")
	var regular := "army_united_kingdom_region_001"
	runner.check(MilitarySystem.validate_move(st, s.world, s.rules, Orders.move(UK, regular, "region_007")) == "", "armée régulière : passage en France autorisé")
	runner.check(MilitarySystem.validate_move(st, s.world, s.rules, Orders.move(UK, home, "region_007")).contains("service intérieur"),
		"Territorial Force en service intérieur : départ à l'étranger refusé (T-054)")
	runner.check(MilitarySystem.validate_move(st, s.world, s.rules, Orders.move(UK, home, "region_002")) == "", "déplacement intérieur autorisé")
	# Volontariat : refusé avant le délai provisoire, accepté ensuite.
	var order := Orders.territorial_overseas(UK, home)
	runner.check(TerritorialForce.validate_overseas(st, s.rules["forces"], order).contains("délai"), "délai minimal depuis l'incorporation (provisoire)")
	runner.check(TerritorialForce.validate_overseas(st, s.rules["forces"], Orders.territorial_overseas(UK, regular)) != "", "une armée régulière n'est pas concernée")
	st.turn += 3
	var before := int(ForceLedger.personnel_of(st, home))
	runner.check(TerritorialForce.validate_overseas(st, s.rules["forces"], order) == "", "délai écoulé : volontariat possible")
	TerritorialForce.apply_overseas(st, s.rules["forces"], order)
	var abroad := _tf_armies(s, "overseas")
	runner.check(abroad.size() == 1 and int(_tf(s)["overseas_volunteers"]) > 0, "armée de volontaires outre-mer formée")
	runner.check(MilitarySystem.validate_move(st, s.world, s.rules, Orders.move(UK, abroad[0], "region_007")) == "", "volontaires : départ en France autorisé")
	runner.check(int(_tf(s)["present_overseas"]) == before, "tous les hommes de l'armée partis (part de volontaires provisoire 1,0), aucun créé ni perdu")
	_conserved(s, "après volontariat")


func test_partial_volunteering_splits_units() -> void:
	var s := _session()
	var st := s.state
	s.rules["forces"]["territorial_force"]["overseas_volunteer_share"]["value"] = 0.6
	MobilizationSystem.set_posture(st, s.rules["forces"]["mobilization"], UK, "generale")
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	st.turn += 1
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	st.turn += 3
	var home: String = _tf_armies(s, "home")[0]
	var total := int(ForceLedger.personnel_of(st, home))
	TerritorialForce.apply_overseas(st, s.rules["forces"], Orders.territorial_overseas(UK, home))
	var t := _tf(s)
	runner.check(int(t["present_overseas"]) > 0 and st.formations.has(home), "part de 0,6 : volontaires partis, les autres restent en service intérieur")
	runner.check(int(ForceLedger.personnel_of(st, home)) + int(t["present_overseas"]) == total, "scission sans perte ni création")
	_conserved(s, "après volontariat partiel")


func test_save_load_with_territorial_force() -> void:
	var s := _session()
	MobilizationSystem.set_posture(s.state, s.rules["forces"]["mobilization"], UK, "generale")
	s.end_turn()
	s.end_turn()
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/territorial_force.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde avec la Territorial Force")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error") and (loaded["state"] as GameState).checksum() == s.state.checksum(), "rechargement identique")
	var env := SaveRepository.envelope(s.state, s.world, s.rules)
	env["format_version"] = 2
	var f := FileAccess.open("user://test_saves/v2.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(env))
	f.close()
	var old := SaveRepository.load_save("user://test_saves/v2.json", s.world, s.rules)
	runner.check(old.has("error") and str(old["error"]).contains("Territorial Force"), "sauvegarde de version 2 refusée avec un message explicite")


func test_ai_united_kingdom_embodies_and_stays_home() -> void:
	var s := _session("france")
	s.state.wars.append({"id": "w_uk", "a": "german_empire", "b": UK, "since_turn": 0})
	for i in 4:
		s.end_turn()
	runner.check(s.state.nations[UK]["forces"]["posture"] == "generale" and bool(_tf(s)["embodied"]), "IA britannique en guerre : posture générale, Territorial Force incorporée")
	var refused := 0
	for h: Dictionary in s.state.orders_history:
		for r: Dictionary in h["rejected"]:
			if str(r["reason"]).contains("service intérieur"):
				refused += 1
	runner.check(refused == 0, "l'IA n'ordonne pas de départ à l'étranger pour la Territorial Force en service intérieur")
	for aid: String in _tf_armies(s, "home"):
		runner.check(s.state.sovereign(s.state.formations[aid]["region"]) == UK, "%s reste sur le territoire national" % aid)
	_conserved(s, "campagne conduite par l'IA")
