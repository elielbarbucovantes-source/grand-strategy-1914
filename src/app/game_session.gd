class_name GameSession
extends RefCounted
## Façade de session : unique point d'entrée de l'interface vers la simulation.
## L'interface prépare des ordres pour le joueur ; la fin de tour fait décider les IA (sur leur
## vue filtrée) puis résout tous les ordres simultanément.

const RULES_PATH := "res://data/rules/game_rules.json"
const SCENARIO_PATH := "res://data/scenarios/campaign_1914.json"
const SANDBOX_PATH := "res://data/scenarios/sandbox_fictif.json"
const COMBAT_RULES_PATH := "res://data/rules/combat_rules.json"
const FORCES_RULES_PATH := "res://data/rules/forces_rules.json"
const AI_DOCTRINES_PATH := "res://data/rules/ai_doctrines.json"
const DIPLOMACY_RULES_PATH := "res://data/rules/diplomacy_rules.json"
const TRANSPORT_PATH := "res://data/game/transport_network.json"
const TRANSPORT_RULES_PATH := "res://data/rules/transport_rules.json"
const SAVE_DIR := "user://saves"

var world: WorldMap
var rules: Dictionary
var scenario: Dictionary
var state: GameState
var transport_network: TransportNetwork
var last_report: Dictionary = {}


