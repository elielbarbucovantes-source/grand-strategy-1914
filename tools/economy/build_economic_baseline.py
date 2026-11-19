#!/usr/bin/env python3
"""Genere data/game/economic_baseline.json a partir des sources historiques versionnees.

La repartition regionale est une ESTIMATION DE MODELE : proportionnelle a la surface,
au nombre de villes et aux axes ferroviaires, avec bonus pour les gisements identifies.
Aucune valeur n'est presentee comme un recensement regional verifie.

Usage : python3 tools/economy/build_economic_baseline.py [--check]
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "data/game/economic_baseline_sources.json"
REGIONS = ROOT / "data/world/map/regions.json"
CITIES = ROOT / "data/world/map/cities.json"
INFRA = ROOT / "data/world/map/infrastructure.json"
NETWORK = ROOT / "data/game/transport_network.json"
OUT = ROOT / "data/game/economic_baseline.json"
SECTORS = {"agriculture": 0.45, "industry": 0.22, "mines": 0.06,
           "transport": 0.07, "services": 0.15, "administration": 0.05}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    src = json.loads(SRC.read_text(encoding="utf-8"))
    region_data = json.loads(REGIONS.read_text(encoding="utf-8"))["regions"]
    cities = json.loads(CITIES.read_text(encoding="utf-8"))["cities"]
    infra = json.loads(INFRA.read_text(encoding="utf-8"))
    net = json.loads(NETWORK.read_text(encoding="utf-8"))

    by_nation: dict[str, list[dict]] = {}
    for r in region_data:
        by_nation.setdefault(r["initial_sovereign_id"], []).append(r)
    cities_per_region: dict[str, int] = {}
    for c in cities:
        cities_per_region[c["region_id"]] = cities_per_region.get(c["region_id"], 0) + 1
    rail_per_region: dict[str, int] = {}
    for f in infra["railways"]["features"]:
        rid = f["properties"].get("from_region_id", "")
        rail_per_region[rid] = rail_per_region.get(rid, 0) + 1

    deposit_boost: dict[str, dict[str, float]] = {}
    for d in src["key_deposits"]:
        for rid in d["regions"]:
            deposit_boost.setdefault(rid, {})[d["resource"]] = 2.0

    baseline: dict[str, dict] = {}
    for nid, n in src["nations"].items():
        regions = by_nation.get(nid, [])
        if not regions:
            continue
        weights = {}
        for r in regions:
            rid = r["id"]
            area = float(r.get("area_km2", 1000) or 1000)
            urban = 1.0 + 0.4 * cities_per_region.get(rid, 0) + 0.3 * rail_per_region.get(rid, 0)
            relief = r.get("relief_categories", [])
            if "mountains" in relief:
                urban *= 0.7
            weights[rid] = area * urban
        total_w = sum(weights.values()) or 1.0
        for r in regions:
            rid = r["id"]
            share = weights[rid] / total_w
            pop = int(n["population"] * share)
            deposits = {}
            for res, amount in n["resources"].items():
                boost = deposit_boost.get(rid, {}).get(res, 1.0)
                deposits[res] = round(float(amount) * share * boost, 3)
            industry = round(float(n["industry"]) * share * (1.0 + 0.2 * rail_per_region.get(rid, 0)), 4)
            baseline[rid] = {
                "region_id": rid, "nation": nid,
                "population": pop,
                "urban_share": round(float(n["urban_share"]), 3),
                "workforce": int(pop * 0.52),
                "sectors": {s: int(pop * 0.52 * p) for s, p in SECTORS.items()},
                "deposits": deposits,
                "exploitation": {res: 0.0 for res in deposits},
                "industry_capacity": industry,
                "stocks": {res: 0.0 for res in deposits},
                "levels": {
                    "population": n["population_level"],
                    "resources": n["resource_level"],
                    "regional_distribution": "C",
                },
                "sources": ["CENSUS" if n["population_level"] in ("A", "B") else "SYB", "EB1911", "MODEL"],
                "note": "Repartition regionale ESTIMEE ; population nationale au niveau %s." % n["population_level"],
            }

    doc = {
        "format": "gs1914.economic_baseline", "format_version": 1,
        "reference_date": src["reference_date"],
        "generated_by": "tools/economy/build_economic_baseline.py",
        "sources": src["sources"],
        "key_deposits": src["key_deposits"],
        "capacity_disclaimer": "Les capacites et la repartition regionale sont des estimations de modele, pas des faits historiques verifies.",
        "regions": baseline,
        "totals": {"regions": len(baseline), "nations": len(src["nations"]),
                   "population": sum(v["population"] for v in baseline.values())},
    }
    text = json.dumps(doc, ensure_ascii=False, indent=2) + "\n"
    if args.check:
        ok = OUT.read_text(encoding="utf-8") == text
        print("[PASS] baseline economique a jour" if ok else "[FAIL] baseline economique obsolete")
        return 0 if ok else 1
    OUT.write_text(text, encoding="utf-8")
    print("[PASS] baseline ecrite : %d regions, %d nations, population %d" % (
        len(baseline), len(src["nations"]), doc["totals"]["population"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
