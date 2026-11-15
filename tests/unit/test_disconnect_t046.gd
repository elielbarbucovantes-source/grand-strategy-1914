extends RefCounted
## T-046 : déconnexions pendant une bataille (simulation locale ; AUCUNE couche réseau n'est testée).

var runner: Object


func _battle(humans: Array) -> Array:
	var s := GameSession.create()
	s.new_game("france", 1, 1914, "sandbox_fictif")
	var st := s.state
	st.human_nations = humans.duplicate()
	st.wars.append({"id": "w", "a": "german_empire", "b": "france", "since_turn": 0})
	st.move_army("army_france_1", "region_011")
	st.move_army("army_german_empire_1", "region_011")
	var b := BattleManager.create(st, s.world, s.rules, s.rules["combat"], {"region": "region_011",
		"attackers": ["army_german_empire_1"], "defenders": ["army_france_1"],
		"origin": {"army_german_empire_1": "region_035", "army_france_1": "region_011"}})
	st.active_battles.append(b)
	return [s, b]


func _snapshot(b: Dictionary, nation: String) -> Dictionary:
	var out := {}
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if u["nation"] == nation:
			out[uid] = {"order": u["order"], "dest": u["dest"], "formation": u["formation"], "soldiers": u["soldiers"]}
	return out


func _formation_ids(st: GameState) -> Array:
	return st.sorted_formation_ids()


func test_solo_disconnection_pauses_until_return() -> void:
	var r := _battle(["france"])
	var s: GameSession = r[0]
	var b: Dictionary = r[1]
	runner.check(not bool(b["multiplayer"]), "partie solo")
	s.advance_battle(10)
	var t0 := int(b["tick"])
	var before := _snapshot(b, "france")
	var ids := _formation_ids(s.state)
	s.disconnect_player("france")
	runner.check(bool(b["disconnect_pause"]) and b["controllers"]["france"] == "disconnected", "solo : bataille en pause à la déconnexion")
	s.advance_battle(40)
	runner.check(int(b["tick"]) == t0, "aucune progression tant que le joueur est absent")
	runner.check(_snapshot(b, "france") == before, "unités et ordres intacts pendant l'absence")
	runner.check(not BattleManager.request_pause(b, "france", false) and bool(b["disconnect_pause"]), "un absent ne peut pas lever la pause")
	s.reconnect_player("france")
	runner.check(b["controllers"]["france"] == "human" and not bool(b["disconnect_pause"]), "reconnexion : contrôle restitué, pause levée")
	s.advance_battle(5)
	runner.check(int(b["tick"]) == t0 + 5, "la bataille reprend après le retour")
	runner.check(_formation_ids(s.state) == ids, "aucune unité perdue ni dupliquée")


func test_multiplayer_grace_then_ai_then_reconnect() -> void:
	var r := _battle(["france", "german_empire"])
	var s: GameSession = r[0]
	var b: Dictionary = r[1]
	var cr: Dictionary = s.rules["combat"]
	runner.check(bool(b["multiplayer"]) and b["controllers"]["france"] == "human" and b["controllers"]["german_empire"] == "human", "multijoueur : deux humains")
	var fr_units: Array = CombatData.unit_ids(b).filter(func(id: String) -> bool: return b["units"][id]["nation"] == "france" and b["units"][id]["status"] == CombatData.ACTIVE)
	var target := Vector2(1000, 700)
	runner.check(TacticalOrders.move(b, cr, "france", fr_units, target) == "", "ordre de groupe donné avant la déconnexion")
	var before := _snapshot(b, "france")
	var unit_count := CombatData.unit_ids(b).size()
	var ids := _formation_ids(s.state)
	var t0 := int(b["tick"])
	s.disconnect_player("france")
	runner.check(b["controllers"]["france"] == "disconnected" and not bool(b["disconnect_pause"]), "multijoueur : pas de pause imposée aux autres joueurs")
	runner.check(not BattleManager._ai_controls(b, cr, "france"), "délai de grâce : l'IA ne commande pas encore")
	var grace := int(cr["disconnection"]["grace_ticks"])
	BattleManager.advance(b, cr, grace - 1)
	runner.check(int(b["tick"]) == t0 + grace - 1, "la bataille continue pour les autres joueurs")
	var during := _snapshot(b, "france")
	var kept := true
	for uid: String in before:
		if not during.has(uid) or b["units"][uid]["status"] != CombatData.ACTIVE or during[uid]["order"] == before[uid]["order"]:
			continue
		# Seule évolution admise : ordre de déplacement accompli (arrivée à destination → « tenir »).
		var arrived: bool = before[uid]["order"] == "move" and during[uid]["order"] == "hold" \
			and CombatData.v(b["units"][uid]["pos"]).distance_to(CombatData.v(before[uid]["dest"])) < 10.0
		if not arrived:
			kept = false
	runner.check(kept, "ordres du joueur conservés pendant le délai de grâce")
	runner.check(b["controllers"]["france"] == "disconnected", "toujours en délai de grâce")
	BattleManager.advance(b, cr, 1)
	runner.check(b["controllers"]["france"] == "ai_takeover", "délai écoulé : l'IA prend le contrôle")
	runner.check(BattleManager._ai_controls(b, cr, "france"), "l'IA décide désormais pour les unités françaises")
	runner.check(not BattleManager.voters(b).has("france"), "un joueur remplacé par l'IA ne vote pas")
	runner.check(BattleManager.request_pause(b, "german_empire", true), "pause : unanimité des humains connectés (le seul restant)")
	BattleManager.request_pause(b, "german_empire", false)
	BattleManager.advance(b, cr, 20)
	s.reconnect_player("france")
	runner.check(b["controllers"]["france"] == "human", "reconnexion : contrôle restitué au joueur")
	runner.check(not BattleManager._ai_controls(b, cr, "france"), "l'IA cesse de commander")
	runner.check(CombatData.unit_ids(b).size() == unit_count, "aucune unité de bataille ajoutée ni retirée par la déconnexion")
	runner.check(_formation_ids(s.state) == ids, "aucune formation stratégique perdue ni dupliquée")
	var locks := 0
	for uid: String in CombatData.unit_ids(b):
		if s.state.formations.has(uid) and s.state.formations[uid]["battle_id"] == b["id"]:
			locks += 1
	runner.check(locks == unit_count, "verrous de bataille inchangés (pas de double emploi)")


func test_disconnection_state_survives_save_reload() -> void:
	var r := _battle(["france", "german_empire"])
	var s: GameSession = r[0]
	var b: Dictionary = r[1]
	s.disconnect_player("german_empire")
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/t046.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde pendant une déconnexion")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "rechargement intègre")
	var b2: Dictionary = (loaded["state"] as GameState).active_battles[0]
	runner.check(b2["controllers"]["german_empire"] == "disconnected" and int(b2["disconnected"]["german_empire"]) == int(b["tick"]), "état de déconnexion et instant conservés")
	runner.check((loaded["state"] as GameState).checksum() == s.state.checksum(), "empreinte identique")
