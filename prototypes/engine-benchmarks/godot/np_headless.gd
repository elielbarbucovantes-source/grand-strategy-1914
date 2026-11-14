extends SceneTree
## NP-2 (graphe) et NP-4 (déterminisme), sans interface et sans règle de jeu.
## Usage : godot --headless --path prototypes/engine-benchmarks/godot --script np_headless.gd -- <world_map.json>

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var path: String = args[0] if args.size() > 0 else "../../../data/game/world_map.json"
	var t0: int = Time.get_ticks_usec()
	var text: String = FileAccess.get_file_as_string(path)
	var data: Dictionary = JSON.parse_string(text)
	var t_load: float = (Time.get_ticks_usec() - t0) / 1000.0
	var regions: Array = data["regions"]
	var nb: Dictionary = {}
	for r: Dictionary in regions:
		nb[r["id"]] = []
	for e: Dictionary in data["graph"]["land_edges"]:
		nb[e["a"]].append(e["b"]); nb[e["b"]].append(e["a"])
	for s: Dictionary in data["graph"]["strait_crossings"]:
		nb[s["a"]].append(s["b"]); nb[s["b"]].append(s["a"])
	var pos: Dictionary = {}
	for r: Dictionary in regions:
		pos[r["id"]] = Vector2(r["label_point_km"][0], r["label_point_km"][1])
	var ids: Array = nb.keys()
	ids.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1914
	var t1: int = Time.get_ticks_usec()
	var reached: int = 0
	for i in 10000:
		var a: String = ids[rng.randi_range(0, ids.size() - 1)]
		var b: String = ids[rng.randi_range(0, ids.size() - 1)]
		if _dijkstra(nb, pos, a, b) >= 0.0:
			reached += 1
	var per_query: float = (Time.get_ticks_usec() - t1) / 1000.0 / 10000.0
	# NP-4 : deux rejeux d'un état synthétique avec la même graine -> même empreinte
	var h1: String = _replay(ids, 42)
	var h2: String = _replay(ids, 42)
	var h3: String = _replay(ids, 43)
	print("NP godot | régions=%d arêtes=%d chargement_ms=%.1f dijkstra_ms=%.4f atteints=%d/10000" % [regions.size(), data["graph"]["land_edges"].size(), t_load, per_query, reached])
	print("NP-4 déterminisme | même graine identique=%s ; graine différente distincte=%s" % [str(h1 == h2), str(h1 != h3)])
	quit(0 if h1 == h2 and h1 != h3 else 1)

func _dijkstra(nb: Dictionary, pos: Dictionary, a: String, b: String) -> float:
	var dist: Dictionary = {a: 0.0}
	var open: Array = [a]
	var done: Dictionary = {}
	while not open.is_empty():
		var best: int = 0
		for i in range(1, open.size()):
			if dist[open[i]] < dist[open[best]]:
				best = i
		var u: String = open[best]
		open.remove_at(best)
		if u == b:
			return dist[u]
		done[u] = true
		for v: String in nb[u]:
			if done.has(v):
				continue
			var d: float = dist[u] + (pos[u] as Vector2).distance_to(pos[v])
			if not dist.has(v) or d < dist[v]:
				if not dist.has(v):
					open.append(v)
				dist[v] = d
	return -1.0

func _replay(ids: Array, seed_value: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var state: Dictionary = {}
	for id: String in ids:
		state[id] = 0
	for step in 1000:
		var id: String = ids[rng.randi_range(0, ids.size() - 1)]
		state[id] = state[id] + rng.randi_range(1, 9)
	return JSON.stringify(state).sha256_text()
