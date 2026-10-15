"""Synthetic audit counterexamples only, never evidence that raids are survivable."""
import copy
from pathlib import Path
import tempfile
import unittest

import defense_sweep as sweep


def fixture(action):
    orders = [(8700, "shelter", {"enabled": True}), (8700, "draft", {"citizens": [2, 3, 4], "rally": {"$tile": [66, 63]}, "stand_fast": False}), (10440, "stand_down", {})] if action == "defend" else [(9000, "raid_offer", {"target": "500", "pay": {"wood": 16}}), (9300, "stand_down", {})]
    decisions = [{"tick_queued": tick, "id": str(n), "kind": kind, "args": args} for n, (tick, kind, args) in enumerate(orders, 1)]
    trace = [{"tick": str(d["tick_queued"] + 1), "command": {k: copy.deepcopy(d[k]) for k in ("id", "kind", "args")}} for d in decisions]
    raid = {"id": "500", "state": "Resolved", "arrival": 9000, "due": 9000, "loot_units": 0, "pay_job": "501" if action == "ransom" else 0}
    enemies = [{"definition": "hungry_thief", "raid": "500", "health": 10 if action == "defend" and n == 0 else 40, "state": "Downed" if action == "defend" and n == 0 else "Gone"} for n in range(2)]
    people = [{**{k: False for k in ("death_recorded", "departed", "away", "downed", "drafted", "stand_fast")}, "health": 100, "equipment": {"weapon": w}} for w in ("spear", "bow", "bow", "spear")]
    tick = 10500 if action == "defend" else 9360
    world = {"tick": str(tick), "citizens": people, "defense_state": {"raids": [raid], "enemies": enemies}, "receipts": {"$map": [[d["id"], "accepted"] for d in decisions]}, "pending_commands": [], "structures": [{"definition": "supply_cart", "x": 66, "y": 63}], "ledger": {"traded_out": {"wood": 16} if action == "ransom" else {}, "looted": {}, "traded_in": {}, "expedition_gain": {}}, "jobs": [{"id": "501", "kind": "raid_pay", "state": "Complete", "inputs": {"wood": 16}}] if action == "ransom" else [], "region_state": {"trips": []}, "trade_state": {"exchanges": []}, "director_state": {"history": []}, "care_state": {"mode": "Standard"}}
    retreat = {"tick": 10200 if action == "defend" else 9300, "state": "Retreating", "loot_units": 0, "reason": "The quoted supplies arrived physically" if action == "ransom" else "Half stopped", "enemies": copy.deepcopy(enemies)}
    row = {"rally": {"$tile": [66, 63]}, "initial_canonical_hash": "same", "raid": copy.deepcopy(raid), "boundary_spawn": True, "all_four_living_home_undrafted": True, "decisions": decisions, "commands": trace, "commands_accepted": True, "end_tick": tick, "zero_fullness_ticks": 0, "invariant_checks": tick // 60 - 30, "reloads": [{"roundtrip_verified": True}], "first_retreat": retreat, "saw_shelter": True, "saw_downed": action == "defend", "enemy_tile_steps": 70, "minimum_health": 100}
    walking = {"tick": "9120", "defense_state": {"enemies": copy.deepcopy(enemies), "raids": [{"state": "Active" if action == "defend" else "Payment"}]}}
    return row, world, walking


class DefenseAuditTests(unittest.TestCase):
    def checks(self, action="defend", edit=None):
        parts = fixture(action)
        if edit: edit(*parts)
        return sweep.branch_checks(*parts, "same", action)

    def test_both_synthetic_contracts_consistent(self):
        for action in ("defend", "ransom"):
            self.assertTrue(all(self.checks(action).values()))

    def test_different_announced_party_fails(self):
        self.assertFalse(self.checks(edit=lambda r, w, s: r.update(initial_canonical_hash="other"))["same_announced_input"])

    def test_time_limit_escape_is_not_repelling(self):
        self.assertFalse(self.checks(edit=lambda r, w, s: r["first_retreat"].update(tick=10800))["retreated_before_theft_quota_or_time_limit"])

    def test_theft_quota_escape_is_not_repelling(self):
        self.assertFalse(self.checks(edit=lambda r, w, s: r["first_retreat"].update(loot_units=8))["retreated_before_theft_quota_or_time_limit"])

    def test_no_downed_enemy_cannot_claim_armed_solution(self):
        self.assertFalse(self.checks(edit=lambda r, w, s: r.update(saw_downed=False))["armed_defense_and_real_civilian_shelter"])

    def test_boundary_teleport_cannot_replace_walking(self):
        self.assertFalse(self.checks(edit=lambda r, w, s: r.update(enemy_tile_steps=0))["armed_defense_and_real_civilian_shelter"])

    def test_missing_shelter_is_not_the_stated_plan(self):
        self.assertFalse(self.checks(edit=lambda r, w, s: r.update(saw_shelter=False))["armed_defense_and_real_civilian_shelter"])

    def test_unaccepted_command_fails_even_when_report_claims_success(self):
        self.assertFalse(self.checks(edit=lambda r, w, s: w["receipts"]["$map"][0].__setitem__(1, "rejected"))["only_exact_accepted_public_orders"])

    def test_changed_trace_fails(self):
        self.assertFalse(self.checks(edit=lambda r, w, s: r["commands"][0]["command"].update(kind="open_passage"))["only_exact_accepted_public_orders"])

    def test_instant_delivery_without_actual_job_fails(self):
        self.assertFalse(self.checks("ransom", lambda r, w, s: w["jobs"][0].update(state="Delivering"))["exact_listed_ransom_physically_delivered"])

    def test_wrong_ransom_or_injury_fails(self):
        self.assertFalse(self.checks("ransom", lambda r, w, s: w["ledger"]["traded_out"].update(wood=15))["exact_listed_ransom_physically_delivered"])
        self.assertFalse(self.checks("ransom", lambda r, w, s: r.update(minimum_health=99))["exact_listed_ransom_physically_delivered"])

    def test_replacement_people_or_equipment_fails(self):
        self.assertFalse(self.checks(edit=lambda r, w, s: w["citizens"].append(copy.deepcopy(w["citizens"][0])))["four_living_undrafted_home_residents_with_starting_weapons"])
        self.assertFalse(self.checks(edit=lambda r, w, s: w["citizens"][0]["equipment"].update(weapon="bow"))["four_living_undrafted_home_residents_with_starting_weapons"])

    def test_early_arrival_and_uncontinued_reload_fail(self):
        self.assertFalse(self.checks(edit=lambda r, w, s: w["defense_state"]["raids"][0].update(arrival=1800))["resolved_same_party_after_normal_boundary_arrival"])
        self.assertFalse(self.checks(edit=lambda r, w, s: s.update(tick="9000"))["active_incident_snapshot_fully_validated_and_continued"])

    def test_starvation_or_resource_grant_fails(self):
        self.assertFalse(self.checks(edit=lambda r, w, s: r.update(zero_fullness_ticks=1))["normal_time_no_starvation_or_theft"])
        self.assertFalse(self.checks(edit=lambda r, w, s: w["ledger"]["traded_in"].update(wood=16))["no_resource_grants_equipment_swaps_or_other_incidents"])

    def test_missing_artifacts_fail_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertFalse(sweep.verify(Path(directory) / "missing.json", 0, "pine_shelf", 1)["passed"])

    def setup_pair(self):
        normal = {"next_id": "500", "tick": "1800", "pending_commands": [], "care_state": {"mode": "Standard"}, "citizens": [{"equipment": {"weapon": w}, "rest": 900} for w in ("spear", "bow", "bow", "spear")], "defense_state": {"rng": "1", "raids": [], "enemies": [], "alert_serial": 0, "shelter": False}, "facts": [], "chronicle_state": {"next_event_id": "1", "facts": [], "settlement": "Brackenward"}, "stacks": [{"item": "wood", "count": 40}]}
        prepared = copy.deepcopy(normal);prepared["next_id"] = "501"
        prepared["defense_state"].update(rng="48271", raids=[{"id": "500", "state": "Announced", "budget": 2, "party": ["hungry_thief", "hungry_thief"], "due": 9000, "arrival": 0, "actors": [], "route_blocked": False, "entry": {"$tile": [0, 40]}}])
        prepared["facts"].append({"kind": "raid_warning", "tick": "1800"})
        prepared["chronicle_state"]["facts"].append({"kind": "raid_warning"});prepared["chronicle_state"]["next_event_id"] = "2"
        return normal, prepared

    def test_setup_exception_is_exactly_one_announcement(self):
        pair = self.setup_pair();original = copy.deepcopy(pair)
        self.assertTrue(all(sweep.setup_checks(*pair).values()));self.assertEqual(pair, original)

    def test_setup_cannot_grant_supplies_or_rest(self):
        normal, prepared = self.setup_pair();prepared["stacks"][0]["count"] += 16
        self.assertFalse(sweep.setup_checks(normal, prepared)["only_one_explicit_announcement_changes_initial_state"])
        normal, prepared = self.setup_pair();prepared["citizens"][0]["rest"] = 1000
        self.assertFalse(sweep.setup_checks(normal, prepared)["only_one_explicit_announcement_changes_initial_state"])

    def test_setup_cannot_shorten_warning_or_replace_party(self):
        normal, prepared = self.setup_pair();prepared["defense_state"]["raids"][0]["due"] = 1800
        self.assertFalse(sweep.setup_checks(normal, prepared)["full_24_hour_warning_with_fixed_two_thief_party"])
        normal, prepared = self.setup_pair();prepared["defense_state"]["raids"][0]["party"] = ["hungry_thief"]
        self.assertFalse(sweep.setup_checks(normal, prepared)["full_24_hour_warning_with_fixed_two_thief_party"])

    def test_setup_must_preserve_actual_warning_and_history(self):
        normal, prepared = self.setup_pair();prepared["facts"][0]["kind"] = "raid_resolved"
        self.assertFalse(sweep.setup_checks(normal, prepared)["only_one_actual_warning_fact"])
        normal, prepared = self.setup_pair();prepared["chronicle_state"]["settlement"] = "Changed"
        self.assertFalse(sweep.setup_checks(normal, prepared)["only_one_actual_warning_fact"])

    def route(self):
        return [[(x, 40) for x in range(1, 65)], (0, 40), (64, 40), (33, 40), [2] * 16384, set(), set()]

    def test_real_contiguous_shortest_approach_accepts_midpoint(self):
        self.assertTrue(sweep.route_valid(*self.route()))

    def test_waiting_at_cart_is_not_the_interception_plan(self):
        args = self.route();args[3] = args[2]
        self.assertFalse(sweep.route_valid(*args))

    def test_route_cannot_walk_through_solid_nature(self):
        args = self.route();args[5].add((20, 40))
        self.assertFalse(sweep.route_valid(*args))

    def test_height_jump_needs_a_real_bridge(self):
        args = self.route();args[4][40 * 128 + 20] = 4
        self.assertFalse(sweep.route_valid(*args))
        args[6].add((20, 40))
        self.assertTrue(sweep.route_valid(*args))

    def test_detour_cannot_forge_the_midpoint_of_a_shortest_approach(self):
        args = self.route();args[0] = [(1, 40), (1, 39), (2, 39)] + [(x, 40) for x in range(2, 65)];args[3] = args[0][len(args[0]) // 2]
        self.assertFalse(sweep.route_valid(*args))

    def test_route_cannot_skip_a_walking_edge(self):
        args = self.route();args[0].pop(10);args[3] = args[0][len(args[0]) // 2]
        self.assertFalse(sweep.route_valid(*args))


if __name__ == "__main__":
    unittest.main()
