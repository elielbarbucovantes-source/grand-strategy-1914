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
const PROPOSE_UNIVERSAL := "propose_universal"
const RESPOND_UNIVERSAL := "respond_universal"
const WITHDRAW_UNIVERSAL := "withdraw_universal"
const CONCLUDE_CONFERENCE := "conclude_conference"
# Phase IV — infrastructures
const DISRUPT_LINK := "disrupt_link"
const REPAIR_LINK := "repair_link"
const SET_PORT_STATUS := "set_port_status"
# Phase V — économie
const TRADE := "trade"
const APPROVE_TRADE := "approve_trade"
const INVEST_RESOURCE := "invest_resource"
# Phase VI
const SET_RESEARCH := "set_research"
const SET_COMMS_PROTECTION := "set_comms_protection"
const INTERCEPT := "intercept"
const AIR_RECON := "air_recon"
const BUILD_AIRBASE := "build_airbase"
const PRODUCE_AIRCRAFT := "produce_aircraft"
const CREATE_FLEET := "create_fleet"
const NAVAL_OPERATION := "naval_operation"
# Phase VII
const POLITICAL_DECISION := "political_decision"
const CHANGE_GOVERNMENT := "change_government"
const SET_BRIDGE_STATUS := "set_bridge_status"
const MP_SETUP := "mp_setup"
const MP_SUBMIT_ORDER := "mp_submit_order"
const MP_DISCONNECT := "mp_disconnect"
const MP_RECONNECT := "mp_reconnect"

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


static func propose_universal(nation: String) -> Dictionary:
	return {"type": PROPOSE_UNIVERSAL, "nation": nation}


static func respond_universal(nation: String, accept: bool) -> Dictionary:
	return {"type": RESPOND_UNIVERSAL, "nation": nation, "accept": accept}


static func withdraw_universal(nation: String) -> Dictionary:
	return {"type": WITHDRAW_UNIVERSAL, "nation": nation}


static func conclude_conference(nation: String, conference: String, topic: String) -> Dictionary:
	return {"type": CONCLUDE_CONFERENCE, "nation": nation, "conference": conference, "topic": topic}


static func disrupt_link(nation: String, link: String, condition: String = "interrupted") -> Dictionary:
	return {"type": DISRUPT_LINK, "nation": nation, "link": link, "condition": condition}


static func repair_link(nation: String, link: String, turns: int = 2) -> Dictionary:
	return {"type": REPAIR_LINK, "nation": nation, "link": link, "turns": turns}


static func set_port_status(nation: String, port: String, status: String) -> Dictionary:
	return {"type": SET_PORT_STATUS, "nation": nation, "port": port, "status": status}


## RESTORATION/STABILIZATION : `nation` est TOUJOURS l'exportateur. Le consentement est
## enregistré dans l'état (voir MarketSystem.approve_trade) avant tout transfert.
static func trade(nation: String, from: String, to: String, resource: String, amount: float) -> Dictionary:
	return {"type": TRADE, "nation": nation, "from": from, "to": to, "resource": resource, "amount": amount}


## Consentement explicite de l'exportateur pour une transaction identifiée.
static func approve_trade(nation: String, transaction: String) -> Dictionary:
	return {"type": APPROVE_TRADE, "nation": nation, "transaction": transaction}


static func invest_resource(nation: String, region: String, resource: String, amount: float) -> Dictionary:
	return {"type": INVEST_RESOURCE, "nation": nation, "region": region, "resource": resource, "amount": amount}


static func set_research(nation: String, tech: String) -> Dictionary:
	return {"type": SET_RESEARCH, "nation": nation, "tech": tech}


static func set_comms_protection(nation: String, level: int) -> Dictionary:
	return {"type": SET_COMMS_PROTECTION, "nation": nation, "level": level}


static func intercept(nation: String, target: String) -> Dictionary:
	return {"type": INTERCEPT, "nation": nation, "target": target}


static func air_recon(nation: String, region: String) -> Dictionary:
	return {"type": AIR_RECON, "nation": nation, "region": region}


static func build_airbase(nation: String, region: String) -> Dictionary:
	return {"type": BUILD_AIRBASE, "nation": nation, "region": region}


static func produce_aircraft(nation: String, kind: String, amount: int) -> Dictionary:
	return {"type": PRODUCE_AIRCRAFT, "nation": nation, "kind": kind, "amount": amount}


static func create_fleet(nation: String, port: String, composition: Dictionary) -> Dictionary:
	return {"type": CREATE_FLEET, "nation": nation, "port": port, "composition": composition.duplicate(true)}


static func naval_operation(nation: String, fleet: String, kind: String, zone: String) -> Dictionary:
	return {"type": NAVAL_OPERATION, "nation": nation, "fleet": fleet, "kind": kind, "zone": zone}


static func political_decision(nation: String, kind: String) -> Dictionary:
	return {"type": POLITICAL_DECISION, "nation": nation, "kind": kind}


static func change_government(nation: String, kind: String) -> Dictionary:
	return {"type": CHANGE_GOVERNMENT, "nation": nation, "kind": kind}


static func set_bridge_status(bridge: String, status: String) -> Dictionary:
	return {"type": SET_BRIDGE_STATUS, "nation": "", "bridge": bridge, "status": status}


static func mp_setup(players: Dictionary) -> Dictionary:
	return {"type": MP_SETUP, "nation": "", "players": players.duplicate(true)}


static func mp_submit_order(player: String, order: Dictionary) -> Dictionary:
	return {"type": MP_SUBMIT_ORDER, "nation": player, "order": order.duplicate(true)}


static func mp_disconnect(player: String) -> Dictionary:
	return {"type": MP_DISCONNECT, "nation": player}


static func mp_reconnect(player: String) -> Dictionary:
	return {"type": MP_RECONNECT, "nation": player}


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
