#!/bin/sh
set -eu
TASK_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TASK_GODOT=${BRACKENWARD_GODOT:-"$HOME/.local/share/brackenward/toolchain/4.7.2/Godot.app/Contents/MacOS/Godot"}
if [ ! -x "$TASK_GODOT" ]; then
  TASK_GODOT=$(command -v godot || true)
fi
if [ -z "$TASK_GODOT" ] || ! "$TASK_GODOT" --version | cut -d. -f1-3 | rg -qx '4\.7\.2'; then
  echo 'Godot 4.7.2 Standard required. Run python3 tools/bootstrap.py or set BRACKENWARD_GODOT.' >&2
  exit 1
fi
exec "$TASK_GODOT" --path "$TASK_ROOT" "$@"
