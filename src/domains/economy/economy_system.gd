class_name EconomySystem
extends RefCounted
## Phase V — orchestrateur économique mensuel. Les données et formules sont PROPOSÉES ;
## les catégories validées du modèle C (production régionale, stocks nationaux, accessibilité)
## sont conservées. Aucun calcul n'est fait à chaque image : uniquement au tour mensuel.

const BASELINE_PATH := "res://data/game/economic_baseline.json"


static func initialize(state: GameState, rules: Dictionary) -> void:
	var text := FileAccess.get_file_as_string(BASELINE_PATH)
	var baseline: Variant = JSON.parse_string(text)
	if not (baseline is Dictionary):
		push_error("EconomySystem : baseline introuvable")
		return
	state.economy["baseline_sha256"] = text.sha256_text()
	state.economy["personalities"] = {}
	for nid: String in state.nation_order:
		state.economy["personalities"][nid] = str(rules.get("ai", {}).get("default_personality", "stability"))
	DemographySystem.init_from_baseline(state, baseline, rules)
	for nid: String in state.nation_order:
		state.economy["stocks"][nid] = {}


## Cycle mensuel complet, ordre déterministe : démographie → ressources → industrie →
## commerce → ravitaillement militaire → remplacement → IA économique (ordres pour le tour suivant).
static func monthly(state: GameState, world: WorldMap, rules: Dictionary, economic_rules: Dictionary) -> void:
	DemographySystem.monthly(state, economic_rules)
	ResourceSystem.monthly(state, economic_rules)
	IndustrySystem.monthly(state, economic_rules)
	MarketSystem.monthly(state, rules)
	MilitaryEconomySystem.monthly_supply(state, economic_rules)
	MilitaryEconomySystem.monthly_replacement(state, economic_rules)
	LogisticsSystem.update_supply(state, world, rules)


## Compatibilité avec les tests Phase antérieurs : production régionale (formule proposée).
static func region_output(state: GameState, rid: String, resource: String) -> Variant:
	var e: Dictionary = state.regions[rid].get("economy", {})
	var potential: Variant = (e.get("potential", {}) as Dictionary).get(resource)
	var capacity: Variant = e.get("exploitation_capacity")
	var infra: Variant = e.get("infrastructure_level")
	if potential == null or capacity == null or infra == null:
		return null
	return float(potential) * float(capacity) * float(infra)


static func national_balance(state: GameState, world: WorldMap, nation: String, categories: Array) -> Dictionary:
	var accessible := LogisticsSystem.accessible_regions(state, world, nation)
	var result := {}
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
	return IndustrySystem.validate_allocation(rules, order)


static func apply_allocation(state: GameState, order: Dictionary) -> void:
	state.nations[order["nation"]]["industry_allocation"] = (order["allocation"] as Dictionary).duplicate(true)


static func summary(state: GameState, nation: String) -> Dictionary:
	return {
		"demography": DemographySystem.summary(state, nation),
		"stocks": ResourceSystem.summary(state, nation),
		"industry_capacity": IndustrySystem.capacity(state, nation),
		"dependencies": MarketSystem.dependencies(state, nation),
		"replacement": MilitaryEconomySystem.summary(state, nation),
	}
