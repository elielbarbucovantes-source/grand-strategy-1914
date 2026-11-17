extends RefCounted
## Phase I post-MIL-01 (INT-01) : mémoire de renseignement militaire et anti-fuite.
## Vérifie les quatre statuts, les fourchettes/fiabilités, la péremption, l'actualisation,
## l'invisibilité d'un renfort non repéré et l'absence de tout effectif ennemi réel dans la vue.

var runner: Object

const ME := "france"
const FOE := "german_empire"
const TARGET_RID := "region_035"  # Lorraine, frontière franco-allemande


func _session() -> GameSession:
	var s := GameSession.create()
	s.new_game(ME, 1, 1914)
	s.state.wars.append({"id": "w_test", "a": ME, "b": FOE, "since_turn": s.state.turn})
	return s


func _report(turn: int, estimate: int, source: String = "reconnaissance", units: int = 3) -> Dictionary:
	return {"turn": turn, "date": "1914-%02d" % ((turn - 1) % 12 + 1), "estimate": estimate,
		"units_seen": units, "confirmed_units": units, "armies_seen": 1,
		"fortification_level": 2, "source": source, "enemy_nations": [FOE]}


func _put(s: GameSession, rid: String, rep: Dictionary) -> void:
	if not s.state.regions[rid].has("recon_reports"):
		s.state.regions[rid]["recon_reports"] = {}
	(s.state.regions[rid]["recon_reports"] as Dictionary)[ME] = rep.duplicate(true)


func _intel(s: GameSession, rid: String) -> Dictionary:
	return IntelSystem.region_intel(s.state, s.world, ME, rid, s.rules)


func test_status_confirmed_clear_when_directly_observed_and_empty() -> void:
	var s := _session()
	# Une région voisine contrôlée par la France, sans armée ennemie.
	var seen := IntelSystem.visible_regions(s.state, s.world, ME)
	var rid := ""
	for r: String in seen:
		var foreign := 0
		for f: Dictionary in s.state.armies_in(r):
			if f["nation"] != ME:
				foreign += 1
		if foreign == 0:
			rid = r
			break
	runner.check(rid != "", "une région directement observée sans armée ennemie existe")
	var inf := _intel(s, rid)
	runner.check(inf["status"] == "confirmed_clear", "région vide observée → confirmed_clear")
	runner.check(inf["estimated_soldiers"] == 0 and inf["reliability"] == 1.0, "confirmation : estimation nulle, fiabilité maximale")
	runner.check(inf["report_date"] == s.state.date_label(), "date d'observation = date courante")


func test_status_estimated_then_stale_then_unknown() -> void:
	var s := _session()
	_put(s, TARGET_RID, _report(s.state.turn, 60000))
	var inf := _intel(s, TARGET_RID)
	runner.check(inf["status"] == "estimated", "rapport frais → estimated")
	runner.check(inf["reliability"] > 0.80, "fiabilité fraîche élevée (%s)" % inf["reliability"])
	runner.check(inf["estimate_min"] < 60000 and inf["estimate_max"] > 60000, "fourchette encadre l'estimation")
	for i in 4:
		s.state.turn += 1
	inf = _intel(s, TARGET_RID)
	runner.check(inf["status"] == "stale", "rapport âgé → stale")
	runner.check(inf["reliability"] < 0.85, "fiabilité diminue avec l'âge (%s)" % inf["reliability"])
	runner.check(inf["estimate_max"] - inf["estimate_min"] > 12000, "fourchette s'élargit avec l'âge")
	var cfg := IntelSystem.cfg(s.rules)
	for i in (int(cfg["stale_turns"]) + 2):
		s.state.turn += 1
	inf = _intel(s, TARGET_RID)
	runner.check(inf["status"] == "unknown", "rapport expiré au-delà de stale_turns → unknown")
	runner.check(inf["estimated_soldiers"] == null and inf["reliability"] == 0.0, "expiration : aucune estimation")
	runner.check(int(cfg["stale_turns"]) == 4, "péremption configurable (stale_turns=4)")


func test_new_observation_refreshes_estimation_and_range() -> void:
	var s := _session()
	_put(s, TARGET_RID, _report(s.state.turn, 30000))
	var first := _intel(s, TARGET_RID)
	s.state.turn += 5
	var old := _intel(s, TARGET_RID)
	runner.check(old["status"] == "unknown", "ancien rapport expiré")
	_put(s, TARGET_RID, _report(s.state.turn, 90000, "combat", 7))
	var fresh := _intel(s, TARGET_RID)
	runner.check(fresh["status"] == "estimated", "nouvelle observation → estimated")
	runner.check(int(fresh["estimated_soldiers"]) == 90000, "nouvelle estimation remplace l'ancienne")
	runner.check(fresh["report_turn"] == s.state.turn and fresh["age_turns"] == 0, "date et âge actualisés")
	runner.check(str(fresh["source"]) == "combat" and int(fresh["units_seen"]) == 7, "source et unités actualisées")
	runner.check(float(fresh["reliability"]) < float(first["reliability"]), "combat moins fiable que reconnaissance")


