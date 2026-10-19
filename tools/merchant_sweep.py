#!/usr/bin/env python3
"""Run/audit imported-cloth economies using only ordinary play from frozen source."""
import argparse
import concurrent.futures
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time

CASES = [(site, "Standard") for site in ("meadow_reach", "pine_shelf", "reed_bend")] + [("pine_shelf", "Hearthside")]
SEED, DAYS = 104729, 24


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result: raise ValueError("Duplicate JSON key")
            result[key] = value
        return result
    return json.loads(path.read_text(), object_pairs_hook=unique)


def snapshot(path):
    envelope = read(path)
    if envelope["format"] != "brackenward-development-colony" or envelope["version"] != 5 or hashlib.sha256(envelope["payload"].encode()).hexdigest() != envelope["sha256"]:
        raise ValueError("Snapshot envelope/checksum differs")
    return envelope, json.loads(envelope["payload"])


def initial_hash(initial, mode, golden=None):
    normalized = dict(initial)
    if golden is not None:
        directory = Path(__file__).resolve().parents[1] / "data/catalogs"
        original = read(directory / "colony_v6.json")
        if golden["content"] != "colony-v6" or initial["content"] not in ("colony-v6", "colony-v7", "colony-v8", "colony-v9", "colony-v10", "colony-v11", "colony-v12", "colony-v13", "colony-v14"):
            raise ValueError("Unsupported inspected content headers")
        current = read(directory / (initial["content"].replace("-", "_") + ".json"))
        digest = lambda value: hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()
        # Only initial-map identity is compared here, never future crop balance.
        comparable = json.loads(json.dumps(current))
        if initial["content"] == "colony-v14":
            additions = {
                "items": {"id": "wheelbarrow", "name_key": "wheelbarrow.name", "description_key": "wheelbarrow.description", "icon_id": "wheelbarrow", "schema_version": 1, "stack_limit": 1, "fullness": 0, "tags": [], "shelf_ticks": 0, "barter_value": 8},
                "recipes": {"id": "make_wheelbarrow", "name_key": "make_wheelbarrow.name", "description_key": "make_wheelbarrow.description", "icon_id": "make_wheelbarrow", "schema_version": 1, "station": "workbench", "alternatives": [], "food_count": 0, "materials": {"wood": 6}, "outputs": {"wheelbarrow": 1}, "work_milli": 14000, "skill": "Craft", "unlock": "wheelbarrows"},
                "research": {"id": "wheelbarrows", "name_key": "wheelbarrows.name", "description_key": "wheelbarrows.description", "icon_id": "wheelbarrows", "schema_version": 1, "points": 1440, "prerequisites": [], "unlocks": ["recipe:make_wheelbarrow"]},
            }
            for section, expected in additions.items():
                if [entry for entry in comparable[section] if entry["id"] == expected["id"]] != [expected]:
                    raise ValueError("Unexpected v14 wheelbarrow definition")
                comparable[section].remove(expected)
        if initial["content"] in ("colony-v13", "colony-v14"):
            previous = read(directory / "colony_v12.json")
            for entry, old in zip(comparable["research"], previous["research"]):
                if entry["id"] != old["id"] or entry["points"] != old["points"] * 6:
                    raise ValueError("Unexpected v13 research cost")
                entry["points"] = old["points"]
        if initial["content"] in ("colony-v8", "colony-v9", "colony-v10", "colony-v11", "colony-v12", "colony-v13", "colony-v14"):
            turnip = next(c for c in comparable["crops"] if c["id"] == "turnip")
            if turnip["growth"] != 4000:
                raise ValueError("Unexpected v8 turnip duration")
            turnip["growth"] = 2000
        if (digest(original) != golden["catalog_sha256"] or digest(current) != initial["content_hash"]
                or {k: v for k, v in comparable.items() if k != "version"} != {k: v for k, v in original.items() if k != "version"}):
            raise ValueError("Inspected catalog definitions or exact headers differ")
        normalized["content"], normalized["content_hash"] = golden["content"], golden["catalog_sha256"]
        if initial["content"] in ("colony-v10", "colony-v11", "colony-v12", "colony-v13", "colony-v14"):
            if initial.get("schema_revision") != (25 if initial["content"] == "colony-v14" else 24):
                raise ValueError("Unexpected inspected schema revision")
            normalized["schema_revision"] = 23
        if initial["content"] in ("colony-v9", "colony-v10", "colony-v11", "colony-v12", "colony-v13", "colony-v14"):
            normalized["citizens"] = json.loads(json.dumps(initial["citizens"]))
            for person in normalized["citizens"]:
                if person.get("preferences", {}).get("Hauling") != 1:
                    raise ValueError("Unexpected v9 starting Hauling preference")
                person["preferences"]["Hauling"] = 2
        if initial["content"] == "colony-v14":
            normalized = json.loads(json.dumps(normalized))
            for person in normalized["citizens"]:
                if person["equipment"].pop("transport") != "":
                    raise ValueError("Unexpected v14 starting transport")
            for _, equipment in normalized["equipment_state"]["$map"]:
                if equipment.pop("transport") != {"replacements": True, "upgrades": False, "preferred": ""}:
                    raise ValueError("Unexpected v14 starting transport policy")
            for store in normalized["stores"]:
                if store["filters"].count("wheelbarrow") != 1:
                    raise ValueError("Unexpected v14 starting store filter")
                store["filters"].remove("wheelbarrow")
    if mode == "Hearthside":
        expected = [{"id": "1", "session": "m1-test", "kind": "care_mode", "args": {"mode": "Hearthside"}}]
        if initial["pending_commands"] != expected or initial["next_command_id"] != "2":
            raise ValueError("Initial Hearthside preset differs")
        normalized["pending_commands"], normalized["next_command_id"] = [], "1"
    elif mode != "Standard" or initial["pending_commands"] or initial["next_command_id"] != "1":
        raise ValueError("Initial Standard command state differs")
    return hashlib.sha256(json.dumps(normalized, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()


def economy_checks(report, world, initial):
    exchanges = world["trade_state"]["exchanges"]
    purchases = [e for e in exchanges if not e["delivery"]]
    deliveries = [e for e in exchanges if e["delivery"]]
    merchants = {int(e["id"]): e for e in world["trade_state"]["merchants"]}
    jobs = {int(j["id"]): j for j in world["jobs"]}
    sewn = [j for j in world["jobs"] if j["kind"] == "craft" and j["definition"] == "sew_cloak" and j["state"] == "Complete"]
    receipts = {int(k): v for k, v in world["receipts"]["$map"]}
    trace = [e["command"] for e in report["commands"]]
    all_commands = trace + world["pending_commands"]
    decisions = [{k: d[k] for k in ("id", "kind", "args")} for d in report["policy_decisions"]]
    planned = [{k: c[k] for k in ("id", "kind", "args")} for c in all_commands if c["kind"] != "care_mode"]
    trades = [c for c in all_commands if c["kind"] == "trade"]
    ledger = world["ledger"]
    imported = ledger["traded_in"].get("cloth", 0)
    consumed = ledger["consumed"].get("cloth", 0)
    checks = {
        "initial_cloth_absent": sum(s["count"] for s in initial["stacks"] if s["item"] == "cloth") == 0,
        "two_distinct_riverward_purchases": len(purchases) == 2 and len({int(e["merchant"]) for e in purchases}) == 2 and all(e["community"] == "riverward" and e["buy"] == {"cloth": 8} and e["pay"] == {"wood": 40} and e["gift"] == 0 for e in purchases),
        "one_road_cloak_delivery": len(deliveries) == 1 and deliveries[0]["community"] == "road_fellowship" and deliveries[0]["pay"] == {"cloak": 3} and deliveries[0]["buy"] == {},
        "all_payments_physically_committed": len(exchanges) == 3 and all(e["state"] == "Complete" and int(e["receipt"]) > 0 and jobs[int(e["job"])]["kind"] == "trade" and jobs[int(e["job"])]["state"] == "Complete" for e in exchanges),
        "purchases_within_actual_cart_stay": all(int(merchants[int(e["merchant"])]["deadline"]) - 7200 <= int(e["receipt"]) < int(merchants[int(e["merchant"])]["deadline"]) and any(v in (0, 127) for v in merchants[int(e["merchant"])]["entry"]["$tile"]) for e in purchases),
        "imported_cloth_is_only_source": imported == 16 and all(ledger[k].get("cloth", 0) == 0 for k in ("produced", "recovered", "expedition_gain")),
        "cloth_conservation_and_real_sewing": consumed >= 6 and len(sewn) >= 3 and imported - consumed == sum(s["count"] for s in world["stacks"] if s["item"] == "cloth") and all(ledger[k].get("cloth", 0) == 0 for k in ("spoiled", "lost", "traded_out", "looted")),
        "exact_payment_and_reputation": ledger["traded_out"].get("wood", 0) >= 80 and ledger["traded_out"].get("cloak", 0) == 3 and world["trade_state"]["reputation"]["road_fellowship"] == min(100, 30 + 3 * sum(e["treated"] for e in world["defense_state"]["enemies"])),
        "no_local_weaving_or_expedition_substitute": not any(f["crop"] == "flax" for f in world["fields"]) and not any(o["recipe"] == "weave_cloth" for o in world["production_state"]["orders"]) and world["region_state"]["trips"] == [] and all(int(o["receipt"]) == 0 for o in world["opportunity_state"]["offers"]),
        "three_accepted_public_trade_commands": len(trades) == 3 and all(receipts[int(c["id"])] == "accepted" for c in trades) and not any(c["kind"] == "trade_cancel" for c in all_commands),
        "planner_decisions_match_all_public_commands": planned == decisions,
        "only_requested_care_mode": [c["args"] for c in all_commands if c["kind"] == "care_mode"] == ([{"mode": "Hearthside"}] if report.get("mode") == "Hearthside" else []),
        "eight_living_equipped_residents": len(world["citizens"]) == 8 and all(not c["death_recorded"] and not c["departed"] and c["equipment"]["cloak"] == "cloak" for c in world["citizens"]),
        "no_starvation_and_final_food_day": report["zero_fullness_ticks"] == report["starvation_grace_exceeded_ticks"] == 0 and report["final"]["food"]["ticks"] >= 7200,
    }
    return checks


def verify(path, code, site, mode):
    row = {"site": site, "mode": mode, "seed": SEED, "exit_code": code, "pass": False}
    try:
        report = read(path)
        envelope, world = snapshot(path.with_name(path.stem + "-final.brackenward"))
        _, initial = snapshot(path.with_name(path.stem + "-initial.brackenward"))
        checks = economy_checks(report, world, initial)
        golden = read(Path(__file__).resolve().parents[1] / "tests/fixtures/generation-v2-goldens.json")
        expected = next(r["canonical_hash"] for r in golden["maps"] if r["site"] == site and r["seed"] == SEED)
        checks["complete_initial_payload_matches_inspected_boundary"] = initial_hash(initial, mode, golden) == expected
        clean = not re.search(r"(?m)^\s*(SCRIPT ERROR:|ERROR:|FATAL:|FAIL )", path.with_suffix(".log").read_text())
        checks["complete_ordinary_scenario"] = (code == 0 and clean and report["scenario"] == "merchant_economy" and report["ordinary_play_only"] is True and report["roundtrip_verified"] is True and report["scenario_pass"] is True and report["invariant_failure"] == "" and report["site"] == world["site_id"] == initial["site_id"] == site and report["mode"] == world["care_state"]["mode"] == mode and report["seed"] == int(world["seed"]) == int(initial["seed"]) == SEED and report["generator_version"] == world["generator_version"] == initial["generator_version"] == 2 and report["start_tick"] == int(initial["tick"]) == 1800 and report["end_tick"] == int(world["tick"]) == 1800 + DAYS * 7200 and len(initial["citizens"]) == 4 and report["invariant_checks"] == DAYS * 24 and envelope["sha256"] == report["canonical_hash"])
        row.update({"pass": all(checks.values()), "checks": checks, "canonical_hash": report["canonical_hash"], "minimum_health": report["minimum_health"], "final_food_ticks": report["final"]["food"]["ticks"], "economy": report["merchant_economy"], "final_snapshot_sha256": sha(path.with_name(path.stem + "-final.brackenward"))})
    except (OSError, ValueError, KeyError, TypeError, IndexError, StopIteration) as error:
        row["error"] = str(error)
    return row


def audit(reports, commit):
    source, completion, summary = (read(reports / name) for name in ("source.json", "completion.json", "summary.json"))
    rows = [verify(reports / f"{site}-{mode.lower()}.json", next((r["exit_code"] for r in summary if (r["site"], r["mode"]) == (site, mode)), None), site, mode) for site, mode in CASES]
    provenance = source["harness_sha256"] == sha(Path(__file__)) and source["initial_golden_sha256"] == sha(Path(__file__).resolve().parents[1] / "tests/fixtures/generation-v2-goldens.json") and source["commit"] == commit and source["days"] == DAYS and source["seed"] == SEED and source["cases"] == [list(c) for c in CASES] and completion["source_unchanged"] is True and completion["total"] == completion["passed"] == len(summary) == 4 and {(r["site"], r["mode"]) for r in summary} == set(CASES)
    return {"passed": provenance and all(r["pass"] for r in rows), "source_commit": commit, "rows": rows, "audit_tool_sha256": sha(Path(__file__)), "scope": "24-day ordinary imported-cloth economies on fresh generator-2 maps. Synthetic unit setups and physical/human gates are separate."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--report-dir", type=Path, required=True)
    parser.add_argument("--workers", type=int, choices=(1, 2), default=2)
    parser.add_argument("--audit", action="store_true")
    args = parser.parse_args()
    source, reports = args.source.resolve(), args.report_dir.resolve()
    if source != Path(__file__).resolve().parents[1]: parser.error("Run this tool from the same frozen source checkout")
    def git(*parts): return subprocess.check_output(["git", *parts], cwd=source, text=True).strip()
    commit = git("rev-parse", "HEAD")
    if git("status", "--porcelain"): parser.error("Source must stay clean and frozen through completion and audit")
    if not args.audit:
        reports.mkdir(parents=True, exist_ok=True)
        if any(reports.iterdir()): parser.error("Use a new empty report directory")
        (reports / ".gitignore").write_text("*\n")
        (reports / ".gdignore").touch()
        (reports / "source.json").write_text(json.dumps({"commit": commit, "source": str(source), "days": DAYS, "seed": SEED, "cases": CASES, "workers": args.workers, "started_unix": time.time(), "harness_sha256": sha(Path(__file__)), "initial_golden_sha256": sha(source / "tests/fixtures/generation-v2-goldens.json")}, indent=2) + "\n")
        def run(case):
            site, mode = case
            stem = f"{site}-{mode.lower()}"
            code, error = None, ""
            try:
                with (reports / (stem + ".log")).open("w") as log:
                    process = subprocess.run([str(source / "tools/godot.sh"), "--headless", "--script", "tools/simulate.gd", "--", "--scenario", "merchant_economy", "--seed", str(SEED), "--site", site, "--mode", mode, "--days", str(DAYS), "--report", str(reports / (stem + ".json"))], cwd=source, stdout=log, stderr=subprocess.STDOUT, timeout=7200)
                    code = process.returncode
            except subprocess.TimeoutExpired:
                error = "Two-hour case bound; partial evidence retained"
            return {"site": site, "mode": mode, "exit_code": code, "error": error}
        summary = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
            for future in concurrent.futures.as_completed([pool.submit(run, case) for case in CASES]):
                row = future.result();summary.append(row)
                (reports / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
                print(f"{len(summary)}/4: {row['site']} {row['mode']} exit {row['exit_code']}", flush=True)
        (reports / "completion.json").write_text(json.dumps({"source_unchanged": git("rev-parse", "HEAD") == commit and not git("status", "--porcelain"), "finished_unix": time.time(), "total": len(summary), "passed": sum(r["exit_code"] == 0 for r in summary)}, indent=2) + "\n")
    try:
        result = audit(reports, commit)
    except (OSError, ValueError, KeyError, TypeError) as error:
        result = {"passed": False, "error": str(error), "source_commit": commit}
    (reports / "audit.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({k: v for k, v in result.items() if k != "rows"}))
    raise SystemExit(0 if result["passed"] else 1)


if __name__ == "__main__":
    main()
