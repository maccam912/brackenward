#!/usr/bin/env python3
"""Continue four audited Charters for 96 additional days using ordinary commands."""
import argparse
import concurrent.futures
import hashlib
import json
from pathlib import Path
import subprocess
import time

from charter_sweep import CASES, SEED, verify


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inputs(directory):
    paths = [directory / name for name in ["source.json", "completion.json", "summary.json", "audit.json"]]
    for site, mode in CASES:
        stem = f"{site}-{mode.lower()}"
        paths.extend(directory / (stem + suffix) for suffix in [".json", ".log", "-initial.brackenward", "-final.brackenward"])
    return {str(path): sha(path) for path in paths}


def origins(directory):
    source = json.loads((directory / "source.json").read_text())
    done = json.loads((directory / "completion.json").read_text())
    audited = json.loads((directory / "audit.json").read_text())
    summary = json.loads((directory / "summary.json").read_text())
    cases = set(CASES)
    valid = (source["days"] == 96 and source["seed"] == SEED and audited["passed"] is True
             and len(source["cases"]) == 4 and {tuple(pair) for pair in source["cases"]} == cases
             and audited["source_commit"] == source["commit"] and done["source_unchanged"] is True
             and done["passed"] == done["total"] == len(summary) == len(audited["rows"]) == 4
             and {(r["site"], r["mode"]) for r in summary} == cases
             and {(r["site"], r["mode"]) for r in audited["rows"]} == cases)
    if not valid: raise ValueError("Need a complete, unchanged, audited four-case 96-day Charter matrix")
    result = []
    for site, mode in CASES:
        path = directory / f"{site}-{mode.lower()}.json"
        old = next(r for r in audited["rows"] if (r["site"], r["mode"]) == (site, mode))
        code = next(r["exit_code"] for r in summary if (r["site"], r["mode"]) == (site, mode))
        row = verify(path, code, site, mode, 96)
        if not row["pass"] or old["pass"] is not True or row["snapshot_sha256"] != old["snapshot_sha256"] or row["canonical_hash"] != old["canonical_hash"]:
            raise ValueError("Starting report/save no longer matches its audited endpoint")
        result.append({"site": site, "mode": mode, "report": str(path), "canonical_hash": row["canonical_hash"], "end_tick": row["end_tick"], "ceremony_end": row["ceremony_end"]})
    return result


