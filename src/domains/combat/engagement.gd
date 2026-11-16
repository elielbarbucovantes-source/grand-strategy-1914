class_name Engagement
extends RefCounted
## Types d'engagement et largeur du front (MIL-01, phase 6, étape 2 ; T-048 choix D, T-055 choix C).
##
## 1. CHOIX. L'attaquant choisit son APPROCHE (reconnaissance en force, attaque limitée, assaut) dans
##    son ordre de déplacement ; le défenseur, sa POSTURE (retarder, tenir, tenir à tout prix), ordre
##    permanent de chaque armée. Ces choix changent des RÈGLES (part des forces engagée d'emblée,
##    seuil de rupture du combat, seuil de déroute, objectifs, charges, retranchement, occupation),
##    jamais un multiplicateur de pertes.
## 2. CLASSIFICATION (escarmouche, engagement limité, assaut frontal, grande bataille) : matrice
##    approche × posture, corrigée par les circonstances (effectifs réellement engagés, terrain,
##    fortifications, moral, encerclement), puis réévaluée en cours de bataille (arrivée des renforts)
##    et à la clôture (durée, rupture du combat).
## 3. LARGEUR DU FRONT : le secteur de combat (km) dépend du type, de la géométrie de la région et du
##    terrain. Seuls les soldats qui y trouvent place tirent (« en ligne ») ; les autres unités au
##    contact attendent (« en attente », peu exposées) et relèvent les unités épuisées (rotation).
##    Les formations et les tranchées changent la place occupée par chaque soldat.
## 4. CAPACITÉ OPÉRATIONNELLE : les blessés légers restés dans leur unité (étape 1) comptent dans
##    l'effectif administratif mais combattent avec une efficacité réduite.
## Valeurs : combat_rules.json, bloc `engagement` (paramètres de CONCEPTION, PROVISOIRES).

const APPROACHES: PackedStringArray = ["reconnaissance", "limited_attack", "assault"]
const POSTURES: PackedStringArray = ["delay", "hold", "hold_at_all_costs"]
const TYPES: PackedStringArray = ["skirmish", "limited", "frontal", "major"]
const DEFAULT_APPROACH := "assault"
const DEFAULT_POSTURE := "hold"


static func cfg(r: Dictionary) -> Dictionary:
	return r.get("engagement", {})


static func active(b: Dictionary) -> bool:
	return b.has("engagement") and not (b["engagement"] as Dictionary).is_empty()


# ------------------------------------------------------------------ capacité opérationnelle
## Effectif opérationnel : les blessés légers restés dans l'unité comptent pour une fraction
## (`lightly_wounded_efficiency`) d'un soldat valide. L'effectif administratif (`soldiers`) est inchangé.
static func operational(r: Dictionary, u: Dictionary) -> float:
	var lw := mini(int(u.get("lightly_wounded", 0)), int(u["soldiers"]))
	var eff := float(cfg(r).get("lightly_wounded_efficiency", 1.0))
	return float(u["soldiers"]) - float(lw) * (1.0 - eff)


## Pertes d'une unité : les blessés légers en font partie au prorata (ils sont dans l'effectif).
static func on_losses(u: Dictionary, n: int, soldiers_before: int) -> void:
	var lw := int(u.get("lightly_wounded", 0))
	if lw <= 0 or n <= 0 or soldiers_before <= 0:
		return
	u["lightly_wounded"] = maxi(0, mini(int(u["soldiers"]), lw - int(round(float(lw) * float(n) / float(soldiers_before)))))


# ------------------------------------------------------------------ choix des camps
## Approche de l'attaquant : celle de l'armée attaquante la plus nombreuse (identifiant croissant en cas
## d'égalité) ; défaut « assaut ».
static func side_approach(state: GameState, armies: Array, approaches: Dictionary) -> String:
	var best := ""
	var top := -1
	var ids := armies.duplicate()
	ids.sort()
	for a: String in ids:
		var s: Variant = state.soldiers_of(a)
		var n := 0 if s == null else int(s)
		if n > top:
			top = n
			best = a
	var ap: String = approaches.get(best, DEFAULT_APPROACH)
	return ap if APPROACHES.has(ap) else DEFAULT_APPROACH


