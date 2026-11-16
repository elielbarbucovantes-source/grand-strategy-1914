class_name BattleManager
extends RefCounted
## Intégration stratégique du combat : création, file, avance, clôture et conséquences.
## - Les effectifs engagés sont ceux des unités réellement présentes (armées de la région).
## - Une unité engagée ou réservée comme renfort est verrouillée (`battle_id`) : elle ne peut
##   ni se déplacer sur la carte stratégique, ni participer à une autre bataille.
## - Toutes les batailles sont closes avant le tour suivant (T-029 A) ; GameSession refuse la
##   fin de mois tant qu'une bataille est active.


# ------------------------------------------------------------------ création
## Crée une bataille tactique à partir d'un affrontement {region, attackers[], defenders[] (armées), origin}.
## Retourne {} si la bataille n'est pas simulable (effectifs inconnus : campagne, MIL-01).
static func create(state: GameState, world: WorldMap, rules: Dictionary, cr: Dictionary, clash: Dictionary) -> Dictionary:
	var rid: String = clash["region"]
	for army: String in clash["attackers"] + clash["defenders"]:
		if state.soldiers_of(army) == null:
			return {}
	var bid := state.new_id("battle")
	var field := Battlefield.build(world, rid, cr)
	var b := {
		"id": bid, "region": rid, "turn": state.turn, "date": state.date_label(), "created_seq": state.next_id,
		"status": "active", "tick": 0, "max_ticks": 0, "field": field, "objectives": field["objectives"],
		"units": {}, "sides": {}, "fog": {"attackers": {}, "defenders": {}}, "visible": {"attackers": {}, "defenders": {}},
		"defenses": _region_defenses(state, rid).duplicate(true), "army_morale": {}, "log": [], "origin": clash["origin"],
		"paused": false, "pause_votes": {}, "controllers": {}, "humans": [], "disconnected": {},
		"disconnect_pause": false, "multiplayer": state.human_nations.size() > 1,
	}
	field.erase("objectives")
	var by_side := {CombatData.ATTACKERS: clash["attackers"], CombatData.DEFENDERS: clash["defenders"]}
	for side: String in CombatData.SIDES:
		var nations: Array = []
		for army: String in by_side[side]:
			var n: String = state.formations[army]["nation"]
			if not nations.has(n):
				nations.append(n)
		nations.sort()
		var source := _side_source(state, world, side, rid, by_side[side], clash["origin"])
		var entry := Battlefield.entry_point(world, field, source)
		b["sides"][side] = {"nations": nations, "armies": (by_side[side] as Array).duplicate(), "entry": CombatData.a(entry),
			"source_region": source, "commander": {}, "primary_objective": "", "start_soldiers": {}}
	for side: String in CombatData.SIDES:
		var i := 0
		for army: String in by_side[side]:
			_ensure_army_morale(state, cr, army)
			b["army_morale"][army] = float(state.formations[army]["morale"])
			for uid: String in state.units_of(army):
				var su: Dictionary = state.formations[uid]
				if su.get("battle_id", "") != "":
					continue  # déjà engagée ou réservée ailleurs : jamais comptée deux fois
				var u := _tactical_unit(state, b, cr, su, side, army)
				var deploy := _deploy_point(b, side, i)
				u["pos"] = CombatData.a(deploy)
				u["status"] = CombatData.RESERVE if su.get("reserve", false) else CombatData.ACTIVE
				b["units"][uid] = u
				su["battle_id"] = bid
				i += 1
	for side: String in CombatData.SIDES:
		var any := false
		for uid: String in b["units"]:
			if b["units"][uid]["side"] == side:
				any = true
		if not any:
			for uid: String in b["units"]:
				state.formations[uid]["battle_id"] = ""
			return {}  # un camp n'a aucune unité disponible : pas de bataille tactique
	_add_reinforcement_candidates(state, world, cr, b)
	for side: String in CombatData.SIDES:
		var per_nation: Dictionary = {}
		for uid: String in b["units"]:
			var u: Dictionary = b["units"][uid]
			if u["side"] == side and u["status"] != CombatData.AVAILABLE:
				per_nation[u["nation"]] = int(per_nation.get(u["nation"], 0)) + int(u["soldiers"])
		b["sides"][side]["start_soldiers"] = per_nation
		b["sides"][side]["commander"] = commander(state, cr, per_nation)
	# Type d'engagement (phase 6, étape 2 ; T-048, T-055) : choix des deux camps et circonstances.
	var encircled := false
	for army: String in clash["defenders"]:
		encircled = encircled or bool(state.formations[army].get("encircled", false))
	Engagement.setup(b, cr, {"approach": Engagement.side_approach(state, clash["attackers"], clash.get("approach", {})),
		"posture": Engagement.side_posture(state, clash["defenders"]), "encircled": encircled,
		"attacker_morale": _side_army_morale(b, CombatData.ATTACKERS), "defender_morale": _side_army_morale(b, CombatData.DEFENDERS)})
	Engagement.apply_commitment(b, cr)
	b["max_ticks"] = max_ticks(b, cr)
	var participants: Array = b["sides"]["attackers"]["nations"] + b["sides"]["defenders"]["nations"]
	for n: String in participants:
		var human: bool = state.human_nations.has(n)
		b["controllers"][n] = "human" if human else "ai"
		if human:
			(b["humans"] as Array).append(n)
	var pr := priority(state, cr, b)
	b["priority_score"] = pr
	b["critical"] = pr >= float(cr["priority"]["critical_score"])
	TacticalSim.update_fog(b, cr)
	return b


