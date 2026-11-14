#!/usr/bin/env bash
#
# Point d'entrée unique des contrôles cartographiques de Grand Strategy-1914.
#
# Étapes (arrêt au premier échec, code de sortie non nul) :
#   1. Empreintes SHA-256 de référence (tools/map/REFERENCE_SHA256SUMS)
#   1b. Zones maritimes densifiées et valides en WGS 84 / EPSG:3035
#   2. validate_geometry.py
#   3. validate_atlas.py
#   4. validate_topology.py
#   5. validate_topology.py --rebuild-check   (rejeu de la topologie, octet pour octet)
#   6. [--full] reconstruction complète de la géométrie (consolidate_geometry.sh)
#      dans une copie temporaire des fichiers suivis, puis comparaison octet pour octet.
#
# Aucune étape n'écrit dans les fichiers suivis du dépôt.
#
# Usage :  tools/map/validate_all.sh [--full]
# Env    :  PYTHON=/chemin/vers/python
#           (défaut : ~/.venvs/gs1914-gis/bin/python, puis <dépôt>/.venv/bin/python, puis python3)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FULL=0
for argument in "$@"; do
  case "$argument" in
    --full) FULL=1 ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "Option inconnue : $argument" >&2; exit 2 ;;
  esac
done

if [[ -n "${PYTHON:-}" ]]; then
  PY="$PYTHON"
elif [[ -x "$HOME/.venvs/gs1914-gis/bin/python" ]]; then
  PY="$HOME/.venvs/gs1914-gis/bin/python"
elif [[ -x "$ROOT/.venv/bin/python" ]]; then
  PY="$ROOT/.venv/bin/python"
else
  PY="python3"
fi
export PYTHONDONTWRITEBYTECODE=1

echo "== Interpréteur : $PY"
"$PY" - <<'EOF'
import sys
try:
    import numpy, pyogrio, pyproj, shapely
except ImportError as error:
    sys.exit(f"Dépendance manquante : {error}. Voir tools/map/README.md.")
print(f"   Python {sys.version.split()[0]} | shapely {shapely.__version__} | "
      f"pyproj {pyproj.__version__} | pyogrio {pyogrio.__version__} | numpy {numpy.__version__}")
EOF

echo "== 1/6  Empreintes de référence"
sha256sum --check --strict tools/map/REFERENCE_SHA256SUMS

echo "== 1b    Zones maritimes densifiées et catalogue aligné sur la géométrie"
"$PY" tools/map/repair_maritime_zones.py --check
"$PY" tools/map/sync_maritime_catalogue.py --check
"$PY" tools/map/sync_region_attributes.py --check
"$PY" tools/map/build_thematic_layers.py --check

echo "== 2/6  validate_geometry.py"
"$PY" tools/map/validate_geometry.py

echo "== 3/6  validate_atlas.py"
"$PY" tools/map/validate_atlas.py

echo "== 4/6  validate_topology.py"
"$PY" tools/map/validate_topology.py

echo "== 5/6  validate_topology.py --rebuild-check"
"$PY" tools/map/validate_topology.py --rebuild-check

echo "== 5b    validate_thematic.py (villes, terrain, infrastructures)"
"$PY" tools/map/validate_thematic.py

if [[ "$FULL" -eq 1 ]]; then
  echo "== 6/6  Reconstruction complète de la géométrie (copie temporaire)"
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/gs1914-geometry-rebuild.XXXXXX")"
  trap 'rm -rf "$WORK"' EXIT
  git ls-files -z | tar --null -T - -cf - | tar -xf - -C "$WORK"
  PYTHON="$PY" bash "$WORK/tools/map/consolidate_geometry.sh" > "$WORK/rebuild.log" 2>&1 || {
    cat "$WORK/rebuild.log"; echo "ÉCHEC : la reconstruction géométrique a échoué." >&2; exit 1; }
  status=0
  for file in data/world/map/regions.geojson data/world/map/regions.json \
              docs/map/corrections/geometry_gaps_report.json \
              docs/map/corrections/strumica_salient_report.json; do
    if cmp -s "$ROOT/$file" "$WORK/$file"; then
      echo "   identique : $file"
    else
      echo "   DIFFÉRENT : $file" >&2; status=1
    fi
  done
  [[ "$status" -eq 0 ]] || { echo "ÉCHEC : reconstruction géométrique non identique." >&2; exit 1; }
else
  echo "== 6/6  Reconstruction géométrique complète : ignorée (utiliser --full)"
fi

echo
echo "RÉSULTAT GLOBAL : tous les contrôles cartographiques sont VALIDÉS."
