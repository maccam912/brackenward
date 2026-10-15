#!/usr/bin/env python3
"""Run/audit one natural twenty-resident summer and winter from frozen source."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def audit(reports, commit):
    try:
        source = json.loads((reports / "source.json").read_text())
        done = json.loads((reports / "completion.json").read_text())
        result = json.loads((reports / "campaign.json").read_text())
        initial = json.loads((reports / "campaign-initial.brackenward").read_text())
        final = json.loads((reports / "campaign-final.brackenward").read_text())
        beginning, world = json.loads(initial["payload"]), json.loads(final["payload"])
        counts = result["large_colony"]
        clean = not re.search(r"(?m)^(SCRIPT ERROR:|ERROR:|FAIL )", (reports / "campaign.log").read_text())
        windows = all(counts[s + "_home_ticks"] == 57600 and counts[s + "_zero_fullness_ticks"] == 0 for s in ["summer", "winter"])
        receipts = dict(world["receipts"]["$map"])
        admissions = [row for row in result["commands"] if row["command"]["kind"] == "newcomer" and row["command"]["args"]["accept"] and receipts.get(row["command"]["id"]) == "accepted"]
        hashes = (sha(reports / "campaign.json") == done["report_sha256"]
                  and hashlib.sha256(initial["payload"].encode()).hexdigest() == initial["sha256"]
                  and hashlib.sha256(final["payload"].encode()).hexdigest() == final["sha256"] == result["canonical_hash"])
        passed = (clean and hashes and done["exit_code"] == 0 and done["source_unchanged"] is True
                  and source["commit"] == commit and not done["error"] and result["scenario"] == "twenty_colony"
                  and result["ordinary_play_only"] is True and result["roundtrip_verified"] is True
                  and result["scenario_pass"] is True and result["invariant_failure"] == ""
                  and result["seed"] == source["seed"] and result["site"] == source["site"] and result["mode"] == source["mode"]
                  and result["start_tick"] == int(beginning["tick"]) == 1800 and len(beginning["citizens"]) == 4
                  and result["end_tick"] == int(world["tick"]) == 693000 and result["invariant_checks"] == 2304
                  and result["final"]["living"] == len(world["citizens"]) == 20 and len(admissions) == 16
                  and all(not c["death_recorded"] and not c["departed"] for c in world["citizens"])
                  and result["starvation_grace_exceeded_ticks"] == 0 and windows and result["final"]["food"]["ticks"] >= 7200)
        return {"passed": bool(passed), "source_commit": commit, "windows_pass": windows,
                "accepted_newcomers": len(admissions), "living": result["final"]["living"],
                "minimum_health": result["minimum_health"], "starvation_grace_exceeded_ticks": result["starvation_grace_exceeded_ticks"],
                "large_colony": counts, "canonical_hash": result["canonical_hash"],
                "final_snapshot_sha256": sha(reports / "campaign-final.brackenward"),
                "audit_tool_sha256": sha(Path(__file__)),
                "scope": "One ordinary campaign; twenty home residents for every tick of year-three summer and winter. Separate from stress, physical-device and human gates."}
    except (OSError, ValueError, KeyError, TypeError) as error:
        return {"passed": False, "error": str(error), "audit_tool_sha256": sha(Path(__file__))}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--report-dir", type=Path, required=True)
    parser.add_argument("--site", choices=["meadow_reach", "pine_shelf", "reed_bend"], default="meadow_reach")
    parser.add_argument("--seed", type=int, default=104729)
    parser.add_argument("--mode", choices=["Standard", "Hearthside"], default="Standard")
    parser.add_argument("--audit", action="store_true")
    args = parser.parse_args()
    source, reports = args.source.resolve(), args.report_dir.resolve()
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip()
    if subprocess.check_output(["git", "status", "--porcelain"], cwd=source): parser.error("Source must stay clean and frozen")
    if not 0 <= args.seed <= 4294967295: parser.error("Seed must be an unsigned 32-bit integer")
    if args.audit:
        result = audit(reports, commit)
        (reports / "audit.json").write_text(json.dumps(result, indent=2) + "\n")
        print(json.dumps(result)); raise SystemExit(0 if result["passed"] else 1)
    reports.mkdir(parents=True, exist_ok=True)
    if any(reports.iterdir()): parser.error("Use a new empty report directory")
    (reports / "source.json").write_text(json.dumps({"commit": commit, "source": str(source), "site": args.site, "seed": args.seed, "mode": args.mode, "days": 96, "started_unix": time.time(), "launcher_sha256": sha(Path(__file__))}, indent=2) + "\n")
    code, error = None, ""
    try:
        with (reports / "campaign.log").open("w") as log:
            process = subprocess.run([str(source / "tools/godot.sh"), "--headless", "--script", "tools/simulate.gd", "--", "--scenario", "twenty_colony", "--seed", str(args.seed), "--site", args.site, "--mode", args.mode, "--days", "96", "--report", str(reports / "campaign.json")], cwd=source, stdout=log, stderr=subprocess.STDOUT, timeout=14400)
            code = process.returncode
    except subprocess.TimeoutExpired:
        error = "Four-hour validation bound; partial reports retained"
    unchanged = commit == subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip() and not subprocess.check_output(["git", "status", "--porcelain"], cwd=source)
    report = reports / "campaign.json"
    (reports / "completion.json").write_text(json.dumps({"exit_code": code, "error": error, "source_unchanged": unchanged, "finished_unix": time.time(), "report_sha256": sha(report) if report.exists() else None}, indent=2) + "\n")
    result = audit(reports, commit)
    (reports / "audit.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result)); raise SystemExit(0 if result["passed"] else 1)


if __name__ == "__main__":
    main()
