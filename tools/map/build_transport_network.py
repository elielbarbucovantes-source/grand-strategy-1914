#!/usr/bin/env python3
"""Construit data/game/transport_network.json a partir des donnees cartographiques versionnees.

Aucune ligne n'est inventee : les axes ferroviaires, les aretes terrestres, les detroits,
les fleuves, les ports et le relief proviennent des fichiers suivis de data/world/map/.
Seules les CAPACITES sont des estimations de modele, explicitement marquees comme telles.

Usage : python3 tools/map/build_transport_network.py [--check]
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MAP = ROOT / "data/world/map"
OUT = ROOT / "data/game/transport_network.json"

CAP = {
    "rail_main": 120, "rail_secondary": 60,
    "road_plains": 40, "road_hills": 25, "road_mountains": 12,
    "river_navigable": 50, "river_crossing": 20,
    "strait": 80,
    "port_capital": 120, "port_major": 80,
}


def haversine(a, b) -> float:
    lon1, lat1 = math.radians(a[0]), math.radians(a[1])
    lon2, lat2 = math.radians(b[0]), math.radians(b[1])
    dlon, dlat = lon2 - lon1, lat2 - lat1
    h = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    return round(6371.0088 * 2 * math.asin(math.sqrt(h)), 1)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    infra = json.loads((MAP / "infrastructure.json").read_text(encoding="utf-8"))
    adj = json.loads((MAP / "adjacency.json").read_text(encoding="utf-8"))
    terrain = json.loads((MAP / "terrain.json").read_text(encoding="utf-8"))
    cities = json.loads((MAP / "cities.json").read_text(encoding="utf-8"))["cities"]

    relief = {r["region_id"]: r for r in terrain["regions_terrain"].values()}
    sovereign = {r["id"]: r["sovereign_1914"]
                 for r in json.loads((MAP / "regions.json").read_text(encoding="utf-8"))["regions"]}
    links: list[dict] = []
    seen: set[str] = set()

    # 1. Axes ferroviaires (GeoJSON FeatureCollection).
    rail_internal: dict[str, int] = {}
    for f in infra["railways"]["features"]:
        p = f["properties"]
        a, b = p.get("from_region_id"), p.get("to_region_id")
        cls = p.get("network_class", "secondary")
        cap = CAP["rail_main"] if cls == "main" else CAP["rail_secondary"]
        coords = f["geometry"]["coordinates"]
        dist = haversine(coords[0], coords[1]) if len(coords) >= 2 else 0.0
        if a == b:
            rail_internal[a] = rail_internal.get(a, 0) + cap
            continue
        key = f"rail|{a}|{b}"
        if key in seen:
            continue
        seen.add(key)
        links.append({
            "id": f["id"], "a": a, "b": b, "mode": "rail",
            "distance_km": dist, "capacity": cap, "condition": "operational",
            "owner": sovereign.get(a, "") if sovereign.get(a) == sovereign.get(b) else "shared",
            "vulnerability": 0.25 if any("mountains" in relief.get(r, {}).get("relief_categories", []) for r in (a, b)) else 0.1,
            "name_fr": p.get("name_fr", ""), "sources": p.get("source_refs", []),
            "capacity_status": "ESTIMATION DE MODELE (non un fait historique)",
        })

    # 2. Routes terrestres : une liaison par arete de l'atlas, qualite issue du relief.
    for e in adj["edges"]:
        a, b = e["region_a_id"], e["region_b_id"]
        ra = relief.get(a, {}).get("dominant_relief", "plains")
        rb = relief.get(b, {}).get("dominant_relief", "plains")
        if "mountains" in (ra, rb) or "mountains" in relief.get(a, {}).get("relief_categories", []) \
            or "mountains" in relief.get(b, {}).get("relief_categories", []):
            quality, cap, difficulty = "difficult", CAP["road_mountains"], 1.6
        elif "hills" in (ra, rb):
            quality, cap, difficulty = "secondary", CAP["road_hills"], 1.2
        else:
            quality, cap, difficulty = "main", CAP["road_plains"], 1.0
        links.append({
            "id": f"road|{a}|{b}", "a": a, "b": b, "mode": "road",
            "distance_km": round(float(e.get("shared_border_km", 0)), 1),
            "capacity": cap, "condition": "operational", "quality": quality,
            "difficulty": difficulty, "owner": "shared", "vulnerability": 0.15,
            "sources": ["atlas_adjacency_v5"],
            "capacity_status": "ESTIMATION DE MODELE (qualite derivee du relief)",
        })

    # 3. Detroits : liaisons maritimes courtes entre regions.
    for s in adj["strait_crossings"]:
        a = s.get("region_a_id") or s.get("region_a")
        b = s.get("region_b_id") or s.get("region_b")
        if not a or not b:
            continue
        links.append({
            "id": f"strait|{a}|{b}", "a": a, "b": b, "mode": "maritime",
            "distance_km": round(float(s.get("distance_km", 0)), 1),
            "capacity": CAP["strait"], "condition": "operational", "owner": "shared",
            "vulnerability": 0.3, "sources": ["atlas_adjacency_v5"],
            "capacity_status": "ESTIMATION DE MODELE",
        })

    # 4. Fleuves navigables : voie de circulation entre regions riveraines.
    for river in terrain["major_rivers"]:
        rids = river.get("region_ids", [])
        if not river.get("is_navigable"):
            continue
        for a, b in zip(rids, rids[1:]):
            if a == b:
                continue
            links.append({
                "id": f"river|{river['id']}|{a}|{b}", "a": a, "b": b, "mode": "river",
                "distance_km": 0.0, "capacity": CAP["river_navigable"], "condition": "operational",
                "owner": "shared", "vulnerability": 0.2, "name_fr": river.get("name_fr", ""),
                "sources": river.get("source_refs", []),
                "capacity_status": "ESTIMATION DE MODELE (navigation signalée, volume non source)",
            })

    # 5. Ports : villes au role major_port, avec capacite estimee.
    ports = []
    for c in cities:
        if "major_port" not in c.get("strategic_roles", []):
            continue
        capital = bool(c.get("is_capital"))
        ports.append({
            "id": c["id"], "region_id": c["region_id"], "name_fr": c["name_fr"],
            "capacity": CAP["port_capital"] if capital else CAP["port_major"],
            "infrastructure": "capital_port" if capital else "major_port",
            "status": "operational", "controller": c.get("sovereign_1914", ""),
            "sources": c.get("source_refs", []),
            "capacity_status": "ESTIMATION DE MODELE (non un fait historique)",
        })

    # 6. Passage des massifs : points de franchissement documentes dans terrain.json.
    passes = []
    for m in terrain["mountain_chains"]:
        for name in m.get("strategic_passes", []):
            passes.append({"mountain": m["id"], "name": name,
                           "regions": m.get("region_ids", []), "sources": m.get("source_refs", [])})

    doc = {
        "format": "gs1914.transport_network", "format_version": 1,
        "reference_date": infra["reference_date"],
        "generated_by": "tools/map/build_transport_network.py",
        "sources": {
            "railways": "data/world/map/infrastructure.json (129 axes)",
            "roads": "data/world/map/adjacency.json (184 aretes terrestres)",
            "straits": "data/world/map/adjacency.json (10 + 3 detroits)",
            "rivers": "data/world/map/terrain.json (59 rivieres)",
            "ports": "data/world/map/cities.json (roles major_port)",
            "passes": "data/world/map/terrain.json (strategic_passes)",
        },
        "capacity_disclaimer": "Toutes les capacites sont des estimations de modele, pas des donnees historiques sourcees.",
        "links": links,
        "rail_internal_capacity": {k: v for k, v in sorted(rail_internal.items())},
        "relief": relief,
        "ports": ports,
        "passes": passes,
        "totals": {"links": len(links), "ports": len(ports), "passes": len(passes)},
    }
    text = json.dumps(doc, ensure_ascii=False, indent=2) + "\n"
    if args.check:
        ok = OUT.read_text(encoding="utf-8") == text
        print("[PASS] reseau de transport a jour" if ok else "[FAIL] reseau de transport obsolete")
        return 0 if ok else 1
    OUT.write_text(text, encoding="utf-8")
    print(f"[PASS] reseau ecrit : {len(links)} liaisons, {len(ports)} ports, {len(passes)} cols")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
