#!/usr/bin/env python3
"""Valide les couches thématiques consolidées (villes, terrain, infrastructures).

Lecture seule. Code 0 si tous les contrôles passent, 1 sinon.
Option --report : affiche aussi les constats informatifs (proximité des frontières,
composantes du réseau ferré).
"""
from __future__ import annotations

import argparse
import collections
import json
import sys
from pathlib import Path

import shapely
from pyproj import Transformer
from shapely.geometry import Point, shape

ROOT = Path(__file__).resolve().parents[2]
MAP = ROOT / "data/world/map"
TO_3035 = Transformer.from_crs(4326, 3035, always_xy=True).transform
SITE_TYPES = {"capital", "major_port", "industrial_centre", "railway_hub", "fortress"}
# Constat documenté (lot 2, 15/11/2026) : les axes ferroviaires des lots ne relient que
# leurs deux villes extrémités. Le réseau forme 17 composantes connexes (134 villes
# desservies sur 175), dont la coupure entre lots signalée par MAJ-002. Ce garde-fou
# détecte toute évolution ; la correction exige des données ferroviaires SOURCÉES
# (docs/map/decisions/THEMATIC_LAYERS.md).
EXPECTED_RAIL_COMPONENTS = 17
FORT_TOLERANCE_M = 5000.0


class Checks:
    def __init__(self) -> None:
        self.failures = 0
        self.total = 0

    def __call__(self, ok: bool, label: str, detail: str = "") -> None:
        self.total += 1
        if not ok:
            self.failures += 1
        print(f"[{'PASS' if ok else 'FAIL'}] {label}" + (f" — {detail}" if detail and not ok else ""))


