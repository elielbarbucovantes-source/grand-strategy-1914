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
  (Kuopio, Vyborg);
* ``REGIS_Yugoslavia.gpkg`` (REGIS Yugoslavia administrative boundaries) — only
  the 1920-1923 L1 shared boundary between ``Bregalnitsa`` (``640-1.290``) and
  ``Bitoly`` (``640-1.300``) is needed for MAJ-003 (Strumica 1913 salient),
  complemented by the 1913 Treaty of Bucharest watershed line across Mount
  Plavuš and the Kosturino pass to Peak 1494 on Belasica Planina.

This script reduces each original to the strict subset the pipeline reads and
writes small extracts under ``data/world/map/sources/derived/``. The extracts
keep the layer names and field names the pipeline expects, so
``build_geometry.py``, ``close_geometry_gaps.py`` and
``fix_strumica_salient.py`` run unchanged and produce the committed consolidated
geometry from versioned files alone.

Usage:
  python tools/map/build_source_extracts.py \
      --gb-tur   /path/to/gb_tur_adm2.geojson \
      --europe1914 /path/to/europe_1914.gpkg \
      --ristat  /path/to/ristat_1897_provinces.gpkg \
      --regis-yugoslavia /path/to/REGIS_Yugoslavia.gpkg \
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
from pyproj import Transformer
from shapely.ops import transform


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = ROOT / "data/world/map/sources/derived"

SARAY_SHAPE_ID = "54988432B91991689904144"
KAVANAGH_COUNTRIES = ("Austria-Hungary", "Romania", "Russia", "Norway")
RISTAT_PROVINCES = ("Kuopio governorate", "Vyborg governorate")
REGIS_YU_L1_LAYER = "REGIS_Yugoslavia_L1_1920-1923"
REGIS_YU_BREGALNITSA_ID = "640-1.290"
REGIS_YU_BITOLY_ID = "640-1.300"

# Treaty of Bucharest (10 August 1913, Art. III & V, Protocol No. 9) and
# Serbo-Greek Boundary Agreement of Belgrade (3/16 August 1913):
# Vardar-Struma watershed between the Konče-Valandovo-Strumica tripoint on
# Mount Plavuš (22.502811, 41.458667) and the 1913 Bulgaro-Greek-Serbian
# tripoint at Peak 1494 on Belasica Planina (22.811499, 41.328567), passing
# over the crest of Mount Plavuš (997 m), the Kosturino pass (457 m, between
# Bulgarian Kosturino and Serbian Rabrovo), and the ridge separating the
# Strumica/Trkajna basin (Memeshli, Ormanli, Dorlombos) from the Bojmija/Dojran
# basin (Čalaklija, Prsten, Bašibos, Bajrambos).
STRUMICA_COTE_1445 = (22.968377, 41.579668)
STRUMICA_PLAVUS_TRIPOINT = (22.502811, 41.458667)
STRUMICA_BELASICA_PEAK_1494 = (22.811499, 41.328567)
STRUMICA_SW_WATERSHED_INTERMEDIATE = (
    (22.525000, 41.425000),
    (22.550000, 41.385000),
    (22.562000, 41.345000),
    (22.595000, 41.335000),
    (22.640000, 41.328000),
    (22.675000, 41.331000),
    (22.740000, 41.329000),
)


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


