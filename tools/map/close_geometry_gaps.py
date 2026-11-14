#!/usr/bin/env python3
"""Close the four MAJ-004 inter-source seam gaps (tested against a copy).

The script reads the assembled atlas from this repository, identifies the four
gap components documented in docs/map/audit/ISSUES.json, and writes a corrected
GeoJSON + JSON metadata pair into a caller-supplied directory.  It never writes
to data/world/map/regions.geojson or data/world/map/regions.json.

Historical allocation:
  * Finland/Olonets: the whole sliver goes to region_052 (Finland).  The
    RISTAT 1897 province layer puts the sliver in Vyborg/Kuopio, i.e. on the
    Finnish side of the Vyborg/Olonets boundary.  Kavanagh's "Russia" polygon
    includes the Grand Duchy of Finland and therefore cannot arbitrate this
    internal border.
  * Khotin/Herța tripoint: split among region_040 (Austria-Hungary/Bukovina),
    region_062 (Russia/Bessarabia) and region_071 (Romania/Moldavia) with the
    Kavanagh 1914 national polygons.
  * Pasvik north/south: split between region_047 (Norway) and region_065
    (Russia) with the Kavanagh 1914 national polygons; this line follows the
    unchanged 1826 Norway-Russia treaty border.

Usage:
  python tools/map/close_geometry_gaps.py \
      --kavanagh /path/to/europe_1914.gpkg \
      --ristat /path/to/ristat_1897_provinces.gpkg \
      --output-dir /tmp/opencode/gs1914-corrected
"""
import argparse
import json
import sys
from pathlib import Path

import pyogrio
import shapely
from pyproj import Transformer
from shapely.geometry import MultiPolygon, Point, box, mapping, shape
from shapely.ops import transform, unary_union


ROOT = Path(__file__).resolve().parents[2]
GEOJSON_PATH = ROOT / "data/world/map/regions.geojson"
REGIONS_PATH = ROOT / "data/world/map/regions.json"

TO_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True).transform
STRICT_OVERLAP_EPSILON = 1e-10

# (sentinel, analysis window, expected gap area in km², historical allocation)
GAPS = {
    "finland": {
        "sentinel": (32.3258, 62.6315),
        "window": (31.0, 61.8, 33.4, 63.4),
        "expected_km2": 662.474739,
        "allocation": {"region_052": "whole"},
    },
    "tripoint": {
        "sentinel": (26.1997, 48.3030),
        "window": (25.4, 47.7, 27.0, 48.9),
        "expected_km2": 225.876731,
        "allocation": {
            "region_040": "Austria-Hungary",
            "region_062": "Russia",
            "region_071": "Romania",
        },
    },
    "pasvik_north": {
        "sentinel": (30.5256, 69.5879),
        "window": (29.9, 68.99, 31.13, 70.19),
        "expected_km2": 117.048461,
        "allocation": {
            "region_047": "Norway",
            "region_065": "Russia",
        },
    },
    "pasvik_south": {
        "sentinel": (29.7994, 69.4143),
        "window": (29.19, 68.81, 30.4, 70.02),
        "expected_km2": 92.085230,
        "allocation": {
            "region_047": "Norway",
            "region_065": "Russia",
        },
    },
}

# Deterministic order used to turn the near-exact country intersections into an
# exact partition.  Any zero-width residual goes to the last country (Russia).
ALLOCATION_ORDER = {
    "finland": (),
    "tripoint": ("Austria-Hungary", "Romania", "Russia"),
    "pasvik_north": ("Norway", "Russia"),
    "pasvik_south": ("Norway", "Russia"),
}

COUNTRY_LABELS = {
    "region_040": "la Bucovine (Autriche-Hongrie)",
    "region_062": "la Bessarabie (Russie)",
    "region_071": "la Moldavie (Roumanie)",
    "region_047": "la Norvège",
    "region_065": "la Russie",
}

# A reassigned component is attached to its destination when it shares a real
# boundary segment.  Point-only contacts are not treated as contiguity; they are
# resolved by the nearest-region rule below.
CONTIGUITY_TOLERANCE_DEG = 0.001


