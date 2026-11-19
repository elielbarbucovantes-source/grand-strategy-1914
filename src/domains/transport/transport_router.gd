class_name TransportRouter
extends RefCounted
## Phase IV — calcul d'itinéraires multimodaux déterministe (Dijkstra), avec capacités,
## état des liaisons, contrôle territorial, accords de transit et pénalités de changement de mode.

const MODE_TIME := {"rail": 0.25, "road": 1.0, "river": 0.7, "maritime": 0.5}
const MODE_CHANGE := 0.6


static func accessible(state: GameState, nation: String, rid: String) -> bool:
	var owner := state.controller(rid)
	if owner == nation or state.at_war(nation, owner) or state.has_transit(nation, owner):
		return true
	return LogisticsSystem.friendly(state, nation, rid)


## Retourne {"ok":bool,"path":[regions],"links":[ids],"modes":[],"time":float,
##          "bottleneck":id,"reason":String}._CACHE est propre à l'instance réseau.
static func route(net: TransportNetwork, state: GameState, from: String, to: String,
		nation: String, needed: int = 1, allow_modes: Array = []) -> Dictionary:
	if from == to:
		return {"ok": true, "path": [from], "links": [], "modes": [], "time": 0.0,
			"bottleneck": "", "reason": ""}
	if not net.by_region.has(from) or not net.by_region.has(to):
		return {"ok": false, "reason": "région absente du réseau"}
	var modes: Array = allow_modes if not allow_modes.is_empty() else MODE_TIME.keys()
	var dist: Dictionary = {from: 0.0}
	var prev: Dictionary = {}
	var prev_link: Dictionary = {}
	var prev_mode: Dictionary = {}
	var visited: Dictionary = {}
	while true:
		var cur := ""
		var best := INF
		for rid: String in dist:
			if visited.has(rid):
				continue
			if float(dist[rid]) < best:
				best = float(dist[rid])
				cur = rid
		if cur == "":
			break
		if cur == to:
			break
		visited[cur] = true
		for lid: String in net.by_region.get(cur, []):
			var l: Dictionary = net.links[lid]
			var a := str(l["a"])
			var b := str(l["b"])
			var nxt := b if a == cur else a
			if visited.has(nxt) or not modes.has(str(l["mode"])):
				continue
			if not accessible(state, nation, nxt) or not accessible(state, nation, cur):
				continue
			if TransportNetwork.condition(state, lid) in ["interrupted", "repairing"]:
				continue
			if TransportNetwork.available(state, net, lid) < needed:
				continue
			if str(l["mode"]) == "maritime" and not _has_port_capacity(net, state, cur):
				continue
			var cost := float(l.get("distance_km", 0)) * float(MODE_TIME[str(l["mode"])]) / 100.0
			cost += float(l.get("difficulty", 1.0)) * 0.2
			if str(l["mode"]) != str(prev_mode.get(cur, "")):
				cost += MODE_CHANGE
			if str(TransportNetwork.condition(state, lid)) == "degraded":
				cost *= 1.8
			var nd := best + cost
			if not dist.has(nxt) or nd < float(dist[nxt]) - 0.000001:
				dist[nxt] = nd
				prev[nxt] = cur
				prev_link[nxt] = lid
				prev_mode[nxt] = str(l["mode"])
	if not dist.has(to):
		return {"ok": false, "reason": "aucun itinéraire disponible"}
	var path: Array = [to]
	var used: Array = []
	var mds: Array = []
	var node := to
	var guard := 0
	while node != from and guard < 200:
		guard += 1
		used.append(prev_link.get(node, ""))
		mds.append(prev_mode.get(node, ""))
		node = prev.get(node, from)
		path.append(node)
	path.reverse()
	used.reverse()
	mds.reverse()
	var bottleneck := ""
	var low := INF
	for lid: String in used:
		var av := TransportNetwork.available(state, net, lid)
		if av < low:
			low = float(av)
			bottleneck = lid
	return {"ok": true, "path": path, "links": used, "modes": mds,
		"time": float(dist[to]), "bottleneck": bottleneck, "reason": ""}


static func _has_port_capacity(net: TransportNetwork, state: GameState, rid: String) -> bool:
	for pid: String in net.ports_by_region.get(rid, []):
		var p: Dictionary = net.ports[pid]
		if str(p.get("status", "operational")) == "operational" and int(p.get("capacity", 0)) > 0:
			return true
	return false


## Consomme la capacité de chaque liaison d'un itinéraire. Retourne false si une liaison sature.
static func commit(net: TransportNetwork, state: GameState, result: Dictionary, amount: int) -> bool:
	for lid: String in result.get("links", []):
		if not TransportNetwork.consume(state, net, lid, amount):
			return false
	return true


static func summary(result: Dictionary) -> String:
	if not bool(result.get("ok", false)):
		return "itinéraire indisponible : %s" % str(result.get("reason", ""))
	return " → ".join(PackedStringArray(result["path"])) + " | %s | temps %.2f" % [
		str(result["modes"]), float(result["time"])]
