#!/usr/bin/env python3
"""Hand-authored synthetic map contracts, independent of the Godot generator."""
import copy
import hashlib
import json
from pathlib import Path
import unittest

from validate_raw_map import COUNTS, exported, neighbors, strict_json, validate

CATALOG = json.loads((Path(__file__).resolve().parents[1] / "data/catalogs/colony_v6.json").read_text())


def synthetic_map(site="meadow_reach"):
    """A valid flat fixture, never a generated seed or release certificate."""
    band = {"meadow_reach": 4, "pine_shelf": 3, "reed_bend": 6}[site]
    elevation = [2] * 16384
    for y in range(128):
        for x in range(32-band, 36+band): elevation[y*128+x] = 0 if 32 <= x <= 35 else 1
        for x in range(96, 128): elevation[y*128+x] = 3 if x < 112 else 4
    paths = {(x, y) for y in [63, 64] for x in range(128)} | {(x, y) for x in [66, 67] for y in range(128)}
    data = {"format": "brackenward-raw-map", "version": 1, "generator": 1, "seed": 0, "index": 0,
            "site": site, "transform": 0, "attempt": 0, "fallback": False, "diagnostics": [], "weather": "clear",
            "elevation": elevation, "fertility": [1000]*16384, "paths": [list(p) for p in sorted(paths)],
            "bridges": [[x, 63] for x in range(32, 36)],
            "starter_field": [[x, y] for y in range(54, 62) for x in range(74, 82)],
            "resources": [], "structures": [], "citizens": [], "animals": [], "habitats": {}, "regions": []}
    anchors = [(62, 59), (64, 59), (62, 61), (64, 61), (66, 63), (70, 62)]
    for index, (x, y) in enumerate(anchors):
        data["structures"].append({"id": 5+index, "definition": "bedroll" if index < 4 else ("supply_cart" if index == 4 else "hearth"), "x": x, "y": y, "rotation": 0, "health": 100, "user": index+1 if index < 4 else 0})
    for index, x in enumerate(range(32, 36)):
        data["structures"].append({"id": 11+index, "definition": "bridge", "x": x, "y": 63, "rotation": 0, "health": 100, "user": 0})
    data["citizens"] = [{"id": i+1, "x": 65+i, "y": 65, "bed": 5+i} for i in range(4)]
    definitions = {r["id"]: r for r in CATALOG["resources"]}
    eligible = [(x, y) for y in range(43, 81) for x in range(50, 90, 2)
                if abs(x-66)+abs(y-63) <= 22 and (x, y) not in paths and not (56 <= x <= 83 and 52 <= y <= 75)]
    assert len(eligible) >= sum(COUNTS.values())

    def resource(kind, point):
        data["resources"].append({"id": 100+len(data["resources"]), "definition": kind, "x": point[0], "y": point[1], "remaining": definitions[kind]["yield_count"]})
    for kind, count in COUNTS.items():
        for _ in range(count): resource(kind, eligible.pop(0))
    if site == "pine_shelf":
        for y in [58, 60, 66, 68]: resource("stone_node", (86, y))
    if site == "reed_bend":
        for y in [58, 60, 66]: resource("clay_bank", (86, y))
    animal_points = {"hare": [(90, y) for y in [5, 15, 25, 35, 95, 105]],
                     "deer": [(92, y) for y in [10, 30, 90, 110]],
                     "boar": [(100, 15), (100, 108)],
                     "marsh_goose": [(36, y) for y in [10, 20, 90, 110]]}
    for species, points in animal_points.items():
        data["habitats"][species] = [list(p) for p in points]
        for x, y in points:
            if species != "marsh_goose": resource("tree", (x+1, y))
            data["animals"].append({"id": 1000+len(data["animals"]), "definition": species, "x": x, "y": y})
    destinations = {(4, 4): "home"}
    offsets = [(-1, 0), (1, 0), (0, -1), (0, 1), (-2, 1), (2, -1), (1, 2), (-1, -2)]
    for row, (x, y) in zip(CATALOG["expeditions"], offsets): destinations[x+4, y+4] = row["id"]
    for row, (x, y) in zip(CATALOG["communities"], [(-2, 0), (2, 0), (0, 2)]): destinations[x+4, y+4] = row["id"]
    data["regions"] = [{"x": x, "y": y, "definition": destinations.get((x, y), "transit")} for y in range(9) for x in range(9)]
    return data


