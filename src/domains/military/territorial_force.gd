class_name TerritorialForce
extends RefCounted
## Territorial Force britannique (T-050, T-054 ; MIL-01 phase 4).
##
## Catégorie DISTINCTE, jamais confondue avec l'armée régulière ni avec les réserves :
##   - effectif propre : forces.territorial_force.pool_initial (268 777 au 1er août 1914, WO 1922 p. 30),
##     hors du réservoir (`echelons`) et hors de l'armée active (`active_start`) ;
##   - incorporation (« embodiment ») intégrale quand le pays adopte la posture générale, après un
##     transit propre (paramètre PROVISOIRE) ; jamais en posture préparatoire ;
##   - unités propres (`category = "territorial_force"`) dans des armées propres, au service INTÉRIEUR
##     (`service = "home"`) : elles ne peuvent pas quitter les régions de souveraineté nationale ;
##   - service outre-mer (T-054) : ordre de volontariat sur une armée de la Territorial Force, après
##     un délai minimal depuis l'incorporation ; les volontaires forment des unités `service = "overseas"`,
##     les autres restent en service intérieur.
## Invariant : non incorporés + en cours + bloqués + incorporés = effectif initial de la Territorial Force.
## Les unités de la Territorial Force sont comptées parmi les présents ; leurs pertes et prisonniers sont
## inscrits dans la comptabilité nationale (ForceLedger), comme pour toutes les unités.

const CATEGORY := "territorial_force"


static func block(state: GameState, nation: String) -> Variant:
	return state.nations[nation].get("forces", {}).get("territorial_force")


static func is_territorial(f: Dictionary) -> bool:
	return f.get("category", "") == CATEGORY


static func tfp(rules: Dictionary, key: String) -> float:
	return float(rules["territorial_force"][key]["value"])


## Étape mensuelle, appelée par MobilizationSystem.monthly (après la mobilisation des réserves).
static func monthly(state: GameState, world: WorldMap, rules: Dictionary, nation: String, accessible: Dictionary) -> void:
	var tf: Variant = block(state, nation)
	if tf == null:
		return
	var f: Dictionary = state.nations[nation]["forces"]
	_unblock(state, world, nation, tf, accessible)
	_incorporate_ready(state, world, rules, nation, tf, accessible)
	if f["posture"] == rules["territorial_force"]["embodiment_posture"]:
		_embody(state, world, rules, nation, tf, accessible)


static func _embody(state: GameState, world: WorldMap, rules: Dictionary, nation: String, tf: Dictionary, accessible: Dictionary) -> void:
	var regions: Array = (tf["pool_by_region"] as Dictionary).keys()
	regions.sort()
	var called := 0
	for rid: String in regions:
		var pool := int(tf["pool_by_region"][rid])
		if pool <= 0:
			continue
		var dest := MobilizationSystem.communication(state, world, nation, rid, accessible)
		if dest == "":
			continue  # Q4 : région sans voie de communication, la Territorial Force n'y est pas incorporée
		tf["pool_by_region"][rid] = 0
		(tf["mobilizing"] as Array).append({"region": rid, "dest": dest, "soldiers": pool,
			"ready_turn": state.turn + int(tfp(rules, "transit_months")) + (1 if dest != rid else 0)})
		called += pool
	if called > 0:
		if tf["embodied_turn"] == null:
			tf["embodied_turn"] = state.turn
			state.log_event("mobilisation publique", "%s : la Territorial Force est incorporée (service intérieur)." % state.nations[nation]["name_fr"],
				state.nation_order.duplicate())
		state.log_event("mobilisation", "%s : %d hommes de la Territorial Force appelés." % [state.nations[nation]["name_fr"], called], [nation])


static func _unblock(state: GameState, world: WorldMap, nation: String, tf: Dictionary, accessible: Dictionary) -> void:
	var still: Array = []
	for c: Dictionary in tf["blocked"]:
		var dest := MobilizationSystem.communication(state, world, nation, c["region"], accessible)
		if dest == "":
			still.append(c)
		else:
			(tf["mobilizing"] as Array).append({"region": c["region"], "dest": dest, "soldiers": int(c["soldiers"]), "ready_turn": state.turn})
	tf["blocked"] = still