def verify_continuation(path, code, origin):
    row = verify(path, code, origin["site"], origin["mode"], 192)
    try:
        prior = json.loads(Path(origin["report"]).read_text())
        result = json.loads(path.read_text())
        source_link = result["source_reports"][-1]
        prefix = result["commands"][:len(prior["commands"])] == prior["commands"]
        initial = path.with_name(path.stem + "-initial.brackenward")
        old_initial = Path(origin["report"]).with_name(Path(origin["report"]).stem + "-initial.brackenward")
        strict = (result["end_tick"] == origin["end_tick"] + 96 * 7200 and origin["end_tick"] > origin["ceremony_end"]
                  and source_link["canonical_hash"] == origin["canonical_hash"] and source_link["end_tick"] == origin["end_tick"]
                  and source_link["path"] == origin["report"] and result["invariant_checks"] == prior["invariant_checks"] + 2304
                  and result["starvation_grace_exceeded_ticks"] == 0 and result["final"]["living"] == 8
                  and len(result["final"]["citizens"]) == 8
                  and all(not p["departed"] for p in result["final"]["citizens"])
                  and result["final"]["food"]["ticks"] >= 7200 and prefix and sha(initial) == sha(old_initial))
        row.update({"continued_from_canonical_hash": origin["canonical_hash"], "additional_ticks": result["end_tick"] - origin["end_tick"], "original_command_prefix_preserved": prefix, "final_food_ticks": result["final"]["food"]["ticks"]})
        row["pass"] = row["pass"] and strict
    except (OSError, ValueError, KeyError, TypeError, IndexError) as error:
        row.update({"pass": False, "error": str(error)})
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--input-directory", required=True, type=Path)
    parser.add_argument("--report-dir", required=True, type=Path)
    parser.add_argument("--workers", type=int, choices=[1, 2], default=2)
    parser.add_argument("--audit", action="store_true")
    args = parser.parse_args()
    source, incoming, reports = args.source.resolve(), args.input_directory.resolve(), args.report_dir.resolve()
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip()
    if subprocess.check_output(["git", "status", "--porcelain"], cwd=source): parser.error("Source must stay clean and frozen")
    if reports == incoming or reports.is_relative_to(incoming): parser.error("Keep continuation output outside the original evidence")
    try:
        start = origins(incoming)
        before = inputs(incoming)
    except (OSError, ValueError, KeyError, TypeError, StopIteration) as error:
        parser.error(str(error))
    if args.audit:
        provenance = json.loads((reports / "source.json").read_text())
        done = json.loads((reports / "completion.json").read_text())
        summary = json.loads((reports / "summary.json").read_text())
        rows = [verify_continuation(reports / f"{r['site']}-{r['mode'].lower()}.json", next((x["exit_code"] for x in summary if (x["site"], x["mode"]) == (r["site"], r["mode"])), None), r) for r in start]
        passed = (provenance["commit"] == commit and provenance["additional_days"] == 96 and provenance["inputs_sha256"] == before and provenance["origins"] == start
                  and done["source_unchanged"] is True and done["inputs_unchanged"] is True and len(summary) == 4
                  and {(r["site"], r["mode"]) for r in summary} == set(CASES) and all(r["pass"] for r in rows) and before == inputs(incoming))
        result = {"passed": passed, "source_commit": commit, "rows": rows, "audit_tool_sha256": sha(Path(__file__))}
        (reports / "audit.json").write_text(json.dumps(result, indent=2) + "\n")
        print(json.dumps({"passed": passed, "cases": len(rows)}));raise SystemExit(0 if passed else 1)
    reports.mkdir(parents=True, exist_ok=True)
    if any(reports.iterdir()): parser.error("Use a new empty report directory")
    (reports / "source.json").write_text(json.dumps({"commit": commit, "source": str(source), "additional_days": 96, "origins": start, "inputs_sha256": before, "started_unix": time.time(), "workers": args.workers, "harness_sha256": sha(Path(__file__))}, indent=2) + "\n")

    def run(origin):
        path = reports / f"{origin['site']}-{origin['mode'].lower()}.json"
        try:
            with path.with_suffix(".log").open("w") as log:
                process = subprocess.run([str(source / "tools/godot.sh"), "--headless", "--script", "tools/simulate.gd", "--", "--scenario", "vegetarian_charter", "--seed", str(SEED), "--site", origin["site"], "--mode", origin["mode"], "--days", "96", "--resume", origin["report"], "--report", str(path)], cwd=source, stdout=log, stderr=subprocess.STDOUT, timeout=14400)
            return verify_continuation(path, process.returncode, origin)
        except subprocess.TimeoutExpired:
            return {"site": origin["site"], "mode": origin["mode"], "exit_code": None, "pass": False, "error": "Four-hour bound; partial evidence retained"}

    summary = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        for future in concurrent.futures.as_completed([pool.submit(run, row) for row in start]):
            summary.append(future.result())
            (reports / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
            row = summary[-1]
            print(f"{len(summary)}/4: {row['site']} {row['mode']} {'PASS' if row['pass'] else 'FAILED'}", flush=True)
    unchanged = commit == subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip() and not subprocess.check_output(["git", "status", "--porcelain"], cwd=source)
    input_unchanged = before == inputs(incoming)
    (reports / "completion.json").write_text(json.dumps({"source_unchanged": unchanged, "inputs_unchanged": input_unchanged, "finished_unix": time.time(), "total": len(summary), "passed": sum(r["pass"] for r in summary)}, indent=2) + "\n")
    raise SystemExit(0 if unchanged and input_unchanged and all(r["pass"] for r in summary) else 1)


if __name__ == "__main__":
    main()
