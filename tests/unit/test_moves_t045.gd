extends RefCounted
## T-045 : déplacements simultanés, croisements sans bataille, absence de biais d'ordre de traitement.
## Campagne historique (effectifs MIL-01) : les batailles créées sont de vraies batailles tactiques.

var runner: Object


func _session(seed_value: int = 1914) -> GameSession:
	var s := GameSession.create()
	s.new_game("france", 1, seed_value)
	s.state.human_nations = []  # aucune bataille ne doit rester en attente d'un humain dans ces tests
	return s


func _war(st: GameState, a: String, b: String) -> void:
	st.wars.append({"id": "war_%s_%s" % [a, b], "a": a, "b": b, "since_turn": 0})


func _transit(st: GameState, grantee: String, grantor: String) -> void:
	st.treaties.append({"id": "tr_%s_%s" % [grantee, grantor], "type": "transit", "members": [grantee, grantor],
		"status": "active", "grantor": grantor, "grantee": grantee})


func _resolve(s: GameSession, orders: Dictionary) -> Dictionary:
	return TurnResolver.resolve(s.state, s.world, s.rules, orders)


## Échange simple : France 011 → 035, Allemagne 035 → 011. Croisement sans bataille (T-045).
func test_swap_positions_without_battle() -> void:
	var s := _session()
	var st := s.state
	_war(st, "france", "german_empire")
	var fr := "army_france_region_011"
	var de := "army_german_empire_region_035"
	var fr_soldiers: int = st.soldiers_of(fr)
	var de_soldiers: int = st.soldiers_of(de)
	var report := _resolve(s, {"france": [Orders.move("france", fr, "region_035")],
		"german_empire": [Orders.move("german_empire", de, "region_011")]})
	runner.check(int(report["battles"]) == 0 and st.active_battles.is_empty() and st.battles.is_empty(), "échange de positions : aucune bataille")
	runner.check(st.formations[fr]["region"] == "region_035" and st.formations[de]["region"] == "region_011", "les deux armées ont échangé leurs positions")
	runner.check(st.soldiers_of(fr) == fr_soldiers and st.soldiers_of(de) == de_soldiers, "aucune perte lors d'un croisement")
	runner.check(st.controller("region_035") == "france" and st.controller("region_011") == "german_empire",
		"règle territoriale normale : chaque région vide d'ennemis est occupée par l'entrant")
	runner.check(st.sovereign("region_035") == "german_empire", "occupation distincte de la souveraineté")


## Échange, mais une autre armée ennemie reste dans la région d'arrivée : bataille normale.
func test_swap_with_stationary_enemy_triggers_normal_battle() -> void:
	var s := _session()
	var st := s.state
	_war(st, "france", "german_empire")
	st.move_army("army_german_empire_region_033", "region_035")  # reste sur place pendant le tour
	var report := _resolve(s, {"france": [Orders.move("france", "army_france_region_011", "region_035")],
		"german_empire": [Orders.move("german_empire", "army_german_empire_region_035", "region_011")]})
	runner.check(int(report["battles"]) == 1, "une seule bataille : celle de la région où des ennemis se retrouvent (%s)" % report["battles"])
	runner.check(st.battles.size() == 1 and st.battles[0]["region"] == "region_035", "bataille dans la région 035, pas sur l'itinéraire")
	runner.check(st.battles[0].has("result"), "bataille tactique réelle (effectifs historiques) résolue avant le tour suivant")
	runner.check(st.controller("region_011") == "german_empire", "l'armée qui a croisé occupe la région laissée vide")


## Plusieurs armées ennemies en mouvement : chaîne et croisement multiples sans contact final.
func test_multiple_enemy_armies_moving() -> void:
	var s := _session()
	var st := s.state
	_war(st, "france", "german_empire")
	var orders := {
		"france": [Orders.move("france", "army_france_region_011", "region_035")],
		"german_empire": [Orders.move("german_empire", "army_german_empire_region_035", "region_032"),
			Orders.move("german_empire", "army_german_empire_region_032", "region_033")],
	}
	var report := _resolve(s, orders)
	runner.check(int(report["battles"]) == 0, "chaîne de déplacements (035 → 032 → 033) et entrée française en 035 : aucun contact final, aucune bataille")
	runner.check(st.formations["army_france_region_011"]["region"] == "region_035", "l'armée française arrive dans une région évacuée")