def approximation_note(rid, labels_and_areas, adjusted):
    """Build one approximation note from the final, post-contiguity areas."""
    sentences = []
    for label, area in labels_and_areas.items():
        if label == "finland":
            if rid == "region_052":
                sentences.append(
                    f"MAJ-004 : lacune de couture de {area:.2f} km² au sud-est "
                    "de la frontière finlandaise (secteur de Suojärvi) comblée "
                    "au profit de la Finlande d'après la limite Vyborg/Olonets "
                    "de RISTAT 1897."
                )
        elif label == "tripoint":
            sentences.append(
                f"MAJ-004 : {area:.2f} km² de la lacune du tripoint "
                f"Khotin/Herța attribués à {COUNTRY_LABELS[rid]} d'après la "
                "frontière nationale Kavanagh 1914."
            )
        elif label in ("pasvik_north", "pasvik_south"):
            pass  # handled jointly below
    pasvik = {
        label: labels_and_areas[label]
        for label in ("pasvik_north", "pasvik_south")
        if label in labels_and_areas
    }
    if pasvik:
        chunks = []
        if "pasvik_north" in pasvik:
            chunks.append(f"{pasvik['pasvik_north']:.2f} km² (Pasvik nord)")
        if "pasvik_south" in pasvik:
            chunks.append(f"{pasvik['pasvik_south']:.2f} km² (Pasvik sud)")
        sentences.append(
            f"MAJ-004 : {' et '.join(chunks)} de lacune attribués à "
            f"{COUNTRY_LABELS[rid]} d'après la frontière nationale Kavanagh "
            "1914, qui reprend la frontière norvégio-russe de 1826."
        )
    if adjusted:
        sentences.append(
            "La répartition inclut un ajustement de contiguïté topologique "
            "documenté dans geometry_gaps_report.json."
        )
    return " ".join(sentences)


def load_features(path):
    collection = json.loads(path.read_text(encoding="utf-8"))
    features = collection["features"]
    ids = [feature["properties"]["id"] for feature in features]
    expected = [f"region_{number:03d}" for number in range(1, 91)]
    if len(features) != 90 or sorted(ids) != expected:
        raise ValueError(f"Inventaire attendu: 90 IDs region_001..region_090; observé {len(features)}")
    return collection, {feature["properties"]["id"]: feature for feature in features}


def load_named_layer(path, layer, name_field="name"):
    meta, _fids, geometries, fields = pyogrio.raw.read(
        path, layer=layer, columns=[name_field], read_geometry=True
    )
    names = fields[0]
    return {
        str(name): shapely.from_wkb(wkb)
        for name, wkb in zip(names, geometries)
    }


def polygonal(geometry):
    if geometry.geom_type in ("Polygon", "MultiPolygon"):
        return geometry
    polygons = []
    for part in getattr(geometry, "geoms", []):
        if part.geom_type == "Polygon":
            polygons.append(part)
        elif part.geom_type == "MultiPolygon":
            polygons.extend(part.geoms)
    if not polygons:
        raise ValueError("La correction a supprimé toute la géométrie polygonale")
    return MultiPolygon(polygons)


def projected_area_km2(geometry):
    return transform(TO_3035, geometry).area / 1_000_000


def gap_component(geometries, sentinel, window, expected_km2):
    union = unary_union(list(geometries.values()))
    gap = box(*window).difference(union)
    parts = [
        part
        for part in (gap.geoms if gap.geom_type == "MultiPolygon" else [gap])
        if part.area > 1e-7
    ]
    if not parts:
        raise ValueError(f"Aucune lacune trouvée autour de {sentinel}")
    point = Point(*sentinel)
    containing = [part for part in parts if part.buffer(1e-9).contains(point)]
    if containing:
        component = containing[0]
    else:
        component = min(parts, key=lambda part: part.distance(point))
    area = projected_area_km2(component)
    if abs(area - expected_km2) > 0.01:
        raise ValueError(
            f"Lacune autour de {sentinel}: {area:.6f} km², attendu {expected_km2:.6f} km²"
        )
    return component, area


