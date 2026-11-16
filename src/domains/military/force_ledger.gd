class_name ForceLedger
extends RefCounted
## Comptabilité nationale des pertes militaires (MIL-01 ; phase 2, puis phase 6 étape 1).
##
## Phase 6, étape 1 (décisions du directeur) : les pertes produites par le combat sont VENTILÉES,
## sans aucun nouveau calcul de pertes ni changement de leur volume :
##   - tués (définitifs) ;
##   - blessés : légers restés dans leur unité (présents) ; en convalescence (1 mois pour les légers,
##     3 mois pour les autres) ; rendus au service (redeviennent présents, jamais recomptés comme
##     nouveaux soldats) ; définitivement inaptes ; le reste demeure en convalescence de longue durée ;
##   - disparus (catégorie distincte, jamais convertie automatiquement), par cause ;
##   - prisonniers : chez l'origine (perdus) et chez le détenteur (détenus), jamais deux fois dans
##     les présents de quiconque.
## Paramètres : data/rules/forces_rules.json, bloc `casualties` (statuts sourcé / PROVISOIRE,
## modifiables par pays dans `national_overrides`). Les règles et le volume des pertes de combat ne
## sont PAS modifiés (data/rules/combat_rules.json inchangé).
##
## Invariant de personnel (nation historique, carte seulement) :
##   présents (unités + services) + tués + en convalescence + inaptes + disparus + prisonniers perdus
##   + pertes non ventilées héritées d'une ancienne sauvegarde
##   = actifs sur la carte + réservistes incorporés + Territorial Force incorporée.

const LEDGER_VERSION := 2
const MISSING_CAUSES := ["battle", "encirclement_attrition", "annihilated_services"]

static var config: Dictionary = {}


## Paramètres de ventilation (bloc `casualties` de forces_rules.json), chargés par GameSession.
static func configure(casualties: Dictionary) -> void:
	config = casualties


static func cfg() -> Dictionary:
	if config.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rules/forces_rules.json"))
		if data is Dictionary:
			config = data.get("casualties", {})
	return config


## Valeur d'un paramètre, avec dérogation nationale éventuelle.
static func param(nation: String, key: String) -> float:
	var c := cfg()
	var over: Dictionary = c.get("national_overrides", {}).get(nation, {})
	if over.has(key):
		return float(over[key]["value"])
	return float(c[key]["value"])


static func _new_ledger() -> Dictionary:
	return {
		"version": LEDGER_VERSION,
		"killed": 0,
		"wounded": {"remained_in_unit": 0, "convalescing": 0, "long_term": 0, "returned": 0, "unfit": 0},
		"convalescence": [],
		"missing": {"battle": 0, "encirclement_attrition": 0, "annihilated_services": 0},
		"missing_total": 0,
		"prisoners_lost": 0, "prisoners_lost_by_captor": {},
		"prisoners_held": 0, "prisoners_held_by_origin": {},
		"released": 0, "repatriated": 0,
		"release_status": "aucun mécanisme de libération ni de rapatriement (évolution ultérieure)",
		"rejoined": 0,
		"legacy_unventilated": 0,
		# Origine tactique des pertes de bataille ventilées (traçabilité ; ne s'additionne pas aux catégories).
		"losses_by_origin": {"fire": 0, "routing": 0, "remnant": 0, "routing_as_ordinary": 0},
	}


static func ledger(state: GameState, nation: String) -> Dictionary:
	var n: Dictionary = state.nations[nation]
	if not n.has("military_ledger"):
		n["military_ledger"] = _new_ledger()
	return n["military_ledger"]


## Total des hommes hors des rangs inscrits ici (pour l'invariant et l'affichage).
static func out_of_ranks(l: Dictionary) -> int:
	if l.is_empty():
		return 0
	var w: Dictionary = l["wounded"]
	return int(l["killed"]) + int(w["convalescing"]) + int(w["long_term"]) + int(w["unfit"]) + int(l["missing_total"]) \
		+ int(l["prisoners_lost"]) + int(l.get("legacy_unventilated", 0))


