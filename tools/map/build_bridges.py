#!/usr/bin/env python3
"""Genere data/game/bridges.json : points de franchissement des grands fleuves.

Sources : data/world/map/terrain.json (59 rivieres). Les ponts sont des estimations de
modele (niveau C/D) : un passage principal par troncon de riviere, pas de trac precis invente.

Usage : python3 tools/map/build_bridges.py [--check]
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TERRAIN = ROOT / "data/world/map/terrain.json"
OUT = ROOT / "data/game/bridges.json"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    terrain = json.loads(TERRAIN.read_text(encoding="utf-8"))
    bridges = []
    for river in terrain["major_rivers"]:
        rids = river.get("region_ids", [])
        for i, rid in enumerate(rids):
            name = river.get("name_fr", river["id"])
            bridges.append({
                "id": f"bridge_{river['id']}_{i+1}",
                "river": river["id"], "name_fr": f"Franchissement du {name} ({i+1})",
                "region": rid, "crossing_type": "bridge" if river.get("is_navigable") else "ford",
                "capacity": 60 if river.get("is_navigable") else 30,
                "status": "operational", "importance": "main" if river.get("is_navigable") else "secondary",
                "sources": river.get("source_refs", []),
                "status_precision": "ESTIMATION DE MODELE : presence d'un passage, pas un inventaire historique verifie",
            })
    doc = {
        "format": "gs1914.bridges", "format_version": 1,
        "reference_date": terrain["reference_date"],
        "generated_by": "tools/map/build_bridges.py",
        "disclaimer": "Les points de franchissement sont des estimations de modele derives des grands fleuves, pas des ponts historiques verifies.",
        "bridges": bridges,
        "totals": {"bridges": len(bridges), "rivers": len(terrain["major_rivers"])},
    }
    text = json.dumps(doc, ensure_ascii=False, indent=2) + "\n"
    if args.check:
        ok = OUT.read_text(encoding="utf-8") == text
        print("[PASS] ponts a jour" if ok else "[FAIL] ponts obsoletes")
        return 0 if ok else 1
    OUT.write_text(text, encoding="utf-8")
    print(f"[PASS] {len(bridges)} franchissements ecrits ({len(terrain['major_rivers'])} rivieres)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
