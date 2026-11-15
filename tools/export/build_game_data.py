#!/usr/bin/env python3
"""NP-0 — Exporte un paquet de données cartographiques neutre vis-à-vis du moteur.

Entrées (atlas validé, inchangé) : data/world/map/{regions.geojson, adjacency.json,
cities.json, terrain.json}, build/agent_2/maritime_zones.json.
Sortie : data/game/world_map.json (déterministe, contrôlé par --check).

Transformations, toutes destinées au RENDU et au calcul de graphe du jeu (la source
validée n'est jamais modifiée) :
1. reprojection EPSG:4326 → EPSG:3035 (LAEA Europe), coordonnées en kilomètres ;
2. make_valid (région 040 et 071 : auto-intersections de surface nulle apparues
   à la projection, aire inchangée) ;
3. coverage_clean (accrochage 50 m), qui rend la couverture topologiquement
   parfaite (écart d'aire ≤ 0,12 km²) ;
4. coverage_simplify (tolérance 1,5 km, frontières communes simplifiées à l'identique) ;
5. arrondi à 0,01 km.

Les attributs (souveraineté, villes, voisinages, détroits, liens maritimes) sont
COPIÉS de l'atlas, sans aucune donnée de jeu ajoutée. Licences : voir le champ
`licence` (dérivé de données CC BY-NC 4.0 et ODbL 1.0 ; usage non commercial).

Usage : python tools/export/build_game_data.py [--check]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

import shapely
from pyproj import Transformer
from shapely.geometry import shape

ROOT = Path(__file__).resolve().parents[2]
MAP = ROOT / "data/world/map"
OUT = ROOT / "data/game/world_map.json"
SNAP_M = 50.0
SIMPLIFY_M = 1500.0
ZONE_SIMPLIFY_M = 3000.0
ROUND_KM = 2
TO_3035 = Transformer.from_crs(4326, 3035, always_xy=True).transform


def project(geometry):
    return shapely.make_valid(shapely.transform(geometry, lambda x, y: TO_3035(x, y), interleaved=False))


def km(value: float) -> float:
    return round(value / 1000.0, ROUND_KM)


def rings(geometry) -> list[list[list[list[float]]]]:
    """Liste de polygones ; chaque polygone = [anneau extérieur, trous…] ; points [x_km, y_km]."""
    polygons = []
    parts = getattr(geometry, "geoms", [geometry])
    for part in parts:
        if part.geom_type != "Polygon" or part.is_empty:
            continue
        polygon = [[[km(x), km(y)] for x, y in part.exterior.coords]]
        polygon += [[[km(x), km(y)] for x, y in hole.coords] for hole in part.interiors]
        polygons.append(polygon)
    return polygons


def point_km(lon: float, lat: float) -> list[float]:
    x, y = TO_3035(lon, lat)
    return [km(x), km(y)]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build() -> dict:
    geo = json.loads((MAP / "regions.geojson").read_text(encoding="utf-8"))
    adjacency = json.loads((MAP / "adjacency.json").read_text(encoding="utf-8"))
    cities = json.loads((MAP / "cities.json").read_text(encoding="utf-8"))["cities"]
    terrain = json.loads((MAP / "terrain.json").read_text(encoding="utf-8"))
    infra = json.loads((MAP / "infrastructure.json").read_text(encoding="utf-8"))
    zones = json.loads((MAP / "build/agent_2/maritime_zones.json").read_text(encoding="utf-8"))

    features = geo["features"]
    projected = [project(shape(f["geometry"])) for f in features]
    cleaned = shapely.coverage_clean(projected, snapping_distance=SNAP_M)
    simplified = shapely.coverage_simplify(cleaned, SIMPLIFY_M)
    if not shapely.coverage_is_valid(simplified):
        raise SystemExit("Couverture simplifiée invalide")

    regions = []
    for feature, source, geom in zip(features, projected, simplified):
        p = feature["properties"]
        rp = geom.representative_point()
        regions.append({
            "id": p["id"],
            "name_fr": p["name_fr"],
            "name_key": p["name_key"],
            "zone": p["zone"],
            "sovereign_1914": p["sovereign_1914"],
            "initial_sovereign_id": p["initial_sovereign_id"],
            "has_coastline": p["has_coastline"],
            "island_class": p.get("island_class"),
            "relief_categories": p["relief_categories"],
            "dominant_relief": terrain["regions_terrain"][p["id"]].get("dominant_relief"),
            "area_km2": p["area_km2"],
            "city_ids": p["city_ids"],
            "label_point_km": [km(rp.x), km(rp.y)],
            "polygons_km": rings(geom),
        })

    zone_geoms = [project(shape(f["geometry"])) for f in zones["features"]]
    zone_simplified = [shapely.simplify(g, ZONE_SIMPLIFY_M, preserve_topology=True) for g in zone_geoms]
    maritime = []
    for feature, geom in zip(zones["features"], zone_simplified):
        p = feature["properties"]
        rp = geom.representative_point()
        maritime.append({"id": p["id"], "name_fr": p["name_fr"], "label_point_km": [km(rp.x), km(rp.y)],
                         "polygons_km": rings(geom)})

    city_records = [{
        "id": c["id"], "name_fr": c["name_fr"], "name_key": c["name_key"], "region_id": c["region_id"],
        "sovereign_1914": c["sovereign_1914"], "site_type": c["site_type"],
        "strategic_roles": c["strategic_roles"], "is_capital": c["is_capital"],
        "position_km": point_km(*c["coordinates"]),
    } for c in cities]

    graph = {
        "land_edges": [{"a": e["region_a_id"], "b": e["region_b_id"],
                        "shared_border_km": e.get("shared_border_km"),
                        "is_international_border_1914": e.get("is_international_border_1914")}
                       for e in adjacency["edges"]],
        "strait_crossings": [{"id": s["id"], "a": s["region_a_id"], "b": s["region_b_id"],
                              "name_fr": s["name_fr"], "width_km": s.get("width_km")}
                             for s in adjacency["strait_crossings"]],
        "internal_straits": [{"id": s["id"], "name_fr": s["name_fr"],
                              "region_id": s.get("region_id") or s.get("region_a_id")}
                             for s in adjacency["internal_straits"]],
        "region_maritime_links": [{"region": l["region_id"], "zone": l["maritime_zone_id"],
                                   "derivation": l["derivation"]} for l in adjacency["region_maritime_zone_links"]],
        "maritime_zone_connections": [{"a": c["zone_a_id"], "b": c["zone_b_id"]}
                                      for c in adjacency["maritime_zone_connections"]],
        # Paires de régions reliées par un axe ferroviaire des lots consolidés (réseau fragmenté :
        # docs/map/decisions/THEMATIC_LAYERS.md). Sert aux délais de renfort et à la retraite.
        "rail_region_links": sorted({tuple(sorted((r["properties"]["from_region_id"], r["properties"]["to_region_id"])))
                                     for r in infra["railways"]["features"]
                                     if r["properties"]["from_region_id"] != r["properties"]["to_region_id"]}),
        "proximity_only_pairs": [{"a": x["region_a_id"], "b": x["region_b_id"], "distance_km": x["distance_km"]}
                                 for x in adjacency["proximity_only_pairs"]],
    }
    return {
        "format": "gs1914.world_map", "format_version": 1, "reference_date": "1914-01-01",
        "crs": "EPSG:3035 (ETRS89-LAEA), kilomètres ; y vers le nord",
        "generated_by": "tools/export/build_game_data.py",
        "sources": {name: sha256(MAP / name) for name in
                    ("regions.geojson", "adjacency.json", "cities.json", "terrain.json", "infrastructure.json")}
                   | {"maritime_zones.json": sha256(MAP / "build/agent_2/maritime_zones.json")},
        "transform": {"snap_m": SNAP_M, "simplify_m": SIMPLIFY_M, "zone_simplify_m": ZONE_SIMPLIFY_M,
                      "purpose": "rendu et graphe de jeu ; la géométrie validée fait foi"},
        "licence": ("Données dérivées de REGIS/REThM (CC BY-NC 4.0, usage non commercial) et "
                    "d'OpenStreetMap via geoBoundaries (ODbL 1.0, régions 087 à 090), entre autres. "
                    "Voir DATA_LICENSES.md et NOTICE. Aucune autorisation commerciale."),
        "regions": regions, "maritime_zones": maritime, "cities": city_records, "graph": graph,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true")
    arguments = parser.parse_args()
    text = json.dumps(build(), ensure_ascii=False, separators=(",", ":")) + "\n"
    if arguments.check:
        ok = OUT.exists() and OUT.read_text(encoding="utf-8") == text
        print("[PASS] data/game/world_map.json à jour" if ok else "[FAIL] data/game/world_map.json obsolète")
        return 0 if ok else 1
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding="utf-8")
    print(f"data/game/world_map.json écrit ({OUT.stat().st_size / 1e6:.2f} Mo)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
