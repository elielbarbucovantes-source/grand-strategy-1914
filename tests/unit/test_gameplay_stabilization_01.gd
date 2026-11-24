extends RefCounted
## STABILIZATION 01 — intégrité commerciale, conditions de victoire et consentement.
## Chaque test reproduit un des défauts confirmés par l'audit global avant correction.

var runner: Object


func _session(player: String = "france", seed_value: int = 1914) -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, seed_value)
	return s


func _route(s: GameSession, a: String, b: String) -> void:
	DiplomacySystem.resolve(s.state, [Orders.propose_agreement(a, [b], "transit", {})], s.rules)
	var p: Dictionary = s.state.proposals[-1]
	DiplomacySystem.resolve(s.state, [Orders.respond_agreement(b, str(p["id"]), true)], s.rules)


func _stocks(s: GameSession, a: String, b: String) -> Array:
	return [ResourceSystem.available(s.state, a, "coal"), ResourceSystem.available(s.state, b, "coal"),
		float(s.state.economy["stocks"][a].get("money", 0.0)), float(s.state.economy["stocks"][b].get("money", 0.0))]


func _signed(s: GameSession, from: String, to: String, res: String, amount: float) -> Dictionary:
	var o := Orders.trade(from, from, to, res, amount)
	o["transaction"] = MarketSystem.open_transaction(s.state, o, s.rules)
	MarketSystem.approve_transaction(s.state, str(o["transaction"]), from, s.rules)
	return o


# ---------------------------------------------------------------- consentement commercial

func test_forged_order_without_consent_is_rejected() -> void:
	var s := _session()
	_route(s, "france", "german_empire")
	s.state.economy["stocks"]["german_empire"]["coal"] = 100.0
	s.state.economy["stocks"]["france"]["money"] = 1000.0
	var before := _stocks(s, "france", "german_empire")
	var forged := Orders.trade("france", "german_empire", "france", "coal", 20.0)
	runner.check(MarketSystem.validate(s.state, s.transport_network, s.rules, forged) != "",
		"ordre forgé refusé (consentement absent)")
	runner.check(MarketSystem.propose(s.state, s.transport_network, s.rules, forged) != "",
		"expédition forgée refusée")
	runner.check(_stocks(s, "france", "german_empire") == before, "stocks inchangés après refus")


func test_falsified_or_foreign_consent_is_rejected() -> void:
	var s := _session()
	_route(s, "france", "german_empire")
	s.state.economy["stocks"]["german_empire"]["coal"] = 100.0
	var o := _signed(s, "german_empire", "france", "coal", 10.0)
	var before := _stocks(s, "france", "german_empire")
	var cases: Array = []
	var missing := o.duplicate(true); missing.erase("transaction"); cases.append(["absent", missing])
	var fake := o.duplicate(true); fake["transaction"] = "trade_inexistant"; cases.append(["falsifié", fake])
	var other := o.duplicate(true)
	other["transaction"] = MarketSystem.open_transaction(s.state,
		Orders.trade("german_empire", "german_empire", "belgium", "coal", 10.0), s.rules)
	MarketSystem.approve_transaction(s.state, str(other["transaction"]), "german_empire", s.rules)
	cases.append(["appartenant à un autre partenaire", other])
	for c: Array in cases:
		runner.check(MarketSystem.validate(s.state, s.transport_network, s.rules, c[1]) != "",
			"consentement %s refusé" % str(c[0]))
		runner.check(_stocks(s, "france", "german_empire") == before, "stocks inchangés (%s)" % str(c[0]))


func test_quantity_resource_partner_and_price_must_match_consent() -> void:
	var s := _session()
	_route(s, "france", "german_empire")
	s.state.economy["stocks"]["german_empire"]["coal"] = 100.0
	s.state.economy["stocks"]["france"]["money"] = 1000.0
	var o := _signed(s, "german_empire", "france", "coal", 10.0)
	var before := _stocks(s, "france", "german_empire")
	var cases: Dictionary = {}
	var big := o.duplicate(true); big["amount"] = 20.0; cases["quantité supérieure"] = big
	var res := o.duplicate(true); res["resource"] = "iron"; cases["ressource différente"] = res
	var who := o.duplicate(true); who["to"] = "belgium"; cases["partenaire différent"] = who
	var price := o.duplicate(true)
	s.state.economy["trade_consents"][str(o["transaction"])]["price"] = 999.0
	cases["prix modifié"] = price
	for k: String in cases:
		runner.check(MarketSystem.validate(s.state, s.transport_network, s.rules, cases[k]) != "",
			"%s refusé" % k)
		runner.check(_stocks(s, "france", "german_empire") == before, "stocks inchangés (%s)" % k)


func test_transaction_cannot_be_reused_or_expired() -> void:
	var s := _session()
	_route(s, "france", "german_empire")
	s.state.economy["stocks"]["german_empire"]["coal"] = 100.0
	s.state.economy["stocks"]["france"]["money"] = 1000.0
	var o := _signed(s, "german_empire", "france", "coal", 10.0)
	runner.check(MarketSystem.propose(s.state, s.transport_network, s.rules, o) == "", "première exécution")
	var after_first := _stocks(s, "france", "german_empire")
	runner.check(MarketSystem.validate(s.state, s.transport_network, s.rules, o) != "", "réutilisation refusée")
	runner.check(_stocks(s, "france", "german_empire") == after_first, "aucun second prélèvement")
	var o2 := _signed(s, "german_empire", "france", "coal", 5.0)
	s.state.turn += 100
	runner.check(MarketSystem.validate(s.state, s.transport_network, s.rules, o2) != "", "consentement expiré refusé")


