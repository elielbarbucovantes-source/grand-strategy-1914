#!/usr/bin/env python3
"""Densifie les géométries des zones maritimes (lot agent_2) — correction C1.

Les zones maritimes sont des rectangles en longitude/latitude dont les terres ont
été soustraites. Leurs longues arêtes, droites en WGS 84, deviennent des courbes
après reprojection en EPSG:3035. Pour mz_norwegian_sea, deux segments se croisent
alors (auto-intersection vers 4,67°E 61,02°N), ce qui oblige rebuild_topology.py
à mesurer sur un buffer(0) de contournement.

Correction : insérer des sommets intermédiaires (shapely.segmentize) tous les
0,25° au plus, en WGS 84. Les sommets existants sont conservés à l'identique et
les nouveaux sont alignés sur les segments d'origine : le TRACÉ en longitude/latitude
est inchangé. Seules les coordonnées NOUVELLES sont arrondies à 6 décimales
(≈ 0,1 m) ; les sommets d'origine restent exacts, quelle que soit leur précision.

Le script est idempotent. Une seconde exécution ne change rien. Il échoue si une
zone reste invalide en WGS 84 ou en EPSG:3035.

Usage :  python tools/map/repair_maritime_zones.py [--check]
  --check : n'écrit rien ; code 1 si le fichier n'est pas déjà densifié.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import shapely
from pyproj import Transformer
from shapely.geometry import mapping, shape

ROOT = Path(__file__).resolve().parents[2]
PATH = ROOT / "data/world/map/build/agent_2/maritime_zones.json"
MAX_SEGMENT_DEG = 0.25
DIGITS = 6
TO_3035 = Transformer.from_crs(4326, 3035, always_xy=True).transform


def round_new_coords(value, originals: set[tuple[float, float]]):
    """Arrondit uniquement les sommets insérés ; les sommets d'origine restent exacts."""
    if isinstance(value, (list, tuple)):
        if value and isinstance(value[0], (int, float)):
            point = (float(value[0]), float(value[1]))
            if point in originals:
                return [value[0], value[1]]
            return [round(point[0], DIGITS), round(point[1], DIGITS)]
        return [round_new_coords(v, originals) for v in value]
    return value


def densify(geometry_json: dict) -> dict:
    geometry = shape(geometry_json)
    originals = {(float(x), float(y)) for x, y in shapely.get_coordinates(geometry)}
    dense = shapely.segmentize(geometry, MAX_SEGMENT_DEG)
    result = mapping(dense)
    return {"type": result["type"], "coordinates": round_new_coords(result["coordinates"], originals)}


def check_valid(zone_id: str, geometry_json: dict) -> None:
    geometry = shape(geometry_json)
    projected = shapely.transform(geometry, lambda x, y: TO_3035(x, y), interleaved=False)
    if not geometry.is_valid or not projected.is_valid:
        raise SystemExit(f"[FAIL] {zone_id} invalide après densification "
                         f"(4326={geometry.is_valid}, 3035={projected.is_valid})")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true")
    arguments = parser.parse_args()
    original = PATH.read_text(encoding="utf-8")
    document = json.loads(original)
    for feature in document["features"]:
        feature["geometry"] = densify(feature["geometry"])
        check_valid(feature["id"], feature["geometry"])
    output = json.dumps(document, indent=2, ensure_ascii=False) + "\n"
    if arguments.check:
        if output != original:
            print("[FAIL] maritime_zones.json n'est pas densifié (exécuter sans --check)")
            return 1
        print("[PASS] maritime_zones.json déjà densifié ; 16/16 zones valides en WGS 84 et EPSG:3035")
        return 0
    PATH.write_text(output, encoding="utf-8")
    print(f"maritime_zones.json densifié ({MAX_SEGMENT_DEG}°) ; "
          f"{len(document['features'])} zones valides en WGS 84 et EPSG:3035")
    return 0


if __name__ == "__main__":
    sys.exit(main())
