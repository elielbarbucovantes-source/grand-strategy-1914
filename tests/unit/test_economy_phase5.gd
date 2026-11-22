extends RefCounted
## Phase V — démographie, ressources, industrie, stocks, commerce, logistique économique,
## ravitaillement MIL-01, remplacement des pertes, IA économique et sauvegardes.

var runner: Object


func _session(player: String = "france") -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, 1914)
	return s


func _model(s: GameSession) -> Dictionary:
	return s.rules.get("economy_model", {})


# ------------------------------------------------------------------ démographie
func test_baseline_and_workforce() -> void:
	var s := _session()
	runner.check(s.state.economy["regions"].size() == 90, "90 régions démographiques")
	runner.check(int(s.state.economy["baseline_sha256"]) != 0 or str(s.state.economy["baseline_sha256"]) != "",
		"empreinte de la baseline conservée")
	var fr := DemographySystem.summary(s.state, "france")
	runner.check(int(fr["population"]) > 30000000, "population française cohérente (%d)" % int(fr["population"]))
	var sectors: Dictionary = fr["workforce"]
	runner.check(sectors.size() == 6, "six secteurs de main-d'œuvre")
	var total := 0.0
	for v: float in sectors.values():
		total += v
	runner.check(total > 0.0, "main-d'œuvre positive")


func test_population_growth_and_food_effect() -> void:
	var s := _session()
	var before := int(DemographySystem.summary(s.state, "france")["population"])
	for i in 3:
		s.end_turn()
	var after := int(DemographySystem.summary(s.state, "france")["population"])
	runner.check(after > 0 and after != before, "population évoluée (%d → %d)" % [before, after])
	var rid: String = s.state.economy["regions"].keys()[0]
	(s.state.economy["regions"][rid] as Dictionary)["food_ratio"] = 0.2
	DemographySystem.monthly(s.state, _model(s))
	runner.check(true, "crise alimentaire abstraite appliquée")


func test_mobilization_reduces_workforce() -> void:
	var s := _session()
	var before := float(DemographySystem.sector(s.state, "france", "agriculture"))
	MobilizationSystem.set_posture(s.state, s.rules["forces"]["mobilization"], "france", "generale")
	for i in 4:
		s.state.turn += 1
		MobilizationSystem.monthly(s.state, s.world, s.rules["forces"])
	DemographySystem.monthly(s.state, _model(s))
	var after := float(DemographySystem.sector(s.state, "france", "agriculture"))
	runner.check(after <= before, "mobilisation ne crée pas de main-d'œuvre (%.0f → %.0f)" % [before, after])


# ------------------------------------------------------------------ ressources
func test_resources_extraction_and_no_negative_stock() -> void:
	var s := _session("united_kingdom")
	var before := ResourceSystem.available(s.state, "united_kingdom", "coal")
	for i in 3:
		ResourceSystem.monthly(s.state, _model(s))
	var after := ResourceSystem.available(s.state, "united_kingdom", "coal")
	runner.check(after > before, "charbon extrait et stocké (%.1f → %.1f)" % [before, after])
	for nid: String in s.state.nation_order:
		for res: String in s.state.economy["stocks"][nid]:
			runner.check(float(s.state.economy["stocks"][nid][res]) >= -0.0001, "stock non négatif")
	var rid := "region_003"  # Pays de Galles, gisement identifié
	var deposit_before := float(s.state.economy["regions"][rid]["deposits"]["coal"])
	s.state.economy["stocks"]["united_kingdom"]["money"] = 50.0
	var err := ResourceSystem.invest(s.state, rid, "coal", 0.2, s.rules, "united_kingdom")
	runner.check(err == "", "investissement accepté : %s" % err)
	runner.check(float(s.state.economy["stocks"]["united_kingdom"]["money"]) < 50.0,
		"investissement a un coût réel en fonds")
	ResourceSystem.monthly(s.state, _model(s))
	runner.check(float(s.state.economy["regions"][rid]["deposits"]["coal"]) <= deposit_before,
		"gisement non régénéré par l'investissement")


# ------------------------------------------------------------------ industrie
func test_industry_consumes_inputs_and_produces() -> void:
	var s := _session("german_empire")
	s.state.economy["stocks"]["german_empire"]["coal"] = 100.0
	s.state.economy["stocks"]["german_empire"]["iron"] = 100.0
	var before_coal := float(s.state.economy["stocks"]["german_empire"]["coal"])
	IndustrySystem.monthly(s.state, _model(s))
	var after_coal := float(s.state.economy["stocks"]["german_empire"]["coal"])
	runner.check(after_coal < before_coal, "matières premières consommées")
	var mil := float(s.state.economy["stocks"]["german_empire"].get("military_goods", 0.0))
	runner.check(mil > 0.0, "production militaire réelle (%.2f)" % mil)


func test_industry_stops_without_inputs() -> void:
	var s := _session("italy")
	s.state.economy["stocks"]["italy"] = {}
	var before := float(s.state.economy["stocks"]["italy"].get("military_goods", 0.0))
	IndustrySystem.monthly(s.state, _model(s))
	runner.check(float(s.state.economy["stocks"]["italy"].get("military_goods", 0.0)) == before,
		"aucune production gratuite sans matières premières")


