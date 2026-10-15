"""Synthetic audit-contract counterexamples; these are not campaign evidence."""
import copy
import json
from pathlib import Path
import tempfile
import unittest

import merchant_sweep as sweep


def fixture():
    exchanges = [{"id": str(n), "merchant": str(n * 10), "community": "riverward" if n < 3 else "road_fellowship", "delivery": n == 3, "state": "Complete", "buy": {"cloth": 8} if n < 3 else {}, "pay": {"wood": 40} if n < 3 else {"cloak": 3}, "gift": 0, "job": str(n * 100), "receipt": str(n * 10000)} for n in (1, 2, 3)]
    commands = [{"id": str(n), "kind": "trade", "args": {"target": str(n * 10)}} for n in (1, 2, 3)]
    world = {"trade_state": {"exchanges": exchanges, "merchants": [{"id": str(n * 10), "deadline": str(n * 10000 + 1000), "entry": {"$tile": [0, 64]}} for n in (1, 2, 3)], "reputation": {"road_fellowship": 30}}, "jobs": [{"id": str(n * 100), "kind": "trade", "state": "Complete", "definition": ""} for n in (1, 2, 3)] + [{"id": str(n), "kind": "craft", "state": "Complete", "definition": "sew_cloak"} for n in (401, 402, 403)], "receipts": {"$map": [[str(n), "accepted"] for n in (1, 2, 3)]}, "pending_commands": [], "ledger": {"traded_in": {"cloth": 16}, "consumed": {"cloth": 6}, "produced": {}, "recovered": {}, "expedition_gain": {}, "spoiled": {}, "lost": {}, "traded_out": {"wood": 80, "cloak": 3}, "looted": {}}, "stacks": [{"item": "cloth", "count": 10}], "fields": [], "production_state": {"orders": [{"recipe": "sew_cloak"}]}, "region_state": {"trips": []}, "opportunity_state": {"offers": []}, "citizens": [{"death_recorded": False, "departed": False, "equipment": {"cloak": "cloak"}} for _ in range(8)], "defense_state": {"enemies": []}}
    report = {"commands": [{"command": copy.deepcopy(c)} for c in commands], "policy_decisions": copy.deepcopy(commands), "zero_fullness_ticks": 0, "starvation_grace_exceeded_ticks": 0, "final": {"food": {"ticks": 7200}}}
    return report, world, {"stacks": []}


class MerchantAuditChecks(unittest.TestCase):
    def test_synthetic_contract_is_internally_consistent(self):
        self.assertTrue(all(sweep.economy_checks(*fixture()).values()))

    def test_native_numeric_merchant_reference_matches_string_entity_id(self):
        r, w, i = fixture()
        for e in w["trade_state"]["exchanges"]:
            e["merchant"], e["receipt"] = int(e["merchant"]), int(e["receipt"])
        self.assertTrue(all(sweep.economy_checks(r, w, i).values()))

    def test_same_merchant_twice_is_not_two_scheduled_visits(self):
        r, w, i = fixture();w["trade_state"]["exchanges"][1]["merchant"] = "10"
        self.assertFalse(sweep.economy_checks(r, w, i)["two_distinct_riverward_purchases"])

    def test_local_cloth_cannot_substitute_for_imports(self):
        r, w, i = fixture();w["ledger"]["produced"]["cloth"] = 1
        self.assertFalse(sweep.economy_checks(r, w, i)["imported_cloth_is_only_source"])

    def test_expedition_cloth_cannot_substitute_for_imports(self):
        r, w, i = fixture();w["ledger"]["expedition_gain"]["cloth"] = 1
        self.assertFalse(sweep.economy_checks(r, w, i)["imported_cloth_is_only_source"])

    def test_packing_does_not_count_as_completed_payment(self):
        r, w, i = fixture();w["jobs"][0]["state"] = "Packing"
        self.assertFalse(sweep.economy_checks(r, w, i)["all_payments_physically_committed"])

    def test_purchase_cannot_commit_at_expiry(self):
        r, w, i = fixture();w["trade_state"]["exchanges"][0]["receipt"] = w["trade_state"]["merchants"][0]["deadline"]
        self.assertFalse(sweep.economy_checks(r, w, i)["purchases_within_actual_cart_stay"])

    def test_real_sewing_is_required_even_with_received_cloaks(self):
        r, w, i = fixture();w["jobs"][-1]["state"] = "Canceled"
        self.assertFalse(sweep.economy_checks(r, w, i)["cloth_conservation_and_real_sewing"])

    def test_changed_command_fails_planner_provenance(self):
        r, w, i = fixture();r["commands"][0]["command"]["args"]["target"] = "999"
        self.assertFalse(sweep.economy_checks(r, w, i)["planner_decisions_match_all_public_commands"])

    def test_starvation_does_not_pass_on_final_food_alone(self):
        r, w, i = fixture();r["starvation_grace_exceeded_ticks"] = 1
        self.assertFalse(sweep.economy_checks(r, w, i)["no_starvation_and_final_food_day"])

    def test_flax_invalidates_import_only_policy(self):
        r, w, i = fixture();w["fields"].append({"crop": "flax"})
        self.assertFalse(sweep.economy_checks(r, w, i)["no_local_weaving_or_expedition_substitute"])

    def test_unrequested_care_mode_change_is_rejected(self):
        r, w, i = fixture();w["pending_commands"].append({"id": "4", "kind": "care_mode", "args": {"mode": "Hearthside"}})
        self.assertFalse(sweep.economy_checks(r, w, i)["only_requested_care_mode"])

    def test_other_normal_raid_tribute_does_not_erase_exact_trade_payment(self):
        r, w, i = fixture();w["ledger"]["traded_out"]["wood"] += 12
        self.assertTrue(sweep.economy_checks(r, w, i)["exact_payment_and_reputation"])

    def test_missing_output_fails_closed(self):
        with tempfile.TemporaryDirectory() as root:
            self.assertFalse(sweep.verify(Path(root) / "missing.json", 0, "meadow_reach", "Standard")["pass"])

    def test_duplicate_keys_and_damaged_payload_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            p = Path(root) / "input.json";p.write_text('{"commit":"old","commit":"new"}')
            with self.assertRaises(ValueError): sweep.read(p)
            p.write_text(json.dumps({"format": "brackenward-development-colony", "version": 5, "payload": "{}", "sha256": "wrong"}))
            with self.assertRaises(ValueError): sweep.snapshot(p)

    def test_only_initial_hearthside_preset_is_normalized_without_mutation(self):
        base = {"pending_commands": [], "next_command_id": "1", "citizens": [{"rest": 1000}]}
        original = copy.deepcopy(base);expected = sweep.initial_hash(base, "Standard")
        hearth = copy.deepcopy(base);hearth["next_command_id"] = "2"
        hearth["pending_commands"] = [{"id": "1", "session": "m1-test", "kind": "care_mode", "args": {"mode": "Hearthside"}}]
        before = copy.deepcopy(hearth)
        self.assertEqual(sweep.initial_hash(hearth, "Hearthside"), expected)
        self.assertEqual(hearth, before);self.assertEqual(base, original)
        hearth["citizens"][0]["rest"] = 999
        self.assertNotEqual(sweep.initial_hash(hearth, "Hearthside"), expected)
        hearth["pending_commands"][0]["args"]["mode"] = "Standard"
        with self.assertRaises(ValueError): sweep.initial_hash(hearth, "Hearthside")


if __name__ == "__main__":
    unittest.main()
