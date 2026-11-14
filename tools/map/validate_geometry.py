import csv
import json
from pathlib import Path

from pyproj import Transformer
from shapely.geometry import Point, shape
from shapely.ops import transform
from shapely.validation import explain_validity


ROOT = Path(__file__).resolve().parents[2]
PLAN_PATH = ROOT / "data/world/map/tables/region_plan.csv"
GEOJSON_PATH = ROOT / "data/world/map/regions.geojson"
REGIONS_PATH = ROOT / "data/world/map/regions.json"
STRICT_OVERLAP_EPSILON = 1e-10
TO_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True).transform


def main():
    errors = []
    with PLAN_PATH.open(encoding="utf-8", newline="") as source:
        plan = list(csv.DictReader(source))
    collection = json.loads(GEOJSON_PATH.read_text(encoding="utf-8"))
    metadata = json.loads(REGIONS_PATH.read_text(encoding="utf-8"))
    features = collection.get("features", [])
    expected = [f"region_{number:03d}" for number in range(1, 91)]
    ids = [feature.get("properties", {}).get("id") for feature in features]
    if len(features) != 90 or len(set(ids)) != 90 or set(ids) != set(expected):
        errors.append(f"Inventaire invalide: {len(features)} features, {len(set(ids))} IDs uniques")
    plan_by_id = {row["region_id"]: row for row in plan}
    regions_by_id = {region["id"]: region for region in metadata.get("regions", [])}
    geometries = {}
    for feature in features:
        rid = feature.get("properties", {}).get("id")
        if rid not in plan_by_id:
            errors.append(f"ID inconnu: {rid}")
            continue
        geometry = shape(feature["geometry"])
        geometries[rid] = geometry
        properties = feature["properties"]
        if not geometry.is_valid or geometry.is_empty or geometry.geom_type not in ("Polygon", "MultiPolygon"):
            errors.append(f"Géométrie invalide: {rid} ({geometry.geom_type})")
        if not geometry.is_valid:
            errors.append(f"Cause géométrie invalide: {rid} ({explain_validity(geometry)})")
        row = plan_by_id[rid]
        if properties.get("name_fr") != row["nom_fr"] or properties.get("zone") != row["zone"]:
            errors.append(f"Métadonnées différentes du plan: {rid}")
        if properties.get("sovereign_1914") != row["souverainete_1914"]:
            errors.append(f"Souveraineté différente du plan: {rid}")
        if rid not in regions_by_id:
            errors.append(f"Absent de regions.json: {rid}")
            continue
        projected = transform(TO_3035, geometry)
        if abs(projected.area / 1_000_000 - properties.get("area_km2", -1)) > 0.02:
            errors.append(f"Superficie incohérente: {rid}")
        point = properties.get("representative_point_lon_lat", [])
        if len(point) != 2 or not geometry.contains(Point(*point)):
            errors.append(f"Point représentatif hors polygone: {rid}")
        if regions_by_id[rid] != properties:
            errors.append(f"Propriétés divergentes entre JSON et GeoJSON: {rid}")
    overlap_count = 0
    max_overlap = 0.0
    ids = sorted(geometries)
    for index, left_id in enumerate(ids):
        for right_id in ids[index + 1 :]:
            area = geometries[left_id].intersection(geometries[right_id]).area
            if area > STRICT_OVERLAP_EPSILON:
                overlap_count += 1
                max_overlap = max(max_overlap, area)
    if overlap_count:
        errors.append(f"Chevauchements au seuil strict: {overlap_count}, maximum {max_overlap:.12g} deg²")
    strumica = Point(22.6427, 41.4378)
    strumica_072 = geometries.get("region_072", Point()).covers(strumica)
    strumica_074 = geometries.get("region_074", Point()).covers(strumica)
    if not strumica_072 or strumica_074:
        errors.append(f"Strumica n'est pas attribuée exclusivement à region_072 (072={strumica_072}, 074={strumica_074})")
    saray = Point(27.9001, 41.4436)
    van = Point(44.1558, 38.5162)
    saray_088 = geometries.get("region_088", Point()).covers(saray)
    van_088 = geometries.get("region_088", Point()).covers(van)
    if not saray_088 or van_088:
        errors.append(f"Saray/VAN non corrigé (Saray dans 088={saray_088}, Van dans 088={van_088})")
    gap_tests = [
        ("MAJ-004 Finlande/Olonets", ["region_052", "region_064"], Point(32.3258, 62.6315)),
        ("MAJ-004 tripoint Khotin/Herța", ["region_040", "region_062", "region_071"], Point(26.1997, 48.3030)),
        ("MAJ-004 Pasvik nord", ["region_047", "region_065"], Point(30.5256, 69.5879)),
        ("MAJ-004 Pasvik sud", ["region_047", "region_065"], Point(29.7994, 69.4143)),
    ]
    unresolved_gaps = []
    for label, candidates, point in gap_tests:
        if not any(geometries.get(rid, Point()).covers(point) for rid in candidates):
            unresolved_gaps.append(label)
    print(f"Régions: {len(features)}/90; géométries valides: {sum(geometry.is_valid and not geometry.is_empty for geometry in geometries.values())}/90")
    print(f"Doublons: {len(features) - len(set(ids))}; paires avec chevauchement > {STRICT_OVERLAP_EPSILON:g} deg²: {overlap_count}")
    print(f"Somme des superficies: {sum(feature['properties']['area_km2'] for feature in features):.2f} km²")
    print(f"Saray: point dans 088={saray_088}, Van dans 088={van_088}")
    print(f"Strumica: dans 072={strumica_072}, dans 074={strumica_074}")
    print(f"Lacunes sentinelles non résolues: {len(unresolved_gaps)}/4 {unresolved_gaps}")
    for error in errors:
        print(f"ERREUR: {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
