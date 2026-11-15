class_name TacticalSim
extends RefCounted
## Simulation tactique à pas fixe, déterministe, sans interface (une bataille = un Dictionary).
## Un pas = `tick_seconds` secondes. Ordre d'un pas :
##   arrivées → brouillard → mouvements et ordres → construction → tir et mêlée (pertes par unité)
##   → application des pertes → moral, déroute, ralliement → objectifs → fin.
## Toutes les valeurs proviennent de data/rules/combat_rules.json (provisoires).


static func step(battle: Dictionary, rules: Dictionary, ticks: int = 1) -> void:
	for i in ticks:
		if battle["status"] != "active":
			return
		_one_tick(battle, rules)


static func _one_tick(b: Dictionary, r: Dictionary) -> void:
	var tick: int = b["tick"]
	_arrivals(b, r)
	if tick % int(r["fog"]["update_ticks"]) == 0:
		update_fog(b, r)
	_movement(b, r)
	_construction(b, r)
	var losses := _fire_and_melee(b, r)
	_apply_losses(b, r, losses)
	_morale(b, r, losses)
	_objectives(b, r)
	b["tick"] = tick + 1
	if int(b["tick"]) >= int(b["max_ticks"]) or _side_broken(b, CombatData.ATTACKERS) or _side_broken(b, CombatData.DEFENDERS):
		b["status"] = "ended"
		b["end_reason"] = "durée maximale atteinte" if int(b["tick"]) >= int(b["max_ticks"]) else "un camp ne peut plus combattre"


# ------------------------------------------------------------------ modificateurs
static func formation_cfg(r: Dictionary, u: Dictionary) -> Dictionary:
	return r["formations"][u["formation"]]


static func type_cfg(r: Dictionary, u: Dictionary) -> Dictionary:
	return r["unit_types"][u["type"]]


static func effectiveness(r: Dictionary, u: Dictionary) -> float:
	var m: Dictionary = r["morale"]
	var eff := lerpf(float(m["effectiveness_floor"]), 1.0, clampf(float(u["morale"]) / float(m["max"]), 0.0, 1.0))
	if float(u["morale"]) < float(m["disorganized_threshold"]):
		eff *= float(m["disorganized_fire"])
	# Durée d'engagement (T-042) : la fatigue réduit progressivement l'efficacité.
	var c: Dictionary = r["combat"]
	eff *= maxf(float(c["fatigue_floor"]), 1.0 - float(u.get("engaged_ticks", 0)) * float(c["fatigue_per_engaged_tick"]))
	return eff


static func is_disorganized(r: Dictionary, u: Dictionary) -> bool:
	return u["status"] == CombatData.ACTIVE and float(u["morale"]) < float(r["morale"]["disorganized_threshold"])


static func side_of_nation(b: Dictionary, nation: String) -> String:
	for side: String in CombatData.SIDES:
		if (b["sides"][side]["nations"] as Array).has(nation):
			return side
	return ""


## Niveau de tranchée achevée (du camp de l'unité) sous l'unité ; 0 si aucune.
static func trench_level(b: Dictionary, r: Dictionary, u: Dictionary) -> int:
	var best := 0
	var pos := CombatData.v(u["pos"])
	var buffer := float(r["construction"]["trench_buffer"])
	for t: Dictionary in b["defenses"]["trenches"]:
		if int(t["level"]) <= best or side_of_nation(b, t["owner"]) != u["side"]:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(pos, CombatData.v(t["a"]), CombatData.v(t["b"]))
		if pos.distance_to(closest) <= buffer:
			best = int(t["level"])
	return best


## Bonus des installations achevées du camp de l'unité : {fire, cover, command}.
static func installation_bonus(b: Dictionary, r: Dictionary, u: Dictionary) -> Dictionary:
	var out := {"fire": 0.0, "cover": 0.0, "command": false}
	var pos := CombatData.v(u["pos"])
	var radius := float(r["combat"]["installation_radius"])
	for inst: Dictionary in b["defenses"]["installations"]:
		if not inst["complete"] or side_of_nation(b, inst["owner"]) != u["side"]:
			continue
		var cfg: Dictionary = r["construction"]["types"][inst["type"]]
		var d := pos.distance_to(CombatData.v(inst["pos"]))
		if inst["type"] == "command_post" and d <= float(r["morale"]["command_post_radius"]):
			out["command"] = true
		if d > radius:
			continue
		var condition := float(inst["condition"])
		if inst["type"] == "artillery_position" and u["type"] != "artillery":
			continue
		out["fire"] = maxf(out["fire"], float(cfg["fire_bonus"]) * condition)
		out["cover"] = maxf(out["cover"], float(cfg["cover"]) * condition)
	return out


