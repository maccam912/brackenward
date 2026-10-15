#!/usr/bin/env python3
"""Audit retained ordinary Charter evidence without rewriting any source record."""
import argparse
import hashlib
import json
from pathlib import Path

from charter_sweep import CASES, SEED, verify


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def trade_checks(report, world):
    commands = [row["command"] for row in report["commands"]] + world["pending_commands"]
    return {
        "no_barter_commands": not any(c["kind"] in {"trade", "trade_cancel"} for c in commands),
        "no_trade_work_history": not any(j["kind"] == "trade" for j in world["jobs"]),
        "no_exchanges": world["trade_state"]["exchanges"] == [],
        "no_imported_goods": world["ledger"]["traded_in"] == {},
        "no_opportunity_receipts": all(int(o["receipt"]) == 0 for o in world["opportunity_state"]["offers"]),
    }


def audit(directory):
    names = ["source.json", "completion.json", "summary.json", "audit.json"]
    for site, mode in CASES:
        stem = f"{site}-{mode.lower()}"
        names.extend([stem + suffix for suffix in [".json", ".log", "-initial.brackenward", "-final.brackenward"]])
    before = {name: sha(directory / name) for name in names}
    source = json.loads((directory / "source.json").read_text())
    completion = json.loads((directory / "completion.json").read_text())
    original = json.loads((directory / "audit.json").read_text())
    summary = json.loads((directory / "summary.json").read_text())
    cases = {(site, mode) for site, mode in CASES}
    provenance = (source["days"] == 96 and source["seed"] == SEED
                  and {tuple(pair) for pair in source["cases"]} == cases
                  and len(summary) == len(original["rows"]) == 4
                  and {(r["site"], r["mode"]) for r in summary} == cases
                  and {(r["site"], r["mode"]) for r in original["rows"]} == cases
                  and completion["source_unchanged"] is True
                  and completion["total"] == completion["passed"] == 4
                  and original["passed"] is True and original["source_commit"] == source["commit"])
    rows = []
    for site, mode in CASES:
        path = directory / f"{site}-{mode.lower()}.json"
        result = json.loads(path.read_text())
        old = next(row for row in original["rows"] if (row["site"], row["mode"]) == (site, mode))
        exit_code = next(row["exit_code"] for row in summary if (row["site"], row["mode"]) == (site, mode))
        row = verify(path, exit_code, site, mode, source["days"])
        snapshot = path.with_name(path.stem + "-final.brackenward")
        envelope = json.loads(snapshot.read_text())
        world = json.loads(envelope["payload"])
        checks = trade_checks(result, world)
        checks["original_endpoint_matches"] = old["pass"] is True and old["snapshot_sha256"] == sha(snapshot) and old["canonical_hash"] == row["canonical_hash"]
        checks["no_starvation_grace_exceeded"] = result["starvation_grace_exceeded_ticks"] == 0
        row["checks"] = checks
        row["pass"] = row["pass"] and all(checks.values())
        rows.append(row)
    unchanged = before == {name: sha(directory / name) for name in names}
    return {"format": "brackenward-trade-free-charter-audit", "version": 1,
            "source_commit": source["commit"], "passed": provenance and unchanged and all(r["pass"] for r in rows),
            "provenance_pass": provenance, "inputs_unchanged": unchanged, "inputs_sha256": before,
            "rows": rows, "audit_tool_sha256": sha(Path(__file__)),
            "scope": "Audit of the retained 96-day campaigns, not new simulations. Expeditions and raid tribute are allowed; no barter, imported goods or opportunity receipts. Physical and human gates remain open."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    directory, report = args.directory.resolve(), args.report.resolve()
    if report.exists() or report.is_relative_to(directory):
        parser.error("Choose a new report outside the preserved evidence directory")
    try:
        result = audit(directory)
    except (OSError, ValueError, KeyError, TypeError, StopIteration) as error:
        result = {"passed": False, "error": str(error), "audit_tool_sha256": sha(Path(__file__))}
    report.parent.mkdir(parents=True, exist_ok=True)
    with report.open("x") as output:
        output.write(json.dumps(result, indent=2) + "\n")
    print(json.dumps({key: result[key] for key in ["passed", "source_commit", "inputs_unchanged"] if key in result}))
    raise SystemExit(0 if result["passed"] else 1)


if __name__ == "__main__":
    main()
