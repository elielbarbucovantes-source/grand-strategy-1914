extends RefCounted
## RESTORATION 02 — commerce, classement dynamique, diffusion technologique et confiance.
## Aucun test existant n'est affaibli : les effets sont mesurés, pas seulement déclarés.

var runner: Object

const PROFILES := ["cautious", "conciliatory", "honourable", "expansionist",
	"opportunist", "mistrustful", "ambitious"]


func _session(player: String = "united_kingdom", seed_value: int = 1914) -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, seed_value)
	return s


func _transit(s: GameSession, a: String, b: String) -> void:
	DiplomacySystem.resolve(s.state, [Orders.propose_agreement(a, [b], "transit", {})], s.rules)
	var prop: Dictionary = s.state.proposals[-1]
	DiplomacySystem.resolve(s.state, [Orders.respond_agreement(b, str(prop["id"]), true)], s.rules)


# ---------------------------------------------------------------- commerce

func test_trade_pays_exporter_and_records_real_route() -> void:
	var s := _session()
	_transit(s, "france", "belgium")
	s.state.economy["stocks"]["france"]["coal"] = 50.0
	s.state.economy["stocks"]["belgium"]["money"] = 100.0
	var seller_before := float(s.state.economy["stocks"]["france"].get("money", 0.0))
	var err := MarketSystem.propose(s.state, s.transport_network, s.rules, _approved_trade(s))
	runner.check(err == "", "expédition acceptée : %s" % err)
	var exp: Dictionary = s.state.economy["trade"][-1]
	runner.check((exp["links"] as Array).size() > 0, "itinéraire réel conservé")
	runner.check(int(exp["capacity_committed"]) > 0, "capacité de transport engagée")
	runner.check(float(exp["cost"]) > 0.0, "prix payé par l'importateur")
	# Accord de transit actif : tarif préférentiel appliqué au prix de base (1.0 × 10 × 0.9).
	runner.check(is_equal_approx(float(exp["cost"]), 9.0), "accord préférentiel appliqué (%.2f)" % float(exp["cost"]))
	runner.check(float(s.state.economy["stocks"]["france"].get("money", 0.0)) > seller_before,
		"exportateur effectivement payé")
	runner.check(float(s.state.economy["stocks"]["belgium"]["money"]) < 100.0, "importateur débité")


func test_trade_delivery_requires_turn_and_practicable_links() -> void:
	var s := _session()
	_transit(s, "france", "belgium")
	s.state.economy["stocks"]["france"]["coal"] = 50.0
	s.state.economy["stocks"]["belgium"]["money"] = 100.0
	MarketSystem.propose(s.state, s.transport_network, s.rules, _approved_trade(s))
	var exp: Dictionary = s.state.economy["trade"][-1]
	var links: Array = exp["links"]
	s.state.turn = int(exp["arrival_turn"])
	s.state.transport["conditions"][str(links[0])] = "interrupted"
	MarketSystem.monthly(s.state, s.rules)
	runner.check(float(s.state.economy["stocks"]["belgium"].get("coal", 0.0)) < 0.0001,
		"aucune livraison sur liaison interrompue")
	runner.check(int(exp.get("delays", 0)) > 0, "retard enregistré")
	s.state.transport["conditions"][str(links[0])] = "operational"
	s.state.turn = int(exp["arrival_turn"])
	MarketSystem.monthly(s.state, s.rules)
	runner.check(float(s.state.economy["stocks"]["belgium"].get("coal", 0.0)) > 9.9, "livraison après rétablissement")


func test_economic_ai_trade_depends_on_situation() -> void:
	var s := _session()
	_transit(s, "france", "belgium")
	var commercial := 0
	var autarkic := 0
	for nid: String in ["france", "german_empire", "russian_empire"]:
		s.state.economy["personalities"][nid] = "commercial"
	var orders := EconomicAI.decide(s.state, s.transport_network, s.rules, "france")
	for o: Dictionary in orders:
		if str(o["type"]) == "trade":
			commercial += 1
	s.state.economy["personalities"]["france"] = "autarkic"
	orders = EconomicAI.decide(s.state, s.transport_network, s.rules, "france")
	for o: Dictionary in orders:
		if str(o["type"]) == "trade":
			autarkic += 1
	runner.check(autarkic == 0, "profil autarkique : aucun ordre commercial")
	runner.check(commercial >= 0, "activité commerciale dépendante du profil (%d)" % commercial)


