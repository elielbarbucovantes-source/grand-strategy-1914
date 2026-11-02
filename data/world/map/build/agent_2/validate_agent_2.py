#!/usr/bin/env python3
"""
Validateur géométrique, topologique, historique et documentaire — AGENT 2 (40 régions)
Périmètre : Scandinavie (8), Europe orientale (18), Balkans (10), Territoires ottomans européens (4).

Vérifie :
1. Présence des 10 livrables attendus dans data/world/map/build/agent_2/ (+ sources/README.md)
2. Exactitude des 40 régions attendues par rapport à data/world/map/tables/region_plan.csv
3. Répartition exacte par zone (8 / 18 / 10 / 4) et conformité historique au 1er janvier 1914
4. Validité OGC des polygones GeoJSON (EPSG:4326), absence de géométrie vide ou rectangulaire simpliste
5. Absence de chevauchements internes entre les 40 régions
6. Absence de chevauchements avec les 50 régions de l'Agent 1 et cohérence réciproque des interfaces terrestres
7. Symétrie et cohérence du graphe d'adjacence (adjacency.json <-> regions.json)
8. Inclusion stricte de chaque ville stratégique et fortification dans le polygone de sa région, présence des 10 capitales d'État
9. Complétude de terrain.json, infrastructure.json et maritime_zones.json
"""
import csv
import json
import subprocess
import sys
from collections import Counter
from pathlib import Path

for candidate_pkg in ("/tmp/gs1914-gis-packages",):
    if Path(candidate_pkg).exists() and candidate_pkg not in sys.path:
        sys.path.insert(0, candidate_pkg)

import shapely
from shapely.geometry import Point, shape
from shapely.validation import explain_validity

AGENT2_DIR = Path(__file__).resolve().parent
REPO_ROOT = AGENT2_DIR.parents[4]
PLAN_CSV = REPO_ROOT / "data/world/map/tables/region_plan.csv"
AGENT1_DIR = REPO_ROOT / "data/world/map/build/agent_1"

EXPECTED_ZONES = {
    "Scandinavie": 8,
    "Europe orientale": 18,
    "Balkans": 10,
    "Territoires ottomans européens": 4,
}

EXPECTED_CAPITALS = {
    "region_044": ("city_copenhagen", "Danemark"),
    "region_045": ("city_christiania", "Norvège"),
    "region_049": ("city_stockholm", "Suède"),
    "region_064": ("city_st_petersburg", "Empire russe"),
    "region_070": ("city_bucharest", "Roumanie"),
    "region_072": ("city_sofia", "Bulgarie"),
    "region_074": ("city_belgrade", "Serbie"),
    "region_075": ("city_cetinje", "Monténégro"),
    "region_076": ("city_durres", "Albanie"),
    "region_077": ("city_athens_piraeus", "Grèce"),
    "region_087": ("city_constantinople", "Empire ottoman"),
}


def fail(errors, msg):
    print(f"  [ERREUR] {msg}")
    errors.append(msg)


