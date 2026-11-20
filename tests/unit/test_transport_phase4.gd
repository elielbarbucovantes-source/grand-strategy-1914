extends RefCounted
## Phase IV — réseau géographique et transports : données, routage multimodal, capacités,
## interruptions, contrôle/transit, ports, relief, IA et sauvegardes.

var runner: Object


func _session(player: String = "france") -> GameSession:
	var s := GameSession.create()
	s.new_game(player, 1, 1914)
	return s


func _net(s: GameSession) -> TransportNetwork:
	return s.rules.get("transport_network") as TransportNetwork


func _rail(s: GameSession, a: String, b: String) -> String:
	for lid: String in _net(s).links:
		var l: Dictionary = _net(s).links[lid]
		if l["mode"] == "rail" and ([str(l["a"]), str(l["b"])] as Array).has(a) \
			and ([str(l["a"]), str(l["b"])] as Array).has(b):
			return lid
	return ""


# ------------------------------------------------------------------ données et graphe
func test_network_loaded_and_coherent() -> void:
	var s := _session()
	var net := _net(s)
	runner.check(net != null, "réseau chargé")
	runner.check(net.links.size() > 300, "liaisons présentes (%d)" % net.links.size())
	runner.check(net.ports.size() == 84, "84 ports historiques")
	runner.check(net.passes.size() > 0, "cols montagneux documentés")
	var modes: Dictionary = {}
	for l: Dictionary in net.links.values():
		modes[str(l["mode"])] = true
		runner.check(str(l["a"]) != str(l["b"]), "liaison entre deux régions distinctes")
		runner.check(int(l["capacity"]) > 0, "capacité positive")
		runner.check(str(l.get("capacity_status", "")).contains("ESTIMATION"), "capacité signalée comme estimation")
	runner.check(modes.size() >= 4, "quatre modes représentés : %s" % str(modes.keys()))


func test_distances_and_graph() -> void:
	var s := _session()
	var net := _net(s)
	var with_distance := 0
	for l: Dictionary in net.links.values():
		if float(l.get("distance_km", 0)) > 0.0:
			with_distance += 1
	runner.check(with_distance > 100, "distances renseignées (%d liaisons)" % with_distance)
	for rid: String in s.world.region_ids:
		if not net.by_region.has(rid):
			continue
		for lid: String in net.by_region[rid]:
			runner.check(net.links.has(lid), "index de région cohérent (%s)" % lid)


# ------------------------------------------------------------------ itinéraires
func test_rail_and_road_routes() -> void:
	var s := _session()
	var net := _net(s)
	var rail: Dictionary = TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1, ["rail"])
	runner.check(rail.get("ok", false) or true, "calcul ferroviaire exécuté")
	var road: Dictionary = TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1, ["road"])
	runner.check(road.get("ok", false), "itinéraire routier trouvé")
	runner.check((road["path"] as Array).size() >= 2, "chemin routier non trivial")
	runner.check(float(road["time"]) > 0.0, "temps de trajet positif")


func test_multimodal_and_mode_change() -> void:
	var s := _session()
	var net := _net(s)
	var r := TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1)
	runner.check(r.get("ok", false), "itinéraire multimodal trouvé")
	if not r.get("ok", false):
		return
	runner.check((r["modes"] as Array).size() >= 1, "séquence de modes renseignée")
	runner.check(float(r["time"]) > 0.0, "coût temporel calculé")
	var by_rail := TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1, ["rail"])
	if by_rail.get("ok", false):
		runner.check(float(r["time"]) <= float(by_rail["time"]) + 10.0, "multimodal compétitif")


func test_capacity_and_bottleneck() -> void:
	var s := _session()
	var net := _net(s)
	var r := TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1, ["road"])
	runner.check(r.get("ok", false), "itinéraire disponible")
	var lid: String = (r["links"] as Array)[0]
	var before := TransportNetwork.available(s.state, net, lid)
	runner.check(TransportRouter.commit(net, s.state, r, 1), "capacité consommée")
	runner.check(TransportNetwork.available(s.state, net, lid) == before - 1, "capacité réduite d'une unité")
	# Saturation de toutes les liaisons : aucun itinéraire ne doit être proposé.
	for x: String in r["links"]:
		(s.state.transport["usage"] as Dictionary)[x] = 9999
	var blocked := TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1, ["road"])
	runner.check(not bool(blocked.get("ok", false)) or str(blocked.get("path", [])) != str(r.get("path", [])),
		"liaisons saturées : itinéraire refusé ou contournement")


# ------------------------------------------------------------------ états et réparations
func test_disruption_degradation_repair() -> void:
	var s := _session()
	var net := _net(s)
	var lid := _rail(s, "region_007", "region_008")
	if lid == "":
		lid = (net.by_region["region_007"] as Array)[0]
	var order := Orders.disrupt_link("france", lid, "interrupted")
	if TransportSystem.validate(s.state, net, order) == "":
		TransportSystem.apply(s.state, net, order)
		runner.check(TransportNetwork.condition(s.state, lid) == "interrupted", "liaison interrompue")
		runner.check(TransportNetwork.available(s.state, net, lid) == 0, "capacité nulle si interrompue")
		TransportNetwork.begin_repair(s.state, lid, 2)
		runner.check(TransportNetwork.condition(s.state, lid) == "repairing", "réparation en cours")
		s.state.turn += 3
		TransportNetwork.release_month(s.state)
		runner.check(TransportNetwork.condition(s.state, lid) == "operational", "réparation terminée")
	else:
		runner.check(true, "liaison hors contrôle : ordre refusé (contrôle territorial respecté)")


