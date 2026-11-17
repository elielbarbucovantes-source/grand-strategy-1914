class_name IntelSystem
extends RefCounted
## Connaissance propre à chaque pays : l'IA et l'interface du joueur ne reçoivent QUE cette vue.
## Règle technique PROPOSÉE (Phase I post-MIL-01, INT-01) :
## - un pays observe directement les régions qu'il contrôle et leurs voisines (terre et détroits),
##   et y détecte la présence d'armées étrangères SANS connaître leur effectif exact (`soldiers = null`) ;
## - les rapports de reconnaissance en force (`reconnaissance`) et de contact au combat (`combat`)
##   fournissent une estimation datée des effectifs et des fortifications adverses ;
## - chaque rapport vieillit mois après mois (baisse de fiabilité, élargissement de la fourchette
##   d'incertitude, passage au statut « ancien » `stale`, puis expiration au-delà de `stale_turns`) ;
## - une nouvelle observation remplace l'ancienne (y compris lorsqu'une région observée devient vide).
## Interception, décryptage et espionnage : structures à venir (OUVERT, INT-02).

const DEFAULT_CFG := {
	"fresh_turns": 1,
	"stale_turns": 4,
	"base_reliability_recon": 0.85,
	"base_reliability_combat": 0.80,
	"reliability_decay_per_turn": 0.18,
	"min_reliability": 0.25,
	"base_uncertainty": 0.15,
	"uncertainty_per_turn": 0.12,
	"unknown_army_default_estimate": 55000,
}


static func cfg(rules: Dictionary = {}) -> Dictionary:
	if rules.has("intelligence") and rules["intelligence"] is Dictionary:
		return rules["intelligence"]
	return DEFAULT_CFG


static func visible_regions(state: GameState, world: WorldMap, nation: String) -> Dictionary:
	var seen: Dictionary = {}
	for rid: String in state.regions_controlled_by(nation):
		seen[rid] = true
		for n: String in world.neighbor_ids(rid, true):
			seen[n] = true
	return seen


## Vue nationale filtrée : jamais l'état complet, jamais les effectifs réels cachés d'autrui.
static func view_for(state: GameState, world: WorldMap, nation: String, rules: Dictionary = {}) -> Dictionary:
	var seen := visible_regions(state, world, nation)
	var formations: Array = []
	var foreign_by_region: Dictionary = {}
	for fid: String in state.top_level_formation_ids():
		var f: Dictionary = state.formations[fid]
		var rid: String = f["region"]
		if f["nation"] == nation:
			var s_val: Variant = state.soldiers_of(fid)
			formations.append({
				"id": fid, "nation": nation, "region": rid, "echelon": f["echelon"],
				"soldiers": s_val,
				"operational_soldiers": _own_operational(state, rules, fid, s_val),
				"morale": _own_morale(state, rules, fid),
				"supplied": bool(f.get("supplied", true)),
				"engaged": state.is_engaged(fid),
				"encircled": bool(f.get("encircled", false)),
				"defensive_posture": str(f.get("defensive_posture", "hold")),
				"home_service_only": TerritorialForce.is_territorial(f) and f.get("service", "home") == "home",
			})
		elif seen.has(rid):
			formations.append({
				"id": fid, "nation": f["nation"], "region": rid, "echelon": f["echelon"],
				"soldiers": null, "operational_soldiers": null, "morale": null,
				"supplied": null, "defensive_posture": null,
				"engaged": false, "encircled": false, "home_service_only": false,
			})
			if not foreign_by_region.has(rid):
				foreign_by_region[rid] = []
			(foreign_by_region[rid] as Array).append(f["nation"])
	var political: Dictionary = {}
	var own_defenses: Dictionary = {}
	var reg_intel: Dictionary = {}
	var rids := state.regions.keys()
	rids.sort()
	for rid: String in rids:
		political[rid] = {"controller": state.controller(rid), "sovereign": state.sovereign(rid)}
		if state.controller(rid) == nation or seen.has(rid):
			var own_lvl := _own_fort_level(state, nation, rid)
			if own_lvl > 0:
				own_defenses[rid] = own_lvl
		reg_intel[rid] = region_intel(state, world, nation, rid, rules, seen, foreign_by_region)
	return {
		"nation": nation, "turn": state.turn, "visible_regions": seen, "formations": formations,
		"political": political,
		"own_defenses": own_defenses,
		"region_intel": reg_intel,
		"wars": state.wars.duplicate(true),
		"public_mobilization": MobilizationSystem.public_view(state, {}),  # T-056 : posture et échelons, sans volumes
		"own_forces": MobilizationSystem.summary(state, nation),  # effectifs PROPRES à ce gouvernement (T-052)
		"public_treaties": state.treaties.filter(func(t: Dictionary) -> bool: return t["status"] == "active").duplicate(true),
		"pending_proposals": DiplomacySystem.pending_for(state, nation),
		"sent_proposals": state.proposals.filter(func(p: Dictionary) -> bool: return p["from"] == nation and p["status"] == "pending"),
		"messages": DiplomacySystem.visible_messages(state, nation),
		"memory": (state.memory.get(nation, []) as Array).duplicate(true),
		"capital_region": state.nations[nation]["capital_region_id"],
		"capitals": _capitals(state),
	}


