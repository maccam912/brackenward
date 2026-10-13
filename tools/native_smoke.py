#!/usr/bin/env python3
"""Check a graphical source-project launch; exported packages/devices are separate gates."""
import argparse
import json
import platform
import re
import subprocess
import sys
import time
from pathlib import Path

from bootstrap import LOCK, ROOT, engine_binary, verify_engine

ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
ERROR = re.compile(r"(?m)^\s*(?:SCRIPT ERROR|ERROR|FATAL ERROR):[^\r\n]*")
RENDERER = re.compile(
    r"(?m)^OpenGL(?: ES)?(?: API)?[^\r\n]* - Compatibility - Using Device: \S[^\r\n]*"
)


def is_software_renderer(renderer):
    # The Windows hosted runner uses ANGLE over Microsoft's WARP adapter.
    return bool(re.search(
        r"llvmpipe|softpipe|SwiftShader|Software Rasterizer|Microsoft Basic Render (?:Driver|Adapter)",
        renderer, re.I,
    ))


def inspect_output(output, returncode, graphical):
    """Require positive graphical evidence, even when Godot exits successfully."""
    clean = ANSI.sub("", output)
    errors = ERROR.findall(clean)
    renderer = RENDERER.findall(clean)
    failures = []
    if returncode != 0:
        failures.append(f"Godot exited with status {returncode}")
    if errors:
        failures.append("Godot reported script or engine errors")
    if graphical and not renderer:
        failures.append("No OpenGL Compatibility renderer startup evidence")
    return {"failures": failures, "errors": errors, "renderer_startup": renderer}


def run_stage(command, graphical):
    started = time.monotonic()
    try:
        result = subprocess.run(
            command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, encoding="utf-8", errors="replace", timeout=180,
        )
        output = result.stdout
        evidence = inspect_output(output, result.returncode, graphical)
        evidence["returncode"] = result.returncode
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ""
        if isinstance(output, bytes):
            output = output.decode("utf-8", errors="replace")
        evidence = inspect_output(output, None, graphical)
        evidence["failures"].append("Godot timed out after 180 seconds")
        evidence["returncode"] = None
    except OSError as error:
        output = str(error) + "\n"
        evidence = {"failures": ["Unable to launch Godot: " + str(error)],
                    "errors": [], "renderer_startup": [], "returncode": None}
    evidence.update(command=command, elapsed_seconds=round(time.monotonic() - started, 3))
    print(output, end="" if output.endswith("\n") else "\n", flush=True)
    return evidence, output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True, help="JSON evidence output path")
    parser.add_argument("--skip-import", action="store_true", help="Use an already imported project")
    args = parser.parse_args()
    report_path = args.report.resolve()
    log_path = report_path.with_suffix(".log")
    if log_path == report_path:
        log_path = report_path.with_name(report_path.name + ".output.log")
    version = f"{LOCK['godot_version']}.stable.official.{LOCK['godot_build'][:9]}"
    report = {
        "version": 1, "check": "source_project_native_launch", "passed": False,
        "scope": "Graphical native launch of the source project's main scene. Exported packages, physical Android, interaction, and performance certification remain separate.",
        "host": {"system": platform.system(), "release": platform.release(), "machine": platform.machine()},
        "engine": version, "project": str(ROOT / "project.godot"),
        "import_skipped": args.skip_import, "requested_quit_after": 60,
        "log": str(log_path), "stages": {}, "failures": [],
    }
    logs = []
    try:
        binary = engine_binary()
        report["binary"] = str(binary)
        verify_engine(binary)
        report["engine_verified"] = True
        if not args.skip_import:
            command = [str(binary), "--path", str(ROOT), "--headless", "--editor", "--import"]
            evidence, output = run_stage(command, graphical=False)
            report["stages"]["import"] = evidence
            logs.append("Project import\n" + output)
            report["failures"].extend(evidence["failures"])
        if not report["failures"]:
            command = [str(binary), "--path", str(ROOT), "--audio-driver", "Dummy",
                       "--rendering-method", "gl_compatibility", "--quit-after", "60"]
            evidence, output = run_stage(command, graphical=True)
            report["stages"]["native_launch"] = evidence
            logs.append("Graphical native launch\n" + output)
            report["failures"].extend(evidence["failures"])
            renderer = "\n".join(evidence["renderer_startup"])
            report["software_renderer"] = is_software_renderer(renderer)
        report["passed"] = not report["failures"] and "native_launch" in report["stages"]
    except (OSError, subprocess.SubprocessError, SystemExit) as error:
        report["failures"].append("Pinned engine verification failed: " + str(error))
        logs.append(report["failures"][-1] + "\n")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text("\n".join(logs), encoding="utf-8")
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(("PASS" if report["passed"] else "FAIL") + ": source-project native launch; " + str(report_path))
    for failure in report["failures"]:
        print(failure, file=sys.stderr)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
