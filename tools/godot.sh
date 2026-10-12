#!/bin/sh
set -eu
TASK_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TASK_GODOT=${BRACKENWARD_GODOT:-"$HOME/.local/share/brackenward/toolchain/4.7.2/Godot.app/Contents/MacOS/Godot"}
if [ ! -x "$TASK_GODOT" ]; then
  TASK_GODOT=$(command -v godot || true)
fi
if [ -z "$TASK_GODOT" ]; then
  echo 'Godot 4.7.2 Standard required. Run python3 tools/bootstrap.py or set BRACKENWARD_GODOT.' >&2
  exit 1
fi
TASK_VERSION=$("$TASK_GODOT" --version)
case "$TASK_VERSION" in
  4.7.2.stable.official.ed1daf0bf) ;;
  *) echo 'Pinned Godot 4.7.2 Standard official build required.' >&2; exit 1 ;;
esac
exec "$TASK_GODOT" --path "$TASK_ROOT" "$@"
