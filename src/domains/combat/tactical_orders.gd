class_name TacticalOrders
extends RefCounted
## Commandes tactiques (T-030, T-034) : contrôle direct, sélection multiple, ordres de groupe et
## modification individuelle ensuite. Utilisées par l'interface, l'IA et, plus tard, le réseau.
## Règles : chaque pays ne commande que ses unités (T-029 C) ; une unité en déroute n'est pas
## contrôlable (T-039) ; l'exécution (tir, mouvements, tâches répétitives) est automatique.
## Chaque fonction renvoie "" si la commande est appliquée, sinon le motif du refus.


static func _check_units(b: Dictionary, nation: String, units: Array, allow_reserve: bool = false) -> String:
	if b["status"] != "active":
		return "bataille terminée"
	if units.is_empty():
		return "aucune unité sélectionnée"
	for uid: String in units:
		var u: Dictionary = b["units"].get(uid, {})
		if u.is_empty():
			return "unité inconnue : %s" % uid
		if u["nation"] != nation:
			return "commandement national : %s n'appartient pas à %s" % [u["name_fr"], nation]
		if u["status"] == CombatData.ROUTING:
			return "%s est en déroute : non contrôlable" % u["name_fr"]
		if u["status"] != CombatData.ACTIVE and not (allow_reserve and u["status"] == CombatData.RESERVE):
			return "%s n'est pas sur le champ de bataille" % u["name_fr"]
	return ""


static func set_formation(b: Dictionary, rules: Dictionary, nation: String, units: Array, formation: String) -> String:
	if not CombatData.FORMATIONS.has(formation):
		return "formation inconnue"
	var err := _check_units(b, nation, units)
	if err != "":
		return err
	for uid: String in units:
		b["units"][uid]["formation"] = formation
	return ""


## Ordre de groupe : le groupe conserve sa disposition relative autour du point visé.
static func move(b: Dictionary, rules: Dictionary, nation: String, units: Array, target: Vector2) -> String:
	var err := _check_units(b, nation, units)
	if err != "":
		return err
	var centroid := Vector2.ZERO
	for uid: String in units:
		centroid += CombatData.v(b["units"][uid]["pos"])
	centroid /= units.size()
	var w := float(b["field"]["w"])
	var h := float(b["field"]["h"])
	for uid: String in units:
		var u: Dictionary = b["units"][uid]
		var offset := CombatData.v(u["pos"]) - centroid if units.size() > 1 else Vector2.ZERO
		var dest := target + offset
		u["dest"] = CombatData.a(Vector2(clampf(dest.x, 0, w), clampf(dest.y, 0, h)))
		u["order"] = "move"
	return ""


static func hold(b: Dictionary, rules: Dictionary, nation: String, units: Array) -> String:
	var err := _check_units(b, nation, units)
	if err != "":
		return err
	for uid: String in units:
		b["units"][uid]["order"] = "hold"
		b["units"][uid]["dest"] = null
	return ""


## Charge contre une unité ennemie REPÉRÉE (brouillard) ; refusée aux unités désorganisées.
static func charge(b: Dictionary, rules: Dictionary, nation: String, units: Array, target: String) -> String:
	var err := _check_units(b, nation, units)
	if err != "":
		return err
	var side := TacticalSim.side_of_nation(b, nation)
	var t: Dictionary = b["units"].get(target, {})
	if t.is_empty() or t["side"] == side or not TacticalSim.is_visible_to(b, side, target):
		return "cible non repérée"
	for uid: String in units:
		if TacticalSim.is_disorganized(rules, b["units"][uid]):
			return "%s est désorganisée : charge impossible" % b["units"][uid]["name_fr"]
	for uid: String in units:
		var u: Dictionary = b["units"][uid]
		u["order"] = "charge"
		u["target"] = target
		u["charge_ticks"] = 40
		u["charge_contact"] = false
	return ""


## Tranchée : segment dessiné de a à b. L'étendue totale du réseau d'un camp est limitée par le
## nombre de soldats présents (T-033, T-040 C). Une nouvelle commande sur un segment existant
## l'approfondit (niveau +1).
static func build_trench(b: Dictionary, rules: Dictionary, nation: String, units: Array, pa: Vector2, pb: Vector2) -> String:
	var err := _check_units(b, nation, units)
	if err != "":
		return err
	var c: Dictionary = rules["construction"]
	var cfg: Dictionary = c["types"]["trench_segment"]
	var side := TacticalSim.side_of_nation(b, nation)
	var length := pa.distance_to(pb)
	if length < 20.0:
		return "segment trop court"
	var existing := {}
	var network := 0.0
	for t: Dictionary in b["defenses"]["trenches"]:
		if TacticalSim.side_of_nation(b, t["owner"]) == side:
			network += CombatData.v(t["a"]).distance_to(CombatData.v(t["b"]))
			if CombatData.v(t["a"]).distance_to(pa) < 10.0 and CombatData.v(t["b"]).distance_to(pb) < 10.0:
				existing = t
	var present := 0
	for uid: String in b["units"]:
		var u: Dictionary = b["units"][uid]
		if u["side"] == side and CombatData.is_on_field(u):
			present += int(u["soldiers"])
	var job: Dictionary
	if not existing.is_empty():
		if int(existing["target_level"]) >= int(cfg["max_level"]):
			return "niveau maximal atteint"
		existing["target_level"] = int(existing["target_level"]) + 1
		existing["complete"] = false
		job = existing
	else:
		if network + length > present * float(c["trench_capacity_per_soldier"]):
			return "réseau trop étendu pour les effectifs présents (%d / %d)" % [int(network + length), int(present * float(c["trench_capacity_per_soldier"]))]
		job = {"id": "trench_%s_%d" % [b["id"], (b["defenses"]["trenches"] as Array).size() + 1], "owner": nation,
			"a": CombatData.a(pa), "b": CombatData.a(pb), "site": CombatData.a((pa + pb) / 2.0), "level": 0, "target_level": 1,
			"progress": 0.0, "work_needed": length / 100.0 * float(cfg["work_per_100_length"]), "complete": false, "condition": 1.0}
		(b["defenses"]["trenches"] as Array).append(job)
	for uid: String in units:
		b["units"][uid]["order"] = "build"
		b["units"][uid]["build"] = job["id"]
	return ""