static func _side_army_morale(b: Dictionary, side: String) -> float:
	var total := 0.0
	var n := 0
	for army: String in b["sides"][side]["armies"]:
		total += float(b["army_morale"].get(army, 70.0))
		n += 1
	return 70.0 if n == 0 else total / float(n)


static func _region_defenses(state: GameState, rid: String) -> Dictionary:
	var r: Dictionary = state.regions[rid]
	if not r.has("defenses"):
		r["defenses"] = {"trenches": [], "installations": []}
	return r["defenses"]


static func _ensure_army_morale(state: GameState, cr: Dictionary, army: String) -> void:
	if state.formations[army].get("morale") == null:
		state.formations[army]["morale"] = float(cr["morale"]["army_default"])


static func _tactical_unit(state: GameState, b: Dictionary, cr: Dictionary, su: Dictionary, side: String, army: String) -> Dictionary:
	var morale: Variant = su.get("morale")
	if morale == null:
		morale = float(state.formations[army]["morale"])
	var kind: String = su.get("unit_type", "infantry")
	var formation := "entrenched" if side == CombatData.DEFENDERS else "assault_column"
	if kind == "artillery":
		formation = "skirmish_line"
	return {"id": su["id"], "army": army, "nation": su["nation"], "side": side, "type": kind, "name_fr": su["name_fr"],
		"soldiers": int(su["soldiers"]), "start_soldiers": int(su["soldiers"]), "morale": float(morale),
		"lightly_wounded": mini(int(su.get("lightly_wounded", 0)), int(su["soldiers"])), "front_share": 0.0, "front_status": "",
		"formation": formation, "pos": [0, 0], "dest": null, "order": "hold", "target": "", "build": "",
		"status": CombatData.ACTIVE, "arrive_tick": 0, "entry": (b["sides"][side]["entry"] as Array).duplicate(),
		"retreat_point": (b["sides"][side]["entry"] as Array).duplicate(), "last_fire_tick": -999, "quiet_ticks": 0,
		"engaged_ticks": 0, "loss_carry": 0.0, "charge_ticks": 0, "reinforcement": false, "source_region": su["region"], "eta_ticks": 0}


## Région d'où vient un camp : origine des attaquants ; pour le défenseur, voisin ami vers sa capitale.
static func _side_source(state: GameState, world: WorldMap, side: String, rid: String, armies: Array, origin: Dictionary) -> String:
	if side == CombatData.ATTACKERS:
		for army: String in armies:
			if origin.has(army) and origin[army] != rid:
				return origin[army]
	var nation: String = state.formations[armies[0]]["nation"]
	var capital: String = state.nations[nation]["capital_region_id"]
	var path := world.shortest_path(rid, capital)
	return path[1] if path.size() > 1 else ""


static func _deploy_point(b: Dictionary, side: String, index: int) -> Vector2:
	var entry := CombatData.v(b["sides"][side]["entry"])
	var center := Vector2(float(b["field"]["w"]), float(b["field"]["h"])) / 2.0
	var anchor: Vector2
	if side == CombatData.DEFENDERS:
		var obj: Dictionary = b["objectives"][index % (b["objectives"] as Array).size()]
		anchor = CombatData.v(obj["pos"]).lerp(entry, 0.15)
	else:
		anchor = entry.lerp(center, 0.12)
	var dir := (center - entry).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var perp := dir.orthogonal()
	var lateral := float((index % 7) - 3) * 70.0
	var depth := float(index / 7) * 60.0
	return anchor + perp * lateral - dir * depth


