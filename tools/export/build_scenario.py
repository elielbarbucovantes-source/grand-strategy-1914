#!/usr/bin/env python3
"""Génère le scénario de campagne 1914 (data/scenarios/campaign_1914.json).

Uniquement à partir de données VALIDÉES ou DOCUMENTÉES, avec leur statut :
- nations, territoires et capitales : atlas validé (regions.geojson, cities.json) ;
- puissances jouables : D-005 / PROJECT.md §4 (sept puissances) ;
- situation diplomatique de départ : docs/diplomacy/OVERVIEW.md §4 (contexte, pas script) ;
- statistiques nationales, population, ressources, industrie, effectifs : AUCUNE valeur
  sourcée n'existe encore, donc `null` avec le statut « À DÉFINIR » (NAT-01 à 03,
  ECO-01/02, MIL-01). Le moteur traite `null` comme « inconnu ».
- formations militaires : un emplacement « armée nationale » par État, à la capitale,
  **effectifs inconnus** (structure seulement, MIL-01 ouvert) ;
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
        "start": {"year": 1914, "month": None,
                  "status": "OUVERTE (R-13) : le mois de départ est choisi à la création de la partie"},
        "nation_order": order, "nations": nations, "regions": regions,
        "treaties": treaties, "wars": [], "formations": formations,
        "provenance": {
            "territories_capitals": "atlas validé (data/world/map ; voir DATA_LICENSES.md)",
            "playable_powers": "D-005, PROJECT.md §4",
            "diplomacy_start": "docs/diplomacy/OVERVIEW.md §4 (contexte, pas script)",
            "unknown_values": "null = inconnu ; aucune statistique historique n'est inventée",
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true")
    arguments = parser.parse_args()
    text = json.dumps(build(), ensure_ascii=False, indent=1) + "\n"
    if arguments.check:
        ok = OUT.exists() and OUT.read_text(encoding="utf-8") == text
        print("[PASS] scénario à jour" if ok else "[FAIL] scénario obsolète")
        return 0 if ok else 1
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding="utf-8")
    print(f"{OUT.relative_to(ROOT)} écrit")
    return 0


if __name__ == "__main__":
    sys.exit(main())
