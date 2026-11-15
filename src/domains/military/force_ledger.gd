class_name ForceLedger
extends RefCounted
## Comptabilité nationale des effectifs sortis des unités (MIL-01, phase 2 ; décision Q6 du directeur).
##
## Chaque soldat qui quitte définitivement une unité est inscrit ICI, une seule fois :
##   - pertes de combat (bataille tactique : différence d'effectif avant / après la bataille) ;
##   - pertes d'attrition d'une armée encerclée (T-044) ;
##   - services (non-combattants) d'une armée anéantie ;
##   - prisonniers : armée encerclée qui capitule (T-044), comptés chez le pays d'origine
##     (« prisonniers perdus ») et chez le pays détenteur (« prisonniers détenus »).
##
## LIMITES DOCUMENTÉES (aucune mécanique inventée) :
##   - la simulation tactique ne distingue PAS les tués, les blessés et les disparus : les pertes de
##     combat sont « non ventilées ». `dead` et `wounded` valent null (« non modélisé ») ; aucun ratio
##     n'est appliqué. Les blessés ne reviennent donc pas encore dans les unités (évolution à définir) ;
##   - aucun mécanisme de libération, d'échange ou de rapatriement de prisonniers n'existe :
##     `released` et `repatriated` restent à 0.
##
## Invariant de personnel vérifié par les tests (nation historique, carte seulement) :
##   présents (unités + services) + pertes + prisonniers perdus = actifs sur la carte + incorporés.

const CAUSES := ["combat", "encirclement_attrition", "annihilated_services"]


static func ledger(state: GameState, nation: String) -> Dictionary:
	var n: Dictionary = state.nations[nation]
	if not n.has("military_ledger"):
		n["military_ledger"] = {
			"losses": {"combat": 0, "encirclement_attrition": 0, "annihilated_services": 0},
			"losses_total": 0,
			"losses_status": "Pertes NON VENTILÉES : la simulation ne distingue pas tués, blessés et disparus.",
			"dead": null, "wounded": null, "missing": null,
			"breakdown_status": "non modélisé (aucun ratio inventé) ; voir docs/military/PERTES_ET_PRISONNIERS.md",
			"prisoners_lost": 0, "prisoners_lost_by_captor": {},
			"prisoners_held": 0, "prisoners_held_by_origin": {},
			"released": 0, "repatriated": 0,
			"release_status": "aucun mécanisme de libération ni de rapatriement (évolution documentée)",
		}
	return n["military_ledger"]


static func add_losses(state: GameState, nation: String, amount: int, cause: String) -> void:
	if amount <= 0 or not state.nations.has(nation):
		return
	assert(cause in CAUSES)
	var l := ledger(state, nation)
	l["losses"][cause] = int(l["losses"][cause]) + amount
	l["losses_total"] = int(l["losses_total"]) + amount


static func add_prisoners(state: GameState, nation: String, captor: String, amount: int) -> void:
	if amount <= 0 or not state.nations.has(nation):
		return
	var l := ledger(state, nation)
	l["prisoners_lost"] = int(l["prisoners_lost"]) + amount
	l["prisoners_lost_by_captor"][captor] = int(l["prisoners_lost_by_captor"].get(captor, 0)) + amount
	if state.nations.has(captor):
		var c := ledger(state, captor)
		c["prisoners_held"] = int(c["prisoners_held"]) + amount
		c["prisoners_held_by_origin"][nation] = int(c["prisoners_held_by_origin"].get(nation, 0)) + amount


## Personnel d'une formation et de ses subordonnées : soldats des unités et services des divisions.
## null si un effectif est inconnu (États hors MIL-01) : rien n'est alors comptabilisé.
static func personnel_of(state: GameState, fid: String) -> Variant:
	var total := 0
	for id: String in [fid] + state.descendants(fid):
		var f: Dictionary = state.formations[id]
		if f["echelon"] == "unit":
			if f.get("soldiers") == null:
				return null
			total += int(f["soldiers"])
		total += int(f.get("services_soldiers", 0))
	return total


## Retire une formation en inscrivant son personnel restant : `fate` = "prisoners" (capitulation,
## détenteur `captor`) ou "losses" (armée anéantie : services restants, cause `cause`).
static func remove_formation_booked(state: GameState, fid: String, fate: String, captor: String = "", cause: String = "annihilated_services") -> void:
	if not state.formations.has(fid):
		return
	var nation: String = state.formations[fid]["nation"]
	var people: Variant = personnel_of(state, fid)
	if people != null:
		if fate == "prisoners":
			add_prisoners(state, nation, captor, int(people))
		else:
			add_losses(state, nation, int(people), cause)
	state.remove_formation(fid)


static func normalize(state: GameState) -> void:
	for nid: String in state.nations:
		var l: Variant = state.nations[nid].get("military_ledger")
		if l == null:
			continue
		for k: String in l["losses"]:
			l["losses"][k] = int(l["losses"][k])
		for k: String in ["losses_total", "prisoners_lost", "prisoners_held", "released", "repatriated"]:
			l[k] = int(l[k])
		for d: String in ["prisoners_lost_by_captor", "prisoners_held_by_origin"]:
			for k: String in l[d]:
				l[d][k] = int(l[d][k])
