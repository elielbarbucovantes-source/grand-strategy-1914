#!/usr/bin/env python3
"""Régénère les attributs DÉRIVÉS des 90 régions depuis adjacency.json (C8, MAJ-005).

Les propriétés `adjacent_region_ids`, `external_adjacent_region_ids` et
`maritime_zone_ids` de regions.geojson et regions.json étaient héritées des lots
agent_1/agent_2. Elles divergeaient d'adjacency.json pour 20 régions, et la clé
`maritime_zone_ids` n'existait que pour 40 régions. Règles appliquées (décision
technique : docs/map/decisions/ATTRIBUTS_DERIVES.md) :

- `adjacent_region_ids` = `adjacency.json` → `neighbors_by_region` (frontières terrestres) ;
- `maritime_zone_ids`   = zones des `region_maritime_zone_links` de la région
  (géométriques et catalogue), triées ; présente pour les 90 régions, liste vide
  si la région n'a pas de lien ;
- `external_adjacent_region_ids` est SUPPRIMÉE : notion de périmètre de lot, sans
  objet dans l'atlas consolidé (le graphe complet est dans adjacency.json).

La géométrie, les noms, les souverainetés et toutes les autres propriétés ne sont
pas touchés. L'ordre des clés est conservé ; `maritime_zone_ids` est insérée après
`adjacent_region_ids` quand elle manque.

Point fixe : les voisinages ne dépendent que de la géométrie, et les liens
maritimes de la géométrie et du catalogue. Reconstruire adjacency.json après ce
script ne change donc pas les attributs. --check le vérifie.

Usage : python tools/map/sync_region_attributes.py [--check]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MAP = ROOT / "data/world/map"
FILES = (MAP / "regions.geojson", MAP / "regions.json")


def derived_values(adjacency: dict) -> dict[str, dict[str, list[str]]]:
    zones: dict[str, set[str]] = {rid: set() for rid in adjacency["neighbors_by_region"]}
    for link in adjacency["region_maritime_zone_links"]:
        zones[link["region_id"]].add(link["maritime_zone_id"])
    return {
        rid: {"adjacent_region_ids": list(neighbors), "maritime_zone_ids": sorted(zones[rid])}
        for rid, neighbors in adjacency["neighbors_by_region"].items()
    }


def update_record(record: dict, values: dict[str, list[str]]) -> dict:
    result: dict = {}
    for key, value in record.items():
        if key == "external_adjacent_region_ids":
            continue
        if key == "maritime_zone_ids":
            result[key] = values["maritime_zone_ids"]
            continue
        result[key] = values["adjacent_region_ids"] if key == "adjacent_region_ids" else value
        if key == "adjacent_region_ids" and "maritime_zone_ids" not in record:
            result["maritime_zone_ids"] = values["maritime_zone_ids"]
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true")
    arguments = parser.parse_args()
    adjacency = json.loads((MAP / "adjacency.json").read_text(encoding="utf-8"))
    values = derived_values(adjacency)
    stale = []
    for path in FILES:
        original = path.read_text(encoding="utf-8")
        document = json.loads(original)
        if "features" in document:
            for feature in document["features"]:
                feature["properties"] = update_record(feature["properties"], values[feature["properties"]["id"]])
        else:
            document["regions"] = [update_record(region, values[region["id"]]) for region in document["regions"]]
        output = json.dumps(document, indent=2, ensure_ascii=False) + "\n"
        if output != original:
            stale.append(path.relative_to(ROOT).as_posix())
            if not arguments.check:
                path.write_text(output, encoding="utf-8")
    if arguments.check:
        if stale:
            print(f"[FAIL] Attributs dérivés non synchronisés : {stale}")
            return 1
        print("[PASS] Attributs dérivés des 90 régions synchronisés avec adjacency.json")
        return 0
    print("Fichiers mis à jour :", stale or "aucun")
    return 0


if __name__ == "__main__":
    sys.exit(main())
