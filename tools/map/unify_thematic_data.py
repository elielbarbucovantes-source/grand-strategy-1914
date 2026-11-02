#!/usr/bin/env python3
"""Assemble the 1914 thematic map layers from the two agent build lots.

The script is deliberately step-wise and deterministic:

    python3 tools/map/unify_thematic_data.py cities
    python3 tools/map/unify_thematic_data.py terrain
    python3 tools/map/unify_thematic_data.py infrastructure
    python3 tools/map/unify_thematic_data.py maritime
    python3 tools/map/unify_thematic_data.py all

By default the source lots are read from the ``agent_1`` and ``agent-2`` Git
branches, so the script works from the audit/integration branch where the
``data/world/map/build`` directories are not checked out.  ``--build-root`` can
point at an extracted copy of the two lots instead.
"""
from __future__ import annotations

import argparse
import json
import math
import subprocess
import sys
from collections import Counter, OrderedDict
from copy import deepcopy
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "data/world/map"
PLAN_CSV = OUT_DIR / "tables/region_plan.csv"
EXPECTED_REGION_IDS = [f"region_{i:03d}" for i in range(1, 91)]

# Shapely/pyproj are not installed system-wide in the development image.
for _pkg in ("/tmp/gs1914-gis-packages",):
    if Path(_pkg).exists() and _pkg not in sys.path:
        sys.path.insert(0, _pkg)

SOURCE_REFS = {
    "regis": "regis_2026_v1",
    "baedeker": "baedeker_bradshaw_1914",
    "ristat": "ristat_1897_v1",
    "natural_earth": "natural_earth_10m_v5",
}

# ---------------------------------------------------------------------------
# Source loading
# ---------------------------------------------------------------------------


