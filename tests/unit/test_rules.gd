extends RefCounted
## Déplacements, souveraineté, occupation, batailles (T-029), diplomatie, logistique,
## économie, IA (non-omniscience).

var runner: Object


func _session(player: String = "france") -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1)
	return s


func _army(s: GameSession, nation: String) -> Dictionary:
	# Armée de garnison de la région-capitale (campagne historique, MIL-01).
	return s.state.formations["army_%s_%s" % [nation, s.state.nations[nation]["capital_region_id"]]]


func test_foreign_entry_requires_war_or_transit() -> void:
	var s := _session()
	var fr := _army(s, "france")
	var here: String = fr["region"]
	var foreign := ""
	for n: String in s.world.neighbor_ids(here):
		if s.state.controller(n) != "france":
			foreign = n
			break
	var own := ""
	for n: String in s.world.neighbor_ids(here):
		if s.state.controller(n) == "france":
			own = n
			break
	runner.check(own != "", "la capitale française a un voisin français")
	runner.check(s.queue_order(Orders.move("france", fr["id"], own)) == "", "déplacement intérieur autorisé")
	if foreign != "":
		runner.check(s.queue_order(Orders.move("france", fr["id"], foreign)) != "", "entrée non autorisée refusée (dossier §5.3)")
	runner.check(s.queue_order(Orders.move("france", "army_german_empire_region_028", own)) != "", "commandement national : formation étrangère refusée")
	var far := "region_069"
	runner.check(s.queue_order(Orders.move("france", fr["id"], far)) != "", "portée mensuelle limitée")


func test_transit_treaty_grants_passage() -> void:
	var s := _session("german_empire")
	# Allemagne (Berlin, 028) demande le passage à l'Autriche-Hongrie (alliée) ; l'IA autrichienne accepte.
	s.queue_order(Orders.propose_treaty("german_empire", "austria_hungary", "transit"))
	s.end_turn()
	s.end_turn()
	runner.check(s.state.has_transit("german_empire", "austria_hungary"), "passage accordé par l'allié (IA niveau 1)")
	var ger := _army(s, "german_empire")
	var target := ""
	for n: String in s.world.neighbor_ids(ger["region"]):
		if s.state.controller(n) == "austria_hungary":
			target = n
	if target == "":
		# Berlin n'est pas limitrophe : on vérifie la règle via MilitarySystem.can_enter.
		runner.check(MilitarySystem.can_enter(s.state, "german_empire", "region_036"), "entrée en territoire austro-hongrois autorisée")
	else:
		runner.check(s.queue_order(Orders.move("german_empire", ger["id"], target)) == "", "déplacement autorisé par le traité")


func test_war_occupation_keeps_sovereignty() -> void:
	var s := _session()
	var fr := _army(s, "france")
	# Rapprocher l'armée française de la frontière allemande (Paris 008 → Nord-Est 011 → Alsace-Lorraine 035).
	var path := s.world.shortest_path(fr["region"], "region_035")
	runner.check(path.size() >= 2, "chemin vers l'Alsace-Lorraine")
	s.queue_order(Orders.declare_war("france", "german_empire"))
	for i in range(1, path.size()):
		var step: String = path[i]
		var err := s.queue_order(Orders.move("france", fr["id"], step))
		runner.check(err == "", "étape %s acceptée : %s" % [step, err])
		s.end_turn()
	var rid: String = path[path.size() - 1]
	var defended := false
	for f: Dictionary in s.state.formations_in(rid):
		if f["nation"] == "german_empire":
			defended = true
	if not defended:
		runner.check(s.state.controller(rid) == "france", "région ennemie non défendue occupée")
		runner.check(s.state.sovereign(rid) == "german_empire", "la souveraineté reste allemande (occupation ≠ annexion)")
		runner.check(s.state.is_occupied(rid), "région marquée occupée")


