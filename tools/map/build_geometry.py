import argparse
import csv
import json
import sys
from collections import Counter
from pathlib import Path

from pyproj import Transformer
import shapely
from shapely.geometry import MultiPolygon, mapping, shape
from shapely.ops import transform


ROOT = Path(__file__).resolve().parents[2]
PLAN_PATH = ROOT / "data/world/map/tables/region_plan.csv"
AGENT_PATHS = (
    ROOT / "data/world/map/build/agent_1/regions.geojson",
    ROOT / "data/world/map/build/agent_2/regions.geojson",
)
GEOJSON_PATH = ROOT / "data/world/map/regions.geojson"
REGIONS_PATH = ROOT / "data/world/map/regions.json"
SARAY_SHAPE_ID = "54988432B91991689904144"
SARY_ID = "region_088"
STRICT_OVERLAP_EPSILON = 1e-10
MAX_REPAIR_OVERLAP_DEG2 = 1e-6
TO_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True).transform


def load_json(path):
    with path.open(encoding="utf-8") as source:
        return json.load(source)


def round_geometry(geometry):
    rounded = transform(
        lambda x, y, z=None: (round(x, 6), round(y, 6)) if z is None else (round(x, 6), round(y, 6), z),
        geometry,
    )
    if not rounded.is_valid:
        rounded = polygonal(shapely.make_valid(rounded))
    return shapely.orient_polygons(rounded, exterior_cw=False)


def polygonal(geometry):
    if geometry.geom_type == "Polygon":
        return geometry
    if geometry.geom_type == "MultiPolygon":
        return geometry
    polygons = []
    if hasattr(geometry, "geoms"):
        for part in geometry.geoms:
            if part.geom_type == "Polygon":
                polygons.append(part)
            elif part.geom_type == "MultiPolygon":
                polygons.extend(part.geoms)
    if not polygons:
        raise ValueError("La correction a supprimé toute la géométrie polygonale")
    return MultiPolygon(polygons)


def load_features():
    features = []
    for path in AGENT_PATHS:
        collection = load_json(path)
        features.extend(collection["features"])
    ids = [feature["properties"].get("id") for feature in features]
    expected = [f"region_{number:03d}" for number in range(1, 91)]
    if len(features) != 90 or len(set(ids)) != 90 or set(ids) != set(expected):
        raise ValueError(f"Inventaire attendu: 90 IDs uniques; observé {len(features)} features")
    return {feature["properties"]["id"]: feature for feature in features}


def load_plan():
    with PLAN_PATH.open(encoding="utf-8", newline="") as source:
        rows = list(csv.DictReader(source))
    if len(rows) != 90:
        raise ValueError(f"region_plan.csv contient {len(rows)} lignes au lieu de 90")
    return {row["region_id"]: row for row in rows}


def add_saray(features, saray_path):
    source = load_json(saray_path)
    candidates = [
        feature
        for feature in source.get("features", [])
        if (feature.get("properties") or {}).get("shapeID") == SARAY_SHAPE_ID
    ]
    if len(candidates) != 1:
        raise ValueError(f"Attendu un shapeID Saray {SARAY_SHAPE_ID}, trouvé {len(candidates)}")
    saray = round_geometry(shape(candidates[0]["geometry"]))
    minx, miny, maxx, maxy = saray.bounds
    if maxx >= 30 or minx < 27 or miny < 41 or maxy > 42:
        raise ValueError(f"Le shapeID Saray n'est pas le district de Thrace attendu: {saray.bounds}")
    target = features[SARY_ID]
    current = shape(target["geometry"])
    parts = list(current.geoms) if current.geom_type == "MultiPolygon" else [current]
    van_parts = [part for part in parts if part.centroid.x > 40]
    if len(van_parts) != 1:
        raise ValueError(f"Attendu une seule composante parasite à Van, trouvé {len(van_parts)}")
    corrected = MultiPolygon(
        [part for part in parts if part.centroid.x <= 40]
    )
    for rid in sorted(features):
        if rid == SARY_ID:
            continue
        other = shape(features[rid]["geometry"])
        if not other.intersects(saray):
            continue
        other_without_saray = polygonal(other.difference(saray))
        features[rid]["geometry"] = mapping(
            round_geometry(other_without_saray)
        )
    corrected = polygonal(corrected.union(saray))
    corrected = shapely.make_valid(corrected)
    corrected = polygonal(corrected)
    props = target["properties"]
    props["source_refs"] = sorted(set(props.get("source_refs", [])) | {"geoboundaries_tur_v6"})
    props["source_layer"] = "gb_tur_adm2.geojson: shapeID 54988432B91991689904144 (Saray, Tekirdağ)"
    props["approximations"] = list(props.get("approximations", [])) + [
        "Le district thrace de Saray a été rétabli à partir du shapeID 54988432B91991689904144 de geoBoundaries TUR ADM2; la composante de Van portant l'homonyme Saray a été retirée."
    ]
    target["geometry"] = mapping(round_geometry(corrected))
    return features


