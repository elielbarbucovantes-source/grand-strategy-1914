class_name GameUI
extends CanvasLayer
## Interface de jeu : barre supérieure, panneau latéral rétractable à onglets, barre d'état.
## Aucune règle métier : les actions deviennent des ordres transmis à GameSession, et
## l'affichage provient de l'état ou de la vue filtrée du joueur.

signal request_menu
signal request_battle
signal request_planning(region_id: String)

const NOT_FUNCTIONAL := "[color=#b03a2e][b]NON FONCTIONNEL[/b][/color]"

var session: GameSession
var map_view: MapView
var tabs: TabContainer
var side: PanelContainer
var status: Label
var date_label: Label
var nation_label: Label
var share_label: Label
var battle_button: Button
var pages: Dictionary = {}    # nom -> VBoxContainer


func setup(s: GameSession, m: MapView) -> void:
	session = s
	map_view = m
	map_view.region_clicked.connect(_on_region_clicked)
	_build()
	refresh()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	add_child(top)
	var bar := HBoxContainer.new()
	top.add_child(bar)
	date_label = _label(bar, "", 18)
	nation_label = _label(bar, "", 16)
	share_label = _label(bar, "", 13)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	battle_button = _button(bar, "⚔ Bataille en cours", func() -> void: request_battle.emit())
	_button(bar, "Fin du mois ▶", _on_end_turn)
	_button(bar, "Sauvegarder", _on_save)
	_button(bar, "Charger", _on_load)
	_button(bar, "Menu", func() -> void: request_menu.emit())
	_button(bar, "Panneau ⇆", func() -> void: side.visible = not side.visible)
	side = PanelContainer.new()
	side.anchor_left = 1.0; side.anchor_right = 1.0; side.anchor_top = 0.0; side.anchor_bottom = 1.0
	side.offset_left = -440; side.offset_top = 44; side.offset_bottom = -30
	add_child(side)
	tabs = TabContainer.new()
	side.add_child(tabs)
	for name in ["Pays", "Diplomatie", "Économie", "Industrie", "Armée", "Logistique", "Recherche", "Renseignement", "Événements", "Ordres"]:
		var scroll := ScrollContainer.new()
		scroll.name = name
		tabs.add_child(scroll)
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(box)
		pages[name] = box
	tabs.tab_changed.connect(func(_i: int) -> void: refresh())
	status = Label.new()
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status.offset_top = -26
	status.add_theme_color_override("font_color", Color("#1b1b1b"))
	add_child(status)


func _label(parent: Node, text: String, size: int = 14) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _rich(parent: Node, bbcode: String) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.text = bbcode
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(r)
	return r


func _clear(page: String) -> VBoxContainer:
	var box: VBoxContainer = pages[page]
	for c in box.get_children():
		c.queue_free()
	return box


func say(text: String) -> void:
	status.text = text


func _n(nid: String) -> String:
	return session.state.nations[nid]["name_fr"]


# ------------------------------------------------------------------ rafraîchissement
func refresh() -> void:
	var st := session.state
	date_label.text = "  %s  " % st.date_label()
	nation_label.text = "%s  " % _n(st.player_nation)
	share_label.text = "Contrôle : %.1f %% des régions (seuil de 90 %% validé ; calcul OUVERT)" % (100.0 * session.territorial_share(st.player_nation))
	battle_button.visible = not session.current_battle().is_empty()
	var current := tabs.get_tab_title(tabs.current_tab)
	match current:
		"Pays": _page_country()
		"Diplomatie": _page_diplomacy()
		"Économie": _page_economy()
		"Industrie": _page_industry()
		"Armée": _page_army()
		"Logistique": _page_logistics()
		"Recherche": _page_research()
		"Renseignement": _page_intel()
		"Événements": _page_events()
		"Ordres": _page_orders()
	map_view.refresh()


