#!/usr/bin/env python3
"""Exact coverage and fallback boundaries; subset runs cannot certify release."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from map_sweep import ANSI, GOLDEN_SEEDS, SITES, audit, coverage, ranges, seed, sha


class SweepChecks(unittest.TestCase):
    def test_boundary_seeds_then_ten_thousand_unique_uint32_cases(self):
        values = [seed(index) for index in range(10000)]
        self.assertEqual(values[:6], GOLDEN_SEEDS)
        self.assertEqual(len(set(values)), 10000)
        self.assertTrue(all(type(n) is int and 0 <= n <= 4294967295 for n in values))
        # Independently checked with shasum: 5d0d9927d48d4197... for the exact
        # UTF-8 text brackenward-map-sweep-v1|6; take four big-endian bytes.
        self.assertEqual(seed(6), 0x5D0D9927)

    def test_nonoverlapping_shards_cover_each_site_exactly(self):
        cases = ranges(6, 513)
        rows = [(site, index) for site, start, count in cases for index in range(start, start+count)]
        self.assertEqual(len(rows), len(set(rows)))
        self.assertEqual(set(rows), {(site, index) for site in SITES for index in range(6, 519)})

    def test_subset_is_never_full_release_even_with_all_geometry_valid(self):
        result = coverage(True, 6, 256, {site: 0 for site in SITES})
        self.assertTrue(result["passed"])
        self.assertFalse(result["release_generation_gate_pass"])
        self.assertIsNone(result["fallback_budget_pass"])

    def test_release_fallback_must_be_strictly_below_one_in_thousand_per_site(self):
        fallback = {site: 9 for site in SITES}
        self.assertTrue(coverage(True, 0, 10000, fallback)["release_generation_gate_pass"])
        fallback["pine_shelf"] = 10
        result = coverage(True, 0, 10000, fallback)
        self.assertFalse(result["passed"])
        self.assertFalse(result["fallback_budget_pass"])
        self.assertTrue(result["geometry_pass"])

    def test_incomplete_geometry_cannot_pass_with_good_fallback_rate(self):
        self.assertFalse(coverage(False, 0, 10000, {site: 0 for site in SITES})["passed"])

    def test_colored_runtime_errors_remain_visible_to_fail_closed_reader(self):
        self.assertEqual(ANSI.sub("", "\x1b[31mSCRIPT ERROR: broken\x1b[0m"), "SCRIPT ERROR: broken")


class AuditContractChecks(unittest.TestCase):
    """Synthetic audit records, not raw maps or a generation certificate."""
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "source";self.source.mkdir()
        (self.source / "src/generation").mkdir(parents=True)
        (self.source / "src/generation/colony_generation.gd").write_text("const VERSION: int = 1\n")
        self.reports = self.root / "reports";self.reports.mkdir()
        self.tools = {"synthetic": "fixture"}
        self.summary = []
        for site in SITES:
            stem = site + "-00006-00006"
            cases, log = self.reports / (stem+".jsonl"), self.reports / (stem+".log")
            row = {"site": site, "index": 6, "seed": seed(6), "generator_version": 1, "attempt": 0, "fallback": False,
                   "map_sha256": "0"*64, "metrics": {"passed": True, "errors": [], "safe_buildable": 1024, "wild_food_units": 40}}
            cases.write_text(json.dumps(row)+"\n");log.write_text("Godot Engine v4.7.2\n")
            self.summary.append({"site": site, "start": 6, "count": 1, "pass": True, "exit_code": 0, "cases_sha256": sha(cases), "log_sha256": sha(log)})
        self.original = {"commit": "synthetic", "generator_version": 1, "tools_sha256": self.tools, "start": 6, "count": 1, "sites": SITES, "seed_algorithm": "brackenward-map-sweep-v1"}
        self.done = {"source_unchanged": True, "processed": 3, "passed": 3}

    def check_result(self):
        for name, value in [("source.json", self.original), ("summary.json", self.summary), ("completion.json", self.done)]:
            (self.reports / name).write_text(json.dumps(value))
        with patch("map_sweep.fingerprints", return_value=self.tools):
            return audit(self.source, self.reports, "synthetic")

    def first_row(self, edit):
        path = self.reports / (SITES[0]+"-00006-00006.jsonl")
        row = json.loads(path.read_text());edit(row)
        path.write_text(json.dumps(row)+"\n");self.summary[0]["cases_sha256"] = sha(path)

    def test_complete_subset_contract_never_claims_full_release(self):
        result = self.check_result()
        self.assertTrue(result["passed"])
        self.assertEqual(result["cases"], 3)
        self.assertFalse(result["release_generation_gate_pass"])

    def test_wrong_seed_even_with_updated_file_digest_is_rejected(self):
        self.first_row(lambda row: row.__setitem__("seed", seed(7)))
        self.assertFalse(self.check_result()["passed"])

    def test_missing_site_is_rejected(self):
        self.summary.pop()
        self.assertFalse(self.check_result()["passed"])

    def test_false_source_proof_is_rejected(self):
        self.done["source_unchanged"] = False
        self.assertFalse(self.check_result()["passed"])

    def test_colored_error_after_valid_rows_cannot_pass(self):
        path = self.reports / (SITES[0]+"-00006-00006.log")
        path.write_text("\x1b[31mSCRIPT ERROR: after final map\x1b[0m\n")
        self.summary[0]["log_sha256"] = sha(path)
        self.assertFalse(self.check_result()["passed"])

    def test_declared_complete_counters_cannot_hide_missing_processed_case(self):
        self.done["processed"] = 2
        self.assertFalse(self.check_result()["passed"])

    def test_raw_validation_failure_cannot_be_promoted_by_summary(self):
        self.first_row(lambda row: row["metrics"].update(passed=False, errors=["unreachable resource"]))
        self.assertFalse(self.check_result()["passed"])


if __name__ == "__main__":
    unittest.main()