static func load_json(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


static func create(world_path: String = WorldMap.DEFAULT_PATH) -> GameSession:
	var s := GameSession.new()
	s.world = WorldMap.load_from(world_path)
	s.rules = load_json(RULES_PATH)
	s.scenario = load_json(SCENARIO_PATH)
	s.rules["combat"] = load_json(COMBAT_RULES_PATH)
	s.rules["forces"] = load_json(FORCES_RULES_PATH)
	s.rules["ai_doctrines"] = load_json(AI_DOCTRINES_PATH)
	s.rules["diplomacy"] = load_json(DIPLOMACY_RULES_PATH)
	s.rules["transport"] = load_json(TRANSPORT_RULES_PATH)
	s.transport_network = TransportNetwork.load_from(TRANSPORT_PATH)
	s.rules["transport_network"] = s.transport_network  # référence en mémoire, non sérialisée
	ForceLedger.configure(s.rules["forces"].get("casualties", {}))
	if s.world == null or s.rules.is_empty() or s.scenario.is_empty() or (s.rules["combat"] as Dictionary).is_empty() \
			or (s.rules["forces"] as Dictionary).is_empty():
		push_error("GameSession : données introuvables")
		return null
	return s


func playable_nations() -> Array:
	var out: Array = []
	for nid: String in scenario["nation_order"]:
		if scenario["nations"][nid]["playable"]:
			out.append(nid)
	return out


## `scenario_id` : "campaign_1914" (historique : effectifs sourcés des sept puissances jouables, MIL-01)
## ou "sandbox_fictif" (forces FICTIVES de test). Voir `scenario["forces_source"]`.
func new_game(player: String, start_month: int, seed_value: int = 1914, scenario_id: String = "campaign_1914") -> String:
	scenario = load_json(SANDBOX_PATH if scenario_id == "sandbox_fictif" else SCENARIO_PATH)
	if not GameCalendar.is_valid_month(start_month):
		return "mois de départ invalide"
	# T-057 (VALIDÉ) : la campagne historique a un mois de départ fixe (janvier 1914) ; le bac à sable
	# FICTIF garde un mois librement configurable (`start.month` = null).
	var fixed_month = scenario.get("start", {}).get("month")
	if fixed_month != null and start_month != int(fixed_month):
		return "la campagne historique commence en %s (T-057)" % GameCalendar.label(int(scenario["start"]["year"]), int(fixed_month))
	if not scenario["nations"].has(player):
		return "pays inconnu"
	state = GameState.from_scenario(scenario, start_month, player, seed_value)
	state.log_event("partie", "Début de la campagne : %s, %s." % [state.nations[player]["name_fr"], state.date_label()], [player])
	LogisticsSystem.update_supply(state, world)
	return ""


func player_orders() -> Array:
	return state.pending_orders.get(state.player_nation, [])


## Ajoute un ordre du joueur après validation immédiate (retour d'erreur à l'interface).
func queue_order(order: Dictionary) -> String:
	var reason := ""
	match order["type"]:
		Orders.MOVE:
			reason = MilitarySystem.validate_move(state, world, rules, order)
			if reason != "" and _declares_war_this_turn_on(state.controller(order["target"])) \
					and state.formations.has(order["formation"]) \
					and world.neighbor_ids(state.formations[order["formation"]]["region"], true).has(order["target"]):
				reason = ""  # revalidé après la phase diplomatique du tour
		Orders.SET_INDUSTRY_ALLOCATION:
			reason = EconomySystem.validate_allocation(rules, order)
		Orders.TERRITORIAL_OVERSEAS:
			reason = TerritorialForce.validate_overseas(state, rules["forces"], order)
		Orders.SET_DEFENSIVE_POSTURE:
			reason = MilitarySystem.validate_posture(state, order)
		Orders.BUILD_DEFENSE:
			reason = DefenseSystem.validate(state, rules["combat"], order)
		Orders.MOBILIZE, Orders.SET_MOBILIZATION_POSTURE, Orders.SET_MOBILIZATION_ALLOCATION, Orders.CALL_NEXT_ECHELON:
			reason = MobilizationSystem.validate(state, order, world, rules["forces"]["mobilization"])
			var same := [Orders.MOBILIZE, Orders.SET_MOBILIZATION_POSTURE] if order["type"] in [Orders.MOBILIZE, Orders.SET_MOBILIZATION_POSTURE] else [order["type"]]
			for o: Dictionary in player_orders():
				if o["type"] in same and reason == "":
					reason = "ordre de mobilisation de ce type déjà donné ce mois-ci"
		Orders.DISRUPT_LINK, Orders.REPAIR_LINK, Orders.SET_PORT_STATUS:
			reason = TransportSystem.validate(state, transport_network, order)
		_:
			reason = DiplomacySystem.validate(state, order, rules)
	if reason != "":
		return reason
	var list: Array = state.pending_orders.get(state.player_nation, [])
	if order["type"] == Orders.MOVE:
		list = list.filter(func(o: Dictionary) -> bool: return not (o["type"] == Orders.MOVE and o["formation"] == order["formation"]))
		state.formations[order["formation"]]["planned_target"] = order["target"]
	elif order["type"] == Orders.SET_DEFENSIVE_POSTURE:
		list = list.filter(func(o: Dictionary) -> bool: return not (o["type"] == Orders.SET_DEFENSIVE_POSTURE and o["army"] == order["army"]))
	list.append(order)
	state.pending_orders[state.player_nation] = list
	return ""


func _declares_war_this_turn_on(target: String) -> bool:
	for o: Dictionary in player_orders():
		if o["type"] == Orders.DECLARE_WAR and o["target"] == target:
			return true
	return false


func cancel_orders() -> void:
	for o: Dictionary in player_orders():
		if o["type"] == Orders.MOVE:
			state.formations[o["formation"]]["planned_target"] = ""
	state.pending_orders.erase(state.player_nation)


## Fin du mois : décisions des IA (vues filtrées), puis résolution simultanée de tous les ordres.
func end_turn() -> Dictionary:
	if not state.active_battles.is_empty():
		return {"error": "%d bataille(s) en cours : elles doivent être jouées ou résolues avant le mois suivant (T-029 A)" % state.active_battles.size()}
	var orders: Dictionary = {state.player_nation: player_orders().duplicate(true)}
	for nid: String in state.nation_order:
		if nid == state.player_nation:
			continue
		orders[nid] = NationAgent.decide(IntelSystem.view_for(state, world, nid, rules), world, rules)
	last_report = TurnResolver.resolve(state, world, rules, orders)
	return last_report


## Désigne une unité comme réserve pour les prochaines batailles (T-040 B).
func set_reserve(uid: String, on: bool) -> String:
	if not state.formations.has(uid) or state.formations[uid]["nation"] != state.player_nation:
		return "unité inconnue ou étrangère"
	if state.formations[uid]["echelon"] != "unit":
		return "seules les unités peuvent être gardées en réserve"
	if state.formations[uid].get("battle_id", "") != "":
		return "unité engagée dans une bataille"
	state.formations[uid]["reserve"] = on
	return ""


# ------------------------------------------------------------------ batailles du joueur
## Bataille que le joueur doit commander maintenant (une seule à la fois, file T-029).
func current_battle() -> Dictionary:
	return BattleManager.next_for(state, state.player_nation)


## Avance la bataille courante de `ticks` pas (IA pour les autres pays) ; clôture si terminée.
func advance_battle(ticks: int) -> Dictionary:
	var b := current_battle()
	if b.is_empty():
		return {}
	BattleManager.advance(b, rules["combat"], ticks)
	if b["status"] == "ended":
		return BattleManager.finish(state, world, rules["combat"], b)
	return {}


## Résolution automatique : l'IA joue aussi les unités du joueur jusqu'à la durée maximale.
func auto_resolve_battle() -> Dictionary:
	var b := current_battle()
	if b.is_empty():
		return {}
	BattleManager.run_to_end(b, rules["combat"], true)
	return BattleManager.finish(state, world, rules["combat"], b)


## Déconnexion / reconnexion d'un joueur humain (T-046) : appliquées à toutes ses batailles actives.
## Fondation de simulation : aucune couche réseau n'appelle encore ces fonctions.
func disconnect_player(nation: String) -> void:
	for b: Dictionary in state.active_battles:
		BattleManager.on_disconnect(b, rules["combat"], nation)


func reconnect_player(nation: String) -> void:
	for b: Dictionary in state.active_battles:
		BattleManager.on_reconnect(b, nation)


## Catégories d'effectifs d'un pays (MIL-01) : actifs, réservistes non appelés (par échelon), en cours,
## bloqués, incorporés, présents, pertes et prisonniers ; posture et allocation.
func forces_summary(nation: String) -> Dictionary:
	return MobilizationSystem.summary(state, nation)


## Informations publiques de mobilisation de toutes les puissances (T-056, Q3) : jamais les volumes.
func public_mobilization() -> Dictionary:
	return MobilizationSystem.public_view(state, rules["forces"]["mobilization"])


func save_game(name: String) -> String:
	return SaveRepository.save(SAVE_DIR.path_join(name + ".json"), state, world, rules)


func load_game(path: String) -> String:
	var result := SaveRepository.load_save(path, world, rules)
	if result.has("error"):
		return result["error"]
	state = result["state"]
	return ""


## Part du territoire sous contrôle militaire (seuil de 90 % VALIDÉ, modalités OUVERTES :
## valeur affichée, aucune fin de partie automatique).
func territorial_share(nation: String) -> float:
	return float(state.regions_controlled_by(nation).size()) / float(state.regions.size())
