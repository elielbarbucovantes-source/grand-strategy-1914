class_name ResearchSystem
extends RefCounted
## Recherche (1914 → 1945 au plus). L'arbre technologique est OUVERT : aucune technologie
## n'est inventée. La structure de projet ci-dessous accueillera le catalogue validé.

const HORIZON_START := 1914
const HORIZON_END := 1945


static func new_project(tech_id: String, cost: Variant) -> Dictionary:
	return {"tech": tech_id, "cost": cost, "progress": 0.0, "status": "en cours"}


## Avance un projet ; coût inconnu (null) = aucune progression mesurable.
static func advance(project: Dictionary, points: Variant) -> void:
	if project["cost"] == null or points == null:
		return
	project["progress"] = minf(float(project["cost"]), float(project["progress"]) + float(points))
	if float(project["progress"]) >= float(project["cost"]):
		project["status"] = "terminé"
