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
const TAB_NAMES: Array[String] = ["Pays", "Diplomatie", "Économie", "Industrie", "Armée",
	"Logistique", "Recherche", "Renseignement", "Politique", "Victoire", "Multijoueur",
	"Événements", "Ordres"]
var nav_bar: HFlowContainer
var nav_buttons: Dictionary = {}
var approach := "assault"     # approche offensive des prochains ordres de déplacement (T-055)


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
	# Phase IV : barre de couches cartographiques (compacte, sous la barre principale).
	var layer_bar := HBoxContainer.new()
	layer_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	layer_bar.offset_top = 44
	add_child(layer_bar)
	for layer: String in ["rail", "road", "river", "maritime", "ports", "interruptions", "capacity",
		"resources", "industry", "population", "agriculture", "stocks",
		"airbases", "fleets", "intel_activity", "rivers", "bridges"]:
		_button(layer_bar, layer, func() -> void:
			map_view.toggle_layer(layer)
			map_view.queue_redraw())
	side = PanelContainer.new()
	side.anchor_left = 1.0; side.anchor_right = 1.0; side.anchor_top = 0.0; side.anchor_bottom = 1.0
	# Consolidation 02 : panneau plus large et navigation adaptative (1280x720 et 1600x900).
	var panel_width := 520.0
	var viewport_w := float(get_viewport().size.x) if get_viewport() != null else 1600.0
	if viewport_w > 0.0 and viewport_w < 1400.0:
		panel_width = 460.0
	side.offset_left = -panel_width; side.offset_top = 84; side.offset_bottom = -30
	add_child(side)
	var side_box := VBoxContainer.new()
	side.add_child(side_box)
	# Barre de navigation à retournement automatique : les 13 rubriques restent toutes visibles.
	nav_bar = HFlowContainer.new()
	nav_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_box.add_child(nav_bar)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_box.add_child(tabs)
	var tab_bar := tabs.get_tab_bar()
	if tab_bar != null:
		tab_bar.visible = false  # évite les flèches tronquées ; nav_bar assure l'accès
	for name in TAB_NAMES:
		var scroll := ScrollContainer.new()
		scroll.name = name
		if name == "Armée":
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tabs.add_child(scroll)
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(box)
		pages[name] = box
		var btn := _button(nav_bar, name, func() -> void: _open_tab(name))
		nav_buttons[name] = btn
	tabs.tab_changed.connect(func(_i: int) -> void:
		_update_nav_highlight()
		refresh())
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


func _open_tab(name: String) -> void:
	if tabs == null:
		return
	for i in tabs.get_tab_count():
		if tabs.get_tab_title(i) == name:
			tabs.current_tab = i
			_update_nav_highlight()
			return


func _update_nav_highlight() -> void:
	if tabs == null:
		return
	var current := tabs.get_tab_title(tabs.current_tab)
	for name: String in nav_buttons:
		var b: Button = nav_buttons[name]
		b.modulate = Color.WHITE if name == current else Color(0.72, 0.72, 0.72)


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
	share_label.text = "Contrôle : %.1f %% des régions (seuil 90 %% ; victoire : %s)" % [100.0 * session.territorial_share(st.player_nation), str(st.victory.get("status", "ongoing"))]
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
		"Politique": _page_politics()
		"Victoire": _page_victory()
		"Multijoueur": _page_multiplayer()
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
		var ri := IntelSystem.region_intel(st, session.world, st.player_nation, rid, session.rules)
		text += "Renseignement militaire : %s\n" % _format_region_intel(ri)
		var baseline: Dictionary = st.economy.get("regions", {}).get(rid, {})
		if baseline.is_empty():
			text += "Économie régionale : [i]données indisponibles[/i]\n"
		else:
			var dep: Dictionary = baseline.get("deposits", {})
			var dep_parts: Array = []
			var dkeys: Array = dep.keys()
			dkeys.sort()
			for k: String in dkeys:
				if float(dep[k]) > 0.0:
					dep_parts.append("%s %.1f" % [k, float(dep[k])])
			text += "Économie régionale (Phase V) : population %s ; main-d'œuvre %s ; industrie %.3f ; gisements %s.\n" % [
				_format_n(int(baseline.get("population", 0))), _format_n(int(baseline.get("workforce", 0))),
				float(baseline.get("industry_capacity", 0.0)),
				", ".join(dep_parts) if not dep_parts.is_empty() else "—"]
		_rich(box, text)
	var nid := st.controller(rid) if rid != "" else st.player_nation
	var n: Dictionary = st.nations[nid]
	var t := "\n[b]Pays : %s[/b]\nCapitale : %s\nRégions contrôlées : %d ; jouable : %s\n" % [n["name_fr"],
		session.world.cities[n["capital_city_id"]]["name_fr"], st.regions_controlled_by(nid).size(), "oui" if n["playable"] else "non"]
	# Consolidation 02 : les valeurs viennent des systèmes Phase V, pas des champs null du scénario.
	var demo: Dictionary = DemographySystem.summary(st, nid)
	var workforce: Dictionary = demo.get("workforce", {})
	var stocks: Dictionary = ResourceSystem.summary(st, nid)
	var pop := int(demo.get("population", 0))
	var soldiers := 0
	for f: Dictionary in st.formations.values():
		if str(f["nation"]) == nid and f["echelon"] == "unit" and f.get("soldiers") != null:
			soldiers += int(f["soldiers"])
	var stability := 0.0
	if st.politics["states"].has(nid):
		stability = float(st.politics["states"][nid].get("stability", 0.0))
	t += "\n[b]Démographie (Phase V)[/b] : population %s ; main-d'œuvre %s.\n" % [
		_format_n(pop), _format_n(int(_sum_dict(workforce)))]
	t += "Répartition : %s.\n" % _format_sectors(workforce)
	t += "[b]Économie (Phase V)[/b] : capacité industrielle %.2f ; stocks %s.\n" % [
		IndustrySystem.capacity(st, nid), _format_stocks(stocks)]
	t += "[b]Militaire (MIL-01)[/b] : soldats sous les drapeaux %s.\n" % _format_n(soldiers)
	t += "[b]Stabilité intérieure (Phase VII)[/b] : %.0f / 100.\n" % stability
	var relations := ""
	for other: String in st.nation_order:
		if other == nid:
			continue
		relations += "- %s : %s\n" % [_n(other), RelationsSystem.summary(st, nid, other, session.rules["diplomacy"])]
	t += "\n[b]Relations[/b] (confiance / hostilité / tensions) :\n%s" % relations
	var unknown: Array = []
	for key: String in n["stats"]:
		if n["stats"][key]["value"] == null:
			unknown.append(key.replace("_", " "))
	if not unknown.is_empty():
		t += "\n[i]Statistiques abstraction non encore sourcées : %s.[/i]" % ", ".join(unknown)
	_rich(box, t)


