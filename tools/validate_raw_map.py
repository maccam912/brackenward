#!/usr/bin/env python3
"""Independent geometry checks over exported data; does not call Godot validators."""
from collections import Counter, deque
import hashlib
import json

SIZE = 128
COUNTS = {"berry_bush": 10, "herb_patch": 6, "mushroom_patch": 6, "tree": 30, "stone_node": 4, "clay_bank": 3, "iron_seam": 3}
WILDLIFE = {"hare": 6, "deer": 4, "boar": 2, "marsh_goose": 4}


def neighbors(point):
    x, y = point
    return [(a, b) for a, b in [(x, y-1), (x+1, y), (x, y+1), (x-1, y)] if 0 <= a < SIZE and 0 <= b < SIZE]


def tile(value):
    if not isinstance(value, (list, tuple)) or len(value) != 2 or not all(type(n) is int and 0 <= n < SIZE for n in value):
        raise ValueError("Invalid tile")
    return tuple(value)


def mirror(point, transform):
    x, y = point
    return (127-x if transform in [1, 3] else x, 127-y if transform in [2, 3] else y)


def footprint(row, buildings):
    definition = buildings[row["definition"]]
    width, height = definition["width"], definition["height"]
    if row["rotation"] % 2: width, height = height, width
    return {tile((row["x"] + x, row["y"] + y)) for y in range(height) for x in range(width)}


def distances(starts, elevations, solid, bridges, flooded=frozenset()):
    def usable(p):
        return p not in solid and (elevations[p[1]*SIZE+p[0]] > 0 or p in bridges) and (p not in flooded or p in bridges)
    if isinstance(starts, tuple) and len(starts) == 2 and all(type(n) is int for n in starts): starts = [starts]
    result = {point: 0 for point in starts if usable(point)}
    queue = deque(sorted(result))
    while queue:
        point = queue.popleft()
        height = elevations[point[1]*SIZE+point[0]]
        for adjacent in neighbors(point):
            if adjacent in result or not usable(adjacent): continue
            if abs(height-elevations[adjacent[1]*SIZE+adjacent[0]]) > 1 and adjacent not in bridges and point not in bridges: continue
            result[adjacent] = result[point]+1
            queue.append(adjacent)
    return result


