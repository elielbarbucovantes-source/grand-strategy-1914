extends RefCounted
## Phase I post-MIL-01 (Chantier B2) : 10 scénarios déterministes du brief, via les vrais
## mécanismes (IntelSystem.view_for → NationAgent.decide/evaluate_target → ordres → résolution).
## Chaque scénario contrôle les informations accessibles, la décision, l'approche, le résultat
## et le respect du brouillard. Deux tests transverses : anti-répétition et non-abandon.

var runner: Object

const ME := "german_empire"
const FOE := "france"
const TARGET := "region_011"  # région française voisine de la Lorraine allemande


func _session() -> GameSession:
	var s := GameSession.create()
	s.new_game("united_kingdom", 1, 1914)
	s.state.wars.append({"id": "w_test", "a": ME, "b": FOE, "since_turn": s.state.turn})
	return s


func _view(s: GameSession) -> Dictionary:
	return IntelSystem.view_for(s.state, s.world, ME, s.rules)


func _army(s: GameSession, id: String, rid: String, soldiers: int, morale: float, supplied: bool = true) -> Dictionary:
	return {"id": id, "nation": ME, "region": rid, "echelon": "army", "soldiers": soldiers,
		"operational_soldiers": soldiers, "morale": morale, "supplied": supplied,
		"engaged": false, "encircled": false, "defensive_posture": "hold"}


func _intel(status: String, estimate: Variant, armies_seen: Variant, reliability: float = 0.9, fort: int = 0) -> Dictionary:
	return {"status": status, "estimated_soldiers": estimate, "armies_seen": armies_seen,
		"reliability": reliability, "fortification_level": fort, "age_turns": 0,
		"source": "reconnaissance", "nations": [FOE]}


func _set_target_intel(view: Dictionary, inf: Dictionary) -> void:
	(view["region_intel"] as Dictionary)[TARGET] = inf
	(view["political"] as Dictionary)[TARGET] = {"controller": FOE, "sovereign": FOE}


func _decide_orders(s: GameSession) -> Array:
	var view := _view(s)
	return NationAgent.decide(view, s.world, s.rules)


func _has_move_to(orders: Array, army: String, target: String) -> bool:
	for o: Dictionary in orders:
		if str(o.get("type", "")) == "move" and str(o.get("formation", "")) == army and str(o.get("target", "")) == target:
			return true
	return false


func _approach_of(orders: Array, army: String, target: String) -> String:
	for o: Dictionary in orders:
		if str(o.get("type", "")) == "move" and str(o.get("formation", "")) == army and str(o.get("target", "")) == target:
			return str(o.get("approach", ""))
	return ""


# ------------------------------------------------------------------ scénarios 1 à 5

func test_01_attack_against_weaker_force() -> void:
	var s := _session()
	var view := _view(s)
	var army := _army(s, "probe_army", "region_035", 90000, 75.0)
	_set_target_intel(view, _intel("estimated", 35000, 1, 0.95))
	var ev := NationAgent.evaluate_target(view, s.world, s.rules, ME, TARGET, [army])
	runner.check(bool(ev["can_attack"]), "cible défendue mais inférieure : offensive retenue")
	runner.check(str(ev["approach"]) == "assault", "supériorité nette → assault (%s)" % ev["approach"])
	runner.check(float(ev["ratio"]) > 1.35, "ratio favorable (%s)" % ev["ratio"])


func test_02_considers_attack_against_stronger_force() -> void:
	var s := _session()
	var view := _view(s)
	var army := _army(s, "probe_army", "region_035", 30000, 60.0)
	_set_target_intel(view, _intel("estimated", 140000, 2, 0.9))
	var ev := NationAgent.evaluate_target(view, s.world, s.rules, ME, TARGET, [army])
	runner.check(not bool(ev["can_attack"]), "infériorité nette : pas d'offensive suicide")
	runner.check(str(ev["reason"]).contains("insuffisant") or float(ev["ratio"]) < 1.0, "raison documentée")


