extends RefCounted
## Phase I post-MIL-01 (T5) : scénarios de bout en bout avec les VRAIES mécanismes.
##
## Différence avec test_ai_phase1_scenarios.gd (tests de décision) : aucune vue n'est modifiée à la
## main. Les observations proviennent d'une reconnaissance en force réellement résolue, les postures
## et les offensives passent par TurnResolver / GameSession.end_turn, et les résultats militaires
## sont lus dans state.battles, state.regions et le contrôle territorial. Graine fixe partout.
##
## Couverture : (a) offensive contre une force inférieure → bataille et résultat ; (c/7/8) inconnu →
## reconnaissance → rapport → décision au tour suivant → péremption ; (4/5) capitale en
## hold_at_all_costs, position secondaire en delay et retraite conforme MIL-01 ; (6) deux IA
## (Allemagne + France) sur 4 tours, batailles résolues, opérations successives, cohérence des
## ordres et brouillard vérifié pour les deux camps à chaque tour.

var runner: Object

const DE := "german_empire"
const FR := "france"
const PLAYER := "united_kingdom"
const SEED := 19140101
const CAP_DE := "region_028"
const TARGET := "region_011"       # région française voisine de la Lorraine allemande (region_035)
const SECONDARY := "region_035"    # position secondaire allemande, voisine de TARGET
const DE_ARMY := "army_german_empire_region_035"
const FR_ARMY := "army_france_region_011"


func _session() -> GameSession:
	var s := GameSession.create()
	s.new_game(PLAYER, 1, 1914)
	s.state.seed_value = SEED
	s.state.wars.append({"id": "w_e2e", "a": DE, "b": FR, "since_turn": 0})
	return s


func _view(s: GameSession, nation: String) -> Dictionary:
	return IntelSystem.view_for(s.state, s.world, nation, s.rules)


func _formation(view: Dictionary, fid: String) -> Dictionary:
	for f: Dictionary in view["formations"]:
		if f["id"] == fid:
			return f
	return {}


func _foreign_soldiers(view: Dictionary) -> int:
	var total := 0
	for f: Dictionary in view["formations"]:
		if str(f["nation"]) != str(view["nation"]) and f["soldiers"] != null:
			total += int(f["soldiers"])
	return total


func _orders_of_turn(s: GameSession, nation: String) -> Array:
	if s.state.orders_history.is_empty():
		return []
	var out: Array = []
	for o: Dictionary in s.state.orders_history[-1].get("orders", []):
		if str(o.get("nation", "")) == nation:
			out.append(o)
	return out


func _report(s: GameSession, rid: String, nation: String) -> Dictionary:
	return s.state.regions[rid].get("recon_reports", {}).get(nation, {})


func _exact_soldiers(s: GameSession, army: String) -> int:
	var total := 0
	for uid: String in s.state.units_of(army):
		total += int(s.state.formations[uid]["soldiers"])
	return total


func _do_reconnaissance(s: GameSession) -> Dictionary:
	TurnResolver.resolve(s.state, s.world, s.rules, {DE: [Orders.move(DE, DE_ARMY, TARGET, "reconnaissance")]})
	runner.check(not s.state.battles.is_empty(), "reconnaissance : une bataille réelle a été résolue")
	return s.state.battles[-1]


# ------------------------------------------------------------------ (a) offensive réelle

func test_e2e_assault_against_weaker_force() -> void:
	var s := _session()
	var enemy_before := _exact_soldiers(s, DE_ARMY)
	var own_before := _exact_soldiers(s, FR_ARMY)
	runner.check(own_before > enemy_before, "préparation : l'attaquant français est supérieur (%d > %d)" % [own_before, enemy_before])
	# L'armée française de region_011 (127 820 hommes) attaque la garnison allemande de region_035
	# (57 819 hommes) : la bataille est créée et jouée par TurnResolver, sans injection de vue.
	TurnResolver.resolve(s.state, s.world, s.rules, {FR: [Orders.move(FR, FR_ARMY, SECONDARY, "assault")]})
	runner.check(s.state.battles.size() == 1, "une seule bataille réelle résolue dans le tour")
	var b: Dictionary = s.state.battles[-1]
	var res: Dictionary = b["result"]
	runner.check(str(b["engagement"]["approach"]) == "assault", "approche réelle de la bataille : assault")
	runner.check(str(res["winner"]) == "attackers" and bool(res["decisive"]), "issue réelle : victoire décisive des attaquants (%s)" % str(res["end_reason"]))
	runner.check(int(res["stats"]["attackers"]["lost"]) > 0 and int(res["stats"]["defenders"]["lost"]) > 0,
		"pertes militaires réelles enregistrées (attaquants %d, défenseurs %d)" % [int(res["stats"]["attackers"]["lost"]), int(res["stats"]["defenders"]["lost"])])
	runner.check(s.state.controller(SECONDARY) == FR, "contrôle militaire de %s transféré à la France" % SECONDARY)
	runner.check(s.state.formations.has(DE_ARMY) and s.state.formations[DE_ARMY]["region"] != SECONDARY, "le défenseur a quitté la région perdue")
	# Retraite MIL-01 : région voisine, amie et sans armée ennemie, pas d'encerclement.
	var dest: String = s.state.formations[DE_ARMY]["region"]
	runner.check(s.world.neighbor_ids(SECONDARY, true).has(dest), "retraite vers une région voisine (%s)" % dest)
	runner.check(s.state.controller(dest) == DE, "retraite vers une région amie (%s)" % dest)
	var hostile := false
	for f: Dictionary in s.state.armies_in(dest):
		hostile = hostile or s.state.at_war(DE, str(f["nation"]))
	runner.check(not hostile and not bool(s.state.formations[DE_ARMY].get("encircled", false)), "retraite sûre et non encerclée")


