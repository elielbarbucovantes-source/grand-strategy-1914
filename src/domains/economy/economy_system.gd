class_name EconomySystem
extends RefCounted
## Économie — modèle C (VALIDÉ par le directeur) : production régionale selon le potentiel
## exploitable, les capacités d'exploitation et les infrastructures ; stocks nationaux ;
## accessibilité réelle déterminée par la logistique.
## Les CATÉGORIES de ressources sont OUVERTES (R-03) : le moteur n'en fixe aucune et les lit
## dans les données. Les FORMULES et les DONNÉES sont absentes (ECO-01/02) : une valeur
## inconnue reste null et se propage telle quelle (jamais remplacée par 0).
## Industrie : cinq catégories VALIDÉES (PROJECT.md §11), priorités gouvernementales
## enregistrées. Leurs effets dépendent de capacités encore inconnues.


## Production mensuelle d'une région pour une ressource : null si une donnée manque.
## Formule PROPOSÉE (configurable, non validée) : potentiel × capacité × infrastructure.
static func region_output(state: GameState, rid: String, resource: String) -> Variant:
	var eco: Dictionary = state.regions[rid]["economy"]
	var potential: Variant = (eco["potential"] as Dictionary).get(resource)
	var capacity: Variant = eco["exploitation_capacity"]
	var infra: Variant = eco["infrastructure_level"]
	if potential == null or capacity == null or infra == null:
		return null
	return float(potential) * float(capacity) * float(infra)


## Bilan national : produit (régions contrôlées) et accessible (régions reliées à la capitale).
static func national_balance(state: GameState, world: WorldMap, nation: String, categories: Array) -> Dictionary:
	var accessible := LogisticsSystem.accessible_regions(state, world, nation)
	var result: Dictionary = {}
	for resource: String in categories:
		var produced: Variant = 0.0
		var reachable: Variant = 0.0
		for rid: String in state.regions_controlled_by(nation):
			var out: Variant = region_output(state, rid, resource)
			if out == null:
				produced = null
				reachable = null
				break
			produced += out
			if accessible.has(rid):
				reachable += out
		result[resource] = {"produced": produced, "accessible": reachable, "delivered": null}
	return result


static func validate_allocation(rules: Dictionary, order: Dictionary) -> String:
	var allowed: Array = rules["economy"]["industry_categories"]
	var total := 0.0
	for key: String in (order.get("allocation", {}) as Dictionary):
		if not allowed.has(key):
			return "catégorie industrielle inconnue : %s" % key
		var v := float(order["allocation"][key])
		if v < 0.0:
			return "part négative"
		total += v
	if total > 100.0001:
		return "la somme des priorités dépasse 100 %"
	return ""


static func apply_allocation(state: GameState, order: Dictionary) -> void:
	state.nations[order["nation"]]["industry_allocation"] = (order["allocation"] as Dictionary).duplicate()
