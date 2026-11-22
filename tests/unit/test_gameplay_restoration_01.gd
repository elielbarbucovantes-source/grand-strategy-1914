extends RefCounted
## RESTORATION 01 — réactivation des boucles stratégiques autonomes.
## Ces tests vérifient des effets réels (coûts payés, stocks modifiés, ordres exécutés),
## pas seulement l'absence d'erreur. Aucun test existant n'est affaibli.

var runner: Object

const PERSONALITIES := ["cautious", "conciliatory", "honourable", "expansionist",
	"opportunist", "mistrustful", "ambitious"]


func _session(player: String = "france", seed_value: int = 1914) -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, seed_value)
	return s


func _count_orders(s: GameSession, kind: String) -> int:
	var n := 0
	for h: Dictionary in s.state.orders_history:
		for o: Dictionary in h.get("orders", []):
			if str(o["type"]) == kind:
				n += 1
	return n


# ---------------------------------------------------------------- chaîne économique

func test_investment_costs_real_money_and_grows_extraction() -> void:
	var s := _session("united_kingdom")
	var rid := "region_003"  # Pays de Galles, gisement de charbon documenté
	var r: Dictionary = s.state.economy["regions"][rid]
	var before_rate := float((r["exploitation"] as Dictionary).get("coal", 0.0))
	s.state.economy["stocks"]["united_kingdom"]["money"] = 40.0
	var err := ResourceSystem.invest(s.state, rid, "coal", 0.25, s.rules, "united_kingdom")
	runner.check(err == "", "investissement valide accepté : %s" % err)
	var after_rate := float((r["exploitation"] as Dictionary).get("coal", 0.0))
	runner.check(after_rate > before_rate, "taux d'extraction augmenté (%.2f → %.2f)" % [before_rate, after_rate])
	var money := float(s.state.economy["stocks"]["united_kingdom"]["money"])
	runner.check(money < 40.0, "fonds réellement débités (%.1f)" % money)
	# Sans fonds, aucun investissement gratuit n'est possible.
	s.state.economy["stocks"]["united_kingdom"]["money"] = 0.0
	var err2 := ResourceSystem.invest(s.state, rid, "coal", 0.25, s.rules, "united_kingdom")
	runner.check(err2 != "", "aucun investissement gratuit quand les fonds manquent")
	runner.check(float((r["exploitation"] as Dictionary).get("coal", 0.0)) <= after_rate,
		"taux inchangé après refus pour fonds insuffisants")


func test_ai_invests_and_extraction_feeds_stocks() -> void:
	# L'observateur est le Royaume-Uni : la France est bien conduite par l'IA.
	var s := _session("united_kingdom")
	for i in 10:
		s.end_turn()
	runner.check(_count_orders(s, "invest_resource") > 0, "l'IA émet des ordres d'investissement")
	var rate := 0.0
	for r: Dictionary in s.state.economy["regions"].values():
		if str(r["nation"]) == "france":
			for v: float in (r.get("exploitation", {}) as Dictionary).values():
				rate += v
	runner.check(rate > 0.0, "l'extraction française a réellement démarré (%.2f)" % rate)
	var extracted := 0.0
	for r: Dictionary in s.state.economy["regions"].values():
		if str(r["nation"]) != "france":
			continue
		for k: String in (r.get("last_extracted_by_resource", {}) as Dictionary):
			var e: Dictionary = r["last_extracted_by_resource"][k]
			extracted += float(e.get("amount", 0.0))
	runner.check(extracted > 0.0, "l'extraction produit réellement des ressources (%.2f)" % extracted)
	var real_stock := 0.0
	for k: String in s.state.economy["stocks"]["france"]:
		if k != "money":
			real_stock += float(s.state.economy["stocks"]["france"][k])
	runner.check(real_stock > 0.0, "des stocks non monétaires changent (%.1f)" % real_stock)


func test_research_completes_and_consumes_funds() -> void:
	var s := _session("german_empire")
	s.state.economy["stocks"]["german_empire"]["money"] = 2000.0
	var tech := "electrification"
	runner.check(TechSystem.start_project(s.state, "german_empire", tech) == "", "projet de recherche lancé")
	var before := float(s.state.economy["stocks"]["german_empire"]["money"])
	var discovered := false
	for i in 20:
		TechSystem.monthly(s.state, s.tech_tree, s.rules["phase6"])
		if TechSystem.known(s.state, "german_empire", tech):
			discovered = true
			break
	runner.check(discovered, "la recherche aboutit réellement avec des fonds disponibles")
	runner.check(float(s.state.economy["stocks"]["german_empire"]["money"]) < before,
		"la recherche consomme des fonds (%.1f → %.1f)" % [before,
		float(s.state.economy["stocks"]["german_empire"]["money"])])