def extract_strumica(regis_yu: Path, output_dir: Path) -> dict:
    meta, _fids, geometries, fields = pyogrio.raw.read(
        regis_yu,
        layer=REGIS_YU_L1_LAYER,
        columns=["id", "name"],
        read_geometry=True,
    )
    field_map = dict(zip(meta["fields"], fields))
    to_4326 = Transformer.from_crs("EPSG:3035", "EPSG:4326", always_xy=True).transform
    by_id = {}
    for uid, uname, wkb in zip(field_map["id"], field_map["name"], geometries):
        sid = str(uid)
        if sid in (REGIS_YU_BREGALNITSA_ID, REGIS_YU_BITOLY_ID):
            by_id[sid] = (str(uname), transform(to_4326, shapely.from_wkb(wkb)))
    for req_id in (REGIS_YU_BREGALNITSA_ID, REGIS_YU_BITOLY_ID):
        if req_id not in by_id:
            raise ValueError(f"Unité {req_id} absente de {REGIS_YU_L1_LAYER}")

    breg_geom = by_id[REGIS_YU_BREGALNITSA_ID][1]
    bit_geom = by_id[REGIS_YU_BITOLY_ID][1]
    breg_poly = breg_geom.geoms[0] if breg_geom.geom_type == "MultiPolygon" else breg_geom
    bit_poly = bit_geom.geoms[0] if bit_geom.geom_type == "MultiPolygon" else bit_geom

    breg_ring = [(round(x, 6), round(y, 6)) for x, y in list(breg_poly.exterior.coords)[:-1]]
    bit_set = {(round(x, 6), round(y, 6)) for x, y in list(bit_poly.exterior.coords)[:-1]}

    if STRUMICA_COTE_1445 not in breg_ring:
        raise ValueError(f"Cote 1445 {STRUMICA_COTE_1445} introuvable dans Bregalnitsa")
    if STRUMICA_PLAVUS_TRIPOINT not in breg_ring:
        raise ValueError(f"Tripoint Plavuš {STRUMICA_PLAVUS_TRIPOINT} introuvable dans Bregalnitsa")

    idx_start = breg_ring.index(STRUMICA_COTE_1445)
    idx_end = breg_ring.index(STRUMICA_PLAVUS_TRIPOINT)
    if idx_start <= idx_end:
        regis_arc_n_to_w = breg_ring[idx_start:idx_end + 1]
    else:
        regis_arc_n_to_w = breg_ring[idx_start:] + breg_ring[:idx_end + 1]

    if len(regis_arc_n_to_w) != 32 or not all(pt in bit_set for pt in regis_arc_n_to_w):
        raise ValueError(
            f"Arc partagé Bregalnitsa/Bitoly inattendu: {len(regis_arc_n_to_w)} sommets"
        )

    sw_watershed_w_to_s = [
        STRUMICA_PLAVUS_TRIPOINT,
        *STRUMICA_SW_WATERSHED_INTERMEDIATE,
        STRUMICA_BELASICA_PEAK_1494,
    ]
    full_frontier_s_to_n = list(reversed(sw_watershed_w_to_s[1:])) + list(reversed(regis_arc_n_to_w))

    features = [
        {
            "type": "Feature",
            "properties": {
                "id": "strumica_1913_regis_n_nw_arc",
                "role": "regis_yugoslavia_l1_boundary_1920_1923",
                "source_layer": f"REGIS_Yugoslavia.gpkg:{REGIS_YU_L1_LAYER}",
                "units": [REGIS_YU_BREGALNITSA_ID, REGIS_YU_BITOLY_ID],
                "vertex_count": len(regis_arc_n_to_w),
                "description": (
                    "Limite nord et nord-ouest du saillant de Stroumitsa (1913-1919) "
                    "entre la Cote 1445 (Maleš/Ograzhden, au sud-ouest de Dobrilaka) "
                    "et le tripoint du mont Plavuš, préservée dans REGIS_Yugoslavia_L1_1920-1923 "
                    "comme limite entre Bregalnitsa (640-1.290) et Bitoly (640-1.300)."
                ),
            },
            "geometry": {
                "type": "LineString",
                "coordinates": [[x, y] for x, y in regis_arc_n_to_w],
            },
        },
        {
            "type": "Feature",
            "properties": {
                "id": "strumica_1913_sw_watershed_arc",
                "role": "bucharest_1913_plavus_kosturino_belasica_watershed",
                "source_layer": (
                    "Traité de Bucarest (10 août 1913, art. III & V, protocole n° 9) + "
                    "Accord gréco-serbe de Belgrade (3/16 août 1913) + "
                    "Generalkarte von Mitteleuropa 1:200 000 (40°41° Vodena)"
                ),
                "vertex_count": len(sw_watershed_w_to_s),
                "description": (
                    "Ligne de partage des eaux Vardar-Strouma du tripoint du mont Plavuš "
                    "(22.502811, 41.458667) au tripoint bulgaro-gréco-serbe de 1913 à la "
                    "Cote 1494 sur la crête de la Belasica (22.811499, 41.328567), par la "
                    "crête du Plavuš (997 m) et le col de Kosturino (457 m)."
                ),
            },
            "geometry": {
                "type": "LineString",
                "coordinates": [[x, y] for x, y in sw_watershed_w_to_s],
            },
        },
        {
            "type": "Feature",
            "properties": {
                "id": "strumica_1913_full_frontier_s_to_n",
                "role": "bucharest_1913_full_strumica_frontier",
                "vertex_count": len(full_frontier_s_to_n),
                "start_point": list(STRUMICA_BELASICA_PEAK_1494),
                "end_point": list(STRUMICA_COTE_1445),
                "description": (
                    "Frontière bulgaro-serbe complète du saillant de Stroumitsa au 1er janvier 1914 "
                    "(orientée du sud au nord, de la Cote 1494 sur la Belasica à la Cote 1445 sur "
                    "Maleš/Ograzhden)."
                ),
            },
            "geometry": {
                "type": "LineString",
                "coordinates": [[x, y] for x, y in full_frontier_s_to_n],
            },
        },
    ]
    out = output_dir / "gs1914_strumica_1913_salient.geojson"
    write_geojson_feature_collection(out, features)
    return {
        "file": out.name,
        "layer": REGIS_YU_L1_LAYER,
        "features": len(features),
        "units": [REGIS_YU_BREGALNITSA_ID, REGIS_YU_BITOLY_ID],
        "regis_vertices": len(regis_arc_n_to_w),
        "watershed_vertices": len(sw_watershed_w_to_s),
        "full_frontier_vertices": len(full_frontier_s_to_n),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--gb-tur", type=Path, required=True, help="gb_tur_adm2.geojson (geoBoundaries TUR ADM2)")
    parser.add_argument("--europe1914", type=Path, required=True, help="1914 national polygon layer (Kavanagh europe_1914)")
    parser.add_argument("--ristat", type=Path, required=True, help="ristat_1897_provinces.gpkg (RISTAT 1897)")
    parser.add_argument("--regis-yugoslavia", type=Path, required=True, help="REGIS_Yugoslavia.gpkg (REGIS Yugoslavia)")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    for path in (args.gb_tur, args.europe1914, args.ristat, args.regis_yugoslavia):
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
            "strumica": extract_strumica(args.regis_yugoslavia, output_dir),
            "sources": {
                "gb_tur": {"path": str(args.gb_tur), "sha256": sha256(args.gb_tur)},
                "europe1914": {"path": str(args.europe1914), "sha256": sha256(args.europe1914)},
                "ristat": {"path": str(args.ristat), "sha256": sha256(args.ristat)},
                "regis_yugoslavia": {"path": str(args.regis_yugoslavia), "sha256": sha256(args.regis_yugoslavia)},
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