func _sum_dict(d: Dictionary) -> float:
	var total := 0.0
	for v: Variant in d.values():
		total += float(v)
	return total


func _format_n(v: int) -> String:
	if v <= 0:
		return "—"
	var s := str(v)
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += " "
		out += s[i]
	return out


func _format_sectors(d: Dictionary) -> String:
	var parts: Array = []
	for k: String in d:
		parts.append("%s %s" % [k, _format_n(int(d[k]))])
	return ", ".join(parts)


func _format_stocks(d: Dictionary) -> String:
	var parts: Array = []
	var keys: Array = d.keys()
	keys.sort()
	for k: String in keys:
		var v := float(d[k])
		if v > 0.0:
			parts.append("%s %.0f" % [k, v])
	return ", ".join(parts) if not parts.is_empty() else "—"


func _page_diplomacy() -> void:
	var box := _clear("Diplomatie")
	var st := session.state
	var me := st.player_nation
	# 1. Négociations en cours : accepter, refuser, contre-proposer, retirer.
	_rich(box, "[b]Négociations en cours[/b]")
	var pending: Array = DiplomacySystem.pending_for(st, me)
	if pending.is_empty():
		_label(box, "Aucune proposition en attente.", 12)
	for p: Dictionary in pending:
		var row := HBoxContainer.new()
		box.add_child(row)
		_label(row, "%s : %s (exp. T%s)" % [_n(str(p["from"])), p["kind"], str(p.get("expires_turn", "?"))], 12)
		_button(row, "Accepter", func() -> void: _queue(Orders.respond(me, str(p["id"]), true)))
		_button(row, "Refuser", func() -> void: _queue(Orders.respond(me, str(p["id"]), false)))
		_button(row, "Contre-proposer", func() -> void: _queue(Orders.respond_agreement(me, str(p["id"]), false,
			{"duration": 18, "reciprocal": true})))
	for p: Dictionary in st.proposals:
		if str(p["from"]) == me and str(p["status"]) == "pending":
			var row2 := HBoxContainer.new()
			box.add_child(row2)
			_label(row2, "Envoyée à %s : %s" % [str(p["to"]), p["kind"]], 12)
			_button(row2, "Retirer", func() -> void: _queue(Orders.withdraw_proposal(me, str(p["id"]))))
	# 2. Relations bilatérales (dimensions réelles, pas une note unique).
	_rich(box, "\n[b]Relations[/b] (confiance / hostilité / coopération / tensions)")
	for nid: String in st.nation_order:
		if nid == me:
			continue
		var tags: Array = []
		if st.at_war(me, nid):
			tags.append("[color=#b03a2e]GUERRE[/color]")
		if st.has_transit(me, nid):
			tags.append("passage")
		var r: Dictionary = RelationsSystem.between(st, me, nid, session.rules)
		if not r.is_empty():
			tags.append("conf %.0f" % float(r.get("trust", 0)))
			tags.append("host %.0f" % float(r.get("hostility", 0)))
			tags.append("tens %.0f" % float(r.get("tensions", 0)))
		_rich(box, "[b]%s[/b] %s" % [_n(nid), " ; ".join(tags)])
		var row := HBoxContainer.new()
		box.add_child(row)
		if st.at_war(me, nid):
			_button(row, "Paix blanche", func() -> void: _queue(Orders.propose_peace(me, [nid], {"white": true})))
			_button(row, "Échanger prisonniers", func() -> void: _queue(Orders.exchange_pow(me, nid)))
		else:
			_button(row, "Guerre", func() -> void: _queue(Orders.declare_war(me, nid)))
			_button(row, "Passage", func() -> void: _queue(Orders.propose_agreement(me, [nid], "transit")))
			_button(row, "Alliance", func() -> void: _queue(Orders.propose_agreement(me, [nid], "alliance")))
			_button(row, "Garantie", func() -> void: _queue(Orders.propose_agreement(me, [nid], "guarantee")))
			_button(row, "Crise", func() -> void: _queue(Orders.start_crisis(me, nid, "incident diplomatique", "frontière")))
	# 3. Alliances et engagements.
	_rich(box, "\n[b]Alliances actives[/b]")
	for a: Dictionary in st.diplomacy.get("alliances", []):
		if str(a.get("status", "")) != "active" or not (a["members"] as Array).has(me):
			continue
		var com: Dictionary = a.get("commitments", {})
		_rich(box, "%s — %s | défensive:%s offensive:%s passage:%s" % [a["id"], str(a["members"]),
			str(com.get("defensive", false)), str(com.get("offensive", false)), str(com.get("transit", false))])
		var row3 := HBoxContainer.new()
		box.add_child(row3)
		_button(row3, "Quitter", func() -> void: _queue(Orders.leave_alliance(me, str(a["id"]))))
		_button(row3, "Dissoudre", func() -> void: _queue(Orders.dissolve_alliance(me, str(a["id"]))))
	# 4. Crises et médiation.
	_rich(box, "\n[b]Crises[/b]")
	for cr: Dictionary in st.diplomacy.get("crises", []):
		if str(cr.get("status", "")) != "active" or not (cr["parties"] as Array).has(me):
			continue
		_rich(box, "%s — %s (tension %.0f, enjeu %s)" % [cr["id"], cr["motive"], float(cr["tension"]), cr["stake"]])
		var row4 := HBoxContainer.new()
		box.add_child(row4)
		for action: String in ["protest", "negotiate", "concede", "guarantee", "sanction", "mobilize"]:
			_button(row4, action, func() -> void: _queue(Orders.crisis_response(me, str(cr["id"]), action)))
	for cr: Dictionary in st.diplomacy.get("crises", []):
		if str(cr.get("status", "")) == "active" and not (cr["parties"] as Array).has(me) \
			and not (cr["mediators"] as Array).has(me):
			var row5 := HBoxContainer.new()
			box.add_child(row5)
			_button(row5, "Médier %s" % cr["id"], func() -> void: _queue(Orders.offer_mediation(me, str(cr["id"]))))
	# 4c. Traité de Paix et d'Unité Internationale (victoire diplomatique).
	_rich(box, "\n[b]Traîté de Paix et d'Unité Internationale[/b] — victoire diplomatique.")
	var prog := PeaceSystem.universal_progress(st)
	var cond: Dictionary = session.rules["diplomacy"]["peace"]
	_rich(box, "Conditions : %s ; seuil de contrôle souverain %.0f %% ; %d États participants requis." % [
		"accord de tous les États" if bool(session.rules["phase7"]["victory"]["diplomatic"]["requires_all_participants"]) else "accord simple",
		100.0 * float(cond["universal_peace_requires_regions"]),
		st.nation_order.size() - 1])
	_rich(box, "État : %s | signés %d | refus %d | en attente %d" % [str(prog["status"]),
		(prog["accepted"] as Array).size(), (prog["refused"] as Array).size(),
		(prog["pending"] as Array).size()])
	for nid: String in (prog["refused"] as Array):
		_rich(box, "[color=#b03a2e]%s refuse : %s[/color]" % [_n(nid), str(prog["reasons"][nid])])
	for nid: String in (prog["pending"] as Array):
		_rich(box, "%s : pas encore de réponse" % _n(nid))
	var rowu := HBoxContainer.new()
	box.add_child(rowu)
	if str(prog["status"]) == "none" or str(prog["status"]) == "withdrawn" or str(prog["status"]) == "rejected":
		_button(rowu, "Proposer à tous les États", func() -> void: _queue(Orders.propose_universal(me)))
	if str(prog["status"]) == "negotiating" and (prog["pending"] as Array).has(me):
		_button(rowu, "Accepter", func() -> void: _queue(Orders.respond_universal(me, true)))
		_button(rowu, "Refuser", func() -> void: _queue(Orders.respond_universal(me, false)))
	if str(prog["status"]) == "negotiating" and str(prog["proposer"]) == me:
		_button(rowu, "Retirer", func() -> void: _queue(Orders.withdraw_universal(me)))
	# 4b. Conférences internationales (sujets multiples, accords réels).
	_rich(box, "\n[b]Conférences[/b]")
	var others: Array = []
	for nid: String in st.nation_order:
		if nid != me:
			others.append(nid)
	if others.size() >= 2:
		_button(box, "Proposer une conférence (crise + alliance)", func() -> void:
			_queue(Orders.propose_agreement(me, others, "conference", {"topics": ["crisis", "alliance"]})))
	for c: Dictionary in st.diplomacy.get("conferences", []):
		if str(c.get("status", "")) != "active" or not (c["participants"] as Array).has(me):
			continue
		_rich(box, "%s — %s" % [c["id"], str(c["topics"])])
		var rowc := HBoxContainer.new()
		box.add_child(rowc)
		for topic: String in c["topics"]:
			_button(rowc, "Conclure %s" % topic, func() -> void:
				_queue(Orders.conclude_conference(me, str(c["id"]), topic)))
	# 5. Traités de paix et prisonniers.
	_rich(box, "\n[b]Traités de paix[/b]")
	for t: Dictionary in st.diplomacy.get("peace_treaties", []):
		_rich(box, "%s — %s (%s)" % [t["id"], str(t.get("parties", [])), str(t.get("terms", {}))])
	_rich(box, "\n[b]Prisonniers[/b] — %s" % PowSystem.summary(st, me))
	_rich(box, "\n[b]Traités historiques / messages[/b] (public, privé, groupe)")
	for t: Dictionary in st.treaties:
		if t["status"] == "active" and (t["members"] as Array).has(me):
			var row6 := HBoxContainer.new()
			box.add_child(row6)
			_label(row6, "%s : %s" % [t["type"], ", ".join((t["members"] as Array).map(func(x: String) -> String: return _n(x)))], 12)
			_button(row6, "Rompre", func() -> void: _queue(Orders.break_treaty(me, str(t["id"]))))
	for m: Dictionary in DiplomacySystem.visible_messages(st, me).slice(-10):
		_rich(box, "[%s] %s : %s" % [m["channel"], _n(str(m["from"])), m["text"]])
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
	var me := session.state.player_nation
	var sum := EconomySystem.summary(session.state, me)
	var demo: Dictionary = sum["demography"]
	var stocks: Dictionary = sum["stocks"]
	t += "\n[b]Phase V — démographie[/b] : population %s ; main-d'œuvre %s.\n" % [
		str(demo.get("population", 0)), str(demo.get("workforce", {}))]
	t += "[b]Capacité industrielle[/b] : %.2f ; [b]stocks[/b] : %s.\n" % [
		float(sum["industry_capacity"]), str(stocks)]
	t += "[b]Dépendances commerciales[/b] : %s ; [b]remplacement[/b] : %s.\n" % [
		str(sum["dependencies"]), str(sum["replacement"])]
	var dep: Dictionary = sum["dependencies"]
	if not dep.is_empty():
		t += "[color=#b03a2e]Ressources dépendantes d'importations : %s[/color]\n" % str(dep.keys())
	_rich(box, t)
	_rich(box, "\n[b]Priorités industrielles[/b] (catégories validées)")
	var current: Dictionary = session.state.nations[me].get("industry_allocation", {})
	for cat: String in session.rules["economy"]["industry_categories"]:
		var row := HBoxContainer.new()
		box.add_child(row)
		_label(row, "%s : %s" % [cat, _num(current.get(cat, 0))], 12)
		var minus := _button(row, "−10", func() -> void:
			var a := current.duplicate(); a[cat] = maxf(0.0, float(a.get(cat, 0)) - 10.0)
			_queue(Orders.industry_allocation(me, a)))
		var plus := _button(row, "+10", func() -> void:
			var a := current.duplicate(); a[cat] = float(a.get(cat, 0)) + 10.0
			_queue(Orders.industry_allocation(me, a)))


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