func test_simultaneous_clash_creates_neutral_battle() -> void:
	var s := _session()
	var st := s.state
	st.wars.append({"id": "war_t", "a": "france", "b": "belgium", "since_turn": 0})
	# Placer deux formations dans des régions voisines puis les faire converger.
	st.formations["army_france_region_008"]["region"] = "region_007"
	var moves := [Orders.move("france", "army_france_region_008", "region_013"), Orders.move("belgium", "army_belgium_region_014", "region_013")]
	for m: Dictionary in moves:
		runner.check(MilitarySystem.validate_move(st, s.world, s.rules, m) == "", "mouvement valide : %s" % MilitarySystem.validate_move(st, s.world, s.rules, m))
	var clashes := MilitarySystem.resolve_moves(st, s.world, s.rules, moves)
	runner.check(clashes.size() == 1 and clashes[0]["region"] == "region_013", "affrontement simultané en 013")
	var battles := BattleSystem.create_battles(st, clashes)
	BattleSystem.resolve_all(st, s.world, s.rules, battles)
	runner.check(st.battles.size() == 1 and st.battles[0]["status"] == "resolved", "bataille close avant le tour suivant")
	runner.check(st.formations["army_france_region_008"]["region"] == "region_007", "résolveur neutre : retour à l'origine")
	runner.check(st.controller("region_013") == "belgium", "aucun changement de contrôle sans règle de combat")


func test_joint_command_and_pause_rules() -> void:
	var s := _session()
	var st := s.state
	# Phase II : règle isolée avec deux UNITÉS historiques (effectifs modifiés pour le test).
	var be := ""
	var nl := ""
	for fid: String in st.sorted_formation_ids():
		var f: Dictionary = st.formations[fid]
		if f["echelon"] != "unit":
			continue
		if f["nation"] == "belgium" and be == "":
			be = fid
		if f["nation"] == "netherlands" and nl == "":
			nl = fid
	st.formations[be]["soldiers"] = 1000
	st.formations[nl]["soldiers"] = 400
	var c := BattleSystem.joint_commander(st, [be, nl])
	runner.check(c["nation"] == "belgium", "commandement au pays fournissant le plus de soldats")
	st.formations[nl]["soldiers"] = 1000
	c = BattleSystem.joint_commander(st, [be, nl])
	runner.check(c["nation"] == "belgium", "égalité sans prestige connu : départage déterministe documenté (T-029 G ; identifiant croissant)")
	st.nations["belgium"]["military_prestige"] = 3
	st.nations["netherlands"]["military_prestige"] = 5
	c = BattleSystem.joint_commander(st, [be, nl])
	runner.check(c["nation"] == "netherlands", "égalité départagée par le prestige militaire")
	st.formations[be]["soldiers"] = null
	c = BattleSystem.joint_commander(st, [be, nl])
	runner.check(c["nation"] == null, "effectifs inconnus : indéterminé")
	var fr := _army(s, "france")
	var uk := _army(s, "united_kingdom")
	c = BattleSystem.joint_commander(st, [fr["id"], uk["id"]])
	runner.check(c["nation"] == ("france" if int(st.soldiers_of(fr["id"])) > int(st.soldiers_of(uk["id"])) else "united_kingdom"),
		"campagne historique : effectifs des unités pris en compte (%s)" % c["basis"])
	runner.check(BattleSystem.pause_allowed(["france"], {}), "solo : pause libre")
	runner.check(not BattleSystem.pause_allowed(["france", "united_kingdom"], {"france": true}), "multijoueur : unanimité requise")
	runner.check(BattleSystem.pause_allowed(["france", "united_kingdom"], {"france": true, "united_kingdom": true}), "unanimité atteinte")


func test_battle_queue_priority() -> void:
	var q := BattleSystem.queue([{"id": "b1", "order": 0, "critical": null}, {"id": "b2", "order": 1, "critical": true},
		{"id": "b3", "order": 2, "critical": null}])
	runner.check(q[0]["id"] == "b2" and q[1]["id"] == "b1" and q[2]["id"] == "b3", "critiques d'abord, puis chronologique")


func test_diplomacy_memory_and_break() -> void:
	var s := _session()
	var st := s.state
	s.queue_order(Orders.break_treaty("france", "t_franco_russian"))
	s.end_turn()
	var broken := false
	for t: Dictionary in st.treaties:
		if t["id"] == "t_franco_russian":
			broken = t["status"] == "broken"
	runner.check(broken, "traité rompu")
	var remembered := false
	for m: Dictionary in st.memory["russian_empire"]:
		if m["kind"] == "treaty_broken" and m["about"] == "france":
			remembered = true
	runner.check(remembered, "la Russie mémorise la rupture")
	s.queue_order(Orders.propose_treaty("france", "russian_empire", "transit"))
	s.end_turn()
	s.end_turn()
	runner.check(not st.has_transit("france", "russian_empire"), "l'IA refuse après une trahison mémorisée")
	s.queue_order(Orders.message("france", "public", [], "Déclaration publique"))
	s.end_turn()
	runner.check(DiplomacySystem.visible_messages(st, "italy").size() >= 1, "message public visible de tous")


