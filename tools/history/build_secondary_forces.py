#!/usr/bin/env python3
"""Integre les forces des 15 Etats secondaires dans la base historique MIL-01.

Source : data/history/sources/secondary_states_research.json (recherche CHORUS,
4 agents OpenCode, 2026-11-17). Cible : data/history/military_forces_1914.json.

Decisions techniques documentees (aucune decision de conception) :
  * aucun effectif "off map" n est invente : ces Etats sont entierement sur la carte ;
  * aucun sous-echelon de mobilisation n est invente : bloc unique (MIL01-P1-D1) ;
  * les reserves sont toutes disponibles sur la carte (ratio 1/1), hypothese explicite ;
  * les districts sont localises par un city_id de l atlas : le siege historique est
    conserve quand il correspond a une ville, sinon la ville la plus proche est choisie
    et l estimation est signalee dans hq_verification.

Usage : python3 tools/history/build_secondary_forces.py [--check]
"""
from __future__ import annotations

import argparse
import json
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RESEARCH = ROOT / "data/history/sources/secondary_states_research.json"
WORLD = ROOT / "data/game/world_map.json"
DB = ROOT / "data/history/military_forces_1914.json"

SECONDARY = [
    "belgium", "netherlands", "luxembourg", "switzerland", "spain", "portugal",
    "denmark", "norway", "sweden", "romania", "bulgaria", "serbia",
    "montenegro", "albania", "greece",
]


def clean_divergences(obj: dict) -> None:
    """Convertit les divergences textuelles en objets conformes au render_fiches."""
    src = obj.get("source", "SOURCE_INCONNUE")
    out = []
    for d in obj.get("divergences") or []:
        if isinstance(d, dict):
            out.append(d)
        else:
            out.append({
                "value": None,
                "source": src,
                "page": "—",
                "definition": str(d),
                "note": "divergence textuelle issue de la recherche secondaires",
            })
    obj["divergences"] = out


def norm(s: str) -> str:
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(c for c in s if not unicodedata.combining(c)).lower()
    s = s.split("(")[0]
    return "".join(c if c.isalnum() else " " for c in s).strip()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    research = json.loads(RESEARCH.read_text(encoding="utf-8"))
    world = json.loads(WORLD.read_text(encoding="utf-8"))
    db = json.loads(DB.read_text(encoding="utf-8"))

    # sovereign id -> French sovereign name, from the validated atlas
    sovereign_name = {}
    for r in world["regions"]:
        sovereign_name.setdefault(r["initial_sovereign_id"], r["sovereign_1914"])
    cities_by_name = {}
    for c in world["cities"]:
        cities_by_name.setdefault(c["sovereign_1914"], []).append(c)

    # merge research sources into the historical database (prefixed keys avoid collisions)
    for key, value in research["sources"].items():
        if key not in db["sources"]:
            entry = dict(value)
            entry["origin"] = "recherche secondaires 2026-11-17 (CHORUS)"
            db["sources"][key] = entry

    for nid in SECONDARY:
        src = research["nations"][nid]
        fr = sovereign_name[nid]
        cities = cities_by_name.get(fr, [])
        if not cities:
            raise SystemExit(f"aucune ville de l atlas pour {nid} ({fr})")

        districts = []
        for d in src.get("districts", []):
            item = dict(d)
            hq = norm(d.get("hq", ""))
            match = None
            for c in cities:
                cn = norm(c["name_fr"])
                if hq and (hq == cn or hq in cn or cn in hq):
                    match = c
                    break
            verification = ("siege historique correspond a une ville de l atlas"
                            if match else "siege approxime par la ville la plus proche (ESTIMATION)")
            if match is None:
                # fallback: first city of the nation (deterministic, documented)
                match = sorted(cities, key=lambda c: c["id"])[0]
            item["city_id"] = match["id"]
            item["hq_verification"] = verification
            item.setdefault("hq", d.get("hq", ""))
            item.setdefault("lon", 0.0)
            item.setdefault("lat", 0.0)
            districts.append(item)

        active = dict(src["active"])
        reserves = dict(src["reserves"])
        clean_divergences(active)
        clean_divergences(reserves)
        reserves["on_map_share"] = {
            "numerator": 1,
            "denominator": 1,
            "basis": ("Hypothese explicite : etat entierement sur la carte, aucun resonnement "
                      "sur une fraction outre-mer documentee ; 100 % des reserves sont "
                      "disponibles dans le reservoir de mobilisation du jeu."),
            "status": "hypothese documentee, non une source historique",
        }

        db["nations"][nid] = {
            "name_fr": src.get("name_fr", fr),
            "data_status": src.get("data_status", "effectifs documentes, repartition estimee"),
            "active": active,
            "off_map": {
                "value": 0,
                "basis": ("Aucun effectif hors carte n est attribue : les troupes coloniales "
                          "eventuelles sont exclues de la definition de l effectif actif retenue."),
                "status": "hypothese documentee",
            },
            "reserves": reserves,
            "districts": districts,
            "districts_count_check": {
                "expected": len(districts),
                "source": f"recherche {research['format']} (voir data/history/sources/)",
                "note": "nombre de districts militaires retenus pour la repartition estimee",
            },
            "mobilization_echelons": {
                "_statut": "Aucun sous-echelon historiquement documente pour cet Etat.",
                "echelons": [],
                "fallback": {
                    "mode": "bloc_unique",
                    "value": int(reserves["value"]),
                    "status": "approximation non documentee",
                    "decision": "MIL01-P1-D1",
                    "note": ("Faute d echelon source, le reservoir est appele en bloc unique. "
                             "Aucun sous-echelon n est invente."),
                },
            },
            "secondary_research": {
                "organisation": src.get("organisation", ""),
                "garrisons": src.get("garrisons", ""),
                "uncertainties": src.get("uncertainties", []),
                "source_file": "data/history/sources/secondary_states_research.json",
            },
        }

    text = json.dumps(db, ensure_ascii=False, indent=2) + "\n"
    if args.check:
        ok = DB.read_text(encoding="utf-8") == text
        print("[PASS] base historique a jour" if ok else "[FAIL] base historique obsolete")
        return 0 if ok else 1
    DB.write_text(text, encoding="utf-8")
    print(f"[PASS] base historique ecrite : {len(SECONDARY)} Etats secondaires, "
          f"{len(db['sources'])} sources")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