## Renforts possibles (T-040 A) : unités d'armées alliées dans les régions voisines, non engagées
## ailleurs, non encerclées. Délai : base + distance / vitesse (terrain ; liaison terrestre plus
## rapide qu'un détroit). Elles sont verrouillées pour cette bataille (pas de double emploi).
## Au plus `max_reinforcement_units_per_side` candidates par camp, les plus rapides d'abord (ordre
## stable) : à l'échelle de la campagne historique, verrouiller toutes les unités voisines
## immobiliserait des armées entières et ralentirait la simulation.
static func _add_reinforcement_candidates(state: GameState, world: WorldMap, cr: Dictionary, b: Dictionary) -> void:
	var rid: String = b["region"]
	var rc: Dictionary = cr["reinforcements"]
	for side: String in CombatData.SIDES:
		var candidates: Array = []  # [eta, uid, army, neighbor]
		var nations: Array = b["sides"][side]["nations"]
		for neighbor: String in world.neighbor_ids(rid, true):
			for army: Dictionary in state.armies_in(neighbor):
				var n: String = army["nation"]
				var friendly := nations.has(n)
				if not friendly:
					for own: String in nations:
						if not state.active_treaties_between(own, n, "alliance").is_empty():
							friendly = true
				if not friendly or army.get("encircled", false):
					continue
				var distance_km := world.label_point(rid).distance_to(world.label_point(neighbor))
				var terrain := Battlefield.terrain_profile(world.regions[neighbor]["relief_categories"], cr)
				var kmpm := float(rc["km_per_minute_road"]) * float(terrain["speed"])
				if world.has_rail_link(rid, neighbor):
					kmpm *= float(rc["rail_speed_mult"])  # axe ferroviaire attesté (infrastructure.json)
				if world.connection_kind(rid, neighbor) == "strait":
					kmpm *= 0.5  # traversée d'un détroit
				var minutes := float(rc["base_delay_minutes"]) + distance_km / maxf(kmpm, 0.1)
				var eta := int(ceil(minutes * 60.0 / float(cr["tick_seconds"])))
				for uid: String in state.units_of(army["id"]):
					var su: Dictionary = state.formations[uid]
					if su.get("battle_id", "") != "" or su.get("soldiers") == null:
						continue
					candidates.append([eta, uid, army["id"], neighbor])
		candidates.sort()
		for c: Array in candidates.slice(0, int(rc["max_reinforcement_units_per_side"])):
			var uid: String = c[1]
			var army_id: String = c[2]
			var su: Dictionary = state.formations[uid]
			if su.get("battle_id", "") != "":
				continue
			_ensure_army_morale(state, cr, army_id)
			b["army_morale"][army_id] = float(state.formations[army_id]["morale"])
			var u := _tactical_unit(state, b, cr, su, side, army_id)
			u["status"] = CombatData.AVAILABLE
			u["reinforcement"] = true
			u["eta_ticks"] = int(c[0])
			u["formation"] = "assault_column"
			u["entry"] = CombatData.a(Battlefield.entry_point(world, b["field"], c[3]))
			u["pos"] = (u["entry"] as Array).duplicate()
			b["units"][uid] = u
			su["battle_id"] = b["id"]


## Commandant général (T-029 G) : plus de soldats au début ; égalité → prestige militaire le plus
## élevé ; égalité ou prestige inconnu → départage déterministe PROPOSÉ (identifiant croissant).
static func commander(state: GameState, cr: Dictionary, soldiers_by_nation: Dictionary) -> Dictionary:
	var nations := soldiers_by_nation.keys()
	if nations.is_empty():
		return {"nation": null, "basis": "aucune force engagée"}
	nations.sort()
	if nations.size() == 1:
		return {"nation": nations[0], "basis": "seul pays engagé"}
	var best: Array = []
	var top := -1
	for n: String in nations:
		var s := int(soldiers_by_nation[n])
		if s > top:
			top = s
			best = [n]
		elif s == top:
			best.append(n)
	if best.size() == 1:
		return {"nation": best[0], "basis": "plus grand nombre de soldats au début (%d)" % top}
	var by_prestige: Array = []
	var top_p := -INF
	for n: String in best:
		var p: Variant = state.nations[n].get("military_prestige")
		var pv := -INF if p == null else float(p)
		if pv > top_p:
			top_p = pv
			by_prestige = [n]
		elif pv == top_p:
			by_prestige.append(n)
	if by_prestige.size() == 1 and top_p > -INF:
		return {"nation": by_prestige[0], "basis": "égalité d'effectifs ; prestige militaire le plus élevé"}
	by_prestige.sort()
	return {"nation": by_prestige[0], "basis": "égalité d'effectifs et de prestige : départage déterministe (%s)" % cr["joint_command"]["final_tiebreak"]}


