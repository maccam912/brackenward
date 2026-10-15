#!/usr/bin/env python3
"""Export and independently validate frozen three-site generation case ranges."""
import argparse
import concurrent.futures
import hashlib
import json
from pathlib import Path
import re
import subprocess
import threading
import time

from validate_raw_map import exported

SITES = ["meadow_reach", "pine_shelf", "reed_bend"]
GOLDEN_SEEDS = [0, 1, 42, 104729, 2147483647, 4294967295]
BATCH = 256
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")


def seed(index):
    return GOLDEN_SEEDS[index] if index < 6 else int.from_bytes(hashlib.sha256(f"brackenward-map-sweep-v1|{index}".encode()).digest()[:4], "big")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(source, *args):
    return subprocess.check_output(["git", *args], cwd=source, text=True).strip()


def fingerprints(source):
    return {name: sha(source / name) for name in ["tools/export_map_batch.gd", "tools/map_sweep.py", "tools/validate_raw_map.py", "src/generation/colony_generation.gd", "src/sim/colony_world.gd", "src/sim/colony_catalog.gd", catalog_path(source), "tools/godot.sh", "toolchain.lock.json"]}


def catalog_path(source):
    matches = re.findall(r'(?m)^const CONTENT_VERSION: String = "(colony-v[1-9][0-9]*)"$', (source / "src/sim/colony_world.gd").read_text())
    if len(matches) != 1: raise ValueError("Cannot identify exact content version")
    return "data/catalogs/" + matches[0].replace("-", "_") + ".json"


def load_catalog(source):
    path = catalog_path(source)
    catalog = json.loads((source / path).read_text())
    if catalog.get("version") != Path(path).stem.replace("_", "-"):
        raise ValueError("Catalog does not match the declared content version")
    return catalog


def generator_revision(source):
    matches = re.findall(r"(?m)^const VERSION: int = (\d+)$", (source / "src/generation/colony_generation.gd").read_text())
    if len(matches) != 1: raise ValueError("Cannot identify exact generator revision")
    return int(matches[0])


def ranges(start, count):
    return [(site, first, min(BATCH, start+count-first)) for first in range(start, start+count, BATCH) for site in SITES]


def coverage(geometry, start, count, fallback):
    full = start == 0 and count == 10000
    budget = all(n*1000 < count for n in fallback.values()) if full else None
    passed = bool(geometry and (not full or budget))
    return {"passed": passed, "geometry_pass": bool(geometry), "release_generation_gate_pass": passed and full,
            "full_10000_per_site": full, "fallback_budget_pass": budget}