## Effectifs du pays (MIL-01, phase 2) : catégories distinctes, échelons, posture, allocation,
## pertes et prisonniers ; informations publiques des autres puissances (T-056).
func _forces_panel(box: VBoxContainer) -> void:
	var st := session.state
	var src: Dictionary = session.scenario.get("forces_source", {})
	var sum := session.forces_summary(st.player_nation)
	var kind: String = sum["source_type"]
	var mr: Dictionary = session.rules["forces"]["mobilization"]
	var t := "[b]Source des effectifs[/b] : %s\n" % {"historical": "historique (base MIL-01)",
		"fictitious": "[color=#b03a2e]FICTIVE (bac à sable, valeurs de test)[/color]"}.get(str(src.get("type", "")), "inconnue")
	if kind == "historical":
		t += "Données : %s\n\n" % sum["data_status"]
		t += "1. Actifs au démarrage : %s (dont %s hors carte)\n" % [_num(sum["active_start"]), _num(sum["active_off_map"])]
		t += "2. Réservistes non appelés : %s sur %s (hors carte : %s)\n" % [_num(sum["reserve_pool"]), _num(sum["reserve_pool_initial"]), _num(sum["reserves_off_map"])]
		for e: Dictionary in sum["echelons"]:
			t += "      • %s : %s / %s — %s\n" % [e["label_fr"], _num(e["pool"]), _num(e["pool_initial"]), "ouvert" if e["opened"] else "fermé"]
		if sum["echelon_mode"] == "bloc_unique":
			t += "      [color=#e06c5c]Approximation non documentée historiquement (décision MIL01-P1-D1)[/color]\n"
		t += "3. En cours de mobilisation : %s" % _num(int(sum["mobilizing"]) + int(sum["blocked"]))
		t += (" (dont bloqués : %s)\n" % _num(sum["blocked"])) if int(sum["blocked"]) > 0 else "\n"
		t += "4. Incorporés : %s\n" % _num(sum["incorporated"])
		t += "5. Présents dans les unités : %s\n      + services non combattants : %s\n" % [_num(sum["present_in_units"]), _num(sum["present_services"])]
		var tfp: Dictionary = sum.get("territorial_force", {})
		if not tfp.is_empty() and int(tfp["incorporated"]) > 0:
			t += "      [i]dont Territorial Force : %s en unités, %s en services[/i]\n" % [_num(int(tfp["present_home"]) + int(tfp["present_overseas"])), _num(tfp["services"])]
		var w: Dictionary = sum["wounded"]
		t += "6. Hors des rangs : %s\n" % _num(sum["losses_total"])
		t += "      Tués : %s\n" % _num(sum["killed"])
		t += "      Blessés en convalescence : %s (dont longue durée : %s)\n" % [_num(int(w["convalescing"]) + int(w["long_term"])), _num(w["long_term"])]
		t += "      Blessés définitivement inaptes : %s\n" % _num(w["unfit"])
		t += "      Disparus (sort inconnu) : %s\n" % _num(sum["missing"])
		t += "      [i]Blessés rendus au service : %s ; blessés légers restés dans leur unité : %s (comptés parmi les présents)[/i]\n" % [_num(w["returned"]), _num(w["remained_in_unit"])]
		if int(sum["legacy_unventilated"]) > 0:
			t += "      Pertes non ventilées (ancienne sauvegarde) : %s\n" % _num(sum["legacy_unventilated"])
		t += "7. Prisonniers perdus : %s ; détenus : %s\n      [i]libération et rapatriement : aucun mécanisme[/i]\n" % [_num(sum["prisoners_lost"]), _num(sum["prisoners_held"])]
		t += "      [i]Ventilation provisoire (phase 6, étape 1) : taux de retour britannique appliqué aux autres pays par approximation.[/i]\n"
		if int(sum["rejoined"]) > 0:
			t += "      Survivants ayant rejoint le territoire : %s (comptés parmi les présents)\n" % _num(sum["rejoined"])
		var tfs: Dictionary = sum.get("territorial_force", {})
		if not tfs.is_empty():
			t += "\n[b]Territorial Force[/b] [i](catégorie distincte de l'armée régulière et des réserves, T-050)[/i]\n"
			t += "      Non incorporés : %s sur %s ; en cours : %s ; incorporés : %s\n" % [_num(tfs["pool"]), _num(tfs["pool_initial"]),
				_num(int(tfs["mobilizing"]) + int(tfs["blocked"])), _num(tfs["incorporated"])]
			t += "      Présents : %s en service intérieur ; %s volontaires outre-mer (+ services : %s)\n" % [
				_num(tfs["present_home"]), _num(tfs["present_overseas"]), _num(tfs["services"])]
			t += "      [i]Incorporée avec la posture générale ; service outre-mer par volontariat (T-054) ; délais PROVISOIRES.[/i]\n"
		var al: Dictionary = sum["allocation"]
		t += "\n[b]Posture de mobilisation[/b] : %s [i](publique)[/i]\n" % mr["postures"][sum["posture"]]["label_fr"]
		t += "Moyens : administration %d %%, chemins de fer %d %%, logistique %d %%\n[i]Sans coût économique (économie non définie). Paramètres nationaux dérivés ou PROVISOIRES.[/i]" % [
			int(al["administration"]), int(al["rail"]), int(al["logistics"])]
	elif kind == "fictitious":
		t += "Aucune réserve ni mobilisation (bac à sable)."
	else:
		t += "[color=#b03a2e]Effectifs inconnus pour ce pays (hors MIL-01) : aucune valeur n'est fabriquée.[/color]"
	_rich(box, t)
	if kind != "historical":
		return
	var row := HBoxContainer.new()
	box.add_child(row)
	for p: String in MobilizationSystem.POSTURES:
		if p != sum["posture"]:
			_button(row, "Posture : %s" % mr["postures"][p]["label_fr"], func() -> void: _queue(Orders.mobilization_posture(st.player_nation, p)))
	if sum["echelon_mode"] != "bloc_unique":
		_button(box, "Appeler l'échelon suivant", func() -> void: _queue(Orders.call_next_echelon(st.player_nation)))
	_rich(box, "[b]Répartition des moyens[/b] [i](total : 100 %)[/i]")
	var spins: Dictionary = {}
	for k: String in MobilizationSystem.MEANS:
		var arow := HBoxContainer.new()
		box.add_child(arow)
		var l := _label(arow, {"administration": "Administration", "rail": "Chemins de fer", "logistics": "Logistique"}[k], 13)
		l.custom_minimum_size.x = 140
		var sp := SpinBox.new()
		sp.max_value = 100
		sp.suffix = "%"
		sp.value = float(sum["allocation"][k])
		arow.add_child(sp)
		spins[k] = sp
	_button(box, "Répartir les moyens", func() -> void:
		_queue(Orders.mobilization_allocation(st.player_nation, int(spins["administration"].value), int(spins["rail"].value), int(spins["logistics"].value))))
	var pub := session.public_mobilization()
	var pt := "\n[b]Mobilisations publiques[/b] [i](postures et échelons ; volumes confidentiels)[/i]\n"
	for nid: String in pub:
		if nid == st.player_nation:
			continue
		var opened: Array = (pub[nid]["opened_echelons"] as Array).map(func(e: Dictionary) -> String: return e["label_fr"])
		pt += "• %s : %s%s\n" % [st.nations[nid]["name_fr"], pub[nid]["posture_fr"], (" — " + ", ".join(opened)) if not opened.is_empty() else ""]
	_rich(box, pt)