## Durée maximale (T-036) : effectifs, terrain, complexité ; bornée ; pas de prolongation.
static func max_ticks(b: Dictionary, cr: Dictionary) -> int:
	var d: Dictionary = cr["duration"]
	var soldiers := 0
	for uid: String in b["units"]:
		if b["units"][uid]["status"] != CombatData.AVAILABLE:
			soldiers += int(b["units"][uid]["soldiers"])
	var minutes := float(d["base_minutes"]) + float(soldiers) / 10000.0 * float(d["per_10000_soldiers_minutes"])
	var terrain := 0.0
	for r: String in b["field"]["relief"]:
		terrain = maxf(terrain, float(d["terrain_minutes"].get(r, 0.0)))
	minutes += terrain
	var n_nations: int = (b["sides"]["attackers"]["nations"] as Array).size() + (b["sides"]["defenders"]["nations"] as Array).size()
	minutes += maxf(0.0, float(n_nations - 2)) * float(d["per_extra_nation_minutes"])
	minutes += float((b["objectives"] as Array).size()) * float(d["per_objective_minutes"])
	minutes = clampf(minutes, float(d["min_minutes"]), float(d["max_minutes"]))
	minutes = minf(minutes, Engagement.max_minutes(b, cr))  # plafond du type d'engagement (étape 2)
	b["max_minutes"] = snappedf(minutes, 0.1)
	return int(ceil(minutes * 60.0 / float(cr["tick_seconds"])))


## Priorité (T-029 D) : critères configurables ; critique si le score atteint le seuil.
static func priority(state: GameState, cr: Dictionary, b: Dictionary) -> float:
	var c: Dictionary = cr["priority"]["criteria"]
	var score := 0.0
	for nid: String in state.nation_order:
		if state.nations[nid]["capital_region_id"] == b["region"]:
			score += float(c["capital_region"])
	if not (b["humans"] as Array).is_empty():
		score += float(c["human_participant"])
	var soldiers := 0
	for uid: String in b["units"]:
		soldiers += int(b["units"][uid]["start_soldiers"])
	score += float(soldiers) / 10000.0 * float(c["per_10000_soldiers"])
	for side: String in CombatData.SIDES:
		for army: String in b["sides"][side]["armies"]:
			if state.formations.has(army) and state.formations[army].get("encircled", false):
				score += float(c["encircled_units"])
	return score


## File (T-029 B/D) : batailles critiques d'abord, puis ordre chronologique.
static func queue(state: GameState) -> Array:
	var q := state.active_battles.duplicate()
	q.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		if bool(x["critical"]) != bool(y["critical"]):
			return bool(x["critical"])
		return int(x["created_seq"]) < int(y["created_seq"]))
	return q


## Bataille que ce joueur doit commander maintenant (une seule à la fois).
static func next_for(state: GameState, nation: String) -> Dictionary:
	for b: Dictionary in queue(state):
		if (b["humans"] as Array).has(nation):
			return b
	return {}


# ------------------------------------------------------------------ déroulement
## Avance une bataille : IA pour les pays non humains (ou tous si `auto_all`), puis simulation.
## Une pause volontaire (T-029 I) ou une pause de déconnexion en solo (T-046) arrête le temps.
static func advance(b: Dictionary, cr: Dictionary, ticks: int, auto_all: bool = false) -> void:
	var every := int(cr["ai"]["decision_ticks"])
	for i in ticks:
		if b["status"] != "active":
			return
		if (bool(b["paused"]) or bool(b.get("disconnect_pause", false))) and not auto_all:
			return
		if int(b["tick"]) % every == 0:
			var nations: Array = b["sides"]["attackers"]["nations"] + b["sides"]["defenders"]["nations"]
			for n: String in nations:
				if auto_all or _ai_controls(b, cr, n):
					TacticalAI.decide(b, cr, n)
		TacticalSim.step(b, cr, 1)
		_grace_expiry(b, cr)


## Contrôleurs (T-046) : "human" (connecté), "disconnected" (délai de grâce : ses unités gardent
## leurs ordres, personne ne les commande), "ai_takeover" (IA après le délai), "ai" (pays IA).
static func _ai_controls(b: Dictionary, cr: Dictionary, nation: String) -> bool:
	var c: String = b["controllers"].get(nation, "ai")
	return c == "ai" or c == "ai_takeover"


## Fin du délai de grâce en multijoueur : l'IA prend le contrôle des unités du joueur absent.
static func _grace_expiry(b: Dictionary, cr: Dictionary) -> void:
	var grace := int(cr["disconnection"]["grace_ticks"])
	for nation: String in b["controllers"]:
		if b["controllers"][nation] == "disconnected" and bool(b.get("multiplayer", false)) \
				and int(b["tick"]) - int(b["disconnected"].get(nation, 0)) >= grace:
			b["controllers"][nation] = "ai_takeover"
			_log_event(b, "%s : délai de grâce écoulé, l'IA prend le contrôle de ses unités." % nation)


static func run_to_end(b: Dictionary, cr: Dictionary, auto_all: bool = true) -> void:
	b["paused"] = false
	while b["status"] == "active":
		advance(b, cr, 50, auto_all)


## Votants d'une pause : humains participants ACTUELLEMENT connectés (l'IA, y compris l'IA qui
## remplace un joueur déconnecté, ne vote pas).
static func voters(b: Dictionary) -> Array:
	return (b["humans"] as Array).filter(func(n: String) -> bool: return b["controllers"].get(n, "") == "human")


