"""Synthetic audit-contract counterexamples; these are not campaign evidence."""
import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import merchant_sweep as sweep


def fixture():
    exchanges = [{"id": str(n), "merchant": str(n * 10), "community": "riverward" if n < 3 else "road_fellowship", "delivery": n == 3, "state": "Complete", "buy": {"cloth": 8} if n < 3 else {}, "pay": {"wood": 40} if n < 3 else {"cloak": 3}, "gift": 0, "job": str(n * 100), "receipt": str(n * 10000)} for n in (1, 2, 3)]
    commands = [{"id": str(n), "kind": "trade", "args": {"target": str(n * 10)}} for n in (1, 2, 3)]
    world = {"trade_state": {"exchanges": exchanges, "merchants": [{"id": str(n * 10), "deadline": str(n * 10000 + 1000), "entry": {"$tile": [0, 64]}} for n in (1, 2, 3)], "reputation": {"road_fellowship": 30}}, "jobs": [{"id": str(n * 100), "kind": "trade", "state": "Complete", "definition": ""} for n in (1, 2, 3)] + [{"id": str(n), "kind": "craft", "state": "Complete", "definition": "sew_cloak"} for n in (401, 402, 403)], "receipts": {"$map": [[str(n), "accepted"] for n in (1, 2, 3)]}, "pending_commands": [], "ledger": {"traded_in": {"cloth": 16}, "consumed": {"cloth": 6}, "produced": {}, "recovered": {}, "expedition_gain": {}, "spoiled": {}, "lost": {}, "traded_out": {"wood": 80, "cloak": 3}, "looted": {}}, "stacks": [{"item": "cloth", "count": 10}], "fields": [], "production_state": {"orders": [{"recipe": "sew_cloak"}]}, "region_state": {"trips": []}, "opportunity_state": {"offers": []}, "citizens": [{"death_recorded": False, "departed": False, "equipment": {"cloak": "cloak"}} for _ in range(8)], "defense_state": {"enemies": []}}
    report = {"commands": [{"command": copy.deepcopy(c)} for c in commands], "policy_decisions": copy.deepcopy(commands), "zero_fullness_ticks": 0, "starvation_grace_exceeded_ticks": 0, "final": {"food": {"ticks": 7200}}}
    return report, world, {"stacks": []}