static func add_missing(state: GameState, nation: String, amount: int, cause: String) -> void:
	if amount <= 0 or not state.nations.has(nation):
		return
	assert(cause in MISSING_CAUSES)
	var l := ledger(state, nation)
	l["missing"][cause] = int(l["missing"][cause]) + amount
	l["missing_total"] = int(l["missing_total"]) + amount


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


## Ventilation des pertes d'UNE unité à la clôture d'une bataille, selon leur ORIGINE tactique :
##   `fire`    : pertes au feu et en mêlée hors déroute ;
##   `routing` : pertes subies pendant une déroute (unité qui survit ou non) ;
##   `remnant` : reliquat d'une unité réellement anéantie (effectif mis à zéro par le combat).
## `outcome` (issue de la bataille pour l'armée de l'unité) : "won" (camp vainqueur, qui conserve le
## terrain), "indecisive", "lost_retreat" ou "lost_no_retreat" (camp vaincu, avec ou sans retraite sûre).
## Correction du directeur (solution A) : les pertes de déroute d'un camp VAINQUEUR sont ventilées comme
## des pertes ordinaires (tués, blessés, disparus aux parts du feu) ; leur origine reste inscrite à part.
## Dans les autres cas, les pertes de déroute sont disparues ou prisonnières (part de capture selon
## l'issue : aucune capture sans défaite). Le reliquat d'une unité anéantie garde son traitement distinct.
## Retourne la ventilation (entiers) ; la somme killed + wounded + missing + prisoners vaut exactement
## `fire + routing + remnant` : aucun soldat créé ni perdu. `remained` est inclus dans `wounded`.
static func book_battle_losses(state: GameState, nation: String, captor: String, fire: int, routing: int, remnant: int,
		outcome: String, unit_survives: bool, origin_region: String) -> Dictionary:
	var out := {"killed": 0, "wounded": 0, "remained": 0, "missing": 0, "prisoners": 0,
		"origin_fire": 0, "origin_routing": 0, "origin_remnant": 0, "routing_as_ordinary": 0}
	if fire + routing + remnant <= 0 or not state.nations.has(nation):
		return out
	var c := cfg()
	var share := float(c["rout_prisoner_share"][outcome]["value"])
	# 1. Pertes ordinaires : feu, et déroute d'un camp vainqueur (origine conservée à part).
	# Unité anéantie d'un camp vainqueur : ses pertes de déroute ne sont ordinaires que si le paramètre
	# `annihilated_unit_routing_as_ordinary` le permet (choix à valider) ; son reliquat reste à part.
	var eligible := unit_survives or bool(cfg().get("annihilated_unit_routing_as_ordinary", {}).get("value", true))
	var routing_ordinary := routing if outcome in routing_ordinary_outcomes() and eligible else 0
	var a := _split_ordinary(nation, fire)
	var b := _split_ordinary(nation, routing_ordinary)
	var killed: int = a[0] + b[0]
	var missing: int = a[1] + b[1]
	var wounded: int = a[2] + b[2]
	# 2. Autres pertes de déroute, puis reliquat d'unité anéantie : prisonniers (capture établie par la
	#    défaite seulement) ou disparus. Arrondis séparés : chaque origine reste traçable.
	var prisoners := 0
	for n: int in [routing - routing_ordinary, remnant]:
		var p := int(round(float(n) * share))
		prisoners += p
		missing += n - p
	# 3. Blessés : légers restés dans l'unité (si elle existe encore), légers et autres en convalescence.
	var light := int(round(float(wounded) * param(nation, "light_wound_share")))
	var remained := int(floor(float(light) * param(nation, "remain_in_unit_share_of_light"))) if unit_survives else 0
	var light_conv := light - remained
	var other_conv := wounded - light
	var l := ledger(state, nation)
	l["killed"] = int(l["killed"]) + killed
	l["wounded"]["remained_in_unit"] = int(l["wounded"]["remained_in_unit"]) + remained
	_add_convalescence(state, l, nation, light_conv, int(param(nation, "convalescence_months_light")), "light", origin_region)
	_add_convalescence(state, l, nation, other_conv, int(param(nation, "convalescence_months_other")), "other", origin_region)
	add_missing(state, nation, missing, "battle")
	if prisoners > 0:
		add_prisoners(state, nation, captor, prisoners)
	if not l.has("losses_by_origin"):
		l["losses_by_origin"] = {"fire": 0, "routing": 0, "remnant": 0, "routing_as_ordinary": 0}
	var o: Dictionary = l["losses_by_origin"]
	o["fire"] = int(o["fire"]) + fire
	o["routing"] = int(o["routing"]) + routing
	o["remnant"] = int(o["remnant"]) + remnant
	o["routing_as_ordinary"] = int(o["routing_as_ordinary"]) + routing_ordinary
	out = {"killed": killed, "wounded": wounded, "remained": remained, "missing": missing, "prisoners": prisoners,
		"origin_fire": fire, "origin_routing": routing, "origin_remnant": remnant, "routing_as_ordinary": routing_ordinary}
	return out


