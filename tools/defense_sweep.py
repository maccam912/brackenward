#!/usr/bin/env python3
"""Paired prepared raid solutions on 30 maps; never ordinary incident-frequency proof."""
import argparse
import concurrent.futures
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time

from validate_raw_map import validate as validate_map, distances, tile, footprint

SEEDS = [0, 1, 42, 104729, 2147483647, 4294967295, 73, 4567, 1357911, 3000000001]
SITES = ["meadow_reach", "pine_shelf", "reed_bend"]
CASES = [(site, seed) for site in SITES for seed in SEEDS]


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


def raw_geometry(normal):
    """Translate the saved geography to the independent raw-map validator's ABI."""
    terrain = normal["terrain_state"]
    data = {"format": "brackenward-raw-map", "version": 1, "seed": int(normal["seed"]), "site": normal["site_id"], "generator": normal["generator_version"], "weather": normal["weather"], **{k: terrain[k] for k in ("transform", "attempt", "fallback", "diagnostics", "elevation", "fertility")}}
    for name in ("paths", "bridges", "starter_field"):
        data[name] = [v["$tile"] for v in terrain[name]]
    data["habitats"] = {k: [v["$tile"] for v in values] for k, values in terrain["habitats"].items()}
    for name, records, keys in (("resources", normal["resources"], ("id", "definition", "x", "y", "remaining")), ("structures", normal["structures"], ("id", "definition", "x", "y", "rotation", "health", "user")), ("citizens", normal["citizens"], ("id", "x", "y", "bed")), ("animals", normal["wildlife_state"]["animals"], ("id", "definition", "x", "y"))):
        data[name] = [{k: int(r[k]) if k in ("id", "bed") else r[k] for k in keys} for r in records]
    data["regions"] = normal["region_state"]["nodes"]
    return data


def geometry(normal):
    catalog = read(Path(__file__).resolve().parents[1] / "data/catalogs/colony_v6.json")
    return validate_map(raw_geometry(normal), catalog)