## Renseignement militaire disponible pour `nation` sur la région `rid`.
## Distingue :
##   - "confirmed_clear" : région directement observée sans aucune armée étrangère ;
##   - "estimated"       : forces estimées par un rapport récent (reconnaissance ou combat) ;
##   - "stale"           : rapport ancien ou devenu incomplet (nouvelle armée arrivée ou perte de vue directe) ;
##   - "unknown"         : effectifs inconnus (armée vue sans rapport, ou région hors de vue / rapport expiré).
static func region_intel(state: GameState, world: WorldMap, nation: String, rid: String,
		rules: Dictionary = {}, seen_in: Dictionary = {}, foreign_by_region: Dictionary = {}) -> Dictionary:
	var seen := seen_in if not seen_in.is_empty() else visible_regions(state, world, nation)
	var directly_observed := seen.has(rid)
	var foreign_nations: Array = []
	var foreign_armies := 0
	if directly_observed:
		if foreign_by_region.has(rid):
			for fn: String in foreign_by_region[rid]:
				foreign_armies += 1
				if not foreign_nations.has(fn):
					foreign_nations.append(fn)
		elif foreign_by_region.is_empty():
			for f: Dictionary in state.armies_in(rid):
				if f["nation"] != nation:
					foreign_armies += 1
					if not foreign_nations.has(f["nation"]):
						foreign_nations.append(f["nation"])
	var icfg := cfg(rules)
	var fresh_turns := int(icfg.get("fresh_turns", 1))
	var stale_turns := int(icfg.get("stale_turns", 4))
	var rep: Dictionary = state.regions[rid].get("recon_reports", {}).get(nation, {})
	var has_rep := not rep.is_empty() and rep.has("turn") and rep.has("estimate")
	var age := state.turn - int(rep.get("turn", -999)) if has_rep else -1
	var valid_rep := has_rep and age >= 0 and age <= stale_turns
	# 1. Observation directe d'une région vide d'armées étrangères : information confirmée qui prime sur un ancien rapport.
	if directly_observed and foreign_armies == 0:
		var known_fort := int(rep.get("fortification_level", 0)) if valid_rep else 0
		return {
			"status": "confirmed_clear",
			"directly_observed": true,
			"confirmed_presence": false,
			"armies_seen": 0,
			"units_seen": 0,
			"confirmed_units": 0,
			"estimated_soldiers": 0,
			"estimate_min": 0,
			"estimate_max": 0,
			"fortification_level": known_fort,
			"reliability": 1.0,
			"age_turns": 0,
			"report_turn": state.turn,
			"report_date": state.date_label(),
			"source": "direct_observation",
			"nations": [],
		}
	# 2. Rapport de reconnaissance ou de combat non expiré.
	if valid_rep:
		var src := str(rep.get("source", "reconnaissance"))
		var base_rel := float(icfg.get("base_reliability_recon", 0.85)) if src == "reconnaissance" else float(icfg.get("base_reliability_combat", 0.80))
		var decay := float(icfg.get("reliability_decay_per_turn", 0.18))
		var min_rel := float(icfg.get("min_reliability", 0.25))
		var rel := clampf(base_rel - decay * float(age), min_rel, 1.0)
		var margin := float(icfg.get("base_uncertainty", 0.15)) + float(icfg.get("uncertainty_per_turn", 0.12)) * float(age)
		var est := int(rep["estimate"])
		var rep_armies := maxi(1, int(rep.get("armies_seen", 1)))
		if directly_observed and foreign_armies > rep_armies:
			# De nouvelles formations ennemies sont arrivées depuis le rapport : estimation partielle et ancienne.
			var extra := foreign_armies - rep_armies
			rel = maxf(min_rel, rel - 0.25 * float(extra))
			margin += 0.25 * float(extra)
		if not directly_observed:
			rel = minf(rel, 0.45)
			margin = maxf(margin, 0.35)
		var status := "estimated" if (age <= fresh_turns and directly_observed and foreign_armies <= rep_armies and rel >= 0.50) else "stale"
		var est_min := maxi(0, int(round(float(est) * maxf(0.10, 1.0 - margin))))
		var est_max := int(round(float(est) * (1.0 + margin)))
		var rep_nations: Array = foreign_nations if directly_observed else (rep.get("enemy_nations", []) as Array).duplicate()
		return {
			"status": status,
			"directly_observed": directly_observed,
			"confirmed_presence": directly_observed and foreign_armies > 0,
			"armies_seen": foreign_armies if directly_observed else rep_armies,
			"units_seen": int(rep.get("units_seen", 0)),
			"confirmed_units": int(rep.get("confirmed_units", rep.get("units_seen", 0))),
			"estimated_soldiers": est,
			"estimate_min": est_min,
			"estimate_max": est_max,
			"fortification_level": int(rep.get("fortification_level", 0)),
			"reliability": snappedf(rel, 0.01),
			"age_turns": age,
			"report_turn": int(rep["turn"]),
			"report_date": str(rep.get("date", "")),
			"source": src,
			"nations": rep_nations,
		}
	# 3. Aucune estimation valide (pas de rapport, ou rapport expiré au-delà de `stale_turns`).
	return {
		"status": "unknown",
		"directly_observed": directly_observed,
		"confirmed_presence": directly_observed and foreign_armies > 0,
		"armies_seen": foreign_armies if directly_observed else null,
		"units_seen": null,
		"confirmed_units": null,
		"estimated_soldiers": null,
		"estimate_min": null,
		"estimate_max": null,
		"fortification_level": null,
		"reliability": 0.0,
		"age_turns": null,
		"report_turn": null,
		"report_date": "",
		"source": "none",
		"nations": foreign_nations if directly_observed else [],
	}