static func cover(b: Dictionary, r: Dictionary, u: Dictionary) -> float:
	var t := float(b["field"]["terrain"]["cover"])
	var lvl := trench_level(b, r, u)
	var trench := lvl * float(r["combat"]["trench_cover_per_level"])
	if u["formation"] == "assault_column":
		trench *= 0.3
	elif u["formation"] == "skirmish_line":
		trench *= 0.7
	return minf(0.85, t + trench + float(installation_bonus(b, r, u)["cover"]))


static func speed(b: Dictionary, r: Dictionary, u: Dictionary) -> float:
	var f := formation_cfg(r, u)
	var terrain_speed := float(b["field"]["terrain"]["speed"])
	if trench_level(b, r, u) > 0:
		terrain_speed = 1.0  # boyaux de communication : les tranchées soutiennent les mouvements
	var bonus := 1.0
	for relief: String in b["field"]["relief"]:
		bonus = maxf(bonus, float((f["terrain_speed_bonus"] as Dictionary).get(relief, 1.0)))
	var s := float(type_cfg(r, u)["speed"]) * float(f["speed"]) * terrain_speed * bonus
	if is_disorganized(r, u):
		s *= float(r["morale"]["disorganized_speed"])
	if u["status"] == CombatData.ROUTING:
		s = float(type_cfg(r, u)["speed"]) * float(r["rout"]["speed_mult"]) * terrain_speed
	if u["order"] == "charge":
		s *= float(r["combat"]["charge_speed_mult"])
	return s * float(r["tick_seconds"])


# ------------------------------------------------------------------ arrivées et brouillard
static func _arrivals(b: Dictionary, r: Dictionary) -> void:
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if u["status"] == CombatData.ARRIVING and int(b["tick"]) >= int(u["arrive_tick"]):
			u["status"] = CombatData.ACTIVE
			u["pos"] = (u["entry"] as Array).duplicate()
			_log(b, "%s arrive sur le champ de bataille." % u["name_fr"], u["side"])


## Brouillard tactique (T-035) : visibilité par camp, mémoire datée qui vieillit puis s'efface.
static func update_fog(b: Dictionary, r: Dictionary) -> void:
	var tick: int = b["tick"]
	var spot_mult := float(b["field"]["terrain"]["spot"])
	var fog_cfg: Dictionary = r["fog"]
	for side: String in CombatData.SIDES:
		var visible: Dictionary = {}
		var memory: Dictionary = b["fog"][side]
		for eid: String in CombatData.unit_ids(b):
			var e: Dictionary = b["units"][eid]
			if e["side"] == side or not CombatData.is_on_field(e):
				continue
			var stealth := float(formation_cfg(r, e)["spot_stealth"])
			if trench_level(b, r, e) > 0:
				stealth *= 0.7
			for oid: String in CombatData.unit_ids(b):
				var o: Dictionary = b["units"][oid]
				if o["side"] != side or not CombatData.is_on_field(o):
					continue
				var rng := float(type_cfg(r, o)["spot_range"]) * spot_mult * stealth
				if CombatData.v(o["pos"]).distance_to(CombatData.v(e["pos"])) <= rng:
					visible[eid] = true
					break
			if visible.has(eid):
				var rounding := float(fog_cfg["estimate_rounding"])
				memory[eid] = {"pos": (e["pos"] as Array).duplicate(), "tick": tick, "type": e["type"], "nation": e["nation"],
					"estimate": int(maxf(rounding, snappedf(float(e["soldiers"]), rounding))), "routing": e["status"] == CombatData.ROUTING,
					"formation": e["formation"]}
		for eid: String in memory.keys():
			if not visible.has(eid) and tick - int(memory[eid]["tick"]) > int(fog_cfg["forget_ticks"]):
				memory.erase(eid)
		b["visible"][side] = visible


static func is_visible_to(b: Dictionary, side: String, uid: String) -> bool:
	return (b["visible"][side] as Dictionary).has(uid)