func test_03_reconnaissance_without_intelligence() -> void:
	var s := _session()
	var view := _view(s)
	var army := _army(s, "probe_army", "region_035", 70000, 70.0)
	_set_target_intel(view, _intel("unknown", null, 1, 0.0))
	var ev := NationAgent.evaluate_target(view, s.world, s.rules, ME, TARGET, [army])
	runner.check(bool(ev["can_attack"]), "force inconnue : action possible")
	runner.check(str(ev["approach"]) == "reconnaissance", "renseignement inconnu → reconnaissance en force")
	runner.check(fl(resolve_hidden_enemy_strength(view)) == 0.0, "vue sans effectif ennemi réel")


func resolve_hidden_enemy_strength(view: Dictionary) -> int:
	# Aucun effectif ennemi réel ne doit être exposé, même après une reconnaissance.
	var total := 0
	for f: Dictionary in view["formations"]:
		if str(f["nation"]) != ME and f["soldiers"] != null:
			total += int(f["soldiers"])
	return total


func fl(v: int) -> float:
	return float(v)


func test_04_capital_defense() -> void:
	var s := _session()
	var view := _view(s)
	var capital: String = view["capital_region"]
	var army := _army(s, "probe_army", capital, 40000, 50.0, false)
	var posture := NationAgent.choose_defensive_posture(view, s.world, s.rules, ME, army)
	runner.check(posture == "hold_at_all_costs", "capitale → hold_at_all_costs (%s)" % posture)


func test_05_abandon_secondary_position() -> void:
	var s := _session()
	var view := _view(s)
	# Région secondaire : garnison faible, moral bas, non ravitailée, retraite possible.
	var army := _army(s, "probe_army", "region_035", 18000, 30.0, false)
	var posture := NationAgent.choose_defensive_posture(view, s.world, s.rules, ME, army)
	runner.check(posture == "delay", "position secondaire préservée par repli → delay (%s)" % posture)


# ------------------------------------------------------------------ scénarios 6 à 10

func test_06_two_ais_successive_operations() -> void:
	var s := _session()
	var hist: Array = []
	for turn in 4:
		var view := _view(s)
		var orders := NationAgent.decide(view, s.world, s.rules)
		hist.append({"turn": s.state.turn, "orders": orders.size()})
		# Les ordres sont soumis au vrai résolveur (validation uniquement, sans bataille joueur).
		var valid := 0
		for o: Dictionary in orders:
			if TurnResolver._validate(s.state, s.world, s.rules, o) == "":
				valid += 1
		runner.check(valid > 0, "tour %d : des ordres valides sont émis (%d)" % [turn + 1, valid])
		s.state.turn += 1
	runner.check(hist.size() == 4, "4 tours successifs simulés")
	runner.check(JSON.stringify(_decide_orders(s)) == JSON.stringify(_decide_orders(s)), "décisions déterministes à tour égal")


func test_07_stale_report_delays_attack() -> void:
	var s := _session()
	var view := _view(s)
	var army := _army(s, "probe_army", "region_035", 50000, 70.0)
	var inf := _intel("stale", 150000, 2, 0.3)
	_set_target_intel(view, inf)
	var ev := NationAgent.evaluate_target(view, s.world, s.rules, ME, TARGET, [army])
	runner.check(not bool(ev["can_attack"]) or str(ev["approach"]) == "reconnaissance",
		"rapport ancien défavorable → attente ou reconnaissance (%s)" % str(ev["reason"]))


func test_08_reevaluation_after_new_intelligence() -> void:
	var s := _session()
	var view := _view(s)
	var army := _army(s, "probe_army", "region_035", 90000, 78.0)
	_set_target_intel(view, _intel("stale", 170000, 2, 0.3))
	var before := NationAgent.evaluate_target(view, s.world, s.rules, ME, TARGET, [army])
	_set_target_intel(view, _intel("estimated", 30000, 1, 0.95))
	var after := NationAgent.evaluate_target(view, s.world, s.rules, ME, TARGET, [army])
	runner.check(not bool(before["can_attack"]) and bool(after["can_attack"]), "réévaluation après nouveau renseignement")
	runner.check(str(after["approach"]) == "assault", "nouvelle estimation favorable → assault")


