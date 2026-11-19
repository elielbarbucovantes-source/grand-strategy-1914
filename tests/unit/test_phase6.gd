extends RefCounted
## Phase VI — technologie, communications/interception/décryptage, aviation et marine.

var runner: Object


func _session(player: String = "france") -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, 1914)
	return s


# ------------------------------------------------------------------ technologie
func test_tree_and_prerequisites() -> void:
	var s := _session()
	var t: TechSystem = s.tech_tree
	runner.check(t.by_id.size() >= 25, "arbre chargé (%d technologies)" % t.by_id.size())
	runner.check(TechSystem.can_research(s.state, t, "france", "float_plane") != "", "technologie inconnue refusée")
	runner.check(TechSystem.can_research(s.state, t, "france", "electrification") == "", "technologie de base accessible")
	runner.check(TechSystem.can_research(s.state, t, "france", "wireless_intercept") != "", "prérequis exigé")
	TechSystem.ensure(s.state, "france")
	(s.state.tech["known"]["france"] as Array).append("telephone_networks")
	runner.check(TechSystem.can_research(s.state, t, "france", "field_radio") == "", "prérequis rempli")


func test_research_costs_and_progress() -> void:
	var s := _session("german_empire")
	for r: String in ["coal", "iron"]:
		s.state.economy["stocks"]["german_empire"][r] = 200.0
	TechSystem.ensure(s.state, "german_empire")
	runner.check(TechSystem.start_project(s.state, "german_empire", "electrification") == "", "projet lancé")
	var before := float(s.state.economy["stocks"]["german_empire"]["coal"])
	for i in 8:
		TechSystem.monthly(s.state, s.tech_tree, s.rules["phase6"])
	runner.check(float(s.state.economy["stocks"]["german_empire"]["coal"]) < before, "recherche consomme des ressources")
	runner.check(TechSystem.known(s.state, "german_empire", "electrification"), "découverte obtenue")


func test_unequal_progress_and_diffusion() -> void:
	var s := _session()
	for nid: String in ["german_empire", "france"]:
		TechSystem.ensure(s.state, nid)
	(s.state.tech["known"]["german_empire"] as Array).append("steel_alloys")
	runner.check(not TechSystem.known(s.state, "france", "steel_alloys"), "progression inégale")
	# Diffusion par accord : une technologie connue peut être transférée avec coût.
	var cost := float(s.tech_tree.by_id["steel_alloys"]["cost"]) * float(s.rules["phase6"]["research"]["diffusion_cost_factor"])
	runner.check(cost < float(s.tech_tree.by_id["steel_alloys"]["cost"]), "accès par accord moins coûteux")


# ------------------------------------------------------------------ communications
func test_interception_levels() -> void:
	var s := _session()
	CommunicationsSystem.ensure(s.state, "france")
	CommunicationsSystem.ensure(s.state, "german_empire")
	var low := CommunicationsSystem.attempt_intercept(s.state, s.tech_tree, "france", "german_empire", s.rules["phase6"], 990)
	var high := CommunicationsSystem.attempt_intercept(s.state, s.tech_tree, "france", "german_empire", s.rules["phase6"], 5)
	runner.check(["none", "detected", "intercepted", "partial", "decrypted"].has(str(low["level"])), "niveau d'interception valide")
	runner.check(float(high.get("reliability", 0.0)) >= float(low.get("reliability", 0.0)), "meilleure interception = meilleure fiabilité")


func test_decryption_is_gradual() -> void:
	var s := _session()
	CommunicationsSystem.ensure(s.state, "france")
	CommunicationsSystem.advance_decryption(s.state, "france", "german_empire", s.rules["phase6"])
	var d := float(s.state.tech["comms"]["france"]["decryption"].get("german_empire", 0.0))
	runner.check(d > 0.0 and d < 1.0, "décryptage progressif (%.2f)" % d)
	for i in 16:
		CommunicationsSystem.advance_decryption(s.state, "france", "german_empire", s.rules["phase6"])
	runner.check(float(s.state.tech["comms"]["france"]["decryption"]["german_empire"]) <= 1.0, "décryptage plafonné")
	var intel := CommunicationsSystem.technical_intel(s.state, "france", "german_empire", s.rules["phase6"])
	runner.check(intel.has("reliability") and intel.has("stale"), "renseignement technique imparfait et daté")


# ------------------------------------------------------------------ aviation
func test_airbase_and_production() -> void:
	var s := _session()
	TechSystem.ensure(s.state, "france")
	AirSystem.ensure(s.state, "france")
	runner.check(AirSystem.build_base(s.state, "france", "region_008", s.rules) == "", "base construite")
	runner.check((s.state.tech["air"]["bases"]["france"] as Array).size() == 1, "base enregistrée")
	(s.state.tech["known"]["france"] as Array).append("military_aviation_basics")
	for r: String in ["iron", "coal"]:
		s.state.economy["stocks"]["france"][r] = 200.0
	var err := AirSystem.produce(s.state, "france", "recon", 2, s.rules)
	runner.check(err == "", "production aéronautique : %s" % err)
	runner.check(int(s.state.tech["air"]["aircraft"]["france"]["recon"]) == 2, "appareils produits")
	var before := float(s.state.economy["stocks"]["france"]["iron"])
	runner.check(before < 200.0, "matières premières consommées")