## Libellé qui se replie dans la largeur du panneau (sinon sa largeur minimale élargit tout l'onglet).
func _wrap(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 120
	return l


## Nombre lisible : séparateur de milliers (espace insécable fine).
func _num(v: Variant) -> String:
	if v == null:
		return "inconnu"
	var s := str(absi(int(v)))
	var out := ""
	while s.length() > 3:
		out = "\u202f" + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if int(v) < 0 else "") + s + out


func _page_army() -> void:
	var box := _clear("Armée")
	var st := session.state
	_forces_panel(box)
	_rich(box, "\nHiérarchie VALIDÉE : soldats et équipements → unités → régiments → divisions → armées.\nSélectionnez une formation (ses unités s'affichent), puis cliquez une région voisine sur la carte pour ordonner un déplacement (portée provisoire : 1 région par mois).")
	_engagement_controls(box)
	for f: Dictionary in st.formations_of(st.player_nation):
		if not st.is_top_level(f):
			continue
		var row := HBoxContainer.new()
		box.add_child(row)
		var txt := "%s — %s%s%s" % [f["name_fr"], session.world.regions[f["region"]]["name_fr"],
			"" if f["supplied"] else " (coupée)", (" → " + session.world.regions[f["planned_target"]]["name_fr"]) if f["planned_target"] != "" else ""]
		_wrap(_label(row, txt, 13))
		var b := _button(row, "Sélectionnée" if map_view.selected_formation == f["id"] else "Sélectionner", func() -> void:
			map_view.selected_formation = "" if map_view.selected_formation == f["id"] else f["id"]
			map_view.center_on(f["region"])
			refresh())
		b.toggle_mode = true
		b.button_pressed = map_view.selected_formation == f["id"]
		_posture_row(box, f)
		var soldiers: Variant = st.soldiers_of(f["id"])
		var extra := "Effectif : %s ; moral d'armée : %s%s%s" % ["[i]inconnu (MIL-01)[/i]" if soldiers == null else _num(soldiers),
			"—" if f.get("morale") == null else "%.0f" % float(f["morale"]), " ; [color=#b03a2e]ENCERCLÉE[/color]" if f.get("encircled", false) else "",
			" ; [color=#b03a2e]ENGAGÉE[/color]" if st.is_engaged(f["id"]) else ""]
		_rich(box, extra)
		for uid: String in (st.units_of(f["id"]) if map_view.selected_formation == f["id"] else []):
			var su: Dictionary = st.formations[uid]
			var urow := HBoxContainer.new()
			box.add_child(urow)
			var lw := int(su.get("lightly_wounded", 0))
			var lw_txt := ""
			if lw > 0 and su.get("soldiers") != null:
				lw_txt = " ; dont %s blessés légers (capacité %s)" % [_num(lw), _num(int(round(Engagement.operational(session.rules["combat"], su))))]
			_wrap(_label(urow, "   %s : %s soldats%s, moral %s" % [su["name_fr"], _num(su.get("soldiers")), lw_txt, "—" if su.get("morale") == null else "%.0f" % float(su["morale"])], 11))
			var rb := CheckBox.new()
			rb.text = "réserve"
			rb.button_pressed = bool(su.get("reserve", false))
			rb.toggled.connect(func(on: bool) -> void:
				var err := session.set_reserve(uid, on)
				say(("Réserve : " + ("oui" if on else "non")) if err == "" else ("Refusé : " + err)))
			urow.add_child(rb)
		var full := "Préparer les défenses de %s" % session.world.regions[f["region"]]["name_fr"]
		var db := _button(box, full, func() -> void: request_planning.emit(f["region"]))
		db.clip_text = true  # noms de régions longs : le libellé ne doit pas élargir le panneau
		db.tooltip_text = full
		if TerritorialForce.is_territorial(f) and f.get("service", "home") == "home":
			var ob := _button(box, "Volontaires pour le service outre-mer", func() -> void: _queue(Orders.territorial_overseas(st.player_nation, f["id"])))
			ob.tooltip_text = "Territorial Force (T-054) : les volontaires de cette armée forment une armée de service outre-mer."
	_rich(box, "\nCréation libre de formations, entraînement, équipement et démobilisation : %s (MIL-02 ouvert).\nBatailles tactiques : opérationnelles pour les 22 États (forces historiques Phase II). Le repli neutre n'est plus utilisé en campagne historique." % NOT_FUNCTIONAL)
	if not st.battles.is_empty():
		_rich(box, "\n[b]Dernières batailles[/b]")
		for b: Dictionary in st.battles.slice(-5):
			var outcome: String
			if b.has("result"):
				var w: String = b["result"]["winner"]
				outcome = "victoire des attaquants" if w == "attackers" else ("victoire des défenseurs" if w == "defenders" else "indécise")
			else:
				outcome = b["resolution"]["status"]
			_rich(box, "%s, %s : %s" % [b["date"], session.world.regions[b["region"]]["name_fr"], outcome])


