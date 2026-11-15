#!/usr/bin/env bash
# Lance les tests GDScript sans interface. Échoue aussi sur toute erreur de script GDScript
# (non interceptable depuis GDScript).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-$HOME/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64}"
cd "$ROOT"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
OUT="$("$GODOT" --headless --path . --script tests/run_tests.gd 2>&1)"; CODE=$?
echo "$OUT" | grep -vE "^Godot Engine"
if echo "$OUT" | grep -qE "SCRIPT ERROR|Parse Error|Compile Error"; then
  echo "ÉCHEC : erreur de script GDScript détectée" >&2; exit 1
fi
exit $CODE