func test_fiscal_revenue_is_not_free_resources() -> void:
	var s := _session()
	var before := float(s.state.economy["stocks"]["france"].get("money", 0.0))
	for i in 3:
		s.end_turn()
	var after := float(s.state.economy["stocks"]["france"].get("money", 0.0))
	runner.check(after > before, "la fiscalité alimente la trésorerie (%.0f → %.0f)" % [before, after])
	# La recette dépend de l'activité : sans industrie ni main-d'œuvre, elle s'effondre.
	var s2 := _session()
	var model: Dictionary = (s2.rules["economy_model"] as Dictionary).duplicate(true)
	model["fiscal"] = {"money_per_worker": 0.0, "money_per_industry": 0.0, "maintenance_share": 0.15}
	s2.rules["economy_model"] = model
	var b2 := float(s2.state.economy["stocks"]["france"].get("money", 0.0))
	for i in 3:
		s2.end_turn()
	runner.check(float(s2.state.economy["stocks"]["france"].get("money", 0.0)) <= b2,
		"aucune recette sans travail ni industrie : pas de création gratuite")


# ---------------------------------------------------------------- décisions politiques

func test_political_decision_applies_correct_keys() -> void:
	var s := _session()
	var pol := PoliticalSystem.ensure(s.state, "france", s.rules["phase7"])
	pol["social_tension"] = 80.0
	s.state.economy["stocks"]["france"]["money"] = 100.0
	var before := float(pol["social_tension"])
	var err := PoliticalSystem.apply_decision(s.state, "france", "cohesion_campaign", s.rules["phase7"])
	runner.check(err == "", "décision de cohésion exécutée : %s" % err)
	runner.check(float(pol["social_tension"]) < before,
		"social_tension réduite (%.1f → %.1f)" % [before, float(pol["social_tension"])])
	runner.check(float(s.state.economy["stocks"]["france"]["money"]) < 100.0,
		"coût de la décision réellement payé")


func test_fiscal_reform_applies_institution_trust() -> void:
	var s := _session()
	var pol := PoliticalSystem.ensure(s.state, "france", s.rules["phase7"])
	var before := float(pol["institution_trust"])
	s.state.economy["stocks"]["france"]["money"] = 100.0
	var err := PoliticalSystem.apply_decision(s.state, "france", "fiscal_reform", s.rules["phase7"])
	runner.check(err == "", "réforme fiscale exécutée : %s" % err)
	runner.check(float(pol["institution_trust"]) < before,
		"institution_trust modifiée (%.1f → %.1f)" % [before, float(pol["institution_trust"])])


# ---------------------------------------------------------------- décisions de guerre

func test_no_automatic_war_during_first_months() -> void:
	var s := _session()
	for i in 6:
		s.end_turn()
	runner.check(s.state.wars.is_empty(), "aucune guerre automatique avant la maturité de la crise")


func test_war_decision_rejects_immature_and_incapable_states() -> void:
	var s := _session()
	var view := IntelSystem.view_for(s.state, s.world, "serbia", s.rules)
	view["turn"] = 0
	runner.check((DiplomaticAI.war_decision(view, s.rules, "serbia")["orders"] as Array).is_empty(),
		"pas de guerre au tour 0")
	var great := IntelSystem.view_for(s.state, s.world, "france", s.rules)
	great["turn"] = 20
	great["own_forces"] = {"source_type": "procedural", "present_in_units": 0, "present_services": 0}
	runner.check((DiplomaticAI.war_decision(great, s.rules, "france")["orders"] as Array).is_empty(),
		"pas de guerre sans capacité militaire modélisée")
	great["own_forces"] = {"source_type": "historical", "present_in_units": 40000, "present_services": 0}
	great["own_money"] = 500.0
	var decision := DiplomaticAI.war_decision(great, s.rules, "france")
	runner.check((decision["orders"] as Array).is_empty() or
		str((decision["orders"] as Array)[0]["type"]) == "declare_war",
		"la décision reste cohérente avec la capacité")


