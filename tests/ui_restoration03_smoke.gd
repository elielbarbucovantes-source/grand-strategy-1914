extends SceneTree
## RESTORATION 03 — tests de fumée des nouvelles sections d'interface, sans rendu.
##   godot --headless --path . --script tests/ui_restoration03_smoke.gd
## Pilote la vraie scène et les vrais systèmes : aucune valeur fictive n'est acceptée.

var failures := 0


func check(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		printerr("  ✗ " + msg)
	else:
		print("  ✓ " + msg)


func _buttons(node: Node, text: String) -> Array:
	var out: Array = []
	if node is Button and (node as Button).text == text:
		out.append(node)
	for c: Node in node.get_children():
		out.append_array(_buttons(c, text))
	return out


func _text_of(node: Node) -> String:
	var out := ""
	if node is RichTextLabel:
		out += (node as RichTextLabel).get_parsed_text() + "\n"
	for c: Node in node.get_children():
		out += _text_of(c)
	return out


func _open(ui: GameUI, title: String) -> void:
	for i in ui.tabs.get_tab_count():
		if ui.tabs.get_tab_title(i) == title:
			ui.tabs.current_tab = i
			ui.refresh()
			return


func _initialize() -> void:
	# 1. Largeur adaptative aux deux résolutions demandées.
	check(is_equal_approx(GameUI.panel_width_for(1600.0), 520.0), "1600×900 : panneau 520 px")
	check(is_equal_approx(GameUI.panel_width_for(1280.0), 460.0), "1280×720 : panneau 460 px")

	var main: Node = load("res://src/ui/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var session: GameSession = main.session
	check(session.new_game("france", 1, 1914) == "", "partie réelle France 1914")
	main._start_game()
	await process_frame
	var ui: GameUI = main.game_ui
	var st := session.state
	var me := st.player_nation

	# 2. Économie : consultation avec valeurs réelles.
	_open(ui, "Économie")
	await process_frame
	var eco_text := _text_of(ui.pages["Économie"])
	check(eco_text.contains("Commerce international"), "section commerce affichée")
	check(eco_text.contains("prix PROPOSÉS"), "prix identifiés comme propositions")
	check(eco_text.contains("réserve industrielle"), "besoins industriels affichés")
	var coal_stock := ResourceSystem.available(st, me, "coal")
	check(eco_text.contains("%.1f" % coal_stock), "stock affiché = stock réel (%.1f)" % coal_stock)

	# 3. Vente réelle via le bouton UI (ordre validé par MarketSystem).
	var partner := "belgium"
	# Conditions valides pour TOUS les partenaires : le sélecteur UI choisit le premier
	# de la liste (ordre stable des nations), pas nécessairement la Belgique.
	for nid: String in st.nation_order:
		if nid == me:
			continue
		st.economy["stocks"][nid]["money"] = 1000.0
		st.economy["stocks"][nid]["coal"] = maxf(50.0, float(st.economy["stocks"][nid].get("coal", 0.0)))
		st.treaties.append({"id": "ui_transit_" + nid, "type": "transit", "members": [me, nid],
			"status": "active", "grantor": nid, "grantee": me, "terms": {}})
	st.economy["stocks"][me]["coal"] = 50.0
	_open(ui, "Économie")
	await process_frame
	var sell_buttons := _buttons(ui.pages["Économie"], "Vendre")
	check(sell_buttons.size() == 1, "bouton Vendre présent")
	if not sell_buttons.is_empty():
		sell_buttons[0].pressed.emit()
		await process_frame
	var orders = session.player_orders()
	var found_trade := false
	for o: Dictionary in orders:
		if str(o["type"]) == "trade" and str(o["from"]) == me:
			found_trade = true
	check(found_trade, "ordre de vente préparé par l'UI")
	check(not ui.status.text.begins_with("Ordre refusé"), "vente validée par le système : %s" % ui.status.text)

	# 3b. Demande d'achat : proposition diplomatique, exécutée seulement après acceptation.
	st.economy["stocks"]["belgium"]["coal"] = 50.0
	st.economy["stocks"][me]["money"] = 1000.0
	_open(ui, "Économie")
	await process_frame
	var buy_buttons := _buttons(ui.pages["Économie"], "Demander achat")
	check(buy_buttons.size() == 1, "bouton Demander achat présent")
	if not buy_buttons.is_empty():
		buy_buttons[0].pressed.emit()
		await process_frame
	var purchase: Dictionary = {}
	for o: Dictionary in session.player_orders():
		if str(o["type"]) == "propose_agreement" and str(o.get("kind", "")) == "trade" \
			and str(o.get("terms", {}).get("request", "")) == "purchase":
			purchase = o
	check(not purchase.is_empty(), "demande d'achat préparée sans prélèvement unilatéral")
	var trades_before := (st.economy["trade"] as Array).size()
	if not purchase.is_empty():
		var fake := {"type": "propose_agreement", "nation": me, "to": purchase["to"],
			"kind": "trade", "terms": purchase["terms"]}
		DiplomacySystem.resolve(st, [fake], session.rules)
		var last: Dictionary = st.proposals[-1]
		DiplomacySystem.resolve(st, [Orders.respond(partner, str(last["id"]), true)], session.rules)
	check((st.economy["trade"] as Array).size() > trades_before,
		"achat exécuté après acceptation du partenaire")

	# 4. Livraison en cours : l'UI ne doit jamais la présenter comme livrée trop tôt.
	var propose_err := MarketSystem.propose(st, session.transport_network, session.rules,
		Orders.trade(me, me, partner, "coal", 10.0))
	_open(ui, "Économie")
	await process_frame
	eco_text = _text_of(ui.pages["Économie"])
	var idx := eco_text.find("transit")
	var i2 := eco_text.find("Expéditions")
	check(eco_text.contains("en transit"), "expédition affichée comme en transit")
	check(not eco_text.contains("livrée T%s" % str(st.turn)), "pas de livraison anticipée")

	# 5. Recherche : arbre, coopération, proposition d'accord.
	_open(ui, "Recherche")
	await process_frame
	var tech_text := _text_of(ui.pages["Recherche"])
	check(tech_text.contains("Arbre technologique"), "arbre technologique affiché")
	check(tech_text.contains("Coopération scientifique"), "coopération scientifique affichée")
	check(tech_text.contains("découverte"), "statut des technologies affiché")
	var propose_buttons := _buttons(ui.pages["Recherche"], "Proposer")
	check(not propose_buttons.is_empty(), "bouton de coopération présent")
	if not propose_buttons.is_empty():
		propose_buttons[0].pressed.emit()
		await process_frame
	var found_tech := false
	for o: Dictionary in session.player_orders():
		if str(o["type"]) == "propose_agreement" and str(o.get("kind", "")) == "tech":
			found_tech = true
	check(found_tech, "proposition de coopération scientifique préparée")

	# 6. Transfert réel : affiché avec son coût et son délai, sans révéler les tiers.
	st.tech["known"]["german_empire"] = ["electrification"]
	st.tech["cooperation"].append({"id": "coop_ui", "turn": 0, "members": ["german_empire", me],
		"expires_turn": 24, "status": "active"})
	st.economy["stocks"][me]["money"] = 1000.0
	TechSystem.monthly(st, session.tech_tree, session.rules["phase6"])
	_open(ui, "Recherche")
	await process_frame
	tech_text = _text_of(ui.pages["Recherche"])
	check(tech_text.contains("coût"), "coût de transfert affiché")
	check(tech_text.contains("arrivée T"), "délai de transfert affiché")

	# 7. Diplomatie : historique du joueur uniquement.
	RelationsSystem.record(st, me, partner, "alliance_exit", "test_ui", session.rules)
	# Un tiers ne doit jamais voir sa mémoire propre exposée au joueur.
	st.memory["german_empire"] = [{"turn": 99, "about": "france", "kind": "secret_test", "detail": "MEMOIRE_SECRETE_TIERS"}]
	_open(ui, "Diplomatie")
	await process_frame
	var dip_text := _text_of(ui.pages["Diplomatie"])
	check(dip_text.contains("Historique et confiance"), "section historique affichée")
	check(dip_text.contains("réputation"), "réputation réelle affichée")
	check(dip_text.contains("alliance_exit"), "rupture enregistrée visible")
	check(dip_text.contains("retrait négocié"), "nature de la rupture distinguée")
	check(not dip_text.contains("MEMOIRE_SECRETE_TIERS"), "mémoire d'un tiers non exposée")
	check(not dip_text.contains("secret_test"), "type de mémoire d'un tiers non exposé")

	# 8. Sauvegarde / chargement pendant un accord commercial et scientifique actif.
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/r03_ui.json"
	check(SaveRepository.save(path, st, session.world, session.rules) == "", "sauvegarde en cours d'accord")
	var loaded := SaveRepository.load_save(path, session.world, session.rules)
	check(not loaded.has("error"), "rechargement réussi")
	var st2: GameState = loaded["state"]
	check((st2.economy["trade"] as Array).size() > 0, "expédition persistée")
	check((st2.tech["cooperation"] as Array).size() > 0, "coopération persistée")
	check((st2.tech["transfers"] as Array).size() > 0, "transfert persisté")
	check(st2.checksum() == st.checksum(), "empreinte identique")

	# 9. Aucune donnée fictive dans les nouvelles sections.
	var fake_markers := ["NON FONCTIONNEL", "valeurs de test", "FICTIVE"]
	for marker: String in fake_markers:
		check(not eco_text.contains(marker), "pas de marqueur fictif en Économie : %s" % marker)
		check(not tech_text.contains(marker), "pas de marqueur fictif en Recherche : %s" % marker)

	print("RÉSULTAT UI R03 : %d échec(s)" % failures)
	quit(1 if failures > 0 else 0)