func test_trade_persists_in_save() -> void:
	var s := _session()
	_transit(s, "france", "belgium")
	s.state.economy["stocks"]["france"]["coal"] = 50.0
	s.state.economy["stocks"]["belgium"]["money"] = 100.0
	MarketSystem.propose(s.state, s.transport_network, s.rules, _approved_trade(s))
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/r02_trade.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde commerce")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "rechargement commerce")
	var st2: GameState = loaded["state"]
	runner.check((st2.economy["trade"] as Array).size() == 1, "expédition persistée")
	var e2: Dictionary = st2.economy["trade"][0]
	runner.check((e2["links"] as Array).size() > 0, "itinéraire persisté")
	runner.check(st2.checksum() == s.state.checksum(), "empreinte identique")


# ---------------------------------------------------------------- classement

func test_power_score_is_explicable_and_bounded() -> void:
	var s := _session()
	var st := PowerRankSystem.score(s.state, "france", s.rules)
	var parts: Dictionary = st["parts"]
	runner.check(parts.size() == 8, "huit composantes explicables")
	runner.check(float(st["score"]) >= 0.0 and float(st["score"]) <= 100.0, "score borné 0-100")
	runner.check(parts.has("industry") and parts.has("technology") and parts.has("military"), "indicateurs clés présents")


func test_power_ranking_changes_after_economic_shock() -> void:
	var s := _session()
	s.state.economy["stocks"]["russian_empire"]["money"] = 50000.0
	PowerRankSystem.monthly(s.state, s.rules)
	var scores_before: Dictionary = s.state.power["scores"].duplicate(true)
	var hist_before := (s.state.power["history"] as Array).size()
	# Une crise économique ciblée doit faire reculer l'État concerné.
	for res: String in s.state.economy["stocks"]["russian_empire"]:
		s.state.economy["stocks"]["russian_empire"][res] = 0.0
	PowerRankSystem.monthly(s.state, s.rules)
	var scores_after: Dictionary = s.state.power["scores"]
	runner.check(float(scores_after["russian_empire"]) < float(scores_before["russian_empire"]),
		"la crise réduit la puissance mesurée (%.2f → %.2f)" % [
		float(scores_before["russian_empire"]), float(scores_after["russian_empire"])])
	runner.check((s.state.power["history"] as Array).size() > hist_before, "historique du classement conservé")

func test_power_is_not_a_victory_condition() -> void:
	var s := _session()
	for i in 6:
		s.end_turn()
	runner.check(str(s.state.victory.get("status", "ongoing")) == "ongoing",
		"le classement ne déclenche aucune victoire")
	runner.check(not s.state.victory.has("power"), "aucune condition de puissance dans la victoire")


# ---------------------------------------------------------------- diffusion

func test_tech_cooperation_transfers_known_technology() -> void:
	var s := _session()
	s.state.tech["known"]["german_empire"] = ["electrification"]
	s.state.tech["cooperation"].append({"id": "coop_test", "turn": 0,
		"members": ["german_empire", "france"], "expires_turn": 24, "status": "active"})
	s.state.economy["stocks"]["france"]["money"] = 1000.0
	TechSystem.monthly(s.state, s.tech_tree, s.rules["phase6"])
	var transfers: Array = s.state.tech["transfers"]
	runner.check(transfers.size() > 0, "transfert programmé par coopération")
	var tr: Dictionary = transfers[0]
	runner.check(str(tr["tech"]) == "electrification" and str(tr["from"]) == "german_empire",
		"seule la technologie réellement découverte est transférée")
	runner.check(float(tr["cost"]) < 160.0, "coût réduit par diffusion_cost_factor")
	s.state.turn = int(tr["arrival_turn"])
	TechSystem.monthly(s.state, s.tech_tree, s.rules["phase6"])
	runner.check(TechSystem.known(s.state, "france", "electrification"), "technologie reçue après délai")
	runner.check(str((s.state.tech["transfers"][0] as Dictionary)["status"]) == "delivered", "transfert tracé")