## Convergence : deux armées ennemies entrent dans la même région → bataille ; le camp défenseur
## d'une rencontre en territoire tiers ne dépend pas de l'ordre des pays (tirage neutre par graine).
func test_convergence_and_no_order_bias() -> void:
	var defenders_seen: Dictionary = {}
	for seed_value: int in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]:
		var s := _session(seed_value)
		var st := s.state
		_war(st, "france", "german_empire")
		_transit(st, "france", "belgium")
		_transit(st, "german_empire", "belgium")
		var moves := [Orders.move("france", "army_france_region_007", "region_014"),
			Orders.move("german_empire", "army_german_empire_region_032", "region_014")]
		for m: Dictionary in moves:
			runner.check(MilitarySystem.validate_move(st, s.world, s.rules, m) == "", "mouvement autorisé (passage) : %s" % m["formation"])
		var clashes := MilitarySystem.resolve_moves(st, s.world, s.rules, moves)
		runner.check(clashes.size() == 1 and clashes[0]["region"] == "region_014", "rencontre : bataille dans la région commune")
		var d: String = st.formations[clashes[0]["defenders"][0]]["nation"]
		defenders_seen[d] = true
		# Même graine, ordre des pays et des ordres inversé : même résultat.
		var s2 := _session(seed_value)
		var st2 := s2.state
		_war(st2, "france", "german_empire")
		_transit(st2, "france", "belgium")
		_transit(st2, "german_empire", "belgium")
		st2.nation_order.reverse()
		var reversed := moves.duplicate()
		reversed.reverse()
		var c2 := MilitarySystem.resolve_moves(st2, s2.world, s2.rules, reversed)
		runner.check(st2.formations[c2[0]["defenders"][0]]["nation"] == d, "résultat indépendant de l'ordre de traitement (graine %d)" % seed_value)
	runner.check(defenders_seen.size() == 2, "selon la graine, chacun des deux pays peut être défenseur : aucun avantage systématique")


## Occupation conjointe d'une région ennemie vide : le plus grand contingent l'emporte ; à égalité,
## tirage neutre indépendant de l'ordre des pays.
func test_joint_occupation_is_order_independent() -> void:
	var s := _session()
	var st := s.state
	_war(st, "france", "german_empire")
	_war(st, "united_kingdom", "german_empire")
	st.move_army("army_german_empire_region_035", "region_033")  # 035 évacuée
	st.move_army("army_united_kingdom_region_001", "region_011")
	var moves := [Orders.move("united_kingdom", "army_united_kingdom_region_001", "region_035"),
		Orders.move("france", "army_france_region_011", "region_035")]
	MilitarySystem.resolve_moves(st, s.world, s.rules, moves)
	var bigger := "france" if int(st.soldiers_of("army_france_region_011")) > int(st.soldiers_of("army_united_kingdom_region_001")) else "united_kingdom"
	runner.check(st.controller("region_035") == bigger, "contrôle au plus grand contingent entrant (%s)" % bigger)
	# Égalité parfaite : le résultat ne dépend pas de l'ordre des pays ni des ordres.
	var outcomes: Array = []
	for flip: bool in [false, true]:
		var s2 := _session(77)
		var st2 := s2.state
		_war(st2, "belgium", "german_empire")
		_war(st2, "netherlands", "german_empire")
		st2.move_army("army_german_empire_region_032", "region_033")
		st2.move_army("army_belgium_1", "region_014")
		st2.move_army("army_netherlands_1", "region_016")
		st2.formations["army_belgium_1"]["soldiers"] = 5000
		st2.formations["army_netherlands_1"]["soldiers"] = 5000
		var mv := [Orders.move("belgium", "army_belgium_1", "region_032"), Orders.move("netherlands", "army_netherlands_1", "region_032")]
		if flip:
			mv.reverse()
			st2.nation_order.reverse()
		MilitarySystem.resolve_moves(st2, s2.world, s2.rules, mv)
		outcomes.append(st2.controller("region_032"))
	runner.check(outcomes[0] == outcomes[1] and ["belgium", "netherlands"].has(outcomes[0]), "égalité : tirage neutre reproductible, indépendant de l'ordre (%s)" % str(outcomes))