# ------------------------------------------------------------------ mouvements et construction
static func _movement(b: Dictionary, r: Dictionary) -> void:
	var w := float(b["field"]["w"])
	var h := float(b["field"]["h"])
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if u["status"] == CombatData.ROUTING:
			u["dest"] = (u["retreat_point"] as Array).duplicate()
		elif u["status"] != CombatData.ACTIVE:
			continue
		if u["order"] == "charge":
			var t: Dictionary = b["units"].get(u["target"], {})
			if t.is_empty() or not CombatData.is_on_field(t) or int(u["charge_ticks"]) <= 0:
				u["order"] = "hold"
				u["dest"] = null
			else:
				u["dest"] = (t["pos"] as Array).duplicate()
				u["charge_ticks"] = int(u["charge_ticks"]) - 1
		elif u["order"] == "build":
			var job := _job(b, u.get("build", ""))
			if job.is_empty() or job["complete"]:
				u["order"] = "hold"
				u["dest"] = null
			else:
				u["dest"] = (job["site"] as Array).duplicate()
		if u["dest"] == null:
			continue
		var pos := CombatData.v(u["pos"])
		var dest := CombatData.v(u["dest"])
		var stop := float(r["combat"]["melee_range"]) * 0.5 if u["order"] == "charge" else 4.0
		if u["order"] == "build":
			stop = 30.0
		var d := pos.distance_to(dest)
		if d <= stop:
			if u["order"] == "move":
				u["order"] = "hold"
				u["dest"] = null
			if u["status"] == CombatData.ROUTING:
				u["status"] = CombatData.WITHDRAWN
				_log(b, "%s, en déroute, quitte le champ de bataille." % u["name_fr"], u["side"])
			continue
		var step_len := minf(speed(b, r, u), d - stop)
		var np := pos + (dest - pos).normalized() * step_len
		u["pos"] = CombatData.a(Vector2(clampf(np.x, 0.0, w), clampf(np.y, 0.0, h)))


static func _job(b: Dictionary, jid: String) -> Dictionary:
	for t: Dictionary in b["defenses"]["trenches"] + b["defenses"]["installations"]:
		if t["id"] == jid:
			return t
	return {}


## Construction (T-032/T-033) : progression selon effectifs, terrain, type, moral ; ralentie sous le feu.
static func _construction(b: Dictionary, r: Dictionary) -> void:
	var c: Dictionary = r["construction"]
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if u["status"] != CombatData.ACTIVE or u["order"] != "build":
			continue
		var job := _job(b, u.get("build", ""))
		if job.is_empty() or job["complete"] or CombatData.v(u["pos"]).distance_to(CombatData.v(job["site"])) > 30.0:
			continue
		var rate := float(u["soldiers"]) * float(c["work_per_soldier_per_tick_battle"]) * float(b["field"]["terrain"]["dig"]) \
			* float(type_cfg(r, u)["dig_rate"]) * effectiveness(r, u)
		if int(b["tick"]) - int(u["last_fire_tick"]) <= int(c["under_fire_memory_ticks"]):
			rate *= float(c["under_fire_rate"])
		job["progress"] = float(job["progress"]) + rate
		if float(job["progress"]) >= float(job["work_needed"]):
			job["progress"] = 0.0 if job.has("level") else float(job["work_needed"])
			if job.has("level"):
				job["level"] = int(job["level"]) + 1
				job["complete"] = int(job["level"]) >= int(job["target_level"])
				job["condition"] = 1.0
			else:
				job["complete"] = true
			_log(b, "%s : construction terminée (%s)." % [u["name_fr"], job.get("type", "tranchée")], u["side"])


# ------------------------------------------------------------------ tir et mêlée (pertes par unité)
static func _fire_and_melee(b: Dictionary, r: Dictionary) -> Dictionary:
	var losses: Dictionary = {}
	var dt := float(r["tick_seconds"])
	var cmb: Dictionary = r["combat"]
	for uid: String in CombatData.unit_ids(b):
		var s: Dictionary = b["units"][uid]
		if s["status"] != CombatData.ACTIVE:
			continue
		var tc := type_cfg(r, s)
		var spos := CombatData.v(s["pos"])
		var target := ""
		var best := INF
		if s["order"] == "charge" and is_visible_to(b, s["side"], s["target"]):
			target = s["target"]
		else:
			for eid: String in b["visible"][s["side"]]:
				var e: Dictionary = b["units"].get(eid, {})
				if e.is_empty() or not CombatData.is_on_field(e):
					continue
				var d := spos.distance_to(CombatData.v(e["pos"]))
				if d <= float(tc["range"]) and d < best:
					best = d
					target = eid
		if target == "":
			continue
		var t: Dictionary = b["units"][target]
		var d := spos.distance_to(CombatData.v(t["pos"]))
		if d <= float(cmb["melee_range"]) and s["order"] == "charge":
			_melee(b, r, s, t, losses)
			continue
		if d > float(tc["range"]):
			continue
		if s["order"] == "build":
			continue  # une unité au travail ne tire pas
		var falloff := lerpf(1.0, float(cmb["falloff_min"]), clampf(d / float(tc["range"]), 0.0, 1.0))
		var bonus := installation_bonus(b, r, s)
		var fire := float(tc["lethality"]) * float(s["soldiers"]) * float(formation_cfg(r, s)["fire"]) \
			* effectiveness(r, s) * (1.0 + float(bonus["fire"])) * falloff * dt
		var c := fire * exposure(b, r, t)
		losses[target] = float(losses.get(target, 0.0)) + c
		if s["type"] == "artillery":
			_damage_installations(b, r, t)
		t["last_fire_tick"] = b["tick"]
		s["engaged_ticks"] = int(s["engaged_ticks"]) + 1
	return losses