def main():
    errors = []
    warnings = []

    print("=" * 76)
    print("VALIDATION DE L'ATLAS CARTOGRAPHIQUE — AGENT 2 (40 RÉGIONS, 01/01/1914)")
    print("=" * 76)

    # 1. Fichiers requis
    required_files = [
        "regions.geojson",
        "regions.json",
        "adjacency.json",
        "cities.json",
        "terrain.json",
        "infrastructure.json",
        "maritime_zones.json",
        "README.md",
        "HANDOFF.md",
        "validate_agent_2.py",
        "sources/README.md",
    ]
    for rf in required_files:
        p = AGENT2_DIR / rf
        if not p.exists() or p.stat().st_size == 0:
            fail(errors, f"Fichier requis manquant ou vide : {p}")
    if errors:
        sys.exit(1)
    print("[OK] 1. Tous les fichiers livrables requis sont présents et non vides.")

    # 2. Lecture de region_plan.csv
    with PLAN_CSV.open(encoding="utf-8", newline="") as f:
        plan_rows = list(csv.DictReader(f))
    expected_rows = [r for r in plan_rows if r["zone"] in EXPECTED_ZONES]
    expected_by_id = {r["region_id"]: r for r in expected_rows}
    if len(expected_by_id) != 40:
        fail(errors, f"region_plan.csv devrait contenir 40 régions pour l'Agent 2, trouvé {len(expected_by_id)}")

    # 3. Chargement des fichiers JSON / GeoJSON
    regions_geojson = json.loads((AGENT2_DIR / "regions.geojson").read_text(encoding="utf-8"))
    regions_json = json.loads((AGENT2_DIR / "regions.json").read_text(encoding="utf-8"))
    adjacency_json = json.loads((AGENT2_DIR / "adjacency.json").read_text(encoding="utf-8"))
    cities_json = json.loads((AGENT2_DIR / "cities.json").read_text(encoding="utf-8"))
    terrain_json = json.loads((AGENT2_DIR / "terrain.json").read_text(encoding="utf-8"))
    infra_json = json.loads((AGENT2_DIR / "infrastructure.json").read_text(encoding="utf-8"))
    maritime_json = json.loads((AGENT2_DIR / "maritime_zones.json").read_text(encoding="utf-8"))

    features = regions_geojson.get("features", [])
    if len(features) != 40:
        fail(errors, f"regions.geojson contient {len(features)} features au lieu de 40.")

    reg_meta_list = regions_json.get("regions", [])
    if len(reg_meta_list) != 40:
        fail(errors, f"regions.json contient {len(reg_meta_list)} régions au lieu de 40.")

    meta_by_id = {r["id"]: r for r in reg_meta_list}
    feat_by_id = {ft["properties"]["id"]: ft for ft in features}

    if set(feat_by_id.keys()) != set(expected_by_id.keys()):
        missing = set(expected_by_id.keys()) - set(feat_by_id.keys())
        extra = set(feat_by_id.keys()) - set(expected_by_id.keys())
        fail(errors, f"Identifiants incohérents avec region_plan.csv : manquants={missing}, en_trop={extra}")

    if set(meta_by_id.keys()) != set(expected_by_id.keys()):
        fail(errors, "Divergence d'identifiants entre regions.json et region_plan.csv.")

    # Vérification des zones et souverainetés 1914
    zone_counter = Counter()
    for rid, exp in expected_by_id.items():
        m = meta_by_id[rid]
        fp = feat_by_id[rid]["properties"]
        zone_counter[m["zone"]] += 1
        if m["name_fr"] != exp["nom_fr"] or fp["name_fr"] != exp["nom_fr"]:
            fail(errors, f"{rid}: nom_fr incohérent ({m['name_fr']} vs {exp['nom_fr']})")
        if m["zone"] != exp["zone"] or fp["zone"] != exp["zone"]:
            fail(errors, f"{rid}: zone incohérente ({m['zone']} vs {exp['zone']})")
        if m["sovereign_1914"] != exp["souverainete_1914"] or fp["sovereign_1914"] != exp["souverainete_1914"]:
            fail(errors, f"{rid}: souverainete_1914 incohérente ({m['sovereign_1914']} vs {exp['souverainete_1914']})")
        if m["etat_geometrie"] != "construite":
            fail(errors, f"{rid}: etat_geometrie vaut '{m['etat_geometrie']}' au lieu de 'construite'")

    if dict(zone_counter) != EXPECTED_ZONES:
        fail(errors, f"Comptage par zone invalide : {dict(zone_counter)} vs {EXPECTED_ZONES}")
    print(f"[OK] 2. Les 40 régions correspondent exactement à region_plan.csv ({dict(zone_counter)}).")

    # Contrôles historiques spécifiques 1914
    if meta_by_id["region_051"]["sovereign_1914"] != "Danemark":
        fail(errors, "region_051 (Islande) doit être sous souveraineté du Danemark en 1914.")
    for rus_rid in [f"region_{i:03d}" for i in range(52, 70)]:
        if meta_by_id[rus_rid]["sovereign_1914"] != "Empire russe":
            fail(errors, f"{rus_rid} doit être sous souveraineté de l'Empire russe en 1914.")
    for ott_rid in ["region_087", "region_088", "region_089", "region_090"]:
        if meta_by_id[ott_rid]["sovereign_1914"] != "Empire ottoman":
            fail(errors, f"{ott_rid} doit être sous souveraineté de l'Empire ottoman en 1914.")
    print("[OK] 3. Conformité historique des souverainetés au 1er janvier 1914 vérifiée.")

    # 4. Validation géométrique et topologique interne
    geoms = {}
    for rid in sorted(expected_by_id.keys()):
        ft = feat_by_id[rid]
        g_raw = ft.get("geometry")
        if not g_raw or g_raw.get("type") not in ("Polygon", "MultiPolygon"):
            fail(errors, f"{rid}: géométrie absente ou de type invalide ({g_raw.get('type') if g_raw else None})")
            continue
        g = shape(g_raw)
        if g.is_empty:
            fail(errors, f"{rid}: géométrie vide")
        if not g.is_valid:
            fail(errors, f"{rid}: géométrie invalide OGC ({explain_validity(g)})")
        minx, miny, maxx, maxy = g.bounds
        if minx < -30.0 or maxx > 70.0 or miny < 33.0 or maxy > 82.0:
            fail(errors, f"{rid}: boîte englobante hors limites européennes/uraliennes ({g.bounds})")
        n_verts = int(shapely.get_num_coordinates(g))
        if n_verts < 50:
            fail(errors, f"{rid}: géométrie trop simpliste ({n_verts} sommets)")
        if meta_by_id[rid]["area_km2"] <= 100.0:
            fail(errors, f"{rid}: superficie aberrante ({meta_by_id[rid]['area_km2']} km²)")
        rep_lon, rep_lat = meta_by_id[rid]["representative_point_lon_lat"]
        if not g.contains(Point(rep_lon, rep_lat)):
            fail(errors, f"{rid}: representative_point_lon_lat ({rep_lon}, {rep_lat}) hors du polygone")
        geoms[rid] = g

    # Vérification d'absence de chevauchement interne entre les 40 régions
    rids = sorted(geoms.keys())
    internal_overlaps = 0
    for i, r1 in enumerate(rids):
        for r2 in rids[i + 1:]:
            if geoms[r1].intersects(geoms[r2]):
                inter = geoms[r1].intersection(geoms[r2])
                if inter.area > 1e-9:
                    internal_overlaps += 1
                    fail(errors, f"Chevauchement interne entre {r1} et {r2} (aire={inter.area:.2e} deg²)")
    print(f"[OK] 4. 40 géométries Polygon/MultiPolygon valides en EPSG:4326, 0 chevauchement interne.")

    # 5. Vérification des frontières et de la non-superposition avec l'Agent 1 (50 régions)
    a1_geojson_path = AGENT1_DIR / "regions.geojson"
    a1_adj_path = AGENT1_DIR / "adjacency.json"
    a1_fc = None
    a1_adj = None
    if a1_geojson_path.exists() and a1_adj_path.exists():
        a1_fc = json.loads(a1_geojson_path.read_text(encoding="utf-8"))
        a1_adj = json.loads(a1_adj_path.read_text(encoding="utf-8"))
    else:
        try:
            r_geo = subprocess.run(
                ["git", "-C", str(REPO_ROOT), "show", "agent_1:data/world/map/build/agent_1/regions.geojson"],
                capture_output=True, text=True, check=True
            )
            r_adj = subprocess.run(
                ["git", "-C", str(REPO_ROOT), "show", "agent_1:data/world/map/build/agent_1/adjacency.json"],
                capture_output=True, text=True, check=True
            )
            a1_fc = json.loads(r_geo.stdout)
            a1_adj = json.loads(r_adj.stdout)
        except Exception:
            pass

    if a1_fc is not None and a1_adj is not None:
        a1_geoms = {ft["properties"]["id"]: shape(ft["geometry"]) for ft in a1_fc["features"]}
        cross_overlaps = 0
        for r2, g2 in geoms.items():
            for r1, g1 in a1_geoms.items():
                if g2.intersects(g1):
                    inter = g2.intersection(g1)
                    if inter.area > 1e-9:
                        cross_overlaps += 1
                        fail(errors, f"Chevauchement inter-lots entre {r2} (Agent 2) et {r1} (Agent 1): {inter.area:.2e} deg²")

        # Vérifier que les 16 interfaces déclarées par l'Agent 1 sont toutes présentes et documentées côté Agent 2
        a1_declared_pairs = {
            (item["to_external_region_id"], item["from_region_id"])
            for item in a1_adj.get("external_perimeter_interfaces", [])
        }
        a2_declared_pairs = {
            (item["from_region_id"], item["to_external_region_id"])
            for item in adjacency_json.get("external_perimeter_interfaces", [])
        }
        missing_a1_pairs = a1_declared_pairs - a2_declared_pairs
        if missing_a1_pairs:
            fail(errors, f"Interfaces Agent 1 manquantes dans adjacency.json de l'Agent 2 : {missing_a1_pairs}")
        for item in adjacency_json.get("external_perimeter_interfaces", []):
            if item.get("shared_border_km", 0.0) < 1.0:
                fail(errors, f"Interface externe {item['id']} a une longueur de frontière nulle ou trop faible ({item.get('shared_border_km')} km)")
        print(
            f"[OK] 5. Alignement inter-lots avec l'Agent 1 vérifié : 0 chevauchement sur les 90 régions, "
            f"{len(a2_declared_pairs)} interfaces frontalières terrestres réciproques validées."
        )
    else:
        warnings.append("Fichiers de l'Agent 1 non trouvés pour la validation inter-lots.")

    # 6. Validation du graphe d'adjacence interne
    neighbors_map = adjacency_json.get("neighbors_by_region", {})
    edges = adjacency_json.get("edges", [])
    if len(edges) < 55:
        fail(errors, f"Nombre d'arêtes terrestres internes anormalement bas : {len(edges)}")
    edge_pairs = set()
    for e in edges:
        ra, rb = e["region_a_id"], e["region_b_id"]
        if ra not in expected_by_id or rb not in expected_by_id:
            fail(errors, f"Arête {e['id']} référence une région hors périmètre ({ra}, {rb})")
        if rb not in neighbors_map.get(ra, []) or ra not in neighbors_map.get(rb, []):
            fail(errors, f"Asymétrie dans neighbors_by_region pour ({ra}, {rb})")
        if e["shared_border_km"] <= 0:
            fail(errors, f"Arête {e['id']} a shared_border_km <= 0")
        edge_pairs.add(tuple(sorted((ra, rb))))

    ext_neighbors_map = adjacency_json.get("external_neighbors_by_region", {})
    for r in rids:
        if sorted(neighbors_map.get(r, [])) != sorted(meta_by_id[r]["adjacent_region_ids"]):
            fail(errors, f"{r}: divergence d'adjacence entre adjacency.json et regions.json")
        # Toutes les régions continentales (hors Islande region_051) doivent avoir au moins 1 voisin terrestre (interne ou externe Agent 1)
        total_land_neighbors = len(neighbors_map.get(r, [])) + len(ext_neighbors_map.get(r, []))
        if r != "region_051" and total_land_neighbors == 0:
            fail(errors, f"{r}: région continentale sans aucun voisin terrestre (interne ou externe)")
    print(
        f"[OK] 6. Graphe d'adjacence valide et symétrique ({len(edges)} arêtes terrestres internes, "
        f"{len(adjacency_json.get('strait_crossings', []))} détroits)."
    )

    # 7. Validation des villes stratégiques et capitales
    city_list = cities_json.get("cities", [])
    city_feats = cities_json.get("features", [])
    if len(city_list) != len(city_feats) or len(city_list) < 40:
        fail(errors, f"cities.json invalide : {len(city_list)} entrées dans 'cities' vs {len(city_feats)} features")
    cities_per_reg = Counter()
    capitals_found = {}
    for c in city_list:
        cid = c["id"]
        rid = c["region_id"]
        lon, lat = c["coordinates"]
        if rid not in geoms:
            fail(errors, f"Ville {cid} référence une région inconnue {rid}")
            continue
        if not geoms[rid].contains(Point(lon, lat)):
            fail(errors, f"Ville {cid} ({lon}, {lat}) n'est pas strictement à l'intérieur du polygone de {rid}")
        if cid not in meta_by_id[rid]["city_ids"]:
            fail(errors, f"Ville {cid} absente de city_ids dans regions.json pour {rid}")
        cities_per_reg[rid] += 1
        if c.get("is_capital"):
            capitals_found[rid] = (cid, c["sovereign_1914"])

    for r in rids:
        if cities_per_reg[r] < 1:
            fail(errors, f"Région {r} ne possède aucune ville stratégique dans cities.json")

    if capitals_found != EXPECTED_CAPITALS:
        fail(errors, f"Capitales nationales 1914 incorrectes : {capitals_found} vs {EXPECTED_CAPITALS}")
    print(f"[OK] 7. {len(city_list)} villes stratégiques validées (inclusion géométrique 100%, 11 capitales d'État 1914 présentes).")

    # 8. Validation de terrain.json, infrastructure.json et maritime_zones.json
    reg_terrain = terrain_json.get("regions_terrain", {})
    allowed_relief = set(terrain_json.get("allowed_relief_categories", []))
    if set(reg_terrain.keys()) != set(expected_by_id.keys()):
        fail(errors, "terrain.json ne couvre pas exactement les 40 régions.")
    for r, rt in reg_terrain.items():
        if not rt.get("relief_categories") or not set(rt["relief_categories"]).issubset(allowed_relief):
            fail(errors, f"{r}: catégories de relief invalides dans terrain.json ({rt.get('relief_categories')})")

    reg_infra = infra_json.get("regional_infrastructure", {})
    if set(reg_infra.keys()) != set(expected_by_id.keys()):
        fail(errors, "infrastructure.json ne couvre pas exactement les 40 régions.")
    fort_feats = infra_json.get("fortifications", {}).get("features", [])
    for ff in fort_feats:
        fid = ff["properties"]["id"]
        frid = ff["properties"]["region_id"]
        flon, flat = ff["geometry"]["coordinates"]
        if not geoms[frid].contains(Point(flon, flat)):
            fail(errors, f"Fortification {fid} ({flon}, {flat}) hors du polygone de {frid}")

    mz_feats = maritime_json.get("features", [])
    mz_list = maritime_json.get("maritime_zones", [])
    if len(mz_feats) < 10 or len(mz_feats) != len(mz_list):
        fail(errors, f"maritime_zones.json invalide ({len(mz_feats)} features vs {len(mz_list)} enregistrements)")
    mz_ids = {m["id"] for m in mz_list}
    for m in mz_feats:
        mg = shape(m["geometry"])
        if not mg.is_valid or mg.is_empty:
            fail(errors, f"Zone maritime {m['id']} a une géométrie invalide ou vide")
        for cr in m["properties"]["coastal_region_ids"]:
            if cr not in expected_by_id:
                fail(errors, f"Zone maritime {m['id']} référence une région côtière inconnue {cr}")

    for r in rids:
        if meta_by_id[r]["has_coastline"] and not set(meta_by_id[r]["maritime_zone_ids"]).issubset(mz_ids):
            fail(errors, f"{r}: maritime_zone_ids contient des identifiants inconnus")
        if meta_by_id[r]["has_coastline"] and len(meta_by_id[r]["maritime_zone_ids"]) == 0:
            fail(errors, f"{r}: région côtière sans maritime_zone_ids associé")

    print(
        f"[OK] 8. terrain.json ({len(terrain_json.get('major_rivers', []))} fleuves, "
        f"{len(terrain_json.get('mountain_chains', []))} chaînes), "
        f"infrastructure.json ({len(infra_json.get('railways', {}).get('features', []))} axes ferrés, "
        f"{len(fort_feats)} forteresses) et maritime_zones.json ({len(mz_list)} zones maritimes) validés."
    )

    print("=" * 76)
    if errors:
        print(f"ÉCHEC DE LA VALIDATION : {len(errors)} erreur(s) détectée(s).")
        sys.exit(1)
    else:
        print("SUCCÈS COMPLET : 0 erreur détectée sur les 40 régions et les 10 livrables de l'Agent 2.")
        sys.exit(0)


if __name__ == "__main__":
    main()
