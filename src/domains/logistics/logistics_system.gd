class_name LogisticsSystem
extends RefCounted
## Logistique indépendante (dossier §7). Implémenté : CONTINUITÉ TERRITORIALE.
## Une région ou une formation est « accessible » si elle est reliée à la région-capitale
## de sa nation par des régions contrôlées par elle ou par un allié (traité « alliance »
## actif), via frontières terrestres ou détroits.
## Distinction (dossier §7) :
##   possédé    = stocks nationaux (données ECO-01 à sourcer)
##   accessible = continuité territoriale (CALCULÉ ici)
##   livré      = selon capacités de transport (routes, rail, ports) : OUVERT ; null tant que
##                les capacités ne sont pas définies. Le réseau ferré actuel est fragmenté
##                (17 composantes, docs/map/decisions/THEMATIC_LAYERS.md).


static func friendly(state: GameState, nation: String, rid: String) -> bool:
	var owner := state.controller(rid)
	return owner == nation or not state.active_treaties_between(nation, owner, "alliance").is_empty()


## Régions accessibles depuis la capitale (parcours en largeur, ordre déterministe).
static func accessible_regions(state: GameState, world: WorldMap, nation: String) -> Dictionary:
	var capital: String = state.nations[nation]["capital_region_id"]
	var reached: Dictionary = {}
	if state.controller(capital) != nation:
		return reached  # capitale perdue : aucune continuité
	var queue: Array[String] = [capital]
	reached[capital] = true
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for next: String in world.neighbor_ids(current, true):
			if not reached.has(next) and friendly(state, nation, next):
				reached[next] = true
				queue.append(next)
	return reached


## Met à jour l'état de ravitaillement des formations (connexion à la capitale).
## Les conséquences d'un mauvais ravitaillement ne sont pas définies (dossier §7.2) :
## l'état est calculé et affiché, sans pénalité appliquée.
static func update_supply(state: GameState, world: WorldMap, rules: Dictionary = {}) -> void:
	var net: TransportNetwork = rules.get("transport_network") as TransportNetwork
	TransportNetwork.ensure_state(state)
	var cache: Dictionary = {}
	var routes: Dictionary = {}
	for fid: String in state.sorted_formation_ids():
		var f: Dictionary = state.formations[fid]
		var nation := str(f["nation"])
		if not cache.has(nation):
			cache[nation] = accessible_regions(state, world, nation)
		var was: bool = f["supplied"]
		f["supplied"] = (cache[nation] as Dictionary).has(str(f["region"]))
		# Phase IV : "livré" dépend du réseau de transport, pas seulement de la continuité.
		if net != null:
			var key := nation + "|" + str(f["region"])
			if not routes.has(key):
				var cap := str(state.nations[nation].get("capital_region_id", ""))
				routes[key] = TransportRouter.route(net, state, cap, str(f["region"]), nation, 1)
			var r: Dictionary = routes[key]
			f["delivered"] = bool(r.get("ok", false))
			f["route_time"] = float(r.get("time", 0.0))
			f["route_bottleneck"] = str(r.get("bottleneck", ""))
		if was and not f["supplied"] and state.is_top_level(f):  # une entrée par armée, pas par unité
			state.log_event("logistique", "%s (%s) est coupée de sa capitale." % [f["name_fr"], state.nations[f["nation"]]["name_fr"]], [f["nation"]])


static func summary(state: GameState, world: WorldMap, nation: String, rules: Dictionary = {}) -> Dictionary:
	var owned := state.regions_controlled_by(nation)
	var acc := accessible_regions(state, world, nation)
	var cut: Array = owned.filter(func(rid: String) -> bool: return not acc.has(rid))
	var net: TransportNetwork = rules.get("transport_network") as TransportNetwork
	var delivered := 0
	var delivered_status := "OUVERT : réseau de transport non chargé"
	if net != null:
		var cap := str(state.nations[nation].get("capital_region_id", ""))
		for rid: String in owned:
			var r := TransportRouter.route(net, state, cap, rid, nation, 1)
			if bool(r.get("ok", false)):
				delivered += 1
		delivered_status = "Phase IV : itinéraires multimodaux calculés avec capacités et contrôle"
	return {"controlled": owned.size(), "accessible": acc.size(), "cut_off": cut,
		"delivered": delivered, "delivered_status": delivered_status}
