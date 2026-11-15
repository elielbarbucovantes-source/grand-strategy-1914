class_name IntelSystem
extends RefCounted
## Connaissance propre à chaque pays : l'IA et l'interface du joueur ne reçoivent QUE cette vue.
## Règle technique PROPOSÉE (niveaux de renseignement à définir, INT-01/02) :
## un pays voit les régions qu'il contrôle et leurs voisines (terre et détroits), les
## formations qui s'y trouvent, la carte politique (contrôle et souveraineté, publics),
## les guerres et traités publics, et les messages qui lui sont accessibles.
## Interception, décryptage et espionnage : structures à venir (OUVERT).


static func visible_regions(state: GameState, world: WorldMap, nation: String) -> Dictionary:
	var seen: Dictionary = {}
	for rid: String in state.regions_controlled_by(nation):
		seen[rid] = true
		for n: String in world.neighbor_ids(rid, true):
			seen[n] = true
	return seen


## Vue nationale filtrée : jamais l'état complet.
static func view_for(state: GameState, world: WorldMap, nation: String) -> Dictionary:
	var seen := visible_regions(state, world, nation)
	var formations: Array = []
	for fid: String in state.sorted_formation_ids():
		var f: Dictionary = state.formations[fid]
		if not state.is_top_level(f):
			continue  # vue stratégique : armées seulement (le détail des unités relève de la bataille)
		if f["nation"] == nation or seen.has(f["region"]):
			formations.append({"id": f["id"], "nation": f["nation"], "region": f["region"], "echelon": f["echelon"],
				"soldiers": state.soldiers_of(f["id"]) if f["nation"] == nation else null,
				"engaged": state.is_engaged(f["id"]) if f["nation"] == nation else false,
				"encircled": bool(f.get("encircled", false)) if f["nation"] == nation else false})
	var political: Dictionary = {}
	for rid: String in state.regions:
		political[rid] = {"controller": state.controller(rid), "sovereign": state.sovereign(rid)}
	return {
		"nation": nation, "turn": state.turn, "visible_regions": seen, "formations": formations,
		"political": political,
		"wars": state.wars.duplicate(true),
		"public_mobilization": MobilizationSystem.public_view(state, {}),  # T-056 : posture et échelons, sans volumes
		"public_treaties": state.treaties.filter(func(t: Dictionary) -> bool: return t["status"] == "active").duplicate(true),
		"pending_proposals": DiplomacySystem.pending_for(state, nation),
		"sent_proposals": state.proposals.filter(func(p: Dictionary) -> bool: return p["from"] == nation and p["status"] == "pending"),
		"messages": DiplomacySystem.visible_messages(state, nation),
		"memory": (state.memory.get(nation, []) as Array).duplicate(true),
		"capital_region": state.nations[nation]["capital_region_id"],
		"capitals": _capitals(state),
	}


## Capitales (information publique).
static func _capitals(state: GameState) -> Dictionary:
	var out: Dictionary = {}
	for nid: String in state.nation_order:
		out[nid] = state.nations[nid]["capital_region_id"]
	return out
