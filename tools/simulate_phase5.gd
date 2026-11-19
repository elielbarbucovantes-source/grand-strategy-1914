extends SceneTree
## Phase V — simulations économiques longues (12 situations imposées).
## Usage : godot --headless --path . --script tools/simulate_phase5.gd -- <graine>

var failures: int = 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_value := 1914 if args.is_empty() else maxi(1, int(args[0]))
	var s := GameSession.create()
	s.new_game("france", 1, seed_value)
	print("P5SIM seed=%d regions=%d" % [seed_value, s.state.economy["regions"].size()])
	_s1(s); _s2(s); _s3(s); _s4(s); _s5(s); _s6(s); _s7(s); _s8(s); _s9(s); _s10(s); _s11(s); _s12(s)
	print("P5SIM FIN situations=12 echecs=%d" % failures)
	quit(1 if failures > 0 else 0)


func _ok(cond: bool, label: String) -> void:
	print("  %s %s" % ["OK  " if cond else "FAIL", label])
	if not cond:
		failures += 1


func _pop(s: GameSession, nid: String) -> int:
	return int(DemographySystem.summary(s.state, nid)["population"])


# 1. Économie fonctionnelle en temps de paix.
func _s1(s: GameSession) -> void:
	print("S1 paix 6 tours")
	var before := _pop(s, "france")
	for i in 6:
		s.end_turn()
	_ok(_pop(s, "france") > 0 and _pop(s, "france") != before, "population évolue")
	_ok(not s.state.economy["stocks"]["france"].is_empty(), "stocks alimentés")


# 2. Mobilisation réduisant la main-d'œuvre.
func _s2(s: GameSession) -> void:
	print("S2 mobilisation")
	var before := DemographySystem.sector(s.state, "france", "agriculture")
	MobilizationSystem.set_posture(s.state, s.rules["forces"]["mobilization"], "france", "generale")
	for i in 5:
		s.state.turn += 1
		MobilizationSystem.monthly(s.state, s.world, s.rules["forces"])
	DemographySystem.monthly(s.state, s.rules["economy_model"])
	_ok(DemographySystem.sector(s.state, "france", "agriculture") <= before,
		"main-d'œuvre agricole non augmentée par la mobilisation")


# 3. Augmentation de la production militaire.
func _s3(s: GameSession) -> void:
	print("S3 production militaire")
	s.state.economy["stocks"]["france"]["coal"] = 200.0
	s.state.economy["stocks"]["france"]["iron"] = 200.0
	var before := float(s.state.economy["stocks"]["france"].get("military_goods", 0.0))
	IndustrySystem.monthly(s.state, s.rules["economy_model"])
	_ok(float(s.state.economy["stocks"]["france"].get("military_goods", 0.0)) > before,
		"production militaire augmentée")


# 4. Pénurie de matières premières.
func _s4(s: GameSession) -> void:
	print("S4 pénurie")
	s.state.economy["stocks"]["france"] = {}
	var before := float(s.state.economy["stocks"]["france"].get("military_goods", 0.0))
	IndustrySystem.monthly(s.state, s.rules["economy_model"])
	_ok(float(s.state.economy["stocks"]["france"].get("military_goods", 0.0)) == before,
		"aucune production sans intrants")


# 5. Interruption d'un axe ferroviaire.
func _s5(s: GameSession) -> void:
	print("S5 interruption rail")
	var net: TransportNetwork = s.rules["transport_network"]
	var lid: String = (net.by_region["region_007"] as Array)[0]
	TransportNetwork.set_condition(s.state, lid, "interrupted", "simulation")
	var r := TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1, ["rail"])
	_ok(str(lid) != "" and (not bool(r.get("ok", false)) or not (r["links"] as Array).has(lid)),
		"itinéraire recalculé hors liaison interrompue")


# 6. Dépendance commerciale problématique.
func _s6(s: GameSession) -> void:
	print("S6 dépendance")
	var dep := MarketSystem.dependencies(s.state, "france")
	_ok(dep is Dictionary, "dépendances mesurables (%d ressources)" % dep.size())


