#!/usr/bin/env python3
"""Valide `data/world/map/adjacency.json` sans modifier aucun fichier versionné.

Contrôles indépendants (le graphe est recalculé depuis les géométries) :

- référentiel des 90 régions, identifiants uniques, aucune référence morte ;
- 184 arêtes terrestres dérivées des frontières partagées en EPSG:3035 ;
- symétrie des voisinages, absence d'auto-boucle et de doublon ;
- 17 interfaces inter-lots et arête manquante 033/037 ;
- 10 détroits inter-régionaux et 3 détroits internes, cohérents avec la
  géométrie et avec les frontières terrestres (cumuls signalés) ;
- 8 proximités non connectées, jamais transformées en adjacence ;
- 16 zones maritimes, 14 connexions réciproques, 67 liens région/zone,
  tous déclarés au catalogue (66 géométriques + 1 catalogue_only : 051) ;
- 26 régions côtières sans zone, documentées comme limite de couverture ;
- empreintes SHA-256 des sources et du constructeur ;
- reproductibilité octet pour octet (option `--rebuild-check`).

Sortie : code 0 si tous les contrôles passent, 1 sinon.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    import shapely
    from pyproj import Transformer
    from shapely.geometry import shape
    from shapely.ops import nearest_points
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "shapely et pyproj sont requis. Installer tools/map/requirements.txt "
        "ou utiliser PYTHONPATH=/tmp/gs1914-gis-packages."
    ) from exc

ROOT = Path(__file__).resolve().parents[2]
MAP_DIR = ROOT / "data" / "world" / "map"
ADJACENCY_PATH = MAP_DIR / "adjacency.json"
REGIONS_GEOJSON = MAP_DIR / "regions.geojson"
REGIONS_INDEX = MAP_DIR / "regions.json"
MARITIME_ZONES_PATH = MAP_DIR / "build" / "agent_2" / "maritime_zones.json"
LOT_DIRS = {
    "agent_1": MAP_DIR / "build" / "agent_1",
    "agent_2": MAP_DIR / "build" / "agent_2",
}
BUILDER_PATH = ROOT / "tools" / "map" / "rebuild_topology.py"

EXPECTED_IDS = {f"region_{index:03d}" for index in range(1, 91)}
EXPECTED_LAND_EDGES = 184
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
EXPECTED_ISOLATED_PASSABLE = {"region_051"}
EXPECTED_STRAIT_IDS = {
    "strait_dover_001_007",
    "strait_north_channel_003_005",
    "strait_st_george_004_006",
    "strait_bonifacio_012_086",
    "strait_oresund_044_048",
    "strait_aland_049_052",
    "strait_moonsund_irbe_053_054",
    "strait_kerch_063_069",
    "strait_rio_antirrio_077_079",
    "strait_messina_084_085",
}
EXPECTED_INTERNAL_STRAITS = {
    "strait_danish_belts_044_044": "region_044",
    "strait_bosphorus_087": "region_087",
    "strait_dardanelles_090": "region_090",
}
EXPECTED_DUAL_STRAITS = {
    ("region_053", "region_054"),
    ("region_077", "region_079"),
}
EXPECTED_ISOLATED_MARITIME_ZONES = {"mz_caspian_sea"}
EXPECTED_PROXIMITY_PAIRS = {
    ("region_001", "region_009"),
    ("region_013", "region_032"),
    ("region_014", "region_035"),
    ("region_018", "region_034"),
    ("region_018", "region_035"),
    ("region_043", "region_076"),
    ("region_046", "region_049"),
    ("region_076", "region_077"),
}
EXPECTED_COASTAL_WITHOUT_ZONE = 26
EXPECTED_REGION_LINKS = 67
EXPECTED_ZONE_CONNECTIONS = 14
EXPECTED_PASSABLE_PAIRS = 192
SHARED_BOUNDARY_TOLERANCE_M = 10.0
MARITIME_TOUCH_TOLERANCE_M = 200.0
MARITIME_SHARED_BOUNDARY_MIN_M = 50.0
PROXIMITY_THRESHOLD_KM = 20.0
STRAIT_MAX_DISTANCE_KM = 100.0
EXPECTED_REGIONS_INDEX_SHA256 = (
    "4b26f0bd133dd9d85dbac6a7d3319aa27da82569af94533e453ac1d76734e771"
)


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def rid_sort_key(region_id: str) -> int:
    return int(region_id.removeprefix("region_"))


def pair_key(region_a: str, region_b: str) -> tuple[str, str]:
    return tuple(sorted((region_a, region_b), key=rid_sort_key))


class Validator:
    def __init__(self) -> None:
        self.checks = 0
        self.failures: list[str] = []

    def check(self, condition: bool, label: str, detail: str = "") -> None:
        self.checks += 1
        if condition:
            print(f"[PASS] {label}")
            return
        message = f"{label} — {detail}" if detail else label
        self.failures.append(message)
        print(f"[FAIL] {message}")

    def finish(self) -> int:
        print()
        print("=" * 72)
        if self.failures:
            print(
                f"RÉSULTAT : ÉCHEC — {len(self.failures)} contrôle(s) "
                f"en échec sur {self.checks}"
            )
            for failure in self.failures:
                print(f"  - {failure}")
            return 1
        print(f"RÉSULTAT : VALIDÉ — {self.checks} contrôles, 0 échec")
        print("=" * 72)
        return 0


def load_geometries() -> dict[str, object]:
    document = load_json(REGIONS_GEOJSON)
    geometries_4326 = {
        feature["properties"]["id"]: shape(feature["geometry"])
        for feature in document["features"]
    }
    to_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True).transform
    return {
        region_id: shapely.transform(geometry, to_3035, interleaved=False)
        for region_id, geometry in geometries_4326.items()
    }


def compute_land_pairs(geometries: dict[str, object]) -> dict[tuple[str, str], float]:
    region_ids = sorted(geometries, key=rid_sort_key)
    pairs: dict[tuple[str, str], float] = {}
    for index, region_a in enumerate(region_ids):
        geometry_a = geometries[region_a]
        for region_b in region_ids[index + 1 :]:
            geometry_b = geometries[region_b]
            if not geometry_a.intersects(geometry_b):
                continue
            shared = geometry_a.boundary.intersection(geometry_b.boundary)
            if shared.length > SHARED_BOUNDARY_TOLERANCE_M:
                pairs[(region_a, region_b)] = shared.length / 1000.0
    return pairs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--rebuild-check",
        action="store_true",
        help="Rejoue le constructeur dans un fichier temporaire et compare les octets.",
    )
    arguments = parser.parse_args()

    validator = Validator()
    check = validator.check

    if not ADJACENCY_PATH.exists():
        print(f"[FAIL] Fichier absent : {ADJACENCY_PATH}")
        return 1
    adjacency = load_json(ADJACENCY_PATH)
    regions_document = load_json(REGIONS_INDEX)
    regions = {region["id"]: region for region in regions_document["regions"]}

    check(adjacency.get("schema_version") == "2.0.0", "schema_version == 2.0.0",
          str(adjacency.get("schema_version")))
    check(adjacency.get("reference_date") == "1914-01-01",
          "Date de référence 1914-01-01")
    check(set(regions) == EXPECTED_IDS and len(regions) == 90,
          "regions.json couvre exactement region_001..region_090",
          f"{len(regions)} régions")
    check(adjacency.get("total_regions") == 90, "total_regions == 90")

    neighbors = adjacency.get("neighbors_by_region", {})
    check(set(neighbors) == EXPECTED_IDS,
          "neighbors_by_region couvre exactement les 90 régions",
          f"{len(neighbors)} entrées")
    check(adjacency.get("adjacent_region_ids") == neighbors,
          "adjacent_region_ids identique à neighbors_by_region (compatibilité)")
    expected_neighbor_errors = [
        region_id for region_id, values in neighbors.items()
        if any(value not in EXPECTED_IDS or value == region_id for value in values)
    ]
    check(not expected_neighbor_errors,
          "Aucun voisin inconnu ni auto-voisin",
          ", ".join(expected_neighbor_errors[:5]))
    check(all(len(values) == len(set(values)) for values in neighbors.values()),
          "Aucun voisin dupliqué")
    check(all(values == sorted(values, key=rid_sort_key)
              for values in neighbors.values()),
          "Voisins triés par identifiant numérique")

    edges = adjacency.get("edges", [])
    check(adjacency.get("total_land_edges") == len(edges) == EXPECTED_LAND_EDGES,
          "total_land_edges == 184",
          f"{adjacency.get('total_land_edges')} / {len(edges)}")
    edge_ids = [edge.get("id") for edge in edges]
    check(len(edge_ids) == len(set(edge_ids)) and all(edge_ids),
          "Identifiants d'arêtes uniques et non vides")
    edge_pairs = [pair_key(edge["region_a_id"], edge["region_b_id"]) for edge in edges]
    check(len(edge_pairs) == len(set(edge_pairs)),
          "Aucune arête terrestre dupliquée")
    check(all(edge["region_a_id"] != edge["region_b_id"] for edge in edges),
          "Aucune auto-boucle terrestre")
    check(all(edge["region_a_id"] in EXPECTED_IDS
              and edge["region_b_id"] in EXPECTED_IDS for edge in edges),
          "Toutes les arêtes référencent des régions existantes")
    check(all(edge.get("connection_type") == "land" for edge in edges),
          "Toutes les entrées de edges sont de type land")
    check(all(float(edge.get("shared_border_km", 0)) > 0 for edge in edges),
          "Toutes les arêtes portent une longueur positive")
    check(all(
        (edge["sovereign_a"] != edge["sovereign_b"])
        == bool(edge["is_international_border_1914"])
        for edge in edges
    ), "Le drapeau de frontière internationale concorde avec les souverainetés")

    origins = {
        name: sum(1 for edge in edges if edge.get("origin") == name)
        for name in (
            "agent_1_internal",
            "agent_2_internal",
            "interlot",
            "added_missing_agent_1",
        )
    }
    check(origins == {
        "agent_1_internal": 97,
        "agent_2_internal": 69,
        "interlot": 17,
        "added_missing_agent_1": 1,
    }, "Décomposition par origine = 97 / 69 / 17 / 1", str(origins))
    check(adjacency.get("land_edges_by_origin") == origins,
          "land_edges_by_origin concorde avec les arêtes")

    geometries = load_geometries()
    land_pairs_km = compute_land_pairs(geometries)
    land_pairs = set(land_pairs_km)
    check(len(land_pairs) == EXPECTED_LAND_EDGES,
          "184 interfaces terrestres mesurées sur la géométrie définitive",
          f"{len(land_pairs)} mesurées")
    check(set(edge_pairs) == land_pairs,
          "Correspondance exacte entre arêtes et interfaces mesurées",
          f"manquantes={sorted(land_pairs - set(edge_pairs))[:5]}, "
          f"en_trop={sorted(set(edge_pairs) - land_pairs)[:5]}")
    length_errors = [
        edge["id"]
        for edge in edges
        if abs(
            float(edge.get("shared_border_km", -1))
            - round(land_pairs_km[pair_key(edge["region_a_id"], edge["region_b_id"])], 2)
        ) > 0.05
    ]
    check(not length_errors,
          "shared_border_km concorde avec la mesure EPSG:3035",
          ", ".join(length_errors[:5]))
    geometry_length_errors = [
        edge["id"]
        for edge in edges
        if abs(
            float(edge.get("geometry_shared_border_km", -1))
            - round(land_pairs_km[pair_key(edge["region_a_id"], edge["region_b_id"])], 2)
        ) > 0.05
    ]
    check(not geometry_length_errors,
          "geometry_shared_border_km concorde avec la mesure EPSG:3035",
          ", ".join(geometry_length_errors[:5]))

    reciprocal_errors: list[str] = []
    for edge in edges:
        region_a, region_b = edge["region_a_id"], edge["region_b_id"]
        if region_b not in neighbors.get(region_a, []):
            reciprocal_errors.append(f"{region_a} ne liste pas {region_b}")
        if region_a not in neighbors.get(region_b, []):
            reciprocal_errors.append(f"{region_b} ne liste pas {region_a}")
    check(not reciprocal_errors,
          "Toutes les relations terrestres sont réciproques",
          "; ".join(reciprocal_errors[:5]))

    neighbor_pairs = {
        pair_key(region_id, other)
        for region_id, values in neighbors.items()
        for other in values
    }
    check(neighbor_pairs == set(edge_pairs),
          "neighbors_by_region est exactement l'image des arêtes")

    lot_membership = {}
    source_edge_count = {}
    for lot_name, directory in LOT_DIRS.items():
        lot_document = load_json(directory / "regions.json")
        lot_membership[lot_name] = {
            region["id"] for region in lot_document["regions"]
        }
        source_edge_count[lot_name] = len(
            load_json(directory / "adjacency.json")["edges"]
        )
    check(lot_membership["agent_1"] | lot_membership["agent_2"] == EXPECTED_IDS
          and not (lot_membership["agent_1"] & lot_membership["agent_2"]),
          "Les deux lots partitionnent les 90 régions")
    measured_interlot = {
        pair for pair in land_pairs
        if (pair[0] in lot_membership["agent_1"])
        != (pair[1] in lot_membership["agent_1"])
    }
    check(measured_interlot == EXPECTED_INTERLOT_PAIRS,
          "Les 17 interfaces inter-lots correspondent à l'audit",
          f"{len(measured_interlot)} mesurées")
    check(adjacency.get("total_interlot_land_interfaces") == 17,
          "total_interlot_land_interfaces == 17")
    check(len(adjacency.get("interlot_interface_pairs", [])) == 17,
          "interlot_interface_pairs contient 17 entrées")
    check(sum(1 for edge in edges if edge.get("interlot_interface")) == 17,
          "Les 17 arêtes inter-lots sont marquées interlot_interface")
    check(EXPECTED_ADDED_PAIR in set(edge_pairs),
          "Arête manquante 033 <-> 037 présente")
    added_edge = next(
        edge for edge in edges
        if pair_key(edge["region_a_id"], edge["region_b_id"]) == EXPECTED_ADDED_PAIR
    )
    check(bool(added_edge.get("missing_land_edge"))
          and added_edge.get("topology_action") == "MAJ-007",
          "L'arête 033 <-> 037 est marquée missing_land_edge / MAJ-007")

    straits = adjacency.get("strait_crossings", [])
    internal_straits = adjacency.get("internal_straits", [])
    check(adjacency.get("total_strait_crossings") == len(straits) == 10,
          "total_strait_crossings == 10", f"{len(straits)}")
    check(adjacency.get("total_internal_straits") == len(internal_straits) == 3,
          "total_internal_straits == 3", f"{len(internal_straits)}")
    check({strait["id"] for strait in straits} == EXPECTED_STRAIT_IDS,
          "Les 10 détroits inter-régionaux attendus sont présents",
          str(sorted({s["id"] for s in straits} ^ EXPECTED_STRAIT_IDS)))
    check(len({strait["id"] for strait in straits}) == len(straits),
          "Identifiants de détroits uniques")
    strait_pairs = {
        pair_key(strait["region_a_id"], strait["region_b_id"])
        for strait in straits
    }
    check(len(strait_pairs) == len(straits),
          "Aucun couple de régions dupliqué dans les détroits")
    check(all(strait["region_a_id"] != strait["region_b_id"] for strait in straits),
          "Aucune auto-boucle dans les détroits")
    check(all(strait["region_a_id"] in EXPECTED_IDS
              and strait["region_b_id"] in EXPECTED_IDS for strait in straits),
          "Tous les détroits référencent des régions existantes")
    check(all(
        (strait["sovereign_a"] != strait["sovereign_b"])
        == bool(strait["is_international_border_1914"])
        for strait in straits
    ), "Le drapeau international des détroits concorde avec les souverainetés")

    dual_errors: list[str] = []
    distance_errors: list[str] = []
    for strait in straits:
        key = pair_key(strait["region_a_id"], strait["region_b_id"])
        is_dual = key in land_pairs
        if bool(strait.get("also_land_adjacent")) != is_dual:
            dual_errors.append(strait["id"])
        if is_dual and key not in EXPECTED_DUAL_STRAITS:
            dual_errors.append(f"{strait['id']} (cumul non attendu)")
        measured_km = geometries[strait["region_a_id"]].distance(
            geometries[strait["region_b_id"]]
        ) / 1000.0
        if is_dual:
            if measured_km > 1.0:
                distance_errors.append(f"{strait['id']} contact terrestre distant")
            if strait.get("measured_min_distance_km") != 0.0:
                distance_errors.append(f"{strait['id']} distance duale non nulle")
        else:
            if not (0.0 < measured_km <= STRAIT_MAX_DISTANCE_KM):
                distance_errors.append(
                    f"{strait['id']}={measured_km:.2f} km hors bornes"
                )
            if abs(
                float(strait.get("measured_min_distance_km", -1))
                - round(measured_km, 2)
            ) > 0.05:
                distance_errors.append(
                    f"{strait['id']} distance enregistrée incohérente"
                )
    check(not dual_errors,
          "Le cumul détroit/frontière terrestre est exactement limité aux cas documentés",
          ", ".join(dual_errors))
    check(not distance_errors,
          "Chaque détroit a un support géométrique crédible (0 < d <= 100 km)",
          ", ".join(distance_errors))
    check({pair for pair in strait_pairs if pair in land_pairs}
          == EXPECTED_DUAL_STRAITS,
          "Les deux détroits cumulés sont Moonsund et Rio-Antirrio")

    internal_ids = {strait["id"] for strait in internal_straits}
    check(internal_ids == set(EXPECTED_INTERNAL_STRAITS),
          "Les 3 détroits internes attendus sont présents",
          str(sorted(internal_ids ^ set(EXPECTED_INTERNAL_STRAITS))))
    check(all(
        strait.get("region_id") == EXPECTED_INTERNAL_STRAITS[strait["id"]]
        and "region_a_id" not in strait
        and "region_b_id" not in strait
        for strait in internal_straits
    ), "Les détroits internes portent un region_id unique, sans auto-boucle")

    passable = adjacency.get("passable_neighbors_by_region", {})
    check(set(passable) == EXPECTED_IDS,
          "passable_neighbors_by_region couvre les 90 régions")
    expected_passable = {
        region_id: set(values) for region_id, values in neighbors.items()
    }
    for region_a, region_b in strait_pairs:
        expected_passable[region_a].add(region_b)
        expected_passable[region_b].add(region_a)
    check(all(
        set(passable.get(region_id, [])) == expected_passable[region_id]
        for region_id in EXPECTED_IDS
    ), "passable_neighbors_by_region = terrestre + détroits")
    passable_symmetric = all(
        region_id in passable.get(other, [])
        for region_id, values in passable.items()
        for other in values
    )
    check(passable_symmetric, "Le graphe jouable est symétrique")
    check(all(region_id not in values for region_id, values in passable.items()),
          "Aucune auto-boucle dans le graphe jouable")
    total_passable = sum(len(values) for values in passable.values()) // 2
    check(adjacency.get("total_passable_region_pairs") == total_passable
          == EXPECTED_PASSABLE_PAIRS,
          "total_passable_region_pairs == 192",
          f"{adjacency.get('total_passable_region_pairs')} / {total_passable}")

    isolated_land = {region_id for region_id, values in neighbors.items() if not values}
    check(isolated_land == EXPECTED_ISOLATED_REGIONS,
          "Régions isolées terrestres = 051, 085, 086",
          str(sorted(isolated_land)))
    isolated_passable = {
        region_id for region_id, values in passable.items() if not values
    }
    check(isolated_passable == EXPECTED_ISOLATED_PASSABLE,
          "Seule region_051 reste isolée dans le graphe jouable",
          str(sorted(isolated_passable)))
    check({entry["id"] for entry in adjacency.get("isolated_regions", [])}
          == EXPECTED_ISOLATED_REGIONS,
          "Chaque région isolée terrestre est justifiée")
    check({entry["id"] for entry in adjacency.get("isolated_in_passable_graph", [])}
          == EXPECTED_ISOLATED_PASSABLE,
          "L'isolement jouable de 051 est justifié")

    proximities = adjacency.get("proximity_only_pairs", [])
    check(adjacency.get("total_proximity_only_pairs") == len(proximities) == 8,
          "total_proximity_only_pairs == 8", f"{len(proximities)}")
    proximity_pairs = {
        pair_key(item["region_a_id"], item["region_b_id"]) for item in proximities
    }
    check(proximity_pairs == EXPECTED_PROXIMITY_PAIRS,
          "Les 8 proximités attendues sont inventoriées",
          str(sorted(proximity_pairs ^ EXPECTED_PROXIMITY_PAIRS)))
    check(not (proximity_pairs & (set(edge_pairs) | strait_pairs)),
          "Aucune proximité n'est en même temps une arête ou un détroit")
    proximity_errors: list[str] = []
    for item in proximities:
        key = pair_key(item["region_a_id"], item["region_b_id"])
        measured_km = geometries[key[0]].distance(geometries[key[1]]) / 1000.0
        if measured_km >= PROXIMITY_THRESHOLD_KM:
            proximity_errors.append(f"{key} à {measured_km:.2f} km")
        if abs(float(item.get("distance_km", -1)) - round(measured_km, 2)) > 0.05:
            proximity_errors.append(f"{key} distance enregistrée incohérente")
        if not item.get("classification") or not item.get("reason"):
            proximity_errors.append(f"{key} sans qualification")
    check(not proximity_errors,
          "Proximités < 20 km, distances exactes et qualifications présentes",
          ", ".join(proximity_errors[:5]))

    maritime_document = load_json(MARITIME_ZONES_PATH)
    zone_features = {
        feature["properties"]["id"]: feature
        for feature in maritime_document["features"]
    }
    zone_ids = set(zone_features)
    check(len(zone_ids) == 16, "16 zones maritimes au catalogue",
          f"{len(zone_ids)}")
    check(set(adjacency.get("maritime_zone_ids", [])) == zone_ids,
          "maritime_zone_ids couvre exactement le catalogue")
    check({zone["id"] for zone in adjacency.get("maritime_zones", [])} == zone_ids,
          "La section maritime_zones couvre exactement le catalogue")

    zone_connections = adjacency.get("maritime_zone_connections", [])
    check(adjacency.get("total_maritime_zone_connections")
          == len(zone_connections) == EXPECTED_ZONE_CONNECTIONS,
          "total_maritime_zone_connections == 14", f"{len(zone_connections)}")
    connection_pairs = {
        tuple(sorted((connection["zone_a_id"], connection["zone_b_id"])))
        for connection in zone_connections
    }
    source_zone_pairs = {
        tuple(sorted((zone_id, other)))
        for zone_id, feature in zone_features.items()
        for other in feature["properties"].get("adjacent_maritime_zone_ids", [])
    }
    check(connection_pairs == source_zone_pairs,
          "Connexions de zones identiques au catalogue")
    check(all(connection["zone_a_id"] != connection["zone_b_id"]
              for connection in zone_connections),
          "Aucune auto-boucle de zone maritime")
    check(len({connection["id"] for connection in zone_connections})
          == len(zone_connections),
          "Identifiants de connexions de zones uniques")
    check(all(connection["zone_a_id"] in zone_ids
              and connection["zone_b_id"] in zone_ids
              for connection in zone_connections),
          "Toutes les connexions référencent des zones existantes")
    check(set(adjacency.get("isolated_maritime_zones", []))
          == EXPECTED_ISOLATED_MARITIME_ZONES,
          "Seule la mer Caspienne est isolée côté maritime")
    check(all(
        connection["zone_b_id"]
        in zone_features[connection["zone_a_id"]]["properties"].get(
            "adjacent_maritime_zone_ids", []
        )
        and connection["zone_a_id"]
        in zone_features[connection["zone_b_id"]]["properties"].get(
            "adjacent_maritime_zone_ids", []
        )
        for connection in zone_connections
    ), "Chaque connexion entre zones est réciproque dans le catalogue")

    catalogue_links: dict[str, set[str]] = {}
    for zone_id, feature in zone_features.items():
        for region_id in feature["properties"].get("coastal_region_ids", []):
            catalogue_links.setdefault(region_id, set()).add(zone_id)

    links = adjacency.get("region_maritime_zone_links", [])
    check(adjacency.get("total_region_maritime_zone_links")
          == len(links) == EXPECTED_REGION_LINKS,
          "total_region_maritime_zone_links == 67", f"{len(links)}")
    link_keys = [(link["region_id"], link["maritime_zone_id"]) for link in links]
    check(len(link_keys) == len(set(link_keys)),
          "Aucun lien région/zone dupliqué")
    check(all(region_id in EXPECTED_IDS and zone_id in zone_ids
              for region_id, zone_id in link_keys),
          "Tous les liens référencent des régions et zones existantes")
    check(all(regions[link["region_id"]].get("has_coastline") for link in links),
          "Aucune région sans côte n'est reliée à une zone maritime")
    check({link["id"] for link in links} == {
        f"rmz_{region_id}__{zone_id}" for region_id, zone_id in link_keys
    }, "Identifiants de liens région/zone cohérents")

    zone_geometries = {
        zone_id: shape(feature["geometry"])
        for zone_id, feature in zone_features.items()
    }
    to_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True).transform
    zone_geometries = {
        zone_id: shapely.transform(geometry, to_3035, interleaved=False)
        for zone_id, geometry in zone_geometries.items()
    }
    derived_links: set[tuple[str, str]] = set()
    for region_id in sorted(geometries, key=rid_sort_key):
        for zone_id, zone_geometry in zone_geometries.items():
            measure_geometry = (
                zone_geometry if zone_geometry.is_valid else zone_geometry.buffer(0)
            )
            distance_m = geometries[region_id].distance(measure_geometry)
            shared = geometries[region_id].boundary.intersection(
                measure_geometry.boundary
            )
            if (distance_m <= MARITIME_TOUCH_TOLERANCE_M
                    or shared.length > MARITIME_SHARED_BOUNDARY_MIN_M):
                derived_links.add((region_id, zone_id))
    check({key for key in link_keys if key in derived_links} == derived_links,
          "Tous les liens géométriques sont présents",
          f"{len(derived_links)} liens mesurés")
    catalogue_only = {
        (region_id, zone_id)
        for region_id, zone_ids in catalogue_links.items()
        for zone_id in zone_ids
        if (region_id, zone_id) not in derived_links
    }
    check(catalogue_only == {("region_051", "mz_norwegian_sea")},
          "Un seul lien catalogue non reproduit : 051 / mer de Norvège",
          str(sorted(catalogue_only)))
    declared = {
        (region_id, zone_id)
        for region_id, zone_ids in catalogue_links.items()
        for zone_id in zone_ids
    }
    check(declared <= set(link_keys),
          "Tous les liens déclarés au catalogue sont présents")
    check(all(
        link["catalogue_declared"] == ((link["region_id"], link["maritime_zone_id"]) in declared)
        for link in links
    ), "Le drapeau catalogue_declared est exact")
    check(all(
        (link["derivation"] == "catalogue_only")
        == ((link["region_id"], link["maritime_zone_id"]) in catalogue_only)
        for link in links
    ), "Le mode catalogue_only est exactement réservé au lien 051 / mer de Norvège")
    check(all(
        link["geometry_contact"] == (link["derivation"] == "geometry")
        for link in links
    ), "Le drapeau geometry_contact est cohérent avec la dérivation")
    derivation_counts = {
        "geometry": sum(1 for link in links if link["derivation"] == "geometry"),
        "catalogue_only": sum(
            1 for link in links if link["derivation"] == "catalogue_only"
        ),
    }
    check(derivation_counts == {"geometry": 66, "catalogue_only": 1},
          "Répartition des liens : 66 géométriques + 1 catalogue_only",
          str(derivation_counts))
    # Lot 2 (C2a, 15/11/2026) : les 14 liens géométriques non catalogués ont été
    # ajoutés au catalogue (tools/map/sync_maritime_catalogue.py) ; 53 -> 67.
    check(sum(1 for link in links if link["catalogue_declared"]) == 67,
          "67 liens région/zone sont déclarés au catalogue")
    check(all(link["catalogue_declared"] for link in links),
          "Aucun lien géométrique n'est absent du catalogue")

    unlinked = adjacency.get("coastal_regions_without_maritime_zone", [])
    check(len(unlinked) == EXPECTED_COASTAL_WITHOUT_ZONE,
          "26 régions côtières sans zone documentées", f"{len(unlinked)}")
    linked_regions = {region_id for region_id, _zone_id in link_keys}
    expected_unlinked = {
        region_id for region_id in EXPECTED_IDS
        if regions[region_id].get("has_coastline")
        and region_id not in linked_regions
    }
    check({entry["id"] for entry in unlinked} == expected_unlinked,
          "La liste des régions côtières sans zone est exacte")
    check(all(regions[entry["id"]].get("has_coastline") for entry in unlinked),
          "Chaque région sans zone est réellement côtière")
    check(all(entry.get("reason") for entry in unlinked),
          "Chaque région côtière sans zone est justifiée")
    check(len({regions[region_id]["id"] for region_id in linked_regions}) == 36,
          "36 régions sont reliées à au moins une zone maritime",
          f"{len(linked_regions)}")

    generated_from = adjacency.get("generated_from", {})
    check(generated_from.get("geometry", {}).get("sha256")
          == sha256_file(REGIONS_GEOJSON),
          "Empreinte de regions.geojson exacte")
    check(generated_from.get("regions_index", {}).get("sha256")
          == sha256_file(REGIONS_INDEX),
          "Empreinte de regions.json exacte")
    check(generated_from.get("regions_index", {}).get("sha256")
          == EXPECTED_REGIONS_INDEX_SHA256,
          "regions.json conserve l'empreinte auditée 4b26f0bd…",
          str(generated_from.get("regions_index", {}).get("sha256")))
    check(generated_from.get("maritime_catalogue", {}).get("sha256")
          == sha256_file(MARITIME_ZONES_PATH),
          "Empreinte de maritime_zones.json exacte")
    for lot_name, directory in LOT_DIRS.items():
        check(
            generated_from.get("lot_builds", {}).get(lot_name, {}).get("sha256")
            == sha256_file(directory / "adjacency.json"),
            f"Empreinte du lot {lot_name} exacte",
        )
    check(generated_from.get("builder", {}).get("sha256")
          == sha256_file(BUILDER_PATH),
          "Empreinte du constructeur exacte")

    if arguments.rebuild_check:
        with tempfile.TemporaryDirectory(prefix="gs1914-topology-") as directory:
            rebuilt_path = Path(directory) / "adjacency.json"
            result = subprocess.run(
                [sys.executable, str(BUILDER_PATH), "--output", str(rebuilt_path)],
                cwd=ROOT,
                capture_output=True,
                text=True,
            )
            check(result.returncode == 0,
                  "Le constructeur se rejoue sans erreur",
                  result.stderr.strip()[-500:])
            if result.returncode == 0:
                check(rebuilt_path.read_bytes() == ADJACENCY_PATH.read_bytes(),
                      "Reconstruction reproductible octet pour octet",
                      f"sha256={sha256_file(rebuilt_path)}")

    return validator.finish()


if __name__ == "__main__":
    raise SystemExit(main())