func test_autonomous_war_engages_military_and_logistics() -> void:
	var s := _session()
	var declared := 0
	for i in 14:
		s.end_turn()
		declared = _count_orders(s, "declare_war")
		if declared > 0 and not s.state.battles.is_empty():
			break
	runner.check(declared > 0, "une guerre est déclarée de façon autonome (%d)" % declared)
	runner.check(not s.state.battles.is_empty(), "le système MIL-01 est sollicité (%d batailles)" % s.state.battles.size())
	runner.check(_count_orders(s, "move") > 0, "des mouvements militaires accompagnent le conflit")


func test_betrayal_is_possible_when_trust_collapses() -> void:
	var s := _session()
	s.state.personalities["france"] = "expansionist"
	# Alliance active france / german_empire avec confiance effondrée.
	s.state.diplomacy["alliances"].append({"id": "test_alliance", "members": ["france", "german_empire"],
		"status": "active", "kind": "alliance"})
	var key := RelationsSystem.key("france", "german_empire")
	RelationsSystem.ensure(s.state, "france", "german_empire", s.rules)
	s.state.relations[key]["trust"] = 5.0
	var view := IntelSystem.view_for(s.state, s.world, "france", s.rules)
	var orders := DiplomaticAI.decide(view, s.world, s.rules)
	var found := false
	for o: Dictionary in orders:
		if str(o["type"]) == "leave_alliance":
			found = true
	runner.check(found, "une rupture d'alliance est émise quand la confiance s'effondre")


# ---------------------------------------------------------------- personnalités et graines

func test_every_personality_emits_orders() -> void:
	for profile: String in PERSONALITIES:
		var s := _session()
		for nid: String in s.state.nation_order:
			s.state.personalities[nid] = profile
		var view := IntelSystem.view_for(s.state, s.world, "german_empire", s.rules)
		var orders := DiplomaticAI.decide(view, s.world, s.rules)
		runner.check(not orders.is_empty(), "profil %s : ordres diplomatiques émis" % profile)


func test_personalities_differ_in_war_appetite() -> void:
	var signatures: Dictionary = {}
	for profile: String in PERSONALITIES:
		var s := _session()
		for nid: String in s.state.nation_order:
			s.state.personalities[nid] = profile
		var view := IntelSystem.view_for(s.state, s.world, "france", s.rules)
		var score := DiplomaticAI._score(view, "german_empire", s.rules)
		signatures[profile] = snappedf(score, 0.01)
	runner.check(signatures.size() >= 5, "au moins cinq profils produisent des scores distincts (%d)" % signatures.size())


func test_seeds_are_reproducible_and_divergent() -> void:
	var a := _session("france", 1914)
	var b := _session("france", 1914)
	var c := _session("france", 2026)
	for i in 12:
		a.end_turn(); b.end_turn(); c.end_turn()
	runner.check(a.state.checksum() == b.state.checksum(), "même graine → résultat identique")
	runner.check(a.state.checksum() != c.state.checksum(), "graines différentes → campagnes différentes")


func test_controlled_variation_is_bounded_and_deterministic() -> void:
	var v1 := ControlledVariation.variation(1914, 3, "cle", "sel")
	var v2 := ControlledVariation.variation(1914, 3, "cle", "sel")
	var v3 := ControlledVariation.variation(7, 3, "cle", "sel")
	runner.check(v1 == v2, "bruit déterministe pour une même graine")
	runner.check(v1 != v3, "bruit différent selon la graine")
	runner.check(absf(v1) <= 1.0, "amplitude bornée à ±1 (%.3f)" % v1)


# ---------------------------------------------------------------- bruit diplomatique

func test_proposals_are_bounded() -> void:
	var s := _session()
	for i in 24:
		s.end_turn()
	var props := _count_orders(s, "propose_agreement")
	runner.check(props < 150, "propositions diplomatiques bornées (%d / 24 tours)" % props)


func test_no_false_hdi_victory_in_early_campaign() -> void:
	var s := _session()
	for i in 24:
		s.end_turn()
	runner.check(str(s.state.victory.get("status", "ongoing")) == "ongoing",
		"aucune victoire IDH artificielle au bout de 24 tours")