# ------------------------------------------------------------------ (c/7/8) renseignement réel

func test_e2e_unknown_to_reconnaissance_report_to_decision() -> void:
	var s := _session()
	var before_view := _view(s, DE)
	var before_intel: Dictionary = before_view["region_intel"][TARGET]
	runner.check(str(before_intel["status"]) == "unknown" and before_intel["estimated_soldiers"] == null,
		"avant observation : effectif ennemi inconnu (%s)" % str(before_intel["status"]))
	runner.check(_foreign_soldiers(before_view) == 0, "avant observation : aucun effectif réel d'autrui dans la vue")
	var before := NationAgent.evaluate_target(before_view, s.world, s.rules, DE, TARGET, [_formation(before_view, DE_ARMY)])
	runner.check(str(before["approach"]) == "reconnaissance", "inconnu → décision de reconnaissance en force")

	var b := _do_reconnaissance(s)
	runner.check(str(b["engagement"]["approach"]) == "reconnaissance", "l'approche de la bataille est bien reconnaissance")
	runner.check(b["result"]["winner"] != "attackers" and s.state.controller(TARGET) == FR,
		"reconnaissance : la région n'est pas capturée, le défenseur tient")
	runner.check(str(b["result"]["engagement"]["approach"]) == "reconnaissance" and not b["recon_report"].is_empty(),
		"issue de reconnaissance consignée dans la bataille et le rapport (%s)" % str(b["result"]["end_reason"]))
	var rep := _report(s, TARGET, DE)
	runner.check(not rep.is_empty() and str(rep["source"]) == "reconnaissance", "rapport écrit par BattleManager dans state.regions")
	runner.check(int(rep["estimate"]) != _exact_soldiers(s, FR_ARMY), "estimation arrondie, jamais l'effectif exact (%d vs %d)" % [int(rep["estimate"]), _exact_soldiers(s, FR_ARMY)])

	var after_view := _view(s, DE)
	var after_intel: Dictionary = after_view["region_intel"][TARGET]
	runner.check(str(after_intel["status"]) == "estimated" and int(after_intel["estimated_soldiers"]) > 0,
		"après reconnaissance : estimation disponible via IntelSystem.view_for (%s)" % str(after_intel["status"]))
	runner.check(int(after_intel["estimate_min"]) <= int(rep["estimate"]) and int(rep["estimate"]) <= int(after_intel["estimate_max"]),
		"fourchette d'incertitude cohérente avec le rapport")
	runner.check(_foreign_soldiers(after_view) == 0, "anti-omniscience : effectifs ennemis réels absents de la vue")
	var after := NationAgent.evaluate_target(after_view, s.world, s.rules, DE, TARGET, [_formation(after_view, DE_ARMY)])
	runner.check(not bool(after["can_attack"]) and str(after["reason"]).contains("défavorable"),
		"nouvelle décision fondée sur le rapport : pas d'assaut suicidaire (%s)" % str(after["reason"]))

	# La décision du tour suivant est réellement soumise au tour : les deux camps décident sur leur
	# propre vue filtrée et TurnResolver résout simultanément (le joueur reste le Royaume-Uni).
	var fr_view := _view(s, FR)
	var report := TurnResolver.resolve(s.state, s.world, s.rules, {
		DE: NationAgent.decide(after_view, s.world, s.rules),
		FR: NationAgent.decide(fr_view, s.world, s.rules),
	})
	runner.check(int(report.get("accepted", 0)) > 0, "tour réel résolu après reconnaissance (%d ordres acceptés)" % int(report.get("accepted", 0)))
	var next_orders := _orders_of_turn(s, DE)
	runner.check(not next_orders.is_empty(), "l'IA allemande émet des ordres au tour suivant (%d)" % next_orders.size())
	for o: Dictionary in next_orders:
		if str(o.get("type", "")) == Orders.MOVE:
			runner.check(str(o["target"]) != TARGET or str(o.get("approach", "")) != "assault",
				"aucun assault allemand contre une force estimée supérieure")


