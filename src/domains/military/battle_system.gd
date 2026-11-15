class_name BattleSystem
extends RefCounted
## Batailles — T-029 (directeur, 15/11/2026).
## VALIDÉ et implémenté :
##   - toutes les batailles sont closes avant le tour suivant (synchronisation) ;
##   - batailles successives, une seule commandée à la fois ;
##   - commandement national ; commandement conjoint : le pays fournissant le plus de soldats
##     au début commande, égalité départagée par le prestige militaire, mandat jusqu'à la fin ;
##   - priorité : batailles critiques d'abord, puis ordre chronologique ;
##   - pause : solo libre ; multijoueur à l'unanimité des humains participants, l'IA ne vote pas.
## OUVERT, non inventé : critères de criticité, formule de durée, règles de résolution
## automatique, déconnexions, absence, reprise, contestation du commandement.
## Ces points passent par un résolveur interchangeable. Le résolveur par défaut,
## « neutral_no_outcome », est PROVISOIRE et NEUTRE : aucune perte, aucun changement de
## contrôle, retour des attaquants dans leur région d'origine.


static func create_battles(state: GameState, clashes: Array) -> Array:
	var created: Array = []
	for clash: Dictionary in clashes:
		var att_nations := _nations_of(state, clash["attackers"])
		var def_nations := _nations_of(state, clash["defenders"])
		var battle := {
			"id": state.new_id("battle"), "turn": state.turn, "date": state.date_label(),
			"region": clash["region"], "order": created.size(),
			"attackers": {"nations": att_nations, "formations": clash["attackers"],
				"commander": joint_commander(state, clash["attackers"])},
			"defenders": {"nations": def_nations, "formations": clash["defenders"],
				"commander": joint_commander(state, clash["defenders"])},
			"critical": null, "critical_status": "OUVERT : critères de criticité non définis",
			"duration_limit": null, "duration_status": "OUVERT : formule de durée non définie",
			"status": "pending", "origin": clash["origin"],
		}
		created.append(battle)
	return created


## Ordre de traitement : critiques d'abord (critère ouvert : aucune n'est critique), puis chronologique.
static func queue(battles: Array) -> Array:
	var sorted := battles.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ca := 1 if a["critical"] == true else 0
		var cb := 1 if b["critical"] == true else 0
		if ca != cb:
			return ca > cb
		return int(a["order"]) < int(b["order"]))
	return sorted


## Commandant général d'un camp : nation fournissant le plus de soldats au début de la bataille ;
## égalité départagée par le prestige militaire. Si les effectifs ou le prestige sont inconnus
## (null), le commandant est « indéterminé » : aucun choix arbitraire.
static func joint_commander(state: GameState, formation_ids: Array) -> Dictionary:
	var soldiers: Dictionary = {}
	var unknown := false
	for fid: String in formation_ids:
		var f: Dictionary = state.formations[fid]
		if not soldiers.has(f["nation"]):
			soldiers[f["nation"]] = 0
		if f["soldiers"] == null:
			unknown = true
		else:
			soldiers[f["nation"]] = int(soldiers[f["nation"]]) + int(f["soldiers"])
	var nations := soldiers.keys()
	nations.sort()
	if nations.is_empty():
		return {"nation": null, "basis": "aucune formation"}
	if nations.size() == 1:
		return {"nation": nations[0], "basis": "seul pays engagé"}
	if unknown:
		return {"nation": null, "basis": "indéterminé : effectifs inconnus (MIL-01)"}
	nations.sort_custom(func(a: String, b: String) -> bool: return int(soldiers[a]) > int(soldiers[b]))
	if int(soldiers[nations[0]]) > int(soldiers[nations[1]]):
		return {"nation": nations[0], "basis": "plus grand nombre de soldats au début"}
	var p0: Variant = state.nations[nations[0]].get("military_prestige")
	var p1: Variant = state.nations[nations[1]].get("military_prestige")
	if p0 == null or p1 == null or p0 == p1:
		return {"nation": null, "basis": "égalité d'effectifs ; prestige militaire inconnu ou égal"}
	return {"nation": nations[0] if p0 > p1 else nations[1], "basis": "égalité d'effectifs, prestige militaire"}


## Pause : solo libre ; multijoueur = unanimité des humains participants ; l'IA ne vote pas.
static func pause_allowed(human_participants: Array, votes: Dictionary) -> bool:
	if human_participants.size() <= 1:
		return true
	for nation: String in human_participants:
		if votes.get(nation, false) != true:
			return false
	return true


## Clôt toutes les batailles du tour (synchronisation T-029) avec le résolveur configuré.
static func resolve_all(state: GameState, world: WorldMap, rules: Dictionary, battles: Array) -> void:
	var resolver: String = rules["battles"]["auto_resolver"]
	for battle: Dictionary in queue(battles):
		if resolver == "neutral_no_outcome":
			_resolve_neutral(state, world, battle)
		else:
			push_error("Résolveur de bataille inconnu : %s" % resolver)
			_resolve_neutral(state, world, battle)
		state.battles.append(battle)


static func _resolve_neutral(state: GameState, world: WorldMap, battle: Dictionary) -> void:
	for fid: String in battle["attackers"]["formations"]:
		state.formations[fid]["region"] = battle["origin"][fid]
	battle["status"] = "resolved"
	battle["resolution"] = {"resolver": "neutral_no_outcome", "losses": null, "control_change": false,
		"status": "PROVISOIRE NEUTRE : règles de combat non définies (T-029, MIL-05/06)"}
	state.log_event("bataille", "Affrontement en %s : %s contre %s. Aucune règle de combat définie : sans issue, les attaquants se replient." % [
		world.regions[battle["region"]]["name_fr"], ", ".join(_names(state, battle["attackers"]["nations"])),
		", ".join(_names(state, battle["defenders"]["nations"]))],
		battle["attackers"]["nations"] + battle["defenders"]["nations"])


static func _nations_of(state: GameState, formation_ids: Array) -> Array:
	var out: Array = []
	for fid: String in formation_ids:
		var n: String = state.formations[fid]["nation"]
		if not out.has(n):
			out.append(n)
	out.sort()
	return out


static func _names(state: GameState, nations: Array) -> Array:
	return nations.map(func(n: String) -> String: return state.nations[n]["name_fr"])
