#!/usr/bin/env python3
"""Reconstruit intégralement l'adjacence des 90 régions de Grand Strategy-1914.

Le graphe est dérivé de la géométrie **définitive** consolidée :

- `data/world/map/regions.geojson` (90 polygones, EPSG:4326) est la seule
  source géométrique pour les frontières terrestres ;
- les métadonnées curatées des lots (`build/agent_1|agent_2/adjacency.json`)
  sont fusionnées sans jamais remplacer une mesure géométrique ;
- les détroits inter-régionaux et internes sont repris du catalogue curaté,
  puis revalidés contre la géométrie définitive ;
- les liens région <-> zone maritime sont dérivés des polygones de
  `build/agent_2/maritime_zones.json`, complétés par le catalogue curaté ;
- les proximités non connectées sont inventoriées séparément : une distance
  faible ne crée jamais une arête.

Le script est déterministe : aucune date, aucun identifiant aléatoire, aucun
accès réseau. Il peut être rejoué à l'identique depuis les fichiers versionnés.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

try:
    import shapely
    from pyproj import Transformer
    from shapely.geometry import shape
    from shapely.ops import nearest_points
except ImportError as exc:  # pragma: no cover - message d'installation
    raise SystemExit(
        "shapely et pyproj sont requis. Installer tools/map/requirements.txt "
        "ou utiliser PYTHONPATH=/tmp/gs1914-gis-packages."
    ) from exc

ROOT = Path(__file__).resolve().parents[2]
MAP_DIR = ROOT / "data" / "world" / "map"
REGIONS_GEOJSON = MAP_DIR / "regions.geojson"
REGIONS_INDEX = MAP_DIR / "regions.json"
LOT_DIRS = {
    "agent_1": MAP_DIR / "build" / "agent_1",
    "agent_2": MAP_DIR / "build" / "agent_2",
}
MARITIME_ZONES_PATH = LOT_DIRS["agent_2"] / "maritime_zones.json"
OUT_PATH = MAP_DIR / "adjacency.json"

SCHEMA_VERSION = "2.0.0"
SHARED_BOUNDARY_TOLERANCE_M = 10.0
MARITIME_TOUCH_TOLERANCE_M = 200.0
MARITIME_SHARED_BOUNDARY_MIN_M = 50.0
PROXIMITY_THRESHOLD_KM = 20.0
STRAIT_MAX_DISTANCE_KM = 100.0

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

# Les quatre détroits occidentaux ne figuraient dans aucun lot source : ils
# sont documentés ici, avec leurs références, puis revalidés géométriquement.
WESTERN_STRAITS = [
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
        "topology_action": "MAJ-007",
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
        "topology_action": "MAJ-007",
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
        "topology_action": "MAJ-007",
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
        "topology_action": "MAJ-007",
    },
]

ISOLATED_REGION_REASONS = {
    "region_051": (
        "Islande : île sans frontière terrestre ; aucun détroit inter-régional "
        "documenté ne la relie à une autre région."
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

# Qualification des proximités < 20 km qui ne sont ni une frontière terrestre
# ni un détroit documenté. Ces couples restent hors du graphe jouable.
PROXIMITY_CLASSES = {
    ("region_001", "region_009"): {
        "classification": "island_sea_gap",
        "reason": (
            "Écart minimal entre les îles Anglo-Normandes (rattachées à "
            "region_001) et la côte normande. La Manche n'est pas franchie "
            "ici par le passage documenté : le transmanche militaire et "
            "ferroviaire de 1914 est Douvres — Calais (region_001/region_007)."
        ),
    },
    ("region_013", "region_032"): {
        "classification": "third_region_interposition",
        "reason": (
            "Le Limbourg néerlandais (region_016) sépare la Flandre belge de "
            "la Rhénanie-Westphalie. L'écart résiduel de quelques kilomètres "
            "est un artefact de simplification, pas une frontière commune."
        ),
    },
    ("region_014", "region_035"): {
        "classification": "third_region_interposition",
        "reason": (
            "Le Grand-Duché de Luxembourg (region_019) sépare la Wallonie de "
            "l'Alsace-Lorraine allemande. Aucune frontière directe."
        ),
    },
    ("region_018", "region_034"): {
        "classification": "lake_gap",
        "reason": (
            "Rive suisse et rive bavaroise du lac de Constance (Bodensee). "
            "Le lac n'a pas de frontière terrestre tracée ; aucune traversée "
            "militaire documentée en 1914. La frontière terrestre "
            "germano-suisse est portée par region_033."
        ),
    },
    ("region_018", "region_035"): {
        "classification": "river_gap",
        "reason": (
            "Couloir rhénan au sud de Bâle : le fleuve n'est pas modélisé "
            "comme frontière dans la géométrie définitive. La traversée "
            "terrestre Suisse — Alsace-Lorraine est déjà portée par "
            "region_017 / region_035."
        ),
    },
    ("region_043", "region_076"): {
        "classification": "third_region_interposition",
        "reason": (
            "Le Monténégro (region_075) et sa bordure orientale séparent la "
            "Bosnie-Herzégovine autrichienne de l'Albanie. Aucune frontière "
            "commune."
        ),
    },
    ("region_046", "region_049"): {
        "classification": "lake_gap",
        "reason": (
            "Lac de Femunden / crête du Kjölen : la frontière norvégo-suédoise "
            "y est couverte par les couples 045/049 et 046/050. L'écart direct "
            "de 6 km ne crée pas une interface terrestre."
        ),
    },
    ("region_076", "region_077"): {
        "classification": "sea_gap_undocumented",
        "reason": (
            "Canal de Corfou entre l'Albanie et l'île de Corfou (region_077). "
            "Passage maritime étroit mais aucune traversée militaire ou "
            "ferroviaire de 1914 n'est documentée dans le corpus : le couple "
            "reste une proximité, pas un détroit jouable."
        ),
    },
}

MARITIME_ZONE_LINK_NOTE = (
    "Lien dérivé du contact géométrique entre la région et le polygone de "
    "zone maritime (seuil 200 m ou frontière partagée > 50 m)."
)
CATALOGUE_ONLY_NOTE = (
    "Lien déclaré par le catalogue curaté mais non reproduit par la géométrie "
    "de la zone (écart d'environ 170 km pour l'Islande). Conservé avec la "
    "mention catalogue_only ; ne vaut pas adjacence de détroit."
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


def fail(message: str) -> None:
    raise SystemExit(f"ERREUR : {message}")


def load_region_geometries() -> dict[str, object]:
    document = load_json(REGIONS_GEOJSON)
    features = document.get("features", [])
    geometries = {
        feature["properties"]["id"]: shape(feature["geometry"])
        for feature in features
    }
    if set(geometries) != EXPECTED_IDS or len(features) != 90:
        fail("regions.geojson ne couvre pas exactement region_001..region_090")
    to_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True).transform
    return {
        region_id: shapely.transform(geometry, to_3035, interleaved=False)
        for region_id, geometry in geometries.items()
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


def build_edge(
    key: tuple[str, str],
    geometries_km: dict[tuple[str, str], float],
    regions: dict[str, dict],
    source_edges: dict[tuple[str, str], tuple[dict, str]],
    external_by_pair: dict[tuple[str, str], dict],
    interlot_pairs: set[tuple[str, str]],
) -> dict:
    region_a, region_b = key
    measured_km = round(geometries_km[key], 2)

    if key in source_edges:
        source, lot_name = source_edges[key]
        edge = {
            "id": f"adj_{region_a}_{region_b}",
            "region_a_id": region_a,
            "region_b_id": region_b,
            "connection_type": "land",
            "boundary_kind": source.get("boundary_kind", "regional"),
            "terrain_boundary_class": source.get(
                "terrain_boundary_class", source.get("boundary_kind", "regional")
            ),
            "is_international_border_1914": bool(
                source.get("is_international_border_1914",
                           regions[region_a]["sovereign_1914"]
                           != regions[region_b]["sovereign_1914"])
            ),
            "sovereign_a": regions[region_a]["sovereign_1914"],
            "sovereign_b": regions[region_b]["sovereign_1914"],
            "shared_border_km": measured_km,
            "shared_border_km_source": "geometry_epsg3035",
            "curated_shared_border_km": source.get("shared_border_km"),
            "geometry_shared_border_km": measured_km,
            "natural_obstacles": source.get("natural_obstacles", []),
            "documented_passages": source.get("documented_passages", []),
            "source_refs": source.get("source_refs", ["regis_2026_v1"]),
            "origin": f"{lot_name}_internal",
        }
        if source.get("id") and source["id"] != edge["id"]:
            edge["source_edge_id"] = source["id"]
        return edge

    international = (
        regions[region_a]["sovereign_1914"] != regions[region_b]["sovereign_1914"]
    )

    if key in interlot_pairs:
        external = external_by_pair.get(key)
        if external is None:
            fail(f"Interface inter-lots absente du lot agent_2 : {key}")
        return {
            "id": f"adj_{region_a}_{region_b}",
            "region_a_id": region_a,
            "region_b_id": region_b,
            "connection_type": "land",
            "boundary_kind": "national" if international else "regional",
            "terrain_boundary_class": "national" if international else "regional",
            "is_international_border_1914": international,
            "sovereign_a": regions[region_a]["sovereign_1914"],
            "sovereign_b": regions[region_b]["sovereign_1914"],
            "shared_border_km": measured_km,
            "shared_border_km_source": "geometry_epsg3035",
            "curated_shared_border_km": external.get("shared_border_km"),
            "geometry_shared_border_km": measured_km,
            "natural_obstacles": [],
            "documented_passages": [],
            "source_refs": ["regis_2026_v1", "audit_map_1914", "agent_2"],
            "notes": external.get("notes", ""),
            "interlot_interface": True,
            "topology_action": "BLK-003",
            "origin": "interlot",
        }

    if key == EXPECTED_ADDED_PAIR:
        return {
            "id": f"adj_{region_a}_{region_b}",
            "region_a_id": region_a,
            "region_b_id": region_b,
            "connection_type": "land",
            "boundary_kind": "national",
            "terrain_boundary_class": "national",
            "is_international_border_1914": True,
            "sovereign_a": regions[region_a]["sovereign_1914"],
            "sovereign_b": regions[region_b]["sovereign_1914"],
            "shared_border_km": measured_km,
            "shared_border_km_source": "geometry_epsg3035",
            "curated_shared_border_km": 1.43,
            "geometry_shared_border_km": measured_km,
            "natural_obstacles": [],
            "documented_passages": [],
            "source_refs": ["audit_map_1914", "regis_2026_v1"],
            "notes": (
                "Interface terrestre près de Bregenz / Lindau, sur la rive "
                "orientale du lac de Constance, omise dans "
                "agent_1/adjacency.json (MAJ-007)."
            ),
            "missing_land_edge": True,
            "topology_action": "MAJ-007",
            "origin": "added_missing_agent_1",
        }

    fail(f"Interface terrestre sans métadonnée source : {key}")


def build_straits(
    regions: dict[str, dict],
    geometries: dict[str, object],
    land_pairs: set[tuple[str, str]],
) -> tuple[list[dict], list[dict]]:
    strait_crossings: dict[tuple[str, str], dict] = {}
    internal_straits: list[dict] = []

    for lot_name, directory in LOT_DIRS.items():
        adjacency = load_json(directory / "adjacency.json")
        for source in adjacency.get("strait_crossings", []):
            region_a = source["region_a_id"]
            region_b = source["region_b_id"]
            if region_a not in EXPECTED_IDS or region_b not in EXPECTED_IDS:
                fail(f"Détroit {source['id']} référence une région inconnue")
            if region_a == region_b:
                internal = {
                    key: value
                    for key, value in source.items()
                    if key not in ("region_a_id", "region_b_id")
                }
                internal["connection_type"] = "internal_strait"
                internal["boundary_kind"] = "strait"
                internal["region_id"] = region_a
                internal["origin"] = f"{lot_name}_catalogue"
                internal_straits.append(internal)
                continue
            key = pair_key(region_a, region_b)
            if key in strait_crossings:
                fail(f"Détroit inter-régional dupliqué : {key}")
            strait_crossings[key] = dict(source)
            strait_crossings[key]["origin"] = f"{lot_name}_catalogue"

    for source in WESTERN_STRAITS:
        key = pair_key(source["region_a_id"], source["region_b_id"])
        if key in strait_crossings:
            fail(f"Détroit occidental dupliqué : {key}")
        if key in land_pairs:
            fail(f"Détroit occidental en conflit avec une frontière terrestre : {key}")
        strait_crossings[key] = dict(source)
        strait_crossings[key]["origin"] = "western_catalogue"

    straits: list[dict] = []
    for key in sorted(
        strait_crossings,
        key=lambda item: (rid_sort_key(item[0]), rid_sort_key(item[1])),
    ):
        strait = dict(strait_crossings[key])
        region_a, region_b = key
        distance_km = geometries[region_a].distance(geometries[region_b]) / 1000.0
        strait["region_a_id"] = region_a
        strait["region_b_id"] = region_b
        strait["connection_type"] = "strait"
        strait["boundary_kind"] = "strait"
        strait["is_international_border_1914"] = (
            regions[region_a]["sovereign_1914"]
            != regions[region_b]["sovereign_1914"]
        )
        strait["sovereign_a"] = regions[region_a]["sovereign_1914"]
        strait["sovereign_b"] = regions[region_b]["sovereign_1914"]
        strait["measured_min_distance_km"] = round(distance_km, 2)
        if key in land_pairs:
            if distance_km > 1.0:
                fail(f"Détroit {strait['id']} marqué terrestre mais distant de "
                     f"{distance_km:.2f} km")
            strait["also_land_adjacent"] = True
            strait["measured_min_distance_km"] = 0.0
            strait["distance_note"] = (
                "Distance nulle car les deux régions se touchent aussi par une "
                "frontière terrestre ailleurs ; la largeur du détroit est celle "
                "du catalogue."
            )
        elif distance_km <= 0.0 or distance_km > STRAIT_MAX_DISTANCE_KM:
            fail(f"Détroit {strait['id']} sans support géométrique crédible "
                 f"({distance_km:.2f} km)")
        straits.append(strait)

    return straits, internal_straits


def compute_proximity_pairs(
    geometries: dict[str, object],
    land_pairs: set[tuple[str, str]],
    strait_pairs: set[tuple[str, str]],
) -> list[dict]:
    region_ids = sorted(geometries, key=rid_sort_key)
    to_4326 = Transformer.from_crs("EPSG:3035", "EPSG:4326", always_xy=True).transform
    proximities: list[dict] = []
    for index, region_a in enumerate(region_ids):
        for region_b in region_ids[index + 1 :]:
            key = (region_a, region_b)
            if key in land_pairs or key in strait_pairs:
                continue
            distance_m = geometries[region_a].distance(geometries[region_b])
            if distance_m >= PROXIMITY_THRESHOLD_KM * 1000.0:
                continue
            classification = PROXIMITY_CLASSES.get(key)
            if classification is None:
                fail(f"Proximité non qualifiée : {key} ({distance_m / 1000:.2f} km)")
            point_a, _point_b = nearest_points(geometries[region_a], geometries[region_b])
            lon, lat = to_4326(point_a.x, point_a.y)
            proximities.append(
                {
                    "id": f"prox_{region_a}_{region_b}",
                    "region_a_id": region_a,
                    "region_b_id": region_b,
                    "connection_type": "proximity_only",
                    "classification": classification["classification"],
                    "distance_km": round(distance_m / 1000.0, 2),
                    "nearest_point_lon_lat": [round(lon, 6), round(lat, 6)],
                    "reason": classification["reason"],
                }
            )
    return proximities


def build_maritime_links(
    regions: dict[str, dict],
    geometries: dict[str, object],
    maritime_document: dict,
) -> tuple[list[dict], list[dict], list[dict], list[dict]]:
    zones = {
        feature["properties"]["id"]: feature
        for feature in maritime_document["features"]
    }
    zone_geometries = {zone_id: shape(feature["geometry"])
                       for zone_id, feature in zones.items()}
    to_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True).transform
    zone_geometries = {
        zone_id: shapely.transform(geometry, to_3035, interleaved=False)
        for zone_id, geometry in zone_geometries.items()
    }
    zone_validity = {
        zone_id: bool(geometry.is_valid)
        for zone_id, geometry in zone_geometries.items()
    }

    catalogue: dict[str, set[str]] = {}
    for feature in maritime_document["features"]:
        zone_id = feature["properties"]["id"]
        for region_id in feature["properties"].get("coastal_region_ids", []):
            if region_id not in EXPECTED_IDS:
                fail(f"Zone {zone_id} référence une région inconnue : {region_id}")
            catalogue.setdefault(region_id, set()).add(zone_id)

    derived: dict[tuple[str, str], dict] = {}
    region_ids = sorted(geometries, key=rid_sort_key)
    for region_id in region_ids:
        for zone_id, zone_geometry in zone_geometries.items():
            # Une géométrie de zone invalide (auto-intersection) est nettoyée
            # uniquement pour la mesure ; le catalogue reste inchangé.
            measure_geometry = (
                zone_geometry if zone_validity[zone_id] else zone_geometry.buffer(0)
            )
            distance_m = geometries[region_id].distance(measure_geometry)
            shared = geometries[region_id].boundary.intersection(
                measure_geometry.boundary
            )
            if distance_m <= MARITIME_TOUCH_TOLERANCE_M or (
                shared.length > MARITIME_SHARED_BOUNDARY_MIN_M
            ):
                derived[(region_id, zone_id)] = {
                    "min_distance_km": round(distance_m / 1000.0, 2),
                    "shared_boundary_km": round(shared.length / 1000.0, 2),
                }

    links: dict[tuple[str, str], dict] = {}
    for (region_id, zone_id), measure in derived.items():
        links[(region_id, zone_id)] = {
            "id": f"rmz_{region_id}__{zone_id}",
            "region_id": region_id,
            "maritime_zone_id": zone_id,
            "connection_type": "region_maritime_zone",
            "derivation": "geometry",
            "geometry_contact": True,
            "min_distance_km": measure["min_distance_km"],
            "shared_boundary_km": measure["shared_boundary_km"],
            "catalogue_declared": zone_id in catalogue.get(region_id, set()),
            "source_refs": ["regions.geojson", "maritime_zones.json"],
            "note": MARITIME_ZONE_LINK_NOTE,
        }

    for region_id, zone_ids in catalogue.items():
        for zone_id in zone_ids:
            key = (region_id, zone_id)
            if key in links:
                continue
            zone_geometry = zone_geometries[zone_id]
            measure_geometry = (
                zone_geometry if zone_validity[zone_id] else zone_geometry.buffer(0)
            )
            distance_km = geometries[region_id].distance(measure_geometry) / 1000.0
            links[key] = {
                "id": f"rmz_{region_id}__{zone_id}",
                "region_id": region_id,
                "maritime_zone_id": zone_id,
                "connection_type": "region_maritime_zone",
                "derivation": "catalogue_only",
                "geometry_contact": False,
                "min_distance_km": round(distance_km, 2),
                "shared_boundary_km": 0.0,
                "catalogue_declared": True,
                "source_refs": ["maritime_zones.json", "regis_2026_v1"],
                "note": CATALOGUE_ONLY_NOTE,
            }

    ordered_links = sorted(
        links.values(),
        key=lambda item: (rid_sort_key(item["region_id"]), item["maritime_zone_id"]),
    )

    linked_regions = {link["region_id"] for link in ordered_links}
    unlinked = [
        {
            "id": region_id,
            "name_fr": regions[region_id]["name_fr"],
            "reason": (
                "Aucune zone maritime du catalogue intermédiaire ne couvre ce "
                "bassin (Manche, Atlantique, Méditerranée occidentale, etc.) ; "
                "la côte existe mais la façade n'est pas encore découpée."
            ),
        }
        for region_id in region_ids
        if regions[region_id].get("has_coastline") and region_id not in linked_regions
    ]

    maritime_zones = [
        {
            "id": feature["properties"]["id"],
            "name_fr": feature["properties"].get("name_fr", ""),
            "geometry_valid": zone_validity[feature["properties"]["id"]],
            "catalogue_coastal_region_count": len(
                feature["properties"].get("coastal_region_ids", [])
            ),
        }
        for feature in sorted(
            maritime_document["features"],
            key=lambda item: item["properties"]["id"],
        )
    ]

    return ordered_links, unlinked, maritime_zones, _build_zone_connections(
        maritime_document
    )


def _build_zone_connections(maritime_document: dict) -> list[dict]:
    zones = {
        feature["properties"]["id"]: feature["properties"]
        for feature in maritime_document["features"]
    }
    pairs: set[tuple[str, str]] = set()
    for zone_id, properties in zones.items():
        for other_id in properties.get("adjacent_maritime_zone_ids", []):
            if zone_id == other_id:
                fail(f"Auto-boucle de zone maritime : {zone_id}")
            if other_id not in zones:
                fail(f"Zone maritime inconnue : {other_id}")
            pairs.add(tuple(sorted((zone_id, other_id))))

    connections = []
    for zone_a, zone_b in sorted(pairs):
        if zone_b not in zones[zone_a].get("adjacent_maritime_zone_ids", []):
            fail(f"Connexion maritime non réciproque : {zone_a} / {zone_b}")
        connections.append(
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
    return connections


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=OUT_PATH,
        help="Chemin de sortie (défaut : data/world/map/adjacency.json).",
    )
    arguments = parser.parse_args()
    output_path: Path = arguments.output

    regions_document = load_json(REGIONS_INDEX)
    regions = {region["id"]: region for region in regions_document["regions"]}
    if set(regions) != EXPECTED_IDS or len(regions) != 90:
        fail("regions.json ne couvre pas exactement region_001..region_090")

    geometries = load_region_geometries()
    land_km = compute_land_pairs(geometries)
    if len(land_km) != EXPECTED_LAND_EDGES:
        fail(f"{EXPECTED_LAND_EDGES} interfaces terrestres attendues, "
             f"{len(land_km)} mesurées")
    land_pairs = set(land_km)

    lot_membership: dict[str, set[str]] = {}
    for lot_name, directory in LOT_DIRS.items():
        lot_document = load_json(directory / "regions.json")
        lot_membership[lot_name] = {
            region["id"] for region in lot_document["regions"]
        }
    if lot_membership["agent_1"] & lot_membership["agent_2"]:
        fail("Un identifiant appartient aux deux lots")
    if lot_membership["agent_1"] | lot_membership["agent_2"] != EXPECTED_IDS:
        fail("Les lots ne couvrent pas les 90 régions")

    interlot_pairs = {
        pair for pair in land_pairs
        if (pair[0] in lot_membership["agent_1"])
        != (pair[1] in lot_membership["agent_1"])
    }
    if interlot_pairs != EXPECTED_INTERLOT_PAIRS:
        fail(
            "Interfaces inter-lots non conformes : "
            f"manquantes={sorted(EXPECTED_INTERLOT_PAIRS - interlot_pairs)}, "
            f"en_trop={sorted(interlot_pairs - EXPECTED_INTERLOT_PAIRS)}"
        )
    if EXPECTED_ADDED_PAIR not in land_pairs:
        fail("L'interface 033 <-> 037 n'a pas de support géométrique")

    source_edges: dict[tuple[str, str], tuple[dict, str]] = {}
    for lot_name, directory in LOT_DIRS.items():
        adjacency = load_json(directory / "adjacency.json")
        for edge in adjacency["edges"]:
            key = pair_key(edge["region_a_id"], edge["region_b_id"])
            if key in source_edges:
                fail(f"Arête source dupliquée : {key}")
            if key not in land_pairs:
                fail(f"Arête source sans support géométrique définitif : {key}")
            source_edges[key] = (edge, lot_name)
    if len(source_edges) != 166:
        fail(f"166 arêtes internes attendues dans les lots, {len(source_edges)} trouvées")

    external_by_pair = {}
    agent_2_adjacency = load_json(LOT_DIRS["agent_2"] / "adjacency.json")
    for interface in agent_2_adjacency.get("external_perimeter_interfaces", []):
        key = pair_key(
            interface["from_region_id"], interface["to_external_region_id"]
        )
        if key in external_by_pair:
            fail(f"Interface inter-lots dupliquée : {key}")
        external_by_pair[key] = interface
    if set(external_by_pair) != EXPECTED_INTERLOT_PAIRS:
        fail("Le catalogue d'interfaces inter-lots ne correspond pas à la géométrie")

    edges = [
        build_edge(
            key,
            land_km,
            regions,
            source_edges,
            external_by_pair,
            interlot_pairs,
        )
        for key in sorted(
            land_km,
            key=lambda item: (rid_sort_key(item[0]), rid_sort_key(item[1])),
        )
    ]

    edge_pairs = {
        pair_key(edge["region_a_id"], edge["region_b_id"]) for edge in edges
    }
    if edge_pairs != land_pairs:
        fail("Le graphe terrestre ne correspond pas aux interfaces mesurées")

    neighbors_by_region = {
        region_id: [] for region_id in sorted(EXPECTED_IDS, key=rid_sort_key)
    }
    for region_a, region_b in edge_pairs:
        neighbors_by_region[region_a].append(region_b)
        neighbors_by_region[region_b].append(region_a)
    for region_id, neighbors in neighbors_by_region.items():
        neighbors.sort(key=rid_sort_key)

    isolated = {
        region_id for region_id, neighbors in neighbors_by_region.items()
        if not neighbors
    }
    if isolated != EXPECTED_ISOLATED_REGIONS:
        fail(f"Régions isolées inattendues : {sorted(isolated)}")

    straits, internal_straits = build_straits(regions, geometries, land_pairs)
    strait_pairs = {
        pair_key(strait["region_a_id"], strait["region_b_id"])
        for strait in straits
    }
    if len(straits) != 10:
        fail(f"10 détroits inter-régionaux attendus, {len(straits)} trouvés")
    if len(internal_straits) != 3:
        fail(f"3 détroits internes attendus, {len(internal_straits)} trouvés")

    passable_neighbors = {
        region_id: set(neighbors)
        for region_id, neighbors in neighbors_by_region.items()
    }
    for region_a, region_b in strait_pairs:
        passable_neighbors[region_a].add(region_b)
        passable_neighbors[region_b].add(region_a)
    passable_neighbors = {
        region_id: sorted(values, key=rid_sort_key)
        for region_id, values in passable_neighbors.items()
    }
    isolated_passable = {
        region_id for region_id, values in passable_neighbors.items() if not values
    }
    if isolated_passable != {"region_051"}:
        fail(f"Isolément du graphe jouable inattendu : {sorted(isolated_passable)}")

    proximities = compute_proximity_pairs(geometries, land_pairs, strait_pairs)
    expected_proximities = {
        pair_key(region_a, region_b) for region_a, region_b in PROXIMITY_CLASSES
    }
    if {pair_key(p["region_a_id"], p["region_b_id"]) for p in proximities} != (
        expected_proximities
    ):
        fail("L'inventaire des proximités ne correspond pas au référentiel")

    maritime_document = load_json(MARITIME_ZONES_PATH)
    links, unlinked_coastal, maritime_zones, zone_connections = build_maritime_links(
        regions, geometries, maritime_document
    )
    if len(links) != 67:
        fail(f"67 liens région/zone maritime attendus, {len(links)} trouvés")
    if len(unlinked_coastal) != 26:
        fail(f"26 régions côtières sans zone attendues, {len(unlinked_coastal)} trouvées")
    if len(zone_connections) != 14:
        fail(f"14 connexions entre zones attendues, {len(zone_connections)} trouvées")
    if any(
        not regions[link["region_id"]].get("has_coastline") for link in links
    ):
        fail("Une région sans côte est reliée à une zone maritime")

    zone_ids = {zone["id"] for zone in maritime_zones}
    isolated_zones = sorted(
        zone_id for zone_id in zone_ids
        if not any(
            zone_id in (connection["zone_a_id"], connection["zone_b_id"])
            for connection in zone_connections
        )
    )
    if isolated_zones != ["mz_caspian_sea"]:
        fail(f"Zone maritime isolée inattendue : {isolated_zones}")

    land_edges_by_origin = {
        "agent_1_internal": 0,
        "agent_2_internal": 0,
        "interlot": 0,
        "added_missing_agent_1": 0,
    }
    for edge in edges:
        land_edges_by_origin[edge["origin"]] += 1
    if land_edges_by_origin != {
        "agent_1_internal": 97,
        "agent_2_internal": 69,
        "interlot": 17,
        "added_missing_agent_1": 1,
    }:
        fail(f"Décomposition par origine inattendue : {land_edges_by_origin}")

    generated_from = {
        "geometry": {
            "path": str(REGIONS_GEOJSON.relative_to(ROOT)),
            "sha256": sha256_file(REGIONS_GEOJSON),
            "total_regions": 90,
        },
        "regions_index": {
            "path": str(REGIONS_INDEX.relative_to(ROOT)),
            "sha256": sha256_file(REGIONS_INDEX),
        },
        "lot_builds": {
            lot_name: {
                "path": str((directory / "adjacency.json").relative_to(ROOT)),
                "sha256": sha256_file(directory / "adjacency.json"),
                "regions": len(lot_membership[lot_name]),
            }
            for lot_name, directory in LOT_DIRS.items()
        },
        "maritime_catalogue": {
            "path": str(MARITIME_ZONES_PATH.relative_to(ROOT)),
            "sha256": sha256_file(MARITIME_ZONES_PATH),
        },
        "builder": {
            "path": str(Path(__file__).resolve().relative_to(ROOT)),
            "sha256": sha256_file(Path(__file__).resolve()),
        },
    }

    output = {
        "schema_version": SCHEMA_VERSION,
        "atlas": "Grand Strategy-1914",
        "reference_date": "1914-01-01",
        "generated_from": generated_from,
        "construction_method": {
            "land_adjacency": (
                "Intersection des frontières des 90 polygones de "
                "regions.geojson en EPSG:3035, seuil de 10 m. Aucune arête "
                "sans support géométrique ; les longueurs de catalogue sont "
                "conservées dans curated_shared_border_km."
            ),
            "straits": (
                "Détroits documentés du catalogue des lots et quatre passages "
                "occidentaux curatés, revalidés par la distance minimale "
                "EPSG:3035. Les détroits internes sont séparés des traversées "
                "inter-régionales."
            ),
            "maritime_zone_connections": (
                "Connexions dérivées de adjacent_maritime_zone_ids du "
                "catalogue agent_2 et vérifiées réciproques."
            ),
            "region_maritime_zone_links": (
                "Contact géométrique région/polygone de zone (seuil 200 m ou "
                "frontière partagée > 50 m), complété des liens déclarés par "
                "le catalogue mais non reproduits (mention catalogue_only)."
            ),
            "proximity_only_pairs": (
                "Couples distants de moins de 20 km, sans frontière terrestre "
                "ni détroit documenté : inventoriés et qualifiés, jamais "
                "convertis en adjacence."
            ),
        },
        "total_regions": len(EXPECTED_IDS),
        "total_land_edges": len(edges),
        "land_edges_by_origin": land_edges_by_origin,
        "total_interlot_land_interfaces": len(interlot_pairs),
        "total_strait_crossings": len(straits),
        "total_internal_straits": len(internal_straits),
        "total_passable_region_pairs": len(edge_pairs | strait_pairs),
        "total_maritime_zone_connections": len(zone_connections),
        "total_region_maritime_zone_links": len(links),
        "total_proximity_only_pairs": len(proximities),
        "neighbors_by_region": neighbors_by_region,
        "adjacent_region_ids": neighbors_by_region,
        "passable_neighbors_by_region": passable_neighbors,
        "isolated_regions": [
            {
                "id": region_id,
                "name_fr": regions[region_id]["name_fr"],
                "reason": ISOLATED_REGION_REASONS[region_id],
            }
            for region_id in sorted(isolated, key=rid_sort_key)
        ],
        "isolated_in_passable_graph": [
            {
                "id": "region_051",
                "name_fr": regions["region_051"]["name_fr"],
                "reason": ISOLATED_REGION_REASONS["region_051"],
            }
        ],
        "interlot_interface_pairs": [
            f"{region_a}<->{region_b}"
            for region_a, region_b in sorted(
                interlot_pairs,
                key=lambda item: (rid_sort_key(item[0]), rid_sort_key(item[1])),
            )
        ],
        "edges": edges,
        "strait_crossings": straits,
        "internal_straits": sorted(internal_straits, key=lambda item: item["id"]),
        "proximity_only_pairs": proximities,
        "maritime_zones": maritime_zones,
        "maritime_zone_ids": sorted(zone_ids),
        "isolated_maritime_zones": isolated_zones,
        "maritime_zone_connections": zone_connections,
        "region_maritime_zone_links": links,
        "coastal_regions_without_maritime_zone": unlinked_coastal,
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"Écrit : {output_path}")
    print(f"Arêtes terrestres : {len(edges)} ({land_edges_by_origin})")
    print(f"Détroits inter-régionaux : {len(straits)}")
    print(f"Détroits internes : {len(internal_straits)}")
    print(f"Couples jouables (terre + détroits) : {len(edge_pairs | strait_pairs)}")
    print(f"Connexions entre zones maritimes : {len(zone_connections)}")
    print(f"Liens région <-> zone maritime : {len(links)}")
    print(f"Régions côtières sans zone : {len(unlinked_coastal)}")
    print(f"Proximités non connectées : {len(proximities)}")
    print(f"Régions isolées (terre) : {sorted(isolated)}")
    print(f"Région isolée (graphe jouable) : {sorted(isolated_passable)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
