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
const MOBILIZE := "mobilize"  # alias conservé : posture générale
const SET_MOBILIZATION_POSTURE := "set_mobilization_posture"
const SET_MOBILIZATION_ALLOCATION := "set_mobilization_allocation"
const CALL_NEXT_ECHELON := "call_next_echelon"

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


## Mobilisation générale (MIL-01/02) : alias de la posture « generale » (T-053).
static func mobilize(nation: String) -> Dictionary:
	return {"type": MOBILIZE, "nation": nation, "posture": "generale"}


## Posture de mobilisation (T-053, Q2) : "paix", "preparatoire" ou "generale". Changement PUBLIC (T-056).
static func mobilization_posture(nation: String, posture: String) -> Dictionary:
	return {"type": SET_MOBILIZATION_POSTURE, "nation": nation, "posture": posture}


## Allocation des moyens de mobilisation (T-053) : pourcentages entiers de somme 100, sans coût économique.
static func mobilization_allocation(nation: String, administration: int, rail: int, logistics: int) -> Dictionary:
	return {"type": SET_MOBILIZATION_ALLOCATION, "nation": nation,
		"allocation": {"administration": administration, "rail": rail, "logistics": logistics}}


## Ouverture de l'échelon suivant (T-051, Q10) : posture générale, échelon en cours épuisé, délai écoulé.
static func call_next_echelon(nation: String) -> Dictionary:
	return {"type": CALL_NEXT_ECHELON, "nation": nation}


static func industry_allocation(nation: String, allocation: Dictionary) -> Dictionary:
	return {"type": SET_INDUSTRY_ALLOCATION, "nation": nation, "allocation": allocation}