func _page_country() -> void:
	var box := _clear("Pays")
	var st := session.state
	var rid := map_view.selected_region
	if rid != "":
		var r: Dictionary = session.world.regions[rid]
		var text := "[b]%s[/b]  (%s)\n" % [r["name_fr"], rid]
		text += "Souveraineté : %s\nContrôle militaire : %s%s\n" % [_n(st.sovereign(rid)), _n(st.controller(rid)),
			"  [color=#b03a2e](occupée)[/color]" if st.is_occupied(rid) else ""]
		text += "Zone : %s ; relief : %s\nCôte : %s ; superficie : %s km²\n" % [r["zone"], ", ".join(r["relief_categories"]),
			"oui" if r["has_coastline"] else "non", str(r["area_km2"])]
		var cities: Array = (r["city_ids"] as Array).map(func(c: String) -> String:
			return session.world.cities[c]["name_fr"] + (" ★" if session.world.cities[c]["is_capital"] else ""))
		text += "Villes : %s\n" % (", ".join(cities) if not cities.is_empty() else "—")
		var neigh: Array = []
		for n: Dictionary in session.world.neighbors[rid]:
			neigh.append(session.world.regions[n["to"]]["name_fr"] + (" (détroit)" if n["kind"] == "strait" else ""))
		text += "Voisins : %s\n" % ", ".join(neigh)
		text += "Zones maritimes : %s\n" % (", ".join(session.world.maritime_links[rid]) if not (session.world.maritime_links[rid] as Array).is_empty() else "—")
		text += "Économie régionale : [i]données à sourcer (modèle C validé, ECO-02 ouvert)[/i]\n"
		_rich(box, text)
	var nid := st.controller(rid) if rid != "" else st.player_nation
	var n: Dictionary = st.nations[nid]
	var t := "\n[b]Pays : %s[/b]\nCapitale : %s\nRégions contrôlées : %d ; jouable : %s\n" % [n["name_fr"],
		session.world.cities[n["capital_city_id"]]["name_fr"], st.regions_controlled_by(nid).size(), "oui" if n["playable"] else "non"]
	t += "Population : [i]inconnue (NAT-02)[/i]\n[b]Statistiques nationales[/b] (NAT-01 à définir) :\n"
	for key: String in n["stats"]:
		var v: Variant = n["stats"][key]["value"]
		t += "  • %s : %s\n" % [key.replace("_", " "), "[i]inconnu[/i]" if v == null else str(v)]
	_rich(box, t)


func _page_diplomacy() -> void:
	var box := _clear("Diplomatie")
	var st := session.state
	var me := st.player_nation
	for p: Dictionary in DiplomacySystem.pending_for(st, me):
		var row := HBoxContainer.new()
		box.add_child(row)
		_label(row, "Proposition de %s : %s" % [_n(p["from"]), p["kind"]], 13)
		_button(row, "Accepter", func() -> void: _queue(Orders.respond(me, p["id"], true)))
		_button(row, "Refuser", func() -> void: _queue(Orders.respond(me, p["id"], false)))
	_rich(box, "[b]Relations[/b] — effets des alliances, garanties et accords commerciaux : [i]OUVERTS (DIP-02), enregistrés sans effet[/i] ; passage : [b]effectif[/b].")
	for nid: String in st.nation_order:
		if nid == me:
			continue
		var tags: Array = []
		if st.at_war(me, nid):
			tags.append("[color=#b03a2e]GUERRE[/color]")
		for t: Dictionary in st.active_treaties_between(me, nid):
			tags.append(t["type"])
		if st.has_transit(me, nid):
			tags.append("passage accordé")
		_rich(box, "[b]%s[/b] %s" % [_n(nid), " ; ".join(tags)])
		var row := HBoxContainer.new()
		box.add_child(row)
		if st.at_war(me, nid):
			_button(row, "Proposer la paix", func() -> void: _queue(Orders.propose_treaty(me, nid, "peace")))
		else:
			_button(row, "Déclarer la guerre", func() -> void: _queue(Orders.declare_war(me, nid)))
			_button(row, "Demander le passage", func() -> void: _queue(Orders.propose_treaty(me, nid, "transit")))
			_button(row, "Alliance", func() -> void: _queue(Orders.propose_treaty(me, nid, "alliance")))
			_button(row, "Commerce", func() -> void: _queue(Orders.propose_treaty(me, nid, "trade")))
	_rich(box, "\n[b]Traités[/b]")
	for t: Dictionary in st.treaties:
		if t["status"] == "active" and (t["members"] as Array).has(me):
			var row := HBoxContainer.new()
			box.add_child(row)
			_label(row, "%s : %s" % [t["type"], ", ".join((t["members"] as Array).map(func(x: String) -> String: return _n(x)))], 12)
			_button(row, "Rompre", func() -> void: _queue(Orders.break_treaty(me, t["id"])))
	_rich(box, "\n[b]Messages[/b] (canaux public, privé, groupe)")
	for m: Dictionary in DiplomacySystem.visible_messages(st, me).slice(-10):
		_rich(box, "[%s] %s : %s" % [m["channel"], _n(m["from"]), m["text"]])
	var edit := LineEdit.new()
	edit.placeholder_text = "Message public…"
	box.add_child(edit)
	_button(box, "Envoyer (public)", func() -> void:
		if edit.text.strip_edges() != "":
			_queue(Orders.message(me, "public", [], edit.text.strip_edges())))