def repair_micro_overlaps(features):
    geometries = {rid: shape(feature["geometry"]) for rid, feature in features.items()}
    changes = []
    ids = sorted(geometries)
    for _ in range(5):
        changed = False
        for index, left_id in enumerate(ids):
            left = geometries[left_id]
            for right_id in ids[index + 1 :]:
                right = geometries[right_id]
                if not left.intersects(right):
                    continue
                intersection = left.intersection(right)
                if intersection.is_empty or intersection.area <= STRICT_OVERLAP_EPSILON:
                    continue
                if intersection.area > MAX_REPAIR_OVERLAP_DEG2:
                    raise ValueError(
                        f"Chevauchement non microscopique à arbitrer avec source: {left_id}/{right_id} "
                        f"({intersection.area:.12g} deg²)"
                    )
                repaired = shapely.orient_polygons(polygonal(right.difference(left)), exterior_cw=False)
                if not repaired.is_valid or repaired.is_empty:
                    raise ValueError(f"Réparation invalide pour {right_id} contre {left_id}")
                geometries[right_id] = repaired
                features[right_id]["geometry"] = mapping(repaired)
                changes.append((left_id, right_id, intersection.area))
                changed = True
        if not changed:
            break
    remaining = []
    for index, left_id in enumerate(ids):
        for right_id in ids[index + 1 :]:
            intersection = geometries[left_id].intersection(geometries[right_id])
            if not intersection.is_empty and intersection.area > STRICT_OVERLAP_EPSILON:
                remaining.append((left_id, right_id, intersection.area))
    if remaining:
        raise ValueError(f"Chevauchements stricts restants: {remaining[:10]}")
    return geometries, changes


def update_metrics(features, geometries):
    for rid, feature in features.items():
        geometry = geometries[rid]
        if not geometry.is_valid or geometry.is_empty:
            raise ValueError(f"Géométrie invalide: {rid} ({shapely.is_valid_reason(geometry)})")
        props = feature["properties"]
        projected = transform(TO_3035, geometry)
        centroid = geometry.centroid
        representative = geometry.representative_point()
        props["area_km2"] = round(projected.area / 1_000_000, 2)
        props["centroid_lon_lat"] = [round(centroid.x, 6), round(centroid.y, 6)]
        props["representative_point_lon_lat"] = [round(representative.x, 6), round(representative.y, 6)]
        props["bbox"] = [round(value, 6) for value in geometry.bounds]
        props["polygon_parts_count"] = len(geometry.geoms) if geometry.geom_type == "MultiPolygon" else 1
        if geometry.geom_type not in ("Polygon", "MultiPolygon"):
            raise ValueError(f"Type non polygonal pour {rid}: {geometry.geom_type}")
        if geometry.geom_type == "Polygon":
            props["vertex_count"] = sum(len(ring.coords) for ring in [geometry.exterior, *geometry.interiors])
        else:
            props["vertex_count"] = sum(
                len(ring.coords)
                for polygon in geometry.geoms
                for ring in [polygon.exterior, *polygon.interiors]
            )


def build(saray_path):
    features = load_features()
    plan = load_plan()
    for rid, feature in features.items():
        props = feature["properties"]
        row = plan[rid]
        if props.get("name_fr") != row["nom_fr"] or props.get("zone") != row["zone"]:
            raise ValueError(f"Nom ou zone discordants avec le plan pour {rid}")
        feature["geometry"] = mapping(
            round_geometry(shape(feature["geometry"]))
        )
    features = add_saray(features, saray_path)
    geometries, repairs = repair_micro_overlaps(features)
    update_metrics(features, geometries)
    ordered_features = [features[f"region_{number:03d}"] for number in range(1, 91)]
    collection = {
        "type": "FeatureCollection",
        "name": "grand_strategy_1914_regions",
        "reference_date": "1914-01-01",
        "crs": {
            "type": "name",
            "properties": {"name": "EPSG:4326"},
        },
        "features": ordered_features,
    }
    region_rows = [feature["properties"] for feature in ordered_features]
    zone_counts = dict(Counter(region["zone"] for region in region_rows))
    sovereign_counts = dict(Counter(region["sovereign_1914"] for region in region_rows))
    metadata = {
        "schema_version": "1.0.0",
        "reference_date": "1914-01-01",
        "total_regions": 90,
        "zone_counts": zone_counts,
        "sovereign_counts_1914": sovereign_counts,
        "regions": region_rows,
    }
    GEOJSON_PATH.write_text(json.dumps(collection, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    REGIONS_PATH.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    total_area = sum(region["area_km2"] for region in region_rows)
    print(f"Généré: {GEOJSON_PATH} ({len(ordered_features)} features)")
    print(f"Généré: {REGIONS_PATH} ({len(region_rows)} régions)")
    print(f"Réparations de micro-chevauchements: {len(repairs)} modifications, seuil strict {STRICT_OVERLAP_EPSILON:g} deg²")
    print(f"Somme des superficies recalculées: {total_area:.2f} km²")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--saray-source", type=Path, required=True)
    args = parser.parse_args()
    try:
        build(args.saray_source)
    except Exception as error:
        print(f"ERREUR: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