## Issues pour lesquelles les pertes de déroute sont des pertes ordinaires (décision : camp vainqueur).
static func routing_ordinary_outcomes() -> Array:
	return cfg().get("routing_as_ordinary_outcomes", {}).get("value", ["won"])


## Pertes ordinaires : [tués, disparus, blessés] aux parts du feu ; somme exactement égale à `n`.
static func _split_ordinary(nation: String, n: int) -> Array:
	if n <= 0:
		return [0, 0, 0]
	var killed := int(round(float(n) * param(nation, "killed_share")))
	var missing := mini(n - killed, int(round(float(n) * param(nation, "missing_share_fire"))))
	return [killed, missing, n - killed - missing]


static func _add_convalescence(state: GameState, l: Dictionary, nation: String, n: int, months: int, kind: String, region: String) -> void:
	if n <= 0:
		return
	(l["convalescence"] as Array).append({"soldiers": n, "return_turn": state.turn + months, "kind": kind, "region": region})
	l["wounded"]["convalescing"] = int(l["wounded"]["convalescing"]) + n


## Étape mensuelle : fin de convalescence. Part rendue au service (redevient présente par le chemin
## d'incorporation, SANS compter de nouveau soldat), part définitivement inapte, reste en convalescence
## de longue durée. Les puissances sans réserves modélisées (bac à sable, États hors MIL-01) gardent
## leurs convalescents (aucun mécanisme de retour pour elles).
static func monthly_recovery(state: GameState, world: WorldMap, rules: Dictionary) -> void:
	for nation: String in state.nation_order:
		var n: Dictionary = state.nations[nation]
		if not n.has("military_ledger") or not MobilizationSystem.is_historical(state, nation):
			continue
		var l: Dictionary = n["military_ledger"]
		var keep: Array = []
		var accessible := LogisticsSystem.accessible_regions(state, world, nation)
		for c: Dictionary in l["convalescence"]:
			if int(c["return_turn"]) > state.turn:
				keep.append(c)
				continue
			var soldiers := int(c["soldiers"])
			var back := int(floor(float(soldiers) * param(nation, "return_share")))
			var unfit := mini(soldiers - back, int(floor(float(soldiers) * param(nation, "unfit_share"))))
			var dest := MobilizationSystem.communication(state, world, nation, c["region"], accessible) if state.regions.has(c["region"]) else ""
			if dest == "":
				dest = n["capital_region_id"] if accessible.has(n["capital_region_id"]) else ""
			if back > 0 and (dest == "" or MobilizationSystem._region_has_battle(state, dest)):
				keep.append(c)  # aucune région d'accueil (ou bataille en cours, Q8) : la convalescence se prolonge
				continue
			l["wounded"]["convalescing"] = int(l["wounded"]["convalescing"]) - soldiers
			l["wounded"]["unfit"] = int(l["wounded"]["unfit"]) + unfit
			l["wounded"]["long_term"] = int(l["wounded"]["long_term"]) + (soldiers - back - unfit)
			if back > 0:
				l["wounded"]["returned"] = int(l["wounded"]["returned"]) + back
				MobilizationSystem.incorporate(state, rules, nation, dest, back, true, true, false)
				state.log_event("pertes", "%s : %d blessés guéris rejoignent le service (%s)." % [n["name_fr"], back, dest], [nation])
		l["convalescence"] = keep


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
## détenteur `captor`) ou "missing" (armée anéantie sans retraite : sort inconnu, cause `cause`).
static func remove_formation_booked(state: GameState, fid: String, fate: String, captor: String = "", cause: String = "annihilated_services") -> void:
	if not state.formations.has(fid):
		return
	var nation: String = state.formations[fid]["nation"]
	var people: Variant = personnel_of(state, fid)
	if people != null:
		if fate == "prisoners":
			add_prisoners(state, nation, captor, int(people))
		else:
			add_missing(state, nation, int(people), cause)
	state.remove_formation(fid)