func test_air_recon_feeds_intel() -> void:
	var s := _session()
	TechSystem.ensure(s.state, "france")
	AirSystem.ensure(s.state, "france")
	(s.state.tech["known"]["france"] as Array).append("military_aviation_basics")
	(s.state.tech["air"]["aircraft"]["france"] as Dictionary)["recon"] = 2
	AirSystem.build_base(s.state, "france", "region_008", s.rules)
	var empty := AirSystem.reconnaissance(s.state, s.tech_tree, "france", "region_007", s.rules)
	runner.check(bool(empty.get("ok", false)), "mission de reconnaissance")
	var intel: Array = s.state.tech["intel"]["france"]
	runner.check(intel.size() > 0 and float(intel[0]["accuracy"]) > 0.0, "renseignement aérien daté ajouté")


# ------------------------------------------------------------------ marine
func test_fleet_and_operations() -> void:
	var s := _session("united_kingdom")
	NavalSystem.ensure(s.state, "united_kingdom")
	for r: String in ["iron", "coal"]:
		s.state.economy["stocks"]["united_kingdom"][r] = 500.0
	var comp := {"cruiser": 1, "destroyer": 2}
	var err := NavalSystem.create_fleet(s.state, "united_kingdom", "city_london", comp, s.rules)
	runner.check(err == "", "flotte créée : %s" % err)
	var fleets: Array = s.state.tech["naval"]["fleets"]["united_kingdom"]
	runner.check(fleets.size() == 1, "flotte enregistrée")
	var fid := str(fleets[0]["id"])
	var op := NavalSystem.operation(s.state, "united_kingdom", fid, "escort", "manche", s.rules["phase6"])
	runner.check(bool(op.get("ok", false)), "opération d'escorte")
	runner.check(NavalSystem.escort_benefit(s.state, "united_kingdom", s.rules["phase6"]) > 0.0, "effet d'escorte mesurable")
	var bad := NavalSystem.operation(s.state, "united_kingdom", "inconnu", "blockade", "manche", s.rules["phase6"])
	runner.check(not bool(bad.get("ok", false)), "opération invalide refusée")


func test_blockade_affects_trade() -> void:
	var s := _session("germany") if false else _session("german_empire")
	NavalSystem.ensure(s.state, "german_empire")
	for r: String in ["iron", "coal"]:
		s.state.economy["stocks"]["german_empire"][r] = 500.0
	NavalSystem.create_fleet(s.state, "german_empire", "city_hamburg", {"destroyer": 1}, s.rules)
	var fid := str((s.state.tech["naval"]["fleets"]["german_empire"] as Array)[0]["id"])
	NavalSystem.operation(s.state, "german_empire", fid, "blockade", "mer_du_nord", s.rules["phase6"])
	runner.check(NavalSystem.blockade_penalty(s.state, "united_kingdom", s.rules["phase6"]) > 0.0, "blocus pénalise le commerce")


# ------------------------------------------------------------------ IA + sauvegarde
func test_ai_bounded_and_deterministic() -> void:
	var s := _session("france")
	var a := JSON.stringify(Phase6AI.decide(s.state, s.tech_tree, s.rules, "france"))
	var b := JSON.stringify(Phase6AI.decide(s.state, s.tech_tree, s.rules, "france"))
	runner.check(a == b, "IA Phase VI déterministe")
	var orders := Phase6AI.decide(s.state, s.tech_tree, s.rules, "france")
	runner.check(orders.size() <= 8, "ordres IA bornés (%d)" % orders.size())


func test_phase6_state_persists() -> void:
	var s := _session()
	TechSystem.ensure(s.state, "france")
	(s.state.tech["known"]["france"] as Array).append("electrification")
	AirSystem.ensure(s.state, "france")
	AirSystem.build_base(s.state, "france", "region_008", s.rules)
	s.end_turn()
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/phase6_state.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde v8")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "rechargement : %s" % str(loaded.get("error", "")))
	var st2: GameState = loaded["state"]
	runner.check(st2.checksum() == s.state.checksum(), "empreinte identique")
	runner.check(TechSystem.known(st2, "france", "electrification"), "découverte persistée")
	runner.check((st2.tech["air"]["bases"]["france"] as Array).size() == 1, "base persistée")


func test_v7_save_migration_initializes_tech() -> void:
	var s := _session()
	var env := SaveRepository.envelope(s.state, s.world, s.rules)
	env["format_version"] = 7
	var st: Dictionary = env["state"]
	st["format_version"] = 7
	st.erase("tech")
	var once := JSON.stringify(st, "", true, true)
	env["state_sha256"] = JSON.stringify(JSON.parse_string(once), "", true, true).sha256_text()
	var path := "user://test_saves/phase6_v7.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(SaveRepository._encode_floats(env), "", true, true))
	f.close()
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "v7 migrée : %s" % str(loaded.get("error", "")))
	runner.check(int(loaded.get("migrated_from", -1)) == 7, "migration v7 identifiée")
	var st2: GameState = loaded["state"]
	runner.check(st2.tech["air"].has("bases"), "structures Phase VI initialisées")
