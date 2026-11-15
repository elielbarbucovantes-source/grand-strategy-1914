extends RefCounted
## Carte, scénario, calendrier, sauvegarde, déterminisme.

var runner: Object


func _session() -> GameSession:
	var s := GameSession.create()
	s.new_game("france", 1)
	return s


func test_world_loads_90_regions_and_graph() -> void:
	var w := WorldMap.load_from()
	runner.check(w != null, "carte chargée")
	runner.check(w.regions.size() == 90, "90 régions (%d)" % w.regions.size())
	var land := 0
	var strait := 0
	for rid: String in w.region_ids:
		for n: Dictionary in w.neighbors[rid]:
			if n["kind"] == "land":
				land += 1
			else:
				strait += 1
			runner.check(w.neighbor_ids(n["to"]).has(rid), "voisinage symétrique %s-%s" % [rid, n["to"]])
	runner.check(land / 2 == 184, "184 arêtes terrestres (%d)" % (land / 2))
	runner.check(strait / 2 == 10, "10 détroits inter-régionaux (%d)" % (strait / 2))
	runner.check(w.cities.size() == 175, "175 villes")
	runner.check(w.shortest_path("region_051", "region_003").is_empty(), "Islande (051) isolée du graphe jouable")
	runner.check(w.shortest_path("region_001", "region_007").size() == 2, "Douvres : 001 → 007 par détroit")
	runner.check(w.connection_kind("region_001", "region_007") == "strait", "type de connexion = détroit")


func test_new_game_territories_and_unknown_values() -> void:
	var s := _session()
	runner.check(s.state.nations.size() == 22, "22 États")
	runner.check(s.playable_nations().size() == 7, "7 puissances jouables (D-005)")
	for rid: String in s.world.region_ids:
		runner.check(s.state.sovereign(rid) == s.world.regions[rid]["initial_sovereign_id"], "souveraineté de départ = atlas (%s)" % rid)
		runner.check(not s.state.is_occupied(rid), "aucune occupation au départ")
	runner.check(s.state.regions_controlled_by("russian_empire").size() == 18, "Empire russe : 18 régions")
	runner.check(s.state.nations["france"]["stats"]["industrie"]["value"] == null, "statistique inconnue = null (NAT-01)")
	runner.check(s.state.soldiers_of("army_france_region_008") != null and int(s.state.soldiers_of("army_france_region_008")) > 0,
		"puissance jouable : effectifs historiques présents (MIL-01)")
	runner.check(s.state.formations["army_belgium_1"]["soldiers"] == null and s.state.soldiers_of("army_belgium_1") == null,
		"État hors MIL-01 : effectifs inconnus = null, rien n'est fabriqué")
	runner.check(s.state.month == 1 and s.state.year == 1914, "mois de départ paramétré")
	runner.check(s.scenario["start"]["month"] == 1, "campagne historique : janvier 1914 fixé dans le scénario (T-057)")
	var s2 := GameSession.create()
	runner.check(s2.new_game("france", 6) != "", "campagne historique : autre mois que janvier refusé (T-057)")
	runner.check(s2.new_game("france", 6, 1914, "sandbox_fictif") == "" and s2.state.date_label() == "juin 1914",
		"bac à sable : mois de départ librement configurable (T-057)")
	runner.check(s2.new_game("france", 13, 1914, "sandbox_fictif") != "", "mois invalide refusé")


func test_calendar_advances_monthly() -> void:
	runner.check(GameCalendar.next(1914, 12) == Vector2i(1915, 1), "décembre → janvier")
	var s := _session()
	s.end_turn()
	runner.check(s.state.date_label() == "février 1914" and s.state.turn == 1, "un tour = un mois")
	runner.check(s.state.orders_history.size() == 1, "historique des ordres conservé")


func test_save_load_roundtrip_and_integrity() -> void:
	var s := _session()
	s.queue_order(Orders.declare_war("france", "german_empire"))
	s.end_turn()
	s.end_turn()
	var path := "user://test_saves/roundtrip.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde écrite")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(loaded.has("state"), "sauvegarde relue : %s" % str(loaded.get("error", "")))
	if loaded.has("state"):
		var st: GameState = loaded["state"]
		runner.check(st.checksum() == s.state.checksum(), "état identique après rechargement (empreinte)")
		runner.check(st.at_war("france", "german_empire") and st.turn == 2, "guerre et date conservées")
	# Corruption : modification d'une valeur sans recalcul de l'empreinte.
	var text := FileAccess.get_file_as_string(path).replace("\"turn\":2", "\"turn\":3")
	var f := FileAccess.open("user://test_saves/corrupt.json", FileAccess.WRITE)
	f.store_string(text)
	f.close()
	var bad := SaveRepository.load_save("user://test_saves/corrupt.json", s.world, s.rules)
	runner.check(bad.has("error"), "sauvegarde corrompue détectée")
	var env: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	env["world_sha256"] = "autre_carte"
	f = FileAccess.open("user://test_saves/other_world.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(env))
	f.close()
	runner.check(SaveRepository.load_save("user://test_saves/other_world.json", s.world, s.rules).has("error"), "carte incompatible détectée")
	f = FileAccess.open("user://test_saves/truncated.json", FileAccess.WRITE)
	f.store_string(text.substr(0, 200))
	f.close()
	runner.check(SaveRepository.load_save("user://test_saves/truncated.json", s.world, s.rules).has("error"), "sauvegarde tronquée détectée")


func test_simulation_is_deterministic() -> void:
	var a := _session()
	var b := _session()
	for s: GameSession in [a, b]:
		s.queue_order(Orders.declare_war("france", "german_empire"))
	for i in 6:
		a.end_turn()
		b.end_turn()
	runner.check(a.state.checksum() == b.state.checksum(), "mêmes ordres → même état après 6 mois")
