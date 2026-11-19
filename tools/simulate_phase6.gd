extends SceneTree
## Phase VI — simulations technologie/comms/air/marine (15 situations imposées).
## Usage : godot --headless --path . --script tools/simulate_phase6.gd -- <graine>

var failures: int = 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_value := 1914 if args.is_empty() else maxi(1, int(args[0]))
	var s := GameSession.create()
	s.new_game("france", 1, seed_value)
	print("P6SIM seed=%d techs=%d" % [seed_value, s.tech_tree.by_id.size()])
	_s1(s); _s2(s); _s3(s); _s4(s); _s5(s); _s6(s); _s7(s); _s8(s); _s9(s)
	_s10(s); _s11(s); _s12(s); _s13(s); _s14(s); _s15(s)
	print("P6SIM FIN situations=15 echecs=%d" % failures)
	quit(1 if failures > 0 else 0)


func _ok(cond: bool, label: String) -> void:
	print("  %s %s" % ["OK  " if cond else "FAIL", label])
	if not cond:
		failures += 1


# 1. Recherche en temps de paix.
func _s1(s: GameSession) -> void:
	print("S1 recherche paix")
	TechSystem.ensure(s.state, "france")
	for r: String in ["coal", "iron"]:
		s.state.economy["stocks"]["france"][r] = 200.0
	var err := TechSystem.start_project(s.state, "france", "electrification")
	for i in 10:
		TechSystem.monthly(s.state, s.tech_tree, s.rules["phase6"])
	_ok(err == "" and TechSystem.known(s.state, "france", "electrification"), "recherche aboutie")


# 2. Progression inégale.
func _s2(s: GameSession) -> void:
	print("S2 progression inegale")
	TechSystem.ensure(s.state, "france")
	TechSystem.ensure(s.state, "german_empire")
	(s.state.tech["known"]["german_empire"] as Array).append("steel_alloys")
	_ok(TechSystem.known(s.state, "german_empire", "steel_alloys")
		and not TechSystem.known(s.state, "france", "steel_alloys"), "États inégaux")


# 3. Acquisition par accord.
func _s3(s: GameSession) -> void:
	print("S3 accord technologique")
	var factor := float(s.rules["phase6"]["research"]["diffusion_cost_factor"])
	_ok(factor < 1.0 and factor > 0.0, "transfert moins coûteux (facteur %.2f)" % factor)


# 4. Interception sans décryptage.
func _s4(s: GameSession) -> void:
	print("S4 interception")
	CommunicationsSystem.ensure(s.state, "france")
	var r := CommunicationsSystem.attempt_intercept(s.state, s.tech_tree, "france", "german_empire", s.rules["phase6"], 5)
	_ok(str(r["level"]) in ["intercepted", "partial", "decrypted"], "trafic intercepté : %s" % r["level"])
	_ok(float(r["reliability"]) < 0.9 or str(r["level"]) != "intercepted", "interception ≠ décryptage")


# 5. Décryptage abstrait.
func _s5(s: GameSession) -> void:
	print("S5 decryptage")
	CommunicationsSystem.ensure(s.state, "france")
	for i in 14:
		CommunicationsSystem.advance_decryption(s.state, "france", "german_empire", s.rules["phase6"])
	_ok(float(s.state.tech["comms"]["france"]["decryption"]["german_empire"]) >= 1.0, "décryptage abouti")


# 6. Reconnaissance aérienne.
func _s6(s: GameSession) -> void:
	print("S6 reco aerienne")
	TechSystem.ensure(s.state, "france")
	AirSystem.ensure(s.state, "france")
	(s.state.tech["known"]["france"] as Array).append("military_aviation_basics")
	(s.state.tech["air"]["aircraft"]["france"] as Dictionary)["recon"] = 2
	AirSystem.build_base(s.state, "france", "region_008", s.rules)
	var r := AirSystem.reconnaissance(s.state, s.tech_tree, "france", "region_007", s.rules)
	_ok(bool(r.get("ok", false)) and (s.state.tech["intel"]["france"] as Array).size() > 0, "renseignement aérien généré")


# 7. Base mal approvisionnée.
func _s7(s: GameSession) -> void:
	print("S7 base sous-approvisionnee")
	s.state.economy["stocks"]["france"] = {}
	var before: int = int((s.state.tech["air"]["aircraft"]["france"] as Dictionary)["recon"])
	var err := AirSystem.produce(s.state, "france", "recon", 1, s.rules)
	_ok(err != "" and int((s.state.tech["air"]["aircraft"]["france"] as Dictionary)["recon"]) == before,
		"production refusée sans ressources")


