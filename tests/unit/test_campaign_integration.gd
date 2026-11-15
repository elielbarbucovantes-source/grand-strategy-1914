extends RefCounted
## Intégration : la campagne historique déclenche de vraies batailles tactiques (effectifs MIL-01) ;
## pertes persistantes, retraite, renforts, sauvegarde et rechargement, tours mensuels.

var runner: Object


func _session() -> GameSession:
	var s := GameSession.create()
	s.new_game("france", 1)
	return s


## Allemagne (035) attaque la France (011) ; la France est jouée par l'humain.
func _attack(s: GameSession) -> Dictionary:
	var st := s.state
	s.queue_order(Orders.declare_war("france", "german_empire"))
	s.end_turn()
	runner.check(st.at_war("france", "german_empire"), "guerre déclarée")
	var orders := {"german_empire": [Orders.move("german_empire", "army_german_empire_region_035", "region_011")]}
	var report := TurnResolver.resolve(st, s.world, s.rules, orders)
	return report


func test_historical_battle_is_tactical_with_reinforcements() -> void:
	var s := _session()
	var st := s.state
	var fr_before: int = st.soldiers_of("army_france_region_011")
	var de_before: int = st.soldiers_of("army_german_empire_region_035")
	var report := _attack(s)
	runner.check(int(report["pending_battles"]) == 1 and st.active_battles.size() == 1, "campagne : bataille tactique créée (plus de repli neutre)")
	var b: Dictionary = st.active_battles[0]
	var engaged := {"france": 0, "german_empire": 0}
	var available := {"attackers": 0, "defenders": 0}
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if u["status"] == CombatData.AVAILABLE:
			available[u["side"]] += 1
		elif engaged.has(u["nation"]):
			engaged[u["nation"]] += int(u["soldiers"])
	runner.check(engaged["france"] == fr_before and engaged["german_empire"] == de_before, "effectifs engagés = effectifs historiques des armées présentes")
	var cap := int(s.rules["combat"]["reinforcements"]["max_reinforcement_units_per_side"])
	runner.check(int(available["defenders"]) > 0 and int(available["defenders"]) <= cap, "renforts français voisins proposés (%d, plafond %d)" % [available["defenders"], cap])
	runner.check(s.end_turn().has("error"), "mois suivant bloqué tant que la bataille est active (T-029 A)")
	var t0 := Time.get_ticks_msec()
	var result := s.auto_resolve_battle()
	var ms := Time.get_ticks_msec() - t0
	runner.check(not result.is_empty() and st.active_battles.is_empty(), "bataille résolue (%d ms, %d unités)" % [ms, CombatData.unit_ids(b).size()])
	var fr_after: Variant = st.soldiers_of("army_france_region_011") if st.formations.has("army_france_region_011") else 0
	var de_after: Variant = st.soldiers_of("army_german_empire_region_035") if st.formations.has("army_german_empire_region_035") else 0
	runner.check(int(fr_after) < fr_before and int(de_after) < de_before, "pertes persistantes des deux côtés (FR %d→%d, DE %d→%d)" % [fr_before, int(fr_after), de_before, int(de_after)])
	var loser: String = "attackers" if result["winner"] != "attackers" else "defenders"
	var loser_army := "army_german_empire_region_035" if loser == "attackers" else "army_france_region_011"
	if st.formations.has(loser_army):
		runner.check(st.formations[loser_army]["region"] != "region_011" or st.formations[loser_army].get("encircled", false),
			"camp vaincu : retraite hors de la région (ou encerclement)")
	runner.check(not s.end_turn().has("error"), "tour mensuel suivant débloqué")


func test_save_reload_mid_battle_and_after_mobilization() -> void:
	var s := _session()
	s.queue_order(Orders.mobilize("france"))
	_attack(s)
	var st := s.state
	s.advance_battle(30)
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/campaign_mid_battle.json"
	runner.check(SaveRepository.save(path, st, s.world, s.rules) == "", "sauvegarde en pleine bataille historique")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "rechargement intègre")
	var st2: GameState = loaded["state"]
	runner.check(st2.checksum() == st.checksum(), "empreinte identique après rechargement")
	runner.check(st2.nations["france"]["forces"]["posture"] == "generale" and int(st2.nations["france"]["forces"]["reserve_pool"]) == int(st.nations["france"]["forces"]["reserve_pool"]),
		"état de mobilisation conservé")
	# La partie rechargée et l'originale évoluent à l'identique.
	var s2 := GameSession.create()
	s2.state = st2
	s.auto_resolve_battle()
	s2.auto_resolve_battle()
	s.end_turn()
	s2.end_turn()
	runner.check(s.state.checksum() == s2.state.checksum(), "déterminisme après rechargement (bataille puis tour mensuel)")


func test_monthly_turns_with_historical_forces() -> void:
	var s := _session()
	var t0 := Time.get_ticks_msec()
	for i in 3:
		var r := s.end_turn()
		runner.check(not r.has("error"), "tour %d résolu" % (i + 1))
	runner.check(s.state.month == 4, "trois mois écoulés (%d ms)" % (Time.get_ticks_msec() - t0))