def audit(source, reports, commit):
    try:
        original = json.loads((reports / "source.json").read_text())
        done = json.loads((reports / "completion.json").read_text())
        shards = json.loads((reports / "summary.json").read_text())
        expected = set(ranges(original["start"], original["count"]))
        valid = (original["commit"] == commit and original["tools_sha256"] == fingerprints(source)
                 and original["generator_version"] == generator_revision(source)
                 and original["sites"] == SITES and original["seed_algorithm"] == "brackenward-map-sweep-v1"
                 and done["source_unchanged"] is True and len(shards) == len(expected)
                 and {(s["site"], s["start"], s["count"]) for s in shards} == expected)
        seen, seeds = set(), {site: set() for site in SITES}
        fallback = {site: 0 for site in SITES}
        attempts = {site: {} for site in SITES}
        minimum_safe, minimum_food = 16384, 1000000
        for shard in shards:
            stem = f"{shard['site']}-{shard['start']:05d}-{shard['start']+shard['count']-1:05d}"
            cases = reports / (stem + ".jsonl")
            log = reports / (stem + ".log")
            clean = not re.search(r"(?m)^(SCRIPT ERROR:|ERROR:|FAIL )", ANSI.sub("", log.read_text()))
            valid = valid and shard["exit_code"] == 0 and shard["pass"] is True and clean and sha(cases) == shard["cases_sha256"] and sha(log) == shard["log_sha256"]
            rows = [json.loads(line) for line in cases.read_text().splitlines()]
            valid = valid and len(rows) == shard["count"]
            for offset, row in enumerate(rows):
                key = (shard["site"], shard["start"]+offset)
                metrics = row["metrics"]
                valid = valid and key not in seen and (row["site"], row["index"]) == key and row["seed"] == seed(key[1]) and row["seed"] not in seeds[key[0]]
                valid = valid and row["generator_version"] == original["generator_version"]
                valid = valid and metrics["passed"] is True and metrics["errors"] == [] and metrics["safe_buildable"] >= 1024 and metrics["wild_food_units"] >= 40
                valid = valid and re.fullmatch(r"[0-9a-f]{64}", row["map_sha256"]) is not None and type(row["attempt"]) is int and 0 <= row["attempt"] <= 32 and type(row["fallback"]) is bool and row["fallback"] == (row["attempt"] == 32)
                if key[1] < 6:
                    raw = reports / "raw" / f"{key[0]}-{key[1]:05d}.json"
                    valid = valid and sha(raw) == row["map_sha256"] and re.fullmatch(r"[0-9a-f]{64}", row["canonical_hash"]) is not None
                seen.add(key);seeds[key[0]].add(row["seed"])
                fallback[key[0]] += int(row["fallback"])
                attempts[key[0]][str(row["attempt"])] = attempts[key[0]].get(str(row["attempt"]), 0)+1
                minimum_safe = min(minimum_safe, metrics["safe_buildable"])
                minimum_food = min(minimum_food, metrics["wild_food_units"])
        valid = valid and len(seen) == done["processed"] == done["passed"] == 3*original["count"] and all(len(s) == original["count"] for s in seeds.values())
        return {**coverage(valid, original["start"], original["count"], fallback),
                "source_commit": commit, "cases": len(seen), "fallback_counts": fallback,
                "attempt_counts": attempts, "minimum_safe_buildable": minimum_safe, "minimum_wild_food_units": minimum_food,
                "audit_tool_sha256": sha(Path(__file__)), "scope": "Independent exported-map geometry/quantity audit only. Physical play, balance, saves and other release gates remain separate."}
    except (OSError, ValueError, KeyError, TypeError, IndexError) as error:
        return {"passed": False, "release_generation_gate_pass": False, "error": str(error), "audit_tool_sha256": sha(Path(__file__))}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--report-dir", type=Path, required=True)
    parser.add_argument("--start", type=int, default=6)
    parser.add_argument("--count", type=int, default=256)
    parser.add_argument("--workers", type=int, choices=[1, 2, 4, 8], default=2)
    parser.add_argument("--audit", action="store_true")
    args = parser.parse_args()
    source, reports = args.source.resolve(), args.report_dir.resolve()
    if Path(__file__).resolve() != source / "tools/map_sweep.py": parser.error("Execute this runner from the frozen source checkout")
    commit = git(source, "rev-parse", "HEAD")
    if git(source, "status", "--porcelain"): parser.error("Source must be clean and remain frozen")
    if not 0 <= args.start < 10000 or not 1 <= args.count <= 10000-args.start: parser.error("Case range must fit 0..9999")
    if args.audit:
        if json.loads((reports / "source.json").read_text())["commit"] != commit: parser.error("Audit the exact recorded source commit; old evidence retained")
        result = audit(source, reports, commit)
        (reports / "audit.json").write_text(json.dumps(result, indent=2)+"\n")
        print(json.dumps(result));raise SystemExit(0 if result["passed"] else 1)
    if len({seed(i) for i in range(args.start, args.start+args.count)}) != args.count: parser.error("Seed sequence contains a duplicate")
    reports.mkdir(parents=True, exist_ok=True)
    if any(reports.iterdir()): parser.error("Use a new empty report directory")
    (reports / ".gdignore").write_text("")
    (reports / "raw").mkdir()
    before = fingerprints(source)
    catalog = load_catalog(source)
    catalog_hash = hashlib.sha256(json.dumps(catalog, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest()
    revision = generator_revision(source)
    (reports / "source.json").write_text(json.dumps({"commit": commit, "source": str(source), "generator_version": revision, "start": args.start, "count": args.count, "sites": SITES, "workers": args.workers, "seed_algorithm": "brackenward-map-sweep-v1", "tools_sha256": before, "catalog_hash": catalog_hash, "started_unix": time.time()}, indent=2)+"\n")
    stop = threading.Event()
    lock = threading.Lock()
    progress = {"processed": 0, "passed": 0, "requested": 3*args.count}

    def run(case):
        site, first, count = case
        stem = f"{site}-{first:05d}-{first+count-1:05d}"
        cases, log = reports / (stem+".jsonl"), reports / (stem+".log")
        code, errors, processed = None, [], 0
        with cases.open("x") as output, log.open("x") as diagnostic:
            if stop.is_set(): errors.append("Stopped after another shard failed")
            else:
                process = subprocess.Popen([str(source / "tools/godot.sh"), "--headless", "--script", "tools/export_map_batch.gd", "--", site, str(first), str(count)], cwd=source, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                timed_out = threading.Event()
                def kill_timed_out():
                    timed_out.set();process.kill()
                timeout = threading.Timer(max(120, count*3), kill_timed_out)
                timeout.start()
                try:
                    for line in process.stdout:
                        if stop.is_set(): errors.append("Stopped after another shard failed");break
                        if not line.startswith("GENMAP "):
                            diagnostic.write(line);diagnostic.flush()
                            if re.search(r"^(SCRIPT ERROR:|ERROR:|FAIL )", ANSI.sub("", line)): errors.append("Godot script/engine error");break
                            continue
                        data, envelope, metrics = exported(line, catalog)
                        expected_index = first+processed
                        if data["site"] != site or data["index"] != expected_index or data["seed"] != seed(expected_index) or data["content_hash"] != catalog_hash or data["generator"] != revision: raise ValueError("Exported case/catalog/generator identity mismatch")
                        if type(envelope["generation_us"]) is not int or envelope["generation_us"] <= 0: raise ValueError("Missing generation timing")
                        if expected_index < 6 or not metrics["passed"]:
                            (reports / "raw" / f"{site}-{expected_index:05d}.json").write_text(envelope["payload"])
                        row = {"site": site, "index": expected_index, "seed": data["seed"], "generator_version": revision, "attempt": data["attempt"], "fallback": data["fallback"], "map_sha256": envelope["sha256"], "canonical_hash": envelope["canonical_hash"], "generation_us": envelope["generation_us"], "metrics": metrics}
                        output.write(json.dumps(row, sort_keys=True)+"\n");output.flush();processed += 1
                        with lock:
                            progress["processed"] += 1;progress["passed"] += int(metrics["passed"])
                            if progress["processed"] % 32 == 0 or not metrics["passed"]:
                                (reports / "progress.json").write_text(json.dumps(progress, indent=2)+"\n")
                                print(f"{progress['processed']}/{progress['requested']}: {site}/{data['seed']} {'PASS' if metrics['passed'] else metrics['errors']}", flush=True)
                        if not metrics["passed"]: errors.extend(metrics["errors"]);break
                except (OSError, ValueError, KeyError, TypeError) as error:
                    errors.append(str(error))
                finally:
                    if errors and process.poll() is None: process.terminate()
                    try: code = process.wait(timeout=10)
                    except subprocess.TimeoutExpired: process.kill();code = process.wait()
                    timeout.cancel()
                    if timed_out.is_set(): errors.append("Generation shard exceeded its bounded timeout")
        passed = code == 0 and processed == count and not errors
        if not passed: stop.set()
        return {"site": site, "start": first, "count": count, "processed": processed, "exit_code": code, "pass": passed, "errors": errors, "cases_sha256": sha(cases), "log_sha256": sha(log)}

    summary = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        for future in concurrent.futures.as_completed([pool.submit(run, case) for case in ranges(args.start, args.count)]):
            summary.append(future.result())
            (reports / "summary.json").write_text(json.dumps(summary, indent=2)+"\n")
    unchanged = commit == git(source, "rev-parse", "HEAD") and not git(source, "status", "--porcelain") and before == fingerprints(source)
    (reports / "completion.json").write_text(json.dumps({"source_unchanged": unchanged, "processed": progress["processed"], "passed": progress["passed"], "finished_unix": time.time()}, indent=2)+"\n")
    result = audit(source, reports, commit)
    (reports / "audit.json").write_text(json.dumps(result, indent=2)+"\n")
    print(json.dumps(result));raise SystemExit(0 if result["passed"] else 1)


if __name__ == "__main__":
    main()
