#!/usr/bin/env python3
"""Run the pinned native editor's SAVE10 replay; fail on engine errors or incomplete evidence."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

import bootstrap
from utf8_output import configure_output

ROOT = Path(__file__).resolve().parents[1]

def run_engine(binary, arguments, timeout, logs):
    result = subprocess.run([str(binary), "--path", str(ROOT), "--headless", "--audio-driver", "Dummy", *arguments],
                            cwd=ROOT, text=True, encoding="utf-8", errors="replace", stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=timeout)
    logs.append(result.stdout)
    print(result.stdout, end="", flush=True)
    clean = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", result.stdout)
    if result.returncode or re.search(r"(?m)^(SCRIPT ERROR:|ERROR:|REPLAY FAIL:)", clean):
        raise RuntimeError("Pinned engine reported a replay/import failure")
    return clean

def main():
    configure_output()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--record-golden", action="store_true", help="Record a new content-version baseline; existing reviewed files are protected")
    parser.add_argument("--report", default="reports/replay.json")
    parser.add_argument("--replay-timeout", type=int, default=780,
                        help="Maximum replay subprocess seconds (1..3600; default 780)")
    args = parser.parse_args()
    if not 1 <= args.replay_timeout <= 3600:
        parser.error("--replay-timeout must be between 1 and 3600 seconds")
    binary = Path(os.environ.get("BRACKENWARD_GODOT", bootstrap.engine_binary()))
    if not binary.exists():
        raise SystemExit("Pinned editor missing; run python tools/bootstrap.py --editor-only")
    bootstrap.verify_engine(binary)
    report = Path(args.report)
    if not report.is_absolute():
        report = ROOT / report
    report.parent.mkdir(parents=True, exist_ok=True)
    report.unlink(missing_ok=True)
    for tick in (7200, 72000):
        report.with_name(report.stem + f"-{tick}.brackenward").unlink(missing_ok=True)
    logs = []
    try:
        run_engine(binary, ["--editor", "--import", "--quit"], 120, logs)
        arguments = ["--script", "tools/replay_campaign.gd", "--", "--report", str(report)]
        if args.record_golden:
            arguments.append("--record-golden")
        clean = run_engine(binary, arguments, args.replay_timeout, logs)
        evidence = json.loads(report.read_text())
        if not evidence.get("passed") or not evidence.get("cross_host_save_continuation") or \
           [int(item["tick"]) for item in evidence.get("checkpoints", [])] != [7200, 72000] or \
           any(not re.fullmatch(r"[a-f0-9]{64}", item["canonical_hash"]) for item in evidence["checkpoints"]) or \
           "REPLAY PASS:" not in clean:
            raise RuntimeError("Replay did not produce complete passing evidence")
        if int(evidence.get("schema_revision", 0)) == 23:
            audit = report.with_name(report.stem + "-schema22-audit.json")
            audit.unlink(missing_ok=True)
            run_engine(binary, ["--script", "tools/check_budget_replay_preservation.gd", "--",
                               "--report", str(report), "--audit", str(audit)], 180, logs)
            if not json.loads(audit.read_text()).get("passed"):
                raise RuntimeError("Schema-22 gameplay/foreign-fixture preservation audit failed")
            evidence["schema22_gameplay_preservation"] = True
            evidence["schema22_scope"] = json.loads(audit.read_text())["scope"]
        migration = report.with_name(report.stem + "-content3-migration.json")
        migration.unlink(missing_ok=True)
        run_engine(binary, ["--script", "tools/check_content3_migration.gd", "--",
                           "--audit", str(migration)], 180, logs)
        if not json.loads(migration.read_text()).get("passed"):
            raise RuntimeError("Frozen v3 acknowledgement migration audit failed")
        evidence["content3_acknowledgement_preservation"] = True
        migration4 = report.with_name(report.stem + "-content4-migration.json")
        migration4.unlink(missing_ok=True)
        run_engine(binary, ["--script", "tools/check_content4_migration.gd", "--",
                           "--audit", str(migration4)], 180, logs)
        if not json.loads(migration4.read_text()).get("passed"):
            raise RuntimeError("Frozen v4 acknowledgement migration audit failed")
        evidence["content4_acknowledgement_preservation"] = True
        migration5 = report.with_name(report.stem + "-content5-migration.json")
        migration5.unlink(missing_ok=True)
        run_engine(binary, ["--script", "tools/check_content5_migration.gd", "--",
                           "--audit", str(migration5)], 180, logs)
        if not json.loads(migration5.read_text()).get("passed"):
            raise RuntimeError("Frozen v5 acknowledgement migration audit failed")
        evidence["content5_acknowledgement_preservation"] = True
        migration6 = report.with_name(report.stem + "-content6-migration.json")
        migration6.unlink(missing_ok=True)
        run_engine(binary, ["--script", "tools/check_content6_migration.gd", "--",
                           "--audit", str(migration6)], 180, logs)
        if not json.loads(migration6.read_text()).get("passed"):
            raise RuntimeError("Frozen v6 acknowledgement migration audit failed")
        evidence["content6_acknowledgement_preservation"] = True
        report.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        if isinstance(error, subprocess.TimeoutExpired) and error.stdout:
            logs.append(error.stdout.decode(errors="replace") if isinstance(error.stdout, bytes) else error.stdout)
        print("Replay gate failed:", error, file=sys.stderr)
        report.write_text(json.dumps({"version": 1, "passed": False, "error": str(error)}, indent=2) + "\n", encoding="utf-8")
        return 1
    finally:
        report.with_suffix(".log").write_text("".join(logs), encoding="utf-8")
    return 0

if __name__ == "__main__":
    sys.exit(main())
