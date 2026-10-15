#!/usr/bin/env python3
"""Fault-inject synthetic report contracts; these are not campaign evidence."""
import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from post_charter_sweep import verify_continuation


class ContinuationChecks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.prior = self.root / "prior.json"
        self.path = self.root / "continued.json"
        commands = [{"command": {"kind": "preference", "id": "1"}, "tick": "1801"}]
        self.prior.write_text(json.dumps({"commands": commands, "invariant_checks": 2304}))
        for stem in ["prior", "continued"]:
            (self.root / (stem + "-initial.brackenward")).write_text("synthetic initial bytes")
        payload = "{}"
        canonical = hashlib.sha256(payload.encode()).hexdigest()
        (self.root / "continued-final.brackenward").write_text(json.dumps({"payload": payload, "sha256": canonical}))
        self.path.with_suffix(".log").write_text("")
        self.origin = {"site": "meadow_reach", "mode": "Standard", "report": str(self.prior), "end_tick": 693000, "canonical_hash": "a" * 64, "ceremony_end": 270901}
        self.result = {"canonical_hash": canonical, "end_tick": 1384200, "start_tick": 1800, "minimum_health": 100,
                       "zero_fullness_ticks": 0, "starvation_grace_exceeded_ticks": 0, "invariant_checks": 4608,
                       "roundtrip_verified": True, "scenario_pass": True, "ordinary_play_only": True,
                       "scenario": "vegetarian_charter", "site": "meadow_reach", "mode": "Standard", "seed": 104729,
                       "invariant_failure": "", "charter": {"completed": list(range(5)), "ending": True, "continued": True, "ceremony": {"state": "Complete", "end": 270901}},
                       "final": {"living": 8, "citizens": [{"departed": False} for _ in range(8)], "food": {"ticks": 7200}},
                       "commands": commands + [{"command": {"kind": "gather", "id": "2"}, "tick": "693001"}],
                       "source_reports": [{"path": str(self.prior), "canonical_hash": "a" * 64, "end_tick": 693000}]}

    def check_result(self, value=None, code=0):
        self.path.write_text(json.dumps(self.result if value is None else value))
        return verify_continuation(self.path, code, self.origin)["pass"]

    def test_complete_contract_is_accepted(self):
        self.assertTrue(self.check_result())

    def test_short_run_or_missing_invariant_coverage_is_rejected(self):
        for field in ["end_tick", "invariant_checks"]:
            result = copy.deepcopy(self.result); result[field] -= 1
            with self.subTest(field=field): self.assertFalse(self.check_result(result))

    def test_wrong_origin_or_removed_command_history_is_rejected(self):
        for field in ["canonical_hash", "path", "end_tick", "commands"]:
            result = copy.deepcopy(self.result)
            if field == "commands": result["commands"] = result["commands"][1:]
            else: result["source_reports"][-1][field] = "wrong" if field != "end_tick" else 1
            with self.subTest(field=field): self.assertFalse(self.check_result(result))

    def test_food_shortage_or_replaced_dead_resident_is_rejected(self):
        for field in ["grace", "food", "replacement", "departure"]:
            result = copy.deepcopy(self.result)
            if field == "grace": result["starvation_grace_exceeded_ticks"] = 1
            elif field == "food": result["final"]["food"]["ticks"] = 7199
            elif field == "replacement": result["final"]["citizens"].append({"departed": False})
            else: result["final"]["citizens"][0]["departed"] = True
            with self.subTest(field=field): self.assertFalse(self.check_result(result))

    def test_changed_original_initial_bytes_are_rejected(self):
        (self.root / "continued-initial.brackenward").write_text("changed")
        self.assertFalse(self.check_result())

    def test_failed_process_or_bad_save_digest_is_rejected(self):
        self.assertFalse(self.check_result(code=1))
        (self.root / "continued-final.brackenward").write_text(json.dumps({"payload": "{}", "sha256": "bad"}))
        self.assertFalse(self.check_result())


if __name__ == "__main__":
    unittest.main()