func _page_economy() -> void:
	var box := _clear("Économie")
	var cats: Array = session.rules["economy"]["resource_categories"]
	var t := "[b]Modèle C[/b] (VALIDÉ) : production régionale selon le potentiel, les capacités et les infrastructures ; stocks nationaux ; accessibilité selon la logistique.\n\n"
	if cats.is_empty():
		t += "%s — catégories de ressources non définies (R-03 ouvert) ; données régionales à sourcer (ECO-01/02).\n" % NOT_FUNCTIONAL
	else:
		var bal := EconomySystem.national_balance(session.state, session.world, session.state.player_nation, cats)
		for k: String in bal:
			t += "%s : produit %s ; accessible %s ; livré %s\n" % [k, str(bal[k]["produced"]), str(bal[k]["accessible"]), str(bal[k]["delivered"])]
	t += "\nBudget mensuel : %s — structure prévue, catégories et formules OUVERTES (ECO-05).\nCommerce : accords enregistrables (onglet Diplomatie), effets OUVERTS (ECO-04)." % NOT_FUNCTIONAL
	_rich(box, t)


func _page_industry() -> void:
	var box := _clear("Industrie")
	var st := session.state
	_rich(box, "[b]Priorités gouvernementales[/b] entre les cinq catégories industrielles (VALIDÉES). Les capacités sont inconnues (données à sourcer) : les priorités sont enregistrées et résolues, mais sans effet de production mesurable.")
	var alloc: Dictionary = st.nations[st.player_nation]["industry_allocation"]
	var spins: Dictionary = {}
	for cat: String in session.rules["economy"]["industry_categories"]:
		var row := HBoxContainer.new()
		box.add_child(row)
		var l := _label(row, cat.replace("_", " "), 12)
		l.custom_minimum_size.x = 250
		var sp := SpinBox.new()
		sp.max_value = 100
		sp.suffix = "%"
		sp.value = float(alloc.get(cat, 0))
		row.add_child(sp)
		spins[cat] = sp
	_button(box, "Appliquer les priorités (ordre du mois)", func() -> void:
		var a: Dictionary = {}
		for cat: String in spins:
			a[cat] = int((spins[cat] as SpinBox).value)
		_queue(Orders.industry_allocation(st.player_nation, a)))