## Survivants (services) d'une armée anéantie qui rejoignent leur territoire (MIL01-P2-D2).
static func rejoin_and_remove(state: GameState, fid: String) -> void:
	var nation: String = state.formations[fid]["nation"]
	var people: Variant = personnel_of(state, fid)
	var forces: Dictionary = state.nations[nation].get("forces", {})
	if people != null and int(people) > 0 and forces.get("source_type", "") == "historical":
		forces["services_regrouped"] = int(forces.get("services_regrouped", 0)) + int(people)
		var l := ledger(state, nation)
		l["rejoined"] = int(l["rejoined"]) + int(people)
	state.remove_formation(fid)


## Migration d'un registre de la phase 2 (sauvegarde de format 3) : les pertes de combat « non
## ventilées » ne peuvent pas être ventilées après coup ; elles sont conservées telles quelles dans
## `legacy_unventilated`. Les pertes de sort inconnu (attrition d'encerclement, services d'armées
## anéanties) deviennent des disparus avec leur cause. Prisonniers et survivants inchangés.
static func migrate_v1(l: Dictionary) -> Dictionary:
	var m := _new_ledger()
	var losses: Dictionary = l.get("losses", {})
	m["legacy_unventilated"] = int(losses.get("combat", 0))
	for cause: String in ["encirclement_attrition", "annihilated_services"]:
		m["missing"][cause] = int(losses.get(cause, 0))
		m["missing_total"] = int(m["missing_total"]) + int(losses.get(cause, 0))
	for k: String in ["prisoners_lost", "prisoners_held", "released", "repatriated", "rejoined"]:
		m[k] = int(l.get(k, 0))
	for d: String in ["prisoners_lost_by_captor", "prisoners_held_by_origin"]:
		m[d] = (l.get(d, {}) as Dictionary).duplicate()
	return m


static func migrate_state(state: GameState) -> void:
	for nid: String in state.nations:
		var l: Variant = state.nations[nid].get("military_ledger")
		if l != null and int(l.get("version", 1)) < LEDGER_VERSION:
			state.nations[nid]["military_ledger"] = migrate_v1(l)


static func normalize(state: GameState) -> void:
	for nid: String in state.nations:
		var l: Variant = state.nations[nid].get("military_ledger")
		if l == null or int(l.get("version", 1)) < LEDGER_VERSION:
			continue
		for k: String in ["version", "killed", "missing_total", "prisoners_lost", "prisoners_held", "released", "repatriated", "rejoined", "legacy_unventilated"]:
			l[k] = int(l.get(k, 0))
		for k: String in l["wounded"]:
			l["wounded"][k] = int(l["wounded"][k])
		# Registres v2 écrits avant la correction de l'étape 1 : origine non enregistrée (zéros).
		var o: Dictionary = l.get("losses_by_origin", {})
		for k: String in ["fire", "routing", "remnant", "routing_as_ordinary"]:
			o[k] = int(o.get(k, 0))
		l["losses_by_origin"] = o
		for k: String in l["missing"]:
			l["missing"][k] = int(l["missing"][k])
		for d: String in ["prisoners_lost_by_captor", "prisoners_held_by_origin"]:
			for k: String in l[d]:
				l[d][k] = int(l[d][k])
		for c: Dictionary in l["convalescence"]:
			c["soldiers"] = int(c["soldiers"])
			c["return_turn"] = int(c["return_turn"])