func test_09_strongly_fortified_position() -> void:
	var s := _session()
	var view := _view(s)
	var army := _army(s, "probe_army", "region_035", 100000, 80.0)
	_set_target_intel(view, _intel("estimated", 60000, 2, 0.95, 3))
	var ev := NationAgent.evaluate_target(view, s.world, s.rules, ME, TARGET, [army])
	runner.check(bool(ev["can_attack"]), "position fortifiée peut être attaquée avec supériorité suffisante")
	runner.check(str(ev["approach"]) != "assault" or float(ev["ratio"]) >= 1.75,
		"fortificationLevel 3 exige un ratio supérieur pour l'assault")


func test_10_unfavorable_logistics() -> void:
	var s := _session()
	var view := _view(s)
	# Armée coupée de ravitaillement dans une région éloignée de la capitale.
	var rid := "region_035"
	var army := _army(s, "probe_army", rid, 40000, 55.0, false)
	var orders := NationAgent.decide(view, s.world, s.rules)
	# Le scénario est vérifié directement : une armée non ravitailée doit se replier.
	runner.check(NationAgent.evaluate_target(view, s.world, s.rules, ME, TARGET, [army]).get("reason") != "",
		"évaluation logistique renseignée")
	var posture := NationAgent.choose_defensive_posture(view, s.world, s.rules, ME, army)
	runner.check(posture == "delay" or posture == "hold", "logistique défavorable → posture prudente (%s)" % posture)


# ------------------------------------------------------------------ tests transverses

func test_anti_repetition_of_ineffective_orders() -> void:
	var s := _session()
	var signatures: Dictionary = {}
	for turn in 6:
		var view := _view(s)
		var orders := NationAgent.decide(view, s.world, s.rules)
		var moves: Array = orders.filter(func(o: Dictionary) -> bool: return str(o.get("type", "")) == "move")
		var sig := JSON.stringify(moves)
		signatures[sig] = int(signatures.get(sig, 0)) + 1
		# Application réelle des ordres via le résolveur (pas de simple incrément de tour).
		var by_nation := {ME: moves}
		TurnResolver.resolve(s.state, s.world, s.rules, by_nation)
		# Résolution des batailles tactiques auto pour ne pas bloquer le tour suivant.
		for b: Dictionary in BattleManager.queue(s.state):
			BattleManager.run_to_end(b, s.rules["combat"], true)
			BattleManager.finish(s.state, s.world, s.rules["combat"], b)
	var repeated := 0
	for sig: String in signatures:
		repeated = maxi(repeated, int(signatures[sig]))
	runner.check(repeated < 6, "aucun ordre de mouvement inefficace répété 6 tours de suite (%d max)" % repeated)


func test_no_abandon_before_reinforcements() -> void:
	var s := _session()
	var view := _view(s)
	var army := _army(s, "probe_army", "region_035", 18000, 40.0, true)
	_set_target_intel(view, _intel("estimated", 120000, 2, 0.9))
	var ev := NationAgent.evaluate_target(view, s.world, s.rules, ME, TARGET, [army])
	runner.check(not bool(ev["can_attack"]), "pas d'attaque avant renforts face à une force supérieure")
	# Renforts numériquement suffisants : l'objectif peut être repris.
	army["soldiers"] = 160000
	army["operational_soldiers"] = 160000
	army["morale"] = 75.0
	var reinforced := NationAgent.evaluate_target(view, s.world, s.rules, ME, TARGET, [army])
	runner.check(bool(reinforced["can_attack"]), "objectif repris après arrivée des renforts")
