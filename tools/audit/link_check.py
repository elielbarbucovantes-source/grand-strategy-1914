#!/usr/bin/env python3
"""Vérifie les liens relatifs des fichiers Markdown suivis par Git (lecture seule).

Usage :
  python3 tools/audit/link_check.py [--ref HEAD] [--include-legacy]

Par défaut, les copies historiques (docs/legacy/, ADR et documents rapatriés de la
lignée du 31/10) sont comptées à part : leurs liens visent l'arborescence d'origine
(voir docs/legacy/oct31/LINK_MAP.md). Code de sortie 1 si un document courant a un
lien relatif cassé. Les liens file:// et conversation:// (artefacts d'agent,
inutilisables hors de la machine d'origine) sont signalés à part.
"""
from __future__ import annotations

import argparse
import posixpath
import re
import subprocess
import sys

HISTORICAL_PREFIXES = ("docs/legacy/",)
HISTORICAL_FILES = {
    "docs/founding-document-v0.1.md", "docs/design-review-v0.1.md",
    "docs/decisions/arbitrage-t029-temps-strategique-tactique.md",
}
LINK = re.compile(r"\]\(([^)#\s]+)(#[^)]*)?\)")


def git(*args: str) -> str:
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def is_historical(path: str) -> bool:
    return (path.startswith(HISTORICAL_PREFIXES) or path in HISTORICAL_FILES
            or re.fullmatch(r"docs/decisions/000[0-6]-.*\.md", path) is not None)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--ref", default="HEAD")
    parser.add_argument("--include-legacy", action="store_true")
    arguments = parser.parse_args()
    files = {f for f in git("ls-tree", "-r", "--name-only", arguments.ref).splitlines() if f}
    current_broken, historical_broken, non_portable = {}, {}, {}
    for path in sorted(f for f in files if f.endswith(".md")):
        text = git("show", f"{arguments.ref}:{path}")
        bad = []
        for match in LINK.finditer(text):
            target = match.group(1)
            if target.startswith(("http://", "https://", "mailto:", "<")):
                continue
            if target.startswith(("file://", "conversation://")):
                non_portable.setdefault(path, []).append(target)
                continue
            resolved = posixpath.normpath(posixpath.join(posixpath.dirname(path), target))
            if resolved not in files and not any(f.startswith(resolved + "/") for f in files):
                bad.append(target)
        if bad:
            (historical_broken if is_historical(path) else current_broken)[path] = bad
    for path, bad in current_broken.items():
        print(f"CASSÉ  {path}: {sorted(set(bad))}")
    for path, bad in non_portable.items():
        print(f"NON PORTABLE  {path}: {len(bad)} lien(s) file:// ou conversation:// (artefacts d'agent)")
    print(f"Documents courants avec liens relatifs cassés : {len(current_broken)}")
    print(f"Copies historiques avec liens cassés : {len(historical_broken)} "
          f"({sum(len(v) for v in historical_broken.values())} liens)")
    if arguments.include_legacy:
        for path, bad in historical_broken.items():
            print(f"historique  {path}: {sorted(set(bad))}")
    return 1 if current_broken else 0


if __name__ == "__main__":
    sys.exit(main())