func test_refused_and_pending_consent_do_not_transfer() -> void:
	var s := _session()
	_route(s, "france", "german_empire")
	s.state.economy["stocks"]["german_empire"]["coal"] = 100.0
	var o := Orders.trade("german_empire", "german_empire", "france", "coal", 10.0)
	o["transaction"] = MarketSystem.open_transaction(s.state, o, s.rules)
	var before := _stocks(s, "france", "german_empire")
	runner.check(MarketSystem.validate(s.state, s.transport_network, s.rules, o) != "", "consentement en attente refusé")
	s.state.economy["trade_consents"][str(o["transaction"])]["status"] = "rejected"
	runner.check(MarketSystem.validate(s.state, s.transport_network, s.rules, o) != "", "consentement refusé rejeté")
	runner.check(_stocks(s, "france", "german_empire") == before, "stocks inchangés")


func test_valid_consent_executes_once() -> void:
	var s := _session()
	_route(s, "france", "german_empire")
	s.state.economy["stocks"]["german_empire"]["coal"] = 50.0
	s.state.economy["stocks"]["france"]["money"] = 100.0
	var o := _signed(s, "german_empire", "france", "coal", 10.0)
	runner.check(MarketSystem.propose(s.state, s.transport_network, s.rules, o) == "", "accord valide exécuté")
	runner.check(ResourceSystem.available(s.state, "german_empire", "coal") == 40.0, "exportateur débité")
	runner.check(bool(s.state.economy["trade_consents"][str(o["transaction"])]["executed"]), "transaction verrouillée")


func test_player_and_ai_trade_flows_remain_valid() -> void:
	var s := _session()
	var p := GameSession.create()
	p.new_game("france", 1, 1914)
	runner.check(p.queue_order({"type": Orders.TRADE, "nation": "france", "from": "france",
		"to": "belgium", "resource": "coal", "amount": 5.0}) in ["", "fonds insuffisants pour l'importation",
		"stock insuffisant chez l'exportateur", "aucun itinéraire commercial disponible", "consentement expiré"],
		"vente joueur validée ou refusée pour motif économique explicite")
	var ai_orders := EconomicAI.decide(s.state, s.transport_network, s.rules, "german_empire")
	var valid := true
	for o: Dictionary in ai_orders:
		if str(o["type"]) == Orders.TRADE:
			if str(o.get("nation", "")) != str(o.get("from", "")):
				valid = false
	runner.check(valid, "l'IA n'expédie jamais le stock d'autrui")


# ---------------------------------------------------------------- conditions de victoire

func test_military_condition_is_signalled_not_automatic() -> void:
	var s := _session()
	var ids: Array = s.state.regions.keys()
	for i in mini(ids.size(), int(float(ids.size()) * 0.91)):
		s.state.regions[str(ids[i])]["controller"] = "france"
	var r := VictorySystem.check_victory(s.state, s.rules["phase7"])
	runner.check(str(r["status"]) == "ongoing", "aucune fin de partie automatique")
	runner.check((r.get("military_condition_met", []) as Array).has("france"), "condition signalée")
	runner.check(str(r.get("condition", "")) != "military", "aucune condition militaire déclarée")


func test_universal_pact_winner_is_proposer_regardless_of_order() -> void:
	for position: int in [0, 1, 11, 21]:
		var s := _session()
		var up := PeaceSystem.propose_universal(s.state, "france", s.rules)
		up["status"] = "negotiating"
		var participants: Array = up["participants"].duplicate()
		for n: String in participants:
			PeaceSystem.respond_universal(s.state, str(up["proposal"]), n, true, "", s.rules)
		var treaties: Array = s.state.diplomacy["peace_treaties"]
		runner.check(treaties.size() == 1, "pacte signé (position %d)" % position)
		var t: Dictionary = treaties[0]
		runner.check(str(t.get("proposer", "")) == "france", "proposant enregistré (position %d)" % position)
		var r := VictorySystem.check_victory(s.state, s.rules["phase7"])
		runner.check(str(r.get("winner", "")) == "france", "vainqueur = proposant (position %d)" % position)


func test_universal_pact_requires_all_acceptances() -> void:
	var s := _session()
	var up := PeaceSystem.propose_universal(s.state, "france", s.rules)
	var participants: Array = up["participants"]
	for i in participants.size() - 1:
		PeaceSystem.respond_universal(s.state, str(up["proposal"]), str(participants[i]), true, "", s.rules)
	runner.check(s.state.diplomacy["peace_treaties"].is_empty(), "pas de pacte sans dernier accord")
	PeaceSystem.respond_universal(s.state, str(up["proposal"]), str(participants[-1]), false, "refus", s.rules)
	runner.check(str(s.state.diplomacy["universal_pact"]["status"]) == "rejected", "pacte rejeté après refus")
	runner.check(str(VictorySystem.check_victory(s.state, s.rules["phase7"]).get("winner", "")) != "france",
		"aucune victoire diplomatique")


# ---------------------------------------------------------------- reproductibilité / sauvegarde

func test_consent_survives_save_and_load() -> void:
	var s := _session()
	_route(s, "france", "german_empire")
	s.state.economy["stocks"]["german_empire"]["coal"] = 50.0
	var o := _signed(s, "german_empire", "france", "coal", 10.0)
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/st01_consent.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde consentement")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "rechargement consentement")
	var st2: GameState = loaded["state"]
	runner.check((st2.economy["trade_consents"] as Dictionary).size() == 1, "consentement persisté")
	runner.check(st2.checksum() == s.state.checksum(), "empreinte identique")


func test_same_seed_is_identical() -> void:
	var a := _session("france", 1914)
	var b := _session("france", 1914)
	for i in 12:
		a.end_turn(); b.end_turn()
	runner.check(a.state.checksum() == b.state.checksum(), "campagnes identiques à graine égale")
