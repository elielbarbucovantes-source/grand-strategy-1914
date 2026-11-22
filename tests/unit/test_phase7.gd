extends RefCounted
## Phase VII — politique intérieure, conditions de victoire, franchissements, multijoueur.

var runner: Object


func _session(player: String = "france") -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, 1914)
	return s


# ------------------------------------------------------------------ politique
func test_political_state_and_groups() -> void:
	var s := _session()
	var p := PoliticalSystem.summary(s.state, "france")
	runner.check(float(p["stability"]) > 0.0 and float(p["cohesion"]) > 0.0, "indicateurs initiaux")
	var groups: Dictionary = s.state.politics["states"]["france"]["groups"]
	runner.check(groups.size() == 7, "sept groupes d'influence (%d)" % groups.size())
	for gid: String in groups:
		runner.check(float(groups[gid]["influence"]) > 0.0 and float(groups[gid]["satisfaction"]) >= 0.0,
			"groupe valide : %s" % gid)


func test_decisions_have_costs_and_limits() -> void:
	var s := _session()
	s.state.economy["stocks"]["france"]["money"] = 100.0
	var before := float(s.state.economy["stocks"]["france"]["money"])
	runner.check(PoliticalSystem.apply_decision(s.state, "france", "social_reform", s.rules["phase7"]) == "", "réforme acceptée")
	runner.check(float(s.state.economy["stocks"]["france"]["money"]) < before, "coût financier appliqué")
	runner.check(PoliticalSystem.apply_decision(s.state, "france", "inconnue", s.rules["phase7"]) != "", "décision inconnue refusée")
	runner.check(PoliticalSystem.apply_decision(s.state, "france", "public_spending", s.rules["phase7"]) == "", "deuxième décision")
	runner.check(PoliticalSystem.apply_decision(s.state, "france", "fiscal_reform", s.rules["phase7"]) != "", "limite par tour respectée")


func test_internal_crisis_and_government_change() -> void:
	var s := _session()
	var p: Dictionary = s.state.politics["states"]["france"]
	p["social_tension"] = 90.0
	PoliticalSystem.monthly(s.state, "france", s.rules["phase7"])
	runner.check(str(p["active_crisis"]) != "", "crise intérieure déclenchée")
	var rep_before := float(s.state.reputation["france"])
	runner.check(PoliticalSystem.change_government(s.state, "france", "regime_change", s.rules["phase7"]) == "", "changement de régime")
	runner.check(str(p["active_crisis"]) == "", "crise résolue par le changement")
	# RESTORATION 02 : la dégradation est persistante et résiste au recalcul mensuel.
	runner.check(float(p.get("government_penalty", 0.0)) > 0.0, "dégradation persistante enregistrée")
	var rep_after := RelationsSystem.reputation(s.state, "france", s.rules)
	runner.check(rep_after < rep_before, "réputation internationale dégradée (%.2f → %.2f)" % [rep_before, rep_after])
	runner.check(not (p["history"] as Array).is_empty(), "historique conservé")


func test_ai_politics_bounded() -> void:
	var s := _session()
	var a := JSON.stringify(PoliticalAI.decide(s.state, "france", s.rules["phase7"]))
	var b := JSON.stringify(PoliticalAI.decide(s.state, "france", s.rules["phase7"]))
	runner.check(a == b, "IA politique déterministe")
	runner.check(PoliticalAI.decide(s.state, "france", s.rules["phase7"]).size() <= 2, "IA bornée")


# ------------------------------------------------------------------ victoire
func test_military_victory_90_percent() -> void:
	var s := _session()
	var ids: Array = s.state.regions.keys()
	for i in int(float(ids.size()) * 0.91):
		s.state.regions[str(ids[i])]["controller"] = "france"
		# distinction souveraineté / occupation conservée : on ne modifie pas "sovereign"
	var r := VictorySystem.check_victory(s.state, s.rules["phase7"])
	runner.check(str(r["status"]) == "finished" and str(r["condition"]) == "military", "victoire militaire à 90 % de contrôle")
	runner.check(str(s.state.victory["winner"]) == "france", "vainqueur identifié")
	var sum := VictorySystem.final_summary(s.state, s.rules["phase7"])
	runner.check((sum["standings"] as Array).size() == 22, "bilan de fin de partie (22 États)")


func test_hdi_victory_requires_duration_and_multiple_indicators() -> void:
	var s := _session()
	var hdi := VictorySystem.hdi(s.state, "france", s.rules["phase7"])
	runner.check(hdi.has("score") and float(hdi["score"]) >= 0.0, "IDH calculé (%.3f)" % float(hdi["score"]))
	var cfg: Dictionary = s.rules["phase7"]["victory"]["hdi"]
	runner.check((cfg["indicators"] as Array).size() >= 5, "IDH multidimensionnel")
	runner.check(int(cfg["duration_months"]) >= 3, "durée minimale exigée")
	# Une seule variable ne suffit pas à gabar la victoire.
	s.state.economy["stocks"]["france"]["money"] = 1.0e9
	var hdi2 := VictorySystem.hdi(s.state, "france", s.rules["phase7"])
	runner.check(float(hdi2["score"]) < 1.0, "score plafonné malgré un revenu énorme")


