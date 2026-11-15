class_name CombatData
extends RefCounted
## Constantes et utilitaires partagés du système de combat. Une bataille est un Dictionary
## JSON-compatible (sauvegarde en cours de bataille, rejeu, multijoueur).

const ATTACKERS := "attackers"
const DEFENDERS := "defenders"
const SIDES: PackedStringArray = ["attackers", "defenders"]

# Statuts d'unité tactique
const ACTIVE := "active"        # sur le champ de bataille, contrôlable
const ROUTING := "routing"      # en déroute : retraite automatique, non contrôlable (T-039)
const WITHDRAWN := "withdrawn"  # a quitté le champ (déroute achevée ou repli)
const DESTROYED := "destroyed"  # anéantie
const RESERVE := "reserve"      # réserve non engagée (T-040 B)
const ARRIVING := "arriving"    # renfort en route (T-040 A) ou réserve en cours d'engagement
const AVAILABLE := "available"  # renfort possible, non appelé

const FORMATIONS: PackedStringArray = ["skirmish_line", "assault_column", "entrenched"]
const INSTALLATIONS: PackedStringArray = ["machine_gun_nest", "artillery_position", "command_post"]


static func other(side: String) -> String:
	return DEFENDERS if side == ATTACKERS else ATTACKERS


static func v(p: Array) -> Vector2:
	return Vector2(float(p[0]), float(p[1]))


static func a(p: Vector2) -> Array:
	return [snappedf(p.x, 0.01), snappedf(p.y, 0.01)]


static func is_on_field(u: Dictionary) -> bool:
	return u["status"] == ACTIVE or u["status"] == ROUTING


static func can_fight(u: Dictionary) -> bool:
	return u["status"] == ACTIVE


## Unités sorted par identifiant (ordre déterministe).
static func unit_ids(battle: Dictionary) -> Array:
	var ids: Array = (battle["units"] as Dictionary).keys()
	ids.sort()
	return ids


## Rétablit les entiers après relecture JSON.
static func normalize_battle(b: Dictionary) -> void:
	for key in ["tick", "max_ticks", "turn", "order", "created_seq"]:
		if b.has(key) and b[key] != null:
			b[key] = int(b[key])
	for uid: String in b.get("units", {}):
		var u: Dictionary = b["units"][uid]
		for key in ["soldiers", "start_soldiers", "arrive_tick", "last_fire_tick", "quiet_ticks", "engaged_ticks", "charge_ticks"]:
			if u.has(key) and u[key] != null:
				u[key] = int(u[key])
	for side: String in b.get("fog", {}):
		for uid: String in b["fog"][side]:
			var m: Dictionary = b["fog"][side][uid]
			m["tick"] = int(m["tick"])
