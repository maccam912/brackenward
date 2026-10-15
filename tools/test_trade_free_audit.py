#!/usr/bin/env python3
"""Reject hidden trade even when a visible command trace appears trade-free."""
import copy
import unittest
from audit_trade_free_charters import trade_checks


class TradeFreeChecks(unittest.TestCase):
    def setUp(self):
        self.report = {"commands": [{"command": {"kind": "expedition_collect"}}, {"command": {"kind": "raid_offer"}}]}
        self.world = {"pending_commands": [], "jobs": [], "trade_state": {"exchanges": []},
                      "ledger": {"traded_in": {}, "traded_out": {"wood": 8}, "expedition_gain": {"ore": 4}},
                      "opportunity_state": {"offers": [{"receipt": 0}]}}

    def test_expeditions_and_tribute_are_permitted(self):
        before = copy.deepcopy((self.report, self.world))
        self.assertTrue(all(trade_checks(self.report, self.world).values()))
        self.assertEqual(before, (self.report, self.world))

    def test_executed_and_pending_barter_are_rejected(self):
        for kind in ["trade", "trade_cancel"]:
            for pending in [False, True]:
                with self.subTest(kind=kind, pending=pending):
                    report, world = copy.deepcopy((self.report, self.world))
                    (world["pending_commands"] if pending else report["commands"]).append({"kind": kind} if pending else {"command": {"kind": kind}})
                    self.assertFalse(all(trade_checks(report, world).values()))

    def test_hidden_transaction_evidence_is_rejected(self):
        for field in ["jobs", "exchange", "import", "opportunity"]:
            with self.subTest(field=field):
                world = copy.deepcopy(self.world)
                if field == "jobs": world["jobs"].append({"kind": "trade", "state": "Canceled"})
                elif field == "exchange": world["trade_state"]["exchanges"].append({"state": "Complete"})
                elif field == "import": world["ledger"]["traded_in"]["ore"] = 1
                else: world["opportunity_state"]["offers"][0]["receipt"] = "42"
                self.assertFalse(all(trade_checks(self.report, world).values()))


if __name__ == "__main__":
    unittest.main()