## Posture du défenseur : celle de l'armée défenseure la plus nombreuse. Une armée IA sans posture
## explicite applique la posture par défaut de l'IA (TacticalAI.default_posture).
static func side_posture(state: GameState, armies: Array) -> String:
	var best := ""
	var top := -1
	var ids := armies.duplicate()
	ids.sort()
	for a: String in ids:
		var s: Variant = state.soldiers_of(a)
		var n := 0 if s == null else int(s)
		if n > top:
			top = n
			best = a
	if best == "":
		return DEFAULT_POSTURE
	var f: Dictionary = state.formations[best]
	var p: String = f.get("defensive_posture", "")
	if p == "" and not state.human_nations.has(f["nation"]):
		p = TacticalAI.default_posture(state, best)
	return p if POSTURES.has(p) else DEFAULT_POSTURE


# ------------------------------------------------------------------ classification
## Classification initiale (à la création) et paramètres. `ctx` : {approach, posture, encircled,
## attacker_morale, defender_morale}. Écrit b["engagement"].
static func setup(b: Dictionary, r: Dictionary, ctx: Dictionary) -> void:
	var c := cfg(r)
	if c.is_empty():
		return
	var reasons: Array = []
	var approach: String = ctx["approach"]
	var posture: String = ctx["posture"]
	if posture == "delay" and bool(ctx.get("encircled", false)):
		posture = "hold"
		reasons.append("défenseur encerclé : il ne peut pas retarder, il tient")
	var t: String = c["matrix"][approach][posture]
	reasons.append("choix : %s contre %s → %s" % [c["approaches"][approach]["label_fr"], c["postures"][posture]["label_fr"], c["types"][t]["label_fr"]])
	var fort := fortification_level(b)
	if approach == "limited_attack" and posture != "delay" and fort >= int(c["fortified_trench_level"]) and t == "limited":
		t = "frontal"
		reasons.append("position fortifiée (tranchées de niveau %d) : l'attaque limitée devient un assaut frontal" % fort)
	if approach == "assault" and float(ctx.get("attacker_morale", 100.0)) < float(c["assault_min_army_morale"]) and t == "frontal":
		t = "limited"
		reasons.append("moral de l'attaquant trop bas (%.0f) pour un assaut frontal : engagement limité" % float(ctx["attacker_morale"]))
	var engaged := engaged_soldiers(b)
	var terrain := terrain_frontage(b, r)
	if t == "frontal" and engaged >= int(c["major_battle_soldiers"]):
		if terrain >= float(c["major_min_terrain_frontage"]):
			t = "major"
			reasons.append("ampleur : %d hommes engagés (seuil %d) → grande bataille" % [engaged, int(c["major_battle_soldiers"])])
		else:
			reasons.append("ampleur suffisante mais terrain trop cloisonné (%.2f) pour une grande bataille" % terrain)
	if engaged < int(c["small_battle_soldiers"]) and TYPES.find(t) > TYPES.find("limited"):
		t = "limited"
		reasons.append("faibles effectifs (%d hommes) : engagement limité au plus" % engaged)
	var width := region_width_km(b)
	b["engagement"] = {
		"approach": approach, "posture": posture, "planned": t, "type": t, "realized": "",
		"reasons": reasons, "region_width_km": snappedf(width, 0.1), "terrain_frontage": snappedf(terrain, 0.01),
		"front_km": 0.0, "artillery_front_km": 0.0, "fortification_level": fort,
		"engaged_start": engaged, "peak_line": {"attackers": 0, "defenders": 0}, "line": {"attackers": 0, "defenders": 0},
		"waiting": {"attackers": 0, "defenders": 0}, "rotations": 0, "disengaged": {}, "disengage_end_tick": -1,
		"start_by_side": {}, "upgraded_tick": -1,
		"objective_mode": str(c["approaches"][approach]["objective"]),
	}
	_update_front(b, r)
	for side: String in CombatData.SIDES:
		var s := 0
		for uid: String in b["units"]:
			var u: Dictionary = b["units"][uid]
			if u["side"] == side and u["status"] != CombatData.AVAILABLE:
				s += int(u["soldiers"])
		b["engagement"]["start_by_side"][side] = s


