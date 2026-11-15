class_name GameSession
extends RefCounted
## Façade de session : unique point d'entrée de l'interface vers la simulation.
## L'interface prépare des ordres pour le joueur ; la fin de tour fait décider les IA (sur leur
## vue filtrée) puis résout tous les ordres simultanément.

const RULES_PATH := "res://data/rules/game_rules.json"
const SCENARIO_PATH := "res://data/scenarios/campaign_1914.json"
const SAVE_DIR := "user://saves"

var world: WorldMap
var rules: Dictionary
var scenario: Dictionary
var state: GameState
var last_report: Dictionary = {}


static func load_json(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


static func create(world_path: String = WorldMap.DEFAULT_PATH) -> GameSession:
	var s := GameSession.new()
	s.world = WorldMap.load_from(world_path)
	s.rules = load_json(RULES_PATH)
	s.scenario = load_json(SCENARIO_PATH)
	if s.world == null or s.rules.is_empty() or s.scenario.is_empty():
		push_error("GameSession : données introuvables")
		return null
	return s


func playable_nations() -> Array:
	var out: Array = []
	for nid: String in scenario["nation_order"]:
		if scenario["nations"][nid]["playable"]:
			out.append(nid)
	return out


func new_game(player: String, start_month: int, seed_value: int = 1914) -> String:
	if not GameCalendar.is_valid_month(start_month):
		return "mois de départ invalide"
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
		_:
			reason = DiplomacySystem.validate(state, order)
	if reason != "":
		return reason
	var list: Array = state.pending_orders.get(state.player_nation, [])
	if order["type"] == Orders.MOVE:
		list = list.filter(func(o: Dictionary) -> bool: return not (o["type"] == Orders.MOVE and o["formation"] == order["formation"]))
		state.formations[order["formation"]]["planned_target"] = order["target"]
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
	var orders: Dictionary = {state.player_nation: player_orders().duplicate(true)}
	for nid: String in state.nation_order:
		if nid == state.player_nation:
			continue
		orders[nid] = NationAgent.decide(IntelSystem.view_for(state, world, nid), world, rules)
	last_report = TurnResolver.resolve(state, world, rules, orders)
	return last_report


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