## Types d'engagement (T-055, phase 6 étape 2) : approche offensive des prochains déplacements et
## explication du système (largeur du front, blessés légers).
func _engagement_controls(box: VBoxContainer) -> void:
	var ec: Dictionary = session.rules["combat"].get("engagement", {})
	if ec.is_empty():
		return
	var row := HBoxContainer.new()
	box.add_child(row)
	_label(row, "Approche offensive :", 13)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.clip_text = true
	for ap: String in Engagement.APPROACHES:
		opt.add_item(ec["approaches"][ap]["label_fr"])
		opt.set_item_tooltip(opt.item_count - 1, ec["approaches"][ap]["description"])
		if ap == approach:
			opt.select(opt.item_count - 1)
	opt.item_selected.connect(func(i: int) -> void:
		approach = Engagement.APPROACHES[i]
		say("Approche des prochains déplacements : " + ec["approaches"][approach]["label_fr"]))
	row.add_child(opt)
	_rich(box, "[i]%s[/i]\n[b]Types d'engagement[/b] : votre approche et la posture du défenseur (escarmouche, engagement limité, assaut frontal, grande bataille au-delà de %s hommes). [b]Largeur du front[/b] : seuls les soldats qui trouvent place sur le secteur combattent ; les autres attendent et relèvent les unités épuisées. [b]Blessés légers[/b] restés dans une unité : comptés dans l'effectif, mais à %d %% de leur capacité jusqu'à leur guérison. [i]Paramètres provisoires.[/i]" % [
		ec["approaches"][approach]["description"], _num(int(ec["major_battle_soldiers"])), int(round(100.0 * float(ec["lightly_wounded_efficiency"])))])


