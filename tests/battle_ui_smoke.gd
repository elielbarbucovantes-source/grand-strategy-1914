extends SceneTree
## Test de l'interface tactique sur la vraie scène (sans rendu) : les boutons et commandes ont
## un effet réel dans la simulation.
##   godot --headless --path . --script tests/battle_ui_smoke.gd

var failures := 0


func check(ok: bool, msg: String) -> void:
	if ok:
		print("  ✓ " + msg)
	else:
		failures += 1
		printerr("  ✗ " + msg)


func press(root_node: Node, text: String) -> bool:
	for n in root_node.find_children("*", "Button", true, false):
		if (n as Button).text == text:
			(n as Button).pressed.emit()
			return true
	return false


func _initialize() -> void:
	var main: Node = load("res://src/ui/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var s: GameSession = main.session
	check(s.new_game("france", 1, 1914, "sandbox_fictif") == "", "bac à sable FICTIF")
	main._start_game()
	s.queue_order(Orders.declare_war("france", "german_empire"))
	s.end_turn()
	s.state.move_army("army_german_empire_1", "region_035")
	s.state.move_army("army_france_1", "region_011")
	s.queue_order(Orders.move("france", "army_france_1", "region_035"))
	main.game_ui._on_end_turn()
	await process_frame
	check(not s.current_battle().is_empty(), "bataille du joueur créée")
	check(main.battle_view != null and main.battle_view.mode == "battle", "vue tactique ouverte automatiquement")
	var bv: BattleView = main.battle_view
	var b: Dictionary = bv.battle
	var mine: Array = CombatData.unit_ids(b).filter(func(id: String) -> bool: return b["units"][id]["nation"] == "france" and b["units"][id]["status"] == "active")
	bv.click_at(CombatData.v(b["units"][mine[0]]["pos"]))
	check(bv.selected == [mine[0]], "sélection individuelle par clic")
	bv.click_at(CombatData.v(b["units"][mine[1]]["pos"]), true)
	check(bv.selected.size() == 2, "sélection multiple (Maj)")
	bv.select_rect(Rect2(0, 0, 2000, 1400))
	check(bv.selected.size() == mine.size(), "sélection par rectangle (%d unités)" % bv.selected.size())
	bv.command_move(Vector2(1000, 700))
	check(b["units"][mine[0]]["order"] == "move", "ordre de groupe par clic droit")
	bv.selected = [mine[2]]
	check(press(bv.hud, "Position retranchée") and b["units"][mine[2]]["formation"] == "entrenched", "bouton de formation : effet réel")
	check(press(bv.hud, "Tenir la position") and b["units"][mine[2]]["order"] == "hold", "bouton « Tenir » : effet réel (ordre individuel)")
	var n_tr: int = (b["defenses"]["trenches"] as Array).size()
	press(bv.hud, "Tranchée (2 clics)")
	var p := CombatData.v(b["units"][mine[2]]["pos"])
	bv.click_at(p + Vector2(-60, 0))
	bv.click_at(p + Vector2(60, 0))
	check((b["defenses"]["trenches"] as Array).size() == n_tr + 1 and b["units"][mine[2]]["order"] == "build", "tranchée dessinée en bataille")
	press(bv.hud, "⏸ Pause")
	check(bool(b["paused"]), "pause (solo : accord du seul humain)")
	var t0 := int(b["tick"])
	bv._process(5.0)
	check(int(b["tick"]) == t0, "aucune progression en pause")
	press(bv.hud, "⏸ Pause")
	press(bv.hud, "×16")
	bv._process(1.0)
	check(int(b["tick"]) > t0, "la bataille avance en temps réel (×16)")
	# Phase 6, étape 2 : type d'engagement, front et répartition affichés ; rupture du combat.
	bv.refresh()
	var panel: String = bv.status_panel.get_parsed_text()
	check(panel.contains("Engagement") and panel.contains("Front") and panel.contains("en ligne") and panel.contains("en réserve"),
		"panneau : type d'engagement, front, soldats en ligne, en attente et en réserve")
	bv.selected = [mine[0]]
	bv.refresh()
	check(bv.info.get_parsed_text().contains("Front :"), "unité sélectionnée : place sur le front affichée")
	check(press(bv.hud, "Rompre le combat") and (b["engagement"]["disengaged"] as Dictionary).has(CombatData.ATTACKERS), "bouton « Rompre le combat » : repli ordonné du camp")
	bv._on_close()
	check(main.battle_view != null, "impossible de quitter une bataille active (T-029 A)")
	press(bv.hud, "Résolution automatique")
	check(s.state.active_battles.is_empty() and bv.result_box != null, "résolution automatique et résultat affiché")
	var res_text := ""
	for c: Node in bv.result_box.get_children()[0].get_children():
		if c is RichTextLabel:
			res_text += (c as RichTextLabel).get_parsed_text()
	check(res_text.contains("Type d'engagement"), "résultat : type d'engagement réalisé affiché")
	press(bv.result_box, "Retour à la carte")
	await process_frame
	check(main.battle_view == null and main.map_view.visible, "retour à la carte")
	check(not s.end_turn().has("error"), "mois suivant débloqué")
	# Préparation des défenses hors bataille.
	var army_region: String = s.state.formations["army_france_1"]["region"] if s.state.formations.has("army_france_1") else "region_008"
	if s.state.controller(army_region) == "france":
		main.open_planning(army_region)
		await process_frame
		var pv: BattleView = main.battle_view
		press(pv.hud, "Tranchée (2 clics)")
		pv.click_at(Vector2(800, 600))
		pv.click_at(Vector2(1000, 600))
		check(s.player_orders().any(func(o: Dictionary) -> bool: return o["type"] == Orders.BUILD_DEFENSE), "ordre de tranchée hors bataille préparé (%s)" % pv.message.text)
		pv._on_close()
	print("RÉSULTAT UI BATAILLE : %s" % ("VALIDÉ" if failures == 0 else "%d échec(s)" % failures))
	quit(1 if failures > 0 else 0)
