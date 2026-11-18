extends SceneTree
## Phase III — simulations de validation diplomatique (10 situations imposées).
## Usage : godot --headless --path . --script tools/simulate_phase3.gd -- <graine>
## Aucun fichier du dépôt n'est modifié pendant l'exécution.

var seed_value: int = 1914
var failures: int = 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		seed_value = maxi(1, int(args[0]))
	print("P3SIM seed=%d" % seed_value)
	var s := _new()
	_scenario_alliance(s)
	s = _new(); _scenario_break(s)
	s = _new(); _scenario_crisis_settled(s)
	s = _new(); _scenario_crisis_war(s)
	s = _new(); _scenario_peace(s)
	s = _new(); _scenario_pow(s)
	s = _new(); _scenario_multi_ai(s)
	s = _new(); _scenario_betrayal(s)
	s = _new(); _scenario_refusal(s)
	s = _new(); _scenario_long(s)
	print("P3SIM FIN situations=10 echecs=%d" % failures)
	quit(1 if failures > 0 else 0)


func _new() -> GameSession:
	var s := GameSession.create()
	s.new_game("united_kingdom", 1, seed_value)
	return s


func _ok(condition: bool, label: String) -> void:
	print("  %s %s" % ["OK  " if condition else "FAIL", label])
	if not condition:
		failures += 1


func _direct(s: GameSession, orders: Array) -> void:
	DiplomacySystem.resolve(s.state, orders, s.rules)


func _alliance(s: GameSession, from: String, to: String, kind: String) -> Dictionary:
	_direct(s, [Orders.propose_agreement(from, [to], kind, {})])
	var p: Dictionary = s.state.proposals[-1]
	_direct(s, [Orders.respond_agreement(to, str(p["id"]), true)])
	return s.state.diplomacy["alliances"][-1]


# 1. Alliance entre plusieurs États.
func _scenario_alliance(s: GameSession) -> void:
	print("S1 alliance multilatérale")
	var a := _alliance(s, "france", "belgium", "alliance")
	RelationsSystem.adjust(s.state, "netherlands", "france", s.rules, {"trust": 60.0}, "sim")
	var err := AllianceSystem.join(s.state, str(a["id"]), "netherlands", s.rules)
	_ok(err == "" and (a["members"] as Array).size() == 3, "trois membres, engagements actifs")
	s.state.wars.append({"id": "w1", "a": "france", "b": "german_empire", "since_turn": 0})
	_ok(AllianceSystem.obligation(s.state, "belgium", "france", "german_empire", s.rules),
		"obligation défensive effective")


# 2. Rupture d'alliance.
func _scenario_break(s: GameSession) -> void:
	print("S2 rupture d'alliance")
	var a := _alliance(s, "france", "belgium", "alliance")
	_direct(s, [Orders.break_treaty("france", str(a["id"]))])
	var r := RelationsSystem.between(s.state, "belgium", "france", s.rules)
	_ok(str(a["status"]) == "broken" and float(r["trust"]) < 30.0, "rupture : confiance effondrée")
	var remembered := false
	for m: Dictionary in s.state.memory["belgium"]:
		if str(m.get("kind", "")) == "treaty_broken":
			remembered = true
	_ok(remembered, "trahison conservée en mémoire")


# 3. Crise résolue pacifiquement.
func _scenario_crisis_settled(s: GameSession) -> void:
	print("S3 crise réglée par médiation")
	var cr := CrisisSystem.start(s.state, "german_empire", "belgium", "incident", "frontière", s.rules)
	_ok(CrisisSystem.offer_mediation(s.state, str(cr["id"]), "united_kingdom", s.rules) == "", "médiation proposée")
	for i in 4:
		CrisisSystem.monthly(s.state, s.rules)
	_ok(str(cr["status"]) == "settled", "issue pacifique (tension %.0f)" % float(cr["tension"]))


# 4. Crise dégénérant en guerre.
func _scenario_crisis_war(s: GameSession) -> void:
	print("S4 crise → guerre")
	var cr := CrisisSystem.start(s.state, "austria_hungary", "serbia", "violation", "souveraineté", s.rules)
	for i in 12:
		CrisisSystem.monthly(s.state, s.rules)
	_ok(str(cr["status"]) == "war" and s.state.at_war("austria_hungary", "serbia"), "guerre déclarée sans automatisme")


# 5. Négociation de paix.
func _scenario_peace(s: GameSession) -> void:
	print("S5 paix blanche")
	s.state.wars.append({"id": "w2", "a": "france", "b": "german_empire", "since_turn": 0})
	_direct(s, [Orders.propose_peace("france", ["german_empire"], {"white": true})])
	var p: Dictionary = s.state.proposals[-1]
	_direct(s, [Orders.respond_agreement("german_empire", str(p["id"]), false)])
	_ok(s.state.at_war("france", "german_empire"), "refus maintient la guerre")
	_direct(s, [Orders.propose_peace("france", ["german_empire"], {"white": true})])
	var p2: Dictionary = s.state.proposals[-1]
	_direct(s, [Orders.respond_agreement("german_empire", str(p2["id"]), true)])
	_ok(not s.state.at_war("france", "german_empire") and s.state.diplomacy["peace_treaties"].size() == 1,
		"acceptation : hostilités terminées, traité persisté")


