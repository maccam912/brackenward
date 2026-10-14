#!/usr/bin/env python3
"""Run the release winter matrix from one clean, frozen checkout; never retry failures."""
import argparse
import concurrent.futures
import hashlib
import json
import re
from pathlib import Path
import subprocess
import time

SEEDS = [0, 1, 42, 104729, 2147483647, 4294967295, 73, 4567, 1357911, 3000000001]
SITES = ["meadow_reach", "pine_shelf", "reed_bend"]


def audit(reports, commit):
    """Also verify already recorded runs, including engine errors despite exit 0."""
    rows = json.loads((reports / "summary.json").read_text())
    original = json.loads((reports / "source.json").read_text())
    expected = {(site, seed) for site in SITES for seed in SEEDS}
    found = set()
    for row in rows:
        path = reports / f"{row['site']}-{row['seed']}.json"
        pair = (row["site"], row["seed"])
        unique = pair not in found and pair in expected
        found.add(pair)
        data = json.loads(path.read_text())
        envelope = json.loads(path.with_name(path.stem + "-final.brackenward").read_text())
        exact = hashlib.sha256(envelope["payload"].encode()).hexdigest()
        log = path.with_suffix(".log").read_text()
        clean = not re.search(r"(?m)^(SCRIPT ERROR:|ERROR:|FAIL )", log)
        row["audit_pass"] = unique and clean and row.get("exit_code") == 0 and row.get("source_commit") == commit == original["commit"] and data.get("scenario_pass") is True and data.get("roundtrip_verified") is True and data.get("ordinary_play_only") is True and data.get("site") == row["site"] and data.get("seed") == row["seed"] and data.get("mode") == "Standard" and data.get("end_tick") == 239400 and data.get("starvation_grace_exceeded_ticks") == 0 and exact == envelope["sha256"] == data["canonical_hash"] == row["canonical_hash"]
    result = {"commit": commit, "total": len(rows), "passed": sum(row["audit_pass"] for row in rows),
        "complete_matrix": found == expected and len(rows) == 30, "rows": rows,
        "audit_tool_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    (reports / "audit.json").write_text(json.dumps(result, indent=2) + "\n")
    return result["complete_matrix"] and result["passed"] == 30


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--report-dir", type=Path, required=True)
    parser.add_argument("--workers", type=int, choices=range(1, 5), default=3)
    parser.add_argument("--audit", action="store_true", help="Verify existing reports and logs without rerunning or replacing them")
    args = parser.parse_args()
    source, reports = args.source.resolve(), args.report_dir.resolve()
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip()
    if subprocess.check_output(["git", "status", "--porcelain"], cwd=source):
        parser.error("Source checkout must be clean and remain frozen throughout the run")
    if args.audit:
        raise SystemExit(0 if audit(reports, commit) else 1)
    reports.mkdir(parents=True, exist_ok=True)
    provenance = reports / "source.json"
    if provenance.exists():
        parser.error("Use a new report directory so earlier evidence cannot be overwritten")
    provenance.write_text(json.dumps({"commit": commit, "source": str(source), "started_unix": time.time(),
        "scenario": "first_winter", "days": 33, "mode": "Standard", "seeds": SEEDS,
        "sites": SITES, "workers": args.workers,
        "harness_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}, indent=2) + "\n")
    summary = []

    def run(pair):
        site, seed = pair
        path = reports / f"{site}-{seed}.json"
        with path.with_suffix(".log").open("w") as log:
            result = subprocess.run([str(source / "tools/godot.sh"), "--headless", "--script", "tools/simulate.gd", "--",
                "--scenario", "first_winter", "--seed", str(seed), "--site", site,
                "--mode", "Standard", "--days", "33", "--report", str(path)], cwd=source, stdout=log, stderr=subprocess.STDOUT)
        entry = {"site": site, "seed": seed, "exit_code": result.returncode, "report": str(path), "source_commit": commit}
        if path.exists():
            data = json.loads(path.read_text())
            envelope = json.loads(path.with_name(path.stem + "-final.brackenward").read_text())
            exact = hashlib.sha256(envelope["payload"].encode()).hexdigest()
            entry.update({key: data.get(key) for key in ["canonical_hash", "end_tick", "minimum_health", "starvation_grace_exceeded_ticks", "invariant_checks", "roundtrip_verified", "scenario_pass"]})
            entry["snapshot_exact"] = exact == envelope["sha256"] == data["canonical_hash"]
        clean = not re.search(r"(?m)^(SCRIPT ERROR:|ERROR:|FAIL )", path.with_suffix(".log").read_text())
        entry["pass"] = clean and result.returncode == 0 and entry.get("scenario_pass") is True and entry.get("roundtrip_verified") is True and entry.get("snapshot_exact") is True
        return entry

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        for future in concurrent.futures.as_completed([pool.submit(run, (site, seed)) for site in SITES for seed in SEEDS]):
            summary.append(future.result())
            (reports / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
            print(f"{len(summary)}/30: {summary[-1]['site']} {summary[-1]['seed']} {'PASS' if summary[-1]['pass'] else 'FAILED'}", flush=True)
    final_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip()
    unchanged = final_commit == commit and not subprocess.check_output(["git", "status", "--porcelain"], cwd=source)
    (reports / "completion.json").write_text(json.dumps({"finished_unix": time.time(), "source_unchanged": unchanged,
        "passed": sum(item["pass"] for item in summary), "total": len(summary)}, indent=2) + "\n")
    raise SystemExit(0 if unchanged and audit(reports, commit) else 1)


if __name__ == "__main__":
    main()
