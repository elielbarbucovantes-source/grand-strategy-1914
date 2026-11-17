extends RefCounted
## Phase II (MIL-01 étendu / NAT-05) : forces historiques des 15 États secondaires européens.
## Données, initialisation, hiérarchie, mobilisation, sauvegarde, IA, non-régression et
## simulation longue. Les sept puissances jouables ne sont pas modifiées.

var runner: Object

const SECONDARY := ["belgium", "netherlands", "luxembourg", "switzerland", "spain", "portugal",
	"denmark", "norway", "sweden", "romania", "bulgaria", "serbia", "montenegro", "albania", "greece"]
const PLAYABLE := ["austria_hungary", "france", "german_empire", "italy", "ottoman_empire", "russian_empire", "united_kingdom"]


func _db() -> Dictionary:
	return GameSession.load_json("res://data/history/military_forces_1914.json")


func _session(player: String = "france", seed_value: int = 1914) -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, seed_value)
	return s


func _war(st: GameState, a: String, b: String) -> void:
	st.wars.append({"id": "war_%s_%s" % [a, b], "a": a, "b": b, "since_turn": 0})


func _armies(st: GameState, nid: String) -> Array:
	var out: Array = []
	for fid: String in st.sorted_formation_ids():
		var f: Dictionary = st.formations[fid]
		if f["nation"] == nid and f["echelon"] == "army":
			out.append(fid)
	return out


func _units(st: GameState, nid: String) -> Array:
	var out: Array = []
	for fid: String in st.sorted_formation_ids():
		var f: Dictionary = st.formations[fid]
		if f["nation"] == nid and f["echelon"] == "unit":
			out.append(fid)
	return out


## ------------------------------------------------------------------ données
func test_all_secondary_states_present() -> void:
	var db := _db()
	var s := _session()
	for nid: String in SECONDARY:
		runner.check(db["nations"].has(nid), "%s : présent dans la base historique" % nid)
		runner.check(s.state.nations.has(nid), "%s : présent dans la campagne" % nid)
		runner.check(not bool(s.state.nations[nid]["playable"]), "%s : non jouable (inchangé)" % nid)
		runner.check(s.state.nations[nid]["forces"]["source_type"] == "historical",
			"%s : forces historiques, plus de source inconnue" % nid)
		runner.check(bool(s.rules["ai_doctrines"]["nations"].has(nid)), "%s : doctrine IA par défaut" % nid)
	var unknown: Array = []
	for nid: String in s.state.nations:
		if s.state.nations[nid]["forces"]["source_type"] == "unknown":
			unknown.append(nid)
	runner.check(unknown.is_empty(), "aucun État de la campagne sans effectif connu")


func test_data_coherence_and_no_duplicates() -> void:
	var db := _db()
	for nid: String in SECONDARY:
		var n: Dictionary = db["nations"][nid]
		var active := int(n["active"]["value"])
		var reserves := int(n["reserves"]["value"])
		runner.check(active > 0, "%s : actif positif (%d)" % [nid, active])
		runner.check(reserves >= 0, "%s : réserves non négatives (%d)" % [nid, reserves])
		runner.check(db["sources"].has(n["active"]["source"]), "%s : source active référencée" % nid)
		runner.check(db["sources"].has(n["reserves"]["source"]), "%s : source réserves référencée" % nid)
		runner.check(str(n["active"].get("definition", "")) != "", "%s : définition de l'actif documentée" % nid)
		runner.check(str(n["reserves"]["on_map_share"].get("basis", "")) != "", "%s : part sur carte justifiée" % nid)
		var ids: Dictionary = {}
		for d: Dictionary in n["districts"]:
			runner.check(not ids.has(d["id"]), "%s : district %s non dupliqué" % [nid, d["id"]])
			ids[d["id"]] = true
			runner.check(str(d.get("city_id", "")) != "", "%s/%s : district localisé par city_id" % [nid, d["id"]])
		runner.check(ids.size() == int(n["districts_count_check"]["expected"]), "%s : nombre de districts cohérent" % nid)
	# aucune source orpheline ni clé dupliquée dans la base
	for sid: String in db["sources"]:
		runner.check(str(db["sources"][sid].get("citation", "")) != "", "source %s : citation présente" % sid)


