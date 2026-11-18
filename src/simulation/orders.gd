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
const TERRITORIAL_OVERSEAS := "territorial_overseas"
const SET_DEFENSIVE_POSTURE := "set_defensive_posture"  # phase 6, étape 2 (T-055)
# Phase III — diplomatie active
const PROPOSE_AGREEMENT := "propose_agreement"
const RESPOND_AGREEMENT := "respond_agreement"
const WITHDRAW_PROPOSAL := "withdraw_proposal"
const START_CRISIS := "start_crisis"
const CRISIS_RESPONSE := "crisis_response"
const OFFER_MEDIATION := "offer_mediation"
const PROPOSE_PEACE := "propose_peace"
const EXCHANGE_POW := "exchange_pow"
const JOIN_ALLIANCE := "join_alliance"
const LEAVE_ALLIANCE := "leave_alliance"
const DISSOLVE_ALLIANCE := "dissolve_alliance"
const UNIVERSAL_PACT := "universal_pact"
const CONCLUDE_CONFERENCE := "conclude_conference"

const TREATY_KINDS: PackedStringArray = ["alliance", "transit", "trade", "guarantee", "coalition", "peace"]
const CHANNELS: PackedStringArray = ["public", "private", "group"]


## `approach` (T-055, phase 6 étape 2) : approche offensive si le déplacement provoque une bataille
## ("reconnaissance", "limited_attack" ou "assault") ; vide = assaut (défaut).
static func move(nation: String, formation: String, target: String, approach: String = "") -> Dictionary:
	var o := {"type": MOVE, "nation": nation, "formation": formation, "target": target}
	if approach != "":
		o["approach"] = approach
	return o


## Posture défensive permanente d'une armée (T-055) : "delay", "hold" ou "hold_at_all_costs".
static func defensive_posture(nation: String, army: String, posture: String) -> Dictionary:
	return {"type": SET_DEFENSIVE_POSTURE, "nation": nation, "army": army, "posture": posture}


static func declare_war(nation: String, target: String) -> Dictionary:
	return {"type": DECLARE_WAR, "nation": nation, "target": target}


## Pour un traité de passage, `nation` demande le passage sur le territoire de `to`.
static func propose_treaty(nation: String, to: String, kind: String) -> Dictionary:
	return {"type": PROPOSE_TREATY, "nation": nation, "to": to, "kind": kind}


static func respond(nation: String, proposal_id: String, accept: bool) -> Dictionary:
	return {"type": RESPOND_PROPOSAL, "nation": nation, "proposal": proposal_id, "accept": accept}


static func break_treaty(nation: String, treaty_id: String) -> Dictionary:
	return {"type": BREAK_TREATY, "nation": nation, "treaty": treaty_id}


static func propose_agreement(nation: String, to: Array, kind: String, terms: Dictionary = {}, channel: String = "private") -> Dictionary:
	return {"type": PROPOSE_AGREEMENT, "nation": nation, "to": to, "kind": kind,
		"terms": terms.duplicate(true), "channel": channel}


static func respond_agreement(nation: String, proposal: String, accept: bool, counter_terms: Dictionary = {}) -> Dictionary:
	return {"type": RESPOND_AGREEMENT, "nation": nation, "proposal": proposal,
		"accept": accept, "counter_terms": counter_terms.duplicate(true)}


static func withdraw_proposal(nation: String, proposal: String) -> Dictionary:
	return {"type": WITHDRAW_PROPOSAL, "nation": nation, "proposal": proposal}


static func start_crisis(nation: String, target: String, motive: String, stake: String) -> Dictionary:
	return {"type": START_CRISIS, "nation": nation, "target": target, "motive": motive, "stake": stake}


static func crisis_response(nation: String, crisis: String, action: String) -> Dictionary:
	return {"type": CRISIS_RESPONSE, "nation": nation, "crisis": crisis, "action": action}


static func offer_mediation(nation: String, crisis: String) -> Dictionary:
	return {"type": OFFER_MEDIATION, "nation": nation, "crisis": crisis}


static func propose_peace(nation: String, to: Array, terms: Dictionary = {}) -> Dictionary:
	return {"type": PROPOSE_PEACE, "nation": nation, "to": to, "terms": terms.duplicate(true)}


static func exchange_pow(nation: String, other: String) -> Dictionary:
	return {"type": EXCHANGE_POW, "nation": nation, "other": other}


static func join_alliance(nation: String, alliance: String) -> Dictionary:
	return {"type": JOIN_ALLIANCE, "nation": nation, "alliance": alliance}


static func leave_alliance(nation: String, alliance: String) -> Dictionary:
	return {"type": LEAVE_ALLIANCE, "nation": nation, "alliance": alliance}


static func dissolve_alliance(nation: String, alliance: String) -> Dictionary:
	return {"type": DISSOLVE_ALLIANCE, "nation": nation, "alliance": alliance}


static func universal_pact(nation: String, members: Array) -> Dictionary:
	return {"type": UNIVERSAL_PACT, "nation": nation, "members": members}


static func conclude_conference(nation: String, conference: String, topic: String) -> Dictionary:
	return {"type": CONCLUDE_CONFERENCE, "nation": nation, "conference": conference, "topic": topic}


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


## Territorial Force (T-054) : les volontaires d'une armée de la Territorial Force acceptent le service outre-mer.
static func territorial_overseas(nation: String, army: String) -> Dictionary:
	return {"type": TERRITORIAL_OVERSEAS, "nation": nation, "army": army}
