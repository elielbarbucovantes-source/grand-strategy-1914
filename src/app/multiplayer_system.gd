class_name MultiplayerSystem
extends RefCounted
## Phase VII.H/I — socle multijoueur LOCAL déterministe. L'autorité est le résolveur de tour
## existant : les ordres sont soumis par joueur, validés, puis résolus simultanément. Le hachage
## d'état détecte les désynchronisations ; les vues filtrées garantissent la confidentialité.
## AUCUN RÉSEAU RÉEL N'EST IMPLÉMENTÉ : cette couche est testable localement.


static func cfg(rules: Dictionary) -> Dictionary:
	return rules.get("multiplayer", {})


static func setup(state: GameState, players: Dictionary, rules: Dictionary, world: WorldMap = null) -> String:
	var c := cfg(rules)
	if players.size() < 2 or players.size() > int(c.get("max_players", 8)):
		return "nombre de joueurs invalide"
	state.multiplayer = {"players": players.duplicate(true), "host": str(players.keys()[0]),
		"state": "lobby", "orders": {}, "state_hashes": [], "events": []}
	for nid: String in players:
		if not state.nations.has(nid):
			return "État inconnu : " + nid
		if not state.human_nations.has(nid):
			state.human_nations.append(nid)
	state.multiplayer["state"] = "playing"
	return ""


static func submit_order(state: GameState, player: String, order: Dictionary, rules: Dictionary) -> String:
	if not state.multiplayer["players"].has(player):
		return "joueur inconnu"
	if str(order.get("nation", "")) != player:
		return "ordre émis au nom d'un autre État"
	var list: Array = state.multiplayer["orders"].get(player, [])
	list.append(order.duplicate(true))
	state.multiplayer["orders"][player] = list
	return ""


static func resolve_orders(state: GameState, rules: Dictionary, world: WorldMap = null) -> Dictionary:
	var all: Dictionary = {}
	for player: String in state.multiplayer["players"]:
		all[player] = state.multiplayer["orders"].get(player, [])
	var report := Dictionary()
	if world != null:
		report = TurnResolver.resolve(state, world, rules, all)
	state.multiplayer["orders"] = {}
	var h := state.checksum()
	(state.multiplayer["state_hashes"] as Array).append({"turn": state.turn, "hash": h})
	return report


static func detect_desync(state: GameState, expected_hash: String, rules: Dictionary) -> bool:
	var tolerance := int(cfg(rules).get("desync_tolerance", 0))
	var last: Array = state.multiplayer["state_hashes"]
	if last.is_empty():
		return false
	var current := str((last[last.size() - 1] as Dictionary).get("hash", ""))
	return current != expected_hash and tolerance == 0


static func disconnect_player(state: GameState, player: String) -> String:
	if not state.multiplayer["players"].has(player):
		return "joueur inconnu"
	state.multiplayer["players"][player]["connected"] = false
	(state.multiplayer["events"] as Array).append({"turn": state.turn, "player": player, "event": "disconnect"})
	state.log_event("multijoueur", "%s déconnecté." % player, [player])
	return ""


static func reconnect_player(state: GameState, player: String) -> String:
	if not state.multiplayer["players"].has(player):
		return "joueur inconnu"
	state.multiplayer["players"][player]["connected"] = true
	(state.multiplayer["events"] as Array).append({"turn": state.turn, "player": player, "event": "reconnect"})
	return ""


static func should_ai_takeover(state: GameState, player: String, rules: Dictionary) -> bool:
	var c := cfg(rules)
	var limit := int(c.get("ai_takeover_after_turns", 2))
	var info: Dictionary = state.multiplayer["players"].get(player, {})
	if bool(info.get("connected", true)):
		return false
	var last_seen := int(info.get("last_seen_turn", state.turn))
	return state.turn - last_seen >= limit


## Vue filtrée : un joueur ne reçoit que ses ordres, ses messages privés et son renseignement.
static func view_for(state: GameState, player: String, rules: Dictionary) -> Dictionary:
	if not state.multiplayer["players"].has(player):
		return {}
	var secret: Array = cfg(rules).get("secrecy", [])
	var view := {
		"nation": player, "turn": state.turn, "connected": bool(state.multiplayer["players"][player].get("connected", true)),
		"own_orders": (state.multiplayer["orders"].get(player, []) as Array).duplicate(true),
		"own_state_hash": "", "players": {}
	}
	for p: String in state.multiplayer["players"]:
		var info: Dictionary = state.multiplayer["players"][p].duplicate(true)
		if secret.has("orders") and p != player:
			info.erase("orders")
		view["players"][p] = info
	if not secret.has("intel"):
		view["intel"] = (state.tech["intel"].get(player, []) as Array).duplicate(true)
	return view