class RawMapChecks(unittest.TestCase):
    def setUp(self):
        self.data = synthetic_map()

    def test_hand_authored_valid_sites_and_no_input_mutation(self):
        for site in ["meadow_reach", "pine_shelf", "reed_bend"]:
            data = synthetic_map(site); before = copy.deepcopy(data)
            result = validate(data, CATALOG)
            with self.subTest(site=site): self.assertTrue(result["passed"], result["errors"])
            self.assertEqual(data, before)

    def reject(self, mutation):
        data = copy.deepcopy(self.data); mutation(data)
        self.assertFalse(validate(data, CATALOG)["passed"])

    def test_protected_home_field_soil_and_flood_failures(self):
        for mutation in [lambda d: d["elevation"].__setitem__(59*128+62, 0),
                         lambda d: d["fertility"].__setitem__(54*128+74, 750),
                         lambda d: d["starter_field"].pop(),
                         lambda d: d["fertility"].__setitem__(3*128+3, 750)]:
            self.reject(mutation)

    def test_resource_quantities_and_geometry_cannot_be_replaced_by_success_flag(self):
        self.data["generator_success"] = True
        self.reject(lambda d: d["resources"][0].__setitem__("remaining", 0))
        self.reject(lambda d: d["resources"][0].update(x=70, y=70))
        self.reject(lambda d: d["resources"][0].update(x=32, y=10))
        self.reject(lambda d: d["resources"][0].update(x=66, y=20))

    def test_missing_crossing_bed_and_bad_transform_are_rejected(self):
        self.reject(lambda d: d["bridges"].pop())
        self.reject(lambda d: d["structures"][0].__setitem__("user", 2))
        self.reject(lambda d: d.__setitem__("transform", 1))
        self.reject(lambda d: d["citizens"][0].update(x=80, y=70))

    def test_unsafe_or_wrong_species_habitat_is_rejected(self):
        self.reject(lambda d: d["animals"][0].update(x=65, y=66))
        self.reject(lambda d: d["animals"][-1].update(x=60, y=90))
        self.reject(lambda d: d["animals"].pop())

    def test_resource_work_position_is_checked_from_actual_collision_geometry(self):
        data = copy.deepcopy(self.data)
        seam = next(row for row in data["resources"] if row["definition"] == "iron_seam")
        occupied = {(r["x"], r["y"]) for r in data["resources"]}
        for point in neighbors((seam["x"], seam["y"])):
            if point in occupied: continue
            data["resources"].append({"id": 2000+len(data["resources"]), "definition": "tree", "x": point[0], "y": point[1], "remaining": 8})
        result = validate(data, CATALOG)
        self.assertFalse(result["passed"])
        self.assertIn("resource has no reachable work tile", result["errors"])

    def test_region_and_id_failures(self):
        self.reject(lambda d: d["regions"][0].update(x=20))
        self.reject(lambda d: d["regions"].pop())
        self.reject(lambda d: d["resources"][0].__setitem__("id", 1))

    def test_malformed_bounds_types_and_attempts(self):
        for mutation in [lambda d: d["elevation"].pop(), lambda d: d["elevation"].__setitem__(0, True),
                         lambda d: d["resources"][0].update(x=-1), lambda d: d.__setitem__("attempt", 1),
                         lambda d: d.__setitem__("fallback", True), lambda d: d.__setitem__("generator", True)]:
            self.reject(mutation)

    def test_export_checksum_and_strict_json(self):
        payload = json.dumps(self.data, separators=(",", ":"), sort_keys=True)
        line = "GENMAP " + json.dumps({"payload": payload, "sha256": hashlib.sha256(payload.encode()).hexdigest()})
        data, envelope, result = exported(line, CATALOG)
        self.assertTrue(result["passed"], result["errors"])
        self.assertEqual(data, self.data)
        with self.assertRaises(ValueError): exported(line.replace(envelope["sha256"], "0"*64), CATALOG)
        for malformed in ['{"a":1,"a":2}', '{"n":NaN}', '{"n":Infinity}']:
            with self.assertRaises(ValueError): strict_json(malformed)


if __name__ == "__main__":
    unittest.main()
