#!/usr/bin/env python3
"""Aligne le catalogue des zones maritimes sur les contacts géométriques mesurés (C2a).

Source de vérité : `adjacency.json` → `region_maritime_zone_links` avec
`derivation == "geometry"` (contact région/zone ≤ 200 m ou frontière partagée > 50 m,
mesuré par rebuild_topology.py sur la géométrie validée).

Pour chaque lien géométrique absent du catalogue, la région est ajoutée aux
`coastal_region_ids` de la zone, dans la liste de tête `maritime_zones` et dans les
propriétés de l'entité GeoJSON, en ordre trié. Elle est retirée des
`external_coastal_region_ids` de cette même zone.

Le script n'ajoute ni zone ni lien non géométrique, et ne retire jamais un lien
déclaré : le lien 051 ↔ mz_norwegian_sea, catalogue seulement, reste en place et
fait l'objet de docs/map/decisions/REGION_051_ISLANDE.md.

Usage : python tools/map/sync_maritime_catalogue.py [--check]
Après écriture, reconstruire la topologie : python tools/map/rebuild_topology.py
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOGUE = ROOT / "data/world/map/build/agent_2/maritime_zones.json"
ADJACENCY = ROOT / "data/world/map/adjacency.json"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="n'écrit rien ; code 1 si un lien géométrique n'est pas catalogué")
    arguments = parser.parse_args()
    original = CATALOGUE.read_text(encoding="utf-8")
    document = json.loads(original)
    adjacency = json.loads(ADJACENCY.read_text(encoding="utf-8"))

    missing: dict[str, set[str]] = {}
    for link in adjacency["region_maritime_zone_links"]:
        if link["derivation"] == "geometry" and not link["catalogue_declared"]:
            missing.setdefault(link["maritime_zone_id"], set()).add(link["region_id"])

    features = {feature["id"]: feature for feature in document["features"]}
    added = []
    for zone in document["maritime_zones"]:
        regions = missing.get(zone["id"], set())
        if not regions:
            continue
        for record in (zone, features[zone["id"]]["properties"]):
            record["coastal_region_ids"] = sorted(set(record["coastal_region_ids"]) | regions)
            if "external_coastal_region_ids" in record:
                record["external_coastal_region_ids"] = [
                    rid for rid in record["external_coastal_region_ids"] if rid not in regions]
        added.extend(f"{rid} -> {zone['id']}" for rid in sorted(regions))

    if arguments.check:
        if added:
            print(f"[FAIL] {len(added)} lien(s) géométrique(s) non catalogué(s) : {added}")
            return 1
        print("[PASS] Catalogue maritime aligné sur les contacts géométriques")
        return 0
    CATALOGUE.write_text(json.dumps(document, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"{len(added)} lien(s) ajouté(s) au catalogue :")
    for line in added:
        print("  ", line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