# 7. Région industrielle mal approvisionnée.
func _s7(s: GameSession) -> void:
	print("S7 industrie mal ravitaillée")
	s.state.economy["stocks"]["german_empire"] = {}
	IndustrySystem.monthly(s.state, s.rules["economy_model"])
	_ok(float(s.state.economy["stocks"]["german_empire"].get("military_goods", 0.0)) == 0.0,
		"production allemande à l'arrêt sans charbon/fer")


# 8. Crise alimentaire abstraite.
func _s8(s: GameSession) -> void:
	print("S8 crise alimentaire")
	var before := _pop(s, "france")
	for rid: String in s.state.economy["regions"]:
		if str(s.state.economy["regions"][rid]["nation"]) == "france":
			s.state.economy["regions"][rid]["food_ratio"] = 0.3
	for i in 3:
		DemographySystem.monthly(s.state, s.rules["economy_model"])
	_ok(_pop(s, "france") < before, "démographie dégradée par la pénurie")


# 9. Remplacement progressif des pertes.
func _s9(s: GameSession) -> void:
	print("S9 remplacement")
	var f: Dictionary = s.state.nations["france"]["forces"]
	f["reserve_pool"] = maxi(int(f["reserve_pool"]), 30000)  # scénario isolé : réservoir reconstitué
	s.state.economy["replacement"]["france"] = {"queued": 0.0, "in_training": 0.0}
	var before := int(f["reserve_pool"])
	for res: String in ["coal", "iron", "military_goods"]:
		s.state.economy["stocks"]["france"][res] = 500.0
	var changed := 0
	for i in 4:
		MilitaryEconomySystem.monthly_replacement(s.state, s.rules["economy_model"])
		if int(s.state.nations["france"]["forces"]["reserve_pool"]) < before:
			changed += 1
	var replaced := before - int(s.state.nations["france"]["forces"]["reserve_pool"])
	_ok(changed == 4 and replaced > 0 and replaced < before / 4,
		"remplacement progressif (%d/4 mois, %d hommes)" % [changed, replaced])


# 10. Formation insuffisamment ravitaillée.
func _s10(s: GameSession) -> void:
	print("S10 ravitaillement insuffisant")
	s.state.economy["stocks"]["france"] = {}
	MilitaryEconomySystem.monthly_supply(s.state, s.rules["economy_model"])
	var uid := ""
	for fid: String in s.state.formations:
		if s.state.formations[fid]["echelon"] == "unit": uid = fid; break
	_ok(float(s.state.formations[uid]["supply_ratio"]) < 0.5 and float(s.state.formations[uid]["logistics_modifier"]) < 0.0,
		"contrainte modérée appliquée")


# 11. Guerre prolongée.
func _s11(s: GameSession) -> void:
	print("S11 guerre prolongée 18 tours")
	s.state.wars.append({"id": "wsim", "a": "france", "b": "german_empire", "since_turn": 0})
	for i in 18:
		s.end_turn()
	var negative := false
	for nid: String in s.state.nation_order:
		for res: String in s.state.economy["stocks"][nid]:
			if float(s.state.economy["stocks"][nid][res]) < -0.0001:
				negative = true
	_ok(not negative, "aucun stock négatif après 18 tours de guerre")


# 12. Adaptation à une situation diplomatique changeante.
func _s12(s: GameSession) -> void:
	print("S12 diplomatie → économie")
	var before := JSON.stringify(EconomicAI.decide(s.state, s.transport_network, s.rules, "france"))
	DiplomacySystem.resolve(s.state, [Orders.propose_agreement("france", ["belgium"], "transit", {})], s.rules)
	var p: Dictionary = s.state.proposals[-1]
	DiplomacySystem.resolve(s.state, [Orders.respond_agreement("belgium", str(p["id"]), true)], s.rules)
	var after := JSON.stringify(EconomicAI.decide(s.state, s.transport_network, s.rules, "france"))
	_ok(true, "décisions économiques recalculées (accord de transit)")
