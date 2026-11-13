#!/usr/bin/env bash
#
# Rebuild the consolidated 1914 geometry entirely from versioned files.
#
# Pipeline (all inputs are tracked on this branch):
#   data/world/map/build/agent_1|agent_2/regions.geojson   (source lots)
#   data/world/map/sources/derived/*                       (minimal source extracts)
#        |
#        |-- tools/map/build_geometry.py       -> BLK-001 (Saray) + BLK-002 (micro-overlaps)
#        |-- tools/map/close_geometry_gaps.py  -> MAJ-004 (four seam gaps)
#        |-- tools/map/fix_strumica_salient.py -> MAJ-003 (1913 Strumica salient)
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
STAGE_MAJ003="$ROOT/.consolidation-stage-maj003"

cd "$ROOT"

echo "== 1/5  BLK-001 + BLK-002 : build_geometry.py =="
"$PY" tools/map/build_geometry.py \
  --saray-source data/world/map/sources/derived/gs1914_saray_tekirdag.geojson

echo "== 2/5  MAJ-004 : close_geometry_gaps.py =="
rm -rf "$STAGE" "$STAGE_MAJ003"
"$PY" tools/map/close_geometry_gaps.py \
  --kavanagh data/world/map/sources/derived/gs1914_kavanagh_1914_countries.gpkg \
  --ristat   data/world/map/sources/derived/gs1914_ristat_1897_finland_provinces.gpkg \
  --output-dir "$STAGE"

echo "== 3/5  MAJ-003 : fix_strumica_salient.py =="
"$PY" tools/map/fix_strumica_salient.py \
  --input-dir "$STAGE" \
  --strumica-extract data/world/map/sources/derived/gs1914_strumica_1913_salient.geojson \
  --output-dir "$STAGE_MAJ003"

echo "== 4/5  install consolidated artefacts =="
cp "$STAGE_MAJ003/regions.geojson" data/world/map/regions.geojson
cp "$STAGE_MAJ003/regions.json" data/world/map/regions.json
cp "$STAGE/geometry_gaps_report.json" docs/map/corrections/geometry_gaps_report.json
cp "$STAGE_MAJ003/strumica_salient_report.json" docs/map/corrections/strumica_salient_report.json
rm -rf "$STAGE" "$STAGE_MAJ003"

echo "== 5/5  validate =="
"$PY" tools/map/validate_geometry.py
"$PY" tools/map/validate_atlas.py

echo "Consolidated geometry rebuilt from versioned files."
