#!/usr/bin/env python3
"""Construit l'adjacence canonique des 90 régions de Grand Strategy-1914.

Le script lit uniquement les lots sources (agent_1 et agent-2) et écrit
`data/world/map/adjacency.json`. Il ne modifie aucune géométrie ni aucun
fichier thématique.

Méthode :
- les arêtes terrestres sont dérivées des frontières partagées réelles,
  mesurées en EPSG:3035 avec un seuil de 10 m ;
- les 17 interfaces inter-lots et l'arête manquante 033 <-> 037 sont
  vérifiées géométriquement, puis enrichies avec les métadonnées d'audit ;
- les détroits inter-régionaux, les détroits internes à une région et les
  connexions entre zones maritimes sont conservés dans des sections
  distinctes.
"""
from __future__ import annotations

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
except ImportError as exc:  # pragma: no cover - message d'installation
    raise SystemExit(
        "shapely et pyproj sont requis. Installer tools/map/requirements.txt "
        "ou utiliser PYTHONPATH=/tmp/gs1914-gis-packages."
    ) from exc

ROOT = Path(__file__).resolve().parents[2]
MAP_DIR = ROOT / "data" / "world" / "map"
LOT_DIRS = {
    "agent_1": MAP_DIR / "build" / "agent_1",
    "agent_2": MAP_DIR / "build" / "agent_2",
}
OUT_PATH = MAP_DIR / "adjacency.json"
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

NEW_STRAITS = [
    {
        "id": "strait_dover_001_007",
        "region_a_id": "region_001",
        "region_b_id": "region_007",
        "name_fr": "Pas de Calais / Détroit de Douvres (Douvres — Calais)",
        "width_km": 33.0,
        "documented_passages": [
            "Ferries Douvres — Calais et Douvres — Boulogne (en service en 1914)"
        ],
        "source_refs": ["regis_2026_v1", "baedeker_bradshaw_1914"],
    },
    {
        "id": "strait_north_channel_003_005",
        "region_a_id": "region_003",
        "region_b_id": "region_005",
        "name_fr": "Canal du Nord (Mer d'Irlande — Écosse / Ulster)",
        "width_km": 21.0,
        "documented_passages": [
            "Ferries Stranraer — Larne et Glasgow — Belfast (en service en 1914)"
        ],
        "source_refs": ["regis_2026_v1", "baedeker_bradshaw_1914"],
    },
    {
        "id": "strait_st_george_004_006",
        "region_a_id": "region_004",
        "region_b_id": "region_006",
        "name_fr": "Canal Saint-Georges (Pays de Galles — Irlande)",
        "width_km": 80.0,
        "documented_passages": [
            "Ferries Holyhead — Dublin et Fishguard — Rosslare (en service en 1914)"
        ],
        "source_refs": ["regis_2026_v1", "baedeker_bradshaw_1914"],
    },
    {
        "id": "strait_bonifacio_012_086",
        "region_a_id": "region_012",
        "region_b_id": "region_086",
        "name_fr": "Bouches de Bonifacio (Corse — Sardaigne)",
        "width_km": 11.0,
        "documented_passages": [
            "Ferries Bonifacio — Santa Teresa di Gallura (en service en 1914)"
        ],
        "source_refs": ["regis_2026_v1", "baedeker_bradshaw_1914"],
    },
]

ISOLATED_REGION_REASONS = {
    "region_051": (
        "Islande : île sans frontière terrestre ; aucun détroit inter-régional "
        "ne la relie à une autre région."
    ),
    "region_085": (
        "Sicile : île sans frontière terrestre ; reliée à region_084 par le "
        "détroit de Messine."
    ),
    "region_086": (
        "Sardaigne : île sans frontière terrestre ; reliée à region_012 par "
        "les Bouches de Bonifacio."
    ),
}


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def rid_sort_key(region_id: str) -> int:
    return int(region_id.removeprefix("region_"))


def pair_key(region_a: str, region_b: str) -> tuple[str, str]:
    return tuple(sorted((region_a, region_b), key=rid_sort_key))


def load_lot(name: str) -> tuple[dict, dict, dict]:
    directory = LOT_DIRS[name]
    regions_doc = load_json(directory / "regions.json")
    regions = {region["id"]: region for region in regions_doc["regions"]}
    geojson = load_json(directory / "regions.geojson")
    geometries = {
        feature["properties"]["id"]: shape(feature["geometry"])
        for feature in geojson["features"]
    }
    adjacency = load_json(directory / "adjacency.json")
    return regions, geometries, adjacency