## Exposition d'une unité au feu : type × formation × (1 − couverture) × vulnérabilité (déroute, travaux).
static func exposure(b: Dictionary, r: Dictionary, t: Dictionary) -> float:
	var e := float(type_cfg(r, t)["exposure"]) * float(formation_cfg(r, t)["exposure"]) * (1.0 - cover(b, r, t))
	if t["status"] == CombatData.ROUTING:
		e *= float(r["rout"]["vulnerability"])
	if t["order"] == "build":
		e *= float(r["construction"]["builder_exposure_mult"])
	if t["type"] == "artillery":
		e *= float(r["combat"]["role_exposure"]["artillery_rear_factor"])
	return e


## Le feu d'artillerie dégrade les installations ennemies proches de la cible (état ∈ [0, 1]).
static func _damage_installations(b: Dictionary, r: Dictionary, target: Dictionary) -> void:
	var radius := float(r["combat"]["installation_radius"])
	var dmg := float(r["combat"]["installation_damage_per_artillery_tick"])
	for inst: Dictionary in b["defenses"]["installations"]:
		if inst["complete"] and side_of_nation(b, inst["owner"]) == target["side"] \
				and CombatData.v(inst["pos"]).distance_to(CombatData.v(target["pos"])) <= radius:
			inst["condition"] = maxf(0.0, float(inst["condition"]) - dmg)


static func _melee(b: Dictionary, r: Dictionary, s: Dictionary, t: Dictionary, losses: Dictionary) -> void:
	var cmb: Dictionary = r["combat"]
	var dt := float(r["tick_seconds"])
	var trench := trench_level(b, r, t) * float(cmb["trench_cover_per_level"])
	var att := float(cmb["charge_melee_lethality"]) * float(s["soldiers"]) * float(type_cfg(r, s)["melee"]) \
		* float(formation_cfg(r, s)["charge"]) * effectiveness(r, s) * dt * (1.0 - minf(0.8, trench * 2.0))
	var dfn := float(cmb["charge_melee_lethality"]) * 0.6 * float(t["soldiers"]) * float(type_cfg(r, t)["melee"]) \
		* effectiveness(r, t) * dt * (1.0 + trench * 2.0)
	if t["status"] == CombatData.ROUTING:
		att *= float(r["rout"]["vulnerability"])
		dfn *= 0.2
	losses[t["id"]] = float(losses.get(t["id"], 0.0)) + att
	losses[s["id"]] = float(losses.get(s["id"], 0.0)) + dfn
	if not s.get("charge_contact", false):
		s["charge_contact"] = true
		t["morale"] = maxf(0.0, float(t["morale"]) - float(cmb["charge_morale_shock"]) * float(formation_cfg(r, s)["charge"]))
		_log(b, "%s charge %s." % [s["name_fr"], t["name_fr"]], s["side"])
	t["last_fire_tick"] = b["tick"]
	s["last_fire_tick"] = b["tick"]


static func _apply_losses(b: Dictionary, r: Dictionary, losses: Dictionary) -> void:
	var keys := losses.keys()
	keys.sort()
	for uid: String in keys:
		var u: Dictionary = b["units"][uid]
		var carry := float(u["loss_carry"]) + float(losses[uid])
		var n := int(floor(carry))
		u["loss_carry"] = carry - n
		n = mini(n, int(u["soldiers"]))
		u["soldiers"] = int(u["soldiers"]) - n
		u["tick_losses"] = n
		if int(u["soldiers"]) < int(r["combat"]["min_unit_soldiers"]) and u["status"] != CombatData.DESTROYED:
			u["status"] = CombatData.DESTROYED
			u["soldiers"] = 0
			u["dest"] = null
			_log(b, "%s est anéantie." % u["name_fr"], u["side"])