## Posture défensive permanente d'une armée (ordre du mois).
func _posture_row(box: VBoxContainer, f: Dictionary) -> void:
	var ec: Dictionary = session.rules["combat"].get("engagement", {})
	if ec.is_empty():
		return
	var current: String = f.get("defensive_posture", "")
	var pending := ""
	for o: Dictionary in session.player_orders():
		if o["type"] == Orders.SET_DEFENSIVE_POSTURE and o["army"] == f["id"]:
			pending = o["posture"]
	var shown := pending if pending != "" else (current if current != "" else Engagement.DEFAULT_POSTURE)
	var row := HBoxContainer.new()
	box.add_child(row)
	_label(row, "   Posture défensive :", 12)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.clip_text = true
	for po: String in Engagement.POSTURES:
		opt.add_item(ec["postures"][po]["label_fr"] + (" (ordre en attente)" if po == pending and pending != current else ""))
		opt.set_item_tooltip(opt.item_count - 1, ec["postures"][po]["description"])
		if po == shown:
			opt.select(opt.item_count - 1)
	opt.item_selected.connect(func(i: int) -> void: _queue(Orders.defensive_posture(session.state.player_nation, f["id"], Engagement.POSTURES[i])))
	row.add_child(opt)


func _page_logistics() -> void:
	var box := _clear("Logistique")
	var s := LogisticsSystem.summary(session.state, session.world, session.state.player_nation)
	var t := "Continuité territoriale (implémentée) : régions contrôlées %d ; accessibles depuis la capitale %d.\n" % [s["controlled"], s["accessible"]]
	if not (s["cut_off"] as Array).is_empty():
		t += "[color=#b03a2e]Régions coupées :[/color] %s\n" % ", ".join((s["cut_off"] as Array).map(func(r: String) -> String: return session.world.regions[r]["name_fr"]))
	t += "\n[b]Phase IV[/b] : %s — %d régions atteignables par un itinéraire multimodal depuis la capitale (capacités et contrôle pris en compte)." % [
		s["delivered_status"], int(s["delivered"])]
	_rich(box, t)
	var net: TransportNetwork = session.rules.get("transport_network") as TransportNetwork
	if net != null:
		var me := session.state.player_nation
		var cap := str(session.state.nations[me]["capital_region_id"])
		_rich(box, "\n[b]Infrastructures contrôlées[/b]")
		var shown := 0
		for lid: String in net.links:
			var l: Dictionary = net.links[lid]
			if shown >= 12:
				break
			if not TransportSystem.controls(session.state, me, str(l["a"]), str(l["b"])):
				continue
			shown += 1
			var row := HBoxContainer.new()
			box.add_child(row)
			_label(row, "%s (%s, cap %d, %s)" % [lid, l["mode"],
				TransportNetwork.available(session.state, net, lid), TransportNetwork.condition(session.state, lid)], 11)
			_button(row, "Interrompre", func() -> void: _queue(Orders.disrupt_link(me, lid)))
			_button(row, "Réparer", func() -> void: _queue(Orders.repair_link(me, lid, 2)))
		if shown == 0:
			_label(box, "Aucune liaison sous contrôle direct.", 12)
		var ports_row := HBoxContainer.new()
		box.add_child(ports_row)
		_label(ports_row, "Ports contrôlés : %d" % (session.state.regions_controlled_by(me).size()), 12)