def exact_partition(gap, sources, order):
    """Partition gap exactly using source polygons, in deterministic order.

    Returns {country: geometry} plus the residual (zero-width) geometry.
    """
    pieces = {}
    cursor = gap
    for country in order:
        if country not in sources:
            raise ValueError(f"Source pays absente: {country}")
        piece = cursor.intersection(sources[country])
        if piece.is_empty:
            raise ValueError(f"Pièce vide pour {country}")
        pieces[country] = piece
        cursor = cursor.difference(piece)
    return pieces, cursor


def split_components(geometry):
    if geometry.is_empty:
        return []
    if geometry.geom_type == "Polygon":
        return [geometry]
    if geometry.geom_type == "MultiPolygon":
        return list(geometry.geoms)
    return [
        part
        for part in getattr(geometry, "geoms", [])
        if part.geom_type == "Polygon" and not part.is_empty
    ]


def reassign_detached(pieces, base_geometries):
    """Keep every assigned component topologically contiguous.

    A component that does not share a boundary with the region it was assigned
    to, and is separated from it, is moved to the region it shares the longest
    boundary with.  If it shares no boundary at all, it is moved to the nearest
    region within 0.001° (about 110 m).  Farther pieces are kept where the
    historical partition puts them and reported as intentionally detached.
    Point-only contacts are kept: an OGC multi-polygon may touch at a point.
    """
    grouped = {}
    adjustments = []
    for rid, piece in pieces.items():
        for component in split_components(piece):
            if component.area <= 1e-12:
                continue
            shared = component.intersection(base_geometries[rid]).length
            separation = component.distance(base_geometries[rid])
            target = rid
            reason = None
            # A point-only contact still belongs to the same polygon (OGC
            # allows multi-polygons to touch at points), so it counts as
            # attached.  Only genuinely separated components are reassigned.
            if shared <= 1e-12 and separation > 1e-9:
                best_length = 0.0
                best_region = None
                for other_id, base in base_geometries.items():
                    if other_id == rid:
                        continue
                    length = component.intersection(base).length
                    if length > best_length:
                        best_length = length
                        best_region = other_id
                if best_region is not None and best_length > 1e-12:
                    target = best_region
                    reason = (
                        f"frontière commune avec {best_region} "
                        f"({best_length:.6g}°)"
                    )
                else:
                    distance, nearest = min(
                        (component.distance(base), other_id)
                        for other_id, base in base_geometries.items()
                        if other_id != rid
                    )
                    if distance <= CONTIGUITY_TOLERANCE_DEG:
                        target = nearest
                        reason = (
                            f"région la plus proche {nearest} à {distance:.6g}°"
                        )
                    else:
                        reason = (
                            f"laisse détaché : {nearest} à {distance:.6g}° "
                            f"> {CONTIGUITY_TOLERANCE_DEG}°"
                        )
            if target != rid:
                adjustments.append(
                    {
                        "from_region": rid,
                        "to_region": target,
                        "area_km2": round(projected_area_km2(component), 6),
                        "reason": reason,
                        "bounds": [round(value, 6) for value in component.bounds],
                    }
                )
            grouped.setdefault(target, []).append(component)
    return {
        rid: polygonal(unary_union(components))
        for rid, components in grouped.items()
    }, adjustments


def add_geometry(geometries, rid, piece):
    current = geometries[rid]
    merged = polygonal(shapely.make_valid(unary_union([current, piece])))
    if merged.is_empty or not merged.is_valid:
        raise ValueError(f"Fusion invalide pour {rid}")
    geometries[rid] = merged


