extends SceneTree
## C1 : banc de performance versionné (Phase I post-MIL-01).
## Mesure descendants(), view_for(), end_turn() et resolve() sur des états synthétiques
## de tailles variables, en paix et en guerre. Sortie machine (BENCH ...) sur stdout.
## Usage : godot --headless --path . --script tools/bench_phase1.gd -- <paix|guerre> <formations> [repetitions]

var rules: Dictionary = {}
var world: WorldMap = null


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <paix|guerre> <formations> [repetitions]")
		quit(2)
		return
	var mode: String = args[0]
	var n := maxi(10, int(args[1]))
	var reps := 20 if args.size() < 3 else maxi(1, int(args[2]))
	var s := GameSession.create()
	s.new_game("france", 1, 1914)
	rules = s.rules
	world = s.world
	var st := _build_state(s, n, mode)
	var label := "%s/%d" % [mode, n]
	_time_descendants(st, label, reps)
	_time_view_for(st, s, label, reps)
	_time_end_turn(st, s, label)
	quit()


func _build_state(s: GameSession, n: int, mode: String) -> GameState:
	var st := s.state
	# Réutilise les armées du scénario puis ajoute des unités synthétiques réparties.
	var armies: Array = []
	for fid: String in st.sorted_formation_ids():
		var f: Dictionary = st.formations[fid]
		if f.get("parent") == null or not st.formations.has(f.get("parent")):
			armies.append(fid)
	if armies.is_empty():
		return st
	var per := maxi(1, n / armies.size())
	var created := 0
	for aid: String in armies:
		for i in per:
			if created >= n:
				break
			var uid := "bench_u_%d" % created
			st.formations[uid] = {"id": uid, "nation": st.formations[aid]["nation"], "echelon": "unit",
				"unit_type": "infantry", "region": st.formations[aid]["region"], "parent": aid,
				"soldiers": 2000, "equipment": null, "morale": 70.0, "supplied": true,
				"planned_target": "", "battle_id": "", "encircled": false, "reserve": false,
				"name_fr": "Bench", "status": "synthétique"}
			created += 1
		if created >= n:
			break
	if mode == "guerre":
		st.wars.append({"id": "bench_war", "a": "france", "b": "german_empire", "since_turn": 0})
	if st.has_method("invalidate_hierarchy"):
		st.invalidate_hierarchy()
	return st


func _ms(a: int, b: int) -> float:
	return float(b - a) / 1000.0


func _time_descendants(st: GameState, label: String, reps: int) -> void:
	var ids: Array = []
	for fid: String in st.sorted_formation_ids():
		var f: Dictionary = st.formations[fid]
		if f.get("parent") == null or not st.formations.has(f.get("parent")):
			ids.append(fid)
	if ids.is_empty():
		return
	var fid: String = ids[0]
	var t0 := Time.get_ticks_usec()
	for i in reps:
		st.descendants(fid)
	print("BENCH %s descendants x%d = %.1f ms" % [label, reps, _ms(t0, Time.get_ticks_usec())])


func _time_view_for(st: GameState, s: GameSession, label: String, reps: int) -> void:
	var t0 := Time.get_ticks_usec()
	for i in reps:
		IntelSystem.view_for(st, world, "france")
	print("BENCH %s view_for x%d = %.1f ms" % [label, reps, _ms(t0, Time.get_ticks_usec())])


func _time_end_turn(st: GameState, s: GameSession, label: String) -> void:
	var t0 := Time.get_ticks_usec()
	TurnResolver.resolve(st, world, rules, {"france": []})
	print("BENCH %s resolve = %.1f ms" % [label, _ms(t0, Time.get_ticks_usec())])
