#!/usr/bin/env python3
"""Audit cartographique en LECTURE SEULE de Grand Strategy-1914.

N'écrit aucun fichier du dépôt. Produit sur la sortie standard :
  1. zones maritimes (validité WGS 84 et EPSG:3035, catalogue, liens) ;
  1b. façades côtières sans zone maritime et zone la plus proche ;
  2. mz_norwegian_sea : diagnostic et test de densification (en mémoire) ;
  3. régions isolées ;
  4. canal de Corfou (076/077) ;
  5. proximités inventoriées ;
  6. villes (cities.json, éventuellement lu dans un commit Git) sur la géométrie validée ;
  7. attributs des régions.

Usage :
  python tools/audit/map_audit.py [--cities-ref 4dbf4f8 | --cities-file chemin]
"""
from __future__ import annotations

import argparse
import collections
import json
import subprocess
from pathlib import Path

import shapely
from pyproj import Transformer
from shapely.geometry import Point, shape
from shapely.ops import nearest_points
from shapely.validation import explain_validity

ROOT = Path(__file__).resolve().parents[2]
MAP = ROOT / "data/world/map"
TO_3035 = Transformer.from_crs(4326, 3035, always_xy=True).transform
TO_4326 = Transformer.from_crs(3035, 4326, always_xy=True).transform


def proj(geometry):
    return shapely.transform(geometry, lambda x, y: TO_3035(x, y), interleaved=False)


