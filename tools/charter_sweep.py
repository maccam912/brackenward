#!/usr/bin/env python3
"""Run and audit four ordinary vegetarian Charter campaigns from frozen source."""
import argparse
import concurrent.futures
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time

CASES = [(site, "Standard") for site in ["meadow_reach", "pine_shelf", "reed_bend"]] + [("pine_shelf", "Hearthside")]
SEED = 104729


def verify(path, exit_code, site, mode, days):
    row = {"site": site, "mode": mode, "seed": SEED, "exit_code": exit_code, "pass": False}
    try:
        data = json.loads(path.read_text())
        save = path.with_name(path.stem + "-final.brackenward")
        envelope = json.loads(save.read_text())
        exact = hashlib.sha256(envelope["payload"].encode()).hexdigest()
        clean = not re.search(r"(?m)^(SCRIPT ERROR:|ERROR:|FAIL )", path.with_suffix(".log").read_text())
        ceremony = data["charter"]["ceremony"]
        row.update({key: data.get(key) for key in ["canonical_hash", "end_tick", "minimum_health", "zero_fullness_ticks", "starvation_grace_exceeded_ticks", "invariant_checks", "roundtrip_verified", "scenario_pass"]})
        row.update({"snapshot_sha256": hashlib.sha256(save.read_bytes()).hexdigest(), "ceremony_end": ceremony.get("end"), "continued": data["charter"]["continued"]})
        row["pass"] = clean and exit_code == 0 and data["ordinary_play_only"] is True and data["scenario"] == "vegetarian_charter" and data["site"] == site and data["mode"] == mode and data["seed"] == SEED and data["start_tick"] == 1800 and data["end_tick"] == 1800 + days * 7200 and data["scenario_pass"] is True and data["roundtrip_verified"] is True and exact == envelope["sha256"] == data["canonical_hash"] and data["invariant_failure"] == "" and len(data["charter"]["completed"]) == 5 and data["charter"]["ending"] is True and data["charter"]["continued"] is True and ceremony["state"] == "Complete" and data["end_tick"] >= ceremony["end"] + 7200 and data["final"]["living"] >= 8 and all(not person["departed"] for person in data["final"]["citizens"])
    except (OSError, ValueError, KeyError, TypeError) as error:
        row["error"] = str(error)
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--report-dir", type=Path, required=True)
    parser.add_argument("--days", type=int, default=96, choices=range(40, 129))
    parser.add_argument("--workers", type=int, default=2, choices=[1, 2, 3])
    parser.add_argument("--audit", action="store_true")
    args = parser.parse_args()
    source, reports = args.source.resolve(), args.report_dir.resolve()
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip()
    if subprocess.check_output(["git", "status", "--porcelain"], cwd=source):
        parser.error("The source checkout must be clean and remain frozen")
    if args.audit:
        provenance = json.loads((reports / "source.json").read_text())
        summary = json.loads((reports / "summary.json").read_text())
        rows = [verify(reports / f"{site}-{mode.lower()}.json", next((r["exit_code"] for r in summary if (r["site"], r["mode"]) == (site, mode)), None), site, mode, provenance["days"]) for site, mode in CASES]
        complete = len(summary) == 4 and {(r["site"], r["mode"]) for r in summary} == set(CASES)
        result = {"source_commit": commit, "passed": complete and provenance["commit"] == commit and all(r["pass"] for r in rows), "rows": rows, "audit_tool_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
        (reports / "audit.json").write_text(json.dumps(result, indent=2) + "\n")
        raise SystemExit(0 if result["passed"] else 1)
    reports.mkdir(parents=True, exist_ok=True)
    provenance = reports / "source.json"
    if any(reports.iterdir()):
        parser.error("Use a new empty report directory to preserve earlier evidence")
    provenance.write_text(json.dumps({"commit": commit, "source": str(source), "days": args.days, "seed": SEED, "cases": CASES, "started_unix": time.time(), "workers": args.workers, "harness_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}, indent=2) + "\n")

    def run(pair):
        site, mode = pair
        path = reports / f"{site}-{mode.lower()}.json"
        try:
            with path.with_suffix(".log").open("w") as log:
                process = subprocess.run([str(source / "tools/godot.sh"), "--headless", "--script", "tools/simulate.gd", "--", "--scenario", "vegetarian_charter", "--seed", str(SEED), "--site", site, "--mode", mode, "--days", str(args.days), "--report", str(path)], cwd=source, stdout=log, stderr=subprocess.STDOUT, timeout=3600)
            return verify(path, process.returncode, site, mode, args.days)
        except subprocess.TimeoutExpired:
            return {"site": site, "mode": mode, "seed": SEED, "exit_code": None, "pass": False, "error": "One-hour validation limit; partial reports retained"}

    summary = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        for future in concurrent.futures.as_completed([pool.submit(run, case) for case in CASES]):
            summary.append(future.result())
            (reports / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
            print(f"{len(summary)}/4: {summary[-1]['site']} {summary[-1]['mode']} {'PASS' if summary[-1]['pass'] else 'FAILED'}", flush=True)
    unchanged = commit == subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip() and not subprocess.check_output(["git", "status", "--porcelain"], cwd=source)
    (reports / "completion.json").write_text(json.dumps({"source_unchanged": unchanged, "finished_unix": time.time(), "total": len(summary), "passed": sum(r["pass"] for r in summary)}, indent=2) + "\n")
    raise SystemExit(0 if unchanged and all(r["pass"] for r in summary) else 1)


if __name__ == "__main__":
    main()
