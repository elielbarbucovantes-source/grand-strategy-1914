class_name BattleResult
extends RefCounted
## Résultat tactique (T-037) : combinaison configurable de deux dimensions.
##   A. Pertes et état des forces : 50 % équilibre des pertes relatives, 50 % part de la capacité
##      de combat restante (soldiers × moral des unités encore actives).
##   B. Contrôle territorial : part pondérée des objectifs contrôlés à la fin.
## score(camp) = weight_losses × A + weight_territory × B ; l'écart doit dépasser `decisive_margin`
## pour une victoire. Sinon : bataille indécise, et le défenseur conserve la région (PROPOSÉ).


static func compute(b: Dictionary, rules: Dictionary) -> Dictionary:
	var v: Dictionary = rules["victory"]
	var stats := {}
	for side: String in CombatData.SIDES:
		var start := 0
		var now := 0
		var capacity := 0.0
		for uid: String in b["units"]:
			var u: Dictionary = b["units"][uid]
			if u["side"] != side or u["status"] == CombatData.AVAILABLE:
				continue
			start += int(u["start_soldiers"])
			now += int(u["soldiers"])
			if u["status"] == CombatData.ACTIVE or u["status"] == CombatData.RESERVE or u["status"] == CombatData.ARRIVING:
				capacity += float(u["soldiers"]) * float(u["morale"]) / 100.0
		stats[side] = {"start": start, "now": now, "lost": start - now,
			"loss_frac": float(start - now) / maxf(1.0, float(start)), "capacity": capacity}
	var total_capacity := maxf(1.0, float(stats["attackers"]["capacity"]) + float(stats["defenders"]["capacity"]))
	var total_weight := 0.0
	var held := {CombatData.ATTACKERS: 0.0, CombatData.DEFENDERS: 0.0}
	for o: Dictionary in b["objectives"]:
		total_weight += float(o["weight"])
		if held.has(o["controller"]):
			held[o["controller"]] += float(o["weight"])
	var scores := {}
	for side: String in CombatData.SIDES:
		var other := CombatData.other(side)
		var balance := clampf(0.5 + 0.5 * (float(stats[other]["loss_frac"]) - float(stats[side]["loss_frac"])), 0.0, 1.0)
		var losses_part := 0.5 * balance + 0.5 * float(stats[side]["capacity"]) / total_capacity
		var territory := float(held[side]) / maxf(1.0, total_weight)
		scores[side] = {"losses": losses_part, "territory": territory,
			"total": float(v["weight_losses"]) * losses_part + float(v["weight_territory"]) * territory}
	var diff := float(scores["attackers"]["total"]) - float(scores["defenders"]["total"])
	var winner := ""
	if diff > float(v["decisive_margin"]):
		winner = CombatData.ATTACKERS
	elif diff < -float(v["decisive_margin"]):
		winner = CombatData.DEFENDERS
	return {"winner": winner, "decisive": winner != "", "holder": winner if winner != "" else CombatData.DEFENDERS,
		"scores": scores, "stats": stats, "margin": diff, "end_reason": b.get("end_reason", ""), "tick": b["tick"],
		"status": "T-037 : pondérations PROVISOIRES (weight_losses %.2f / weight_territory %.2f)" % [float(v["weight_losses"]), float(v["weight_territory"])]}