## Part initialement engagée par l'attaquant : les autres unités restent en réserve (proportionnellement
## par type d'unité, ordre déterministe des identifiants).
static func apply_commitment(b: Dictionary, r: Dictionary) -> void:
	if not active(b):
		return
	var share := float(cfg(r)["approaches"][b["engagement"]["approach"]]["commit_share"])
	if share >= 1.0:
		return
	var by_type: Dictionary = {}
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if u["side"] == CombatData.ATTACKERS and u["status"] == CombatData.ACTIVE:
			if not by_type.has(u["type"]):
				by_type[u["type"]] = []
			by_type[u["type"]].append(uid)
	for kind: String in by_type:
		var ids: Array = by_type[kind]
		var keep := maxi(1, int(ceil(share * float(ids.size()))))
		for i in range(keep, ids.size()):
			b["units"][ids[i]]["status"] = CombatData.RESERVE


## Durée maximale du type (plafonne la formule T-036, sans prolongation).
static func max_minutes(b: Dictionary, r: Dictionary) -> float:
	if not active(b):
		return INF
	return float(cfg(r)["types"][b["engagement"]["type"]]["max_minutes"])


static func engaged_soldiers(b: Dictionary) -> int:
	var n := 0
	for uid: String in b["units"]:
		var u: Dictionary = b["units"][uid]
		if u["status"] == CombatData.ACTIVE or u["status"] == CombatData.RESERVE:
			n += int(u["soldiers"])
	return n


## Soldats ayant effectivement pris part (sur le champ à un moment) : effectif initial des unités
## entrées sur le terrain.
static func entered_soldiers(b: Dictionary) -> int:
	var n := 0
	for uid: String in b["units"]:
		var u: Dictionary = b["units"][uid]
		if u["status"] in [CombatData.ACTIVE, CombatData.ROUTING, CombatData.WITHDRAWN, CombatData.DESTROYED, CombatData.WITHDRAWING]:
			n += int(u["start_soldiers"])
	return n


static func fortification_level(b: Dictionary) -> int:
	var best := 0
	var defenders: Array = b["sides"][CombatData.DEFENDERS]["nations"]
	for t: Dictionary in b["defenses"]["trenches"]:
		if defenders.has(t["owner"]):
			best = maxi(best, int(t["level"]))
	return best


static func terrain_frontage(b: Dictionary, r: Dictionary) -> float:
	var tf: Dictionary = cfg(r)["front"]["terrain_frontage"]
	var total := 0.0
	var n := 0
	for relief: String in b["field"]["relief"]:
		if tf.has(relief):
			total += float(tf[relief])
			n += 1
	return 1.0 if n == 0 else total / float(n)


## Largeur de la région perpendiculairement à l'axe d'attaque (km), d'après sa géométrie.
static func region_width_km(b: Dictionary) -> float:
	var f: Dictionary = b["field"]
	var entry := CombatData.v(b["sides"][CombatData.ATTACKERS]["entry"])
	var center := Vector2(float(f["w"]), float(f["h"])) / 2.0
	var axis := (center - entry).normalized()
	if axis == Vector2.ZERO:
		axis = Vector2.RIGHT
	var perp := axis.orthogonal()
	var lo := INF
	var hi := -INF
	for p: Array in f["polygon"]:
		var d := CombatData.v(p).dot(perp)
		lo = minf(lo, d)
		hi = maxf(hi, d)
	return maxf(0.0, hi - lo) * float(f["km_per_unit"])


## Secteur de combat : min(largeur du type, largeur de la région) × terrain.
static func _update_front(b: Dictionary, r: Dictionary) -> void:
	var e: Dictionary = b["engagement"]
	var sector := float(cfg(r)["types"][e["type"]]["sector_km"])
	e["front_km"] = snappedf(minf(sector, float(e["region_width_km"])) * float(e["terrain_frontage"]), 0.01)
	e["artillery_front_km"] = e["front_km"]