static func _own_operational(state: GameState, rules: Dictionary, army_id: String, s_val: Variant) -> Variant:
	if s_val == null:
		return null
	var units := state.units_of(army_id)
	if units.is_empty():
		return int(s_val)
	var eff := float(rules.get("combat", {}).get("engagement", {}).get("lightly_wounded_efficiency", 0.5))
	var total := 0.0
	for uid: String in units:
		var u: Dictionary = state.formations[uid]
		var n := float(u.get("soldiers", 0))
		var lw := clampf(float(u.get("lightly_wounded", 0)), 0.0, n)
		total += (n - lw) + lw * eff
	return int(round(total))


static func _own_morale(state: GameState, rules: Dictionary, army_id: String) -> float:
	var f: Dictionary = state.formations[army_id]
	if f.get("morale") != null:
		return float(f["morale"])
	var def_m := float(rules.get("combat", {}).get("morale", {}).get("army_default", 70.0))
	var units := state.units_of(army_id)
	if units.is_empty():
		return def_m
	var sum_m := 0.0
	var count := 0
	for uid: String in units:
		var m: Variant = state.formations[uid].get("morale")
		if m != null:
			sum_m += float(m)
			count += 1
	return def_m if count == 0 else sum_m / float(count)


static func _own_fort_level(state: GameState, nation: String, rid: String) -> int:
	var best := 0
	var d: Dictionary = state.regions[rid].get("defenses", {})
	for t: Dictionary in d.get("trenches", []):
		if t.get("owner", "") == nation:
			best = maxi(best, int(t.get("level", 0)))
	return best


## Capitales (information publique).
static func _capitals(state: GameState) -> Dictionary:
	var out: Dictionary = {}
	for nid: String in state.nation_order:
		out[nid] = state.nations[nid]["capital_region_id"]
	return out