class MerchantAuditChecks(unittest.TestCase):
    def v14_initial(self):
        root = Path(__file__).resolve().parents[1]
        golden = sweep.read(root / "tests/fixtures/generation-v2-goldens.json")
        catalog = sweep.read(root / "data/catalogs/colony_v14.json")
        digest = hashlib.sha256(json.dumps(catalog, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()
        old = {"content": "colony-v6", "content_hash": golden["catalog_sha256"],
               "schema_revision": 23, "pending_commands": [], "next_command_id": "1",
               "citizens": [{"id": "1", "preferences": {"Hauling": 2}, "rest": 900,
                             "equipment": {"weapon": "spear"}}],
               "equipment_state": {"$map": [["1", {"weapon": {"preferred": "spear"}}]]},
               "stores": [{"filters": ["wood", "spear"]}]}
        current = copy.deepcopy(old)
        current.update(content="colony-v14", content_hash=digest, schema_revision=25)
        current["citizens"][0]["preferences"]["Hauling"] = 1
        current["citizens"][0]["equipment"]["transport"] = ""
        current["equipment_state"]["$map"][0][1]["transport"] = {"replacements": True, "upgrades": False, "preferred": ""}
        current["stores"][0]["filters"].append("wheelbarrow")
        return old, current, golden

    def test_v14_initial_map_normalizes_only_empty_transport_defaults(self):
        old, current, golden = self.v14_initial()
        before = copy.deepcopy(current)
        self.assertEqual(sweep.initial_hash(current, "Standard", golden),
                         sweep.initial_hash(old, "Standard", golden))
        self.assertEqual(current, before)
        current["citizens"][0]["rest"] -= 1
        self.assertNotEqual(sweep.initial_hash(current, "Standard", golden),
                            sweep.initial_hash(old, "Standard", golden))

    def test_v14_nondefault_equipment_or_schema_is_not_hidden(self):
        for edit in (lambda s: s.update(schema_revision=24),
                     lambda s: s["citizens"][0]["equipment"].update(transport="wheelbarrow"),
                     lambda s: s["equipment_state"]["$map"][0][1]["transport"].update(upgrades=True)):
            _, current, golden = self.v14_initial()
            edit(current)
            with self.assertRaises(ValueError):
                sweep.initial_hash(current, "Standard", golden)

    def test_v14_added_catalog_definitions_must_match_reviewed_values(self):
        for section, field, value in (("items", "barter_value", 9),
                                      ("recipes", "work_milli", 1),
                                      ("research", "points", 1)):
            _, current, golden = self.v14_initial()
            catalog = sweep.read(Path(__file__).resolve().parents[1] / "data/catalogs/colony_v14.json")
            catalog[section][-1][field] = value
            current["content_hash"] = hashlib.sha256(json.dumps(catalog, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()
            original_read = sweep.read
            with patch("merchant_sweep.read", side_effect=lambda p: catalog if p.name == "colony_v14.json" else original_read(p)):
                with self.assertRaises(ValueError):
                    sweep.initial_hash(current, "Standard", golden)

    def test_v9_initial_map_normalizes_only_the_declared_hauling_default(self):
        root = Path(__file__).resolve().parents[1]
        golden = sweep.read(root / 'tests/fixtures/generation-v2-goldens.json')
        catalog = sweep.read(root / 'data/catalogs/colony_v9.json')
        digest = hashlib.sha256(json.dumps(catalog, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()).hexdigest()
        old = {'content': 'colony-v6', 'content_hash': golden['catalog_sha256'], 'pending_commands': [], 'next_command_id': '1', 'citizens': [{'preferences': {'Hauling': 2, 'Building': 2}, 'rest': 900}]}
        current = copy.deepcopy(old)
        current.update(content='colony-v9', content_hash=digest)
        current['citizens'][0]['preferences']['Hauling'] = 1
        before = copy.deepcopy(current)
        self.assertEqual(sweep.initial_hash(current, 'Standard', golden), sweep.initial_hash(old, 'Standard', golden))
        self.assertEqual(current, before)
        current['citizens'][0]['preferences']['Building'] = 3
        self.assertNotEqual(sweep.initial_hash(current, 'Standard', golden), sweep.initial_hash(old, 'Standard', golden))
        current['citizens'][0]['preferences']['Hauling'] = 2
        with self.assertRaises(ValueError):
            sweep.initial_hash(current, 'Standard', golden)

    def test_content_header_normalization_keeps_all_gameplay_and_source_fields(self):
        root = Path(__file__).resolve().parents[1]
        golden = sweep.read(root / 'tests/fixtures/generation-v2-goldens.json')
        catalog = sweep.read(root / 'data/catalogs/colony_v7.json')
        digest = hashlib.sha256(json.dumps(catalog, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()).hexdigest()
        old = {'content': 'colony-v6', 'content_hash': golden['catalog_sha256'], 'pending_commands': [], 'next_command_id': '1', 'citizens': [{'rest': 1000}]}
        current = copy.deepcopy(old);current.update(content='colony-v7', content_hash=digest)
        before = copy.deepcopy(current)
        self.assertEqual(sweep.initial_hash(current, 'Standard', golden), sweep.initial_hash(old, 'Standard', golden))
        self.assertEqual(current, before)
        current['citizens'][0]['rest'] = 999
        self.assertNotEqual(sweep.initial_hash(current, 'Standard', golden), sweep.initial_hash(old, 'Standard', golden))

    def test_header_normalization_rejects_changed_definitions_hashes_and_versions(self):
        root = Path(__file__).resolve().parents[1]
        golden = sweep.read(root / 'tests/fixtures/generation-v2-goldens.json')
        catalog = sweep.read(root / 'data/catalogs/colony_v7.json')
        digest = hashlib.sha256(json.dumps(catalog, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()).hexdigest()
        current = {'content': 'colony-v7', 'content_hash': digest, 'pending_commands': [], 'next_command_id': '1'}
        for changes in [{'content_hash': '0' * 64}, {'content': 'colony-v8'}]:
            with self.assertRaises(ValueError):sweep.initial_hash({**current, **changes}, 'Standard', golden)
        changed = copy.deepcopy(catalog);changed['items'][0]['barter_value'] += 1
        forged = {**current, 'content_hash': hashlib.sha256(json.dumps(changed, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()).hexdigest()}
        original_read = sweep.read
        with patch('merchant_sweep.read', side_effect=lambda path: changed if path.name == 'colony_v7.json' else original_read(path)):
            with self.assertRaises(ValueError):sweep.initial_hash(forged, 'Standard', golden)

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