## Renforts arrivés : un assaut frontal peut devenir une grande bataille (secteur élargi).
static func on_arrival(b: Dictionary, r: Dictionary) -> void:
	if not active(b):
		return
	var e: Dictionary = b["engagement"]
	var c := cfg(r)
	if e["type"] != "frontal":
		return
	var present := 0
	for uid: String in b["units"]:
		var u: Dictionary = b["units"][uid]
		if u["status"] in [CombatData.ACTIVE, CombatData.ROUTING, CombatData.RESERVE, CombatData.ARRIVING, CombatData.WITHDRAWING]:
			present += int(u["soldiers"])
	if present >= int(c["major_battle_soldiers"]) and float(e["terrain_frontage"]) >= float(c["major_min_terrain_frontage"]):
		e["type"] = "major"
		e["upgraded_tick"] = int(b["tick"])
		(e["reasons"] as Array).append("renforts : %d hommes sur le terrain → grande bataille (secteur élargi)" % present)
		_update_front(b, r)
		b["max_ticks"] = mini(int(b["max_ticks"]), int(ceil(float(c["types"]["major"]["max_minutes"]) * 60.0 / float(r["tick_seconds"]))))
		TacticalSim._log(b, "La bataille prend de l'ampleur : grande bataille, front élargi à %.0f km." % float(e["front_km"]))


## Classification réalisée, à la clôture : un camp qui rompt le combat tôt ramène l'engagement d'un cran.
static func finalize(b: Dictionary, r: Dictionary) -> void:
	if not active(b):
		return
	var e: Dictionary = b["engagement"]
	var t: String = e["type"]
	var c := cfg(r)
	if not (e["disengaged"] as Dictionary).is_empty() and int(b["tick"]) * 3 < int(b["max_ticks"]) and TYPES.find(t) > 0:
		t = TYPES[TYPES.find(t) - 1]
		(e["reasons"] as Array).append("rupture du combat dès le premier tiers de la durée : %s" % c["types"][t]["label_fr"])
	var entered := entered_soldiers(b)
	if entered < int(c["small_battle_soldiers"]) and TYPES.find(t) > TYPES.find("limited"):
		t = "limited"
	e["realized"] = t
	e["entered"] = entered


static func label(r: Dictionary, t: String) -> String:
	return str(cfg(r).get("types", {}).get(t, {}).get("label_fr", t))


# ------------------------------------------------------------------ largeur du front (chaque pas)
## Répartit la place sur le front entre les unités AU CONTACT (un ennemi repéré à portée) : les
## unités déjà en ligne et fraîches d'abord, puis les plus proches de l'ennemi ; les unités épuisées
## (moral ou fatigue) passent derrière si une unité fraîche attend (rotation). Écrit pour chaque unité
## `front_share` (part de l'effectif en ligne) et `front_status` ("line", "waiting" ou "").
static func allocate_front(b: Dictionary, r: Dictionary) -> void:
	if not active(b):
		for uid: String in b["units"]:
			b["units"][uid]["front_share"] = 1.0
			b["units"][uid]["front_status"] = ""
		return
	var e: Dictionary = b["engagement"]
	var fc: Dictionary = cfg(r)["front"]
	for side: String in CombatData.SIDES:
		var pools := {"infantry": [], "artillery": []}
		for uid: String in CombatData.unit_ids(b):
			var u: Dictionary = b["units"][uid]
			if u["side"] != side:
				continue
			var prev: String = u.get("front_status", "")
			u["front_share"] = 0.0
			u["front_status"] = ""
			if u["status"] != CombatData.ACTIVE or u["order"] == "build":
				continue
			var d := _contact_distance(b, r, u)
			if d == INF:
				continue
			var tired := float(u["morale"]) < float(fc["rotation_morale"]) or _fatigue(r, u) < float(fc["rotation_fatigue"])
			var rank := 2 if tired else (0 if prev == "line" else 1)
			(pools["artillery" if u["type"] == "artillery" else "infantry"] as Array).append([rank, d, uid, prev])
		var line := 0
		var waiting := 0
		for pool: String in pools:
			var items: Array = pools[pool]
			items.sort()
			var per_km := float(fc["artillery_per_km"]) if pool == "artillery" else float(fc["infantry_per_km"])
			var room := float(e["artillery_front_km"] if pool == "artillery" else e["front_km"]) * per_km  # en « soldats-équivalents »
			var entered_line := false
			for it: Array in items:
				var u: Dictionary = b["units"][it[2]]
				var need := float(u["soldiers"]) * frontage(b, r, u)
				var share := clampf(room / maxf(1.0, need), 0.0, 1.0)
				room = maxf(0.0, room - share * need)
				u["front_share"] = share
				u["front_status"] = "line" if share > 0.0 else "waiting"
				if share > 0.0:
					line += int(round(float(u["soldiers"]) * share))
					if it[3] != "line":
						entered_line = true
				else:
					waiting += int(u["soldiers"])
					u["engaged_ticks"] = maxi(0, int(u["engaged_ticks"]) - int(fc["fatigue_recovery_per_tick"]))
				if share < 1.0 and share > 0.0:
					waiting += int(round(float(u["soldiers"]) * (1.0 - share)))
			for it: Array in items:
				if it[3] == "line" and b["units"][it[2]]["front_status"] == "waiting" and entered_line:
					e["rotations"] = int(e["rotations"]) + 1
		e["line"][side] = line
		e["waiting"][side] = waiting
		e["peak_line"][side] = maxi(int(e["peak_line"][side]), line)