static func _incorporate_ready(state: GameState, world: WorldMap, rules: Dictionary, nation: String, tf: Dictionary, accessible: Dictionary) -> void:
	var keep: Array = []
	for c: Dictionary in tf["mobilizing"]:
		if int(c["ready_turn"]) > state.turn:
			keep.append(c)
			continue
		var dest: String = c["dest"]
		if not (state.controller(dest) == nation and accessible.has(dest)):
			dest = MobilizationSystem.communication(state, world, nation, c["region"], accessible)
		if dest == "":
			(tf["blocked"] as Array).append({"region": c["region"], "soldiers": int(c["soldiers"]), "since_turn": state.turn})
			continue
		if MobilizationSystem._region_has_battle(state, dest):
			c["dest"] = dest
			keep.append(c)  # Q8 : pas de nouvelle armée dans une région en bataille
			continue
		_form_units(state, rules, nation, tf, dest, int(c["soldiers"]))
	tf["mobilizing"] = keep


## Unités de la Territorial Force : ventilation par arme ESTIMÉE (proportions de l'armée régulière).
static func _form_units(state: GameState, rules: Dictionary, nation: String, tf: Dictionary, rid: String, soldiers: int) -> void:
	var f: Dictionary = state.nations[nation]["forces"]
	var shares: Dictionary = f["arm_shares"]
	var kinds: Array = shares.keys().filter(func(k: String) -> bool: return k != "services" and float(shares[k]) > 0.0)
	kinds.sort()
	var weights: Array = kinds.map(func(k: String) -> float: return float(shares[k]))
	weights.append(float(shares.get("services", 0.0)))
	var parts := MobilizationSystem.split(soldiers, weights)
	tf["services"] = int(tf["services"]) + int(parts[-1])
	var army := _army(state, nation, rid, "home")
	var size := int(rules["mobilization"]["new_unit_soldiers"])
	for i in kinds.size():
		var amount: int = parts[i]
		while amount > 0:
			var n := mini(amount, size)
			_new_unit(state, nation, rid, army, kinds[i], n, "home")
			amount -= n
	tf["incorporated"] = int(tf["incorporated"]) + soldiers
	state.log_event("mobilisation", "%s : %d hommes de la Territorial Force incorporés (%s, service intérieur)." % [
		state.nations[nation]["name_fr"], soldiers, rid], [nation])


static func _army(state: GameState, nation: String, rid: String, service: String) -> String:
	var k := 1
	while true:
		var aid := "army_%s_%s_tf_%s%d" % [nation, rid, service, k]
		if not state.formations.has(aid):
			state.register_formation({"id": aid, "nation": nation, "echelon": "army", "category": CATEGORY, "service": service,
				"name_fr": "Territorial Force %s n° %d" % ["(service intérieur)" if service == "home" else "(volontaires outre-mer)", k],
				"region": rid, "parent": null, "soldiers": null, "equipment": null, "morale": null, "supplied": true,
				"planned_target": "", "battle_id": "", "encircled": false, "reserve": false,
				"status": "TERRITORIAL FORCE (T-050) : catégorie distincte ; répartition et ventilation ESTIMÉES"})
			return aid
		var a: Dictionary = state.formations[aid]
		if a["region"] == rid and not state.is_engaged(aid) and not a.get("encircled", false):
			return aid
		k += 1
	return ""


static func _new_unit(state: GameState, nation: String, rid: String, army: String, kind: String, soldiers: int, service: String) -> String:
	var uid := state.new_id("%s_tf_%s" % [nation, kind.substr(0, 3)])
	var label: String = {"infantry": "Infanterie", "cavalry": "Yeomanry (cavalerie)", "artillery": "Artillerie"}.get(kind, kind)
	state.register_formation({"id": uid, "nation": nation, "echelon": "unit", "unit_type": kind, "category": CATEGORY, "service": service,
		"name_fr": "%s territoriale n° %d" % [label, state.next_id - 1], "region": rid, "parent": army,
		"soldiers": soldiers, "establishment": soldiers, "war_cap": soldiers, "equipment": null, "morale": null,
		"supplied": true, "planned_target": "", "battle_id": "", "encircled": false, "reserve": false,
		"status": "TERRITORIAL FORCE (T-050)"})
	return uid


## T-054 : une armée de la Territorial Force en service intérieur ne quitte pas le territoire national.
static func move_restriction(state: GameState, army: Dictionary, target: String) -> String:
	if not is_territorial(army) or army.get("service", "home") != "home":
		return ""
	if state.sovereign(target) != army["nation"]:
		return "Territorial Force : service intérieur seulement ; le service outre-mer exige des volontaires (T-054)"
	return ""


