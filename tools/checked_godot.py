#!/usr/bin/env python3
"""Fail closed on Godot script/engine errors, including a misleading zero exit.

Pass Godot arguments after --. An explicit executable can check an exported app;
--require-smoke-exit also requires graphical startup and the application's exact
isolated sixty-frame, audio-drained exit marker.
"""
import argparse
from pathlib import Path
import subprocess
import sys
from native_smoke import inspect_output
from utf8_output import configure_output

ROOT = Path(__file__).resolve().parents[1]


def run_command(command, require_smoke_exit=False, timeout=180, working_directory=ROOT):
    configure_output()
    try:
        result = subprocess.run(command, cwd=working_directory, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, encoding="utf-8",
                                errors="replace", timeout=timeout)
        print(result.stdout, end="")
        evidence = inspect_output(result.stdout, result.returncode, require_smoke_exit,
                                  app_exit_required=require_smoke_exit)
        for failure in evidence["failures"]:
            print("Godot check failed: " + failure, file=sys.stderr)
        return 1 if evidence["failures"] else 0
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ""
        print(output.decode("utf-8", "replace") if isinstance(output, bytes) else output, end="")
        print("Godot command timed out; no successful result.", file=sys.stderr)
        return 1
    except OSError as error:
        print("Could not start Godot command: " + str(error), file=sys.stderr)
        return 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--executable", default=str(ROOT / "tools/godot.sh"))
    parser.add_argument("--require-smoke-exit", action="store_true")
    parser.add_argument("--working-directory", type=Path, default=ROOT)
    parser.add_argument("--timeout", type=float, default=180, help="Wall-clock command limit in seconds (up to one hour)")
    parser.add_argument("arguments", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    forwarded = args.arguments[1:] if args.arguments[:1] == ["--"] else args.arguments
    if not forwarded:
        parser.error("Pass Godot arguments after --")
    if not 0 < args.timeout <= 3600:
        parser.error("--timeout must be positive and at most 3600 seconds")
    return run_command([str(Path(args.executable).resolve()), *forwarded], args.require_smoke_exit,
                       timeout=args.timeout, working_directory=args.working_directory)


if __name__ == "__main__":
    raise SystemExit(main())