## Place occupée par un soldat sur le front (1 = référence) : formation, tranchée achevée.
static func frontage(b: Dictionary, r: Dictionary, u: Dictionary) -> float:
	var fc: Dictionary = cfg(r)["front"]
	var f := float(fc["formation_frontage"].get(u["formation"], 1.0))
	if u["type"] != "artillery" and TacticalSim.trench_level(b, r, u) > 0 and u["formation"] == "entrenched":
		f /= float(fc["trench_frontage"])
	return f


## Exposition d'une unité selon sa place : en attente, elle est en retrait du front.
static func exposure_factor(r: Dictionary, u: Dictionary) -> float:
	match u.get("front_status", ""):
		"waiting":
			return float(cfg(r)["front"]["waiting_exposure"])
		"line":
			var s := float(u.get("front_share", 1.0))
			return s + (1.0 - s) * float(cfg(r)["front"]["waiting_exposure"])
	return 1.0


static func _fatigue(r: Dictionary, u: Dictionary) -> float:
	var c: Dictionary = r["combat"]
	return maxf(float(c["fatigue_floor"]), 1.0 - float(u.get("engaged_ticks", 0)) * float(c["fatigue_per_engaged_tick"]))


static func _contact_distance(b: Dictionary, r: Dictionary, u: Dictionary) -> float:
	var rng := float(r["unit_types"][u["type"]]["range"])
	var pos := CombatData.v(u["pos"])
	var best := INF
	for eid: String in b["visible"][u["side"]]:
		var e: Dictionary = b["units"].get(eid, {})
		if e.is_empty() or not CombatData.is_on_field(e):
			continue
		var d := pos.distance_to(CombatData.v(e["pos"]))
		if d <= rng and d < best:
			best = d
	return best


# ------------------------------------------------------------------ rupture du combat
## Seuil de pertes (part de l'effectif engagé) au-delà duquel un camp rompt le combat en ordre :
## attaquant selon l'approche, défenseur selon la posture (aucun pour « tenir à tout prix »).
static func disengage_threshold(b: Dictionary, r: Dictionary, side: String) -> float:
	var c := cfg(r)
	var e: Dictionary = b["engagement"]
	var v: Variant = c["approaches"][e["approach"]]["disengage_loss"] if side == CombatData.ATTACKERS else c["postures"][e["posture"]]["disengage_loss"]
	return INF if v == null else float(v)