func _page_army() -> void:
	var box := _clear("Armée")
	var st := session.state
	_rich(box, "Hiérarchie VALIDÉE : soldats et équipements → unités → régiments → divisions → armées. Effectifs et composition : [i]inconnus (MIL-01)[/i].\nSélectionnez une formation, puis cliquez une région voisine sur la carte pour ordonner un déplacement (portée provisoire : 1 région par mois).")
	for f: Dictionary in st.formations_of(st.player_nation):
		if not st.is_top_level(f):
			continue
		var row := HBoxContainer.new()
		box.add_child(row)
		var txt := "%s — %s%s%s" % [f["name_fr"], session.world.regions[f["region"]]["name_fr"],
			"" if f["supplied"] else " (coupée)", (" → " + session.world.regions[f["planned_target"]]["name_fr"]) if f["planned_target"] != "" else ""]
		_label(row, txt, 13)
		var b := _button(row, "Sélectionnée" if map_view.selected_formation == f["id"] else "Sélectionner", func() -> void:
			map_view.selected_formation = "" if map_view.selected_formation == f["id"] else f["id"]
			map_view.center_on(f["region"])
			refresh())
		b.toggle_mode = true
		b.button_pressed = map_view.selected_formation == f["id"]
		var soldiers: Variant = st.soldiers_of(f["id"])
		var extra := "Effectif : %s ; moral d'armée : %s%s%s" % ["[i]inconnu (MIL-01)[/i]" if soldiers == null else str(soldiers),
			"—" if f.get("morale") == null else "%.0f" % float(f["morale"]), " ; [color=#b03a2e]ENCERCLÉE[/color]" if f.get("encircled", false) else "",
			" ; [color=#b03a2e]ENGAGÉE[/color]" if st.is_engaged(f["id"]) else ""]
		_rich(box, extra)
		for uid: String in st.units_of(f["id"]):
			var su: Dictionary = st.formations[uid]
			var urow := HBoxContainer.new()
			box.add_child(urow)
			_label(urow, "   %s : %s soldats, moral %s" % [su["name_fr"], str(su.get("soldiers")), "—" if su.get("morale") == null else "%.0f" % float(su["morale"])], 11)
			var rb := CheckBox.new()
			rb.text = "réserve"
			rb.button_pressed = bool(su.get("reserve", false))
			rb.toggled.connect(func(on: bool) -> void:
				var err := session.set_reserve(uid, on)
				say(("Réserve : " + ("oui" if on else "non")) if err == "" else ("Refusé : " + err)))
			urow.add_child(rb)
		_button(box, "Préparer les défenses de %s" % session.world.regions[f["region"]]["name_fr"], func() -> void: request_planning.emit(f["region"]))
	_rich(box, "\nMobilisation et création de formations : %s (règles MIL-02 ouvertes).\nBatailles : règles T-029 de synchronisation, commandement et pause implémentées ; [b]résolution du combat OUVERTE[/b] : un affrontement est clos sans issue (résolveur neutre provisoire)." % NOT_FUNCTIONAL)
	if not st.battles.is_empty():
		_rich(box, "\n[b]Dernières batailles[/b]")
		for b: Dictionary in st.battles.slice(-5):
			_rich(box, "%s, %s : %s" % [b["date"], session.world.regions[b["region"]]["name_fr"], b["resolution"]["status"]])


func _page_logistics() -> void:
	var box := _clear("Logistique")
	var s := LogisticsSystem.summary(session.state, session.world, session.state.player_nation)
	var t := "Continuité territoriale (implémentée) : régions contrôlées %d ; accessibles depuis la capitale %d.\n" % [s["controlled"], s["accessible"]]
	if not (s["cut_off"] as Array).is_empty():
		t += "[color=#b03a2e]Régions coupées :[/color] %s\n" % ", ".join((s["cut_off"] as Array).map(func(r: String) -> String: return session.world.regions[r]["name_fr"]))
	t += "Ressources livrées : %s — capacités de transport non définies ; réseau ferré des données fragmenté (17 composantes).\nConséquences d'un mauvais ravitaillement : OUVERTES (aucune pénalité appliquée)." % NOT_FUNCTIONAL
	_rich(box, t)


func _page_research() -> void:
	_rich(_clear("Recherche"), "%s — l'arbre technologique (1914–1945) n'est pas défini. La structure des projets existe (ResearchSystem) ; aucune technologie n'est inventée." % NOT_FUNCTIONAL)


func _page_intel() -> void:
	var box := _clear("Renseignement")
	var view := IntelSystem.view_for(session.state, session.world, session.state.player_nation)
	var foreign := (view["formations"] as Array).filter(func(f: Dictionary) -> bool: return f["nation"] != session.state.player_nation)
	var t := "Vue nationale (implémentée) : %d régions observées ; %d formation(s) étrangère(s) visible(s), effectifs masqués.\n" % [(view["visible_regions"] as Dictionary).size(), foreign.size()]
	for f: Dictionary in foreign:
		t += "  • %s en %s\n" % [_n(f["nation"]), session.world.regions[f["region"]]["name_fr"]]
	t += "\nInterception, décryptage, espionnage industriel : %s (INT-01/02 ouverts)." % NOT_FUNCTIONAL
	_rich(box, t)


