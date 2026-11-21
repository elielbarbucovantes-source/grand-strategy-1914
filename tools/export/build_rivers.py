#!/usr/bin/env python3
"""Copie les rivieres de data/world/map/terrain.json vers data/rules/rivers.json.

data/world contient un .gdignore : ses fichiers ne sont pas presents dans un
export Godot. data/rules est, lui, exporte. Ce generateur rend la copie
reproductible et evite de dupliquer manuellement les donnees.

Usage : python3 tools/export/build_rivers.py [--check]
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "data/world/map/terrain.json"
OUT = ROOT / "data/rules/rivers.json"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    src = json.loads(SRC.read_text(encoding="utf-8"))
    doc = {
        "format": "gs1914.rivers",
        "format_version": 1,
        "generated_by": "tools/export/build_rivers.py",
        "reference_date": src["reference_date"],
        "sources": src.get("source_refs", []),
        "major_rivers": src["major_rivers"],
    }
    text = json.dumps(doc, ensure_ascii=False, indent=2) + "\n"
    if args.check:
        ok = OUT.read_text(encoding="utf-8") == text
        print("[PASS] rivieres a jour" if ok else "[FAIL] rivieres obsoletes")
        return 0 if ok else 1
    OUT.write_text(text, encoding="utf-8")
    print(f"[PASS] {len(src['major_rivers'])} rivieres exportees")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
