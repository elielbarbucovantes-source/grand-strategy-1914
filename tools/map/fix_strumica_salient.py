#!/usr/bin/env python3
"""Restore the 1 January 1914 Bulgaro-Serbian frontier in the Strumica salient (MAJ-003).

Historical background:
  Under Article III and Protocol No. 9 of the Treaty of Bucharest (28 July /
  10 August 1913), the Serbo-Bulgarian boundary south of Patarica followed the
  former Turco-Bulgarian frontier and the Vardar-Struma watershed, "with the
  exception of the upper valley of the Strumica [the Radoviš basin / Stara Reka]
  which shall remain in Serbian territory", down to Mount Belasica, where it met
  the Greco-Bulgarian frontier defined by Article V and the Serbo-Greek
  Boundary Agreement of Belgrade (3/16 August 1913) at Peak 1494 on the crest
  of Belasica Planina (northeast of Lake Dojran, 11.59 km west of Mount Tumba).

  Consequently, on 1 January 1914, the town of Strumica (Stroumitsa) and its
  caza/okolija (75 localities: 1 town and 74 villages, forming the Strumica
  okolija of the Bulgarian Strumica okrug plus the western border villages of
  the Petrich okolija on Ograzhden) belonged to the Kingdom of Bulgaria
  (region_072, Bulgarie occidentale).  The salient was ceded to the Kingdom of
  Serbs, Croats and Slovenes only six years later under Article 27, § 1 of the
  Treaty of Neuilly-sur-Seine (27 November 1919), which detached the salient
  along a new line from Cote 1445 on Maleš/Ograzhden (southwest of Dobrilaka)
  to Mount Tumba (Cote 1253) on Belasica.

Root cause of the atlas anomaly:
  In the initial lot construction, region_072 was assembled from
  REGIS_Bulgaria_L2_1923-1925 (post-Neuilly) + REGIS_Bulgaria_L0_1886-1912
  (pre-Balkan Wars), while region_074 was assembled from
  REGIS_Yugoslavia_L2_1948-1954.  Because the Strumica salient belonged to
  Bulgaria only between 1913 and 1919, it was absent from both the 1886-1912
  and 1923-1925 Bulgarian layers and remained embedded in region_074 along the
  1919 Neuilly border.  However, in REGIS_Yugoslavia_L1_1920-1923, the newly
  annexed Strumica district (Strumički srez) was attached to Bitoly (640-1.300)
  while neighboring Bregalnitsa (640-1.290: Berovo/Maleš, Radoviš, Konče) kept
  its pre-1919 border, thereby preserving the exact 32-vertex 1913 northern and
  northwestern frontier of the Strumica salient from Cote 1445 (22.968377,
  41.579668) to the Mount Plavuš tripoint (22.502811, 41.458667).

Usage:
  python tools/map/fix_strumica_salient.py \
      --input-dir data/world/map \
      --strumica-extract data/world/map/sources/derived/gs1914_strumica_1913_salient.geojson \
      --output-dir .consolidation-stage
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import shapely
from pyproj import Transformer
from shapely.geometry import Point, Polygon, mapping, shape


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_INPUT_DIR = ROOT / "data/world/map"
DEFAULT_EXTRACT = ROOT / "data/world/map/sources/derived/gs1914_strumica_1913_salient.geojson"

TO_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True).transform
STRICT_OVERLAP_EPSILON = 1e-10

COTE_1445 = (22.968377, 41.579668)
MOUNT_TUMBA = (22.950025, 41.333460)
BELASICA_PEAK_1494 = (22.811499, 41.328567)
PLAVUS_TRIPOINT = (22.502811, 41.458667)
STRUMICA_POINT = (22.6427, 41.4378)

# Historical localities inside the 1913-1919 Bulgarian Strumica salient
BULGARIAN_SALIENT_LOCALITIES = {
    "Strumica (chef-lieu)": (22.6427, 41.4378),
    "Novo Selo": (22.8811, 41.4139),
    "Bosilovo": (22.7278, 41.4406),
    "Vasilevo": (22.6419, 41.4756),
    "Kosturino": (22.5714, 41.3572),
    "Kuklish": (22.6653, 41.4053),
    "Veljusa": (22.5675, 41.4761),
    "Bansko": (22.7436, 41.3833),
    "Koleshino": (22.8058, 41.3822),
    "Mokrino": (22.8422, 41.3806),
    "Gabrovo": (22.7897, 41.3811),
    "Dabilje": (22.6858, 41.4461),
    "Murtino": (22.7753, 41.4153),
    "Monospitovo": (22.7556, 41.4178),
    "Popchevo": (22.5889, 41.4194),
    "Raborci": (22.5964, 41.3917),
    "Badolen": (22.9100, 41.5200),
}

# Historical localities remaining in the Kingdom of Serbia in 1913-1914
SERBIAN_BORDER_LOCALITIES = {
    "Radoviš (haute vallée / Stara Reka)": (22.4647, 41.6381),
    "Konče (bassin de la Kriva Lakavica)": (22.3836, 41.4956),
    "Berovo (Maleš / haute Bregalnica)": (22.8578, 41.7031),
    "Valandovo (Bojmija / Anska Reka)": (22.5606, 41.3174),
    "Rabrovo": (22.5597, 41.3292),
    "Čalaklija": (22.6078, 41.3075),
    "Prsten": (22.6258, 41.3025),
    "Bašibos": (22.6908, 41.3056),
    "Bajrambos": (22.7153, 41.3125),
    "Kurtamzali": (22.6606, 41.2889),
    "Dojran (Stari Dojran)": (22.7206, 41.1864),
}


def projected_area_km2(geometry) -> float:
    return shapely.transform(geometry, TO_3035, interleaved=False).area / 1_000_000


def load_frontier_extract(path: Path) -> dict:
    collection = json.loads(path.read_text(encoding="utf-8"))
    by_role = {
        feature["properties"]["role"]: feature
        for feature in collection.get("features", [])
    }
    required_roles = (
        "regis_yugoslavia_l1_boundary_1920_1923",
        "bucharest_1913_plavus_kosturino_belasica_watershed",
        "bucharest_1913_full_strumica_frontier",
    )
    for role in required_roles:
        if role not in by_role:
            raise ValueError(f"Rôle {role!r} absent de {path}")
    return by_role


def update_region_metrics(feature: dict, geometry) -> None:
    if not geometry.is_valid or geometry.is_empty:
        raise ValueError(
            f"Géométrie invalide: {feature['properties']['id']} "
            f"({shapely.is_valid_reason(geometry)})"
        )
    props = feature["properties"]
    projected = shapely.transform(geometry, TO_3035, interleaved=False)
    centroid = geometry.centroid
    representative = geometry.representative_point()
    props["area_km2"] = round(projected.area / 1_000_000, 2)
    props["centroid_lon_lat"] = [round(centroid.x, 6), round(centroid.y, 6)]
    props["representative_point_lon_lat"] = [round(representative.x, 6), round(representative.y, 6)]
    props["bbox"] = [round(value, 6) for value in geometry.bounds]
    props["polygon_parts_count"] = len(geometry.geoms) if geometry.geom_type == "MultiPolygon" else 1
    if geometry.geom_type == "Polygon":
        props["vertex_count"] = sum(
            len(ring.coords) for ring in [geometry.exterior, *geometry.interiors]
        )
    else:
        props["vertex_count"] = sum(
            len(ring.coords)
            for polygon in geometry.geoms
            for ring in [polygon.exterior, *polygon.interiors]
        )


def apply_strumica_correction(features: dict[str, dict], extract_by_role: dict) -> dict:
    r72_feature = features["region_072"]
    r74_feature = features["region_074"]
    r78_feature = features["region_078"]

    r72_old = shape(r72_feature["geometry"])
    r74_old = shape(r74_feature["geometry"])
    r78_geom = shape(r78_feature["geometry"])

    if r72_old.geom_type != "Polygon" or r74_old.geom_type != "Polygon":
        raise ValueError("region_072 et region_074 doivent être de type Polygon")

    raw72 = list(r72_old.exterior.coords)[:-1]
    raw74 = list(r74_old.exterior.coords)[:-1]
    ring72 = [(round(x, 6), round(y, 6)) for x, y in raw72]
    ring74 = [(round(x, 6), round(y, 6)) for x, y in raw74]

    # Locate anchor vertices on region_074 (Serbie) and region_072 (Bulgarie occidentale)
    for label, pt, ring, rid in (
        ("Mount Tumba", MOUNT_TUMBA, ring74, "region_074"),
        ("Cote 1445", COTE_1445, ring74, "region_074"),
        ("Belasica Peak 1494", BELASICA_PEAK_1494, ring74, "region_074"),
        ("Mount Tumba", MOUNT_TUMBA, ring72, "region_072"),
        ("Cote 1445", COTE_1445, ring72, "region_072"),
    ):
        if pt not in ring:
            raise ValueError(f"Point d'ancrage {label} {pt} introuvable dans {rid}")

    idx74_tumba = ring74.index(MOUNT_TUMBA)
    idx74_1445 = ring74.index(COTE_1445)
    idx74_1494 = ring74.index(BELASICA_PEAK_1494)

    idx72_1445 = ring72.index(COTE_1445)
    idx72_tumba = ring72.index(MOUNT_TUMBA)

    if not (idx74_tumba == 1 and idx74_1445 == 40 and idx74_1494 == 1700):
        raise ValueError(
            f"Indices inattendus dans region_074: Tumba={idx74_tumba}, "
            f"Cote1445={idx74_1445}, Peak1494={idx74_1494}"
        )
    if not (idx72_1445 == 592 and idx72_tumba == 631):
        raise ValueError(
            f"Indices inattendus dans region_072: Cote1445={idx72_1445}, Tumba={idx72_tumba}"
        )

    frontier_s_to_n = [
        (round(x, 6), round(y, 6))
        for x, y in extract_by_role["bucharest_1913_full_strumica_frontier"]["geometry"]["coordinates"]
    ]
    if frontier_s_to_n[0] != BELASICA_PEAK_1494 or frontier_s_to_n[-1] != COTE_1445:
        raise ValueError("Extrémités de la frontière 1913 de Stroumitsa invalides")

    # Preserve exact native coordinates at the shared anchor vertices
    frontier_s_to_n[0] = raw74[idx74_1494]
    frontier_s_to_n[-1] = raw74[idx74_1445]

    neuilly_1919_s_to_n = raw74[idx74_tumba:idx74_1445 + 1]
    belasica_crest_w_to_e = raw74[idx74_1494:] + raw74[:idx74_tumba + 1]

    # Construct the transferred Strumica salient polygon
    salient_ring = frontier_s_to_n + list(reversed(neuilly_1919_s_to_n[:-1])) + list(reversed(belasica_crest_w_to_e[:-1]))
    salient_poly = shapely.orient_polygons(Polygon(salient_ring), exterior_cw=False)
    if not salient_poly.is_valid or salient_poly.is_empty:
        raise ValueError(f"Polygone du saillant invalide: {shapely.is_valid_reason(salient_poly)}")

    # Build updated region_074 and region_072 rings preserving all untouched vertices bit-for-bit
    new_ring74 = frontier_s_to_n + raw74[idx74_1445 + 1:idx74_1494]
    new_ring72 = (
        raw72[:idx72_1445]
        + list(reversed(frontier_s_to_n))
        + belasica_crest_w_to_e[1:-1]
        + raw72[idx72_tumba:]
    )

    r74_new = shapely.orient_polygons(Polygon(new_ring74), exterior_cw=False)
    r72_new = shapely.orient_polygons(Polygon(new_ring72), exterior_cw=False)

    if not r72_new.is_valid or not r74_new.is_valid:
        raise ValueError("Géométrie mise à jour invalide pour region_072 ou region_074")

    # Topological & area conservation checks
    overlap_72_74 = r72_new.intersection(r74_new).area
    overlap_72_78 = r72_new.intersection(r78_geom).area
    overlap_74_78 = r74_new.intersection(r78_geom).area
    if max(overlap_72_74, overlap_72_78, overlap_74_78) > STRICT_OVERLAP_EPSILON:
        raise ValueError(
            f"Chevauchement détecté: 72/74={overlap_72_74}, 72/78={overlap_72_78}, 74/78={overlap_74_78}"
        )

    sym_diff_union = r72_old.union(r74_old).symmetric_difference(r72_new.union(r74_new)).area
    if sym_diff_union > 1e-12:
        raise ValueError(f"Altération de l'enveloppe externe 072+074: {sym_diff_union:.3g} deg²")

    area72_before = projected_area_km2(r72_old)
    area74_before = projected_area_km2(r74_old)
    area72_after = projected_area_km2(r72_new)
    area74_after = projected_area_km2(r74_new)
    salient_area_km2 = projected_area_km2(salient_poly)

    if abs((area72_after + area74_after) - (area72_before + area74_before)) > 1e-6:
        raise ValueError("Non-conservation de la superficie cumulée region_072 + region_074")

    # Verify Strumica and all historical localities
    strumica_pt = Point(*STRUMICA_POINT)
    if not r72_new.contains(strumica_pt) or r74_new.contains(strumica_pt):
        raise ValueError("Attribution incorrecte du point de Stroumitsa après correction")

    locality_checks = {"bulgarian_salient_in_072": {}, "serbian_border_in_074": {}}
    for name, coords in BULGARIAN_SALIENT_LOCALITIES.items():
        pt = Point(*coords)
        in_72 = bool(r72_new.contains(pt))
        in_74 = bool(r74_new.contains(pt))
        if not in_72 or in_74:
            raise ValueError(f"Localité bulgare {name} {coords} mal attribuée: 072={in_72}, 074={in_74}")
        locality_checks["bulgarian_salient_in_072"][name] = {
            "lon_lat": list(coords),
            "in_072": in_72,
            "in_074": in_74,
        }

    for name, coords in SERBIAN_BORDER_LOCALITIES.items():
        pt = Point(*coords)
        in_74 = bool(r74_new.contains(pt))
        in_72 = bool(r72_new.contains(pt))
        if not in_74 or in_72:
            raise ValueError(f"Localité serbe {name} {coords} mal attribuée: 074={in_74}, 072={in_72}")
        locality_checks["serbian_border_in_074"][name] = {
            "lon_lat": list(coords),
            "in_074": in_74,
            "in_072": in_72,
        }

    # Update geometries and properties
    r72_feature["geometry"] = mapping(r72_new)
    r74_feature["geometry"] = mapping(r74_new)
    update_region_metrics(r72_feature, r72_new)
    update_region_metrics(r74_feature, r74_new)

    # Update editorial traceability on region_072 and region_074
    props72 = r72_feature["properties"]
    admin72 = list(props72.get("historical_admin_units") or [])
    if "Pétritch (Petrich)" in admin72:
        idx_pet = admin72.index("Pétritch (Petrich)")
        admin72[idx_pet] = "Stroumitsa / Pétritch (Strumica / Petrich)"
    props72["historical_admin_units"] = admin72
    props72["source_layer"] = (
        "REGIS_Bulgaria.gpkg:REGIS_Bulgaria_L2_1923-1925 + "
        "REGIS_Bulgaria_L0_1886-1912 + "
        "REGIS_Yugoslavia.gpkg:REGIS_Yugoslavia_L1_1920-1923 (saillant de Stroumitsa 1913)"
    )
    props72["notes"] = (
        "Regroupe les okrugs occidentaux de Vidin, Vratsa, Pleven, Sofia, Kyoustendil "
        "(incluant Tsaribrod et Bosilegrad, bulgares en 1914) et Stroumitsa/Pétritch "
        "(Macédoine du Pirin et saillant de Stroumitsa acquis au traité de Bucarest du 10 août 1913)."
    )
    approx72 = [
        item for item in (props72.get("approximations") or [])
        if not item.startswith("MAJ-003")
    ]
    approx72.append(
        f"MAJ-003 : rattachement du saillant de Stroumitsa ({salient_area_km2:.2f} km², "
        "okoliya de Stroumitsa et villages frontaliers occidentaux de l'okoliya de Pétritch) "
        "à region_072 d'après le traité de Bucarest du 10 août 1913 (art. III et V, protocole n° 9), "
        "la limite REGIS_Yugoslavia_L1_1920-1923 (Bregalnitsa/Bitoly) entre la Cote 1445 et le mont Plavuš, "
        "et la ligne de partage des eaux Vardar-Strouma par le col de Kosturino jusqu'à la Cote 1494 sur la Belasica."
    )
    props72["approximations"] = approx72

    props74 = r74_feature["properties"]
    props74["source_layer"] = (
        "REGIS_Yugoslavia.gpkg:REGIS_Yugoslavia_L2_1948-1954 + "
        "REGIS_Yugoslavia_L1_1920-1923 + "
        "REGIS_Serbia_L1_1900-1901"
    )
    props74["notes"] = (
        "Royaume de Serbie dans ses frontières du 1er janvier 1914 (issues du traité de Bucarest "
        "du 10 août 1913) : Vieille Serbie au sud du Danube et de la Save (hors Voïvodine/Syrmie "
        "austro-hongroise), Sandjak oriental, Kosovo et Macédoine du Vardar (Skopje, Bitola, Radoviš, "
        "Valandovo, Dojran), sans les confins de Tsaribrod/Bosilegrad ni le saillant de Stroumitsa "
        "(conservés dans la Bulgarie occidentale region_072)."
    )
    approx74 = [
        item for item in (props74.get("approximations") or [])
        if not item.startswith("MAJ-003")
    ]
    approx74.append(
        f"MAJ-003 : retrait du saillant de Stroumitsa ({salient_area_km2:.2f} km², cédé au Royaume "
        "des Serbes, Croates et Slovènes seulement au traité de Neuilly-sur-Seine du 27 novembre 1919) "
        "au profit de region_072 ; maintien de la haute vallée de la Stroumitsa (bassin de Radoviš / "
        "Stara Reka) et de la Bojmija (Valandovo, Rabrovo) en territoire serbe conformément à "
        "l'article III du traité de Bucarest (10 août 1913)."
    )
    props74["approximations"] = approx74

    return {
        "mission": "MAJ-003",
        "target_date": "1914-01-01",
        "salient": {
            "area_km2_epsg3035": round(salient_area_km2, 6),
            "area_km2_rounded": round(salient_area_km2, 2),
            "bounds_epsg4326": [round(v, 6) for v in salient_poly.bounds],
            "vertex_count_ring": len(salient_ring),
            "anchors": {
                "north_divergence_1913_1919_cote_1445": list(COTE_1445),
                "west_tripoint_plavus": list(PLAVUS_TRIPOINT),
                "south_tripoint_1913_belasica_peak_1494": list(BELASICA_PEAK_1494),
                "southeast_tripoint_1919_mount_tumba": list(MOUNT_TUMBA),
            },
            "segments": {
                "regis_l1_1920_1923_bregalnitsa_bitoly_vertices": 32,
                "watershed_plavus_kosturino_belasica_vertices": 8,
                "full_1913_bucharest_frontier_vertices": len(frontier_s_to_n),
                "replaced_1919_neuilly_frontier_vertices": len(neuilly_1919_s_to_n),
                "belasica_crest_1494_to_tumba_vertices": len(belasica_crest_w_to_e),
            },
        },
        "regions": {
            "region_072": {
                "area_km2_before": round(area72_before, 6),
                "area_km2_after": round(area72_after, 6),
                "area_km2_published_before": 40498.91,
                "area_km2_published_after": props72["area_km2"],
                "delta_km2": round(area72_after - area72_before, 6),
                "vertex_count_before": len(ring72) + 1,
                "vertex_count_after": props72["vertex_count"],
                "strumica_contains_before": False,
                "strumica_contains_after": True,
            },
            "region_074": {
                "area_km2_before": round(area74_before, 6),
                "area_km2_after": round(area74_after, 6),
                "area_km2_published_before": 89797.38,
                "area_km2_published_after": props74["area_km2"],
                "delta_km2": round(area74_after - area74_before, 6),
                "vertex_count_before": len(ring74) + 1,
                "vertex_count_after": props74["vertex_count"],
                "strumica_contains_before": True,
                "strumica_contains_after": False,
            },
        },
        "conservation": {
            "sum_072_074_before_km2": round(area72_before + area74_before, 6),
            "sum_072_074_after_km2": round(area72_after + area74_after, 6),
            "envelope_symmetric_difference_deg2": sym_diff_union,
            "overlap_072_074_deg2": overlap_72_74,
            "overlap_072_078_deg2": overlap_72_78,
            "overlap_074_078_deg2": overlap_74_78,
        },
        "locality_checks": locality_checks,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--input-dir", type=Path, default=DEFAULT_INPUT_DIR, help="Directory containing input regions.geojson and regions.json")
    parser.add_argument("--strumica-extract", type=Path, default=DEFAULT_EXTRACT, help="Derived Strumica 1913 frontier GeoJSON extract")
    parser.add_argument("--output-dir", type=Path, required=True, help="Staging directory for the corrected output files")
    args = parser.parse_args()

    input_dir = args.input_dir.resolve()
    output_dir = args.output_dir.resolve()
    canonical_dir = (ROOT / "data/world/map").resolve()
    if output_dir == canonical_dir or canonical_dir in output_dir.parents:
        raise ValueError(
            "Refus d'écrire directement dans data/world/map ; utiliser un répertoire de staging."
        )

    geojson_in = input_dir / "regions.geojson"
    regions_in = input_dir / "regions.json"
    for path in (geojson_in, regions_in, args.strumica_extract):
        if not path.exists():
            raise FileNotFoundError(f"Fichier introuvable: {path}")

    collection = json.loads(geojson_in.read_text(encoding="utf-8"))
    metadata = json.loads(regions_in.read_text(encoding="utf-8"))
    features = {feature["properties"]["id"]: feature for feature in collection["features"]}
    if len(features) != 90:
        raise ValueError(f"Attendu 90 régions, observé {len(features)}")

    extract_by_role = load_frontier_extract(args.strumica_extract)
    report = apply_strumica_correction(features, extract_by_role)

    # Full-atlas validity & overlap check
    geometries = {rid: shape(feature["geometry"]) for rid, feature in features.items()}
    overlap_count = 0
    max_overlap = 0.0
    ids = sorted(geometries)
    for index, left in enumerate(ids):
        for right in ids[index + 1:]:
            area = geometries[left].intersection(geometries[right]).area
            if area > STRICT_OVERLAP_EPSILON:
                overlap_count += 1
                max_overlap = max(max_overlap, area)
    if overlap_count:
        raise ValueError(f"Chevauchements détectés: {overlap_count} (max {max_overlap:.12g} deg²)")

    ordered = [features[f"region_{number:03d}"] for number in range(1, 91)]
    collection["features"] = ordered
    metadata["regions"] = [feature["properties"] for feature in ordered]

    report["atlas"] = {
        "features": len(ordered),
        "valid": sum(geom.is_valid and not geom.is_empty for geom in geometries.values()),
        "overlap_pairs_gt_1e-10_deg2": overlap_count,
        "max_overlap_deg2": max_overlap,
        "total_area_km2_published_sum": round(
            sum(feature["properties"]["area_km2"] for feature in ordered), 2
        ),
        "total_area_km2_unrounded_sum": round(
            sum(projected_area_km2(geom) for geom in geometries.values()), 6
        ),
    }

    output_dir.mkdir(parents=True, exist_ok=True)
    geojson_out = output_dir / "regions.geojson"
    regions_out = output_dir / "regions.json"
    report_out = output_dir / "strumica_salient_report.json"

    geojson_out.write_text(json.dumps(collection, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    regions_out.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    report_out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"Écrit: {geojson_out}")
    print(f"Écrit: {regions_out}")
    print(f"Écrit: {report_out}")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"ERREUR: {error}", file=sys.stderr)
        raise SystemExit(1)
