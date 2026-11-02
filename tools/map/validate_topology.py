#!/usr/bin/env python3
"""Valide `data/world/map/adjacency.json` sans modifier aucun fichier.

Contrôles :
- 90 régions référencées et périmètre exact region_001..region_090 ;
- 184 arêtes terrestres, réciproques, sans doublon ni auto-boucle ;
- support géométrique de chaque arête (frontière partagée > 10 m) ;
- 17 interfaces inter-lots, dont 026/056 ;
- arête 033/037 ;
- détroits inter-régionaux et internes, sans auto-boucle ;
- connexions entre zones maritimes réciproques ;
- régions isolées légitimes.
"""
from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

for candidate_pkg in ("/tmp/gs1914-gis-packages",):
    if Path(candidate_pkg).exists() and candidate_pkg not in sys.path:
        sys.path.insert(0, candidate_pkg)

try:
    import shapely
    from pyproj import Transformer
    from shapely.geometry import shape
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "shapely et pyproj sont requis. Installer tools/map/requirements.txt "
        "ou utiliser PYTHONPATH=/tmp/gs1914-gis-packages."
    ) from exc

ROOT = Path(__file__).resolve().parents[2]
MAP_DIR = ROOT / "data" / "world" / "map"
ADJACENCY_PATH = MAP_DIR / "adjacency.json"
PLAN_PATH = MAP_DIR / "tables" / "region_plan.csv"
LOT_DIRS = {
    "agent_1": MAP_DIR / "build" / "agent_1",
    "agent_2": MAP_DIR / "build" / "agent_2",
}
SHARED_BOUNDARY_TOLERANCE_M = 10.0

EXPECTED_INTERLOT_PAIRS = {
    ("region_026", "region_054"),
    ("region_026", "region_055"),
    ("region_026", "region_056"),
    ("region_027", "region_055"),
    ("region_029", "region_044"),
    ("region_030", "region_055"),
    ("region_040", "region_055"),
    ("region_040", "region_056"),
    ("region_040", "region_058"),
    ("region_040", "region_062"),
    ("region_040", "region_071"),
    ("region_041", "region_070"),
    ("region_041", "region_074"),
    ("region_042", "region_070"),
    ("region_042", "region_071"),
    ("region_043", "region_074"),
    ("region_043", "region_075"),
}
EXPECTED_ADDED_PAIR = ("region_033", "region_037")
EXPECTED_ISOLATED_REGIONS = {"region_051", "region_085", "region_086"}
REQUIRED_STRAITS = {
    "strait_dover_001_007": {"region_001", "region_007"},
    "strait_north_channel_003_005": {"region_003", "region_005"},
    "strait_st_george_004_006": {"region_004", "region_006"},
    "strait_bonifacio_012_086": {"region_012", "region_086"},
}
EXPECTED_INTERNAL_STRAITS = {
    "strait_danish_belts_044_044": "region_044",
    "strait_bosphorus_087": "region_087",
    "strait_dardanelles_090": "region_090",
}
EXPECTED_ISOLATED_MARITIME_ZONES = {"mz_caspian_sea"}


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def rid_sort_key(region_id: str) -> int:
    return int(region_id.removeprefix("region_"))


def pair_key(region_a: str, region_b: str) -> tuple[str, str]:
    return tuple(sorted((region_a, region_b), key=rid_sort_key))