def main() -> int:
    all_regions: dict[str, dict] = {}
    geometries_4326: dict[str, object] = {}
    source_edges: dict[tuple[str, str], dict] = {}
    source_adjacency: dict[str, dict] = {}

    for lot_name in LOT_DIRS:
        regions, geometries, adjacency = load_lot(lot_name)
        overlap = set(all_regions) & set(regions)
        if overlap:
            raise SystemExit(f"IDs dupliqués entre lots : {sorted(overlap)}")
        all_regions.update(regions)
        geometries_4326.update(geometries)
        source_adjacency[lot_name] = adjacency
        for edge in adjacency["edges"]:
            key = pair_key(edge["region_a_id"], edge["region_b_id"])
            if key in source_edges:
                raise SystemExit(f"Arête source dupliquée : {key}")
            source_edges[key] = edge

    region_ids = sorted(all_regions, key=rid_sort_key)
    if len(region_ids) != 90:
        raise SystemExit(f"90 régions attendues, {len(region_ids)} trouvées")
    if set(region_ids) != {f"region_{i:03d}" for i in range(1, 91)}:
        raise SystemExit("Les identifiants ne couvrent pas region_001..region_090")

    to_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True).transform
    geometries_3035 = {
        region_id: shapely.transform(geometry, to_3035, interleaved=False)
        for region_id, geometry in geometries_4326.items()
    }

    # Calcul exhaustif des frontières terrestres partagées.
    geometric_pairs: dict[tuple[str, str], float] = {}
    for index, region_a in enumerate(region_ids):
        geometry_a = geometries_3035[region_a]
        for region_b in region_ids[index + 1 :]:
            geometry_b = geometries_3035[region_b]
            if not geometry_a.intersects(geometry_b):
                continue
            shared = geometry_a.boundary.intersection(geometry_b.boundary)
            shared_km = shared.length / 1000.0
            if shared.length > SHARED_BOUNDARY_TOLERANCE_M:
                geometric_pairs[(region_a, region_b)] = shared_km

    if len(geometric_pairs) != 184:
        raise SystemExit(
            f"184 interfaces terrestres attendues d'après l'audit, "
            f"{len(geometric_pairs)} mesurées"
        )

    # `regions.json` ne porte pas `agent_id` : utiliser les fichiers de lot.
    agent_1_ids = {
        region["id"]
        for region in load_json(LOT_DIRS["agent_1"] / "regions.json")["regions"]
    }

    interlot_pairs = {
        pair for pair in geometric_pairs
        if (pair[0] in agent_1_ids) != (pair[1] in agent_1_ids)
    }
    if interlot_pairs != EXPECTED_INTERLOT_PAIRS:
        raise SystemExit(
            "Les interfaces inter-lots mesurées diffèrent de l'audit : "
            f"manquantes={sorted(EXPECTED_INTERLOT_PAIRS - interlot_pairs)}, "
            f"en_trop={sorted(interlot_pairs - EXPECTED_INTERLOT_PAIRS)}"
        )
    if EXPECTED_ADDED_PAIR not in geometric_pairs:
        raise SystemExit("L'interface 033 <-> 037 n'a pas de support géométrique")

    external_by_pair = {
        pair_key(interface["from_region_id"], interface["to_external_region_id"]): interface
        for interface in source_adjacency["agent_2"]["external_perimeter_interfaces"]
    }

    def sovereign(region_id: str) -> str:
        return all_regions[region_id]["sovereign_1914"]

    def make_added_edge(key: tuple[str, str]) -> dict:
        region_a, region_b = key
        is_interlot = key in interlot_pairs
        international = sovereign(region_a) != sovereign(region_b)
        edge = {
            "id": f"adj_{region_a}_{region_b}",
            "region_a_id": region_a,
            "region_b_id": region_b,
            "connection_type": "land",
            "boundary_kind": "national" if international else "regional",
            "terrain_boundary_class": "national" if international else "regional",
            "is_international_border_1914": international,
            "sovereign_a": sovereign(region_a),
            "sovereign_b": sovereign(region_b),
            "natural_obstacles": [],
            "documented_passages": [],
            "source_refs": ["audit_map_1914", "regis_2026_v1"],
        }
        if is_interlot:
            external = external_by_pair.get(key)
            if external is None:
                raise SystemExit(f"Interface inter-lots absente du lot agent_2 : {key}")
            edge["shared_border_km"] = external["shared_border_km"]
            edge["shared_border_km_source"] = "agent_2_external_interface"
            edge["notes"] = external.get("notes", "")
            edge["interlot_interface"] = True
            edge["topology_action"] = "BLK-003"
            if key == ("region_026", "region_056"):
                # Valeur de référence de l'audit ; la mesure géométrique est
                # conservée séparément dans geometry_shared_border_km.
                edge["shared_border_km"] = 368.87
                edge["shared_border_km_source"] = "audit_map_1914"
                edge["agent_2_shared_border_km"] = external["shared_border_km"]
        else:
            edge["shared_border_km"] = 1.43
            edge["shared_border_km_source"] = "audit_map_1914"
            edge["notes"] = (
                "Interface terrestre de 1,43 km près de Bregenz / Lindau, sur la "
                "rive orientale du lac de Constance, omise dans "
                "agent_1/adjacency.json (MAJ-007)."
            )
            edge["missing_land_edge"] = True
            edge["topology_action"] = "MAJ-007"
        edge["geometry_shared_border_km"] = round(geometric_pairs[key], 2)
        return edge

    edges = []
    for key in sorted(geometric_pairs, key=lambda item: (rid_sort_key(item[0]), rid_sort_key(item[1]))):
        source = source_edges.get(key)
        if source is None:
            edges.append(make_added_edge(key))
            continue
        edge = dict(source)
        edge["geometry_shared_border_km"] = round(geometric_pairs[key], 2)
        edges.append(edge)

    edge_pairs = {
        pair_key(edge["region_a_id"], edge["region_b_id"]) for edge in edges
    }
    if edge_pairs != set(geometric_pairs):
        raise SystemExit("Le graphe terrestre ne correspond pas aux interfaces mesurées")

    neighbors_by_region = {region_id: [] for region_id in region_ids}
    for region_a, region_b in edge_pairs:
        neighbors_by_region[region_a].append(region_b)
        neighbors_by_region[region_b].append(region_a)
    for region_id, neighbors in neighbors_by_region.items():
        neighbors.sort(key=rid_sort_key)

    isolated = {region_id for region_id, neighbors in neighbors_by_region.items() if not neighbors}
    if isolated != EXPECTED_ISOLATED_REGIONS:
        raise SystemExit(
            f"Régions isolées inattendues : {sorted(isolated)} "
            f"(attendu {sorted(EXPECTED_ISOLATED_REGIONS)})"
        )

    # Détroits : conserver les traversées inter-régionales, isoler les détroits
    # strictement internes à une région, puis ajouter les quatre passages ouest.
    strait_crossings: dict[tuple[str, str], dict] = {}
    internal_straits: list[dict] = []
    for adjacency in source_adjacency.values():
        for strait in adjacency.get("strait_crossings", []):
            if strait["region_a_id"] == strait["region_b_id"]:
                internal = {
                    key: value
                    for key, value in strait.items()
                    if key not in ("region_a_id", "region_b_id")
                }
                internal["region_id"] = strait["region_a_id"]
                internal["connection_type"] = "internal_strait"
                internal["boundary_kind"] = "strait"
                internal_straits.append(internal)
                continue
            key = pair_key(strait["region_a_id"], strait["region_b_id"])
            if key in strait_crossings:
                raise SystemExit(f"Détroit inter-régional dupliqué : {key}")
            strait_crossings[key] = dict(strait)

    for strait in NEW_STRAITS:
        key = pair_key(strait["region_a_id"], strait["region_b_id"])
        if key in strait_crossings:
            raise SystemExit(f"Détroit dupliqué : {key}")
        if key in edge_pairs:
            raise SystemExit(f"Nouveau détroit en conflit avec une arête terrestre : {key}")
        entry = dict(strait)
        entry["connection_type"] = "strait"
        entry["boundary_kind"] = "strait"
        entry["is_international_border_1914"] = (
            sovereign(strait["region_a_id"]) != sovereign(strait["region_b_id"])
        )
        entry["sovereign_a"] = sovereign(strait["region_a_id"])
        entry["sovereign_b"] = sovereign(strait["region_b_id"])
        entry["topology_action"] = "MAJ-007"
        strait_crossings[key] = entry

    # Une même paire peut légitimement cumuler une frontière terrestre et une
    # liaison maritime (cas 053/054, Moonsund + frontière de Courlande). Le
    # doublon est signalé sans fusionner les deux types de relation.
    for key, strait in strait_crossings.items():
        if key in edge_pairs:
            strait["also_land_adjacent"] = True

    # Connexions entre zones maritimes, dérivées du catalogue agent_2.
    maritime_doc = load_json(LOT_DIRS["agent_2"] / "maritime_zones.json")
    maritime_zones = {zone["id"]: zone for zone in maritime_doc["maritime_zones"]}
    maritime_pairs: set[tuple[str, str]] = set()
    for zone_id, zone in maritime_zones.items():
        for other_id in zone.get("adjacent_maritime_zone_ids", []):
            if zone_id == other_id:
                raise SystemExit(f"Auto-boucle de zone maritime : {zone_id}")
            if other_id not in maritime_zones:
                raise SystemExit(f"Zone maritime inconnue : {other_id}")
            maritime_pairs.add(tuple(sorted((zone_id, other_id))))

    for zone_a, zone_b in maritime_pairs:
        if zone_b not in maritime_zones[zone_a].get("adjacent_maritime_zone_ids", []):
            raise SystemExit(f"Connexion maritime non réciproque : {zone_a} / {zone_b}")

    maritime_connections = []
    for zone_a, zone_b in sorted(maritime_pairs):
        maritime_connections.append(
            {
                "id": "mzconn_"
                + zone_a.removeprefix("mz_")
                + "__"
                + zone_b.removeprefix("mz_"),
                "zone_a_id": zone_a,
                "zone_b_id": zone_b,
                "connection_type": "maritime_zone",
                "boundary_kind": "sea",
                "source_refs": ["natural_earth_10m_v5", "regis_2026_v1"],
            }
        )
    isolated_maritime = sorted(
        zone_id for zone_id in maritime_zones
        if not any(zone_id in pair for pair in maritime_pairs)
    )

    output = {
        "schema_version": "1.1.0",
        "atlas": "Grand Strategy-1914",
        "reference_date": "1914-01-01",
        "generated_from": {
            "audit_commit": "b5a07aee2d6d545ebf42ec682ec9d0dd25353387",
            "agent_1": {
                "branch": "agent_1",
                "commit": "286975a96fc2238040a9bf09163c664740ee3854",
                "regions": 50,
                "build_path": "data/world/map/build/agent_1",
            },
            "agent_2": {
                "branch": "agent-2",
                "commit": "baa0c90932c74a39ae8745add9a07a7686cd770e",
                "regions": 40,
                "build_path": "data/world/map/build/agent_2",
            },
        },
        "construction_method": {
            "land_adjacency": (
                "Intersection des frontières des polygones en EPSG:3035, "
                "seuil de 10 m ; aucune arête sans support géométrique."
            ),
            "straits": (
                "Passages maritimes distincts des frontières terrestres ; "
                "les détroits strictement internes sont séparés."
            ),
            "maritime_zones": (
                "Connexions dérivées de adjacent_maritime_zone_ids du catalogue "
                "agent_2 et vérifiées réciproques."
            ),
        },
        "total_regions": len(region_ids),
        "total_land_edges": len(edges),
        "land_edges_by_origin": {
            "agent_1_internal": len(source_adjacency["agent_1"]["edges"]),
            "agent_2_internal": len(source_adjacency["agent_2"]["edges"]),
            "interlot": len(interlot_pairs),
            "added_missing_agent_1": 1,
        },
        "total_interlot_land_interfaces": len(interlot_pairs),
        "total_strait_crossings": len(strait_crossings),
        "total_internal_straits": len(internal_straits),
        "total_maritime_zone_connections": len(maritime_connections),
        "neighbors_by_region": neighbors_by_region,
        "adjacent_region_ids": neighbors_by_region,
        "isolated_regions": [
            {
                "id": region_id,
                "name_fr": all_regions[region_id]["name_fr"],
                "reason": ISOLATED_REGION_REASONS[region_id],
            }
            for region_id in sorted(isolated, key=rid_sort_key)
        ],
        "interlot_interface_pairs": [
            f"{region_a}<->{region_b}"
            for region_a, region_b in sorted(
                interlot_pairs, key=lambda item: (rid_sort_key(item[0]), rid_sort_key(item[1]))
            )
        ],
        "edges": edges,
        "strait_crossings": [
            strait_crossings[key]
            for key in sorted(
                strait_crossings,
                key=lambda item: (rid_sort_key(item[0]), rid_sort_key(item[1])),
            )
        ],
        "internal_straits": sorted(internal_straits, key=lambda item: item["id"]),
        "maritime_zone_ids": sorted(maritime_zones),
        "isolated_maritime_zones": isolated_maritime,
        "maritime_zone_connections": maritime_connections,
    }

    OUT_PATH.write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Écrit : {OUT_PATH}")
    print(f"Arêtes terrestres : {len(edges)}")
    print(f"Interfaces inter-lots : {len(interlot_pairs)}")
    print(f"Détroits inter-régionaux : {len(strait_crossings)}")
    print(f"Détroits internes : {len(internal_straits)}")
    print(f"Connexions de zones maritimes : {len(maritime_connections)}")
    print(f"Régions isolées : {sorted(isolated)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