## Un camp rompt le combat quand la part de son effectif engagé PERDUE OU EN DÉROUTE atteint le seuil
## de son approche ou de sa posture (le commandement constate qu'une partie de ses forces est hors de
## combat), ou quand toutes ses unités actives sont épuisées (moral sous `disengage_morale`).
## « Tenir à tout prix » : jamais.
static func check_disengagement(b: Dictionary, r: Dictionary) -> void:
	if not active(b):
		return
	var e: Dictionary = b["engagement"]
	if not (e["disengaged"] as Dictionary).is_empty():
		return
	for side: String in CombatData.SIDES:
		var threshold := disengage_threshold(b, r, side)
		if threshold == INF:
			continue
		var start := 0
		var now := 0
		var routing := 0
		var active_n := 0
		var exhausted := 0
		for uid: String in b["units"]:
			var u: Dictionary = b["units"][uid]
			if u["side"] != side or not (u["status"] in [CombatData.ACTIVE, CombatData.ROUTING, CombatData.WITHDRAWN, CombatData.DESTROYED, CombatData.WITHDRAWING]):
				continue
			start += int(u["start_soldiers"])
			now += int(u["soldiers"])
			if u["status"] == CombatData.ROUTING:
				routing += int(u["soldiers"])
			elif u["status"] == CombatData.ACTIVE:
				active_n += 1
				if float(u["morale"]) < float(cfg(r)["disengage_morale"]):
					exhausted += 1
		if start <= 0:
			continue
		var out := float(start - now + routing) / float(start)
		var who := "l'approche" if side == CombatData.ATTACKERS else "la posture"
		if out >= threshold:
			disengage(b, r, side, "%.0f %% de l'effectif perdu ou en déroute (seuil de %s : %.0f %%)" % [100.0 * out, who, 100.0 * threshold])
			return
		if active_n > 0 and exhausted == active_n and int(b["tick"]) > 0:
			disengage(b, r, side, "toutes les unités engagées sont épuisées (moral inférieur à %.0f)" % float(cfg(r)["disengage_morale"]))
			return


## Rupture du combat en ordre : les unités actives se replient (sans déroute), les réserves et les
## renforts en route ne s'engagent plus. La bataille s'achève après `disengage_ticks`.
static func disengage(b: Dictionary, r: Dictionary, side: String, why: String) -> String:
	if not active(b):
		return "types d'engagement inactifs"
	var e: Dictionary = b["engagement"]
	if not (e["disengaged"] as Dictionary).is_empty():
		return "un camp a déjà rompu le combat"
	e["disengaged"][side] = int(b["tick"])
	e["disengage_end_tick"] = int(b["tick"]) + int(cfg(r)["disengage_ticks"])
	for uid: String in b["units"]:
		var u: Dictionary = b["units"][uid]
		if u["side"] != side:
			continue
		if u["status"] == CombatData.ACTIVE:
			u["status"] = CombatData.WITHDRAWING
			u["order"] = "withdraw"
			u["dest"] = (u["retreat_point"] as Array).duplicate()
		elif u["status"] == CombatData.RESERVE or u["status"] == CombatData.ARRIVING:
			u["status"] = CombatData.WITHDRAWN
	TacticalSim._log(b, "%s rompent le combat en ordre : %s." % ["Les attaquants" if side == CombatData.ATTACKERS else "Les défenseurs", why], side)
	return ""


## Fin de la rupture : les unités en repli ont quitté le contact.
static func disengagement_over(b: Dictionary) -> bool:
	if not active(b) or int(b["engagement"]["disengage_end_tick"]) < 0:
		return false
	if int(b["tick"]) < int(b["engagement"]["disengage_end_tick"]):
		return false
	for uid: String in b["units"]:
		if b["units"][uid]["status"] == CombatData.WITHDRAWING:
			b["units"][uid]["status"] = CombatData.WITHDRAWN
	return true


## Seuil de déroute de l'unité (posture « tenir à tout prix » : les défenseurs tiennent plus longtemps).
static func rout_threshold(b: Dictionary, r: Dictionary, u: Dictionary) -> float:
	var base := float(r["rout"]["threshold"])
	if not active(b) or u["side"] != CombatData.DEFENDERS:
		return base
	return base * float(cfg(r)["postures"][b["engagement"]["posture"]]["rout_threshold_mult"])


## Paramètre d'approche (attaquant) ou de posture (défenseur) pour un camp.
static func side_param(b: Dictionary, r: Dictionary, side: String, key: String, fallback: Variant) -> Variant:
	if not active(b):
		return fallback
	var e: Dictionary = b["engagement"]
	var block: Dictionary = cfg(r)["approaches"][e["approach"]] if side == CombatData.ATTACKERS else cfg(r)["postures"][e["posture"]]
	return block.get(key, fallback)


## Mode de choix de l'objectif de l'attaquant ("nearest" ou "main"), d'après l'approche.
static func cfg_objective(b: Dictionary) -> String:
	return str(b["engagement"].get("objective_mode", "main"))
