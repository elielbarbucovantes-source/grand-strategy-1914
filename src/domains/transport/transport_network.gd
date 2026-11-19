class_name TransportNetwork
extends RefCounted
## Phase IV — réseau de transport chargé depuis data/game/transport_network.json.
## Données pures + état d'exploitation (condition, capacité utilisée, réparations).
## Aucune dépendance à l'interface. Le cache de routage n'est pas sérialisé.

const DEFAULT_PATH := "res://data/game/transport_network.json"

var links: Dictionary = {}          # id -> {id,a,b,mode,distance_km,capacity,...}
var by_region: Dictionary = {}      # region id -> Array[String] de ids de liaisons
var ports: Dictionary = {}          # city id -> port
var ports_by_region: Dictionary = {}
var rail_internal: Dictionary = {}  # region id -> capacité ferroviaire interne
var passes: Array = []
var relief: Dictionary = {}
var source_sha256: String = ""
var _cache: Dictionary = {}


static func load_from(path: String = DEFAULT_PATH) -> TransportNetwork:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if not (data is Dictionary):
		return null
	var n := TransportNetwork.new()
	n.source_sha256 = text.sha256_text()
	var raw_links: Variant = data.get("links", [])
	for l: Dictionary in raw_links:
		n.links[str(l["id"])] = l
	var raw_ports: Variant = data.get("ports", [])
	for p: Dictionary in raw_ports:
		n.ports[str(p["id"])] = p
	n.rail_internal = data.get("rail_internal_capacity", {})
	n.passes = data.get("passes", [])
	n.relief = data.get("relief", {})
	for l: Dictionary in n.links.values():
		for r: String in [str(l["a"]), str(l["b"])]:
			if not n.by_region.has(r):
				n.by_region[r] = []
			(n.by_region[r] as Array).append(str(l["id"]))
	for p: Dictionary in n.ports.values():
		var r := str(p["region_id"])
		if not n.ports_by_region.has(r):
			n.ports_by_region[r] = []
		(n.ports_by_region[r] as Array).append(str(p["id"]))
	return n


## L'état d'exploitation est porté par GameState.transport (sérialisé).
static func ensure_state(state: GameState) -> void:
	if not (state.transport is Dictionary):
		state.transport = {}
	for k: String in ["conditions", "usage", "repairs", "disruptions"]:
		if not (state.transport.has(k)):
			state.transport[k] = {} if k != "disruptions" else []


static func condition(state: GameState, lid: String) -> String:
	return str(state.transport.get("conditions", {}).get(lid, "operational"))


static func set_condition(state: GameState, lid: String, value: String, reason: String = "") -> void:
	ensure_state(state)
	(state.transport["conditions"] as Dictionary)[lid] = value
	if value == "interrupted":
		(state.transport["disruptions"] as Array).append({"turn": state.turn, "link": lid, "reason": reason})
	state.log_event("transport", "Liaison %s : %s." % [lid, value], [])


static func available(state: GameState, net: TransportNetwork, lid: String) -> int:
	var l: Dictionary = net.links.get(lid, {})
	if l.is_empty():
		return 0
	var c := condition(state, lid)
	if c == "interrupted":
		return 0
	var factor := 0.5 if c == "degraded" else 1.0
	return maxi(0, int(int(l["capacity"]) * factor) - int(state.transport.get("usage", {}).get(lid, 0)))


static func consume(state: GameState, net: TransportNetwork, lid: String, amount: int) -> bool:
	if available(state, net, lid) < amount:
		return false
	ensure_state(state)
	var u: Dictionary = state.transport["usage"]
	u[lid] = int(u.get(lid, 0)) + amount
	return true


static func release_month(state: GameState) -> void:
	# La capacité est un flux mensuel : elle est remise à zéro en début de mois.
	state.transport["usage"] = {}
	var repairs: Dictionary = state.transport.get("repairs", {})
	for lid: String in repairs.keys():
		if state.turn >= int(repairs[lid]):
			set_condition(state, lid, "operational", "réparation terminée")
			repairs.erase(lid)


static func begin_repair(state: GameState, lid: String, turns: int) -> void:
	ensure_state(state)
	set_condition(state, lid, "repairing", "réparation en cours")
	(state.transport["repairs"] as Dictionary)[lid] = state.turn + maxi(1, turns)