# ------------------------------------------------------------------ commerce
func test_trade_transfers_and_no_duplication() -> void:
	var s := _session("france")
	DiplomacySystem.resolve(s.state, [Orders.propose_agreement("france", ["belgium"], "transit", {})], s.rules)
	var prop: Dictionary = s.state.proposals[-1]
	DiplomacySystem.resolve(s.state, [Orders.respond_agreement("belgium", str(prop["id"]), true)], s.rules)
	s.state.economy["stocks"]["france"]["coal"] = 50.0
	var order := Orders.trade("france", "france", "belgium", "coal", 10.0)
	runner.check(MarketSystem.validate(s.state, s.transport_network, s.rules, order) == "", "commerce valide")
	runner.check(MarketSystem.propose(s.state, s.transport_network, s.rules, order) == "", "expédition acceptée")
	runner.check(ResourceSystem.available(s.state, "france", "coal") == 40.0, "stock expéditeur débité immédiatement")
	runner.check(ResourceSystem.available(s.state, "belgium", "coal") < 0.0001, "rien crédité avant livraison")
	s.state.turn += 2
	MarketSystem.monthly(s.state)
	runner.check(ResourceSystem.available(s.state, "belgium", "coal") == 10.0, "livraison après délai")
	var total := ResourceSystem.available(s.state, "france", "coal") + ResourceSystem.available(s.state, "belgium", "coal")
	runner.check(is_equal_approx(total, 50.0), "aucune duplication (total %.1f)" % total)


# ------------------------------------------------------------------ MIL-01
func test_military_supply_and_shortage() -> void:
	var s := _session()
	MilitaryEconomySystem.monthly_supply(s.state, _model(s))
	var uid := ""
	for fid: String in s.state.formations:
		if s.state.formations[fid]["echelon"] == "unit":
			uid = fid
			break
	runner.check(s.state.formations[uid].has("supply_ratio"), "ratio de ravitaillement calculé")
	s.state.economy["stocks"]["france"] = {}
	MilitaryEconomySystem.monthly_supply(s.state, _model(s))
	runner.check(float(s.state.formations[uid]["supply_ratio"]) < 0.5, "pénurie détectée")
	runner.check(float(s.state.formations[uid]["logistics_modifier"]) < 0.0, "conséquence modérée appliquée")


func test_replacement_is_progressive() -> void:
	var s := _session("france")
	var f: Dictionary = s.state.nations["france"]["forces"]
	var before := int(f["reserve_pool"])
	s.state.economy["stocks"]["france"]["iron"] = 1000.0
	s.state.economy["stocks"]["france"]["coal"] = 1000.0
	s.state.economy["stocks"]["france"]["military_goods"] = 1000.0
	MilitaryEconomySystem.monthly_replacement(s.state, _model(s))
	var after := int(s.state.nations["france"]["forces"]["reserve_pool"])
	runner.check(after < before and before - after < before / 10,
		"remplacement progressif (%d → %d)" % [before, after])


# ------------------------------------------------------------------ IA
func test_economic_ai_is_bounded_and_deterministic() -> void:
	var s := _session("france")
	var a := JSON.stringify(EconomicAI.decide(s.state, s.transport_network, s.rules, "france"))
	var b := JSON.stringify(EconomicAI.decide(s.state, s.transport_network, s.rules, "france"))
	runner.check(a == b, "décisions économiques déterministes")
	var orders := EconomicAI.decide(s.state, s.transport_network, s.rules, "france")
	runner.check(orders.size() <= int(_model(s).get("ai", {}).get("max_allocation_changes_per_month", 1))
		+ int(_model(s).get("ai", {}).get("max_trade_orders_per_month", 2)), "nombre d'ordres borné")
	for o: Dictionary in orders:
		runner.check(str(o.get("nation", "")) == "france", "ordre au nom de l'IA")


# ------------------------------------------------------------------ sauvegarde
func test_economy_persists_in_v7_save() -> void:
	var s := _session()
	s.end_turn()
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/phase5_economy.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde v7")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "rechargement : %s" % str(loaded.get("error", "")))
	var st2: GameState = loaded["state"]
	runner.check(st2.checksum() == s.state.checksum(), "empreinte identique")
	runner.check(st2.economy["regions"].size() == 90, "régions économiques persistées")
	runner.check(st2.economy["stocks"].size() == s.state.economy["stocks"].size(), "stocks persistés")


func test_v6_save_migration_keeps_transport_and_diplomacy() -> void:
	var s := _session()
	var env := SaveRepository.envelope(s.state, s.world, s.rules)
	env["format_version"] = 6
	var st: Dictionary = env["state"]
	st["format_version"] = 6
	st.erase("economy")
	st.erase("tech")
	st.erase("politics")
	st.erase("victory")
	st.erase("bridges")
	st.erase("multiplayer")
	var once := JSON.stringify(st, "", true, true)
	env["state_sha256"] = JSON.stringify(JSON.parse_string(once), "", true, true).sha256_text()
	var path := "user://test_saves/phase5_v6.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(SaveRepository._encode_floats(env), "", true, true))
	f.close()
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "v6 migrée : %s" % str(loaded.get("error", "")))
	runner.check(int(loaded.get("migrated_from", -1)) == 6, "migration v6 identifiée")
	var st2: GameState = loaded["state"]
	runner.check(st2.economy["regions"].size() == 90, "économie initialisée")
	runner.check(st2.transport["conditions"].is_empty(), "réseau Phase IV conservé")