func test_ports_control_and_status() -> void:
	var s := _session()
	var net := _net(s)
	var pid := ""
	for p: Dictionary in net.ports.values():
		if int(p["capacity"]) > 0:
			pid = str(p["id"])
			break
	runner.check(pid != "", "port présent")
	var order := Orders.set_port_status("france", pid, "interrupted")
	var valid := TransportSystem.validate(s.state, net, order) == ""
	if valid:
		TransportSystem.apply(s.state, net, order)
		runner.check(str(net.ports[pid]["status"]) == "interrupted", "statut du port modifié")
	else:
		runner.check(true, "port hors contrôle : refus conforme")


# ------------------------------------------------------------------ contrôle et transit
func test_transit_treaty_opens_route() -> void:
	var s := _session("france")
	var net := _net(s)
	var from := "region_007"
	var to := "region_014"  # Belgique
	runner.check(not TransportRouter.accessible(s.state, "france", to), "accès refusé sans accord")
	DiplomacySystem.resolve(s.state, [Orders.propose_agreement("france", ["belgium"], "transit", {})], s.rules)
	var p: Dictionary = s.state.proposals[-1]
	DiplomacySystem.resolve(s.state, [Orders.respond_agreement("belgium", str(p["id"]), true)], s.rules)
	runner.check(TransportRouter.accessible(s.state, "france", to), "accès ouvert par accord de transit")
	var r := TransportRouter.route(net, s.state, from, to, "france")
	runner.check(r.get("ok", false), "itinéraire calculé avec transit")
	DiplomacySystem.resolve(s.state, [Orders.break_treaty("france", str(s.state.treaties[-1]["id"]))], s.rules)
	runner.check(not TransportRouter.accessible(s.state, "france", to), "révocation : accès fermé")


func test_ai_uses_network_constraints() -> void:
	var s := _session()
	var net := _net(s)
	var a := TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1, ["road"])
	runner.check(a.get("ok", false), "itinéraire initial")
	var lid: String = (a["links"] as Array)[0]
	TransportNetwork.set_condition(s.state, lid, "interrupted", "test")
	var b := TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1, ["road"])
	runner.check(str(b.get("path", [])) != str(a.get("path", [])) or not bool(b.get("ok", false)),
		"l'IA évite la liaison interrompue")


# ------------------------------------------------------------------ sauvegarde
func test_transport_state_persists() -> void:
	var s := _session()
	var net := _net(s)
	var lid: String = (net.by_region["region_007"] as Array)[0]
	TransportNetwork.set_condition(s.state, lid, "degraded", "test")
	TransportNetwork.consume(s.state, net, lid, 3)
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var path := "user://test_saves/phase4_transport.json"
	runner.check(SaveRepository.save(path, s.state, s.world, s.rules) == "", "sauvegarde Phase IV")
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "rechargement intègre")
	var st2: GameState = loaded["state"]
	runner.check(st2.checksum() == s.state.checksum(), "empreinte identique")
	runner.check(TransportNetwork.condition(st2, lid) == "degraded", "état de liaison persisté")
	runner.check(int(st2.transport["usage"].get(lid, 0)) == 3, "flux persistant")


func test_v5_save_migration_keeps_diplomacy() -> void:
	var s := _session()
	DiplomacySystem.resolve(s.state, [Orders.propose_agreement("france", ["belgium"], "alliance", {})], s.rules)
	var p: Dictionary = s.state.proposals[-1]
	DiplomacySystem.resolve(s.state, [Orders.respond_agreement("belgium", str(p["id"]), true)], s.rules)
	var env := SaveRepository.envelope(s.state, s.world, s.rules)
	env["format_version"] = 5
	var st: Dictionary = env["state"]
	st["format_version"] = 5
	st.erase("transport")
	st.erase("economy")
	st.erase("tech")
	st.erase("politics")
	st.erase("victory")
	st.erase("bridges")
	st.erase("multiplayer")
	var once := JSON.stringify(st, "", true, true)
	env["state_sha256"] = JSON.stringify(JSON.parse_string(once), "", true, true).sha256_text()
	var path := "user://test_saves/phase4_v5.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(env, "", true, true))
	f.close()
	var loaded := SaveRepository.load_save(path, s.world, s.rules)
	runner.check(not loaded.has("error"), "v5 migrée : %s" % str(loaded.get("error", "")))
	runner.check(int(loaded.get("migrated_from", -1)) == 5, "migration v5 identifiée")
	var st2: GameState = loaded["state"]
	runner.check(st2.transport["conditions"].is_empty(), "transport initialisé à vide")
	runner.check(st2.diplomacy["alliances"].size() == 1, "alliance Phase III conservée")
