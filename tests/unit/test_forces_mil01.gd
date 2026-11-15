extends RefCounted
## MIL-01 : base historique des effectifs, campagne générée, mobilisation progressive, séparation
## stricte entre campagne historique et bac à sable FICTIF.

var runner: Object

const PLAYABLE := ["austria_hungary", "france", "german_empire", "italy", "ottoman_empire", "russian_empire", "united_kingdom"]


func _db() -> Dictionary:
	return GameSession.load_json("res://data/history/military_forces_1914.json")


func _session(player: String = "france", scenario: String = "campaign_1914") -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, 1914, scenario)
	return s


func _units(st: GameState, nation: String) -> Array:
	return st.sorted_formation_ids().filter(func(id: String) -> bool:
		return st.formations[id]["echelon"] == "unit" and st.formations[id]["nation"] == nation)


func _invariant(f: Dictionary) -> int:
	var mob := 0
	for c: Dictionary in f["mobilizing"]:
		mob += int(c["soldiers"])
	return int(f["reserve_pool"]) + mob + int(f["incorporated"])


# ------------------------------------------------------------------ base de données
func test_database_is_sourced_and_complete() -> void:
	var db := _db()
	runner.check(db.get("format", "") == "gs1914.historical_forces", "base historique chargée")
	var nations: Array = (db["nations"] as Dictionary).keys()
	nations.sort()
	runner.check(nations == PLAYABLE, "exactement les sept puissances jouables (liste non modifiée)")
	for nid: String in PLAYABLE:
		var n: Dictionary = db["nations"][nid]
		for cat: String in ["active", "reserves"]:
			var v: Dictionary = n[cat]
			runner.check(v["value"] is float and float(v["value"]) > 0, "%s/%s : valeur présente" % [nid, cat])
			runner.check(db["sources"].has(v["source"]), "%s/%s : source référencée (%s)" % [nid, cat, v["source"]])
			runner.check(str(v.get("definition", "")) != "" and str(v.get("reliability", "")) != "" and v.has("page"),
				"%s/%s : définition, page et fiabilité renseignées" % [nid, cat])
			for d: Dictionary in v.get("divergences", []):
				runner.check(db["sources"].has(d["source"]), "%s/%s : divergence sourcée" % [nid, cat])
		runner.check(float(n["off_map"]["value"]) < float(n["active"]["value"]), "%s : part hors carte inférieure à l'actif" % nid)
		var share: Dictionary = n["reserves"]["on_map_share"]
		runner.check(int(share["numerator"]) <= int(share["denominator"]) and str(share["basis"]) != "", "%s : part des réserves sur la carte justifiée" % nid)
		var count: int = (n["districts"] as Array).size()
		runner.check(count == int(n["districts_count_check"]["expected"]), "%s : %d districts conformes au nombre sourcé" % [nid, count])
	for sid: String in db["sources"]:
		var src: Dictionary = db["sources"][sid]
		runner.check(str(src.get("citation", "")) != "" and src.has("reliability"), "source %s : citation et fiabilité" % sid)
	runner.check(db["nations"]["ottoman_empire"]["arms"] == null, "donnée manquante explicite : ventilation ottomane inconnue (null)")


# ------------------------------------------------------------------ séparation des jeux de données
func test_campaign_and_sandbox_are_separate() -> void:
	var camp := _session()
	var sand := _session("france", "sandbox_fictif")
	runner.check(camp.scenario["forces_source"]["type"] == "historical", "campagne : source d'effectifs historique déclarée")
	runner.check(sand.scenario["forces_source"]["type"] == "fictitious", "bac à sable : source FICTIVE déclarée")
	var db_text := FileAccess.get_file_as_string("res://data/history/military_forces_1914.json")
	runner.check(camp.scenario["forces_source"]["database_sha256"] == db_text.sha256_text(), "campagne générée depuis la version actuelle de la base")
	var fictive_in_campaign := 0
	for fid: String in camp.state.formations:
		if str(camp.state.formations[fid].get("status", "")).contains("FICTIF"):
			fictive_in_campaign += 1
	runner.check(fictive_in_campaign == 0, "aucune formation fictive dans la campagne")
	var historical_in_sandbox := 0
	for fid: String in sand.state.formations:
		var st: String = str(sand.state.formations[fid].get("status", ""))
		if st.contains("HISTORIQUE"):
			historical_in_sandbox += 1
		if sand.state.formations[fid]["echelon"] == "unit":
			runner.check(st.contains("FICTIF"), "bac à sable : unité %s marquée FICTIF" % fid)
	runner.check(historical_in_sandbox == 0, "aucune donnée historique dans le bac à sable")
	runner.check(MobilizationSystem.validate(sand.state, Orders.mobilize("france")) != "", "bac à sable : pas de mobilisation (aucune réserve modélisée)")
	runner.check(camp.state.nations["belgium"]["forces"]["source_type"] == "unknown", "État hors MIL-01 : source inconnue signalée")
	runner.check(MobilizationSystem.validate(camp.state, Orders.mobilize("belgium")).contains("inconnus"), "données insuffisantes signalées, rien n'est fabriqué")


