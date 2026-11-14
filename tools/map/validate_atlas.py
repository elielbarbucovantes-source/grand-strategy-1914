#!/usr/bin/env python3
"""Validate the 90-region editorial index and, when present, basic region geometry."""
import csv
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PLAN = ROOT / "data/world/map/tables/region_plan.csv"
GEOJSON = ROOT / "data/world/map/regions.geojson"

def fail(message):
    print(f"ERREUR: {message}")
    return False

def main():
    errors = []
    with PLAN.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    if len(rows) != 90: errors.append(f"index: {len(rows)} lignes, cible 90")
    ids = [r.get("region_id", "") for r in rows]
    if len(set(ids)) != len(ids): errors.append("index: IDs dupliqués")
    if ids != [f"region_{i:03}" for i in range(1, 91)]: errors.append("index: IDs attendus region_001..region_090 en ordre")
    for i, r in enumerate(rows, 1):
        for field in ("nom_fr", "zone", "souverainete_1914"):
            if not r.get(field, "").strip(): errors.append(f"index ligne {i}: {field} manquant")
    counts = Counter(r["zone"] for r in rows)
    print(f"Index: {len(rows)} lignes; zones: {dict(counts)}")
    expected = {"Îles Britanniques": 6, "Europe occidentale": 13, "Péninsule ibérique": 6,
                "Europe centrale": 18, "Scandinavie": 8, "Europe orientale": 18,
                "Balkans": 10, "Italie": 7, "Territoires ottomans européens": 4}
    if counts != Counter(expected): errors.append("index: effectifs par zone différents de la répartition validée")
    if errors:
        for e in errors: fail(e)
        return 1
    print("Index éditorial: OK (90 IDs, champs obligatoires présents).")
    if not GEOJSON.exists():
        print("INCOMPLET: regions.geojson absent; aucune validation géométrique/topologique effectuée.")
        return 2
    try:
        from shapely.geometry import shape
        from shapely.validation import explain_validity
    except ImportError:
        print("ERREUR: géométries présentes mais pyogrio et shapely requis; installer tools/map/requirements.txt")
        return 1
    data = json.loads(GEOJSON.read_text(encoding="utf-8"))
    if data.get("type") != "FeatureCollection":
        fail("regions.geojson n'est pas une FeatureCollection")
        return 1
    features = data.get("features", [])
    if len(features) != 90: errors.append(f"GeoJSON: {len(features)} features, cible 90")
    found = {}
    geoms = {}
    for ft in features:
        props = ft.get("properties") or {}
        rid = props.get("id")
        if not rid or rid in found: errors.append(f"GeoJSON: ID absent ou dupliqué {rid!r}"); continue
        found[rid] = props
        try:
            g = shape(ft["geometry"]); geoms[rid] = g
            if g.geom_type not in ("Polygon", "MultiPolygon"): errors.append(f"{rid}: type {g.geom_type}")
            if g.is_empty: errors.append(f"{rid}: géométrie vide")
            if not g.is_valid: errors.append(f"{rid}: géométrie invalide ({explain_validity(g)})")
            minx, miny, maxx, maxy = g.bounds
            if minx < -180 or maxx > 180 or miny < -90 or maxy > 90:
                errors.append(f"{rid}: coordonnées hors WGS 84 longitude/latitude")
        except Exception as e: errors.append(f"{rid}: géométrie illisible ({e})")
        for field in ("name_fr", "sovereign_1914", "zone"):
            if not props.get(field): errors.append(f"{rid}: {field} manquant")
    if set(found) != set(ids): errors.append("GeoJSON: les IDs ne correspondent pas à l'index éditorial")
    plan_by_id = {r["region_id"]: r for r in rows}
    for rid, props in found.items():
        plan = plan_by_id.get(rid)
        if plan and (props.get("name_fr") != plan["nom_fr"] or props.get("zone") != plan["zone"]):
            errors.append(f"{rid}: nom/zone discordants avec region_plan.csv")
    rids = list(geoms)
    for i, left in enumerate(rids):
        for right in rids[i + 1:]:
            if geoms[left].intersection(geoms[right]).area > 1e-10:
                errors.append(f"chevauchement surfacique: {left} / {right}")
    try:
        crs = data.get("crs")
        if crs and "4326" not in json.dumps(crs): errors.append("GeoJSON: CRS déclaré différent d'EPSG:4326")
    except Exception: pass
    for e in errors: fail(e)
    print(f"Géométries valides: {sum(g.is_valid and not g.is_empty for g in geoms.values())}/{len(geoms)}")
    print("AVERTISSEMENT: l’absence d’une emprise de référence empêche de conclure à la couverture complète ou aux frontières historiques exactes.")
    return 1 if errors else 0

if __name__ == "__main__": sys.exit(main())