def load(name: str) -> dict:
    return json.loads((MAP / name).read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", action="store_true")
    arguments = parser.parse_args()
    check = Checks()
    geo = load("regions.geojson")
    regions = {f["properties"]["id"]: f["properties"] for f in geo["features"]}
    polygons = {f["properties"]["id"]: shape(f["geometry"]) for f in geo["features"]}
    cities_doc, terrain, infra = load("cities.json"), load("terrain.json"), load("infrastructure.json")
    cities = cities_doc["cities"]
    by_id = {c["id"]: c for c in cities}

    # ------------------------------------------------------------------ villes
    print("== Villes")
    check(len(cities) == cities_doc["total_cities"] == 175, "175 villes", str(len(cities)))
    for field in ("id", "name_fr"):
        dup = [k for k, v in collections.Counter(c[field] for c in cities).items() if v > 1]
        check(not dup, f"{field} unique", str(dup))
    coords = [k for k, v in collections.Counter(tuple(c["coordinates"]) for c in cities).items() if v > 1]
    check(not coords, "Coordonnées uniques", str(coords))
    check([f["id"] for f in cities_doc["features"]] == [c["id"] for c in cities]
          and all(f["geometry"]["coordinates"] == c["coordinates"] for f, c in zip(cities_doc["features"], cities)),
          "Entités GeoJSON cohérentes avec la liste des villes")
    outside = [c["id"] for c in cities if not polygons[c["region_id"]].covers(Point(c["coordinates"]))]
    check(not outside, "Chaque ville est dans le polygone de sa région déclarée", str(outside))
    sov = [c["id"] for c in cities if c["sovereign_1914"] != regions[c["region_id"]]["sovereign_1914"]]
    check(not sov, "Souveraineté de la ville = souveraineté de sa région", str(sov))
    bad_types = [c["id"] for c in cities if c["site_type"] not in SITE_TYPES
                 or not set(c["strategic_roles"]) <= SITE_TYPES]
    check(not bad_types, "Types et rôles de site connus", str(bad_types))
    capitals = collections.Counter(c["sovereign_1914"] for c in cities if c["is_capital"])
    sovereigns = {r["sovereign_1914"] for r in regions.values()}
    check(set(capitals) == sovereigns and all(v == 1 for v in capitals.values()),
          "Exactement une capitale par État souverain représenté",
          f"capitales={dict(capitals)} ; États={sorted(sovereigns)}")
    check(cities_doc["capital_count"] == sum(capitals.values()), "capital_count exact")
    check(all(c["capital_names_always_visible"] == c["is_capital"] for c in cities),
          "Noms de capitales toujours visibles (MAP-DEC-41)")
    declared = {rid: set(r.get("city_ids", [])) for rid, r in regions.items()}
    actual = collections.defaultdict(set)
    for c in cities:
        actual[c["region_id"]].add(c["id"])
    check(all(declared[r] == actual.get(r, set()) for r in regions), "city_ids des régions = villes rattachées")

    # ------------------------------------------------------------------ terrain
    print("== Terrain")
    profiles = terrain["regions_terrain"]
    check(sorted(profiles) == sorted(regions), "Profil de relief pour les 90 régions")
    allowed = set(terrain["allowed_relief_categories"])
    check(all(set(p["relief_categories"]) <= allowed for p in profiles.values()), "Catégories de relief autorisées")
    check(all(p.get("island_class", "x") is not None for p in profiles.values()), "Aucun island_class nul")
    check(all(not k.startswith("external_") for p in profiles.values() for k in p), "Aucune clé external_*")
    for kind in ("major_rivers", "mountain_chains"):
        ids = [x["id"] for x in terrain[kind]]
        check(len(ids) == len(set(ids)), f"{kind} : identifiants uniques")
        refs = [x["id"] for x in terrain[kind] if not set(x["region_ids"]) <= set(regions)]
        check(not refs, f"{kind} : références de régions valides", str(refs))
        aliases = {s for x in terrain[kind] for s in x.get("source_ids", []) if s != x["id"]}
        check(not (aliases & set(ids)), f"{kind} : aucun doublon transfrontalier résiduel (MAJ-006)")

    # ------------------------------------------------------------------ infrastructures
    print("== Infrastructures")
    rails = infra["railways"]["features"]
    forts = infra["fortifications"]["features"]
    check(len({r["id"] for r in rails}) == len(rails) == infra["total_railway_axes"], "Axes ferroviaires : identifiants uniques")
    rail_site = [r["id"] for r in rails if r["properties"]["from_site_id"] not in by_id
                 or r["properties"]["to_site_id"] not in by_id]
    check(not rail_site, "Extrémités ferroviaires = villes existantes", str(rail_site))
    rail_reg = [r["id"] for r in rails if r["properties"]["from_site_id"] in by_id and r["properties"]["to_site_id"] in by_id
                and (by_id[r["properties"]["from_site_id"]]["region_id"] != r["properties"]["from_region_id"]
                     or by_id[r["properties"]["to_site_id"]]["region_id"] != r["properties"]["to_region_id"])]
    check(not rail_reg, "Régions des extrémités ferroviaires cohérentes", str(rail_reg))
    rail_geom = [r["id"] for r in rails if r["properties"]["from_site_id"] in by_id and r["properties"]["to_site_id"] in by_id
                 and (r["geometry"]["coordinates"][0] != by_id[r["properties"]["from_site_id"]]["coordinates"]
                      or r["geometry"]["coordinates"][-1] != by_id[r["properties"]["to_site_id"]]["coordinates"])]
    check(not rail_geom, "Tracé ferroviaire ancré sur les villes extrémités", str(rail_geom[:10]))
    ports = infra["major_port_ids"]
    bad_ports = [p for p in ports if p not in by_id or "major_port" not in by_id[p]["strategic_roles"]]
    check(not bad_ports, "Grands ports = villes au rôle major_port", str(bad_ports))
    role_ports = sorted(c["id"] for c in cities if "major_port" in c["strategic_roles"])
    check(sorted(ports) == role_ports, "Tous les sites au rôle major_port sont recensés comme ports",
          f"absents={sorted(set(role_ports) - set(ports))} ; en trop={sorted(set(ports) - set(role_ports))}")
    check(len({f["id"] for f in forts}) == len(forts), "Places fortes : identifiants uniques")
    fort_out = []
    for f in forts:
        p = f["properties"]
        if p["region_id"] not in polygons:
            fort_out.append((f["id"], "région inconnue"))
            continue
        pt = Point(f["geometry"]["coordinates"])
        if not polygons[p["region_id"]].covers(pt):
            d = shapely.transform(polygons[p["region_id"]], lambda x, y: TO_3035(x, y), interleaved=False).distance(
                shapely.transform(pt, lambda x, y: TO_3035(x, y), interleaved=False))
            if d > FORT_TOLERANCE_M:
                fort_out.append((f["id"], round(d / 1000, 1)))
    check(not fort_out, f"Places fortes dans leur région (tolérance {FORT_TOLERANCE_M / 1000:.0f} km)", str(fort_out))
    fort_sov = [f["id"] for f in forts if f["properties"]["region_id"] in regions
                and f["properties"]["sovereign_1914"] != regions[f["properties"]["region_id"]]["sovereign_1914"]]
    check(not fort_sov, "Souveraineté des places fortes = souveraineté de la région", str(fort_sov))
    reg = infra["regional_infrastructure"]
    check(sorted(reg) == sorted(regions), "Fiche d'infrastructure pour les 90 régions")
    rail_ids, fort_ids = {r["id"] for r in rails}, {f["id"] for f in forts}
    dangling = []
    for rid, r in reg.items():
        for key, pool in (("strategic_site_ids", by_id), ("major_port_ids", set(ports)),
                          ("fortification_ids", fort_ids), ("connected_railway_axis_ids", rail_ids)):
            dangling += [(rid, key, x) for x in r.get(key, []) if x not in pool]
    check(not dangling, "Références des fiches régionales valides", str(dangling[:10]))

    graph = collections.defaultdict(set)
    for r in rails:
        a, b = r["properties"]["from_site_id"], r["properties"]["to_site_id"]
        graph[a].add(b); graph[b].add(a)
    seen, components = set(), []
    for node in sorted(graph):
        if node in seen:
            continue
        stack, comp = [node], set()
        while stack:
            n = stack.pop()
            if n not in comp:
                comp.add(n); stack.extend(graph[n] - comp)
        seen |= comp; components.append(comp)
    check(len(components) == EXPECTED_RAIL_COMPONENTS,
          f"Réseau ferré : {EXPECTED_RAIL_COMPONENTS} composantes constatées (documenté, non corrigé sans source)",
          f"{len(components)} composantes de tailles {sorted(len(c) for c in components)}")
    if arguments.report:
        print("   tailles des composantes ferroviaires :", sorted(len(c) for c in components))

    print("=" * 72)
    print(f"RÉSULTAT : {'VALIDÉ' if not check.failures else 'ÉCHEC'} — {check.total} contrôles, {check.failures} échec")
    return 1 if check.failures else 0


if __name__ == "__main__":
    sys.exit(main())