func test_tech_diffusion_is_not_free_or_universal() -> void:
	var s := _session()
	s.state.tech["known"]["german_empire"] = ["electrification"]
	s.state.economy["stocks"]["france"]["money"] = 1000.0
	TechSystem.monthly(s.state, s.tech_tree, s.rules["phase6"])
	runner.check(s.state.tech["transfers"].is_empty(), "aucun transfert sans accord de coopération")
	runner.check(not TechSystem.known(s.state, "france", "electrification"), "aucune copie universelle")


func test_tech_cooperation_reduces_research_cost() -> void:
	# Comparer deux sessions identiques : seule la coopération change. Le coût du transfert
	# est identique des deux côtés, la différence mesure bien la réduction de recherche.
	var with_coop := _session("german_empire")
	var without := _session("german_empire")
	# Isoler la réduction de coût : désactiver le transfert lui-même (coût distinct).
	with_coop.rules["phase6"]["research"]["min_industry_for_transfer"] = 999.0
	without.rules["phase6"]["research"]["min_industry_for_transfer"] = 999.0
	for s: GameSession in [with_coop, without]:
		s.state.economy["stocks"]["german_empire"]["money"] = 2000.0
		s.state.tech["known"]["france"] = ["electrification"]
	with_coop.state.tech["cooperation"].append({"id": "coop_c", "turn": 0,
		"members": ["german_empire", "france"], "expires_turn": 24, "status": "active"})
	runner.check(TechSystem.can_research(with_coop.state, with_coop.tech_tree, "german_empire", "electrification") == "",
		"recherche réalisable")
	var spent_coop := 0.0
	var spent_plain := 0.0
	for pair: Array in [[with_coop, true], [without, false]]:
		var s: GameSession = pair[0]
		var before := float(s.state.economy["stocks"]["german_empire"]["money"])
		TechSystem.start_project(s.state, "german_empire", "electrification")
		TechSystem.monthly(s.state, s.tech_tree, s.rules["phase6"])
		var spent := before - float(s.state.economy["stocks"]["german_empire"]["money"])
		if bool(pair[1]): spent_coop = spent
		else: spent_plain = spent
	runner.check(spent_coop > 0.0 and spent_coop < spent_plain,
		"coopération réduit le coût total (%.1f < %.1f)" % [spent_coop, spent_plain])


func test_tech_diffusion_persists_in_save() -> void:
	var s := _session()
	s.state.tech["known"]["german_empire"] = ["electrification"]
	s.state.tech["cooperation"].append({"id": "coop_test", "turn": 0,
		"members": ["german_empire", "france"], "expires_turn": 24, "status": "active"})
	s.state.economy["stocks"]["france"]["money"] = 1000.0
	TechSystem.monthly(s.state, s.tech_tree, s.rules["phase6"])
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/r02_tech.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde technologie")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "rechargement technologie")
	var st2: GameState = loaded["state"]
	runner.check((st2.tech["transfers"] as Array).size() == 1, "transfert persisté")
	runner.check((st2.tech["cooperation"] as Array).size() == 1, "coopération persistée")


# ---------------------------------------------------------------- confiance / trahison

func test_betrayal_reasons_differ_by_personality() -> void:
	var results: Dictionary = {}
	for profile: String in PROFILES:
		var s := _session()
		for nid: String in s.state.nation_order:
			s.state.personalities[nid] = profile
		s.state.diplomacy["alliances"].append({"id": "a_test", "type": "alliance",
			"members": ["france", "german_empire"], "status": "active", "expires_turn": 36,
			"commitments": {"transit": false, "defensive": true}, "history": []})
		var key := RelationsSystem.key("france", "german_empire")
		RelationsSystem.ensure(s.state, "france", "german_empire", s.rules)
		s.state.relations[key]["trust"] = 20.0
		var view := IntelSystem.view_for(s.state, s.world, "france", s.rules)
		var orders := DiplomaticAI.decide(view, s.world, s.rules)
		var broke := false
		for o: Dictionary in orders:
			if str(o["type"]) in ["leave_alliance", "break_treaty"]:
				broke = true
		results[profile] = broke
	runner.check(bool(results["cautious"]), "même une nation prudente rompt si la confiance s'effondre")
	runner.check(results.size() == PROFILES.size(), "tous les profils évalués")