func test_e2e_report_expiration_after_stale_turns() -> void:
	var s := _session()
	var b := _do_reconnaissance(s)
	runner.check(not _report(s, TARGET, DE).is_empty() and int(b["recon_report"]["estimate"]) > 0, "rapport de reconnaissance disponible")
	var stale_turns := int(IntelSystem.cfg(s.rules).get("stale_turns", 4))
	for i in stale_turns:
		# Vrais tours simulés, sans ordres : seul le temps passe, le rapport vieillit.
		TurnResolver.resolve(s.state, s.world, s.rules, {})
		var ri: Dictionary = _view(s, DE)["region_intel"][TARGET]
		var age := s.state.turn - int(_report(s, TARGET, DE).get("turn", s.state.turn))
		if age <= stale_turns:
			runner.check(ri["age_turns"] == age and str(ri["status"]) == "stale" and ri["estimated_soldiers"] != null,
				"rapport encore valide mais ancien (âge %d ≤ %d)" % [age, stale_turns])
		else:
			runner.check(ri["age_turns"] == null and str(ri["status"]) == "unknown" and ri["estimated_soldiers"] == null,
				"péremption après stale_turns=%d (âge %d)" % [stale_turns, age])
	var expired_view := _view(s, DE)
	var expired: Dictionary = expired_view["region_intel"][TARGET]
	runner.check(str(expired["status"]) == "unknown", "à péremption la région redevient inconnue")
	var decision := NationAgent.evaluate_target(expired_view, s.world, s.rules, DE, TARGET, [_formation(expired_view, DE_ARMY)])
	runner.check(str(decision["approach"]) == "reconnaissance", "décision après péremption : nouvelle reconnaissance nécessaire")
	runner.check(_foreign_soldiers(expired_view) == 0, "péremption sans fuite d'effectifs réels dans la vue")


# ------------------------------------------------------------------ (4/5) postures et retraite

func test_e2e_capital_hold_at_all_costs_in_real_battle() -> void:
	var s := _session()
	var view := _view(s, DE)
	var capital_army := ""
	var capital_entry: Dictionary = {}
	for f: Dictionary in view["formations"]:
		if str(f["nation"]) == DE and str(f["region"]) == CAP_DE:
			capital_army = str(f["id"])
			capital_entry = f
			break
	runner.check(capital_army != "", "une formation allemande réelle est en place dans la capitale %s" % CAP_DE)
	var wanted := NationAgent.choose_defensive_posture(view, s.world, s.rules, DE, capital_entry)
	runner.check(wanted == "hold_at_all_costs", "capitale : posture choisie hold_at_all_costs (%s)" % wanted)
	# La posture est appliquée par le vrai résolveur, puis utilisée lors d'une bataille réelle.
	TurnResolver.resolve(s.state, s.world, s.rules, {DE: [Orders.defensive_posture(DE, capital_army, wanted)]})
	runner.check(str(s.state.formations[capital_army]["defensive_posture"]) == wanted, "posture appliquée à l'état par TurnResolver")
	var attack_from := ""
	for n: String in s.world.neighbor_ids(CAP_DE, true):
		if s.state.controller(n) == DE:
			attack_from = n
			break
	runner.check(attack_from != "", "une région allemande voisine permet l'attaque de la capitale")
	s.state.move_army(FR_ARMY, attack_from)
	TurnResolver.resolve(s.state, s.world, s.rules, {FR: [Orders.move(FR, FR_ARMY, CAP_DE, "assault")]})
	runner.check(not s.state.battles.is_empty(), "bataille réelle déclenchée contre la capitale")
	var b: Dictionary = s.state.battles[-1]
	runner.check(str(b["region"]) == CAP_DE and str(b["engagement"]["posture"]) == "hold_at_all_costs",
		"la bataille utilise la posture défensive choisie")
	var disengaged: Dictionary = b["engagement"].get("disengaged", {})
	runner.check(not disengaged.has("defenders"), "tenir à tout prix : le défenseur ne rompt jamais le combat")
	runner.check(str(b["result"]["winner"]) == "defenders" and s.state.controller(CAP_DE) == DE,
		"la capitale reste aux mains du défenseur (%s)" % str(b["result"]["end_reason"]))