# 8. Production aéronautique limitée.
func _s8(s: GameSession) -> void:
	print("S8 production limitee")
	s.state.economy["stocks"]["france"]["iron"] = 2.0
	s.state.economy["stocks"]["france"]["coal"] = 1.0
	(s.state.tech["known"]["france"] as Array).append("military_aviation_basics")
	var err := AirSystem.produce(s.state, "france", "recon", 1, s.rules)
	var err2 := AirSystem.produce(s.state, "france", "recon", 1, s.rules)
	_ok(err == "" and err2 != "", "capacité limitée par les ressources")


# 9. Flotte multi-ports.
func _s9(s: GameSession) -> void:
	print("S9 flotte multi-ports")
	TechSystem.ensure(s.state, "france")
	NavalSystem.ensure(s.state, "france")
	for r: String in ["iron", "coal"]:
		s.state.economy["stocks"]["france"][r] = 1000.0
	var e1 := NavalSystem.create_fleet(s.state, "france", "city_le_havre", {"cruiser": 1}, s.rules)
	var e2 := NavalSystem.create_fleet(s.state, "france", "city_toulon", {"destroyer": 1}, s.rules)
	_ok(e1 == "" and e2 == "", "deux flottes créées depuis deux ports")


# 10. Escorte commerciale.
func _s10(s: GameSession) -> void:
	print("S10 escorte")
	NavalSystem.ensure(s.state, "france")
	var fid := str((s.state.tech["naval"]["fleets"]["france"] as Array)[0]["id"])
	var op := NavalSystem.operation(s.state, "france", fid, "escort", "manche", s.rules["phase6"])
	_ok(bool(op["ok"]) and NavalSystem.escort_benefit(s.state, "france", s.rules["phase6"]) > 0.0,
		"escorte protège le commerce")


# 11. Interruption de route maritime.
func _s11(s: GameSession) -> void:
	print("S11 interruption maritime")
	var lid: String = ""
	for l: String in (s.rules["transport_network"] as TransportNetwork).links:
		if (s.rules["transport_network"] as TransportNetwork).links[l]["mode"] == "maritime":
			lid = l
			break
	TransportNetwork.set_condition(s.state, lid, "interrupted", "simulation")
	_ok(TransportNetwork.condition(s.state, lid) == "interrupted", "liaison maritime interrompue")


# 12. Blocus.
func _s12(s: GameSession) -> void:
	print("S12 blocus")
	NavalSystem.ensure(s.state, "german_empire")
	for r: String in ["iron", "coal"]:
		s.state.economy["stocks"]["german_empire"][r] = 500.0
	NavalSystem.create_fleet(s.state, "german_empire", "city_hamburg", {"destroyer": 1}, s.rules)
	var fid := str((s.state.tech["naval"]["fleets"]["german_empire"] as Array)[0]["id"])
	NavalSystem.operation(s.state, "german_empire", fid, "blockade", "mer_du_nord", s.rules["phase6"])
	_ok(NavalSystem.blockade_penalty(s.state, "france", s.rules["phase6"]) > 0.0, "blocus pénalise le commerce")


# 13. Transport militaire.
func _s13(s: GameSession) -> void:
	print("S13 transport militaire")
	NavalSystem.ensure(s.state, "france")
	var fid := str((s.state.tech["naval"]["fleets"]["france"] as Array)[1]["id"])
	var op := NavalSystem.operation(s.state, "france", fid, "transport", "mediterranee", s.rules["phase6"])
	_ok(bool(op["ok"]) and str(op.get("effect", "")) == "transport_capacity", "transport militaire planifié")


# 14. Opération amphibie.
func _s14(s: GameSession) -> void:
	print("S14 amphibie")
	NavalSystem.ensure(s.state, "france")
	var fid := str((s.state.tech["naval"]["fleets"]["france"] as Array)[0]["id"])
	var op := NavalSystem.operation(s.state, "france", fid, "amphibious", "manche", s.rules["phase6"])
	_ok(bool(op["ok"]), "débarquement planifié")


# 15. Évolution longue.
func _s15(s: GameSession) -> void:
	print("S15 campagne longue 18 tours")
	s.state.wars.append({"id": "w", "a": "france", "b": "german_empire", "since_turn": 0})
	for i in 18:
		s.end_turn()
	var negative := false
	for nid: String in s.state.nation_order:
		for r: String in s.state.economy["stocks"][nid]:
			if float(s.state.economy["stocks"][nid][r]) < -0.0001:
				negative = true
	_ok(not negative, "aucun stock négatif après 18 tours")
	_ok(s.state.tech["known"].size() >= 22, "états technologiques conservés")