def load_cities(arguments) -> dict | None:
    if arguments.cities_file:
        return json.loads(Path(arguments.cities_file).read_text(encoding="utf-8"))
    if arguments.cities_ref:
        blob = subprocess.run(
            ["git", "-C", str(ROOT), "show", f"{arguments.cities_ref}:data/world/map/cities.json"],
            check=True, capture_output=True, text=True).stdout
        return json.loads(blob)
    local = MAP / "cities.json"
    return json.loads(local.read_text(encoding="utf-8")) if local.exists() else None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--cities-ref", help="commit Git contenant data/world/map/cities.json (ex. 4dbf4f8)")
    parser.add_argument("--cities-file", help="chemin d'un cities.json")
    arguments = parser.parse_args()

    geo = json.loads((MAP / "regions.geojson").read_text(encoding="utf-8"))
    adj = json.loads((MAP / "adjacency.json").read_text(encoding="utf-8"))
    mz = json.loads((MAP / "build/agent_2/maritime_zones.json").read_text(encoding="utf-8"))
    index = json.loads((MAP / "regions.json").read_text(encoding="utf-8"))

    regions = {f["properties"]["id"]: f for f in geo["features"]}
    g4326 = {k: shape(f["geometry"]) for k, f in regions.items()}
    g3035 = {k: proj(g) for k, g in g4326.items()}
    name = {k: f["properties"]["name_fr"] for k, f in regions.items()}
    zones = {f["id"]: shape(f["geometry"]) for f in mz["features"]}
    zone_meta = {z["id"]: z for z in mz["maritime_zones"]}
    zones3035 = {}
    for zid, g in zones.items():
        p = proj(g)
        zones3035[zid] = p if p.is_valid else p.buffer(0)
    links = adj["region_maritime_zone_links"]

    print("#### 1. ZONES MARITIMES")
    for zid, g in zones.items():
        p = proj(g)
        meta = zone_meta[zid]
        print(f"{zid:30s} valide4326={g.is_valid!s:5s} valide3035={p.is_valid!s:5s} "
              f"bbox={[round(v, 1) for v in g.bounds]} cotes={meta.get('coastal_region_ids')} "
              f"externes={meta.get('external_coastal_region_ids')}")
        if not p.is_valid:
            print(f"   3035 : {explain_validity(p)}")
    counts = collections.Counter((l["derivation"], l["geometry_contact"], l["catalogue_declared"]) for l in links)
    print("liens (dérivation, contact, catalogue) :", dict(counts))
    for l in links:
        if not l["catalogue_declared"]:
            print(f"   géométrique non catalogué : {l['region_id']} -> {l['maritime_zone_id']}")
        if not l["geometry_contact"]:
            print(f"   catalogue seulement : {l['region_id']} -> {l['maritime_zone_id']} ({l['min_distance_km']} km)")
    graph = collections.defaultdict(set)
    for c in adj["maritime_zone_connections"]:
        graph[c["zone_a_id"]].add(c["zone_b_id"]); graph[c["zone_b_id"]].add(c["zone_a_id"])
    seen, components = set(), []
    for zid in sorted(zones):
        if zid in seen:
            continue
        stack, comp = [zid], set()
        while stack:
            z = stack.pop()
            if z in comp:
                continue
            comp.add(z); stack.extend(graph[z] - comp)
        seen |= comp; components.append(sorted(comp))
    print(f"composantes connexes du graphe naval : {len(components)}")
    for comp in components:
        print("   ", comp)

    print("\n#### 1b. FAÇADES CÔTIÈRES SANS ZONE MARITIME")
    for item in adj["coastal_regions_without_maritime_zone"]:
        rid = item["id"]
        nearest = sorted((g3035[rid].distance(z) / 1000, zid) for zid, z in zones3035.items())[:2]
        print(f"   {rid} {name[rid][:34]:34s} plus proches={[(z, round(d, 1)) for d, z in nearest]}")

    print("\n#### 2. mz_norwegian_sea")
    g = zones["mz_norwegian_sea"]
    raw = proj(g)
    print("WGS 84 :", explain_validity(g), "| EPSG:3035 :", explain_validity(raw))
    print("aire buffer(0) km² :", round(raw.buffer(0).area / 1e6, 1))
    for step in (1.0, 0.25):
        dense = proj(shapely.segmentize(g, step))
        print(f"segmentize {step}° : valide={dense.is_valid} aire km²={round(dense.area / 1e6, 1)}")

    print("\n#### 3. RÉGIONS ISOLÉES")
    for x in adj["isolated_regions"]:
        print("   terre :", x["id"], "-", x["reason"])
    print("   graphe jouable :", [x["id"] for x in adj["isolated_in_passable_graph"]])
    print("   051 liens maritimes :", [(l["maritime_zone_id"], l["derivation"], l["min_distance_km"])
                                      for l in links if l["region_id"] == "region_051"])
    near = sorted((g3035["region_051"].distance(g3035[k]) / 1000, k) for k in g3035 if k != "region_051")[:3]
    print("   051 régions les plus proches :", [(k, round(d, 1)) for d, k in near])

    print("\n#### 4. CANAL DE CORFOU 076/077")
    a, b = nearest_points(g3035["region_076"], g3035["region_077"])
    print("   distance min km :", round(a.distance(b) / 1000, 2),
          "| points :", [tuple(round(v, 4) for v in TO_4326(p.x, p.y)) for p in (a, b)])
    for k in ("region_076", "region_077"):
        print(f"   {k} zones :", [l["maritime_zone_id"] for l in links if l["region_id"] == k])

    print("\n#### 5. PROXIMITÉS")
    for x in adj["proximity_only_pairs"]:
        print(f"   {x['region_a_id']}-{x['region_b_id']} {x['distance_km']} km {x['classification']}")

    cities_doc = load_cities(arguments)
    print("\n#### 6. VILLES")
    if cities_doc is None:
        print("   cities.json absent (utiliser --cities-ref 4dbf4f8)")
    else:
        cities = cities_doc["cities"]
        print("   total :", len(cities), "| capitales :", sum(c["is_capital"] for c in cities))
        for field in ("id", "name_fr"):
            dup = [k for k, v in collections.Counter(c[field] for c in cities).items() if v > 1]
            print(f"   doublons {field} :", dup)
        changed, outside, near_border = [], [], 0
        for c in cities:
            pt = Point(c["coordinates"]); pt3 = proj(pt)
            hits = [k for k, geom in g4326.items() if geom.covers(pt)]
            actual = hits[0] if hits else sorted((g3035[k].distance(pt3), k) for k in g3035)[0][1]
            if not hits:
                outside.append(c["id"])
            if actual != c["region_id"]:
                changed.append((c["id"], c["region_id"], actual))
            if g3035[actual].boundary.distance(pt3) < 5000:
                near_border += 1
            if c["sovereign_1914"] != regions[actual]["properties"]["sovereign_1914"]:
                print("   souveraineté divergente :", c["id"])
        print("   hors région :", outside)
        print("   rattachements modifiés :", changed)
        print("   à moins de 5 km d'une frontière ou côte :", near_border)
        print("   noms composites :", [c["name_fr"] for c in cities if "(" in c["name_fr"] and c["is_capital"]])

    print("\n#### 7. ATTRIBUTS DES RÉGIONS")
    empty = collections.Counter(k for f in geo["features"] for k, v in f["properties"].items() if v in (None, "", [], {}))
    print("   champs vides :", dict(empty))
    stale = [k for k in regions if sorted(regions[k]["properties"].get("adjacent_region_ids", []))
             != sorted(adj["neighbors_by_region"][k])]
    print(f"   adjacent_region_ids (GeoJSON) ≠ adjacency.json : {len(stale)} {stale}")
    by_id = {r["id"]: r for r in index["regions"]}
    diverging = [k for k in regions if any(by_id[k].get(f) != regions[k]["properties"].get(f)
                                           for f in ("name_fr", "sovereign_1914", "area_km2", "city_ids"))]
    print("   regions.json ≠ GeoJSON :", diverging)
    area = [k for k in regions if abs(regions[k]["properties"]["area_km2"] - g3035[k].area / 1e6) > 1]
    print("   area_km2 inexacte (> 1 km²) :", area)
    print("   source_refs :", dict(collections.Counter(s for f in geo["features"] for s in f["properties"].get("source_refs", []))))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
