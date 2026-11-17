extends RefCounted
## Phase I post-MIL-01 (perf GameState) : index hiérarchique incrémental.
## Compare après CHAQUE mutation l'index avec un recalcul naïf de descendants(), units_of()
## et soldiers_of(). Couvre création, suppression, reparentage, Territorial Force outre-mer
## et rechargement de sauvegarde.

var runner: Object


func _session() -> GameSession:
	var s := GameSession.create()
	s.new_game("united_kingdom", 1, 1914)
	return s


## Recalcul naïf, indépendant de l'index : parcourt toutes les formations.
func _naive_descendants(st: GameState, fid: String) -> Array:
	if not st.formations.has(fid):
		return []
	var out: Array = []
	for id: String in st.formations:
		var cur: Variant = id
		var guard := 0
		while cur != null and st.formations.has(cur) and guard < 100:
			guard += 1
			cur = st.formations[cur].get("parent")
			if str(cur) == fid:
				out.append(id)
				break
	out.sort()
	return out


func _naive_units(st: GameState, fid: String) -> Array:
	var out: Array = []
	for uid: String in _naive_descendants(st, fid):
		if st.formations[uid].get("echelon") == "unit":
			out.append(uid)
	return out


func _assert_consistent(st: GameState, label: String) -> void:
	for fid: String in st.formations:
		var actual: Array = st.descendants(fid)
		var expected := _naive_descendants(st, fid)
		runner.check(JSON.stringify(actual) == JSON.stringify(expected),
			"%s : descendants(%s) index=%d naïf=%d" % [label, fid, actual.size(), expected.size()])
		var ua: Array = st.units_of(fid)
		var ue := _naive_units(st, fid)
		runner.check(JSON.stringify(ua) == JSON.stringify(ue), "%s : units_of(%s)" % [label, fid])
	var ids: Array = st.sorted_formation_ids()
	var sorted := ids.duplicate()
	sorted.sort()
	runner.check(JSON.stringify(ids) == JSON.stringify(sorted), "%s : sorted_formation_ids ordonné" % label)
	var top: Array = st.top_level_formation_ids()
	for tid: String in top:
		runner.check(st.is_top_level(st.formations[tid]), "%s : top-level %s valide" % [label, tid])


func test_index_matches_naive_on_initial_campaign() -> void:
	var s := _session()
	runner.check(s.state.formations.size() > 100, "scénario initial consistant (%d formations)" % s.state.formations.size())
	_assert_consistent(s.state, "initial")


func test_index_after_formation_creation() -> void:
	var s := _session()
	var army := "army_france_region_008"
	var before: Array = s.state.units_of(army)
	for i in 5:
		var uid := s.state.new_id("idx_probe")
		s.state.register_formation({"id": uid, "nation": "france", "echelon": "unit", "unit_type": "infantry",
			"region": "region_008", "parent": army, "soldiers": 4000 + i, "name_fr": "Probe",
			"supplied": true, "planned_target": "", "battle_id": "", "encircled": false, "reserve": false,
			"status": "test"})
		runner.check(s.state.units_of(army).size() == before.size() + i + 1, "création %d visible" % (i + 1))
		_assert_consistent(s.state, "création %d" % (i + 1))


func test_index_after_reparenting() -> void:
	var s := _session()
	var a1 := "army_france_region_008"
	var a2 := "army_german_empire_region_035"
	var units: Array = s.state.units_of(a1).duplicate()
	runner.check(units.size() > 0, "armée source a des unités")
	var moving: String = units[0]
	s.state.set_formation_parent(moving, a2)
	_assert_consistent(s.state, "reparentage")
	runner.check(s.state.units_of(a1).has(moving) == false, "unité retirée de l'armée source")
	runner.check(s.state.units_of(a2).has(moving), "unité ajoutée à l'armée cible")
	# Retour vers le parent initial.
	var old: String = ""
	for uid: String in units:
		if uid == moving:
			continue
		old = str(s.state.formations[uid].get("parent", ""))
	s.state.set_formation_parent(moving, old)
	_assert_consistent(s.state, "reparentage retour")


