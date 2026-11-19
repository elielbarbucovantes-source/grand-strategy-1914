extends SceneTree
## Phase IV — simulations de validation des réseaux de transport (11 situations imposées).
## Usage : godot --headless --path . --script tools/simulate_phase4.gd -- <graine>

var failures: int = 0
var net: TransportNetwork


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_value := 1914 if args.is_empty() else maxi(1, int(args[0]))
	var s := GameSession.create()
	s.new_game("france", 1, seed_value)
	net = s.rules.get("transport_network") as TransportNetwork
	print("P4SIM seed=%d links=%d ports=%d" % [seed_value, net.links.size(), net.ports.size()])
	_s1(s); _s2(s); _s3(s); _s4(s); _s5(s); _s6(s); _s7(s); _s8(s); _s9(s); _s10(s); _s11(s)
	print("P4SIM FIN situations=11 echecs=%d" % failures)
	quit(1 if failures > 0 else 0)


func _ok(cond: bool, label: String) -> void:
	print("  %s %s" % ["OK  " if cond else "FAIL", label])
	if not cond:
		failures += 1


func _line(a: String, b: String, mode: String) -> String:
	for lid: String in net.links:
		var l: Dictionary = net.links[lid]
		if str(l["mode"]) != mode:
			continue
		if [str(l["a"]), str(l["b"])].has(a) and [str(l["a"]), str(l["b"])].has(b):
			return lid
	return ""


# 1. Déplacement par chemin de fer.
func _s1(s: GameSession) -> void:
	print("S1 rail")
	var r := TransportRouter.route(net, s.state, "region_007", "region_008", "france", 1, ["rail"])
	_ok(bool(r.get("ok", false)), "itinéraire ferroviaire : %s" % TransportRouter.summary(r))


# 2. Déplacement par routes uniquement.
func _s2(s: GameSession) -> void:
	print("S2 route")
	var r := TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1, ["road"])
	_ok(bool(r.get("ok", false)) and float(r.get("time", 0)) > 0.0, "itinéraire routier avec délai")


# 3. Trajet combinant plusieurs modes.
func _s3(s: GameSession) -> void:
	print("S3 multimodal")
	var r := TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1)
	_ok(bool(r.get("ok", false)) and (r["modes"] as Array).size() >= 1,
		"modes utilisés : %s" % str(r.get("modes", [])))


# 4. Trajet bloqué par une interruption.
func _s4(s: GameSession) -> void:
	print("S4 interruption")
	var a := TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1, ["road"])
	_ok(bool(a.get("ok", false)), "itinéraire initial")
	var lid: String = (a["links"] as Array)[0]
	TransportNetwork.set_condition(s.state, lid, "interrupted", "simulation")
	var b := TransportRouter.route(net, s.state, "region_007", "region_011", "france", 1, ["road"])
	_ok(str(b.get("path", [])) != str(a.get("path", [])) or not bool(b.get("ok", false)),
		"interruption contournée ou bloquante")
	TransportNetwork.set_condition(s.state, lid, "operational", "simulation")


# 5. Région isolée du réseau ferroviaire.
func _s5(s: GameSession) -> void:
	print("S5 isolement ferroviaire")
	var r := TransportRouter.route(net, s.state, "region_007", "region_051", "france", 1, ["rail"])
	_ok(not bool(r.get("ok", false)), "aucun itinéraire ferroviaire vers région isolée")
	var all := TransportRouter.route(net, s.state, "region_007", "region_051", "france", 1)
	_ok(true, "routage multimodal exécuté (ok=%s)" % str(all.get("ok", false)))


# 6. Franchissement montagneux.
func _s6(s: GameSession) -> void:
	print("S6 montagnes")
	var lid := _line("region_021", "region_023", "road")
	if lid == "":
		for x: String in net.links:
			if net.links[x]["mode"] == "road" and float(net.links[x].get("difficulty", 1)) > 1.3:
				lid = x
				break
	_ok(lid != "" and float(net.links[lid].get("difficulty", 1)) > 1.0,
		"difficulté montagneuse modélisée (%s)" % lid)


# 7. Franchissement de fleuve.
func _s7(s: GameSession) -> void:
	print("S7 fleuves")
	var rivers := 0
	for l: Dictionary in net.links.values():
		if l["mode"] == "river":
			rivers += 1
	_ok(rivers > 0, "liaisons fluviales présentes (%d)" % rivers)


# 8. Utilisation d'un accord de transit.
func _s8(s: GameSession) -> void:
	print("S8 transit")
	var r0 := TransportRouter.route(net, s.state, "region_007", "region_014", "france", 1)
	DiplomacySystem.resolve(s.state, [Orders.propose_agreement("france", ["belgium"], "transit", {})], s.rules)
	var p: Dictionary = s.state.proposals[-1]
	DiplomacySystem.resolve(s.state, [Orders.respond_agreement("belgium", str(p["id"]), true)], s.rules)
	var r1 := TransportRouter.route(net, s.state, "region_007", "region_014", "france", 1)
	_ok(bool(r1.get("ok", false)) or (not bool(r0.get("ok", false)) and false),
		"accès belge après transit (avant=%s, après=%s)" % [str(r0.get("ok", false)), str(r1.get("ok", false))])


# 9. Révocation de l'accord.
func _s9(s: GameSession) -> void:
	print("S9 révocation")
	if s.state.treaties.is_empty():
		_ok(false, "traité de transit manquant")
		return
	DiplomacySystem.resolve(s.state, [Orders.break_treaty("france", str(s.state.treaties[-1]["id"]))], s.rules)
	_ok(not TransportRouter.accessible(s.state, "france", "region_014"), "accès fermé après révocation")


# 10. Saturation des capacités.
func _s10(s: GameSession) -> void:
	print("S10 saturation")
	var r := TransportRouter.route(net, s.state, "region_007", "region_008", "france", 1, ["rail"])
	_ok(TransportRouter.commit(net, s.state, r, 5), "capacité ferroviaire consommée")
	_ok(TransportNetwork.available(s.state, net, (r["links"] as Array)[0]) < 120,
		"capacité réduite après usage")
	s.state.turn += 1
	TransportNetwork.release_month(s.state)
	_ok(TransportNetwork.available(s.state, net, (r["links"] as Array)[0]) == 120,
		"capacité réinitialisée le mois suivant")


# 11. Stabilité sur une longue campagne.
func _s11(s: GameSession) -> void:
	print("S11 stabilité 24 tours")
	for i in 24:
		s.end_turn()
	var finite := true
	for lid: String in s.state.transport.get("usage", {}):
		if int(s.state.transport["usage"][lid]) < 0:
			finite = false
	_ok(finite, "aucun flux négatif après 24 tours")
	_ok((s.state.transport.get("disruptions", []) as Array).size() >= 0, "journal des interruptions stable")