## Pause (T-029 I) : solo, accord du seul humain ; multijoueur, unanimité des humains participants
## connectés ; l'IA ne vote pas. Une demande de reprise d'un humain lève la pause.
static func request_pause(b: Dictionary, nation: String, wants_pause: bool) -> bool:
	if not voters(b).has(nation):
		return bool(b["paused"])  # l'IA, les absents et les non-participants ne votent pas
	b["pause_votes"][nation] = wants_pause
	if not wants_pause:
		b["paused"] = false
		b["pause_votes"] = {}
		return false
	b["paused"] = BattleSystem.pause_allowed(voters(b), b["pause_votes"])
	return bool(b["paused"])


## Déconnexion d'un joueur humain pendant une bataille (T-046, VALIDÉ).
## - Solo : la bataille est mise en pause jusqu'au retour du joueur.
## - Multijoueur : délai de grâce (`disconnection.grace_ticks`, configurable) pendant lequel ses
##   unités CONSERVENT leurs ordres ; à son expiration, l'IA prend le contrôle (vue filtrée par le
##   brouillard de son camp, comme toute IA tactique). Les autres joueurs continuent ; une pause
##   volontaire reste soumise à l'unanimité des humains encore connectés.
## Aucune unité n'est retirée, dupliquée ou modifiée par la déconnexion elle-même.
static func on_disconnect(b: Dictionary, cr: Dictionary, nation: String) -> void:
	if not (b["humans"] as Array).has(nation) or b["controllers"].get(nation, "") != "human":
		return
	b["controllers"][nation] = "disconnected"
	b["disconnected"][nation] = int(b["tick"])
	(b["pause_votes"] as Dictionary).erase(nation)
	if not bool(b.get("multiplayer", false)):
		b["disconnect_pause"] = true
		_log_event(b, "%s : joueur déconnecté, bataille en pause jusqu'à son retour (solo)." % nation)
		return
	var remaining := voters(b)
	if bool(b["paused"]):
		b["paused"] = not remaining.is_empty() and BattleSystem.pause_allowed(remaining, b["pause_votes"])
	_log_event(b, "%s : joueur déconnecté, délai de grâce de %d pas avant reprise par l'IA." % [nation, int(cr["disconnection"]["grace_ticks"])])


## Reconnexion (T-046) : le joueur reprend ses unités dans l'état où elles sont, avec les ordres en
## cours (les siens pendant le délai de grâce, ceux de l'IA ensuite) ; en solo, la pause est levée.
static func on_reconnect(b: Dictionary, nation: String) -> void:
	if not (b["humans"] as Array).has(nation):
		return
	var c: String = b["controllers"].get(nation, "")
	if c != "disconnected" and c != "ai_takeover":
		return
	b["controllers"][nation] = "human"
	(b["disconnected"] as Dictionary).erase(nation)
	if not bool(b.get("multiplayer", false)):
		b["disconnect_pause"] = false
	_log_event(b, "%s : joueur reconnecté, contrôle de ses unités restitué." % nation)


static func _log_event(b: Dictionary, text: String) -> void:
	(b["log"] as Array).append({"tick": int(b["tick"]), "text": text, "side": ""})