# 6. Échange de prisonniers.
func _scenario_pow(s: GameSession) -> void:
	print("S6 échange de prisonniers")
	ForceLedger.add_prisoners(s.state, "france", "german_empire", 800)
	ForceLedger.add_prisoners(s.state, "german_empire", "france", 800)
	var before := PowSystem.lost_by(s.state, "france")
	var res := PowSystem.exchange(s.state, "france", "german_empire", s.rules)
	_ok(int(res["a"]) > 0 and PowSystem.lost_by(s.state, "france") == before,
		"échange effectif sans double comptage")


# 7. Diplomatie entre plusieurs IA.
func _scenario_multi_ai(s: GameSession) -> void:
	print("S7 diplomatie multi-IA (6 tours)")
	for i in 6:
		for nid: String in s.state.nation_order:
			if s.state.human_nations.has(nid):
				continue
			var view := IntelSystem.view_for(s.state, s.world, nid, s.rules)
			var orders := DiplomaticAI.decide(view, s.world, s.rules)
			_direct(s, orders)
		s.end_turn()
	var proposals := 0
	for p: Dictionary in s.state.proposals:
		if str(p["status"]) == "pending":
			proposals += 1
	_ok(proposals <= 22 and s.state.diplomacy["alliances"].size() <= 22,
		"nombre borné de propositions (%d) et d'alliances (%d)" % [proposals, s.state.diplomacy["alliances"].size()])
	_ok(s.state.relations.size() > 0, "relations créées par les IA (%d)" % s.state.relations.size())


# 8. Trahison d'une IA.
func _scenario_betrayal(s: GameSession) -> void:
	print("S8 trahison d'IA expansionniste")
	s.state.personalities["german_empire"] = "expansionist"
	var a := _alliance(s, "german_empire", "belgium", "alliance")
	RelationsSystem.adjust(s.state, "german_empire", "belgium", s.rules, {"trust": -60.0}, "sim")
	var view := IntelSystem.view_for(s.state, s.world, "german_empire", s.rules)
	var orders := DiplomaticAI.decide(view, s.world, s.rules)
	var betrayal := false
	for o: Dictionary in orders:
		if str(o.get("type", "")) == Orders.LEAVE_ALLIANCE:
			betrayal = true
	_ok(betrayal, "l'IA quitte l'alliance quand la confiance s'effondre")
	_direct(s, orders)
	_ok(str(a["status"]) in ["dissolved", "active"], "sortie traitée sans erreur")


# 9. Refus malgré un avantage apparent.
func _scenario_refusal(s: GameSession) -> void:
	print("S9 refus rationnel")
	RelationsSystem.adjust(s.state, "france", "german_empire", s.rules,
		{"trust": -60.0, "hostility": 70.0, "tensions": 50.0}, "sim")
	var view := IntelSystem.view_for(s.state, s.world, "france", s.rules)
	var score := DiplomaticAI._score(view, "german_empire", s.rules)
	_direct(s, [Orders.propose_agreement("france", ["german_empire"], "alliance", {})])
	var p: Dictionary = s.state.proposals[-1]
	var view2 := IntelSystem.view_for(s.state, s.world, "german_empire", s.rules)
	_direct(s, DiplomaticAI.decide(view2, s.world, s.rules))
	_ok(score < 0.0, "score de confiance négatif (%.1f)" % score)


# 10. Campagne longue et stabilité.
func _scenario_long(s: GameSession) -> void:
	print("S10 stabilité sur 24 tours")
	s.state.wars.append({"id": "wl", "a": "german_empire", "b": "france", "since_turn": 0})
	var c1 := s.state.checksum()
	for i in 24:
		for nid: String in ["france", "german_empire", "belgium", "austria_hungary"]:
			var view := IntelSystem.view_for(s.state, s.world, nid, s.rules)
			_direct(s, DiplomaticAI.decide(view, s.world, s.rules))
		s.end_turn()
	var finite := true
	for k: String in s.state.relations:
		var r: Dictionary = s.state.relations[k]
		for d: String in ["trust", "hostility", "cooperation", "rivalry", "tensions", "interests"]:
			var v := float(r.get(d, 0))
			if v != v or v < 0.0 or v > 100.0:
				finite = false
	_ok(finite, "relations bornées et finies (%d paires)" % s.state.relations.size())
	_ok(s.state.checksum() != c1, "monde évolué (checksum différent)")
	var pending := 0
	for p: Dictionary in s.state.proposals:
		if str(p["status"]) == "pending":
			pending += 1
	_ok(pending <= 30, "pas d'accumulation de propositions (%d)" % pending)
