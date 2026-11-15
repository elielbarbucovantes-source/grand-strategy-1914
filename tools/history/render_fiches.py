#!/usr/bin/env python3
"""Génère une fiche Markdown par puissance depuis la base MIL-01.

Sources : data/history/military_forces_1914.json (valeurs, sources, divergences) et
data/scenarios/campaign_1914.json (répartition effectivement utilisée par le jeu).
Les fiches sont DÉRIVÉES : toute correction se fait dans la base, puis on régénère.

Usage : python3 tools/history/render_fiches.py [--check]
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DB = ROOT / "data/history/military_forces_1914.json"
CAMPAIGN = ROOT / "data/scenarios/campaign_1914.json"
WORLD = ROOT / "data/game/world_map.json"
OUT = ROOT / "docs/history/fiches"


def fmt(v) -> str:
    if v is None:
        return "**inconnu**"
    if isinstance(v, (int, float)):
        return f"{int(v):,}".replace(",", " ")
    return str(v)


def value_block(title: str, v: dict, sources: dict) -> list[str]:
    src = sources[v["source"]]
    lines = [f"### {title}", "",
             "| Champ | Contenu |", "|---|---|",
             f"| Valeur retenue | **{fmt(v['value'])}** |",
             f"| Date de référence | {v.get('reference_date', '—')} |",
             f"| Définition | {v.get('definition', '—')} |",
             f"| Source | `{v['source']}` — {src['citation']} |",
             f"| Page / passage | {v.get('page', '—')} |",
             f"| Lien | {src.get('url') or '—'} |",
             f"| Fiabilité | {v.get('reliability', '—')} |"]
    if v.get("derivation"):
        lines.append(f"| Calcul | {v['derivation']} |")
    if v.get("choice"):
        lines.append(f"| Justification du choix | {v['choice']} |")
    if v.get("reliability_note"):
        lines.append(f"| Remarque | {v['reliability_note']} |")
    lines.append("")
    if v.get("divergences"):
        lines += ["**Divergences conservées :**", "", "| Valeur | Source | Page | Définition | Note |", "|---|---|---|---|---|"]
        for d in v["divergences"]:
            lines.append(f"| {fmt(d['value'])} | `{d['source']}` | {d.get('page', '—')} | {d.get('definition', '—')} | {d.get('note', '')} |")
        lines.append("")
    for e in v.get("excluded", []):
        lines.append(f"- Exclu : **{e['category']}** ({fmt(e['value'])}, {e['source']}) : {e['reason']}")
    if v.get("excluded"):
        lines.append("")
    return lines


def echelon_block(block: dict | None) -> list[str]:
    if not block:
        return []
    lines = ["### Échelons de mobilisation (T-051)", "", block["_statut"], "",
             "| Échelon | Valeur | Statut | Sources | Définition, calcul ou motif |", "|---|---|---|---|---|"]
    for e in block["echelons"]:
        detail = " ".join(str(e[k]) for k in ("definition", "derivation", "composition", "precision", "reason") if e.get(k))
        if e.get("timing"):
            detail += f" Délais : {e['timing']}."
        for dv in e.get("divergences", []):
            detail += f" Divergence : {fmt(dv['value'])} (`{dv['source']}` {dv.get('page', '')}) — {dv['definition']}."
        lines.append(f"| {e['label_fr']} | **{fmt(e['value'])}** | {e['status']} | {', '.join(e.get('sources', [])) or '—'} | {detail} |")
    return lines + [""]


def territorial_block(tf: dict, sources: dict) -> list[str]:
    lines = ["### Territorial Force (catégorie distincte, T-050 et T-054)", "", tf["_statut"], "",
             "| Champ | Contenu |", "|---|---|",
             f"| Effectif réel | **{fmt(tf['value'])}** |",
             f"| Date | {tf['reference_date']} |",
             f"| Définition | {tf['definition']} |",
             f"| Source | `{tf['source']}` — {sources[tf['source']]['citation']} |",
             f"| Page | {tf['page']} |",
             f"| Effectif théorique | {fmt(tf['establishment']['value'])} ({tf['establishment']['definition']}) |",
             f"| Double comptage | {tf['double_counting_check']} |",
             f"| Emploi | {tf['deployment_rule']} |", ""]
    for x in tf.get("not_included", []):
        lines.append(f"- Non inclus : **{x['category']}** ({fmt(x['value'])}, {x['page']}) : {x['note']}")
    for dv in tf.get("divergences", []):
        lines.append(f"- Divergence : {fmt(dv['value'])} (`{dv['source']}` {dv['page']}) — {dv['definition']} {dv.get('note', '')}")
    return lines + [""]


def render(nid: str, n: dict, db: dict, camp: dict, regions: dict) -> str:
    forces = camp["nations"][nid]["forces"]
    units = [f for f in camp["formations"] if f["nation"] == nid and f["echelon"] == "unit"]
    per_region = defaultdict(lambda: defaultdict(int))
    for u in units:
        per_region[u["region"]][u["unit_type"]] += u["soldiers"]
    lines = [f"# {n['name_fr']} — effectifs 1914 (MIL-01)", "",
             "> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.", "",
             f"**État des données : {n['data_status']}**", ""]
    lines += value_block("A. Armée active (temps de paix)", n["active"], db["sources"])
    lines += value_block("B. Réserves mobilisables", n["reserves"], db["sources"])
    share = n["reserves"]["on_map_share"]
    lines += [f"Part des réserves sur la carte : {share['numerator']}/{share['denominator']} — {share['basis']}", ""]
    chk = n["reserves"].get("source_total_check")
    if chk:
        total = chk["total_including_active"]
        lines += ["**Contrôle de cohérence avec la source :** "
                  + (f"total des instruits, actifs compris : {fmt(total)} (`{chk['source']}` {chk['page']}) ; "
                     f"actif + réserves = {fmt(n['active']['value'] + n['reserves']['value'])}. " if total is not None else "")
                  + f"{chk['definition']} {chk['rule']}", ""]
    lines += echelon_block(n.get("mobilization_echelons"))
    if n.get("territorial_force"):
        lines += territorial_block(n["territorial_force"], db["sources"])
    lines += ["### Ventilation par arme", ""]
    if n.get("arms"):
        a = n["arms"]
        lines += [f"Source : `{a['source']}` {a['page']}" + (f" ; périmètre : {a['scope']}" if a.get("scope") else ""), "",
                  "| Infanterie | Cavalerie | Art. de campagne | Art. à pied | Art. côtière | Technique | Train | Santé | Total |",
                  "|---|---|---|---|---|---|---|---|---|",
                  "| " + " | ".join(fmt(a.get(k)) for k in ["infantry", "cavalry", "field_artillery", "foot_artillery",
                                                         "coast_artillery", "technical", "train", "sanitary", "total"]) + " |", ""]
        if a.get("note"):
            lines += [a["note"], ""]
    else:
        lines += [n.get("arms_status", "**inconnue**"), ""]
    off = n["off_map"]
    lines += ["### Forces hors de la carte", "", f"**{fmt(off['value'])}** ({off['status']}) — {off['basis']}", ""]
    lines += ["### Districts du temps de paix (répartition ESTIMÉE)", "",
              f"Contrôle du nombre : {n['districts_count_check']['expected']} — {n['districts_count_check']['source']}", "",
              "| District | Siège | Siège vérifié ? | Région du jeu |", "|---|---|---|---|"]
    located = {f["district_id"]: f["district_region"] for f in camp["formations"] if f.get("district_id")}
    for d in n["districts"]:
        rid = located.get(d["id"])
        where = f"{rid} ({regions[rid]})" if rid else "hors carte"
        check = d["hq_verification"] + (f" ({d['hq_source']})" if d.get("hq_source") else "")
        check += "".join(f" — {d[k]}" for k in ("hq_correction", "hq_note") if d.get(k))
        lines.append(f"| {d['name_fr']} | {d['hq']} | {check} | {where} |")
    lines += ["", "### Situation de départ dans le jeu (campagne historique)", "",
              f"- Actifs au démarrage : {fmt(forces['active_start'])} ; sur la carte : {fmt(forces['active_on_map'])} "
              f"(unités combattantes {fmt(sum(u['soldiers'] for u in units))} + services {fmt(forces['services_active'])}).",
              f"- Réserves sur la carte (non incorporées) : {fmt(forces['reserve_pool_initial'])} ; hors carte : {fmt(forces['reserves_off_map'])}.",
              f"- Unités : {len(units)}.", "",
              "| Région | Infanterie | Cavalerie | Artillerie |", "|---|---|---|---|"]
    for rid in sorted(per_region):
        r = per_region[rid]
        lines.append(f"| {rid} ({regions[rid]}) | {fmt(r.get('infantry', 0))} | {fmt(r.get('cavalry', 0))} | {fmt(r.get('artillery', 0))} |")
    lines += ["", "Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).", ""]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    db = json.loads(DB.read_text(encoding="utf-8"))
    camp = json.loads(CAMPAIGN.read_text(encoding="utf-8"))
    regions = {r["id"]: r["name_fr"] for r in json.loads(WORLD.read_text(encoding="utf-8"))["regions"]}
    outputs = {OUT / f"{nid}.md": render(nid, n, db, camp, regions) for nid, n in db["nations"].items()}
    if args.check:
        ok = all(p.exists() and p.read_text(encoding="utf-8") == t for p, t in outputs.items())
        print("[PASS] fiches MIL-01 à jour" if ok else "[FAIL] fiches MIL-01 obsolètes")
        return 0 if ok else 1
    OUT.mkdir(parents=True, exist_ok=True)
    for p, t in outputs.items():
        p.write_text(t, encoding="utf-8")
        print(f"{p.relative_to(ROOT)} écrit")
    return 0


if __name__ == "__main__":
    sys.exit(main())