func test_unspotted_reinforcement_is_invisible_until_observed() -> void:
	var s := _session()
	_put(s, TARGET_RID, _report(s.state.turn, 40000))
	var before := _intel(s, TARGET_RID)
	runner.check(int(before["estimated_soldiers"]) == 40000, "estimation initiale")
	# Renfort non repéré : on modifie uniquement l'état réel, aucun rapport n'est actualisé.
	for f: Dictionary in s.state.formations.values():
		if f["echelon"] == "unit" and f["nation"] == FOE:
			f["soldiers"] = int(f.get("soldiers", 0)) * 10
			break
	var after := _intel(s, TARGET_RID)
	runner.check(int(after["estimated_soldiers"]) == 40000, "renfort non repéré n'apparaît pas dans l'estimation")
	runner.check(after["estimate_max"] == before["estimate_max"], "fourchette inchangée sans observation")


func test_view_never_exposes_real_enemy_soldiers() -> void:
	var s := _session()
	_put(s, TARGET_RID, _report(s.state.turn, 60000))
	var view := IntelSystem.view_for(s.state, s.world, ME, s.rules)
	var real: Dictionary = {}
	for fid: String in s.state.formations:
		var f: Dictionary = s.state.formations[fid]
		if f["nation"] == FOE:
			var v: Variant = s.state.soldiers_of(fid) if s.state.formations.has(fid) else null
			if v != null:
				real[int(v)] = true
	# Aucune formation ennemie ne doit exposer son effectif.
	for f: Dictionary in view["formations"]:
		if str(f["nation"]) != ME:
			runner.check(f["soldiers"] == null and f["operational_soldiers"] == null and f["morale"] == null,
				"formation ennemie sans effectif, moral ni effectif opérationnel")
	# Le renseignement régional ne doit jamais être égal au total administratif réel.
	for rid: String in (view["region_intel"] as Dictionary):
		var inf: Dictionary = view["region_intel"][rid]
		if inf["estimated_soldiers"] != null:
			runner.check(not real.has(int(inf["estimated_soldiers"])),
				"estimation (%s) distincte d'un effectif réel" % inf["estimated_soldiers"])
	# Aucune référence directe à l'état interne ne doit fuir dans la vue.
	var blob := JSON.stringify(view)
	runner.check(not blob.contains("\"formations\":{\"id\":"), "vue sérialisée sans structure interne")
	runner.check(view.has("region_intel") and view.has("wars") and view.has("memory"), "vue complète mais filtrée")


func test_nation_agent_decision_independent_of_hidden_enemy_strength() -> void:
	var s := _session()
	_put(s, TARGET_RID, _report(s.state.turn, 55000))
	_put(s, "region_032", _report(s.state.turn, 40000))
	var view := IntelSystem.view_for(s.state, s.world, ME, s.rules)
	var orders1 := NationAgent.decide(view, s.world, s.rules)
	# On mute les effectifs réels ennemis (invisibles dans la vue) puis on recalcule.
	var changed := 0
	for fid: String in s.state.formations:
		var f: Dictionary = s.state.formations[fid]
		if f["nation"] == FOE and f["echelon"] == "unit":
			f["soldiers"] = int(f.get("soldiers", 0)) * 5 + 111
			changed += 1
	runner.check(changed > 0, "des unités ennemies réelles ont été modifiées (%d)" % changed)
	var view2 := IntelSystem.view_for(s.state, s.world, ME, s.rules)
	var orders2 := NationAgent.decide(view2, s.world, s.rules)
	runner.check(JSON.stringify(orders1) == JSON.stringify(orders2), "décisions identiques malgré la mutation secrète")
	runner.check(JSON.stringify(view["formations"]) == JSON.stringify(view2["formations"]),
		"vue des formations inchangée par la mutation secrète")


func test_estimate_range_brackets_rounded_value() -> void:
	var s := _session()
	_put(s, TARGET_RID, _report(s.state.turn, 61000))  # estimation déjà arrondie par la reconnaissance
	var inf := _intel(s, TARGET_RID)
	var est := int(inf["estimated_soldiers"])
	runner.check(est == 61000, "estimation arrondie conservée (%d)" % est)
	runner.check(int(inf["estimate_min"]) < est and int(inf["estimate_max"]) > est, "fourchette non dégénérée")
	runner.check(int(inf["estimate_min"]) >= 0, "bornes positives")