func _page_research() -> void:
	var box := _clear("Recherche")
	var me := session.state.player_nation
	TechSystem.ensure(session.state, me)
	var known: Array = session.state.tech["known"][me]
	var projects: Array = session.state.tech["projects"][me]
	_rich(box, "[b]Recherche 1914–1945[/b] — %d technologies connues, %d projet(s) actif(s)." % [known.size(), projects.size()])
	for p: Dictionary in projects:
		var tech: Dictionary = session.tech_tree.by_id.get(str(p["tech"]), {})
		_rich(box, "%s : %.0f / %.0f pts (%s)" % [p["tech"], float(p["progress"]),
			float(tech.get("cost", 100)), str(p["status"])])
	_rich(box, "\n[b]Technologies disponibles[/b] (prérequis remplis)")
	var count := 0
	var candidates: Array = session.tech_tree.tree.get("technologies", [])
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["year"]) < int(b["year"]))
	for tech: Dictionary in candidates:
		if count >= 10:
			break
		if TechSystem.can_research(session.state, session.tech_tree, me, str(tech["id"])) != "":
			continue
		count += 1
		var row := HBoxContainer.new()
		box.add_child(row)
		_label(row, "%s (%s, %d pt, %d mois)" % [tech["id"], tech["domain"], int(tech["cost"]), int(tech["duration"])], 11)
		_button(row, "Lancer", func() -> void: _queue(Orders.set_research(me, str(tech["id"]))))
	if count == 0:
		_label(box, "Aucune technologie accessible pour le moment.", 12)
	# Communications et renseignement technique.
	CommunicationsSystem.ensure(session.state, me)
	var comms: Dictionary = session.state.tech["comms"][me]
	_rich(box, "\n[b]Communications[/b] — protection %d ; interceptions %d." % [
		int(comms["protection"]), (comms["intercepts"] as Array).size()])
	for nid: String in session.state.nation_order:
		if nid == me:
			continue
		var row2 := HBoxContainer.new()
		box.add_child(row2)
		_label(row2, "Intercepter %s" % _n(nid), 11)
		_button(row2, "Écouter", func() -> void: _queue(Orders.intercept(me, nid)))
	# Aviation et marine (résumé).
	AirSystem.ensure(session.state, me)
	NavalSystem.ensure(session.state, me)
	var ac: Dictionary = session.state.tech["air"]["aircraft"][me]
	_rich(box, "\n[b]Aviation[/b] — appareils : %s ; bases : %d." % [
		str(ac), (session.state.tech["air"]["bases"][me] as Array).size()])
	var fleets: Array = session.state.tech["naval"]["fleets"][me]
	_rich(box, "[b]Marine[/b] — flottes : %d." % fleets.size())


func _page_politics() -> void:
	var box := _clear("Politique")
	var me := session.state.player_nation
	var pol := PoliticalSystem.summary(session.state, me)
	_rich(box, "[b]Stabilité intérieure[/b] — stabilité %.0f | cohésion %.0f | popularité %.0f | tensions sociales %.0f | soutien guerre %.0f | confiance %.0f." % [
		float(pol["stability"]), float(pol["cohesion"]), float(pol["popularity"]), float(pol["social_tension"]),
		float(pol["war_support"]), float(pol["trust"])])
	if str(pol["crisis"]) != "":
		_rich(box, "[color=#b03a2e]Crise intérieure active : %s[/color]" % str(pol["crisis"]))
	var groups: Dictionary = session.state.politics["states"][me]["groups"]
	_rich(box, "\n[b]Groupes d'influence[/b]")
	for gid: String in groups:
		var g: Dictionary = groups[gid]
		_rich(box, "%s : influence %.0f, satisfaction %.0f (%s)" % [gid, float(g["influence"]),
			float(g["satisfaction"]), str(g["interests"])])
	_rich(box, "\n[b]Décisions gouvernementales[/b]")
	for kind: String in session.rules["phase7"]["politics"]["decisions"]["costs"]:
		_button(box, kind, func() -> void: _queue(Orders.political_decision(me, kind)))
	_button(box, "Changement de gouvernement (négocié)", func() -> void:
		_queue(Orders.change_government(me, "negotiated")))
	_rich(box, "\n[b]Historique politique[/b]")
	for h: Dictionary in (session.state.politics["states"][me]["history"] as Array).slice(-8):
		_rich(box, "T%s : %s" % [str(h["turn"]), str(h["event"])])


func _page_victory() -> void:
	var box := _clear("Victoire")
	var me := session.state.player_nation
	var v: Dictionary = session.state.victory
	var rules_v: Dictionary = session.rules["phase7"]["victory"]
	_rich(box, "[b]État[/b] : %s — %s (tour %s)" % [str(v.get("status", "ongoing")),
		str(v.get("condition", "")), str(v.get("turn", "-"))])
	var share := VictorySystem.military_share(session.state, me, session.rules["phase7"])
	_rich(box, "\n[b]1. Victoire militaire[/b] — contrôle %.1f %% (seuil %.0f %%)." % [
		100.0 * share, 100.0 * float(rules_v["military"]["threshold"])])
	var hdi := VictorySystem.hdi(session.state, me, session.rules["phase7"])
	_rich(box, "[b]2. Développement humain[/b] — score %.3f, population %d, industrie %.2f (seuil relatif %.2f sur %d mois)." % [
		float(hdi["score"]), int(hdi["population"]), float(hdi["industry"]),
		float(rules_v["hdi"]["relative_threshold"]), int(rules_v["hdi"]["duration_months"])])
	var universal := false
	for t: Dictionary in session.state.diplomacy["peace_treaties"]:
		if str(t.get("type", "")) == "universal" and str(t.get("status", "")) == "active":
			universal = true
	_rich(box, "[b]3. Traité de Paix et d'Unité Internationale[/b] — %s." % ("signé" if universal else "non signé"))
	if str(v.get("status", "ongoing")) == "finished":
		_rich(box, "\n[b]Bilan de fin de partie[/b]")
		var summary := VictorySystem.final_summary(session.state, session.rules["phase7"])
		for s: Dictionary in summary["standings"]:
			_rich(box, "%s : contrôle %.1f %%, IDH %.3f" % [str(s["nation"]),
				100.0 * float(s["military"]), float(s["hdi"])])
	# RESTORATION 02 — classement dynamique, distinct des conditions de victoire.
	_rich(box, "\n[b]Puissance des États[/b] — indicateur composite, sans lien avec la victoire.")
	var standings: Array = PowerRankSystem.standings(session.state, session.rules)
	for i in mini(10, standings.size()):
		var st: Dictionary = standings[i]
		var nid := str(st["nation"])
		var name_fr := str(session.state.nations[nid].get("name_fr", nid))
		var delta := PowerRankSystem.rank_delta(session.state, nid)
		var parts: Dictionary = st["parts"]
		_rich(box, "%d. %s — %.1f (%+d) · industrie %.0f · armée %.0f · tech %.0f" % [
			int(st["rank"]), name_fr, float(st["score"]), delta,
			float(parts.get("industry", 0.0)), float(parts.get("military", 0.0)),
			float(parts.get("technology", 0.0))])
	_rich(box, "Variation depuis le début de campagne entre parenthèses.")


