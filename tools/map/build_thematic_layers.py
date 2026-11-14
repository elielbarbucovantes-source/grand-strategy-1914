#!/usr/bin/env python3
"""Consolide les couches thématiques des lots agent_1 / agent_2 (lot 2 : C6, C7).

Produit, de façon déterministe et sans AJOUTER aucune donnée historique :

  data/world/map/cities.json          175 villes (C6)
  data/world/map/terrain.json         profils de relief, fleuves, massifs (C7)
  data/world/map/infrastructure.json  voies ferrées, ports, places fortes (C7)

Sources : data/world/map/build/agent_1/ et agent_2/ (lots audités).

Règles :
- **Villes** : logique de tools/map/unify_thematic_data.py (commit 4dbf4f8),
  reprise à l'identique. Le résultat est identique octet pour octet au
  cities.json de 4dbf4f8. Seul nettoyage : « Ekaterinoslav (Dniepropetrovsk) »
  devient « Ekaterinoslav » (nom de 1926, OPT-001).
- **Terrain** : profils régionaux repris tels quels (clés `external_*` et
  `island_class: null` retirées ; `maritime_zone_ids` retirée, la source de vérité
  étant regions.geojson et adjacency.json). Fleuves et massifs : fusion des seules
  entités transfrontalières identifiées par l'audit global (MAJ-006).
- **Infrastructures** : union des voies ferrées, places fortes et ports des deux
  lots, ports référencés par identifiant de ville. **Aucune ligne, aucun
  écartement ni aucune connexion transfrontalière ajoutés.** Les 10 axes proposés
  par MAJ-002 restent une liste de lacunes à sourcer
  (docs/map/decisions/THEMATIC_LAYERS.md).

Le script n'emploie volontairement PAS les étapes `terrain`, `infrastructure` et
`maritime` de unify_thematic_data.py : elles injectent des zones maritimes
occidentales non décidées et des données ferroviaires non sourcées par élément.

Usage : python tools/map/build_thematic_layers.py [--check]
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import OrderedDict
from copy import deepcopy
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[2]
MAP = ROOT / "data/world/map"
BUILD = MAP / "build"
EXPECTED_REGION_IDS = [f"region_{i:03d}" for i in range(1, 91)]

CITY_NAME_CLEANUPS = {"Ekaterinoslav (Dniepropetrovsk)": "Ekaterinoslav"}
# Entités transfrontalières dédoublonnées (audit global, MAJ-006, docs/map/audit/ISSUES.json).
RIVER_MERGES = {"river_danube_lower": "river_danube", "river_vistula_middle": "river_vistula"}
MOUNTAIN_MERGES = {"mtn_carpathians_east_south": "mtn_carpathians",
                   "mtn_dinaric_prokletije_sar": "mtn_dinaric_alps"}
MERGED_RIVER_TARGETS = {"river_danube", "river_vistula", "river_dniester", "river_niemen",
                        "river_sava", "river_drina"}
MERGED_MOUNTAIN_TARGETS = {"mtn_carpathians", "mtn_dinaric_alps"}


def load(lot: str, name: str) -> Any:
    return json.loads((BUILD / lot / name).read_text(encoding="utf-8"))


def dump(data: Any) -> str:
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


def unique(values: Iterable[Any]) -> list[Any]:
    seen, out = set(), []
    for value in values:
        if value not in seen:
            seen.add(value)
            out.append(value)
    return out


def source_refs(*groups: Iterable[str]) -> list[str]:
    return sorted({ref for group in groups for ref in group})


def drop_external_keys(value: Any) -> Any:
    if isinstance(value, dict):
        return {k: drop_external_keys(v) for k, v in value.items() if not k.startswith("external_")}
    if isinstance(value, list):
        return [drop_external_keys(v) for v in value]
    return value


# --------------------------------------------------------------------------- villes
def clean_city_name(name: str) -> str:
    return CITY_NAME_CLEANUPS.get(name, name)


def city_feature(city: dict[str, Any]) -> dict[str, Any]:
    properties = {key: deepcopy(value) for key, value in city.items() if key != "coordinates"}
    properties["name_fr"] = clean_city_name(properties["name_fr"])
    return OrderedDict([("type", "Feature"), ("id", city["id"]),
                        ("geometry", {"type": "Point", "coordinates": list(city["coordinates"])}),
                        ("properties", properties)])


def build_cities() -> dict[str, Any]:
    records = []
    for record in load("agent_1", "cities.json")["cities"] + load("agent_2", "cities.json")["cities"]:
        item = deepcopy(record)
        item["name_fr"] = clean_city_name(item["name_fr"])
        records.append(item)
    records.sort(key=lambda item: (item["region_id"], item["id"]))
    return OrderedDict([
        ("type", "FeatureCollection"), ("schema_version", "1.0.0"), ("reference_date", "1914-01-01"),
        ("total_cities", len(records)),
        ("capital_count", sum(1 for item in records if item.get("is_capital"))),
        ("cities", records), ("features", [city_feature(item) for item in records]),
    ])


# --------------------------------------------------------------------------- terrain
def merge_relief(base: list[dict], extra: list[dict], aliases: dict[str, str], targets: set[str]) -> list[dict]:
    merged = [deepcopy(item) for item in base]
    by_id = {item["id"]: item for item in merged}
    for record in extra:
        target_id = aliases.get(record["id"], record["id"])
        if target_id in by_id:
            target = by_id[target_id]
            target["region_ids"] = unique(list(target.get("region_ids", [])) + list(record.get("region_ids", [])))
            target["source_refs"] = source_refs(target.get("source_refs", []), record.get("source_refs", []))
            if "strategic_passes" in target or "strategic_passes" in record:
                target["strategic_passes"] = unique(list(target.get("strategic_passes", []))
                                                    + list(record.get("strategic_passes", [])))
            if record.get("is_navigable"):
                target["is_navigable"] = True
            ids = set(target.get("source_ids", [target["id"]])) | {record["id"]}
            if target_id in targets and len(ids) > 1:
                target["source_ids"] = sorted(ids)
        else:
            item = deepcopy(record)
            item["id"] = target_id
            if target_id != record["id"]:
                item["source_ids"] = [record["id"]]
            merged.append(item)
            by_id[target_id] = item
    return merged


def build_terrain() -> dict[str, Any]:
    a1, a2 = load("agent_1", "terrain.json"), load("agent_2", "terrain.json")
    profiles: dict[str, Any] = {}
    for rid in EXPECTED_REGION_IDS:
        source = a1["regions_terrain"].get(rid) or a2["regions_terrain"].get(rid)
        if source is None:
            raise SystemExit(f"Profil de relief absent pour {rid}")
        profile = drop_external_keys(deepcopy(source))
        if profile.get("island_class", "absent") is None:
            profile.pop("island_class")
        profile.pop("maritime_zone_ids", None)
        profiles[rid] = profile
    rivers = merge_relief(a1["major_rivers"], a2["major_rivers"], RIVER_MERGES, MERGED_RIVER_TARGETS)
    mountains = merge_relief(a1["mountain_chains"], a2["mountain_chains"], MOUNTAIN_MERGES, MERGED_MOUNTAIN_TARGETS)
    return OrderedDict([
        ("schema_version", "1.0.0"), ("reference_date", "1914-01-01"),
        ("allowed_relief_categories", deepcopy(a1["allowed_relief_categories"])),
        ("total_regions", len(profiles)), ("total_major_rivers", len(rivers)),
        ("total_mountain_chains", len(mountains)),
        ("regions_terrain", profiles), ("major_rivers", rivers), ("mountain_chains", mountains),
    ])


# --------------------------------------------------------------------------- infrastructures
def build_infrastructure() -> dict[str, Any]:
    lots = [load("agent_1", "infrastructure.json"), load("agent_2", "infrastructure.json")]
    regional: dict[str, Any] = {}
    for lot in lots:
        for rid, record in lot["regional_infrastructure"].items():
            if rid in regional:
                raise SystemExit(f"Région en double dans les infrastructures : {rid}")
            regional[rid] = drop_external_keys(deepcopy(record))
    regional = OrderedDict((rid, regional[rid]) for rid in EXPECTED_REGION_IDS)
    railways = [drop_external_keys(deepcopy(f)) for lot in lots for f in lot["railways"]["features"]]
    forts = [drop_external_keys(deepcopy(f)) for lot in lots for f in lot["fortifications"]["features"]]
    port_ids = sorted(p["id"] for lot in lots for p in lot["major_ports"])
    return OrderedDict([
        ("schema_version", "1.0.0"), ("reference_date", "1914-01-01"),
        ("total_regions", len(regional)), ("total_railway_axes", len(railways)),
        ("total_major_ports", len(port_ids)), ("total_fortifications", len(forts)),
        ("note", "Union des lots agent_1 et agent_2 sans ajout. Les grands ports sont des villes "
                 "(cities.json). Les connexions ferroviaires entre lots (MAJ-002) restent à sourcer : "
                 "docs/map/decisions/THEMATIC_LAYERS.md."),
        ("regional_infrastructure", regional),
        ("railways", {"type": "FeatureCollection", "features": railways}),
        ("major_port_ids", port_ids),
        ("fortifications", {"type": "FeatureCollection", "features": forts}),
    ])


OUTPUTS = {"cities.json": build_cities, "terrain.json": build_terrain, "infrastructure.json": build_infrastructure}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="vérifie que les fichiers versionnés sont reproduits à l'identique")
    arguments = parser.parse_args()
    stale = []
    for name, builder in OUTPUTS.items():
        text = dump(builder())
        path = MAP / name
        if not path.exists() or path.read_text(encoding="utf-8") != text:
            stale.append(name)
            if not arguments.check:
                path.write_text(text, encoding="utf-8")
    if arguments.check:
        if stale:
            print(f"[FAIL] Couches thématiques non reproduites : {stale}")
            return 1
        print("[PASS] cities.json, terrain.json, infrastructure.json reproduits depuis les lots")
        return 0
    print("Fichiers écrits :", stale or "aucun (déjà à jour)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