def update_metrics(features, geometries, ids):
    for rid in ids:
        feature = features[rid]
        geometry = geometries[rid]
        if not geometry.is_valid or geometry.is_empty:
            raise ValueError(f"Géométrie invalide: {rid} ({shapely.is_valid_reason(geometry)})")
        props = feature["properties"]
        projected = transform(TO_3035, geometry)
        centroid = geometry.centroid
        representative = geometry.representative_point()
        props["area_km2"] = round(projected.area / 1_000_000, 2)
        props["centroid_lon_lat"] = [round(centroid.x, 6), round(centroid.y, 6)]
        props["representative_point_lon_lat"] = [round(representative.x, 6), round(representative.y, 6)]
        props["bbox"] = [round(value, 6) for value in geometry.bounds]
        props["polygon_parts_count"] = len(geometry.geoms) if geometry.geom_type == "MultiPolygon" else 1
        if geometry.geom_type == "Polygon":
            props["vertex_count"] = sum(len(ring.coords) for ring in [geometry.exterior, *geometry.interiors])
        else:
            props["vertex_count"] = sum(
                len(ring.coords)
                for polygon in geometry.geoms
                for ring in [polygon.exterior, *polygon.interiors]
            )


def assert_partition(label, pieces, gap, residual):
    overlap_pairs = []
    names = sorted(pieces)
    for index, left in enumerate(names):
        for right in names[index + 1:]:
            overlap = pieces[left].intersection(pieces[right])
            if not overlap.is_empty and projected_area_km2(overlap) > 1e-9:
                overlap_pairs.append((left, right, projected_area_km2(overlap)))
    if overlap_pairs:
        raise ValueError(f"{label}: chevauchements de partition {overlap_pairs}")
    residual_area = residual.area if not residual.is_empty else 0.0
    if residual_area > 1e-12:
        raise ValueError(f"{label}: résidu surfacique non attribué ({residual_area:.3g} deg²)")
    covered = projected_area_km2(unary_union(list(pieces.values())))
    total = projected_area_km2(gap)
    if abs(covered - total) > 0.01:
        raise ValueError(f"{label}: partition incomplète ({covered:.6f} / {total:.6f} km²)")