func _page_multiplayer() -> void:
	var box := _clear("Multijoueur")
	var mp: Dictionary = session.state.multiplayer
	_rich(box, "[b]État[/b] : %s — hôte %s." % [str(mp.get("state", "solo")), str(mp.get("host", ""))])
	var players: Dictionary = mp.get("players", {})
	_rich(box, "[b]Joueurs[/b] : %d" % players.size())
	for p: String in players:
		var info: Dictionary = players[p]
		_rich(box, "%s : connecté=%s" % [p, str(info.get("connected", true))])
	_rich(box, "\n[b]Synchronisation[/b] — %d hachages enregistrés." % (mp.get("state_hashes", []) as Array).size())
	for e: Dictionary in (mp.get("events", []) as Array).slice(-8):
		_rich(box, "T%s : %s (%s)" % [str(e["turn"]), str(e["player"]), str(e["event"])])
	_rich(box, "\n[i]Socle local déterministe : aucune connexion réelle n'est implémentée.[/i]")


func _page_intel() -> void:
	var box := _clear("Renseignement")
	var view := IntelSystem.view_for(session.state, session.world, session.state.player_nation, session.rules)
	var foreign := (view["formations"] as Array).filter(func(f: Dictionary) -> bool: return f["nation"] != session.state.player_nation)
	var t := "[b]Vue nationale[/b] (brouillard de guerre strict) : %d régions observées ; %d armée(s) étrangère(s) repérée(s) aux frontières.\n" % [(view["visible_regions"] as Dictionary).size(), foreign.size()]
	for f: Dictionary in foreign:
		var ri: Dictionary = view["region_intel"].get(f["region"], {})
		t += "  • %s en %s — %s\n" % [_n(f["nation"]), session.world.regions[f["region"]]["name_fr"], _format_region_intel(ri)]
	t += "\n[b]Rapports de reconnaissance et de combat[/b]\n"
	var reports := 0
	for rid: String in view["region_intel"]:
		var ri: Dictionary = view["region_intel"][rid]
		if ri["status"] in ["estimated", "stale"]:
			reports += 1
			t += "  • [b]%s[/b] : %s\n" % [session.world.regions[rid]["name_fr"], _format_region_intel(ri)]
	if reports == 0:
		t += "  [i]Aucun rapport de reconnaissance actif (ordonnez une approche « Reconnaissance en force » pour évaluer une position défendue).[/i]\n"
	t += "\n[b]Interception et décryptage[/b] (Phase VI) : opérationnels — détection, interception, compréhension partielle puis décryptage abstrait, avec fiabilité décroissante selon l'ancienneté. L'espionnage industriel distinct n'est pas implémenté (INT-02 ouvert)."
	_rich(box, t)


func _format_region_intel(ri: Dictionary) -> String:
	var st_code: String = ri.get("status", "unknown")
	match st_code:
		"confirmed_clear":
			return "observée directement — aucune force étrangère (confirmé)"
		"estimated", "stale":
			var label := "estimé" if st_code == "estimated" else "[color=#d4882a]ancien[/color]"
			var age := int(ri.get("age_turns", 0))
			var age_txt := "ce mois-ci" if age == 0 else "il y a %d mois (%s)" % [age, str(ri.get("report_date", ""))]
			return "%s : ~%s h (%s–%s), %d unité(s), tranchées niv. %d, fiabilité %d %%, %s" % [
				label, _num(ri["estimated_soldiers"]), _num(ri["estimate_min"]), _num(ri["estimate_max"]),
				int(ri.get("units_seen", 0)), int(ri.get("fortification_level", 0)),
				int(round(100.0 * float(ri.get("reliability", 0.0)))), age_txt]
		_:
			if bool(ri.get("confirmed_presence", false)):
				return "%d armée(s) présente(s) (confirmé), effectifs inconnus" % int(ri.get("armies_seen", 1))
			return "inconnu (hors de vue)"


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
			var ap: String = o.get("approach", Engagement.DEFAULT_APPROACH)
			return "Déplacer %s vers %s (approche : %s)" % [session.state.formations[o["formation"]]["name_fr"], session.world.regions[o["target"]]["name_fr"],
				session.rules["combat"]["engagement"]["approaches"][ap]["label_fr"]]
		Orders.SET_DEFENSIVE_POSTURE:
			return "Posture défensive de %s : %s" % [session.state.formations[o["army"]]["name_fr"], session.rules["combat"]["engagement"]["postures"][o["posture"]]["label_fr"]]
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
		Orders.MOBILIZE:
			return "Décréter la mobilisation générale (posture générale)"
		Orders.SET_MOBILIZATION_POSTURE:
			return "Posture de mobilisation : %s" % session.rules["forces"]["mobilization"]["postures"][o["posture"]]["label_fr"]
		Orders.SET_MOBILIZATION_ALLOCATION:
			return "Moyens de mobilisation : administration %d %%, chemins de fer %d %%, logistique %d %%" % [
				int(o["allocation"]["administration"]), int(o["allocation"]["rail"]), int(o["allocation"]["logistics"])]
		Orders.CALL_NEXT_ECHELON:
			return "Appeler l'échelon de mobilisation suivant"
		Orders.TERRITORIAL_OVERSEAS:
			return "Territorial Force : volontaires outre-mer (%s)" % session.state.formations.get(o["army"], {}).get("name_fr", o["army"])
		Orders.BUILD_DEFENSE:
			return "Ouvrage défensif (%s) en %s" % [o["kind"], session.world.regions[o["region"]]["name_fr"]]
	return o["type"]


# ------------------------------------------------------------------ actions
func _queue(order: Dictionary) -> void:
	var err := session.queue_order(order)
	say(("Ordre préparé : " + _describe(order)) if err == "" else ("Ordre refusé : " + err))
	refresh()


func _on_region_clicked(rid: String) -> void:
	if map_view.selected_formation != "":
		_queue(Orders.move(session.state.player_nation, map_view.selected_formation, rid, approach))
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