# ------------------------------------------------------------------ clôture et conséquences
static func finish(state: GameState, world: WorldMap, cr: Dictionary, b: Dictionary) -> Dictionary:
	if b["status"] == "active":
		b["status"] = "ended"
		b["end_reason"] = "résolution forcée"
	Engagement.finalize(b, cr)
	var result := BattleResult.compute(b, cr)
	var rid: String = b["region"]
	# Reconnaissance en force : la région n'est prise que si la défense s'est effondrée ; sinon
	# l'attaquant se retire avec son renseignement (issue indécise, aucune capture).
	if Engagement.active(b) and bool(Engagement.side_param(b, cr, CombatData.ATTACKERS, "occupy_only_if_broken", false)) \
			and result["winner"] == CombatData.ATTACKERS and not TacticalSim._side_broken(b, CombatData.DEFENDERS):
		result["winner"] = ""
		result["decisive"] = false
		result["holder"] = CombatData.DEFENDERS
		result["end_reason"] = str(result["end_reason"]) + " ; reconnaissance achevée, l'attaquant se retire"
	if Engagement.active(b):
		result["engagement"] = {"type": b["engagement"]["realized"], "label_fr": Engagement.label(cr, b["engagement"]["realized"]),
			"planned": b["engagement"]["planned"], "approach": b["engagement"]["approach"], "posture": b["engagement"]["posture"]}
		if b["engagement"]["approach"] == "reconnaissance":
			_record_reconnaissance(state, b)
	b["result"] = result
	b["status"] = "finished"
	var winner: String = result["winner"]
	var loser := CombatData.other(winner) if winner != "" else CombatData.ATTACKERS
	# 1. Pertes persistantes et moral des unités ; unités détruites retirées ; verrous levés.
	# Comptabilité (phase 6, étape 1) : la perte d'effectif de chaque unité, inchangée, est VENTILÉE
	# en tués, blessés, disparus et prisonniers ; aucun soldat n'est créé ni perdu.
	var destroyed: Array = []
	var outcomes := _side_outcomes(state, world, cr, b, winner, rid)
	var booked := {}
	for side: String in CombatData.SIDES:
		booked[side] = {}
		for k: String in ["killed", "wounded", "remained", "missing", "prisoners", "origin_fire", "origin_routing", "origin_remnant", "routing_as_ordinary"]:
			booked[side][k] = 0
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if not state.formations.has(uid):
			continue
		var su: Dictionary = state.formations[uid]
		su["battle_id"] = ""
		if u["status"] == CombatData.AVAILABLE:
			continue
		var remained := 0
		if su.get("soldiers") != null:
			var delta := int(su["soldiers"]) - int(u["soldiers"])
			# Origine tactique (instrumentation du simulateur) ; bornée par la perte réelle d'effectif.
			var remnant := clampi(int(u.get("loss_remnant", 0)), 0, maxi(0, delta))
			var routing := clampi(int(u.get("loss_routing", 0)), 0, maxi(0, delta - remnant))
			var side: String = u["side"]
			var captor := _captor(b, CombatData.other(side))
			var r := ForceLedger.book_battle_losses(state, su["nation"], captor, delta - routing - remnant, routing, remnant,
				outcomes.get(state.army_of(uid), "indecisive"), u["status"] != CombatData.DESTROYED, su.get("region", rid))
			remained = int(r["remained"])
			for k: String in r:
				booked[side][k] = int(booked[side][k]) + int(r[k])
		su["soldiers"] = int(u["soldiers"]) + remained  # blessés légers restés dans leur unité (présents)
		# Étape 2 : ces blessés légers réduisent la capacité opérationnelle jusqu'à leur guérison.
		su["lightly_wounded"] = mini(int(su["soldiers"]), int(u.get("lightly_wounded", 0)) + remained)
		if remained > 0:
			su["lightly_wounded_turn"] = state.turn
		su["morale"] = snappedf(float(u["morale"]), 0.1)
		if u["status"] == CombatData.DESTROYED:
			destroyed.append(uid)
	for uid: String in destroyed:
		state.remove_formation(uid)
	# 2. Moral des armées.
	var m: Dictionary = cr["morale"]
	for side: String in CombatData.SIDES:
		for army: String in b["sides"][side]["armies"]:
			if not state.formations.has(army):
				continue
			if winner == side:
				state.formations[army]["morale"] = minf(float(m["max"]), float(state.formations[army]["morale"]) + float(m["victory_army_bonus"]))
			elif winner == CombatData.other(side):
				state.formations[army]["morale"] = maxf(0.0, float(state.formations[army]["morale"]) - float(m["defeat_army_penalty"]))
	# 3. Contrôle territorial.
	if winner == CombatData.ATTACKERS:
		var occupant: Variant = b["sides"]["attackers"]["commander"]["nation"]
		if occupant == null:
			occupant = b["sides"]["attackers"]["nations"][0]
		var previous := state.controller(rid)
		state.regions[rid]["controller"] = occupant
		state.log_event("occupation", "%s prend le contrôle de %s après la bataille (souveraineté : %s)." % [
			state.nations[occupant]["name_fr"], world.regions[rid]["name_fr"], state.nations[state.sovereign(rid)]["name_fr"]],
			[occupant, previous])
		state.remember(previous, occupant, "region_lost", rid)
	# 4. Retraite du camp vaincu (ou des attaquants si la bataille est indécise), encerclement sinon.
	for army: String in b["sides"][loser]["armies"]:
		if not state.formations.has(army):
			continue
		if state.units_of(army).is_empty():
			state.log_event("bataille", "%s est anéantie." % state.formations[army]["name_fr"], [state.formations[army]["nation"]])
			_dissolve_annihilated(state, world, cr, army, rid)
			continue
		var prefer: String = b["origin"].get(army, "")
		var dest := choose_retreat(state, world, cr, state.formations[army]["nation"], rid, prefer)
		if dest == "":
			state.formations[army]["encircled"] = true
			state.log_event("encerclement", "%s ne trouve aucune retraite sûre : encerclée en %s." % [
				state.formations[army]["name_fr"], world.regions[rid]["name_fr"]], [state.formations[army]["nation"]])
		else:
			state.move_army(army, dest)
			state.formations[army]["encircled"] = false
			state.log_event("retraite", "%s (%s) se replie sur %s." % [state.formations[army]["name_fr"],
				state.nations[state.formations[army]["nation"]]["name_fr"], world.regions[dest]["name_fr"]], [state.formations[army]["nation"]])
	for side: String in CombatData.SIDES:
		for army: String in b["sides"][side]["armies"]:
			if state.formations.has(army) and state.units_of(army).is_empty():
				_dissolve_annihilated(state, world, cr, army, rid)
	# 5. Positions défensives conservées dans la région (état et niveau compris).
	state.regions[rid]["defenses"] = b["defenses"].duplicate(true)
	# 6. Historique.
	var summary := "Bataille de %s%s : %s. Pertes : attaquants %d, défenseurs %d (%s)." % [world.regions[rid]["name_fr"],
		(" (%s)" % result["engagement"]["label_fr"]) if result.has("engagement") else "",
		"victoire des attaquants" if winner == CombatData.ATTACKERS else ("victoire des défenseurs" if winner == CombatData.DEFENDERS else "indécise, le défenseur tient"),
		int(result["stats"]["attackers"]["lost"]), int(result["stats"]["defenders"]["lost"]), result["end_reason"]]
	for side: String in CombatData.SIDES:
		var k: Dictionary = booked[side]
		summary += " %s : tués %d, blessés %d (dont %d restés dans leur unité), disparus %d, prisonniers %d." % [
			"Attaquants" if side == CombatData.ATTACKERS else "Défenseurs", int(k["killed"]), int(k["wounded"]), int(k["remained"]), int(k["missing"]), int(k["prisoners"])]
	b["casualty_breakdown"] = booked
	state.log_event("bataille", summary, b["sides"]["attackers"]["nations"] + b["sides"]["defenders"]["nations"])
	state.active_battles.erase(b)
	var record := b.duplicate(true)
	record.erase("fog")
	record.erase("visible")
	state.battles.append(record)
	return result