func test_e2e_secondary_delay_and_mil01_retreat() -> void:
	var s := _session()
	# Position secondaire réellement précaire : troupe non ravitaillée et moral bas dans l'état.
	s.state.formations[DE_ARMY]["supplied"] = false
	s.state.formations[DE_ARMY]["morale"] = 30.0
	var view := _view(s, DE)
	var army_entry := _formation(view, DE_ARMY)
	var wanted := NationAgent.choose_defensive_posture(view, s.world, s.rules, DE, army_entry)
	runner.check(wanted == "delay", "position secondaire : posture choisie delay (%s)" % wanted)
	# Posture et offensive sont résolues dans le même tour (les postures s'appliquent avant les batailles).
	TurnResolver.resolve(s.state, s.world, s.rules, {
		DE: [Orders.defensive_posture(DE, DE_ARMY, wanted)],
		FR: [Orders.move(FR, FR_ARMY, SECONDARY, "assault")],
	})
	runner.check(str(s.state.formations[DE_ARMY]["defensive_posture"]) == wanted, "posture delay appliquée par TurnResolver")
	runner.check(not s.state.battles.is_empty(), "bataille réelle déclenchée contre la position secondaire")
	var b: Dictionary = s.state.battles[-1]
	runner.check(str(b["engagement"]["posture"]) == "delay", "la bataille utilise la posture delay")
	var disengaged: Dictionary = b["engagement"].get("disengaged", {})
	runner.check(disengaged.has("defenders"), "retarder : le défenseur rompt le combat (%s)" % JSON.stringify(disengaged))
	runner.check(str(b["result"]["winner"]) == "attackers" and s.state.controller(SECONDARY) == FR,
		"la position secondaire est cédée après la rupture")
	var dest: String = s.state.formations[DE_ARMY]["region"]
	runner.check(dest != SECONDARY and s.world.neighbor_ids(SECONDARY, true).has(dest), "retraite MIL-01 vers une région voisine (%s)" % dest)
	runner.check(s.state.controller(dest) == DE, "retraite MIL-01 vers un territoire ami (%s)" % dest)
	var hostile := false
	for f: Dictionary in s.state.armies_in(dest):
		hostile = hostile or s.state.at_war(DE, str(f["nation"]))
	runner.check(not hostile and not bool(s.state.formations[DE_ARMY].get("encircled", false)), "retraite MIL-01 : aucun ennemi sur place, pas d'encerclement")


# ------------------------------------------------------------------ (6) deux IA, 4 tours

func test_e2e_two_ais_four_turns() -> void:
	var s := _session()
	var move_turns := {DE: 0, FR: 0}
	for turn in 4:
		# Brouillard vérifié pour les deux camps AVANT chaque décision.
		for nation: String in [DE, FR]:
			var view := _view(s, nation)
			runner.check(_foreign_soldiers(view) == 0,
				"tour %d, %s : aucune formation ennemie n'expose son effectif réel" % [turn + 1, nation])
		var report := s.end_turn()
		runner.check(not report.has("error"), "tour %d : fin de tour sans bataille joueur en attente (%s)" % [turn + 1, str(report.get("error", ""))])
		var history: Dictionary = s.state.orders_history[-1]
		runner.check((history.get("rejected", []) as Array).is_empty(), "tour %d : aucun ordre IA rejeté" % [turn + 1])
		runner.check(not (history.get("orders", []) as Array).is_empty(), "tour %d : des ordres IA acceptés" % [turn + 1])
		runner.check(s.state.active_battles.is_empty(), "tour %d : toutes les batailles IA sont résolues" % [turn + 1])
		for nation: String in [DE, FR]:
			var seen_moves := {}
			var has_move := false
			for o: Dictionary in _orders_of_turn(s, nation):
				if str(o.get("type", "")) != Orders.MOVE:
					continue
				var fid: String = str(o["formation"])
				runner.check(s.state.formations[fid]["nation"] == nation, "tour %d : %s ne commande que ses propres armées" % [turn + 1, nation])
				runner.check(not seen_moves.has(fid), "tour %d : pas de deux ordres de mouvement contradictoires pour %s" % [turn + 1, fid])
				seen_moves[fid] = str(o["target"])
				if o.has("approach"):
					runner.check(["reconnaissance", "limited_attack", "assault"].has(str(o["approach"])),
						"tour %d : approche connue (%s)" % [turn + 1, str(o["approach"])])
				has_move = true
			if has_move:
				move_turns[nation] = int(move_turns[nation]) + 1
	runner.check(int(s.state.battles.size()) >= 1, "au moins une bataille réelle résolue sur 4 tours (%d)" % s.state.battles.size())
	runner.check(int(move_turns[DE]) >= 2 or int(move_turns[FR]) >= 2,
		"opérations successives : DE %d tours avec mouvements, FR %d" % [int(move_turns[DE]), int(move_turns[FR])])
	for nation: String in [DE, FR]:
		runner.check(_foreign_soldiers(_view(s, nation)) == 0, "après 4 tours : brouillard toujours respecté pour %s" % nation)