func _page_events() -> void:
	var box := _clear("Événements")
	var ev: Array = session.state.events.duplicate()
	ev.reverse()
	for e: Dictionary in ev.slice(0, 60):
		_rich(box, "[color=#555]%s[/color] [b]%s[/b] — %s" % [e["date"], e["category"], e["text"]])


func _page_orders() -> void:
	var box := _clear("Ordres")
	_rich(box, "[b]Ordres préparés ce mois[/b] (secrets, résolus simultanément à la fin du mois)")
	for o: Dictionary in session.player_orders():
		_rich(box, "• " + _describe(o))
	_button(box, "Annuler tous les ordres", func() -> void:
		session.cancel_orders()
		say("Ordres annulés.")
		refresh())
	var rep := session.last_report
	if not rep.is_empty() and not (rep["rejected"] as Array).is_empty():
		_rich(box, "\n[b]Ordres rejetés au dernier tour[/b]")
		for r: Dictionary in rep["rejected"]:
			if r["order"]["nation"] == session.state.player_nation:
				_rich(box, "• %s — %s" % [_describe(r["order"]), r["reason"]])


func _describe(o: Dictionary) -> String:
	match o["type"]:
		Orders.MOVE:
			return "Déplacer %s vers %s" % [session.state.formations[o["formation"]]["name_fr"], session.world.regions[o["target"]]["name_fr"]]
		Orders.DECLARE_WAR:
			return "Déclarer la guerre à %s" % _n(o["target"])
		Orders.PROPOSE_TREATY:
			return "Proposer « %s » à %s" % [o["kind"], _n(o["to"])]
		Orders.RESPOND_PROPOSAL:
			return "%s la proposition %s" % ["Accepter" if o["accept"] else "Refuser", o["proposal"]]
		Orders.BREAK_TREATY:
			return "Rompre %s" % o["treaty"]
		Orders.SEND_MESSAGE:
			return "Message %s : %s" % [o["channel"], o["text"]]
		Orders.SET_INDUSTRY_ALLOCATION:
			return "Priorités industrielles %s" % JSON.stringify(o["allocation"])
	return o["type"]


# ------------------------------------------------------------------ actions
func _queue(order: Dictionary) -> void:
	var err := session.queue_order(order)
	say(("Ordre préparé : " + _describe(order)) if err == "" else ("Ordre refusé : " + err))
	refresh()


func _on_region_clicked(rid: String) -> void:
	if map_view.selected_formation != "":
		_queue(Orders.move(session.state.player_nation, map_view.selected_formation, rid))
		return
	map_view.selected_region = rid
	tabs.current_tab = 0
	refresh()


func _on_end_turn() -> void:
	var rep := session.end_turn()
	if rep.has("error"):
		say(rep["error"])
		refresh()
		return
	var mine := (rep["rejected"] as Array).filter(func(r: Dictionary) -> bool: return r["order"]["nation"] == session.state.player_nation)
	say("%s résolu : %d ordre(s) exécuté(s) (tous pays), %d bataille(s), %d ordre(s) refusé(s) pour vous." % [rep["resolved_month"], rep["accepted"], rep["battles"], mine.size()])
	refresh()
	if not session.current_battle().is_empty():
		request_battle.emit()


func _on_save() -> void:
	var name := "partie_%s_tour%d" % [session.state.player_nation, session.state.turn]
	var err := session.save_game(name)
	say(("Sauvegardé : user://saves/%s.json" % name) if err == "" else ("Échec de la sauvegarde : " + err))


func _on_load() -> void:
	var saves := SaveRepository.list_saves(GameSession.SAVE_DIR)
	if saves.is_empty():
		say("Aucune sauvegarde.")
		return
	var err := session.load_game(saves[saves.size() - 1])
	say(("Chargé : " + saves[saves.size() - 1]) if err == "" else ("Chargement refusé : " + err))
	if err == "":
		map_view.setup(session)
		refresh()