def validate(data, catalog):
    """Return explicit failures/observations. Generator success flags are ignored."""
    errors = []
    try:
        if data["format"] != "brackenward-raw-map" or type(data["version"]) is not int or data["version"] != 1 or type(data["generator"]) is not int or data["generator"] not in [1, 2]: raise ValueError("Unsupported raw map format/generator")
        if type(data["seed"]) is not int or not 0 <= data["seed"] <= 4294967295: raise ValueError("Invalid seed")
        if data["site"] not in {"meadow_reach", "pine_shelf", "reed_bend"}: raise ValueError("Invalid site")
        if data["weather"] not in {"clear", "rain", "fog", "snow", "drought", "cold_snap", "flood"}: raise ValueError("Unknown starting weather")
        transform, attempt = data["transform"], data["attempt"]
        if type(transform) is not int or transform not in range(4) or type(attempt) is not int or attempt not in range(33): raise ValueError("Invalid generation metadata")
        if type(data["fallback"]) is not bool or data["fallback"] != (attempt == 32): raise ValueError("Fallback/attempt mismatch")
        if not isinstance(data["diagnostics"], list) or len(data["diagnostics"]) != attempt or not all(isinstance(s, str) and len(s) <= 256 for s in data["diagnostics"]): errors.append("attempt diagnostics count/bounds")
        elevations, fertility = data["elevation"], data["fertility"]
        if len(elevations) != SIZE*SIZE or len(fertility) != SIZE*SIZE: raise ValueError("Incomplete terrain arrays")
        if not all(type(x) is int and 0 <= x <= 4 for x in elevations): raise ValueError("Invalid elevation")
        if not all(type(x) is int and x in {750, 1000, 1250} for x in fertility): raise ValueError("Invalid fertility")
        def original_value(values, x, y):
            a, b = mirror((x, y), transform)
            return values[b*SIZE+a]
        band = 4 if data["fallback"] else {"meadow_reach": 4, "pine_shelf": 3, "reed_bend": 6}[data["site"]]
        centers = []
        for y in range(SIZE):
            columns = [x for x in range(SIZE) if original_value(elevations, x, y) == 0]
            if len(columns) != 4 or columns != list(range(columns[0], columns[0]+4)) or not 28 <= columns[0]+1 <= 40:
                errors.append("four-wide continuous river"); break
            centers.append(columns[0]+1)
            if any(original_value(elevations, x, y) != 1 for x in list(range(columns[0]-band, columns[0])) + list(range(columns[-1]+1, columns[-1]+band+1))): errors.append("site flood band width")
        if len(centers) == SIZE:
            if any(centers[y] != (centers[y//16*16]*(16-y%16)+centers[(y//16+1)*16]*(y%16))//16 for y in range(112)): errors.append("integer-interpolated river anchors")
            if not any(all(centers[y] == (centers[112]*(16-(y-112))+endpoint*(y-112))//16 for y in range(112, 128)) for endpoint in range(28, 41)): errors.append("final river anchor")
        if sum(n == 1 for n in elevations) != 2*band*SIZE: errors.append("unexpected floodplain outside river band")
        if any(original_value(elevations, x, y) != (3 if x < 112 else 4) for y in range(SIZE) for x in range(96, 128)): errors.append("transformed eastern uplands")
        resources = {r["id"]: r for r in data["resources"]}
        buildings = {r["id"]: r for r in catalog["buildings"]}
        definitions = {r["id"]: r for r in catalog["resources"]}
        structures = {r["id"]: r for r in data["structures"]}
        records = data["citizens"] + data["resources"] + data["structures"] + data["animals"]
        ids = [r["id"] for r in records]
        if not all(type(n) is int and n > 0 for n in ids) or len(set(ids)) != len(ids): raise ValueError("Duplicate/invalid actor or object IDs")
        if len(resources) != len(data["resources"]) or len(structures) != len(data["structures"]): raise ValueError("Duplicate records")
        paths = {tile(p) for p in data["paths"]}
        bridges = {tile(p) for p in data["bridges"]}
        field = {tile(p) for p in data["starter_field"]}
        expected_field = {mirror((x, y), transform) for y in range(54, 62) for x in range(74, 82)}
        home = {mirror((x, y), transform) for y in range(52, 76) for x in range(56, 84)}
        expected_paths = {mirror((x, y), transform) for y in [63, 64] for x in range(128)} | {mirror((x, y), transform) for x in [66, 67] for y in range(128)}
        if len(field) != len(data["starter_field"]) or field != expected_field: errors.append("connected exact 8x8 starter field")
        if paths != expected_paths or len(paths) != len(data["paths"]): errors.append("transformed two-tile trails")
        if len(bridges) != 4 or len(bridges) != len(data["bridges"]): errors.append("four authored crossing tiles")
        if any(elevations[y*SIZE+x] != 2 or fertility[y*SIZE+x] < 1000 for x, y in home): errors.append("protected safe fertile home")
        if any(fertility[y*SIZE+x] != 1000 for x, y in field): errors.append("normal fertile starter field")
        for cy in range(0, SIZE, 8):
            for cx in range(0, SIZE, 8):
                points = {mirror((x, y), transform) for y in range(cy, cy+8) for x in range(cx, cx+8)}
                ordinary = {fertility[y*SIZE+x] for x, y in points-home}
                protected = {fertility[y*SIZE+x] for x, y in (points & home)-field}
                if len(ordinary) > 1 or len(protected) > 1: errors.append("coarse-cell soil inheritance")
                if ordinary and protected and protected != {max(1000, next(iter(ordinary)))}: errors.append("protected coarse-cell soil adjustment")
        solid = set()
        resource_points = set()
        tree_points = set()
        for row in resources.values():
            point = tile((row["x"], row["y"]))
            definition = definitions[row["definition"]]
            if point in resource_points: errors.append("natural object collision")
            resource_points.add(point)
            if point in home or point in paths or elevations[point[1]*SIZE+point[0]] == 0: errors.append("resource on protected/water tile")
            if type(row["remaining"]) is not int or row["remaining"] != definition["yield_count"]: errors.append("initial remaining resource quantity")
            if definition["solid"]: solid.add(point)
            if row["definition"] == "tree": tree_points.add(point)
        occupied = set()
        initial_kinds = Counter(row["definition"] for row in structures.values())
        if initial_kinds != Counter({"bedroll": 4, "supply_cart": 1, "hearth": 1, "bridge": 4}): errors.append("initial structures")
        actual_bridges = set()
        for row in structures.values():
            if type(row["rotation"]) is not int or row["rotation"] not in range(4): raise ValueError("Invalid structure rotation")
            points = footprint(row, buildings)
            if occupied & points: errors.append("overlapping structures")
            occupied |= points
            if type(row["health"]) is not int or row["health"] <= 0: errors.append("destroyed/invalid starting structure")
            if row["definition"] == "bridge": actual_bridges |= points
            if buildings[row["definition"]]["solid"] and row["definition"] != "supply_cart": solid |= points
        if actual_bridges != bridges: errors.append("bridge state differs from actual structures")
        if occupied & resource_points: errors.append("resource overlaps starting footprint")
        for definition, anchors in {"supply_cart": [(66, 63)], "hearth": [(70, 62)], "bedroll": [(62, 59), (64, 59), (62, 61), (64, 61)]}.items():
            shape = buildings[definition]
            expected = {frozenset(mirror((x+dx, y+dy), transform) for dy in range(shape["height"]) for dx in range(shape["width"])) for x, y in anchors}
            actual = {frozenset(footprint(r, buildings)) for r in structures.values() if r["definition"] == definition}
            if actual != expected: errors.append("transformed starting footprint: " + definition)
        carts = [r for r in structures.values() if r["definition"] == "supply_cart"]
        if len(carts) != 1: raise ValueError("Missing/duplicate starting cart")
        starts = footprint(carts[0], buildings)
        reached = distances(starts, elevations, solid, bridges)
        safe_buildable = sum(elevations[y*SIZE+x] >= 2 and (x, y) not in occupied for x, y in reached)
        if safe_buildable < 1024: errors.append("fewer than 1024 reachable safe buildable tiles")
        if not field <= reached.keys(): errors.append("starter field unreachable")
        water = {(x, y) for y in range(SIZE) for x in range(SIZE) if elevations[y*SIZE+x] == 0}
        flood = set(water)
        queue = deque(water)
        while queue:
            point = queue.popleft()
            for adjacent in neighbors(point):
                if adjacent not in flood and elevations[adjacent[1]*SIZE+adjacent[0]] <= 1:
                    flood.add(adjacent); queue.append(adjacent)
        if home & flood or field & flood: errors.append("flood overlaps protected start")
        dry = distances(starts, elevations, solid, bridges, flood)
        if not any(x in [0, 127] or y in [0, 127] for x, y in dry): errors.append("no dry boundary route")
        # Floodplain is usable at the actual clear start. Separately assert the
        # protected home/field and a boundary route avoid the maximum flood mask;
        # future floodwater may close the remote bridge approaches.
        current_reached = dry if data["weather"] == "flood" else reached
        if not any(any(p in water for p in neighbors(point)) for point in current_reached): errors.append("no safe river access")
        if len(data["citizens"]) != 4 or {p["id"] for p in data["citizens"]} != {1, 2, 3, 4}: errors.append("starting residents")
        assigned = set()
        for person in data["citizens"]:
            point = tile((person["x"], person["y"]))
            bed = structures[person["bed"]]
            bed_point = tile((bed["x"], bed["y"]))
            if point not in dry or bed_point not in dry or bed["definition"] != "bedroll" or bed["user"] != person["id"] or bed["id"] in assigned: errors.append("unusable assigned starting bed/arrival")
            if point != mirror((64+person["id"], 65), transform): errors.append("transformed resident arrival")
            assigned.add(bed["id"])
        if any(not footprint(row, buildings) <= current_reached.keys() for row in structures.values()): errors.append("initial structure lacks nonflooded route")
        near_quantity = Counter()
        extra_quantity = Counter()
        food = 0
        for row in resources.values():
            point = (row["x"], row["y"])
            distance = min((reached.get(p, SIZE*SIZE) for p in neighbors(point)), default=SIZE*SIZE)
            if distance == SIZE*SIZE: errors.append("resource has no reachable work tile")
            if distance <= 24: near_quantity[row["definition"]] += row["remaining"]
            if distance <= 40: extra_quantity[row["definition"]] += row["remaining"]
            if row["definition"] in {"berry_bush", "mushroom_patch"} and distance < SIZE*SIZE: food += row["remaining"]
        for definition, minimum in COUNTS.items():
            if near_quantity[definition] < minimum*definitions[definition]["yield_count"]: errors.append("insufficient reachable start-ring quantity: " + definition)
        extra = {"pine_shelf": ("stone_node", 4), "reed_bend": ("clay_bank", 3)}.get(data["site"])
        if extra and extra_quantity[extra[0]] < (COUNTS[extra[0]]+extra[1])*definitions[extra[0]]["yield_count"]: errors.append("insufficient reachable site-extra quantity")
        if food < 40: errors.append("fewer than forty reachable wild food units")
        species_counts = Counter(row["definition"] for row in data["animals"])
        if species_counts != Counter(WILDLIFE): errors.append("initial wildlife counts")
        animal_points = set()
        for row in data["animals"]:
            point = tile((row["x"], row["y"]))
            species = row["definition"]
            if point in animal_points or point in occupied or point in resource_points or point in home: errors.append("wildlife spawn collision")
            animal_points.add(point)
            if reached.get(point, -1) < (40 if species == "boar" else 30): errors.append("unreachable/unsafe wildlife distance")
            if point not in {tile(p) for p in data["habitats"][species]}: errors.append("animal outside declared habitat")
            near_tree = any(p in tree_points for p in neighbors(point))
            height = elevations[point[1]*SIZE+point[0]]
            if species in {"hare", "deer"} and (not near_tree or height != 2): errors.append("invalid meadow wildlife habitat")
            if species == "boar" and (not near_tree or height < 3): errors.append("invalid boar upland woodland")
            if species == "marsh_goose" and not any((point[0]+x, point[1]+y) in water for x in range(-4, 5) for y in range(-4, 5) if abs(x)+abs(y) <= 4): errors.append("goose farther than four from river")
        if set(data["habitats"]) != set(WILDLIFE) or any(len(data["habitats"][s]) != n for s, n in WILDLIFE.items()): errors.append("habitat counts")
        nodes = {(n["x"], n["y"]): n["definition"] for n in data["regions"]}
        if any(type(n[key]) is not int or not 0 <= n[key] < 9 for n in data["regions"] for key in ["x", "y"]): errors.append("regional coordinate encoding")
        if len(data["regions"]) != 81 or set(nodes) != {(x, y) for y in range(9) for x in range(9)} or nodes.get((4, 4)) != "home": errors.append("regional grid/home")
        destinations = {r["id"] for r in catalog["expeditions"] + catalog["communities"]}
        labels = Counter(nodes.values())
        if set(labels) != destinations | {"transit", "home"} or labels["home"] != 1: errors.append("unknown/missing regional labels")
        if any(labels[name] != 1 for name in destinations): errors.append("missing/duplicate Charter destination")
        if any(abs(x-4)+abs(y-4) > 4 for (x, y), name in nodes.items() if name in destinations): errors.append("Charter destination beyond four edges")
        return {"passed": not errors, "errors": sorted(set(errors)), "safe_buildable": safe_buildable, "reachable_tiles": len(reached), "dry_reachable_tiles": len(dry), "wild_food_units": food, "start_ring_quantities": dict(near_quantity), "site_ring_quantities": dict(extra_quantity), "resource_counts": dict(Counter(r["definition"] for r in resources.values())), "wildlife_counts": dict(species_counts)}
    except (KeyError, TypeError, ValueError, IndexError) as error:
        return {"passed": False, "errors": ["Malformed raw map: " + str(error)]}


def strict_json(text):
    def pairs(values):
        result = {}
        for key, value in values:
            if key in result: raise ValueError("Duplicate JSON key")
            result[key] = value
        return result
    def constant(value):
        raise ValueError("Nonfinite JSON number")
    return json.loads(text, object_pairs_hook=pairs, parse_constant=constant)


def exported(line, catalog):
    envelope = strict_json(line.removeprefix("GENMAP "))
    payload = envelope["payload"]
    if not isinstance(payload, str): raise ValueError("Raw map payload must be text")
    if hashlib.sha256(payload.encode()).hexdigest() != envelope["sha256"]: raise ValueError("Raw map checksum mismatch")
    data = strict_json(payload)
    return data, envelope, validate(data, catalog)