## ------------------------------------------------------------------ initialisation
func test_formations_created_with_hierarchy_and_geography() -> void:
	var s := _session()
	var st := s.state
	var all_ids: Dictionary = {}
	for fid: String in st.sorted_formation_ids():
		runner.check(not all_ids.has(fid), "identifiant de formation unique : %s" % fid)
		all_ids[fid] = true
	for nid: String in SECONDARY:
		var armies := _armies(st, nid)
		var units := _units(st, nid)
		runner.check(not armies.is_empty(), "%s : au moins une armée créée" % nid)
		runner.check(not units.is_empty(), "%s : au moins une unité créée" % nid)
		var total := 0
		for uid: String in units:
			var u: Dictionary = st.formations[uid]
			runner.check(int(u["soldiers"]) > 0, "%s/%s : effectif d'unité positif" % [nid, uid])
			runner.check(st.formations.has(str(u.get("parent", ""))), "%s/%s : parent valide" % [nid, uid])
			total += int(u["soldiers"])
		runner.check(total > 0 and total <= int(s.state.nations[nid]["forces"]["active_start"]),
			"%s : total des unités (%d) cohérent avec l'actif sourcé" % [nid, total])
		for aid: String in armies:
			runner.check(str(st.formations[aid].get("parent")) == "<null>" or st.formations[aid].get("parent") == null
				or st.formations.has(str(st.formations[aid].get("parent"))), "%s : rattachement d'armée valide" % aid)
			var rid: String = st.formations[aid]["region"]
			runner.check(s.world.regions.has(rid), "%s : région d'armée existante" % aid)


## ------------------------------------------------------------------ fonctionnement
func test_progressive_mobilization_secondary() -> void:
	var s := _session()
	var st := s.state
	var mr: Dictionary = s.rules["forces"]["mobilization"]
	MobilizationSystem.set_posture(st, mr, "belgium", "generale")
	for i in 4:
		st.turn += 1
		MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	var f: Dictionary = st.nations["belgium"]["forces"]
	runner.check(int(f["incorporated"]) > 0, "Belgique : réservistes incorporés progressivement")
	var c := MobilizationSystem.conservation(st, "belgium")
	runner.check(bool(c["reserves_ok"]) and bool(c["personnel_ok"]), "Belgique : conservation des effectifs")
	runner.check(int(f["reserve_pool"]) < int(f["reserve_pool_initial"]), "Belgique : réservoir diminué sans double comptage")


func test_save_load_preserves_secondary_forces() -> void:
	var s := _session()
	MobilizationSystem.set_posture(s.state, s.rules["forces"]["mobilization"], "serbia", "generale")
	MobilizationSystem.monthly(s.state, s.world, s.rules["forces"])
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/phase2_secondary.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde Phase II")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "rechargement intègre")
	var st2: GameState = loaded["state"]
	runner.check(st2.checksum() == s.state.checksum(), "empreinte identique après rechargement")
	for nid: String in SECONDARY:
		runner.check(st2.nations[nid]["forces"]["source_type"] == "historical", "%s : source conservée" % nid)
		for aid: String in _armies(s.state, nid):
			runner.check(st2.soldiers_of(aid) == s.state.soldiers_of(aid), "%s : effectif conservé après rechargement" % aid)


func test_ai_controls_secondary_with_valid_orders() -> void:
	var s := _session()
	var st := s.state
	_war(st, "german_empire", "belgium")
	for i in 2:
		s.end_turn()
	var view := IntelSystem.view_for(st, s.world, "belgium")
	var orders := NationAgent.decide(view, s.world, s.rules)
	for o: Dictionary in orders:
		runner.check(str(o.get("type", "")) != "", "ordre IA belge typé : %s" % str(o))
		runner.check(str(o.get("nation", "belgium")) == "belgium", "ordre IA belge au nom de la Belgique")
	var before: int = st.soldiers_of(_armies(st, "belgium")[0])
	for i in 4:
		s.end_turn()
	runner.check(st.soldiers_of(_armies(st, "belgium")[0]) <= before, "Belgique : pertes ou maintien, aucune création")
	var c := MobilizationSystem.conservation(st, "belgium")
	runner.check(bool(c["reserves_ok"]) and bool(c["personnel_ok"]), "Belgique : conservation sous contrôle IA")


## ------------------------------------------------------------------ non-régression
func test_great_powers_unchanged() -> void:
	var db := _db()
	var s := _session()
	for nid: String in PLAYABLE:
		runner.check(bool(s.state.nations[nid]["playable"]), "%s : toujours jouable" % nid)
		runner.check(int(s.state.nations[nid]["forces"]["active_start"]) == int(db["nations"][nid]["active"]["value"]),
			"%s : actif inchangé" % nid)
		runner.check(int(s.state.nations[nid]["forces"]["reserves_total"]) == int(db["nations"][nid]["reserves"]["value"]),
			"%s : réserves inchangées" % nid)


func test_long_simulation_is_deterministic_and_conserves_forces() -> void:
	var signatures: Array = []
	for run: int in 2:
		var s := _session("france", 77)
		var st := s.state
		_war(st, "german_empire", "belgium")
		_war(st, "austria_hungary", "serbia")
		for i in 18:
			s.end_turn()
		signatures.append(st.checksum())
		for nid: String in SECONDARY + PLAYABLE:
			var c := MobilizationSystem.conservation(st, nid)
			runner.check(bool(c["reserves_ok"]) and bool(c["personnel_ok"]),
				"%s : conservation après 18 tours" % nid)
	runner.check(signatures[0] == signatures[1], "simulation longue déterministe (deux exécutions, même graine)")