## Reconnaissance en force : renseignement de l'attaquant sur ce que son camp a repéré (brouillard,
## estimations arrondies), conservé dans la région pour chaque pays attaquant.
static func _record_reconnaissance(state: GameState, b: Dictionary) -> void:
	var mem: Dictionary = b["fog"][CombatData.ATTACKERS]
	var estimate := 0
	for eid: String in mem:
		estimate += int(mem[eid]["estimate"])
	var report := {"turn": state.turn, "date": state.date_label(), "units_seen": mem.size(), "estimate": estimate,
		"fortification_level": int(b["engagement"]["fortification_level"])}
	var rid: String = b["region"]
	if not state.regions[rid].has("recon_reports"):
		state.regions[rid]["recon_reports"] = {}
	for n: String in b["sides"][CombatData.ATTACKERS]["nations"]:
		state.regions[rid]["recon_reports"][n] = report.duplicate()
	b["recon_report"] = report
	state.log_event("renseignement", "Reconnaissance en force : %d unité(s) ennemie(s) repérée(s), environ %d hommes ; tranchées de niveau %d." % [
		mem.size(), estimate, int(report["fortification_level"])], b["sides"][CombatData.ATTACKERS]["nations"])


## Retraite (T-043) : région nationale ou alliée, sans armée ennemie, de préférence reliée à la
## capitale, peu exposée (voisins ennemis), l'origine étant préférée si elle est sûre. "" = encerclée.
static func choose_retreat(state: GameState, world: WorldMap, cr: Dictionary, nation: String, rid: String, prefer: String = "") -> String:
	var rc: Dictionary = cr["retreat"]
	var accessible := LogisticsSystem.accessible_regions(state, world, nation)
	var best := ""
	var best_score := -INF
	for n: String in world.neighbor_ids(rid, true):
		var owner := state.controller(n)
		var friendly := owner == nation or not state.active_treaties_between(nation, owner, "alliance").is_empty()
		if not friendly:
			continue
		var hostile := false
		for army: Dictionary in state.armies_in(n):
			if state.at_war(nation, army["nation"]):
				hostile = true
		if hostile:
			continue
		var score := 0.0
		if accessible.has(n):
			score += float(rc["prefer_connected_to_capital"])
		if world.has_rail_link(rid, n):
			score += float(rc["rail_bonus"])
		for nn: String in world.neighbor_ids(n, true):
			if state.at_war(nation, state.controller(nn)):
				score -= float(rc["enemy_neighbor_penalty"])
		if n == prefer:
			score += 0.5
		if score > best_score or (score == best_score and n < best):
			best_score = score
			best = n
	return best