def _git_show(ref: str, rel_path: str) -> Any:
    try:
        raw = subprocess.check_output(
            ["git", "-C", str(ROOT), "show", f"{ref}:{rel_path}"],
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as exc:
        raise SystemExit(
            f"Impossible de lire {ref}:{rel_path}. "
            "Utiliser --build-root si les branches agent_1/agent-2 ne sont pas disponibles."
        ) from exc
    return json.loads(raw.decode("utf-8"))


def load_source(
    build_root: Path | None,
    lot: str,
    filename: str,
) -> Any:
    rel = f"data/world/map/build/{lot}/{filename}"
    if build_root is not None:
        path = build_root / lot / filename
        if not path.exists():
            raise SystemExit(f"Fichier source absent: {path}")
        return json.loads(path.read_text(encoding="utf-8"))
    ref = "agent_1" if lot == "agent_1" else "agent-2"
    return _git_show(ref, rel)


def load_all_sources(build_root: Path | None) -> dict[str, Any]:
    return {
        "a1_cities": load_source(build_root, "agent_1", "cities.json"),
        "a2_cities": load_source(build_root, "agent_2", "cities.json"),
        "a1_terrain": load_source(build_root, "agent_1", "terrain.json"),
        "a2_terrain": load_source(build_root, "agent_2", "terrain.json"),
        "a1_infra": load_source(build_root, "agent_1", "infrastructure.json"),
        "a2_infra": load_source(build_root, "agent_2", "infrastructure.json"),
        "a1_regions": load_source(build_root, "agent_1", "regions.json"),
        "a2_regions": load_source(build_root, "agent_2", "regions.json"),
        "a1_geojson": load_source(build_root, "agent_1", "regions.geojson"),
        "a2_geojson": load_source(build_root, "agent_2", "regions.geojson"),
        "a2_maritime": load_source(build_root, "agent_2", "maritime_zones.json"),
    }


# ---------------------------------------------------------------------------
# Generic helpers
# ---------------------------------------------------------------------------


def dump_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    path.write_text(text, encoding="utf-8")


def unique(values: Iterable[Any]) -> list[Any]:
    seen = set()
    out = []
    for value in values:
        if value not in seen:
            seen.add(value)
            out.append(value)
    return out


def sorted_unique(values: Iterable[Any]) -> list[Any]:
    return sorted(set(values))


def drop_external_keys(value: Any) -> Any:
    """Recursively remove temporary ``external_*`` construction keys."""
    if isinstance(value, dict):
        return {
            key: drop_external_keys(item)
            for key, item in value.items()
            if not key.startswith("external_")
        }
    if isinstance(value, list):
        return [drop_external_keys(item) for item in value]
    return value


def source_refs(*groups: Iterable[str]) -> list[str]:
    return sorted_unique(ref for group in groups for ref in group)


def round_coord(value: float, digits: int = 6) -> float:
    return round(float(value), digits)


def round_coords(value: Any, digits: int = 6) -> Any:
    if isinstance(value, (int, float)):
        return round_coord(value, digits)
    if isinstance(value, (list, tuple)):
        return [round_coords(item, digits) for item in value]
    raise TypeError(f"Type de coordonnée inattendu: {type(value)!r}")


# ---------------------------------------------------------------------------
# Cities
# ---------------------------------------------------------------------------

CITY_NAME_CLEANUPS = {
    "Ekaterinoslav (Dniepropetrovsk)": "Ekaterinoslav",
}


def clean_city_name(name: str) -> str:
    return CITY_NAME_CLEANUPS.get(name, name)


def city_feature(city: dict[str, Any]) -> dict[str, Any]:
    properties = {key: deepcopy(value) for key, value in city.items() if key != "coordinates"}
    properties["name_fr"] = clean_city_name(properties["name_fr"])
    return OrderedDict(
        [
            ("type", "Feature"),
            ("id", city["id"]),
            ("geometry", {"type": "Point", "coordinates": list(city["coordinates"])}),
            ("properties", properties),
        ]
    )


def build_cities(sources: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    records = []
    for record in sources["a1_cities"]["cities"] + sources["a2_cities"]["cities"]:
        item = deepcopy(record)
        item["name_fr"] = clean_city_name(item["name_fr"])
        records.append(item)
    records.sort(key=lambda item: (item["region_id"], item["id"]))

    data = OrderedDict(
        [
            ("type", "FeatureCollection"),
            ("schema_version", "1.0.0"),
            ("reference_date", "1914-01-01"),
            ("total_cities", len(records)),
            ("capital_count", sum(1 for item in records if item.get("is_capital"))),
            ("cities", records),
            ("features", [city_feature(item) for item in records]),
        ]
    )
    dump_json(output_dir / "cities.json", data)
    print(f"cities.json: {len(records)} villes, {data['capital_count']} capitales")
    return data


# ---------------------------------------------------------------------------
# Terrain
# ---------------------------------------------------------------------------

RIVER_MERGES = {
    "river_danube_lower": "river_danube",
    "river_vistula_middle": "river_vistula",
}
MOUNTAIN_MERGES = {
    "mtn_carpathians_east_south": "mtn_carpathians",
    "mtn_dinaric_prokletije_sar": "mtn_dinaric_alps",
}
MERGED_RIVER_TARGETS = {
    "river_danube",
    "river_vistula",
    "river_dniester",
    "river_niemen",
    "river_sava",
    "river_drina",
}
MERGED_MOUNTAIN_TARGETS = {"mtn_carpathians", "mtn_dinaric_alps"}


def _merge_relief_records(
    base_records: list[dict[str, Any]],
    extra_records: list[dict[str, Any]],
    aliases: dict[str, str],
    merged_targets: set[str],
) -> list[dict[str, Any]]:
    merged: list[dict[str, Any]] = [deepcopy(item) for item in base_records]
    by_id = {item["id"]: item for item in merged}

    def merge_into(target: dict[str, Any], extra: dict[str, Any]) -> None:
        target["region_ids"] = unique(list(target.get("region_ids", [])) + list(extra.get("region_ids", [])))
        target["source_refs"] = source_refs(target.get("source_refs", []), extra.get("source_refs", []))
        if "strategic_passes" in target or "strategic_passes" in extra:
            target["strategic_passes"] = unique(
                list(target.get("strategic_passes", [])) + list(extra.get("strategic_passes", []))
            )
        if extra.get("is_navigable"):
            target["is_navigable"] = True
        source_ids = set(target.get("source_ids", [target["id"]]))
        source_ids.update(extra.get("source_ids", [extra["id"]]))
        source_ids.add(extra["id"])
        if target["id"] in merged_targets and len(source_ids) > 1:
            target["source_ids"] = sorted(source_ids)

    for extra in extra_records:
        target_id = aliases.get(extra["id"], extra["id"])
        if target_id in by_id:
            merge_into(by_id[target_id], extra)
        else:
            item = deepcopy(extra)
            item["id"] = target_id
            if target_id in merged_targets:
                item["source_ids"] = [extra["id"]] if extra["id"] == target_id else [extra["id"]]
            merged.append(item)
            by_id[target_id] = item
    return merged


def zone_coastal_map(maritime_source: dict[str, Any]) -> dict[str, list[str]]:
    """Return ``zone_id -> coastal regions`` for the original 16 + western zones."""
    mapping: dict[str, list[str]] = {}
    for zone in maritime_source["maritime_zones"]:
        regions = list(zone.get("coastal_region_ids", [])) + list(
            zone.get("external_coastal_region_ids", [])
        )
        mapping[zone["id"]] = sorted_unique(regions)
    for spec in NEW_MARITIME_ZONES:
        mapping[spec["id"]] = sorted_unique(spec["coastal_region_ids"])
    return mapping


def build_terrain(sources: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    a1 = sources["a1_terrain"]
    a2 = sources["a2_terrain"]

    profiles: dict[str, Any] = {}
    for rid in EXPECTED_REGION_IDS:
        if rid in a1["regions_terrain"]:
            profile = deepcopy(a1["regions_terrain"][rid])
        elif rid in a2["regions_terrain"]:
            profile = deepcopy(a2["regions_terrain"][rid])
        else:
            raise ValueError(f"Profil de relief absent pour {rid}")
        profile["region_id"] = rid
        if profile.get("island_class", "missing") is None:
            profile.pop("island_class", None)
        profile = drop_external_keys(profile)
        profiles[rid] = profile

    rivers = _merge_relief_records(
        a1["major_rivers"], a2["major_rivers"], RIVER_MERGES, MERGED_RIVER_TARGETS
    )
    mountains = _merge_relief_records(
        a1["mountain_chains"], a2["mountain_chains"], MOUNTAIN_MERGES, MERGED_MOUNTAIN_TARGETS
    )

    coastal_by_zone = zone_coastal_map(sources["a2_maritime"])
    zones_by_region: dict[str, list[str]] = {rid: [] for rid in EXPECTED_REGION_IDS}
    for zone_id, regions in coastal_by_zone.items():
        for rid in regions:
            if rid not in zones_by_region:
                raise ValueError(f"Zone {zone_id} référence une région inconnue: {rid}")
            zones_by_region[rid].append(zone_id)
    for rid, profile in profiles.items():
        existing = profile.get("maritime_zone_ids", [])
        profile["maritime_zone_ids"] = sorted_unique(existing + zones_by_region[rid])
        if not profile["maritime_zone_ids"]:
            profile.pop("maritime_zone_ids", None)

    data = OrderedDict(
        [
            ("schema_version", "1.0.0"),
            ("reference_date", "1914-01-01"),
            ("allowed_relief_categories", deepcopy(a1["allowed_relief_categories"])),
            ("total_regions", len(profiles)),
            ("total_major_rivers", len(rivers)),
            ("total_mountain_chains", len(mountains)),
            ("regions_terrain", profiles),
            ("major_rivers", rivers),
            ("mountain_chains", mountains),
        ]
    )
    dump_json(output_dir / "terrain.json", data)
    print(
        f"terrain.json: {len(profiles)} profils, "
        f"{len(rivers)} fleuves, {len(mountains)} massifs"
    )
    return data


# ---------------------------------------------------------------------------
# Infrastructure
# ---------------------------------------------------------------------------

RUSSIAN_GAUGE_IDS = {
    "rail_ru_helsingfors_viborg_stpetersburg",
    "rail_ru_stpetersburg_reval",
    "rail_ru_stpetersburg_pskov_vilna_warsaw",
    "rail_ru_pskov_riga",
    "rail_ru_riga_libau_romny",
    "rail_ru_kovno_vilna",
    "rail_ru_warsaw_lomza_grodno",
    "rail_ru_warsaw_ivangorod_lublin",
    "rail_ru_warsaw_brest_minsk_moscow",
    "rail_ru_brest_rovno_kiev",
    "rail_ru_zhitomir_kamenets",
    "rail_ru_kiev_odessa",
    "rail_ru_odessa_kishinev",
    "rail_ru_kiev_poltava_kharkov",
    "rail_ru_moscow_tula_kharkov_sevastopol",
    "rail_ru_kharkov_ekaterinoslav",
    "rail_ru_kharkov_donbass_taganrog",
    "rail_ru_yuzovka_rostov",
    "rail_ru_stpetersburg_moscow",
    "rail_ru_stpetersburg_vologda_perm",
    "rail_ru_moscow_vologda_arkhangelsk",
    "rail_ru_moscow_nizhny_kazan",
    "rail_ru_moscow_saratov_astrakhan",
    "rail_ru_moscow_samara_ufa_transsiberian",
    "rail_ru_saratov_astrakhan_orenburg",
    "rail_ru_moscow_voronezh_rostov",
    "rail_ru_rostov_novorossiysk_vladikavkaz",
}
IRISH_GAUGE_IDS = {"rail_ire_dublin_belfast", "rail_ire_dublin_cork"}

GAUGE_NOTES = {
    1435: "Écartement standard (4 ft 8½ in)",
    1524: "Écartement russe (5 ft)",
    1600: "Écartement irlandais (5 ft 3 in)",
    1672: "Écartement ibérique (5 ft 5½ in)",
}


def gauge_for_source_route(route_id: str) -> int:
    if route_id in RUSSIAN_GAUGE_IDS:
        return 1524
    if route_id in IRISH_GAUGE_IDS:
        return 1600
    if route_id.startswith("rail_ib_"):
        return 1672
    return 1435


def new_rail(
    *,
    route_id: str,
    name_fr: str,
    from_city: dict[str, Any],
    to_city: dict[str, Any],
    coordinates: list[list[float]],
    region_ids: list[str],
    gauge_mm: int,
    source_refs_list: list[str],
    historical_via: list[str],
    approximation: str,
    gauge_scope: str = "single",
    gauge_segments: list[dict[str, Any]] | None = None,
    gauge_change_points: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    if coordinates[0] != list(from_city["coordinates"]):
        raise ValueError(f"{route_id}: première coordonnée différente de {from_city['id']}")
    if coordinates[-1] != list(to_city["coordinates"]):
        raise ValueError(f"{route_id}: dernière coordonnée différente de {to_city['id']}")

    properties: dict[str, Any] = OrderedDict(
        [
            ("id", route_id),
            ("name_fr", name_fr),
            ("network_type", "railway"),
            ("network_class", "main"),
            ("is_major_axis", True),
            ("from_region_id", from_city["region_id"]),
            ("to_region_id", to_city["region_id"]),
            ("from_site_id", from_city["id"]),
            ("to_site_id", to_city["id"]),
            ("region_ids", list(region_ids)),
            ("gauge_mm", gauge_mm),
            ("gauge_scope", gauge_scope),
            ("gauge_note", GAUGE_NOTES[gauge_mm]),
            ("historical_via", list(historical_via)),
            ("approximation", approximation),
            ("source_refs", source_refs_list),
        ]
    )
    if gauge_segments is not None:
        properties["gauge_segments"] = gauge_segments
    if gauge_change_points is not None:
        properties["gauge_change_points"] = gauge_change_points
    return OrderedDict(
        [
            ("type", "Feature"),
            ("id", route_id),
            (
                "geometry",
                {
                    "type": "LineString",
                    "coordinates": [list(coord) for coord in coordinates],
                },
            ),
            ("properties", properties),
        ]
    )


def add_gauge_to_source_routes(features: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out = []
    for feature in features:
        item = deepcopy(feature)
        props = item["properties"]
        gauge = gauge_for_source_route(props["id"])
        props["gauge_mm"] = gauge
        props["gauge_scope"] = "single"
        props["gauge_note"] = GAUGE_NOTES[gauge]
        if gauge == 1524:
            props["gauge_context"] = "réseau russe/finlandais 1914"
        elif gauge == 1600:
            props["gauge_context"] = "réseau irlandais 1914"
        elif gauge == 1672:
            props["gauge_context"] = "réseau ibérique 1914"
        elif props["id"] == "rail_ru_warsaw_lodz":
            props["gauge_context"] = "ligne Varsovie–Łódź, écartement standard dans le réseau russe"
        out.append(item)
    return out


def build_new_routes(cities_by_id: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    def city(city_id: str) -> dict[str, Any]:
        return cities_by_id[city_id]

    routes = [
        new_rail(
            route_id="rail_hamburg_aarhus",
            name_fr="Ligne Hambourg — Kiel — Flensburg — Fredericia — Aarhus (Jutland)",
            from_city=city("city_hamburg"),
            to_city=city("city_aarhus"),
            coordinates=[
                [9.9937, 53.5511],
                [10.1228, 54.3233],
                [9.496, 54.783],
                [9.752, 55.565],
                [10.2039, 56.1629],
            ],
            region_ids=["region_029", "region_044"],
            gauge_mm=1435,
            source_refs_list=[SOURCE_REFS["baedeker"], SOURCE_REFS["regis"]],
            historical_via=["Kiel", "Flensburg", "Fredericia"],
            approximation="Tracé reconstitué par les nœuds ferroviaires historiques du Jutland; aucune polyligne source inter-lots n'existait.",
        ),
    ]
    routes.extend(
        [
            new_rail(
                route_id="rail_konigsberg_kovno",
                name_fr="Ligne Königsberg — Eydtkuhnen — Virbalis — Kovno (Prusse-Orientale — Pays baltes)",
                from_city=city("city_konigsberg"),
                to_city=city("city_kovno"),
                coordinates=[
                    [20.4522, 54.7104],
                    [22.5667, 54.6333],
                    [22.8167, 54.6333],
                    [23.9036, 54.8985],
                ],
                region_ids=["region_026", "region_054"],
                gauge_mm=1524,
                source_refs_list=[SOURCE_REFS["ristat"], SOURCE_REFS["baedeker"]],
                historical_via=["Eydtkuhnen", "Virbalis"],
                approximation="Tracé reconstitué par les postes-frontières historiques d'Eydtkuhnen/Virbalis; ligne à écartement russe.",
            ),
            new_rail(
                route_id="rail_posen_warsaw",
                name_fr="Ligne Posen — Thorn — Varsovie (Posnanie — Pologne russe)",
                from_city=city("city_posen"),
                to_city=city("city_warsaw"),
                coordinates=[
                    [16.9252, 52.4064],
                    [18.598, 53.013],
                    [18.7, 52.85],
                    [19.0678, 52.6483],
                    [19.945, 52.107],
                    [21.0122, 52.2297],
                ],
                region_ids=["region_027", "region_055"],
                gauge_mm=1435,
                source_refs_list=[SOURCE_REFS["baedeker"], SOURCE_REFS["regis"]],
                historical_via=["Thorn (Toruń)", "Aleksandrów", "Włocławek", "Łowicz"],
                approximation="Le tracé traverse Thorn/Aleksandrów, point de rupture de charge 1435/1524; la ville de Thorn n'a pas de fiche urbaine séparée.",
                gauge_scope="mixed",
                gauge_segments=[
                    {"gauge_mm": 1435, "from_index": 0, "to_index": 1, "note": "Posen — Thorn (Prusse)"},
                    {"gauge_mm": 1524, "from_index": 1, "to_index": 5, "note": "Thorn/Aleksandrów — Varsovie (Pologne russe)"},
                ],
                gauge_change_points=[
                    {"index": 1, "lon": 18.598, "lat": 53.013, "name": "Thorn (Toruń)"}
                ],
            ),
            new_rail(
                route_id="rail_kattowitz_warsaw",
                name_fr="Ligne Kattowitz — Częstochowa — Łódź — Varsovie (chemin de fer Varsovie-Vienne)",
                from_city=city("city_kattowitz"),
                to_city=city("city_warsaw"),
                coordinates=[
                    [19.0238, 50.2649],
                    [19.12, 50.8118],
                    [19.456, 51.7592],
                    [21.0122, 52.2297],
                ],
                region_ids=["region_030", "region_055"],
                gauge_mm=1435,
                source_refs_list=[SOURCE_REFS["baedeker"], SOURCE_REFS["regis"]],
                historical_via=["Częstochowa", "Łódź"],
                approximation="Ligne Varsovie-Vienne reconstituée par ses nœuds historiques; Łódź est la fiche source existante.",
            ),
            new_rail(
                route_id="rail_krakow_warsaw",
                name_fr="Ligne Przemyśl — Kraków — Kielce — Radom — Varsovie (Galicie — Pologne russe)",
                from_city=city("city_przemysl"),
                to_city=city("city_warsaw"),
                coordinates=[
                    [22.7678, 49.7838],
                    [19.945, 50.0647],
                    [20.628, 50.87],
                    [21.147, 51.402],
                    [21.0122, 52.2297],
                ],
                region_ids=["region_040", "region_055"],
                gauge_mm=1435,
                source_refs_list=[SOURCE_REFS["baedeker"], SOURCE_REFS["regis"]],
                historical_via=["Kraków", "Kielce", "Radom"],
                approximation="La fiche source city_przemysl regroupe Przemyśl et Cracovie; le tracé passe par les deux pour restituer la relation Galicie–Varsovie.",
            ),
            new_rail(
                route_id="rail_lemberg_kiev",
                name_fr="Ligne Lemberg — Brody — Podwoloczyska — Jitomir — Kiev (Galicie — Ukraine)",
                from_city=city("city_lemberg"),
                to_city=city("city_kiev"),
                coordinates=[
                    [24.0297, 49.8397],
                    [25.15, 50.08],
                    [26.1, 49.8],
                    [28.6587, 50.2547],
                    [30.5234, 50.4501],
                ],
                region_ids=["region_040", "region_058", "region_059"],
                gauge_mm=1435,
                source_refs_list=[SOURCE_REFS["baedeker"], SOURCE_REFS["ristat"]],
                historical_via=["Brody", "Podwoloczyska", "Jitomir"],
                approximation="Rupture de charge à la frontière austro-russe (Brody/Podwoloczyska); la fiche city_zhitomir_rovno représente Jitomir.",
                gauge_scope="mixed",
                gauge_segments=[
                    {"gauge_mm": 1435, "from_index": 0, "to_index": 2, "note": "Lemberg — Brody/Podwoloczyska (Galicie)"},
                    {"gauge_mm": 1524, "from_index": 2, "to_index": 4, "note": "Podwoloczyska — Jitomir — Kiev (Empire russe)"},
                ],
                gauge_change_points=[
                    {"index": 2, "lon": 26.1, "lat": 49.8, "name": "Podwoloczyska / Brody"}
                ],
            ),
            new_rail(
                route_id="rail_czernowitz_iasi",
                name_fr="Ligne Lemberg — Tarnopol — Czernowitz — Iași (Bucovine — Moldavie)",
                from_city=city("city_lemberg"),
                to_city=city("city_iasi"),
                coordinates=[
                    [24.0297, 49.8397],
                    [25.6, 49.55],
                    [25.935, 48.292],
                    [27.6014, 47.1585],
                ],
                region_ids=["region_040", "region_071"],
                gauge_mm=1435,
                source_refs_list=[SOURCE_REFS["baedeker"], SOURCE_REFS["regis"]],
                historical_via=["Tarnopol", "Czernowitz"],
                approximation="Czernowitz ne possède pas de fiche urbaine séparée; il est restitué comme nœud du tracé Lemberg–Iași.",
            ),
            new_rail(
                route_id="rail_brasso_bucharest",
                name_fr="Ligne Kolozsvár — Sibiu — Brassó — Sinaia — Bucarest (Transylvanie — Valachie)",
                from_city=city("city_kolozsvar"),
                to_city=city("city_bucharest"),
                coordinates=[
                    [23.6236, 46.7712],
                    [24.15, 45.8],
                    [25.6, 45.65],
                    [25.55, 45.35],
                    [26.03, 44.94],
                    [26.1025, 44.4268],
                ],
                region_ids=["region_042", "region_070"],
                gauge_mm=1435,
                source_refs_list=[SOURCE_REFS["baedeker"], SOURCE_REFS["regis"]],
                historical_via=["Sibiu", "Brassó (Brașov)", "Sinaia", "Ploiești"],
                approximation="La fiche city_kolozsvar regroupe Kolozsvár, Kronstadt et Brașov; le tracé passe par les nœuds historiques transylvains et valaques.",
            ),
            new_rail(
                route_id="rail_temesvar_bucharest",
                name_fr="Ligne Budapest — Temesvár — Craiova — Bucarest (Banat — Olténie)",
                from_city=city("city_budapest"),
                to_city=city("city_bucharest"),
                coordinates=[
                    [19.0402, 47.4979],
                    [21.227, 45.7489],
                    [23.8, 44.3167],
                    [26.1025, 44.4268],
                ],
                region_ids=["region_041", "region_070"],
                gauge_mm=1435,
                source_refs_list=[SOURCE_REFS["baedeker"], SOURCE_REFS["regis"]],
                historical_via=["Temesvár (Timișoara)", "Craiova"],
                approximation="Temesvár et Craiova n'ont pas de fiche urbaine séparée; le tracé est ancré sur Budapest et Bucarest et documente les nœuds intermédiaires.",
            ),
            new_rail(
                route_id="rail_budapest_belgrade",
                name_fr="Ligne Budapest — Újvidék — Belgrade (Orient-Express)",
                from_city=city("city_budapest"),
                to_city=city("city_belgrade"),
                coordinates=[
                    [19.0402, 47.4979],
                    [19.845, 45.251],
                    [20.4489, 44.7866],
                ],
                region_ids=["region_041", "region_074"],
                gauge_mm=1435,
                source_refs_list=[SOURCE_REFS["baedeker"], SOURCE_REFS["regis"]],
                historical_via=["Újvidék (Novi Sad)"],
                approximation="Újvidék n'a pas de fiche urbaine séparée; le tracé suit le corridor historique de l'Orient-Express par la Save.",
            ),
        ]
    )
    return routes


def build_infrastructure(sources: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    a1 = sources["a1_infra"]
    a2 = sources["a2_infra"]

    source_routes = list(a1["railways"]["features"]) + list(a2["railways"]["features"])
    routes = add_gauge_to_source_routes(source_routes)

    cities_data = build_cities(sources, output_dir)
    cities_by_id = {item["id"]: item for item in cities_data["cities"]}
    routes.extend(build_new_routes(cities_by_id))

    ports = [deepcopy(item) for item in a1["major_ports"] + a2["major_ports"]]
    for item in ports:
        item["name_fr"] = clean_city_name(item["name_fr"])
    ports.sort(key=lambda item: (item["region_id"], item["id"]))

    forts = [
        deepcopy(item)
        for item in a1["fortifications"]["features"] + a2["fortifications"]["features"]
    ]
    forts.sort(key=lambda item: (item["properties"]["region_id"], item["id"]))

    regional: dict[str, Any] = {}
    for rid in EXPECTED_REGION_IDS:
        if rid in a1["regional_infrastructure"]:
            item = deepcopy(a1["regional_infrastructure"][rid])
        elif rid in a2["regional_infrastructure"]:
            item = deepcopy(a2["regional_infrastructure"][rid])
        else:
            item = {
                "region_id": rid,
                "strategic_site_ids": [],
                "major_port_ids": [],
                "fortification_ids": [],
                "connected_railway_axis_ids": [],
                "has_major_port": False,
                "has_fortification": False,
            }
        item = drop_external_keys(item)
        item["strategic_site_ids"] = sorted_unique(
            list(item.get("strategic_site_ids", []))
            + [city["id"] for city in cities_data["cities"] if city["region_id"] == rid]
        )
        item["major_port_ids"] = sorted_unique(
            [port["id"] for port in ports if port["region_id"] == rid]
        )
        item["fortification_ids"] = sorted_unique(
            [
                fort["id"]
                for fort in forts
                if fort["properties"]["region_id"] == rid
            ]
        )
        item["has_major_port"] = bool(item["major_port_ids"])
        item["has_fortification"] = bool(item["fortification_ids"])
        regional[rid] = item

    route_regions: dict[str, list[str]] = {}
    for feature in routes:
        props = feature["properties"]
        touched = props.get("region_ids") or [props["from_region_id"], props["to_region_id"]]
        route_regions[props["id"]] = unique(touched)
        for rid in route_regions[props["id"]]:
            regional[rid]["connected_railway_axis_ids"].append(props["id"])
    for rid in EXPECTED_REGION_IDS:
        regional[rid]["connected_railway_axis_ids"] = sorted_unique(
            regional[rid].get("connected_railway_axis_ids", [])
        )

    gauge_counts = Counter(feature["properties"]["gauge_mm"] for feature in routes)
    mixed_count = sum(1 for feature in routes if feature["properties"].get("gauge_scope") == "mixed")
    data = OrderedDict(
        [
            ("schema_version", "1.0.0"),
            ("reference_date", "1914-01-01"),
            ("total_regions", len(regional)),
            ("total_railway_axes", len(routes)),
            ("total_major_ports", len(ports)),
            ("total_fortifications", len(forts)),
            (
                "gauge_summary",
                {
                    "by_gauge_mm": {str(key): gauge_counts[key] for key in sorted(gauge_counts)},
                    "mixed_gauge_axes": mixed_count,
                    "allowed_gauges_mm": [1435, 1524, 1600, 1672],
                },
            ),
            ("regional_infrastructure", regional),
            ("railways", {"type": "FeatureCollection", "features": routes}),
            ("major_ports", ports),
            ("fortifications", {"type": "FeatureCollection", "features": forts}),
        ]
    )
    dump_json(output_dir / "infrastructure.json", data)
    print(
        f"infrastructure.json: {len(routes)} axes, "
        f"{len(ports)} ports, {len(forts)} fortifications; jauges={dict(gauge_counts)}"
    )
    return data


# ---------------------------------------------------------------------------
# Maritime zones
# ---------------------------------------------------------------------------

# Additional western/Mediterranean basins needed to cover Agent 1's coastal
# regions.  Bounding boxes deliberately stop before the North African coast,
# which is outside the 90-region atlas.
NEW_MARITIME_ZONES = [
    {
        "id": "mz_english_channel",
        "name_fr": "Manche et Pas de Calais",
        "name_key": "maritime.mz_english_channel.name",
        "sea_basin": "Manche / Mer du Nord méridionale",
        "bbox": [-6.5, 49.0, 2.0, 51.4],
        "coastal_region_ids": [
            "region_001",
            "region_002",
            "region_004",
            "region_007",
            "region_008",
            "region_009",
            "region_013",
        ],
        "adjacent_zone_ids": [
            "mz_irish_sea",
            "mz_north_sea_eastern",
            "mz_northeast_atlantic",
            "mz_bay_of_biscay",
        ],
        "straits_controlled": [
            "Pas de Calais / Détroit de Douvres",
        ],
        "strait_ids": ["strait_dover_001_007"],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
    {
        "id": "mz_irish_sea",
        "name_fr": "Mer d'Irlande et canaux écossais",
        "name_key": "maritime.mz_irish_sea.name",
        "sea_basin": "Mer d'Irlande / Atlantique Nord-Est",
        "bbox": [-7.5, 51.0, -2.5, 55.6],
        "coastal_region_ids": [
            "region_002",
            "region_003",
            "region_004",
            "region_005",
            "region_006",
        ],
        "adjacent_zone_ids": ["mz_english_channel", "mz_northeast_atlantic"],
        "straits_controlled": [
            "Canal du Nord (North Channel)",
            "Canal Saint-Georges (St George's Channel)",
        ],
        "strait_ids": ["strait_north_channel_003_005", "strait_st_george_004_006"],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
    {
        "id": "mz_northeast_atlantic",
        "name_fr": "Atlantique Nord-Est et façade ibérique",
        "name_key": "maritime.mz_northeast_atlantic.name",
        "sea_basin": "Océan Atlantique Nord-Est",
        "bbox": [-16.0, 42.5, -4.0, 59.0],
        "coastal_region_ids": [
            "region_003",
            "region_005",
            "region_006",
            "region_009",
            "region_020",
            "region_021",
            "region_025",
        ],
        "adjacent_zone_ids": [
            "mz_irish_sea",
            "mz_english_channel",
            "mz_bay_of_biscay",
            "mz_norwegian_sea",
            "mz_gibraltar_alboran",
        ],
        "straits_controlled": [],
        "strait_ids": [],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
    {
        "id": "mz_bay_of_biscay",
        "name_fr": "Golfe de Gascogne",
        "name_key": "maritime.mz_bay_of_biscay.name",
        "sea_basin": "Golfe de Gascogne / Atlantique Nord-Est",
        "bbox": [-10.0, 43.0, -1.0, 48.8],
        "coastal_region_ids": ["region_009", "region_010", "region_021"],
        "adjacent_zone_ids": ["mz_northeast_atlantic", "mz_english_channel"],
        "straits_controlled": [],
        "strait_ids": [],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
    {
        "id": "mz_gibraltar_alboran",
        "name_fr": "Détroit de Gibraltar et mer d'Alboran",
        "name_key": "maritime.mz_gibraltar_alboran.name",
        "sea_basin": "Mer d'Alboran / Méditerranée occidentale",
        "bbox": [-5.5, 36.0, -1.0, 37.2],
        "coastal_region_ids": ["region_024", "region_025"],
        "adjacent_zone_ids": ["mz_northeast_atlantic", "mz_west_mediterranean"],
        "straits_controlled": ["Détroit de Gibraltar"],
        "strait_ids": ["strait_gibraltar"],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
    {
        "id": "mz_west_mediterranean",
        "name_fr": "Méditerranée occidentale et golfe du Lion",
        "name_key": "maritime.mz_west_mediterranean.name",
        "sea_basin": "Méditerranée occidentale",
        "bbox": [-1.0, 37.0, 7.0, 43.6],
        "coastal_region_ids": [
            "region_012",
            "region_022",
            "region_024",
            "region_086",
        ],
        "adjacent_zone_ids": [
            "mz_gibraltar_alboran",
            "mz_tyrrhenian_ligurian",
            "mz_adriatic_north",
        ],
        "straits_controlled": ["Bouches de Bonifacio"],
        "strait_ids": ["strait_bonifacio_012_086"],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
    {
        "id": "mz_tyrrhenian_ligurian",
        "name_fr": "Mer Tyrrhénienne et golfe de Ligurie",
        "name_key": "maritime.mz_tyrrhenian_ligurian.name",
        "sea_basin": "Méditerranée centrale / Tyrrhénienne",
        "bbox": [7.0, 38.0, 16.0, 44.2],
        "coastal_region_ids": [
            "region_012",
            "region_080",
            "region_081",
            "region_082",
            "region_085",
            "region_086",
        ],
        "adjacent_zone_ids": [
            "mz_west_mediterranean",
            "mz_adriatic_north",
            "mz_ionian_sea",
        ],
        "straits_controlled": ["Détroit de Messine"],
        "strait_ids": ["strait_messina_084_085"],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
    {
        "id": "mz_adriatic_north",
        "name_fr": "Adriatique septentrionale et centrale",
        "name_key": "maritime.mz_adriatic_north.name",
        "sea_basin": "Mer Adriatique",
        "bbox": [12.0, 42.0, 16.5, 45.8],
        "coastal_region_ids": [
            "region_037",
            "region_080",
            "region_081",
            "region_083",
        ],
        "adjacent_zone_ids": [
            "mz_west_mediterranean",
            "mz_tyrrhenian_ligurian",
            "mz_adriatic_south_otranto",
        ],
        "straits_controlled": ["Passage du Kvarner"],
        "strait_ids": ["passage_kvarner"],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
]

ZONE_STRAIT_IDS = {
    "mz_north_atlantic_iceland": ["strait_denmark_strait"],
    "mz_norwegian_sea": ["strait_giuk"],
    "mz_barents_white_sea": ["strait_white_sea_gorlo", "passage_north_cape"],
    "mz_north_sea_eastern": [],
    "mz_skagerrak_kattegat": ["strait_oresund_044_048", "strait_danish_belts_044_044"],
    "mz_baltic_south_central": ["strait_kalmar", "strait_moonsund_irbe_053_054"],
    "mz_gulf_of_bothnia": ["strait_aland_049_052", "strait_kvarken_north"],
    "mz_gulf_of_finland_riga": [
        "strait_moonsund_irbe_053_054",
        "passage_kronstadt",
        "passage_porkkala_naissaar",
    ],
    "mz_adriatic_south_otranto": ["strait_otranto"],
    "mz_ionian_sea": ["strait_corinth", "strait_rio_antirrio_077_079"],
    "mz_aegean_sea": ["strait_dardanelles_090", "passage_kythira_kassos"],
    "mz_marmara_straits": ["strait_dardanelles_090", "strait_bosphorus_087"],
    "mz_black_sea_west": ["passage_bosphorus_north", "passage_danube_sulina"],
    "mz_black_sea_east": ["strait_kerch_063_069"],
    "mz_sea_of_azov": ["strait_kerch_063_069"],
    "mz_caspian_sea": ["passage_volga_astrakhan"],
    "mz_english_channel": ["strait_dover_001_007"],
    "mz_irish_sea": ["strait_north_channel_003_005", "strait_st_george_004_006"],
    "mz_northeast_atlantic": [],
    "mz_bay_of_biscay": [],
    "mz_gibraltar_alboran": ["strait_gibraltar"],
    "mz_west_mediterranean": ["strait_bonifacio_012_086"],
    "mz_tyrrhenian_ligurian": ["strait_messina_084_085"],
    "mz_adriatic_north": ["passage_kvarner"],
}

STRATEGIC_STRAITS = [
    {
        "id": "strait_dover_001_007",
        "name_fr": "Pas de Calais / Détroit de Douvres",
        "zone_ids": ["mz_english_channel"],
        "region_ids": ["region_001", "region_007"],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
    {
        "id": "strait_north_channel_003_005",
        "name_fr": "Canal du Nord (North Channel)",
        "zone_ids": ["mz_irish_sea"],
        "region_ids": ["region_003", "region_005"],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
    {
        "id": "strait_st_george_004_006",
        "name_fr": "Canal Saint-Georges (St George's Channel)",
        "zone_ids": ["mz_irish_sea"],
        "region_ids": ["region_004", "region_006"],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
    {
        "id": "strait_bonifacio_012_086",
        "name_fr": "Bouches de Bonifacio",
        "zone_ids": ["mz_west_mediterranean"],
        "region_ids": ["region_012", "region_086"],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
    {
        "id": "strait_gibraltar",
        "name_fr": "Détroit de Gibraltar",
        "zone_ids": ["mz_gibraltar_alboran"],
        "region_ids": ["region_025"],
        "source_refs": [SOURCE_REFS["natural_earth"], SOURCE_REFS["regis"]],
    },
    {
        "id": "strait_messina_084_085",
        "name_fr": "Détroit de Messine",
        "zone_ids": ["mz_tyrrhenian_ligurian"],
        "region_ids": ["region_084", "region_085"],
        "source_refs": [SOURCE_REFS["regis"], "ciccarelli_groote_1913"],
    },
    {
        "id": "strait_oresund_044_048",
        "name_fr": "Détroit de l'Øresund",
        "zone_ids": ["mz_skagerrak_kattegat"],
        "region_ids": ["region_044", "region_048"],
        "source_refs": [SOURCE_REFS["regis"], SOURCE_REFS["baedeker"]],
    },
    {
        "id": "strait_danish_belts_044_044",
        "name_fr": "Grand Belt et Petit Belt",
        "zone_ids": ["mz_skagerrak_kattegat"],
        "region_ids": ["region_044"],
        "source_refs": [SOURCE_REFS["regis"], SOURCE_REFS["baedeker"]],
    },
    {
        "id": "strait_aland_049_052",
        "name_fr": "Mer d'Åland (Södra Kvarken)",
        "zone_ids": ["mz_gulf_of_bothnia"],
        "region_ids": ["region_049", "region_052"],
        "source_refs": [SOURCE_REFS["regis"], SOURCE_REFS["baedeker"]],
    },
    {
        "id": "strait_kvarken_north",
        "name_fr": "Kvarken du Nord (Norra Kvarken)",
        "zone_ids": ["mz_gulf_of_bothnia"],
        "region_ids": ["region_049", "region_050"],
        "source_refs": [SOURCE_REFS["regis"]],
    },
    {
        "id": "strait_kalmar",
        "name_fr": "Détroit de Kalmar",
        "zone_ids": ["mz_baltic_south_central"],
        "region_ids": ["region_048", "region_049"],
        "source_refs": [SOURCE_REFS["regis"]],
    },
    {
        "id": "strait_moonsund_irbe_053_054",
        "name_fr": "Détroit d'Irbe et Moonsund",
        "zone_ids": ["mz_baltic_south_central", "mz_gulf_of_finland_riga"],
        "region_ids": ["region_053", "region_054"],
        "source_refs": [SOURCE_REFS["ristat"]],
    },
    {
        "id": "passage_kronstadt",
        "name_fr": "Approches de Kronstadt",
        "zone_ids": ["mz_gulf_of_finland_riga"],
        "region_ids": ["region_064"],
        "source_refs": [SOURCE_REFS["ristat"]],
    },
    {
        "id": "passage_porkkala_naissaar",
        "name_fr": "Barrage naval Porkkala — Naissaar",
        "zone_ids": ["mz_gulf_of_finland_riga"],
        "region_ids": ["region_052", "region_053"],
        "source_refs": [SOURCE_REFS["ristat"]],
    },
    {
        "id": "strait_otranto",
        "name_fr": "Canal d'Otrante",
        "zone_ids": ["mz_adriatic_south_otranto"],
        "region_ids": ["region_075", "region_076"],
        "source_refs": [SOURCE_REFS["regis"]],
    },
    {
        "id": "passage_kvarner",
        "name_fr": "Passage du Kvarner",
        "zone_ids": ["mz_adriatic_north"],
        "region_ids": ["region_037", "region_043"],
        "source_refs": [SOURCE_REFS["regis"]],
    },
    {
        "id": "strait_corinth",
        "name_fr": "Canal de Corinthe",
        "zone_ids": ["mz_ionian_sea"],
        "region_ids": ["region_077", "region_079"],
        "source_refs": [SOURCE_REFS["regis"], SOURCE_REFS["baedeker"]],
    },
    {
        "id": "strait_rio_antirrio_077_079",
        "name_fr": "Détroit de Rion-Antirion",
        "zone_ids": ["mz_ionian_sea"],
        "region_ids": ["region_077", "region_079"],
        "source_refs": [SOURCE_REFS["regis"], SOURCE_REFS["baedeker"]],
    },
    {
        "id": "strait_dardanelles_090",
        "name_fr": "Détroit des Dardanelles",
        "zone_ids": ["mz_aegean_sea", "mz_marmara_straits"],
        "region_ids": ["region_090"],
        "source_refs": ["geoboundaries_tur_v6", SOURCE_REFS["baedeker"]],
    },
    {
        "id": "strait_bosphorus_087",
        "name_fr": "Détroit du Bosphore",
        "zone_ids": ["mz_marmara_straits"],
        "region_ids": ["region_087"],
        "source_refs": ["geoboundaries_tur_v6", SOURCE_REFS["baedeker"]],
    },
    {
        "id": "strait_kerch_063_069",
        "name_fr": "Détroit de Kertch",
        "zone_ids": ["mz_black_sea_east", "mz_sea_of_azov"],
        "region_ids": ["region_063", "region_069"],
        "source_refs": [SOURCE_REFS["ristat"], SOURCE_REFS["baedeker"]],
    },
    {
        "id": "strait_denmark_strait",
        "name_fr": "Détroit de Danemark (Islande — Groenland)",
        "zone_ids": ["mz_north_atlantic_iceland"],
        "region_ids": ["region_051"],
        "source_refs": [SOURCE_REFS["natural_earth"]],
    },
    {
        "id": "strait_giuk",
        "name_fr": "Passage GIUK (Islande — Féroé — Norvège)",
        "zone_ids": ["mz_norwegian_sea"],
        "region_ids": ["region_046", "region_051"],
        "source_refs": [SOURCE_REFS["natural_earth"]],
    },
    {
        "id": "strait_white_sea_gorlo",
        "name_fr": "Goulet de la mer Blanche (Gorlo)",
        "zone_ids": ["mz_barents_white_sea"],
        "region_ids": ["region_065"],
        "source_refs": [SOURCE_REFS["natural_earth"]],
    },
    {
        "id": "passage_north_cape",
        "name_fr": "Passage du cap Nord",
        "zone_ids": ["mz_barents_white_sea"],
        "region_ids": ["region_047"],
        "source_refs": [SOURCE_REFS["natural_earth"]],
    },
    {
        "id": "passage_kythira_kassos",
        "name_fr": "Passages de Cythère et de Kassos",
        "zone_ids": ["mz_aegean_sea"],
        "region_ids": ["region_079"],
        "source_refs": [SOURCE_REFS["natural_earth"]],
    },
    {
        "id": "passage_bosphorus_north",
        "name_fr": "Approches septentrionales du Bosphore",
        "zone_ids": ["mz_black_sea_west"],
        "region_ids": ["region_087"],
        "source_refs": [SOURCE_REFS["ristat"]],
    },
    {
        "id": "passage_danube_sulina",
        "name_fr": "Embouchures du Danube (Sulina / Chilia)",
        "zone_ids": ["mz_black_sea_west"],
        "region_ids": ["region_070", "region_071"],
        "source_refs": [SOURCE_REFS["regis"]],
    },
    {
        "id": "passage_volga_astrakhan",
        "name_fr": "Delta de la Volga (Astrakhan)",
        "zone_ids": ["mz_caspian_sea"],
        "region_ids": ["region_068"],
        "source_refs": [SOURCE_REFS["ristat"]],
    },
]


def _shapely_imports():
    try:
        from pyproj import Geod
        from shapely.geometry import box, mapping, shape
        from shapely.geometry.polygon import orient
        from shapely.ops import unary_union
    except ImportError as exc:  # pragma: no cover - environment guard
        raise SystemExit(
            "Shapely et pyproj sont requis pour l'étape maritime; "
            "installer tools/map/requirements.txt ou définir PYTHONPATH."
        ) from exc
    return Geod, box, mapping, shape, orient, unary_union


def _sea_zone_geometry(
    bbox: list[float],
    land,
    *,
    simplify_tolerance: float = 0.035,
) -> Any:
    _, box, _, _, orient, _ = _shapely_imports()
    sea = box(*bbox).difference(land)
    if sea.is_empty:
        raise ValueError(f"Zone maritime vide pour bbox={bbox}")
    sea = sea.buffer(0)
    sea = sea.simplify(simplify_tolerance, preserve_topology=True)
    if sea.geom_type == "Polygon":
        sea = orient(sea, sign=1.0)
    elif sea.geom_type == "MultiPolygon":
        sea = type(sea)([orient(part, sign=1.0) for part in sea.geoms if not part.is_empty])
    else:
        raise ValueError(f"Géométrie maritime inattendue: {sea.geom_type}")
    return sea


def _geom_to_geojson(geom) -> dict[str, Any]:
    _, _, mapping, _, _, _ = _shapely_imports()
    obj = mapping(geom)
    return {
        "type": obj["type"],
        "coordinates": round_coords(obj["coordinates"]),
    }


def build_maritime(sources: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    Geod, _, _, shape, _, unary_union = _shapely_imports()
    source = sources["a2_maritime"]
    source_features = {feature["id"]: feature for feature in source["features"]}
    source_props = {zone["id"]: zone for zone in source["maritime_zones"]}

    land = unary_union(
        [shape(feature["geometry"]) for feature in sources["a1_geojson"]["features"]]
        + [shape(feature["geometry"]) for feature in sources["a2_geojson"]["features"]]
    )

    zones: list[dict[str, Any]] = []
    features: list[dict[str, Any]] = []
    for source_id in [zone["id"] for zone in source["maritime_zones"]]:
        props = deepcopy(source_props[source_id])
        props = drop_external_keys(props)
        regions = list(props.get("coastal_region_ids", []))
        regions += list(source_props[source_id].get("external_coastal_region_ids", []))
        props["coastal_region_ids"] = sorted_unique(regions)
        props["adjacent_zone_ids"] = sorted_unique(
            list(props.pop("adjacent_maritime_zone_ids", []))
        )
        props["strait_ids"] = list(ZONE_STRAIT_IDS.get(source_id, []))
        props.pop("external_coastal_region_ids", None)
        props = OrderedDict(
            [
                ("id", props["id"]),
                ("name_fr", props["name_fr"]),
                ("name_key", props["name_key"]),
                ("sea_basin", props["sea_basin"]),
                ("granularity_level", props.get("granularity_level", "intermediate")),
                ("area_km2", props["area_km2"]),
                ("representative_point_lon_lat", props["representative_point_lon_lat"]),
                ("coastal_region_ids", props["coastal_region_ids"]),
                ("adjacent_zone_ids", props["adjacent_zone_ids"]),
                ("straits_controlled", props.get("straits_controlled", [])),
                ("strait_ids", props["strait_ids"]),
                ("source_refs", props.get("source_refs", [])),
                ("bbox", props["bbox"]),
            ]
        )
        zones.append(props)
        features.append(
            OrderedDict(
                [
                    ("type", "Feature"),
                    ("id", source_id),
                    ("geometry", deepcopy(source_features[source_id]["geometry"])),
                    ("properties", props),
                ]
            )
        )

    geod = Geod(ellps="WGS84")
    for spec in NEW_MARITIME_ZONES:
        geom = _sea_zone_geometry(spec["bbox"], land)
        area = abs(geod.geometry_area_perimeter(geom)[0]) / 1_000_000.0
        point = geom.representative_point()
        props = OrderedDict(
            [
                ("id", spec["id"]),
                ("name_fr", spec["name_fr"]),
                ("name_key", spec["name_key"]),
                ("sea_basin", spec["sea_basin"]),
                ("granularity_level", "intermediate"),
                ("area_km2", round(area, 2)),
                (
                    "representative_point_lon_lat",
                    [round(point.x, 6), round(point.y, 6)],
                ),
                ("coastal_region_ids", sorted_unique(spec["coastal_region_ids"])),
                ("adjacent_zone_ids", sorted_unique(spec["adjacent_zone_ids"])),
                ("straits_controlled", list(spec["straits_controlled"])),
                ("strait_ids", list(spec["strait_ids"])),
                ("source_refs", list(spec["source_refs"])),
                ("bbox", [round(value, 6) for value in geom.bounds]),
            ]
        )
        zones.append(props)
        features.append(
            OrderedDict(
                [
                    ("type", "Feature"),
                    ("id", spec["id"]),
                    ("geometry", _geom_to_geojson(geom)),
                    ("properties", props),
                ]
            )
        )

    # Symmetrise adjacency after all zones exist.
    zone_ids = {zone["id"] for zone in zones}
    adjacency = {zone["id"]: set(zone["adjacent_zone_ids"]) for zone in zones}
    for zone_id, neighbours in list(adjacency.items()):
        for neighbour in list(neighbours):
            if neighbour not in zone_ids:
                raise ValueError(f"{zone_id} référence une zone inconnue: {neighbour}")
            adjacency[neighbour].add(zone_id)
    for zone in zones:
        zone["adjacent_zone_ids"] = sorted(adjacency[zone["id"]])

    data = OrderedDict(
        [
            ("type", "FeatureCollection"),
            ("schema_version", "1.0.0"),
            ("reference_date", "1914-01-01"),
            ("granularity", "intermediate"),
            ("total_maritime_zones", len(zones)),
            ("maritime_zones", zones),
            ("features", features),
            ("strategic_straits", deepcopy(STRATEGIC_STRAITS)),
        ]
    )
    dump_json(output_dir / "maritime_zones.json", data)
    print(f"maritime_zones.json: {len(zones)} zones, {len(STRATEGIC_STRAITS)} passages stratégiques")
    return data


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "step",
        choices=["cities", "terrain", "infrastructure", "maritime", "all"],
        help="Étape à générer",
    )
    parser.add_argument(
        "--build-root",
        type=Path,
        help="Répertoire contenant agent_1/ et agent_2/ (défaut: lecture Git)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=OUT_DIR,
        help="Répertoire de sortie (défaut: data/world/map)",
    )
    args = parser.parse_args()

    sources = load_all_sources(args.build_root)
    steps = ["cities", "terrain", "infrastructure", "maritime"] if args.step == "all" else [args.step]
    for step in steps:
        if step == "cities":
            build_cities(sources, args.output_dir)
        elif step == "terrain":
            build_terrain(sources, args.output_dir)
        elif step == "infrastructure":
            build_infrastructure(sources, args.output_dir)
        elif step == "maritime":
            build_maritime(sources, args.output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
