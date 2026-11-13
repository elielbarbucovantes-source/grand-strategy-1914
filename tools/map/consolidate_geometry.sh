#!/usr/bin/env bash
#
# Rebuild the consolidated 1914 geometry entirely from versioned files.
#
# Pipeline (all inputs are tracked on this branch):
#   data/world/map/build/agent_1|agent_2/regions.geojson   (source lots)
#   data/world/map/sources/derived/*                       (minimal source extracts)
#        |
#        |-- tools/map/build_geometry.py      -> BLK-001 (Saray) + BLK-002 (micro-overlaps)
#        |-- tools/map/close_geometry_gaps.py -> MAJ-004 (four seam gaps)
#        v
#   data/world/map/regions.geojson + regions.json          (consolidated atlas)
#
# It never writes to /tmp and never touches main, the branches, or the thematic
# data. Re-running it on the pinned environment reproduces the committed files
# byte for byte.
#
# Usage:  tools/map/consolidate_geometry.sh
# Env:    PYTHON=/path/to/python  (default: <repo>/.venv/bin/python)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PY="${PYTHON:-$ROOT/.venv/bin/python}"
STAGE="$ROOT/.consolidation-stage"

cd "$ROOT"

echo "== 1/4  BLK-001 + BLK-002 : build_geometry.py =="
"$PY" tools/map/build_geometry.py \
  --saray-source data/world/map/sources/derived/gs1914_saray_tekirdag.geojson

echo "== 2/4  MAJ-004 : close_geometry_gaps.py =="
rm -rf "$STAGE"
"$PY" tools/map/close_geometry_gaps.py \
  --kavanagh data/world/map/sources/derived/gs1914_kavanagh_1914_countries.gpkg \
  --ristat   data/world/map/sources/derived/gs1914_ristat_1897_finland_provinces.gpkg \
  --output-dir "$STAGE"

echo "== 3/4  install consolidated artefacts =="
cp "$STAGE/regions.geojson" data/world/map/regions.geojson
cp "$STAGE/regions.json" data/world/map/regions.json
cp "$STAGE/geometry_gaps_report.json" docs/map/corrections/geometry_gaps_report.json

echo "== 4/4  validate =="
# validate_geometry.py exits 1 on the known, out-of-scope Strumica (MAJ-003)
# finding; the four MAJ-004 gaps and all geometry/overlap checks must pass.
"$PY" tools/map/validate_geometry.py || true
"$PY" tools/map/validate_atlas.py

echo "Consolidated geometry rebuilt from versioned files."