static func build_installation(b: Dictionary, rules: Dictionary, nation: String, units: Array, kind: String, pos: Vector2) -> String:
	if not CombatData.INSTALLATIONS.has(kind):
		return "installation inconnue"
	var err := _check_units(b, nation, units)
	if err != "":
		return err
	var cfg: Dictionary = rules["construction"]["types"][kind]
	var job := {"id": "inst_%s_%d" % [b["id"], (b["defenses"]["installations"] as Array).size() + 1], "type": kind, "owner": nation,
		"pos": CombatData.a(pos), "site": CombatData.a(pos), "progress": 0.0, "work_needed": float(cfg["work"]),
		"complete": false, "condition": 1.0}
	(b["defenses"]["installations"] as Array).append(job)
	for uid: String in units:
		b["units"][uid]["order"] = "build"
		b["units"][uid]["build"] = job["id"]
	return ""


## Engagement des réserves (T-040 B) : arrivée après un délai, jamais instantanée.
static func commit_reserve(b: Dictionary, rules: Dictionary, nation: String, units: Array) -> String:
	for uid: String in units:
		var u: Dictionary = b["units"].get(uid, {})
		if u.is_empty() or u["nation"] != nation:
			return "commandement national"
		if u["status"] != CombatData.RESERVE:
			return "%s n'est pas en réserve" % u.get("name_fr", uid)
	var delay := int(ceil(float(rules["reinforcements"]["reserve_delay_minutes"]) * 60.0 / float(rules["tick_seconds"])))
	for uid: String in units:
		var u: Dictionary = b["units"][uid]
		u["status"] = CombatData.ARRIVING
		u["arrive_tick"] = int(b["tick"]) + delay
	return ""


## Appel d'un renfort voisin (T-040 A) : délai calculé à la création (distance, terrain, rail).
static func call_reinforcement(b: Dictionary, rules: Dictionary, nation: String, uid: String) -> String:
	var u: Dictionary = b["units"].get(uid, {})
	if u.is_empty() or u["nation"] != nation:
		return "commandement national"
	if u["status"] != CombatData.AVAILABLE:
		return "renfort non disponible"
	var arrive := int(b["tick"]) + int(u["eta_ticks"])
	if arrive >= int(b["max_ticks"]):
		return "arriverait après la fin de la bataille"
	var side_units := 0
	for id: String in b["units"]:
		var x: Dictionary = b["units"][id]
		if x["side"] == u["side"] and x.get("reinforcement", false) and x["status"] != CombatData.AVAILABLE:
			side_units += 1
	if side_units >= int(rules["reinforcements"]["max_reinforcement_units_per_side"]):
		return "plafond de renforts atteint"
	u["status"] = CombatData.ARRIVING
	u["arrive_tick"] = arrive
	return ""


## Autorité opérationnelle (T-029 F) : seul le commandant général fixe l'objectif commun.
static func set_primary_objective(b: Dictionary, nation: String, objective_id: String) -> String:
	var side := TacticalSim.side_of_nation(b, nation)
	if side == "":
		return "pays non engagé"
	if b["sides"][side]["commander"]["nation"] != nation:
		return "seul le commandant général fixe l'objectif commun"
	for o: Dictionary in b["objectives"]:
		if o["id"] == objective_id:
			b["sides"][side]["primary_objective"] = objective_id
			return ""
	return "objectif inconnu"


## Rupture du combat en ordre (phase 6, étape 2) : décision du commandant général de son camp.
## Les unités actives se replient sans déroute ; la bataille s'achève peu après (disengage_ticks).
static func disengage(b: Dictionary, rules: Dictionary, nation: String) -> String:
	if b["status"] != "active":
		return "bataille terminée"
	var side := TacticalSim.side_of_nation(b, nation)
	if side == "":
		return "pays non engagé"
	if b["sides"][side]["commander"]["nation"] != nation:
		return "seul le commandant général peut rompre le combat"
	return Engagement.disengage(b, rules, side, "ordre du commandant")

