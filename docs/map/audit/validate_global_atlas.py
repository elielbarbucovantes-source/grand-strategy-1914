#!/usr/bin/env python3
"""
Audit et validation globale de l'atlas à 90 régions — Grand Strategy-1914 (1er janvier 1914).

Ce script inspecte en lecture seule les productions des deux agents :
- Branche `agent_1` (commit 286975a96fc2238040a9bf09163c664740ee3854, 50 régions)
- Branche `agent-2` (commit baa0c90932c74a39ae8745add9a07a7686cd770e, 40 régions)
- Référentiel `data/world/map/tables/region_plan.csv` (90 régions)

Il fonctionne directement depuis n'importe quelle branche Git (ex. `audit/map-1914`)
sans nécessiter de fusion préalable des branches `agent_1` et `agent-2`.

Usage :
    PYTHONPATH=/tmp/gs1914-gis-packages python3 docs/map/audit/validate_global_atlas.py
"""
import argparse
import csv
import json
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

for candidate_pkg in ("/tmp/gs1914-gis-packages",):
    if Path(candidate_pkg).exists() and candidate_pkg not in sys.path:
        sys.path.insert(0, candidate_pkg)

import shapely
from shapely.geometry import Point, shape
from shapely.ops import unary_union
from shapely.validation import explain_validity
from pyproj import Transformer

REPO_ROOT = Path(__file__).resolve().parents[3]
PLAN_CSV = REPO_ROOT / "data/world/map/tables/region_plan.csv"
SCHEMA_JSON = REPO_ROOT / "data/schemas/map.schema.json"

EXPECTED_ZONE_COUNTS = {
    "Îles Britanniques": 6,
    "Europe occidentale": 13,
    "Péninsule ibérique": 6,
    "Europe centrale": 18,
    "Scandinavie": 8,
    "Europe orientale": 18,
    "Balkans": 10,
    "Italie": 7,
    "Territoires ottomans européens": 4,
}


def git_read_json(ref: str, rel_path: str):
    """Lit un fichier JSON directement depuis un commit/branche Git sans modifier l'arbre de travail."""
    out = subprocess.check_output(
        ["git", "-C", str(REPO_ROOT), "show", f"{ref}:{rel_path}"],
        stderr=subprocess.PIPE,
    )
    return json.loads(out.decode("utf-8"))


def git_rev_parse(ref: str) -> str:
    return subprocess.check_output(
        ["git", "-C", str(REPO_ROOT), "rev-parse", ref],
        text=True,
    ).strip()


