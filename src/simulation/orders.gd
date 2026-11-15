class_name Orders
extends RefCounted
## Ordres structurés : simples dictionnaires JSON, transmissibles et rejouables
## (préparation multijoueur). Ils sont préparés pendant le mois et résolus simultanément.

const MOVE := "move"
const DECLARE_WAR := "declare_war"
const PROPOSE_TREATY := "propose_treaty"
const RESPOND_PROPOSAL := "respond_proposal"
const BREAK_TREATY := "break_treaty"
const SEND_MESSAGE := "send_message"
const SET_INDUSTRY_ALLOCATION := "set_industry_allocation"
const BUILD_DEFENSE := "build_defense"

const TREATY_KINDS: PackedStringArray = ["alliance", "transit", "trade", "guarantee", "coalition", "peace"]
const CHANNELS: PackedStringArray = ["public", "private", "group"]


static func move(nation: String, formation: String, target: String) -> Dictionary:
	return {"type": MOVE, "nation": nation, "formation": formation, "target": target}


static func declare_war(nation: String, target: String) -> Dictionary:
	return {"type": DECLARE_WAR, "nation": nation, "target": target}


## Pour un traité de passage, `nation` demande le passage sur le territoire de `to`.
static func propose_treaty(nation: String, to: String, kind: String) -> Dictionary:
	return {"type": PROPOSE_TREATY, "nation": nation, "to": to, "kind": kind}


static func respond(nation: String, proposal_id: String, accept: bool) -> Dictionary:
	return {"type": RESPOND_PROPOSAL, "nation": nation, "proposal": proposal_id, "accept": accept}


static func break_treaty(nation: String, treaty_id: String) -> Dictionary:
	return {"type": BREAK_TREATY, "nation": nation, "treaty": treaty_id}


static func message(nation: String, channel: String, to: Array, text: String) -> Dictionary:
	return {"type": SEND_MESSAGE, "nation": nation, "channel": channel, "to": to, "text": text}


## Ouvrage défensif hors bataille ; coordonnées dans le cadre tactique de la région.
static func build_trench(nation: String, region: String, a: Vector2, b: Vector2) -> Dictionary:
	return {"type": BUILD_DEFENSE, "nation": nation, "region": region, "kind": "trench_segment",
		"a": [a.x, a.y], "b": [b.x, b.y]}


static func build_installation(nation: String, region: String, kind: String, pos: Vector2) -> Dictionary:
	return {"type": BUILD_DEFENSE, "nation": nation, "region": region, "kind": kind, "pos": [pos.x, pos.y]}


static func industry_allocation(nation: String, allocation: Dictionary) -> Dictionary:
	return {"type": SET_INDUSTRY_ALLOCATION, "nation": nation, "allocation": allocation}
