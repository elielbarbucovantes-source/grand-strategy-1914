#!/usr/bin/env python3
"""Build the minimal, versionable source extracts used by the geometry pipeline.

The atlas pipeline depends on three external datasets that are too large or too
loosely licensed to commit in full:

* ``gb_tur_adm2.geojson`` (geoBoundaries TUR ADM2, ~3.9 MB) — only the Thrace
  district of Saray (``shapeID 54988432B91991689904144``) is needed for BLK-001;
* a 1914 national polygon layer (Kavanagh ``europe_1914``) — only the four
  countries that arbitrate the MAJ-004 tripoint and Pasvik gaps are needed
  (Austria-Hungary, Romania, Russia, Norway);
* ``ristat_1897_provinces.gpkg`` (RISTAT 1897 Russian provinces, ~1.3 MB) — only
  the two Finnish governorates that arbitrate the MAJ-004 Finland gap are needed
  (Kuopio, Vyborg).

This script reduces each original to the strict subset the pipeline reads and
writes small extracts under ``data/world/map/sources/derived/``. The extracts
keep the layer names and field names the pipeline expects, so
``build_geometry.py`` and ``close_geometry_gaps.py`` run unchanged and produce
the committed consolidated geometry from versioned files alone.

Usage:
  python tools/map/build_source_extracts.py \
      --gb-tur   /path/to/gb_tur_adm2.geojson \
      --europe1914 /path/to/europe_1914.gpkg \
      --ristat  /path/to/ristat_1897_provinces.gpkg \
      --output-dir data/world/map/sources/derived

The output directory must be inside the repository (never a temporary copy).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

import numpy as np
import pyogrio
import shapely


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = ROOT / "data/world/map/sources/derived"

SARAY_SHAPE_ID = "54988432B91991689904144"
KAVANAGH_COUNTRIES = ("Austria-Hungary", "Romania", "Russia", "Norway")
RISTAT_PROVINCES = ("Kuopio governorate", "Vyborg governorate")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_geojson_feature_collection(path: Path, features: list[dict]) -> None:
    collection = {
        "type": "FeatureCollection",
        "name": path.stem,
        "crs": {"type": "name", "properties": {"name": "EPSG:4326"}},
        "features": features,
    }
    path.write_text(json.dumps(collection, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def extract_saray(gb_tur: Path, output_dir: Path) -> dict:
    source = json.loads(gb_tur.read_text(encoding="utf-8"))
    matches = [
        feature
        for feature in source.get("features", [])
        if (feature.get("properties") or {}).get("shapeID") == SARAY_SHAPE_ID
    ]
    if len(matches) != 1:
        raise ValueError(f"Attendu exactement 1 shapeID {SARAY_SHAPE_ID}, trouvé {len(matches)}")
    out = output_dir / "gs1914_saray_tekirdag.geojson"
    write_geojson_feature_collection(out, matches)
    return {"file": out.name, "features": 1, "shapeID": SARAY_SHAPE_ID}


def extract_kavanagh(europe1914: Path, output_dir: Path) -> dict:
    # The original is a GeoPackage with layer ``europe_1914``; the low-resolution
    # GeoJSON substitute has no layer name, so fall back to layer=None.
    layer = None
    try:
        pyogrio.read_info(europe1914, layer="europe_1914")
        layer = "europe_1914"
    except Exception:
        layer = None
    meta, _fids, geometries, fields = pyogrio.raw.read(
        europe1914, layer=layer, columns=["name"], read_geometry=True
    )
    names = [str(name) for name in fields[0]]
    by_name = {name: shapely.from_wkb(wkb) for name, wkb in zip(names, geometries)}
    missing = [country for country in KAVANAGH_COUNTRIES if country not in by_name]
    if missing:
        raise ValueError(f"Pays absents de la source 1914: {missing}")
    selected = [(country, by_name[country]) for country in KAVANAGH_COUNTRIES]
    out = output_dir / "gs1914_kavanagh_1914_countries.gpkg"
    if out.exists():
        out.unlink()
    pyogrio.raw.write(
        out,
        np.array([shapely.to_wkb(geom) for _, geom in selected], dtype=object),
        [np.array([country for country, _ in selected], dtype=object)],
        ["name"],
        layer="europe_1914",
        driver="GPKG",
        geometry_type="MultiPolygon",
        crs="EPSG:4326",
    )
    return {"file": out.name, "layer": "europe_1914", "features": len(selected),
            "names": [country for country, _ in selected]}


def extract_ristat(ristat: Path, output_dir: Path) -> dict:
    meta, _fids, geometries, fields = pyogrio.raw.read(
        ristat, layer="provinces_1897", columns=["prov_ENG"], read_geometry=True
    )
    names = [str(name) for name in fields[0]]
    by_name = {name: shapely.from_wkb(wkb) for name, wkb in zip(names, geometries)}
    missing = [name for name in RISTAT_PROVINCES if name not in by_name]
    if missing:
        raise ValueError(f"Gouvernements absents de RISTAT: {missing}")
    selected = [(name, by_name[name]) for name in RISTAT_PROVINCES]
    out = output_dir / "gs1914_ristat_1897_finland_provinces.gpkg"
    if out.exists():
        out.unlink()
    pyogrio.raw.write(
        out,
        np.array([shapely.to_wkb(geom) for _, geom in selected], dtype=object),
        [np.array([name for name, _ in selected], dtype=object)],
        ["prov_ENG"],
        layer="provinces_1897",
        driver="GPKG",
        geometry_type="MultiPolygon",
        crs="EPSG:4326",
    )
    return {"file": out.name, "layer": "provinces_1897", "features": len(selected),
            "names": [name for name, _ in selected]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--gb-tur", type=Path, required=True, help="gb_tur_adm2.geojson (geoBoundaries TUR ADM2)")
    parser.add_argument("--europe1914", type=Path, required=True, help="1914 national polygon layer (Kavanagh europe_1914)")
    parser.add_argument("--ristat", type=Path, required=True, help="ristat_1897_provinces.gpkg (RISTAT 1897)")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    for path in (args.gb_tur, args.europe1914, args.ristat):
        if not path.exists():
            print(f"ERREUR: source introuvable: {path}", file=sys.stderr)
            return 1

    output_dir = args.output_dir.resolve()
    try:
        output_dir.relative_to(ROOT.resolve())
    except ValueError:
        print(f"ERREUR: le répertoire de sortie doit être dans le dépôt: {output_dir}", file=sys.stderr)
        return 1
    output_dir.mkdir(parents=True, exist_ok=True)

    try:
        report = {
            "saray": extract_saray(args.gb_tur, output_dir),
            "kavanagh": extract_kavanagh(args.europe1914, output_dir),
            "ristat": extract_ristat(args.ristat, output_dir),
            "sources": {
                "gb_tur": {"path": str(args.gb_tur), "sha256": sha256(args.gb_tur)},
                "europe1914": {"path": str(args.europe1914), "sha256": sha256(args.europe1914)},
                "ristat": {"path": str(args.ristat), "sha256": sha256(args.ristat)},
            },
        }
    except Exception as error:
        print(f"ERREUR: {error}", file=sys.stderr)
        return 1

    manifest = output_dir / "SOURCE_EXTRACTS.json"
    manifest.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(f"Écrit: {manifest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