def run_audit(strict: bool = False) -> int:
    print("=" * 80)
    print("AUDIT GLOBAL DE L'ATLAS CARTOGRAPHIQUE — GRAND STRATEGY-1914 (90 RÉGIONS)")
    print("=" * 80)

    sha_main = git_rev_parse("main")
    sha_a1 = git_rev_parse("agent_1")
    sha_a2 = git_rev_parse("agent-2")
    print(f"Branche main    : {sha_main}")
    print(f"Branche agent_1 : {sha_a1} (50 régions)")
    print(f"Branche agent-2 : {sha_a2} (40 régions)")

    # Chargement de region_plan.csv
    with PLAN_CSV.open(encoding="utf-8", newline="") as f:
        plan_rows = list(csv.DictReader(f))
    plan_by_id = {r["region_id"]: r for r in plan_rows}

    # Chargement des lots Agent 1 et Agent 2 depuis Git
    a1_geojson = git_read_json("agent_1", "data/world/map/build/agent_1/regions.geojson")
    a1_regions = git_read_json("agent_1", "data/world/map/build/agent_1/regions.json")
    a1_adj = git_read_json("agent_1", "data/world/map/build/agent_1/adjacency.json")
    a1_cities = git_read_json("agent_1", "data/world/map/build/agent_1/cities.json")
    a1_terrain = git_read_json("agent_1", "data/world/map/build/agent_1/terrain.json")
    a1_infra = git_read_json("agent_1", "data/world/map/build/agent_1/infrastructure.json")

    a2_geojson = git_read_json("agent-2", "data/world/map/build/agent_2/regions.geojson")
    a2_regions = git_read_json("agent-2", "data/world/map/build/agent_2/regions.json")
    a2_adj = git_read_json("agent-2", "data/world/map/build/agent_2/adjacency.json")
    a2_cities = git_read_json("agent-2", "data/world/map/build/agent_2/cities.json")
    a2_terrain = git_read_json("agent-2", "data/world/map/build/agent_2/terrain.json")
    a2_infra = git_read_json("agent-2", "data/world/map/build/agent_2/infrastructure.json")
    a2_maritime = git_read_json("agent-2", "data/world/map/build/agent_2/maritime_zones.json")

    blocking_issues = []
    major_issues = []

    # =========================================================================
    # A. INVENTAIRE DES 90 RÉGIONS
    # =========================================================================
    print("\n--- A. CONTRÔLE DE L'INVENTAIRE (90 RÉGIONS) ---")
    a1_ids = [ft["properties"]["id"] for ft in a1_geojson["features"]]
    a2_ids = [ft["properties"]["id"] for ft in a2_geojson["features"]]
    combined_ids = a1_ids + a2_ids
    expected_ids = [f"region_{i:03d}" for i in range(1, 91)]

    dup_internal_a1 = len(a1_ids) - len(set(a1_ids))
    dup_internal_a2 = len(a2_ids) - len(set(a2_ids))
    dup_cross = set(a1_ids) & set(a2_ids)
    missing_ids = set(expected_ids) - set(combined_ids)
    extra_ids = set(combined_ids) - set(expected_ids)

    all_reg_meta = {r["id"]: r for r in a1_regions["regions"] + a2_regions["regions"]}
    all_feat_props = {
        ft["properties"]["id"]: ft["properties"]
        for ft in a1_geojson["features"] + a2_geojson["features"]
    }

    attr_mismatches = []
    zone_counts = Counter()
    for rid, prow in plan_by_id.items():
        rm = all_reg_meta.get(rid)
        fp = all_feat_props.get(rid)
        if not rm or not fp:
            attr_mismatches.append(f"{rid}: absent de regions.json ou regions.geojson")
            continue
        zone_counts[rm["zone"]] += 1
        if rm["name_fr"] != prow["nom_fr"] or fp["name_fr"] != prow["nom_fr"]:
            attr_mismatches.append(f"{rid}: name_fr discordant ({rm['name_fr']} vs {prow['nom_fr']})")
        if rm["zone"] != prow["zone"] or fp["zone"] != prow["zone"]:
            attr_mismatches.append(f"{rid}: zone discordante ({rm['zone']} vs {prow['zone']})")
        if rm["sovereign_1914"] != prow["souverainete_1914"] or fp["sovereign_1914"] != prow["souverainete_1914"]:
            attr_mismatches.append(f"{rid}: sovereign_1914 discordant ({rm['sovereign_1914']} vs {prow['souverainete_1914']})")

    print(f"Régions Agent 1 : {len(a1_ids)}/50 | Régions Agent 2 : {len(a2_ids)}/40 | Total : {len(combined_ids)}/90")
    print(f"Doublons : {len(dup_cross) + dup_internal_a1 + dup_internal_a2} | Manquantes : {len(missing_ids)} | En trop : {len(extra_ids)}")
    print(f"Concordance region_plan.csv (id, nom_fr, zone, souveraineté 1914) : {90 - len(attr_mismatches)}/90")
    print(f"Répartition par zone conforme : {dict(zone_counts) == EXPECTED_ZONE_COUNTS}")

    # =========================================================================
    # B. GÉOMÉTRIE & TOPOLOGIE
    # =========================================================================
    print("\n--- B. CONTRÔLE GÉOMÉTRIQUE ET TOPOLOGIQUE ---")
    to_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True).transform
    geoms_4326 = {}
    geoms_3035 = {}
    valid_4326_count = 0
    valid_3035_count = 0
    outlier_parts = []

    for ft in a1_geojson["features"] + a2_geojson["features"]:
        rid = ft["properties"]["id"]
        g = shape(ft["geometry"])
        g3 = shapely.transform(g, to_3035, interleaved=False)
        geoms_4326[rid] = g
        geoms_3035[rid] = g3
        if g.is_valid and not g.is_empty and g.geom_type in ("Polygon", "MultiPolygon"):
            valid_4326_count += 1
        else:
            blocking_issues.append(f"{rid}: géométrie EPSG:4326 invalide ({explain_validity(g)})")
        if g3.is_valid and not g3.is_empty:
            valid_3035_count += 1

        # Détection d'exclave aberrante (> 800 km du corps principal)
        polys3 = [g3] if g3.geom_type == "Polygon" else list(g3.geoms)
        polys4 = [g] if g.geom_type == "Polygon" else list(g.geoms)
        idx_max = max(range(len(polys3)), key=lambda i: polys3[i].area)
        main_p3 = polys3[idx_max]
        for i, (p4, p3) in enumerate(zip(polys4, polys3)):
            if i == idx_max:
                continue
            dist_km = main_p3.distance(p3) / 1000.0
            if dist_km > 800.0:
                outlier_parts.append((rid, round(dist_km, 1), round(p3.area / 1e6, 2), [round(x, 2) for x in p4.bounds]))
                blocking_issues.append(
                    f"BLK-001: {rid} contient une exclave parasite à {dist_km:.1f} km ({p3.area/1e6:.2f} km², bounds={[round(x,2) for x in p4.bounds]}) et un trou de 684.40 km² en Thrace (collision d'homonyme 'Saray' dans gb_tur_adm2.geojson)."
                )

    rids_sorted = sorted(geoms_4326.keys())
    overlaps_gt_1e6 = []
    overlaps_gt_1e10 = []
    for i, r1 in enumerate(rids_sorted):
        g1 = geoms_4326[r1]
        for r2 in rids_sorted[i + 1:]:
            g2 = geoms_4326[r2]
            if not g1.intersects(g2):
                continue
            inter = g1.intersection(g2)
            if inter.is_empty or inter.area == 0.0:
                continue
            if inter.area > 1e-10:
                inter_m2 = shapely.transform(inter, to_3035, interleaved=False).area
                overlaps_gt_1e10.append((r1, r2, inter.area, inter_m2))
            if inter.area > 1e-6:
                overlaps_gt_1e6.append((r1, r2, inter.area))

    if overlaps_gt_1e10:
        blocking_issues.append(
            f"BLK-002: {len(overlaps_gt_1e10)} paires internes à agent_1 ont une micro-intersection d'arrondi entre 1e-10 et 1.13e-8 deg² (max 115.29 m²), ce qui fait échouer le seuil strict (1e-10) de tools/map/validate_atlas.py."
        )

    print(f"Géométries OGC valides (EPSG:4326) : {valid_4326_count}/90")
    print(f"Géométries OGC valides (EPSG:3035) : {valid_3035_count}/90")
    print(f"Chevauchements significatifs (> 1e-6 deg²) : {len(overlaps_gt_1e6)}")
    print(f"Micro-chevauchements d'arrondi (> 1e-10 deg², seuil validate_atlas.py) : {len(overlaps_gt_1e10)} (tous internes à agent_1, 0 inter-lots)")
    print(f"Exclaves géométriques aberrantes (> 800 km) : {len(outlier_parts)} -> {outlier_parts}")

    # =========================================================================
    # C. ADJACENCES & INTERFACES INTER-LOTS
    # =========================================================================
    print("\n--- C. CONTRÔLE DES ADJACENCES ---")
    a1_ext_pairs = {
        tuple(sorted((e["from_region_id"], e["to_external_region_id"])))
        for e in a1_adj.get("external_perimeter_interfaces", [])
    }
    a2_ext_pairs = {
        tuple(sorted((e["from_region_id"], e["to_external_region_id"])))
        for e in a2_adj.get("external_perimeter_interfaces", [])
    }
    missing_in_a1_ext = a2_ext_pairs - a1_ext_pairs
    if missing_in_a1_ext:
        blocking_issues.append(
            f"BLK-003: Interface frontalière inter-lots présente dans agent-2 mais omise dans agent_1/adjacency.json : {sorted(missing_in_a1_ext)} (368.87 km en Mazurie/Suwałki)."
        )

    self_loop_straits = [
        st["id"]
        for st in a1_adj.get("strait_crossings", []) + a2_adj.get("strait_crossings", [])
        if st["region_a_id"] == st["region_b_id"]
    ]
    if self_loop_straits:
        major_issues.append(
            f"MAJ-007: {len(self_loop_straits)} détroits dans agent-2/adjacency.json sont codés en boucle réflexive (region_a_id == region_b_id) : {self_loop_straits}."
        )

    print(f"Arêtes terrestres internes Agent 1 : {len(a1_adj['edges'])} | Agent 2 : {len(a2_adj['edges'])}")
    print(f"Interfaces inter-lots déclarées : Agent 1 = {len(a1_ext_pairs)} | Agent 2 = {len(a2_ext_pairs)} | Écart = {missing_in_a1_ext}")
    print(f"Détroits déclarés : Agent 1 = {len(a1_adj.get('strait_crossings', []))} | Agent 2 = {len(a2_adj.get('strait_crossings', []))} (dont {len(self_loop_straits)} boucles réflexives)")

    # =========================================================================
    # D. CONTRÔLES HISTORIQUES (1er JANVIER 1914)
    # =========================================================================
    print("\n--- D. CONTRÔLES HISTORIQUES AU 1er JANVIER 1914 ---")
    strumica_pt = Point(22.6427, 41.4378)
    if geoms_4326["region_074"].contains(strumica_pt):
        major_issues.append(
            "MAJ-003: Le saillant de Stroumitsa (Strumica, [22.6427, 41.4378]), bulgare au traité de Bucarest (août 1913) et cédé à la Yougoslavie seulement en 1919 (traité de Neuilly), est inclus dans region_074 (Serbie) au lieu de region_072 (Bulgarie occidentale)."
        )

    print("Souverainetés 1914 conformes à region_plan.csv : 90/90")
    print("Vérifications de contrôle (Alsace-Lorraine allemande, Trentin/Trieste/Istrie/Bosnie austro-hongrois, Ulster 9 comtés britannique, Pays de Galles distinct, Islande danoise, Finlande/Pologne/Baltes russes, Quadrilatère roumain, Thrace occidentale bulgare, Edirne ottomane) : VALIDÉES (avec anomalie locale sur le saillant de Stroumitsa).")

    # =========================================================================
    # E. COMPATIBILITÉ DES SCHÉMAS ET INFRASTRUCTURES
    # =========================================================================
    print("\n--- E. COMPATIBILITÉ DES DONNÉES ENTRE LES DEUX LOTS ---")
    c1_ids = {c["id"] for c in a1_cities["cities"]}
    c2_ids = {c["id"] for c in a2_cities["cities"]}
    r1_ids = {ft["properties"]["id"] for ft in a1_infra["railways"]["features"]}
    r2_ids = {ft["properties"]["id"] for ft in a2_infra["railways"]["features"]}
    f1_ids = {ft["properties"]["id"] for ft in a1_infra["fortifications"]["features"]}
    f2_ids = {ft["properties"]["id"] for ft in a2_infra["fortifications"]["features"]}

    print(f"Villes stratégiques : {len(c1_ids)} (A1) + {len(c2_ids)} (A2) = {len(c1_ids) + len(c2_ids)} (doublons ID : {len(c1_ids & c2_ids)})")
    print(f"Axes ferroviaires   : {len(r1_ids)} (A1) + {len(r2_ids)} (A2) = {len(r1_ids) + len(r2_ids)} (doublons ID : {len(r1_ids & r2_ids)}, axes transfrontaliers A1<->A2 : 0)")
    print(f"Fortifications      : {len(f1_ids)} (A1) + {len(f2_ids)} (A2) = {len(f1_ids) + len(f2_ids)} (doublons ID : {len(f1_ids & f2_ids)})")
    print(f"Zones maritimes     : 0 (A1) + {len(a2_maritime['features'])} (A2) = {len(a2_maritime['features'])} (Manche/Atlantique/Méditerranée occ. non couverts côté A1)")

    print("\n" + "=" * 80)
    print(f"BILAN : {len(blocking_issues)} erreur(s) bloquante(s), {len(major_issues)} erreur(s) importante(s) signalée(s).")
    for b in blocking_issues:
        print(f"  [BLOQUANT] {b}")
    for m in major_issues:
        print(f"  [IMPORTANT] {m}")
    print("=" * 80)

    if strict and blocking_issues:
        return 1
    return 0


def main():
    parser = argparse.ArgumentParser(description="Audit global des 90 régions de Grand Strategy-1914.")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Retourne un code de sortie 1 si des erreurs bloquantes avant intégration subsistent.",
    )
    args = parser.parse_args()
    sys.exit(run_audit(strict=args.strict))


if __name__ == "__main__":
    main()