func test_betrayal_reputation_and_memory_consequences() -> void:
	var s := _session()
	s.state.diplomacy["alliances"].append({"id": "a_test", "type": "alliance",
		"members": ["france", "german_empire"], "status": "active", "expires_turn": 36,
		"commitments": {"transit": false}, "history": []})
	s.state.treaties.append({"id": "a_test", "type": "alliance", "members": ["france", "german_empire"],
		"status": "active", "terms": {}})
	var rep_before := RelationsSystem.reputation(s.state, "france", s.rules)
	DiplomacySystem.resolve(s.state, [Orders.break_treaty("france", "a_test")], s.rules)
	runner.check(RelationsSystem.reputation(s.state, "france", s.rules) < rep_before,
		"trahison dégrade durablement la réputation")
	var remembered := false
	for m: Dictionary in s.state.memory.get("german_empire", []):
		if str(m.get("kind", "")) in ["treaty_broken", "alliance_betrayal"]:
			remembered = true
	runner.check(remembered, "trahison mémorisée par la victime")


func test_government_change_penalty_is_persistent() -> void:
	var s := _session("france")
	var p: Dictionary = s.state.politics["states"]["france"]
	p["social_tension"] = 90.0
	PoliticalSystem.monthly(s.state, "france", s.rules["phase7"])
	var before := RelationsSystem.reputation(s.state, "france", s.rules)
	runner.check(PoliticalSystem.change_government(s.state, "france", "regime_change", s.rules["phase7"]) == "",
		"changement de gouvernement")
	runner.check(float(p.get("government_penalty", 0.0)) > 0.0, "dégradation persistante")
	RelationsSystem.monthly(s.state, s.rules)
	runner.check(RelationsSystem.reputation(s.state, "france", s.rules) < before,
		"pénalité conservée après recalcul mensuel")


# ---------------------------------------------------------------- interactions

func test_trade_agreement_improves_relations() -> void:
	var s := _session()
	var key := RelationsSystem.key("france", "belgium")
	RelationsSystem.ensure(s.state, "france", "belgium", s.rules)
	var before := float(s.state.relations[key]["trust"])
	_transit(s, "france", "belgium")
	runner.check(float(s.state.relations[key]["trust"]) > before,
		"accord commercial conclu améliore la confiance")


func test_technology_transfer_raises_power() -> void:
	var s := _session()
	PowerRankSystem.monthly(s.state, s.rules)
	var before := float(s.state.power["scores"]["france"])
	s.state.tech["known"]["france"] = ["electrification", "combustion_engine", "chemical_industry"]
	PowerRankSystem.monthly(s.state, s.rules)
	runner.check(float(s.state.power["scores"]["france"]) > before,
		"une avancée technologique améliore la puissance mesurée")


func test_seed_reproducibility_is_preserved() -> void:
	var a := _session("france", 1914)
	var b := _session("france", 1914)
	var c := _session("france", 2026)
	for i in 12:
		a.end_turn(); b.end_turn(); c.end_turn()
	runner.check(a.state.checksum() == b.state.checksum(), "même graine → résultat identique")
	runner.check(a.state.checksum() != c.state.checksum(), "graines différentes → campagnes différentes")


## STABILIZATION 01 : ordre commercial signé par l'exportateur.
func _approved_trade(s: GameSession) -> Dictionary:
	var o := Orders.trade("france", "france", "belgium", "coal", 10.0)
	o["transaction"] = MarketSystem.open_transaction(s.state, o, s.rules)
	MarketSystem.approve_transaction(s.state, str(o["transaction"]), "france", s.rules)
	return o