def main() -> int:
    failures: list[str] = []
    checks = 0

    def check(condition: bool, label: str, detail: str = "") -> None:
        nonlocal checks
        checks += 1
        if condition:
            print(f"[PASS] {label}")
        else:
            message = f"{label} — {detail}" if detail else label
            failures.append(message)
            print(f"[FAIL] {message}")

    if not ADJACENCY_PATH.exists():
        print(f"[FAIL] Fichier absent : {ADJACENCY_PATH}")
        return 1
    adjacency = load_json(ADJACENCY_PATH)

    with PLAN_PATH.open(encoding="utf-8", newline="") as handle:
        plan_ids = [row["region_id"] for row in csv.DictReader(handle)]
    expected_ids = {f"region_{index:03d}" for index in range(1, 91)}
    check(set(plan_ids) == expected_ids and len(plan_ids) == 90,
          "Référentiel region_plan.csv : 90 identifiants region_001..region_090")

    lot_regions: dict[str, dict] = {}
    geometries_4326: dict[str, object] = {}
    source_edge_counts: dict[str, int] = {}
    for lot_name, directory in LOT_DIRS.items():
        regions_doc = load_json(directory / "regions.json")
        lot_regions[lot_name] = {region["id"]: region for region in regions_doc["regions"]}
        geojson = load_json(directory / "regions.geojson")
        geometries_4326.update(
            {
                feature["properties"]["id"]: shape(feature["geometry"])
                for feature in geojson["features"]
            }
        )
        source_edge_counts[lot_name] = len(load_json(directory / "adjacency.json")["edges"])

    all_regions = {**lot_regions["agent_1"], **lot_regions["agent_2"]}
    check(len(all_regions) == 90, "Inventaire des lots : 90 régions uniques",
          f"{len(all_regions)} trouvées")
    check(set(all_regions) == expected_ids, "Les lots couvrent exactement region_001..region_090")

    check(adjacency.get("total_regions") == 90, "total_regions == 90")
    neighbors = adjacency.get("neighbors_by_region", {})
    check(set(neighbors) == expected_ids, "neighbors_by_region couvre les 90 régions",
          f"{len(neighbors)} entrées")
    check(adjacency.get("adjacent_region_ids") == neighbors,
          "adjacent_region_ids identique à neighbors_by_region")

    edges = adjacency.get("edges", [])
    check(adjacency.get("total_land_edges") == len(edges) == 184,
          "total_land_edges == 184", f"{adjacency.get('total_land_edges')} / {len(edges)}")
    check(adjacency.get("land_edges_by_origin") == {
        "agent_1_internal": 97,
        "agent_2_internal": 69,
        "interlot": 17,
        "added_missing_agent_1": 1,
    }, "Décomposition des arêtes par origine conforme à l'audit")

    edge_ids = [edge.get("id") for edge in edges]
    check(len(edge_ids) == len(set(edge_ids)) and all(edge_ids),
          "Identifiants d'arêtes uniques et non vides")
    edge_pairs = [pair_key(edge["region_a_id"], edge["region_b_id"]) for edge in edges]
    check(len(edge_pairs) == len(set(edge_pairs)), "Aucune arête terrestre dupliquée")
    check(all(edge["region_a_id"] != edge["region_b_id"] for edge in edges),
          "Aucune auto-boucle terrestre")
    check(all(edge["region_a_id"] in expected_ids and edge["region_b_id"] in expected_ids
              for edge in edges), "Toutes les arêtes référencent des régions existantes")
    check(all(edge.get("connection_type") == "land" for edge in edges),
          "Toutes les entrées de edges sont de type land")
    check(all(float(edge.get("shared_border_km", 0)) > 0 for edge in edges),
          "Toutes les arêtes portent une longueur de frontière positive")

    # Réciprocité des listes de voisins.
    reciprocal_errors: list[str] = []
    for edge in edges:
        region_a, region_b = edge["region_a_id"], edge["region_b_id"]
        if region_b not in neighbors.get(region_a, []):
            reciprocal_errors.append(f"{region_a} ne liste pas {region_b}")
        if region_a not in neighbors.get(region_b, []):
            reciprocal_errors.append(f"{region_b} ne liste pas {region_a}")
    check(not reciprocal_errors, "Toutes les relations terrestres sont réciproques",
          "; ".join(reciprocal_errors[:5]))
    check(all(len(values) == len(set(values)) for values in neighbors.values()),
          "Aucun voisin dupliqué dans neighbors_by_region")

    # Recalcul complet des interfaces à partir des géométries.
    to_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True).transform
    geometries_3035 = {
        region_id: shapely.transform(geometry, to_3035, interleaved=False)
        for region_id, geometry in geometries_4326.items()
    }
    geometric_pairs: dict[tuple[str, str], float] = {}
    sorted_ids = sorted(geometries_3035, key=rid_sort_key)
    for index, region_a in enumerate(sorted_ids):
        geometry_a = geometries_3035[region_a]
        for region_b in sorted_ids[index + 1 :]:
            geometry_b = geometries_3035[region_b]
            if not geometry_a.intersects(geometry_b):
                continue
            shared = geometry_a.boundary.intersection(geometry_b.boundary)
            if shared.length > SHARED_BOUNDARY_TOLERANCE_M:
                geometric_pairs[(region_a, region_b)] = shared.length / 1000.0

    check(len(geometric_pairs) == 184,
          "184 interfaces terrestres mesurées sur les géométries",
          f"{len(geometric_pairs)} mesurées")
    check(set(edge_pairs) == set(geometric_pairs),
          "Aucune connexion terrestre artificielle et aucune interface oubliée",
          f"manquantes={sorted(set(geometric_pairs) - set(edge_pairs))[:5]}, "
          f"en_trop={sorted(set(edge_pairs) - set(geometric_pairs))[:5]}")
    length_errors = [
        edge["id"]
        for edge in edges
        if abs(float(edge.get("geometry_shared_border_km", -1))
               - round(geometric_pairs[pair_key(edge["region_a_id"], edge["region_b_id"])], 2)) > 0.05
    ]
    check(not length_errors,
          "geometry_shared_border_km concorde avec la mesure EPSG:3035",
          ", ".join(length_errors[:5]))

    # Interfaces inter-lots.
    agent_1_ids = set(lot_regions["agent_1"])
    interlot_pairs = {
        pair for pair in geometric_pairs
        if (pair[0] in agent_1_ids) != (pair[1] in agent_1_ids)
    }
    check(interlot_pairs == EXPECTED_INTERLOT_PAIRS,
          "Les 17 interfaces inter-lots correspondent à l'audit",
          f"mesurées={len(interlot_pairs)}")
    check(("region_026", "region_056") in edge_pairs,
          "Interface 026 <-> 056 présente dans les arêtes terrestres")
    interlot_edge = next(
        edge for edge in edges
        if pair_key(edge["region_a_id"], edge["region_b_id"]) == ("region_026", "region_056")
    )
    check(abs(float(interlot_edge["shared_border_km"]) - 368.87) < 0.01,
          "Longueur de référence 026 <-> 056 = 368,87 km",
          str(interlot_edge.get("shared_border_km")))
    check(EXPECTED_ADDED_PAIR in edge_pairs,
          "Arête manquante 033 <-> 037 présente")
    check(sum(1 for edge in edges if edge.get("interlot_interface")) == 17,
          "Les 17 arêtes inter-lots sont marquées interlot_interface")
    check(all(edge.get("missing_land_edge") for edge in edges
              if pair_key(edge["region_a_id"], edge["region_b_id"]) == EXPECTED_ADDED_PAIR),
          "L'arête 033 <-> 037 est marquée missing_land_edge")

    # Contrôles ciblés de voisinage.
    check(neighbors.get("region_044") == ["region_029"],
          "region_044 (Danemark) a bien region_029 comme seul voisin terrestre",
          str(neighbors.get("region_044")))
    check(set(neighbors.get("region_026", [])) >= {"region_027", "region_054", "region_055", "region_056"},
          "region_026 inclut ses voisins inter-lots 054, 055 et 056")
    check("region_037" in neighbors.get("region_033", [])
          and "region_033" in neighbors.get("region_037", []),
          "033 et 037 se listent mutuellement")

    # Détroits.
    straits = adjacency.get("strait_crossings", [])
    internal_straits = adjacency.get("internal_straits", [])
    check(adjacency.get("total_strait_crossings") == len(straits) == 10,
          "total_strait_crossings == 10", f"{len(straits)}")
    check(adjacency.get("total_internal_straits") == len(internal_straits) == 3,
          "total_internal_straits == 3", f"{len(internal_straits)}")
    check(all(s["region_a_id"] != s["region_b_id"] for s in straits),
          "Aucune auto-boucle dans strait_crossings")
    check(len({s["id"] for s in straits}) == len(straits),
          "Identifiants de détroits inter-régionaux uniques")
    check(len({pair_key(s["region_a_id"], s["region_b_id"]) for s in straits}) == len(straits),
          "Aucun couple de régions dupliqué dans strait_crossings")
    check(all(s["region_a_id"] in expected_ids and s["region_b_id"] in expected_ids
              for s in straits), "Tous les détroits référencent des régions existantes")

    strait_by_id = {s["id"]: s for s in straits}
    for strait_id, required_pair in REQUIRED_STRAITS.items():
        present = strait_id in strait_by_id
        same_pair = present and {
            strait_by_id[strait_id]["region_a_id"],
            strait_by_id[strait_id]["region_b_id"],
        } == required_pair
        check(present and same_pair, f"Détroit requis présent : {strait_id}")

    for strait_id, region_id in EXPECTED_INTERNAL_STRAITS.items():
        matches = [s for s in internal_straits if s["id"] == strait_id]
        check(len(matches) == 1 and matches[0].get("region_id") == region_id
              and "region_a_id" not in matches[0] and "region_b_id" not in matches[0],
              f"Détroit interne corrigé sans auto-boucle : {strait_id}")

    # Un détroit peut longer une frontière terrestre (Moonsund, Corinthe), mais
    # le drapeau doit alors l'indiquer explicitement.
    dual_errors = []
    for strait in straits:
        key = pair_key(strait["region_a_id"], strait["region_b_id"])
        is_land = key in edge_pairs
        if bool(strait.get("also_land_adjacent")) != is_land:
            dual_errors.append(strait["id"])
    check(not dual_errors,
          "Le cumul détroit/frontière terrestre est correctement signalé",
          ", ".join(dual_errors))
    check(all(pair_key(s["region_a_id"], s["region_b_id"]) not in edge_pairs
              for s in straits if s["id"] in REQUIRED_STRAITS),
          "Les quatre nouveaux détroits ne sont pas des frontières terrestres")
    strait_distance_errors = []
    for strait in straits:
        if strait["id"] not in REQUIRED_STRAITS:
            continue
        region_a = geometries_3035[strait["region_a_id"]]
        region_b = geometries_3035[strait["region_b_id"]]
        distance_km = region_a.distance(region_b) / 1000.0
        if distance_km > 100.0:
            strait_distance_errors.append(f"{strait['id']}={distance_km:.1f} km")
    check(not strait_distance_errors,
          "Les quatre nouveaux détroits relient des rives distantes de moins de 100 km",
          ", ".join(strait_distance_errors))

    # Zones maritimes.
    maritime_doc = load_json(LOT_DIRS["agent_2"] / "maritime_zones.json")
    maritime_zones = {zone["id"]: zone for zone in maritime_doc["maritime_zones"]}
    source_maritime_pairs = {
        tuple(sorted((zone_id, other_id)))
        for zone_id, zone in maritime_zones.items()
        for other_id in zone.get("adjacent_maritime_zone_ids", [])
    }
    output_maritime_pairs = {
        tuple(sorted((connection["zone_a_id"], connection["zone_b_id"])))
        for connection in adjacency.get("maritime_zone_connections", [])
    }
    check(len(maritime_zones) == 16, "16 zones maritimes au catalogue")
    check(adjacency.get("total_maritime_zone_connections") == 14,
          "total_maritime_zone_connections == 14")
    check(output_maritime_pairs == source_maritime_pairs,
          "Connexions de zones maritimes identiques au catalogue agent_2")
    maritime_connections = adjacency.get("maritime_zone_connections", [])
    check(all(connection["zone_a_id"] != connection["zone_b_id"]
              for connection in maritime_connections),
          "Aucune auto-boucle de zone maritime")
    check(len({c["id"] for c in maritime_connections}) == len(maritime_connections),
          "Identifiants de connexions maritimes uniques")
    maritime_reciprocal = {
        tuple(sorted((connection["zone_b_id"], connection["zone_a_id"])))
        for connection in maritime_connections
    }
    check(maritime_reciprocal == output_maritime_pairs,
          "Toutes les connexions entre zones maritimes sont réciproques")
    check(set(adjacency.get("isolated_maritime_zones", [])) == EXPECTED_ISOLATED_MARITIME_ZONES,
          "Seule la mer Caspienne est isolée côté maritime")

    # Régions isolées.
    measured_isolated = {region_id for region_id, values in neighbors.items() if not values}
    check(measured_isolated == EXPECTED_ISOLATED_REGIONS,
          "Régions isolées = 051, 085, 086",
          f"{sorted(measured_isolated)}")
    explanations = {item["id"]: item.get("reason", "") for item in adjacency.get("isolated_regions", [])}
    check(set(explanations) == EXPECTED_ISOLATED_REGIONS
          and all(explanations.values()),
          "Chaque région isolée possède une justification")
    strait_pairs = {pair_key(s["region_a_id"], s["region_b_id"]) for s in straits}
    check(("region_084", "region_085") in strait_pairs,
          "Sicile reliée par le détroit de Messine")
    check(("region_012", "region_086") in strait_pairs,
          "Sardaigne reliée par les Bouches de Bonifacio")

    print()
    print("=" * 72)
    if failures:
        print(f"RÉSULTAT : ÉCHEC — {len(failures)} contrôle(s) en échec sur {checks}")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print(f"RÉSULTAT : VALIDÉ — {checks} contrôles, 0 échec")
    print("=" * 72)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