def close_gaps(features, kavanagh, ristat):
    geometries = {rid: shape(feature["geometry"]) for rid, feature in features.items()}
    base_geometries = dict(geometries)
    original_gaps = {}
    modified = set()
    area_by_gap_region = {}
    all_adjustments = []
    report = {"gaps": {}, "assignments": [], "contiguity_adjustments": []}
    for label, spec in GAPS.items():
        gap, area = gap_component(
            geometries, spec["sentinel"], spec["window"], spec["expected_km2"]
        )
        original_gaps[label] = gap
        report["gaps"][label] = {
            "sentinel": list(spec["sentinel"]),
            "area_km2_before": round(area, 6),
            "bounds": [round(value, 6) for value in gap.bounds],
        }
        allocation = spec["allocation"]
        if allocation == {"region_052": "whole"}:
            # Verify the historical allocation against the RISTAT 1897
            # governorate layer: the whole sliver must be Vyborg/Kuopio.
            finnish_names = ("Kuopio governorate", "Vyborg governorate")
            ristat_parts = {
                name: gap.intersection(ristat[name])
                for name in finnish_names
                if name in ristat
            }
            if len(ristat_parts) != len(finnish_names):
                raise ValueError("Les gouvernements RISTAT Vyborg/Kuopio sont absents")
            ristat_cover = unary_union(list(ristat_parts.values()))
            uncovered = gap.difference(ristat_cover)
            uncovered_km2 = projected_area_km2(uncovered) if not uncovered.is_empty else 0.0
            # The residual is 0.0013 km² (0.0002 %) of boundary-generalization
            # slivers that RISTAT's generalized Olonets polygon clips from the
            # gap.  It is far below the 0.01 km² tolerance and is assigned to
            # Finland with the rest of the sliver; see the report.
            if uncovered_km2 > 0.01:
                raise ValueError(
                    f"Finlande: {uncovered_km2:.6f} km² hors RISTAT Vyborg/Kuopio"
                )
            report["gaps"][label]["ristat_coverage_km2"] = {
                name: round(projected_area_km2(piece), 6)
                for name, piece in ristat_parts.items()
            }
            report["gaps"][label]["ristat_uncovered_km2"] = round(uncovered_km2, 6)
            pieces = {"region_052": gap}
            residual = gap.difference(gap)
        else:
            order = ALLOCATION_ORDER[label]
            report["gaps"][label]["kavanagh_coverage_km2"] = {
                country: round(projected_area_km2(gap.intersection(kavanagh[country])), 6)
                for country in order
                if country in kavanagh
            }
            by_country, residual = exact_partition(gap, kavanagh, order)
            # The zero-width residual is line-like; give it to the last country
            # so that the partition is exact without creating a new area.
            if not residual.is_empty:
                by_country[order[-1]] = unary_union([by_country[order[-1]], residual])
                residual = gap.difference(unary_union(list(by_country.values())))
            assert_partition(label, by_country, gap, residual)
            pieces = {
                rid: by_country[country]
                for rid, country in allocation.items()
            }
        pieces, adjustments = reassign_detached(pieces, base_geometries)
        for adjustment in adjustments:
            adjustment["gap"] = label
            all_adjustments.append(adjustment)
        for rid, piece in pieces.items():
            piece_area = projected_area_km2(piece)
            add_geometry(geometries, rid, piece)
            modified.add(rid)
            area_by_gap_region.setdefault(label, {})
            area_by_gap_region[label][rid] = (
                area_by_gap_region[label].get(rid, 0.0) + piece_area
            )
            props = features[rid]["properties"]
            props["source_refs"] = sorted(
                set(props.get("source_refs", []))
                | ({"ristat_1897_v1"} if label == "finland" else {"kavanagh_1914_v1"})
            )
            report["assignments"].append(
                {
                    "gap": label,
                    "region_id": rid,
                    "country": allocation.get(rid, "contiguity adjustment"),
                    "area_km2": round(piece_area, 6),
                }
            )
    report["contiguity_adjustments"] = all_adjustments
    # Notes are generated after contiguity so the published areas are the
    # final, on-disk areas and no region receives duplicate wording.
    notes_by_region = {}
    for label, by_region in area_by_gap_region.items():
        for rid, area in by_region.items():
            notes_by_region.setdefault(rid, {})[label] = area
    for rid, labels_and_areas in notes_by_region.items():
        adjusted = any(
            adjustment["from_region"] == rid or adjustment["to_region"] == rid
            for adjustment in all_adjustments
        )
        note = approximation_note(rid, labels_and_areas, adjusted)
        props = features[rid]["properties"]
        approximations = list(props.get("approximations") or [])
        if not any(item.startswith("MAJ-004") for item in approximations):
            approximations.append(note)
        props["approximations"] = approximations
    if "finland" in area_by_gap_region:
        finland_km2 = sum(area_by_gap_region["finland"].values())
        props = features["region_064"]["properties"]
        approximations = list(props.get("approximations") or [])
        if not any(item.startswith("MAJ-004") for item in approximations):
            approximations.append(
                f"MAJ-004 : la lacune adjacente de {finland_km2:.2f} km² "
                "(secteur de Suojärvi) a été attribuée à region_052 d'après la "
                "limite Vyborg/Olonets de RISTAT 1897 ; la limite occidentale "
                "de la Russie du Nord-Ouest reste inchangée."
            )
        props["approximations"] = approximations
    # Keep the native precision of the Kavanagh seams.  Independent rounding
    # of the two sides of a new seam to 10^-6° reopens 21-78 m² gaps; the rest
    # of the atlas already sits on the canonical 10^-6° grid.
    # Remove any micro-overlap introduced by the overlay operations.  As in
    # build_geometry.py, only intersections <= 1e-6 deg² are repaired.  When one
    # side is untouched, remove the overlap from the touched side so that the
    # canonical geometry of innocent neighbours is preserved.
    ids = sorted(geometries)
    repairs = []
    for _ in range(10):
        changed = False
        for index, left_id in enumerate(ids):
            for right_id in ids[index + 1:]:
                if left_id not in modified and right_id not in modified:
                    continue
                inter = geometries[left_id].intersection(geometries[right_id])
                if inter.is_empty or inter.area <= STRICT_OVERLAP_EPSILON:
                    continue
                if inter.area > 1e-6:
                    raise ValueError(
                        f"Chevauchement non microscopique: {left_id}/{right_id} "
                        f"({inter.area:.12g} deg²)"
                    )
                target_id = left_id if left_id in modified and right_id not in modified else right_id
                other_id = right_id if target_id == left_id else left_id
                geometries[target_id] = shapely.orient_polygons(
                    polygonal(geometries[target_id].difference(geometries[other_id])),
                    exterior_cw=False,
                )
                modified.add(target_id)
                repairs.append((left_id, right_id, target_id, inter.area))
                changed = True
        if not changed:
            break
    update_metrics(features, geometries, modified)
    for rid in modified:
        features[rid]["geometry"] = mapping(geometries[rid])
    report["rounding_repairs"] = [
        {"left": left, "right": right, "subtracted_from": target, "area_deg2": area}
        for left, right, target, area in repairs
    ]
    report["gaps_after"] = {}
    union_after = unary_union(list(geometries.values()))
    for label, spec in GAPS.items():
        point = Point(*spec["sentinel"])
        residual = original_gaps[label].difference(union_after)
        residual_area = projected_area_km2(residual) if not residual.is_empty else 0.0
        report["gaps_after"][label] = {
            "residual_area_km2": round(residual_area, 6) if residual_area > 1e-6 else 0.0,
            "sentinel_covered_by": [
                rid
                for rid, geom in geometries.items()
                if geom.buffer(1e-9).contains(point)
            ],
        }
    return geometries, report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--kavanagh", type=Path, required=True, help="Kavanagh 1914 GeoPackage")
    parser.add_argument("--ristat", type=Path, required=True, help="RISTAT 1897 provinces GeoPackage")
    parser.add_argument("--output-dir", type=Path, required=True, help="Directory for the corrected test copy")
    args = parser.parse_args()

    output_dir = args.output_dir.resolve()
    canonical_dir = (ROOT / "data/world/map").resolve()
    if output_dir == canonical_dir or canonical_dir in output_dir.parents:
        raise ValueError(
            "Refus d'écrire dans le répertoire canonique data/world/map ; "
            "utiliser un répertoire de test hors du dépôt."
        )

    collection, features = load_features(GEOJSON_PATH)
    kavanagh = load_named_layer(args.kavanagh, "europe_1914", "name")
    ristat = load_named_layer(args.ristat, "provinces_1897", "prov_ENG")

    geometries, report = close_gaps(features, kavanagh, ristat)

    # Final full-atlas checks, independent of the repo validators.
    overlap_count = 0
    max_overlap = 0.0
    ids = sorted(geometries)
    for index, left in enumerate(ids):
        for right in ids[index + 1:]:
            area = geometries[left].intersection(geometries[right]).area
            if area > STRICT_OVERLAP_EPSILON:
                overlap_count += 1
                max_overlap = max(max_overlap, area)
    report["atlas"] = {
        "features": len(features),
        "valid": sum(geometry.is_valid and not geometry.is_empty for geometry in geometries.values()),
        "overlap_pairs_gt_1e-10_deg2": overlap_count,
        "max_overlap_deg2": max_overlap,
        "total_area_km2": round(sum(feature["properties"]["area_km2"] for feature in features.values()), 2),
    }
    if overlap_count:
        raise ValueError(f"Chevauchements restants: {overlap_count}, maximum {max_overlap:.12g} deg²")

    ordered = [features[f"region_{number:03d}"] for number in range(1, 91)]
    collection["features"] = ordered
    metadata = json.loads(REGIONS_PATH.read_text(encoding="utf-8"))
    metadata["regions"] = [feature["properties"] for feature in ordered]

    output_dir.mkdir(parents=True, exist_ok=True)
    geojson_out = output_dir / "regions.geojson"
    regions_out = output_dir / "regions.json"
    geojson_out.write_text(json.dumps(collection, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    regions_out.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    report_out = output_dir / "geometry_gaps_report.json"
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
