#!/usr/bin/env python3
"""Génère le scénario de campagne 1914 (data/scenarios/campaign_1914.json).

Uniquement à partir de données VALIDÉES ou DOCUMENTÉES, avec leur statut :
- nations, territoires et capitales : atlas validé (regions.geojson, cities.json) ;
- puissances jouables : D-005 / PROJECT.md §4 (sept puissances) ;
- situation diplomatique de départ : docs/diplomacy/OVERVIEW.md §4 (contexte, pas script) ;
- statistiques nationales, population, ressources, industrie, effectifs : AUCUNE valeur
  sourcée n'existe encore, donc `null` avec le statut « À DÉFINIR » (NAT-01 à 03,
  ECO-01/02, MIL-01). Le moteur traite `null` comme « inconnu ».
- formations militaires des SEPT PUISSANCES JOUABLES : générées depuis la base historique
  data/history/military_forces_1914.json (effectif actif et réserves sourcés ; répartition par
  district de corps du temps de paix et ventilation par arme ESTIMÉES, voir
  docs/history/MIL01_METHODE.md) avec les paramètres techniques de data/rules/forces_rules.json ;
- autres États : un emplacement « armée nationale » à la capitale, **effectifs inconnus**
  (hors du périmètre MIL-01, qui ne couvre que les puissances jouables) ;
- couleurs : paramètre de PRÉSENTATION, personnalisable (pas une donnée historique).

Usage : python3 tools/export/build_scenario.py [--check]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORLD = ROOT / "data/game/world_map.json"
OUT = ROOT / "data/scenarios/campaign_1914.json"
FORCES_DB = ROOT / "data/history/military_forces_1914.json"
FORCES_RULES = ROOT / "data/rules/forces_rules.json"
PLAYABLE = ["german_empire", "united_kingdom", "france", "russian_empire", "austria_hungary", "italy", "ottoman_empire"]
STATS = ["population_totale", "puissance_demographique", "industrie", "economie", "ressources_naturelles",
         "armee_de_terre", "marine", "technologie", "infrastructures", "diplomatie", "prestige_international",
         "unite_nationale"]
# Palette de présentation (personnalisable dans l'interface ; aucune valeur de jeu).
COLORS = {
    "german_empire": "#5b6770", "united_kingdom": "#c0392b", "france": "#2e5fa8", "russian_empire": "#3b7d4f",
    "austria_hungary": "#d4b13a", "italy": "#5aa36b", "ottoman_empire": "#8e5a3c", "belgium": "#e0c25c",
    "netherlands": "#e08a3c", "switzerland": "#b5505a", "luxembourg": "#8fa3c8", "portugal": "#4f8a6e",
    "spain": "#e3b53e", "denmark": "#c76b6b", "norway": "#7aa0c4", "sweden": "#4c78b0", "romania": "#b8a14a",
    "bulgaria": "#6f9a57", "serbia": "#a35a6e", "montenegro": "#8a6fa8", "albania": "#9b4e4e", "greece": "#6aa6d6",
}


def treaty(tid, kind, members, note):
    return {"id": tid, "type": kind, "members": members, "status": "active", "signed": "avant 1914",
            "terms": None, "terms_status": "OUVERTE (DIP-02 : obligations et effets à définir)",
            "source": "docs/diplomacy/OVERVIEW.md §4", "note": note}


def build() -> dict:
    world = json.loads(WORLD.read_text(encoding="utf-8"))
    capitals = {c["sovereign_1914"]: c for c in world["cities"] if c["is_capital"]}
    nations, order = {}, []
    for region in world["regions"]:
        nid = region["initial_sovereign_id"]
        if nid not in nations:
            cap = capitals[region["sovereign_1914"]]
            nations[nid] = {
                "id": nid, "name_fr": region["sovereign_1914"], "playable": nid in PLAYABLE,
                "playable_source": "D-005 / PROJECT.md §4" if nid in PLAYABLE else None,
                "capital_city_id": cap["id"], "capital_region_id": cap["region_id"],
                "color": COLORS[nid], "color_status": "présentation, personnalisable",
                "population": {"value": None, "unit": "habitants", "status": "À DÉFINIR (NAT-02)", "source": None},
                "stats": {k: {"value": None, "status": "À DÉFINIR (NAT-01)", "source": None} for k in STATS},
                "stocks": {}, "stocks_status": "À DÉFINIR (ECO-01 ; catégories de ressources ouvertes, R-03)",
            }
            order.append(nid)
    regions = {r["id"]: {"sovereign": r["initial_sovereign_id"], "controller": r["initial_sovereign_id"],
                         "economy": {"potential": {}, "exploitation_capacity": None, "infrastructure_level": None,
                                     "status": "À DÉFINIR (ECO-02 ; modèle C validé, données à sourcer)",
                                     "source": None}}
               for r in world["regions"]}
    formations = []
    for nid in order:
        formations.append({
            "id": f"army_{nid}_1", "nation": nid, "echelon": "army", "name_fr": "Armée nationale",
            "region": nations[nid]["capital_region_id"], "parent": None,
            "soldiers": None, "equipment": None,
            "status": "EMPLACEMENT — effectifs et composition inconnus (MIL-01) ; structure seulement",
        })
    treaties = [
        treaty("t_dual_alliance", "alliance", ["german_empire", "austria_hungary"], "Alliance (contexte de 1914)."),
        treaty("t_franco_russian", "alliance", ["france", "russian_empire"], "Alliance formelle (contexte de 1914)."),
        treaty("t_entente_cordiale", "entente", ["france", "united_kingdom"],
               "Entente cordiale, sans obligation automatique d'entrée en guerre britannique."),
        treaty("t_triple_alliance", "alliance", ["german_empire", "austria_hungary", "italy"],
               "Triple Alliance ; Italie membre mais neutre au début de 1914."),
    ]
    return {
        "format": "gs1914.scenario", "format_version": 1, "id": "campaign_1914",
        "name_fr": "Campagne historique 1914",
        "atlas_reference_date": "1914-01-01",
        "start": {"year": 1914, "month": 1,
                  "status": "VALIDÉ (T-057, directeur, 15/11/2026) : la campagne historique commence en janvier 1914"},
        "nation_order": order, "nations": nations, "regions": regions,
        "treaties": treaties, "wars": [], "formations": formations,
        "provenance": {
            "territories_capitals": "atlas validé (data/world/map ; voir DATA_LICENSES.md)",
            "playable_powers": "D-005, PROJECT.md §4",
            "diplomacy_start": "docs/diplomacy/OVERVIEW.md §4 (contexte, pas script)",
            "unknown_values": "null = inconnu ; aucune statistique historique n'est inventée",
        },
    }


# ------------------------------------------------------------------ effectifs historiques (MIL-01)
def _sha256(path: Path) -> str:
    import hashlib
    return hashlib.sha256(path.read_bytes()).hexdigest()


def locate_districts(world: dict, db: dict) -> dict:
    """Région du jeu contenant le siège de chaque district (point dans polygone, EPSG:3035 km).

    Un siège peut être donné par `city_id` (ville de l'atlas) ou par lon/lat (WGS 84). Un point
    situé sur une côte simplifiée (hors de tout polygone) est rattaché à la région la plus proche
    de la même souveraineté si elle est à moins de 10 km ; sinon le district est signalé.
    """
    from pyproj import Transformer
    from shapely.geometry import MultiPolygon, Point, Polygon
    tr = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True)
    polys = {}
    for r in world["regions"]:
        parts = [Polygon(p[0], p[1:]) for p in r["polygons_km"]]
        polys[r["id"]] = (MultiPolygon(parts).buffer(0), r["initial_sovereign_id"])
    cities = {c["id"]: c for c in world["cities"]}
    out = {}
    for nid, nation in db["nations"].items():
        for d in nation["districts"]:
            if d.get("off_map"):
                out[d["id"]] = None
                continue
            if d.get("city_id"):
                out[d["id"]] = cities[d["city_id"]]["region_id"]
                continue
            x, y = tr.transform(d["lon"], d["lat"])
            pt = Point(x / 1000.0, y / 1000.0)
            hit = sorted(rid for rid, (g, _) in polys.items() if g.contains(pt))
            if not hit:
                near = sorted((g.distance(pt), rid) for rid, (g, sov) in polys.items() if sov == nid)
                if near and near[0][0] <= 10.0:
                    hit = [near[0][1]]
            if len(hit) != 1 or polys[hit[0]][1] != nid:
                raise SystemExit(f"district {d['id']} ({d['hq']}) : région introuvable ou étrangère {hit}")
            out[d["id"]] = hit[0]
    return out


def _split(total: int, weights: list) -> list:
    """Répartition entière exacte (plus forts restes, ordre stable)."""
    s = sum(weights)
    raw = [total * w / s for w in weights]
    base = [int(x) for x in raw]
    rest = total - sum(base)
    order = sorted(range(len(raw)), key=lambda i: (-(raw[i] - base[i]), i))
    for i in order[:rest]:
        base[i] += 1
    return base


def arm_shares(arms: dict | None, gen: dict) -> dict:
    """Parts infanterie / cavalerie / artillerie / services d'après la ventilation sourcée."""
    if not arms:
        return {gen["unknown_arms_fallback"]: 1.0, "services": 0.0}
    total = float(arms["total"])
    out = {}
    for kind, cols in gen["arms_to_unit_types"].items():
        out[kind] = sum(float(arms.get(c) or 0) for c in cols) / total
    out["services"] = max(0.0, 1.0 - sum(out.values()))
    return out


ALLOCATION_DEFAULT = {"administration": 34, "rail": 33, "logistics": 33}
ECHELON_STATUS_FR = {
    "documented": "Échelons dérivés de sources consultées (T-051) ; voir la base historique.",
    "bloc_unique": "APPROXIMATION NON DOCUMENTÉE HISTORIQUEMENT (décision MIL01-P1-D1) : aucun échelon sourcé, "
                   "le réservoir est appelé en bloc unique ; aucun sous-échelon n'est inventé.",
}


def territorial_block(n: dict) -> dict | None:
    """Territorial Force (T-050, T-054) : catégorie distincte du réservoir, répartie par division
    (ESTIMATION, voir la base). Absente pour les autres puissances."""
    tf = n.get("territorial_force")
    if not tf:
        return None
    counts: dict = {}
    for d in tf["distribution"]["divisions"]:
        counts[d["region_id"]] = counts.get(d["region_id"], 0) + 1
    regions = sorted(counts)
    split = dict(zip(regions, _split(int(tf["value"]), [counts[r] for r in regions])))
    return {"pool_initial": int(tf["value"]), "pool_by_region": split, "embodied_turn": None,
            "mobilizing": [], "blocked": [], "incorporated": 0, "services": 0, "overseas_volunteers": 0,
            "status_fr": "Territorial Force : catégorie DISTINCTE de l'armée régulière et des réserves (T-050) ; "
                         "service intérieur, outre-mer seulement par volontariat (T-054). Répartition ESTIMÉE par division."}


def scenario_echelons(n: dict, reserves_on_map: int, weights: dict) -> tuple[list, str]:
    """Échelons du jeu (part sur la carte), chacun réparti par région de district (plus forts restes).

    Seuls les échelons à valeur documentée sont repris ; un échelon « introuvable » (null) n'est
    jamais créé. Sans échelon documenté : un bloc unique égal au réservoir sur la carte.
    """
    share = n["reserves"]["on_map_share"]
    regions = sorted(weights)
    w = [weights[r] for r in regions]
    block = n["mobilization_echelons"]
    documented = [e for e in block["echelons"] if e["value"] is not None]
    out = []
    if documented:
        for e in documented:
            v = int(e["value"]) * int(share["numerator"]) // int(share["denominator"])
            out.append({"id": e["id"], "label_fr": e["label_fr"], "status": e["status"], "documented": True,
                        "pool_initial": v, "pool_initial_by_region": dict(zip(regions, _split(v, w))),
                        "pool_by_region": dict(zip(regions, _split(v, w))), "opened_turn": None})
        mode = "documented"
    else:
        fb = block["fallback"]
        if not fb or fb["mode"] != "bloc_unique":
            raise SystemExit(f"{n['name_fr']} : ni échelon documenté ni bloc unique déclaré")
        out.append({"id": "bloc_unique", "label_fr": "Bloc unique (approximation non documentée)", "status": "bloc_unique",
                    "documented": False, "pool_initial": reserves_on_map,
                    "pool_initial_by_region": dict(zip(regions, _split(reserves_on_map, w))),
                    "pool_by_region": dict(zip(regions, _split(reserves_on_map, w))), "opened_turn": None})
        mode = "bloc_unique"
    if sum(e["pool_initial"] for e in out) != reserves_on_map:
        raise SystemExit(f"{n['name_fr']} : la somme des échelons ({sum(e['pool_initial'] for e in out)}) "
                         f"diffère du réservoir sur la carte ({reserves_on_map})")
    return out, mode


def historical_forces(world: dict, nations: dict) -> tuple[dict, list]:
    """Forces des puissances documentées : bloc national `forces` et formations du jeu."""
    db = json.loads(FORCES_DB.read_text(encoding="utf-8"))
    gen = json.loads(FORCES_RULES.read_text(encoding="utf-8"))["unit_generation"]
    located = locate_districts(world, db)
    region_names = {r["id"]: r["name_fr"] for r in world["regions"]}
    blocks, formations = {}, []
    for nid, n in db["nations"].items():
        active = int(n["active"]["value"])
        off_map = int(n["off_map"]["value"] or 0)
        on_map = active - off_map
        reserves = int(n["reserves"]["value"])
        districts = [d for d in n["districts"] if located[d["id"]]]
        n_all = len(n["districts"])
        share = n["reserves"]["on_map_share"]  # part sur la carte, justifiée nation par nation
        reserves_on_map = reserves * int(share["numerator"]) // int(share["denominator"])
        shares = arm_shares(n.get("arms"), gen)
        per_district = _split(on_map, [1] * len(districts))
        reserve_split = _split(reserves_on_map, [1] * len(districts))
        weights: dict = {}
        services_total = 0
        armies: dict = {}
        for d, soldiers, pool in zip(districts, per_district, reserve_split):
            rid = located[d["id"]]
            weights[rid] = weights.get(rid, 0) + pool
            army_id = f"army_{nid}_{rid}"
            if army_id not in armies:
                armies[army_id] = {
                    "id": army_id, "nation": nid, "echelon": "army",
                    "name_fr": f"Forces du temps de paix — {region_names[rid]}", "region": rid, "parent": None,
                    "soldiers": None, "equipment": None, "morale": None,
                    "status": "HISTORIQUE : groupement de jeu des corps stationnés dans la région (répartition ESTIMÉE)"}
            kinds = [k for k in shares if k != "services" and shares[k] > 0]
            amounts = _split(soldiers, [shares[k] for k in kinds] + [shares["services"]])
            services = amounts[-1]
            services_total += services
            div_id = f"div_{d['id']}"
            formations.append({
                "id": div_id, "nation": nid, "echelon": "division", "name_fr": f"{d['name_fr']} — {d['hq']}",
                "region": rid, "parent": army_id, "soldiers": None, "equipment": None,
                "services_soldiers": services, "district_id": d["id"], "district_region": rid,
                "status": f"HISTORIQUE : district de corps du temps de paix (siège {d['hq_verification']}) ; effectif = part égale ESTIMÉE"})
            for kind, amount in zip(kinds, amounts[:-1]):
                if amount <= 0:
                    continue
                count = max(1, round(amount / gen["peace_unit_soldiers"]))
                for i, size in enumerate(_split(amount, [1] * count), start=1):
                    formations.append({
                        "id": f"{div_id}_{kind[:3]}{i}", "nation": nid, "echelon": "unit", "unit_type": kind,
                        "name_fr": f"{ {'infantry': 'Infanterie', 'cavalry': 'Cavalerie', 'artillery': 'Artillerie'}[kind] } {i} — {d['name_fr']}",
                        "region": rid, "parent": div_id, "soldiers": size, "establishment": size,
                        "equipment": None, "morale": None,
                        "status": ("HISTORIQUE : effectif national sourcé ; répartition ESTIMÉE"
                                   + ("" if n.get("arms") else " ; arme INCONNUE, infanterie générique (simplification)"))})
        formations.extend(armies.values())
        echelons, mode = scenario_echelons(n, reserves_on_map, weights)
        blocks[nid] = {
            "source_type": "historical", "database": "data/history/military_forces_1914.json",
            "data_status": n["data_status"],
            "active_start": active, "active_reference": f"{n['active']['source']} {n['active']['page']}",
            "active_off_map": off_map, "active_on_map": on_map, "services_active": services_total,
            "reserves_total": reserves, "reserves_off_map": reserves - reserves_on_map,
            "reserve_pool_initial": reserves_on_map, "reserve_pool": reserves_on_map,
            "mobilizing": [], "blocked": [], "incorporated": 0,
            "echelons": echelons, "echelon_mode": mode,
            "echelon_status_fr": (ECHELON_STATUS_FR[mode]),
            "posture": "paix", "allocation": dict(ALLOCATION_DEFAULT), "public_record": [],
            "territorial_force": territorial_block(n),
            "district_pool_weights": dict(sorted(weights.items())),
            "arm_shares": {k: round(v, 6) for k, v in shares.items()},
            "districts_total": n_all, "districts_on_map": len(districts),
            "status": "Effectif actif et réserves SOURCÉS (voir la base) ; répartition territoriale et ventilation par arme ESTIMÉES.",
        }
    return blocks, formations


def build_campaign(base: dict) -> dict:
    """Campagne historique : base + effectifs historiques des puissances documentées."""
    world = json.loads(WORLD.read_text(encoding="utf-8"))
    campaign = json.loads(json.dumps(base))
    blocks, formations = historical_forces(world, campaign["nations"])
    documented = sorted(blocks)
    for nid, nation in campaign["nations"].items():
        nation["forces"] = blocks.get(nid, {
            "source_type": "unknown",
            "status": "INCONNU : MIL-01 ne couvre que les sept puissances jouables ; aucune valeur n'est fabriquée."})
    campaign["formations"] = [f for f in base["formations"] if f["nation"] not in blocks] + formations
    campaign["forces_source"] = {
        "type": "historical", "database": "data/history/military_forces_1914.json",
        "database_sha256": _sha256(FORCES_DB), "rules": "data/rules/forces_rules.json",
        "rules_sha256": _sha256(FORCES_RULES),
        "nations_documented": documented,
        "nations_unknown": sorted(n for n in campaign["nations"] if n not in blocks),
        "warning": "Effectifs nationaux sourcés ; répartitions estimées (docs/history/MIL01_METHODE.md).",
    }
    campaign["provenance"]["military_forces"] = "data/history/military_forces_1914.json (MIL-01)"
    return campaign


# Bac à sable FICTIF : forces génériques identiques pour tous les États. Ni historique ni
# équilibré. Sert uniquement à jouer et à tester le système de combat tant que les effectifs
# de 1914 ne sont pas sourcés (MIL-01). Les chiffres sont des valeurs RONDES DE TEST.
SANDBOX_OUT = ROOT / "data/scenarios/sandbox_fictif.json"
SANDBOX_COMPOSITION = [  # (division, régiment, type, soldats) : FICTIF
    (1, 1, "infantry", 3000), (1, 1, "infantry", 3000), (1, 1, "artillery", 600),
    (1, 2, "cavalry", 900),
    (2, 1, "infantry", 3000), (2, 1, "infantry", 3000), (2, 1, "artillery", 600),
]


def build_sandbox(base: dict) -> dict:
    campaign = base
    scenario = json.loads(json.dumps(base))
    scenario["id"] = "sandbox_fictif"
    scenario["name_fr"] = "Bac à sable FICTIF (forces génériques de test)"
    scenario["start"] = {"year": 1914, "month": None,
                         "status": "Bac à sable : mois de départ librement configurable à la création de la partie (T-057)"}
    scenario["sandbox_warning"] = ("FORCES FICTIVES : composition identique pour tous les États, valeurs rondes de test. "
                                   "Ni historique ni équilibré. Ne pas utiliser comme donnée de jeu.")
    formations = []
    for army in campaign["formations"]:
        nid = army["nation"]
        a = dict(army)
        a["status"] = "FICTIF (bac à sable)"
        a["morale"] = None
        formations.append(a)
        divisions = {}
        for div, reg, kind, soldiers in SANDBOX_COMPOSITION:
            did = f"{a['id']}_d{div}"
            if did not in divisions:
                divisions[did] = True
                formations.append({"id": did, "nation": nid, "echelon": "division", "name_fr": f"{div}e division",
                                   "region": a["region"], "parent": a["id"], "soldiers": None, "equipment": None,
                                   "status": "FICTIF (bac à sable)"})
            rid_ = f"{did}_r{reg}"
            if not any(f["id"] == rid_ for f in formations):
                formations.append({"id": rid_, "nation": nid, "echelon": "regiment", "name_fr": f"{reg}er régiment ({div}e div.)",
                                   "region": a["region"], "parent": did, "soldiers": None, "equipment": None,
                                   "status": "FICTIF (bac à sable)"})
            index = sum(1 for f in formations if f.get("parent") == rid_) + 1
            formations.append({"id": f"{rid_}_u{index}", "nation": nid, "echelon": "unit", "unit_type": kind,
                               "name_fr": f"{kind} {div}.{reg}.{index}", "region": a["region"], "parent": rid_,
                               "soldiers": soldiers, "equipment": None, "morale": None,
                               "status": "FICTIF (bac à sable) : effectif de test"})
    scenario["formations"] = formations
    for nation in scenario["nations"].values():
        nation["forces"] = {"source_type": "fictitious",
                            "status": "FICTIF (bac à sable) : aucune réserve ni mobilisation historique."}
    scenario["forces_source"] = {"type": "fictitious", "database": None,
                                 "warning": "FORCES FICTIVES de test : ne pas utiliser comme donnée de jeu."}
    return scenario


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true")
    arguments = parser.parse_args()
    base = build()
    outputs = {OUT: json.dumps(build_campaign(base), ensure_ascii=False, indent=1) + "\n",
               SANDBOX_OUT: json.dumps(build_sandbox(base), ensure_ascii=False, indent=1) + "\n"}
    if arguments.check:
        ok = all(path.exists() and path.read_text(encoding="utf-8") == text for path, text in outputs.items())
        print("[PASS] scénarios à jour" if ok else "[FAIL] scénario(s) obsolète(s)")
        return 0 if ok else 1
    for path, text in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        print(f"{path.relative_to(ROOT)} écrit")
    return 0


if __name__ == "__main__":
    sys.exit(main())