func test_index_after_removal() -> void:
	var s := _session()
	var victim: String = s.state.top_level_formation_ids()[0]
	var n := s.state.descendants(victim).size() + 1
	s.state.remove_formation(victim)
	runner.check(not s.state.formations.has(victim), "formation supprimée")
	runner.check(s.state.descendants(victim).is_empty(), "plus de descendants pour l'id supprimé")
	_assert_consistent(s.state, "suppression (%d formations retirées)" % n)


func test_index_after_territorial_force_overseas() -> void:
	var s := _session()
	# Incorporation de la TF, puis volontariat outre-mer dans une région nationale.
	var rules := s.rules
	var mr: Dictionary = rules["forces"]["mobilization"]
	var st := s.state
	MobilizationSystem.set_posture(st, mr, "united_kingdom", "generale")
	MobilizationSystem.monthly(st, s.world, rules["forces"])
	st.turn += 1
	MobilizationSystem.monthly(st, s.world, rules["forces"])
	st.turn += 3
	var found := ""
	var order: Dictionary = {}
	for fid: String in st.top_level_formation_ids():
		var f: Dictionary = st.formations[fid]
		if TerritorialForce.is_territorial(f) and f.get("service", "home") == "home" and not st.units_of(fid).is_empty():
			var candidate := {"nation": "united_kingdom", "army": fid, "type": "territorial_overseas"}
			if TerritorialForce.validate_overseas(st, rules["forces"], candidate) == "":
				found = fid
				order = candidate
				break
	runner.check(found != "", "une armée TF éligible au volontariat outre-mer existe")
	if found == "":
		return
	var before := st.units_of(found).size()
	TerritorialForce.apply_overseas(st, rules["forces"], order)
	runner.check(st.units_of(found).size() <= before, "volontaires transférés depuis l'armée d'origine")
	_assert_consistent(st, "TF outre-mer")


func test_index_rebuilt_after_save_load() -> void:
	var s := _session()
	s.state.register_formation({"id": "idx_extra_unit", "nation": "united_kingdom", "echelon": "unit",
		"unit_type": "infantry", "region": "region_001", "parent": "army_united_kingdom_region_001",
		"soldiers": 3456, "name_fr": "Extra", "supplied": true, "planned_target": "",
		"battle_id": "", "encircled": false, "reserve": false, "status": "test"})
	var path := "user://test_saves/hierarchy_index.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "chargement")
	var st: GameState = loaded["state"]
	_assert_consistent(st, "après chargement")
	runner.check(int(st.soldiers_of("army_france_region_008")) == int(s.state.soldiers_of("army_france_region_008")),
		"effectifs identiques après rechargement")


func test_direct_mutation_detected_by_size_check() -> void:
	var s := _session()
	# Une mutation directe de formations (hors API) change la taille : l'index doit se reconstruire.
	var fid := "idx_direct"
	s.state.formations[fid] = {"id": fid, "nation": "france", "echelon": "unit", "unit_type": "infantry",
		"region": "region_008", "parent": "army_france_region_008", "soldiers": 1000,
		"supplied": true, "planned_target": "", "battle_id": "", "encircled": false, "reserve": false,
		"status": "test"}
	_assert_consistent(s.state, "mutation directe (ajout)")


func test_direct_mutation_of_parent_and_echelon_invalidated() -> void:
	var s := _session()
	var st := s.state
	var a1 := "army_france_region_008"
	var a2 := "army_german_empire_region_035"
	var units: Array = st.units_of(a1).duplicate()
	runner.check(units.size() > 0, "armée source avec unités")
	var moved: String = units[0]
	# Mutation directe du parent, sans passer par set_formation_parent() :
	# l'appelant doit invalider explicitement (coût O(n) par lecture prohibitive).
	st.formations[moved]["parent"] = a2
	st.invalidate_hierarchy()
	_assert_consistent(st, "mutation directe (parent) + invalidate")
	# Mutation directe de l'échelon : units_of() doit cesser de compter cette formation.
	st.formations[moved]["echelon"] = "army"
	st.invalidate_hierarchy()
	_assert_consistent(st, "mutation directe (échelon) + invalidate")
	runner.check(not st.units_of(a1).has(moved), "unité requalifiée retirée de units_of")