def route_valid(points, entry, cart, rally, elevations, solid, bridges):
    if len(points) < 30 or len(points) != len(set(points)) or points[-1] != cart or rally != points[len(points) // 2]: return False
    walked = [entry] + points
    reached = distances(entry, elevations, solid, bridges)
    if reached.get(cart) != len(points): return False
    return all(b in reached and abs(a[0]-b[0])+abs(a[1]-b[1]) == 1 and (a in bridges or b in bridges or abs(elevations[a[1]*128+a[0]]-elevations[b[1]*128+b[0]]) <= 1) for a, b in zip(walked, walked[1:]))


def interception(normal, row, entry):
    data = raw_geometry(normal)
    catalog = read(Path(__file__).resolve().parents[1] / "data/catalogs/colony_v6.json")
    resources = {r["id"]: r for r in catalog["resources"]};buildings = {b["id"]: b for b in catalog["buildings"]}
    solid = {(r["x"], r["y"]) for r in data["resources"] if resources[r["definition"]]["solid"]}
    for building in data["structures"]:
        if building["definition"] != "supply_cart" and buildings[building["definition"]]["solid"]: solid |= footprint(building, buildings)
    cart = next(s for s in data["structures"] if s["definition"] == "supply_cart")
    return route_valid([tile(v["$tile"]) for v in row["approach_route"]], tile(entry["$tile"]), (cart["x"], cart["y"]), tile(row["rally"]["$tile"]), data["elevation"], solid, {tile(p) for p in data["bridges"]})


def setup_checks(normal, prepared):
    changed = {k for k in normal.keys() | prepared.keys() if normal.get(k) != prepared.get(k)}
    raids = prepared["defense_state"]["raids"]
    raid = raids[0] if len(raids) == 1 else {}
    stable_defense = {k: v for k, v in normal["defense_state"].items() if k not in ("rng", "raids")}
    prepared_stable = {k: v for k, v in prepared["defense_state"].items() if k not in ("rng", "raids")}
    old_story, new_story = normal["chronicle_state"], prepared["chronicle_state"]
    return {
        "only_one_explicit_announcement_changes_initial_state": changed == {"next_id", "defense_state", "facts", "chronicle_state"} and int(prepared["next_id"]) == int(normal["next_id"]) + 1 and stable_defense == prepared_stable and not normal["defense_state"]["raids"] and not normal["defense_state"]["enemies"],
        "full_24_hour_warning_with_fixed_two_thief_party": bool(raid) and int(raid["id"]) == int(normal["next_id"]) and raid["state"] == "Announced" and raid["budget"] == 2 and raid["party"] == ["hungry_thief", "hungry_thief"] and int(raid["due"]) == 9000 and int(raid["arrival"]) == 0 and raid["actors"] == [] and raid["route_blocked"] is False and any(v in (0, 127) for v in raid["entry"]["$tile"]),
        "only_one_actual_warning_fact": len(prepared["facts"]) == len(normal["facts"]) + 1 and prepared["facts"][:-1] == normal["facts"] and prepared["facts"][-1]["kind"] == "raid_warning" and int(prepared["facts"][-1]["tick"]) == 1800 and new_story["facts"][:-1] == old_story["facts"] and len(new_story["facts"]) == len(old_story["facts"]) + 1 and new_story["facts"][-1]["kind"] == "raid_warning" and int(new_story["next_event_id"]) == int(old_story["next_event_id"]) + 1 and all(new_story[k] == v for k, v in old_story.items() if k not in ("facts", "next_event_id")),
        "normal_starting_four_with_original_weapons_and_supplies": len(normal["citizens"]) == 4 and [c["equipment"]["weapon"] for c in normal["citizens"]] == ["spear", "bow", "bow", "spear"] and int(normal["tick"]) == int(prepared["tick"]) == 1800 and normal["pending_commands"] == [] and normal["care_state"]["mode"] == "Standard",
    }


def branch_checks(row, world, walking, announced_hash, action):
    raid = world["defense_state"]["raids"][0]
    enemies = world["defense_state"]["enemies"]
    receipts = {int(k): v for k, v in world["receipts"]["$map"]}
    decisions = row["decisions"]
    trace = row["commands"]
    paid = world["ledger"]["traded_out"].get("wood", 0)
    retreat = row["first_retreat"]
    expected = ["shelter", "draft", "stand_down"] if action == "defend" else ["raid_offer", "stand_down"]
    plan = [{k: d[k] for k in ("id", "kind", "args")} for d in decisions]
    applied = [{k: e["command"][k] for k in ("id", "kind", "args")} for e in trace]
    checks = {
        "same_announced_input": row["initial_canonical_hash"] == announced_hash,
        "resolved_same_party_after_normal_boundary_arrival": len(world["defense_state"]["raids"]) == 1 and raid == row["raid"] and raid["state"] == "Resolved" and int(raid["arrival"]) == int(raid["due"]) == 9000 and len(enemies) == 2 and all(e["definition"] == "hungry_thief" and int(e["raid"]) == int(raid["id"]) for e in enemies) and row["boundary_spawn"] is True,
        "four_living_undrafted_home_residents_with_starting_weapons": len(world["citizens"]) == 4 and all(not any(c[k] for k in ("death_recorded", "departed", "away", "downed", "drafted", "stand_fast")) for c in world["citizens"]) and [c["equipment"]["weapon"] for c in world["citizens"]] == ["spear", "bow", "bow", "spear"] and row["all_four_living_home_undrafted"] is True,
        "only_exact_accepted_public_orders": [d["kind"] for d in decisions] == expected and plan == applied and len(receipts) == len(decisions) and all(receipts.get(int(d["id"])) == "accepted" and int(e["tick"]) == int(d["tick_queued"]) + 1 for d, e in zip(decisions, trace)) and not world["pending_commands"] and row["commands_accepted"] is True,
        "normal_time_no_starvation_or_theft": 9000 < int(world["tick"]) <= 16200 and int(row["end_tick"]) == int(world["tick"]) and row["zero_fullness_ticks"] == 0 and raid["loot_units"] == 0 and world["ledger"]["looted"] == {} and int(row["invariant_checks"]) == int(world["tick"]) // 60 - 30,
        "active_incident_snapshot_fully_validated_and_continued": int(walking["tick"]) == 9120 and len(walking["defense_state"]["enemies"]) == 2 and walking["defense_state"]["raids"][0]["state"] == ("Active" if action == "defend" else "Payment") and len(row["reloads"]) == 1 and row["reloads"][0]["roundtrip_verified"] is True and int(world["tick"]) > int(walking["tick"]),
        "retreated_before_theft_quota_or_time_limit": bool(retreat) and retreat["state"] == "Retreating" and retreat["loot_units"] == 0 and 9000 < int(retreat["tick"]) < 10800,
        "no_resource_grants_equipment_swaps_or_other_incidents": world["ledger"]["traded_in"] == {} and world["ledger"]["expedition_gain"] == {} and not world["region_state"]["trips"] and not world["trade_state"]["exchanges"] and not world["director_state"]["history"] and world["care_state"]["mode"] == "Standard",
    }
    if action == "defend":
        checks["armed_defense_and_real_civilian_shelter"] = decisions[0]["args"] == {"enabled": True} and decisions[1]["args"] == {"citizens": [2, 3, 4], "rally": row["rally"], "stand_fast": False} and int(decisions[0]["tick_queued"]) == int(decisions[1]["tick_queued"]) == 8700 and row["saw_shelter"] is True and row["saw_downed"] is True and int(row["enemy_tile_steps"]) >= 30 and any(e["health"] <= 10 for e in enemies) and sum(e["state"] in ("Downed", "Retreating", "Leaving", "Gone") for e in retreat["enemies"]) * 2 >= 2 and paid == 0 and int(raid["pay_job"]) == 0
    else:
        jobs = [j for j in world["jobs"] if int(j["id"]) == int(raid["pay_job"])]
        checks["exact_listed_ransom_physically_delivered"] = decisions[0]["args"] == {"target": raid["id"], "pay": {"wood": 16}} and int(decisions[0]["tick_queued"]) == 9000 and paid == 16 and len(jobs) == 1 and jobs[0]["kind"] == "raid_pay" and jobs[0]["state"] == "Complete" and jobs[0]["inputs"] == {"wood": 16} and row["minimum_health"] == 100 and all(c["health"] == 100 for c in world["citizens"]) and all(e["health"] == 40 for e in enemies) and "arrived physically" in retreat["reason"]
    return checks


def verify(path, code, site, seed):
    row = {"site": site, "seed": seed, "passed": False}
    try:
        report = read(path)
        normal_env, normal = snapshot(path.with_name(path.stem + "-normal.brackenward"))
        prepared_env, prepared = snapshot(path.with_name(path.stem + "-announced.brackenward"))
        checks = setup_checks(normal, prepared)
        map_check = geometry(normal)
        checks["independent_initial_geometry"] = map_check["passed"]
        checks["complete_prepared_report"] = code == 0 and report["format"] == "brackenward-prepared-defense" and report["version"] == 1 and report["passed"] is True and report["failure"] == "" and set(report["branches"]) == {"defend", "ransom"} and report["site"] == normal["site_id"] == site and report["seed"] == int(normal["seed"]) == seed and report["generator_version"] == normal["generator_version"] == 2 and all(report[label]["canonical_hash"] == env["sha256"] and report[label]["sha256"] == sha(path.with_name(path.stem + "-" + label + ".brackenward")) and report[label]["roundtrip_verified"] is True for label, env in (("normal", normal_env), ("announced", prepared_env)))
        log = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", path.with_suffix(".log").read_text())
        checks["no_engine_errors"] = not re.search(r"(?m)^\s*(SCRIPT ERROR:|ERROR:|FATAL:|FAIL )", log)
        golden = read(Path(__file__).resolve().parents[1] / "tests/fixtures/generation-v2-goldens.json")
        expected = [r for r in golden["maps"] if (r["site"], r["seed"]) == (site, seed)]
        if expected: checks["inspected_initial_boundary_unchanged"] = len(expected) == 1 and expected[0]["canonical_hash"] == normal_env["sha256"]
        branches = {}
        for action in ("defend", "ransom"):
            end_path = path.with_name(path.stem + f"-{action}-final.brackenward")
            walking_path = path.with_name(path.stem + f"-{action}-active.brackenward")
            env, world = snapshot(end_path);walk_env, walking = snapshot(walking_path)
            detail = report["branches"][action]
            found = branch_checks(detail, world, walking, prepared_env["sha256"], action)
            found["interception_is_midpoint_of_real_shortest_approach"] = interception(normal, detail, prepared["defense_state"]["raids"][0]["entry"])
            fixed = ("id", "budget", "party", "entry", "meeting", "due")
            found["announced_identity_and_route_unchanged"] = all(world["defense_state"]["raids"][0][k] == prepared["defense_state"]["raids"][0][k] for k in fixed)
            found["exact_written_snapshot_identity"] = detail["passed"] is True and detail["final"]["roundtrip_verified"] is True and detail["final"]["canonical_hash"] == env["sha256"] and detail["final"]["sha256"] == sha(end_path) and detail["reloads"][0]["canonical_hash"] == walk_env["sha256"] and detail["reloads"][0]["sha256"] == sha(walking_path)
            branches[action] = {"passed": all(found.values()), "checks": found, "canonical_hash": env["sha256"], "minimum_health": detail["minimum_health"], "retreat_tick": detail["first_retreat"]["tick"], "end_tick": world["tick"]}
        row.update({"passed": all(checks.values()) and all(b["passed"] for b in branches.values()), "checks": checks, "geometry": map_check, "branches": branches, "entry": report["entry"], "normal_canonical_hash": normal_env["sha256"]})
    except (OSError, ValueError, KeyError, TypeError, IndexError, StopIteration) as error:
        row["error"] = str(error)
    return row


def audit(reports, commit):
    source, completion, summary = (read(reports / n) for n in ("source.json", "completion.json", "summary.json"))
    rows = [verify(reports / f"{site}-{seed}.json", next((r["exit_code"] for r in summary if (r["site"], r["seed"]) == (site, seed)), None), site, seed) for site, seed in CASES]
    provenance = source["commit"] == commit and source["harness_sha256"] == sha(Path(__file__)) and source["seeds"] == SEEDS and source["sites"] == SITES and source["scenario_sha256"] == sha(Path(__file__).with_name("defense_scenario.gd")) and completion["source_unchanged"] is True and len(summary) == 30 and {(r["site"], r["seed"]) for r in summary} == set(CASES) and all(sha(reports / name) == digest for name, digest in completion["artifacts_sha256"].items())
    distinct = len({r.get("normal_canonical_hash", "") for r in rows})
    entries = {tuple(r["entry"]["$tile"]) for r in rows if "entry" in r}
    return {"passed": provenance and distinct == 30 and all(r["passed"] for r in rows), "source_commit": commit, "total_maps": 30, "passed_maps": sum(r["passed"] for r in rows), "distinct_maps": distinct, "distinct_entries": len(entries), "rows": rows, "audit_tool_sha256": sha(Path(__file__)), "scope": "Paired prepared defense/ransom fixtures with normal movement, needs, combat and payment. All normal initial geometry is independently checked; eighteen initial maps match inspected goldens. Not ordinary director-frequency, physical-device or human comprehension certification."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--report-dir", type=Path, required=True)
    parser.add_argument("--workers", type=int, choices=(1, 2), default=2)
    parser.add_argument("--audit", action="store_true")
    args = parser.parse_args();source, reports = args.source.resolve(), args.report_dir.resolve()
    if source != Path(__file__).resolve().parents[1]: parser.error("Run from the same frozen source checkout")
    def git(*parts): return subprocess.check_output(["git", *parts], cwd=source, text=True).strip()
    commit = git("rev-parse", "HEAD")
    if git("status", "--porcelain"): parser.error("Source must remain clean and frozen through completion and audit")
    if not args.audit:
        reports.mkdir(parents=True, exist_ok=True)
        if any(reports.iterdir()): parser.error("Use a new empty report directory")
        (reports / ".gitignore").write_text("*\n");(reports / ".gdignore").touch()
        (reports / "source.json").write_text(json.dumps({"commit": commit, "source": str(source), "seeds": SEEDS, "sites": SITES, "workers": args.workers, "started_unix": time.time(), "harness_sha256": sha(Path(__file__)), "scenario_sha256": sha(Path(__file__).with_name("defense_scenario.gd"))}, indent=2) + "\n")
        def run(case):
            site, seed = case;path = reports / f"{site}-{seed}.json";code, error = None, ""
            try:
                with path.with_suffix(".log").open("w") as log:
                    process = subprocess.run([str(source / "tools/godot.sh"), "--headless", "--script", "tools/defense_scenario.gd", "--", "--seed", str(seed), "--site", site, "--report", str(path)], cwd=source, stdout=log, stderr=subprocess.STDOUT, timeout=900)
                    code = process.returncode
            except subprocess.TimeoutExpired: error = "Fifteen-minute case bound; partial evidence retained"
            return {"site": site, "seed": seed, "exit_code": code, "error": error}
        summary = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
            for future in concurrent.futures.as_completed([pool.submit(run, c) for c in CASES]):
                row = future.result();summary.append(row)
                (reports / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
                print(f"{len(summary)}/30: {row['site']} seed {row['seed']} exit {row['exit_code']}", flush=True)
        manifest = {p.name: sha(p) for p in reports.iterdir() if p.is_file() and not p.name.startswith(".")}
        (reports / "completion.json").write_text(json.dumps({"source_unchanged": git("rev-parse", "HEAD") == commit and not git("status", "--porcelain"), "finished_unix": time.time(), "artifacts_sha256": manifest}, indent=2) + "\n")
    try: result = audit(reports, commit)
    except (OSError, ValueError, KeyError, TypeError, IndexError, StopIteration) as error: result = {"passed": False, "error": str(error), "source_commit": commit}
    (reports / "audit.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({k: v for k, v in result.items() if k != "rows"}))
    raise SystemExit(0 if result["passed"] else 1)


if __name__ == "__main__":
    main()