func test_diplomatic_victory_is_universal_pact() -> void:
	var s := _session()
	s.state.diplomacy["peace_treaties"].append({"id": "p1", "type": "universal", "members": ["france", "german_empire"],
		"status": "active", "signed_turn": 0})
	var r := VictorySystem.check_victory(s.state, s.rules["phase7"])
	runner.check(str(r["status"]) == "finished" and str(r["condition"]) == "diplomatic", "victoire diplomatique par pacte universel")
	# Une paix bilatérale ne doit pas déclencher la victoire.
	var s2 := _session()
	s2.state.diplomacy["peace_treaties"].append({"id": "p2", "type": "bilateral", "members": ["france", "german_empire"], "status": "active"})
	runner.check(str(VictorySystem.check_victory(s2.state, s2.rules["phase7"])["status"]) == "ongoing",
		"paix bilatérale ≠ victoire diplomatique")


# ------------------------------------------------------------------ franchissements
func test_bridges_and_crossing_effects() -> void:
	var s := _session()
	CrossingSystem.init_state(s.state)
	runner.check(s.state.bridges.size() > 50, "franchissements générés (%d)" % s.state.bridges.size())
	var bid: String = s.state.bridges.keys()[0]
	var rid: String = str(s.state.bridges[bid]["region"])
	var normal := CrossingSystem.difficulty(s.state, rid, s.rules["phase7"])
	runner.check(normal >= 1.0, "difficulté de franchissement (%.2f)" % normal)
	runner.check(CrossingSystem.set_status(s.state, bid, "interrupted") == "", "pont interrompu")
	runner.check(CrossingSystem.difficulty(s.state, rid, s.rules["phase7"]) > normal, "interruption augmente la difficulté")
	runner.check(CrossingSystem.logistics_factor(s.state, rid, s.rules["phase7"]) < 1.0, "logistique dégradée")


# ------------------------------------------------------------------ multijoueur
func test_multiplayer_foundation() -> void:
	var s := _session()
	var players := {"france": {"connected": true}, "german_empire": {"connected": true}}
	runner.check(MultiplayerSystem.setup(s.state, players, s.rules["phase7"], s.world) == "", "partie multijoueur configurée")
	runner.check(s.state.human_nations.size() == 2, "deux joueurs humains")
	runner.check(MultiplayerSystem.submit_order(s.state, "france", Orders.mobilize("france"), s.rules["phase7"]) == "", "ordre soumis")
	runner.check(MultiplayerSystem.submit_order(s.state, "france", Orders.declare_war("german_empire", "france"), s.rules["phase7"]) != "",
		"ordre au nom d'un autre État refusé")
	var report := MultiplayerSystem.resolve_orders(s.state, s.rules, s.world)
	runner.check((s.state.multiplayer["state_hashes"] as Array).size() == 1, "hachage d'état enregistré")
	runner.check(MultiplayerSystem.detect_desync(s.state, "faux_hash", s.rules["phase7"]), "désynchronisation détectée")
	runner.check(not MultiplayerSystem.detect_desync(s.state, str((s.state.multiplayer["state_hashes"] as Array)[0]["hash"]), s.rules["phase7"]),
		"pas de fausse désynchronisation")


func test_multiplayer_disconnect_reconnect_and_secrecy() -> void:
	var s := _session()
	var players := {"france": {"connected": true}, "german_empire": {"connected": true}}
	MultiplayerSystem.setup(s.state, players, s.rules["phase7"], s.world)
	MultiplayerSystem.submit_order(s.state, "german_empire", Orders.mobilize("german_empire"), s.rules["phase7"])
	runner.check(MultiplayerSystem.disconnect_player(s.state, "france") == "", "déconnexion")
	var view := MultiplayerSystem.view_for(s.state, "german_empire", s.rules["phase7"])
	runner.check(not (view["players"]["france"] as Dictionary).has("orders"), "ordres adverses cachés")
	runner.check(MultiplayerSystem.reconnect_player(s.state, "france") == "", "reconnexion")
	runner.check(MultiplayerSystem.should_ai_takeover(s.state, "france", s.rules["phase7"]) == false, "joueur reconnecté : pas de prise de contrôle IA")


# ------------------------------------------------------------------ sauvegarde
func test_v9_state_persists_and_v8_migration() -> void:
	var s := _session()
	CrossingSystem.init_state(s.state)
	s.state.politics["states"]["france"]["stability"] = 42.0
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/phase7_state.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde v9")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "rechargement : %s" % str(loaded.get("error", "")))
	var st2: GameState = loaded["state"]
	runner.check(st2.checksum() == s.state.checksum(), "empreinte identique")
	runner.check(float(st2.politics["states"]["france"]["stability"]) == 42.0, "politique persistée")

	var env := SaveRepository.envelope(s.state, s.world, s.rules)
	env["format_version"] = 8
	var raw: Dictionary = env["state"]
	raw["format_version"] = 8
	for k: String in ["politics", "victory", "bridges", "multiplayer"]:
		raw.erase(k)
	var once := JSON.stringify(raw, "", true, true)
	env["state_sha256"] = JSON.stringify(JSON.parse_string(once), "", true, true).sha256_text()
	var p2 := "user://test_saves/phase7_v8.json"
	var f := FileAccess.open(p2, FileAccess.WRITE)
	f.store_string(JSON.stringify(SaveRepository._encode_floats(env), "", true, true))
	f.close()
	var mig := SaveRepository.load_save(p2, s.world, s.rules)
	runner.check(not mig.has("error"), "v8 migrée : %s" % str(mig.get("error", "")))
	runner.check(int(mig.get("migrated_from", -1)) == 8, "migration v8 identifiée")
	var st3: GameState = mig["state"]
	runner.check(not st3.politics.is_empty(), "politique initialisée")
	runner.check(st3.tech.has("known") and st3.tech.has("air") and st3.tech.has("naval"), "structures technologiques Phase VI conservées")