## Ordre de volontariat outre-mer (T-054) sur une armée de la Territorial Force en service intérieur.
static func validate_overseas(state: GameState, rules: Dictionary, order: Dictionary) -> String:
	var nation: String = order.get("nation", "")
	var aid: String = order.get("army", "")
	if not state.formations.has(aid):
		return "armée inconnue"
	var a: Dictionary = state.formations[aid]
	if a["nation"] != nation or not is_territorial(a) or not state.is_top_level(a):
		return "seule une armée de la Territorial Force de ce pays peut être proposée au service outre-mer"
	if a.get("service", "home") != "home":
		return "ces troupes servent déjà outre-mer"
	if state.is_engaged(aid):
		return "armée engagée dans une bataille"
	var tf: Variant = block(state, nation)
	if tf == null or tf["embodied_turn"] == null:
		return "Territorial Force non incorporée"
	var wait := int(tfp(rules, "overseas_min_months_embodied"))
	if state.turn < int(tf["embodied_turn"]) + wait:
		return "délai minimal depuis l'incorporation non écoulé (%d mois, provisoire)" % wait
	return ""


static func apply_overseas(state: GameState, rules: Dictionary, order: Dictionary) -> void:
	if validate_overseas(state, rules, order) != "":
		return
	var nation: String = order["nation"]
	var aid: String = order["army"]
	var a: Dictionary = state.formations[aid]
	var tf: Dictionary = block(state, nation)
	var share := tfp(rules, "overseas_volunteer_share")
	var dest := _army(state, nation, a["region"], "overseas")
	var moved := 0
	for uid: String in state.units_of(aid):
		var u: Dictionary = state.formations[uid]
		var vol := int(floor(float(u["soldiers"]) * share))
		if vol <= 0:
			continue
		if vol == int(u["soldiers"]):
			state.set_formation_parent(uid, dest)
			u["service"] = "overseas"
		else:
			u["soldiers"] = int(u["soldiers"]) - vol
			u["establishment"] = int(u["soldiers"])
			u["war_cap"] = int(u["soldiers"])
			_new_unit(state, nation, a["region"], dest, u["unit_type"], vol, "overseas")
		moved += vol
	tf["overseas_volunteers"] = int(tf["overseas_volunteers"]) + moved
	if state.units_of(aid).is_empty():
		state.remove_formation(aid)  # armée vidée : ses unités ont toutes rejoint l'armée de volontaires (aucun effectif perdu)
	if state.units_of(dest).is_empty():
		state.remove_formation(dest)
	state.log_event("mobilisation", "%s : %d volontaires de la Territorial Force acceptent le service outre-mer." % [state.nations[nation]["name_fr"], moved], [nation])


## Catégories de la Territorial Force (résumé et contrôles).
static func summary(state: GameState, nation: String) -> Dictionary:
	var tf: Variant = block(state, nation)
	if tf == null:
		return {}
	var pool := 0
	for rid: String in tf["pool_by_region"]:
		pool += int(tf["pool_by_region"][rid])
	var mob := 0
	for c: Dictionary in tf["mobilizing"]:
		mob += int(c["soldiers"])
	var blocked := 0
	for c: Dictionary in tf["blocked"]:
		blocked += int(c["soldiers"])
	var home := 0
	var overseas := 0
	for x: Dictionary in state.formations.values():
		if x["nation"] == nation and x["echelon"] == "unit" and is_territorial(x):
			if x.get("service", "home") == "home":
				home += int(x["soldiers"])
			else:
				overseas += int(x["soldiers"])
	return {"pool_initial": int(tf["pool_initial"]), "pool": pool, "mobilizing": mob, "blocked": blocked,
		"incorporated": int(tf["incorporated"]), "services": int(tf["services"]), "present_home": home,
		"present_overseas": overseas, "overseas_volunteers": int(tf["overseas_volunteers"]),
		"embodied": tf["embodied_turn"] != null}


static func normalize(fo: Dictionary) -> void:
	var tf: Variant = fo.get("territorial_force")
	if tf == null:
		return
	for k: String in ["pool_initial", "incorporated", "services", "overseas_volunteers"]:
		tf[k] = int(tf[k])
	if tf["embodied_turn"] != null:
		tf["embodied_turn"] = int(tf["embodied_turn"])
	for rid: String in tf["pool_by_region"]:
		tf["pool_by_region"][rid] = int(tf["pool_by_region"][rid])
	for c: Dictionary in tf["mobilizing"] + tf["blocked"]:
		c["soldiers"] = int(c["soldiers"])
		for k: String in ["ready_turn", "since_turn"]:
			if c.has(k):
				c[k] = int(c[k])
