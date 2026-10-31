#!/usr/bin/env bash
# Pixel FX Starter checks: import, headless tests, then render tests.
# Run from anywhere:  GODOT=/path/to/godot tools/check.sh
# Render tests need a display. With no DISPLAY set, the script uses xvfb-run
# when it is installed (Mesa llvmpipe gives a software OpenGL renderer).
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
LOG="$(mktemp -d)"

fail_on_engine_errors() {
  # Engine error markers fail the run before any summary line is believed.
  if grep -nE "^(ERROR|SCRIPT ERROR)|Parse Error" "$1"; then
    echo "engine errors in $1"; exit 1
  fi
}

echo "== import"
"$GODOT" --headless --path . --import >"$LOG/import.log" 2>&1 || true
fail_on_engine_errors "$LOG/import.log"

echo "== headless tests"
"$GODOT" --headless --path . -s res://tests/run_tests.gd >"$LOG/headless.log" 2>&1 || { cat "$LOG/headless.log"; exit 1; }
fail_on_engine_errors "$LOG/headless.log"
tail -n 1 "$LOG/headless.log"

echo "== render tests"
RUN=("$GODOT" --path . --rendering-driver opengl3 --audio-driver Dummy -s res://tests/run_tests.gd)
if [[ -z "${DISPLAY:-}" ]]; then
  if command -v xvfb-run >/dev/null; then
    RUN=(xvfb-run -a -s "-screen 0 1280x720x24" "${RUN[@]}")
  else
    echo "no display and no xvfb-run: render tests NOT run"; exit 1
  fi
fi
"${RUN[@]}" >"$LOG/render.log" 2>&1 || { cat "$LOG/render.log"; exit 1; }
fail_on_engine_errors "$LOG/render.log"
grep -E "^renderer:" "$LOG/render.log"
tail -n 1 "$LOG/render.log"
echo "all checks passed"
