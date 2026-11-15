#!/usr/bin/env bash
# Lance les tests GDScript sans interface. Échoue aussi sur toute erreur de script GDScript
# (non interceptable depuis GDScript).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-$HOME/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64}"
cd "$ROOT"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
OUT="$(timeout 900 "$GODOT" --headless --path . --script tests/run_tests.gd 2>&1)"; CODE=$?
echo "$OUT" | grep -vE "^Godot Engine"
UI="$(timeout 300 "$GODOT" --headless --path . --script tests/ui_smoke.gd 2>&1)"; UICODE=$?
echo "$UI" | grep -vE "^Godot Engine"
BUI="$(timeout 300 "$GODOT" --headless --path . --script tests/battle_ui_smoke.gd 2>&1)"; BUICODE=$?
echo "$BUI" | grep -vE "^Godot Engine"
UI="$UI$BUI"; [[ $BUICODE -eq 0 ]] || UICODE=1
if echo "$OUT$UI" | grep -qE "SCRIPT ERROR|Parse Error|Compile Error"; then
  echo "ÉCHEC : erreur de script GDScript détectée" >&2; exit 1
fi
[[ $CODE -eq 0 && $UICODE -eq 0 ]] || exit 1
exit 0