# ------------------------------------------------------------------ actifs, réserves, cohérence
func test_active_and_reserves_are_distinct_and_consistent() -> void:
	var s := _session()
	var st := s.state
	var db := _db()
	for nid: String in PLAYABLE:
		var f: Dictionary = st.nations[nid]["forces"]
		var n: Dictionary = db["nations"][nid]
		runner.check(int(f["active_start"]) == int(n["active"]["value"]), "%s : actif = valeur sourcée" % nid)
		runner.check(int(f["active_on_map"]) + int(f["active_off_map"]) == int(f["active_start"]), "%s : actif = carte + hors carte" % nid)
		runner.check(int(f["reserve_pool_initial"]) + int(f["reserves_off_map"]) == int(f["reserves_total"]), "%s : réserves = carte + hors carte" % nid)
		var sum := MobilizationSystem.summary(st, nid)
		runner.check(int(sum["present_in_units"]) + int(sum["present_services"]) == int(f["active_on_map"]),
			"%s : présents au départ = actifs sur la carte (aucun réserviste incorporé)" % nid)
		runner.check(int(sum["incorporated"]) == 0 and int(sum["mobilizing"]) == 0 and int(sum["reserve_pool"]) == int(f["reserve_pool_initial"]),
			"%s : réserves disponibles, non incorporées au départ" % nid)
		runner.check(not bool(sum["declared"]), "%s : pas de mobilisation au départ" % nid)


func test_territorial_distribution() -> void:
	var s := _session()
	var st := s.state
	for nid: String in PLAYABLE:
		var per_region := {}
		for uid: String in _units(st, nid):
			var u: Dictionary = st.formations[uid]
			runner.check(st.sovereign(u["region"]) == nid, "%s : unité %s sur son territoire" % [nid, uid])
			per_region[u["region"]] = int(per_region.get(u["region"], 0)) + int(u["soldiers"])
		runner.check(per_region.size() >= 1, "%s : forces présentes sur la carte" % nid)
	runner.check(int(st.soldiers_of("army_german_empire_region_035")) > 0, "Alsace-Lorraine : XVe et XVIe corps stationnés")
	runner.check(not st.formations.has("army_german_empire_region_030") or int(st.soldiers_of("army_german_empire_region_030")) < int(st.soldiers_of("army_german_empire_region_033")),
		"répartition par districts de corps, pas uniforme par région")
	var ottoman: Array = _units(st, "ottoman_empire")
	runner.check(ottoman.all(func(id: String) -> bool: return st.formations[id]["region"] == "region_087"), "Empire ottoman : seule la part européenne estimée est sur la carte")
	runner.check(ottoman.all(func(id: String) -> bool: return str(st.formations[id]["status"]).contains("arme INCONNUE")), "arme inconnue signalée sur chaque unité ottomane")
	runner.check(int(st.nations["united_kingdom"]["forces"]["active_off_map"]) == 121123, "Royaume-Uni : garnisons d'Inde et des colonies hors carte (WO 1922)")


# ------------------------------------------------------------------ mobilisation progressive
func test_progressive_mobilization_without_double_counting() -> void:
	var s := _session("france")
	var st := s.state
	var f: Dictionary = st.nations["france"]["forces"]
	var initial := int(f["reserve_pool_initial"])
	var present0 := int(MobilizationSystem.summary(st, "france")["present_in_units"]) + int(MobilizationSystem.summary(st, "france")["present_services"])
	runner.check(s.queue_order(Orders.mobilize("france")) == "", "ordre de mobilisation accepté")
	runner.check(s.queue_order(Orders.mobilize("france")) != "", "un seul ordre de mobilisation par mois")
	s.end_turn()
	var m1 := MobilizationSystem.summary(st, "france")
	runner.check(bool(m1["declared"]), "mobilisation décrétée")
	runner.check(int(m1["mobilizing"]) > 0 and int(m1["reserve_pool"]) < initial, "premier mois : réservistes rappelés")
	runner.check(int(m1["incorporated"]) == 0 and int(m1["present_in_units"]) + int(m1["present_services"]) == present0, "aucune apparition instantanée")
	runner.check(_invariant(f) == initial, "conservation : réservoir + en cours + incorporés = réservoir initial")
	runner.check(MobilizationSystem.validate(st, Orders.mobilize("france")) != "", "mobilisation déjà décrétée : refus")
	s.end_turn()
	var m2 := MobilizationSystem.summary(st, "france")
	runner.check(int(m2["incorporated"]) > 0, "deuxième mois : premiers incorporés")
	runner.check(int(m2["present_in_units"]) + int(m2["present_services"]) == present0 + int(m2["incorporated"]),
		"présents = actifs + incorporés exactement (aucune création sans origine, aucun double comptage)")
	runner.check(_invariant(f) == initial, "conservation après incorporation")
	for i in 4:
		s.end_turn()
		runner.check(_invariant(f) == initial and int(f["reserve_pool"]) >= 0, "conservation au mois %d" % (i + 3))
	runner.check(int(f["reserve_pool"]) == 0, "réservoir épuisé, jamais dépassé")
	var over_cap := 0
	for uid: String in _units(st, "france"):
		var u: Dictionary = st.formations[uid]
		if u.has("war_cap") and int(u["soldiers"]) > int(u["war_cap"]):
			over_cap += 1
	runner.check(over_cap == 0, "aucune unité au-delà de son effectif de guerre")


func test_mobilization_blocked_in_occupied_district() -> void:
	var s := _session("france")
	var st := s.state
	var f: Dictionary = st.nations["france"]["forces"]
	MobilizationSystem.declare(st, "france")
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	var for_011 := 0
	for c: Dictionary in f["mobilizing"]:
		if c["region"] == "region_011":
			for_011 += int(c["soldiers"])
	runner.check(for_011 > 0, "réservistes rappelés pour le district 011")
	st.regions["region_011"]["controller"] = "german_empire"
	st.turn += 1
	MobilizationSystem.monthly(st, s.world, s.rules["forces"])
	var still := 0
	for c: Dictionary in f["mobilizing"]:
		if c["region"] == "region_011":
			still += int(c["soldiers"])
	runner.check(still >= for_011, "district occupé : les rappelés restent en cours de mobilisation, sans incorporation")
	runner.check(_invariant(f) == int(f["reserve_pool_initial"]), "conservation malgré le blocage")