# ------------------------------------------------------------------ moral et déroute
static func _morale(b: Dictionary, r: Dictionary, losses: Dictionary) -> void:
	var m: Dictionary = r["morale"]
	var routing_positions: Array = []
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if u["status"] == CombatData.ROUTING:
			routing_positions.append([u["side"], CombatData.v(u["pos"])])
	for uid: String in CombatData.unit_ids(b):
		var u: Dictionary = b["units"][uid]
		if not CombatData.is_on_field(u):
			continue
		var morale := float(u["morale"])
		var army_morale := float(b["army_morale"].get(u["army"], m["army_default"]))
		morale += (army_morale - morale) * float(m["army_influence_per_tick"])
		var n := int(u.get("tick_losses", 0))
		var resist := float(formation_cfg(r, u)["morale_resist"]) * (1.0 + 0.15 * trench_level(b, r, u))
		if n > 0:
			morale -= float(n) / maxf(1.0, float(u["soldiers"]) + n) * float(m["loss_shock"]) / resist
		var under_fire := int(b["tick"]) - int(u["last_fire_tick"]) <= 1
		if under_fire:
			morale -= float(m["under_fire_per_tick"]) / resist
			u["quiet_ticks"] = 0
		else:
			u["quiet_ticks"] = int(u["quiet_ticks"]) + 1
		for entry: Array in routing_positions:
			if entry[0] == u["side"] and (entry[1] as Vector2).distance_to(CombatData.v(u["pos"])) <= float(m["rout_contagion_radius"]) \
					and u["status"] != CombatData.ROUTING:
				morale -= float(m["rout_contagion_per_tick"])
		if not under_fire and installation_bonus(b, r, u)["command"]:
			morale += float(m["command_post_recovery_per_tick"])
		for o: Dictionary in b["objectives"]:
			if o["controller"] == u["side"] and CombatData.v(o["pos"]).distance_to(CombatData.v(u["pos"])) <= float(r["victory"]["objective_radius"]):
				morale += float(m["objective_hold_per_tick"])
				break
		u["morale"] = clampf(morale, 0.0, float(m["max"]))
		u["tick_losses"] = 0
		var rt: Dictionary = r["rout"]
		if u["status"] == CombatData.ACTIVE and float(u["morale"]) < float(rt["threshold"]):
			u["status"] = CombatData.ROUTING
			u["order"] = "rout"
			_log(b, "%s est en déroute !" % u["name_fr"], u["side"])
		elif u["status"] == CombatData.ROUTING and float(u["morale"]) >= float(rt["rally_threshold"]) \
				and int(u["quiet_ticks"]) >= int(rt["rally_quiet_ticks"]):
			u["status"] = CombatData.ACTIVE
			u["order"] = "hold"
			u["dest"] = null
			_log(b, "%s se rallie." % u["name_fr"], u["side"])


# ------------------------------------------------------------------ objectifs et fin
static func _objectives(b: Dictionary, r: Dictionary) -> void:
	var radius := float(r["victory"]["objective_radius"])
	for o: Dictionary in b["objectives"]:
		var present := {CombatData.ATTACKERS: false, CombatData.DEFENDERS: false}
		for uid: String in CombatData.unit_ids(b):
			var u: Dictionary = b["units"][uid]
			if u["status"] == CombatData.ACTIVE and CombatData.v(u["pos"]).distance_to(CombatData.v(o["pos"])) <= radius:
				present[u["side"]] = true
		if present[CombatData.ATTACKERS] and not present[CombatData.DEFENDERS]:
			o["controller"] = CombatData.ATTACKERS
		elif present[CombatData.DEFENDERS] and not present[CombatData.ATTACKERS]:
			o["controller"] = CombatData.DEFENDERS


static func _side_broken(b: Dictionary, side: String) -> bool:
	for uid: String in b["units"]:
		var u: Dictionary = b["units"][uid]
		if u["side"] == side and (u["status"] == CombatData.ACTIVE or u["status"] == CombatData.RESERVE or u["status"] == CombatData.ARRIVING):
			return false
	return true


static func _log(b: Dictionary, text: String, side: String = "") -> void:
	(b["log"] as Array).append({"tick": b["tick"], "side": side, "text": text})