func test_ai_view_is_not_omniscient() -> void:
	var s := _session()
	var view := IntelSystem.view_for(s.state, s.world, "portugal")
	var sees_russian := false
	for f: Dictionary in view["formations"]:
		if f["nation"] == "russian_empire":
			sees_russian = true
		if f["nation"] != "portugal":
			runner.check(f["soldiers"] == null, "effectifs étrangers masqués")
	runner.check(not sees_russian, "le Portugal ne voit pas l'armée russe")
	runner.check(not view.has("nations"), "la vue ne contient pas l'état complet")


func test_ai_defends_and_counterattacks() -> void:
	var s := _session("france")
	s.queue_order(Orders.declare_war("france", "belgium"))
	s.end_turn()
	var st := s.state
	runner.check(st.at_war("france", "belgium"), "guerre déclarée")
	# Occupation d'une région belge non défendue par la France, puis réaction de l'IA belge.
	st.formations["army_france_region_008"]["region"] = "region_007"
	var belgian_regions := st.regions_controlled_by("belgium")
	var target := ""
	for n: String in s.world.neighbor_ids("region_007"):
		if belgian_regions.has(n) and st.formations_in(n).is_empty():
			target = n
	if target != "":
		s.queue_order(Orders.move("france", "army_france_region_008", target))
		s.end_turn()
		runner.check(st.controller(target) == "france", "région belge occupée")
		var orders := NationAgent.decide(IntelSystem.view_for(st, s.world, "belgium"), s.world, s.rules)
		var peace := false
		for o: Dictionary in orders:
			if o["type"] == Orders.PROPOSE_TREATY and o["kind"] == "peace":
				peace = true
		runner.check(peace, "l'IA belge propose la paix après une perte de territoire")
		s.end_turn()
		var again := NationAgent.decide(IntelSystem.view_for(st, s.world, "belgium"), s.world, s.rules)
		runner.check(again.filter(func(o: Dictionary) -> bool: return o["type"] == Orders.PROPOSE_TREATY and o["kind"] == "peace").is_empty(),
			"pas de nouvelle proposition de paix tant que la précédente est en attente")


func test_logistics_cut_off() -> void:
	var s := _session()
	var st := s.state
	st.formations["army_france_region_008"]["region"] = "region_007"
	LogisticsSystem.update_supply(st, s.world)
	runner.check(st.formations["army_france_region_008"]["supplied"], "formation reliée à la capitale")
	st.regions["region_008"]["controller"] = "german_empire"  # capitale perdue
	LogisticsSystem.update_supply(st, s.world)
	runner.check(not st.formations["army_france_region_008"]["supplied"], "capitale perdue : formation coupée")
	var summary := LogisticsSystem.summary(st, s.world, "france")
	# Phase IV : « livré » est un nombre de régions atteignables par le réseau (0 ici, capitale perdue).
	runner.check(int(summary["delivered"]) == 0, "« livré » = 0 sans continuité depuis la capitale")


func test_economy_unknowns_propagate() -> void:
	var s := _session()
	var bal := EconomySystem.national_balance(s.state, s.world, "france", ["ressource_test"])
	runner.check(bal["ressource_test"]["produced"] == null, "donnée absente → production inconnue, jamais 0")
	for rid: String in s.state.regions_controlled_by("france"):
		var eco: Dictionary = s.state.regions[rid]["economy"]
		eco["potential"] = {"ressource_test": 2.0}
		eco["exploitation_capacity"] = 1.0
		eco["infrastructure_level"] = 0.5
	bal = EconomySystem.national_balance(s.state, s.world, "france", ["ressource_test"])
	runner.check(is_equal_approx(float(bal["ressource_test"]["produced"]), 6.0), "6 régions × 1,0 (formule proposée)")
	runner.check(EconomySystem.validate_allocation(s.rules, Orders.industry_allocation("france", {"industrie_navale": 60, "industrie_civile": 50})) != "", "priorités > 100 % refusées")
	runner.check(EconomySystem.validate_allocation(s.rules, Orders.industry_allocation("france", {"acier": 10})) != "", "catégorie inconnue refusée")
	runner.check(s.queue_order(Orders.industry_allocation("france", {"industrie_navale": 40, "industrie_civile": 60})) == "", "priorités valides acceptées")
	s.end_turn()
	runner.check(int(s.state.nations["france"]["industry_allocation"]["industrie_navale"]) == 40, "priorités appliquées à la résolution")