## Issue de la bataille pour chaque armée engagée, utilisée par la ventilation des pertes en déroute :
## "won" (camp vainqueur : il conserve ou prend le terrain), "indecisive" (issue indécise : aucune
## capture établie), "lost_retreat" ou "lost_no_retreat" (camp vaincu, selon qu'une retraite sûre existe).
## Calculée AVANT les conséquences territoriales, avec la règle de retraite existante (T-043), sans la modifier.
static func _side_outcomes(state: GameState, world: WorldMap, cr: Dictionary, b: Dictionary, winner: String, rid: String) -> Dictionary:
	var out: Dictionary = {}
	for side: String in CombatData.SIDES:
		for army: String in b["sides"][side]["armies"]:
			if not state.formations.has(army):
				continue
			if winner == side:
				out[army] = "won"
			elif winner == "":
				out[army] = "indecisive"
			else:
				var dest := choose_retreat(state, world, cr, state.formations[army]["nation"], rid, b["origin"].get(army, ""))
				out[army] = "lost_retreat" if dest != "" else "lost_no_retreat"
	return out


## Puissance détentrice des prisonniers faits par un camp : son commandant, sinon sa première nation.
static func _captor(b: Dictionary, side: String) -> String:
	var cmd: Variant = b["sides"][side].get("commander", {}).get("nation")
	return str(cmd) if cmd != null else str(b["sides"][side]["nations"][0])


## Armée anéantie (plus aucune unité combattante) : ses services rejoignent le territoire national
## si une retraite sûre existe ; sinon leur sort est inconnu (pertes, cause `annihilated_services`).
## Jamais de prisonniers sans capture établie (MIL01-P2-D2).
static func _dissolve_annihilated(state: GameState, world: WorldMap, cr: Dictionary, army: String, rid: String) -> void:
	var nation: String = state.formations[army]["nation"]
	if choose_retreat(state, world, cr, nation, rid) != "":
		var people: Variant = ForceLedger.personnel_of(state, army)
		if people != null and int(people) > 0:
			state.log_event("retraite", "Les services de %s (%d hommes) rejoignent leur territoire." % [state.formations[army]["name_fr"], int(people)], [nation])
		ForceLedger.rejoin_and_remove(state, army)
	else:
		ForceLedger.remove_formation_booked(state, army, "missing")


## Encerclement (T-044), une fois par mois : libération si une retraite sûre réapparaît ;
## sinon attrition, puis reddition selon le moral. La destruction résulte des combats.
static func monthly_encirclement(state: GameState, world: WorldMap, cr: Dictionary) -> void:
	var e: Dictionary = cr["encirclement"]
	for army: String in state.sorted_formation_ids():
		if not state.formations.has(army):
			continue
		var f: Dictionary = state.formations[army]
		if not state.is_top_level(f) or not f.get("encircled", false) or state.is_engaged(army):
			continue
		var rid: String = f["region"]
		var nation: String = f["nation"]
		var friendly_here := state.controller(rid) == nation or not state.active_treaties_between(nation, state.controller(rid), "alliance").is_empty()
		if friendly_here or choose_retreat(state, world, cr, nation, rid) != "":
			f["encircled"] = false
			state.log_event("encerclement", "%s est libérée de l'encerclement." % f["name_fr"], [nation])
			continue
		f["morale"] = maxf(0.0, float(f.get("morale", cr["morale"]["army_default"])) - float(e["monthly_morale_loss"]))
		var lost := 0
		for uid: String in state.units_of(army):
			var su: Dictionary = state.formations[uid]
			if su.get("soldiers") == null:
				continue
			var l := int(round(float(su["soldiers"]) * float(e["monthly_attrition"])))
			su["soldiers"] = int(su["soldiers"]) - l
			lost += l
			ForceLedger.add_missing(state, nation, l, "encirclement_attrition")  # sort inconnu
		if float(f["morale"]) < float(e["surrender_morale"]):
			var prisoners: Variant = state.soldiers_of(army)
			state.log_event("reddition", "%s, encerclée en %s, capitule (%s prisonniers)." % [f["name_fr"], world.regions[rid]["name_fr"], str(prisoners)], [nation, state.controller(rid)])
			state.remember(nation, state.controller(rid), "army_surrendered", army)
			ForceLedger.remove_formation_booked(state, army, "prisoners", state.controller(rid))
		else:
			state.log_event("encerclement", "%s reste encerclée (moral %.0f, %d pertes d'attrition)." % [f["name_fr"], float(f["morale"]), lost], [nation])


## Récupération mensuelle du moral des unités non engagées (T-038), vers le moral de leur armée.
static func monthly_morale(state: GameState, cr: Dictionary) -> void:
	for uid: String in state.sorted_formation_ids():
		var su: Dictionary = state.formations[uid]
		if su["echelon"] != "unit" or su.get("morale") == null or su.get("battle_id", "") != "":
			continue
		var army: Dictionary = state.formations[state.army_of(uid)]
		if army.get("encircled", false) or army.get("morale") == null:
			continue
		su["morale"] = minf(float(army["morale"]), float(su["morale"]) + float(cr["morale"]["monthly_recovery"]))
