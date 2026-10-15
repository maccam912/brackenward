#!/usr/bin/env python3
"""Render retained boundary maps for human review; requires Pillow, changes no maps."""
import argparse
from collections import deque
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw

from validate_raw_map import distances, footprint, mirror, neighbors, strict_json, validate

ROOT = Path(__file__).resolve().parents[1]
SITES = ["meadow_reach", "pine_shelf", "reed_bend"]
TERRAIN = ["#5f98ac", "#bc9f70", "#a6b878", "#879574", "#716d88"]
SOIL = {750: "#c49d7e", 1000: "#a6b878", 1250: "#557454"}
RESOURCE = {"tree": "#375749", "berry_bush": "#9d4169", "herb_patch": "#f3e8cc", "mushroom_patch": "#c57353", "stone_node": "#263c3b", "clay_bank": "#c64b3c", "iron_seam": "#f2cc55"}
SEEDS = [0, 1, 42, 104729, 2147483647, 4294967295]
TILE = 3
MAP = 128*TILE
CELL = MAP+20
HEIGHT = MAP+53


def panel(data, catalog, view):
    buildings = {row["id"]: row for row in catalog["buildings"]}
    definitions = {row["id"]: row for row in catalog["resources"]}
    bridges = {tuple(p) for p in data["bridges"]}
    solid = {(r["x"], r["y"]) for r in data["resources"] if definitions[r["definition"]]["solid"]}
    for row in data["structures"]:
        if buildings[row["definition"]]["solid"] and row["definition"] != "supply_cart": solid |= footprint(row, buildings)
    starts = footprint(next(r for r in data["structures"] if r["definition"] == "supply_cart"), buildings)
    reached = distances(starts, data["elevation"], solid, bridges)
    flooded = {(x, y) for y in range(128) for x in range(128) if data["elevation"][y*128+x] == 0}
    queue = deque(flooded)
    while queue:
        for point in neighbors(queue.popleft()):
            if point not in flooded and data["elevation"][point[1]*128+point[0]] <= 1: flooded.add(point);queue.append(point)
    image = Image.new("RGB", (MAP, MAP));draw = ImageDraw.Draw(image)
    for y in range(128):
        for x in range(128):
            height = data["elevation"][y*128+x]
            color = TERRAIN[height]
            if view == "soil" and height: color = SOIL[data["fertility"][y*128+x]]
            if view == "access" and height:
                distance = reached.get((x, y), 16384)
                color = "#769b78" if distance <= 24 else "#b3c69a" if distance <= 40 else "#c1c4ba" if distance < 16384 else "#9b7372"
                if (x, y) in flooded: color = "#bc9f70"
                if (x, y) in solid: color = "#34473f"
            draw.rectangle((x*TILE, y*TILE, (x+1)*TILE-1, (y+1)*TILE-1), fill=color)
    for x, y in data["paths"]: draw.rectangle((x*TILE, y*TILE, (x+1)*TILE-1, (y+1)*TILE-1), fill="#f3e8cc")
    for x, y in bridges: draw.rectangle((x*TILE, y*TILE, (x+1)*TILE-1, (y+1)*TILE-1), fill="#895b44")
    if view in ["terrain", "access"]:
        for row in data["resources"]:
            if view == "access" and row["definition"] not in ["stone_node", "clay_bank", "iron_seam"]: continue
            x, y = row["x"]*TILE+1, row["y"]*TILE+1
            radius = 2 if row["definition"] in ["stone_node", "clay_bank", "iron_seam"] else 1
            draw.ellipse((x-radius, y-radius, x+radius, y+radius), fill=RESOURCE[row["definition"]])
        for row in data["animals"]:
            x, y = row["x"]*TILE+1, row["y"]*TILE+1
            draw.rectangle((x-2, y-2, x+2, y+2), outline="#f8f3e7" if row["definition"] != "boar" else "#ed77ac")
    for row in data["structures"]:
        if row["definition"] == "bridge": continue
        for x, y in footprint(row, buildings): draw.rectangle((x*TILE, y*TILE, (x+1)*TILE-1, (y+1)*TILE-1), fill="#716d88")
    for points, color in [([mirror((x, y), data["transform"]) for x, y in [(56, 52), (83, 75)]], "#f8f3e7"), (data["starter_field"], "#f2cc55")]:
        xs, ys = zip(*points)
        draw.rectangle((min(xs)*TILE, min(ys)*TILE, (max(xs)+1)*TILE-1, (max(ys)+1)*TILE-1), outline=color, width=1)
    return image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    source = json.loads((args.report_dir / "source.json").read_text())
    audit = json.loads((args.report_dir / "audit.json").read_text())
    if not audit["passed"] or source["start"] != 0 or source["count"] != 6 or audit["cases"] != 18: parser.error("Require the completed frozen eighteen-map boundary audit")
    catalog = json.loads((ROOT / "data/catalogs/colony_v6.json").read_text())
    digest = hashlib.sha256(json.dumps(catalog, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest()
    if source["catalog_hash"] != digest: parser.error("Review catalog must match frozen maps")
    if args.output.exists() and any(path.name != ".gdignore" for path in args.output.iterdir()): parser.error("Use a new empty output directory")
    args.output.mkdir(parents=True, exist_ok=True);(args.output / ".gdignore").touch()
    rows = []
    for site in SITES:
        maps = []
        for index, seed in enumerate(SEEDS):
            raw = (args.report_dir / "raw" / f"{site}-{index:05d}.json").read_bytes()
            data = strict_json(raw.decode());metrics = validate(data, catalog)
            if data["site"] != site or data["seed"] != seed or data["generator"] != source["generator_version"] or not metrics["passed"]: parser.error("Boundary map identity/geometry failed")
            maps.append(data);rows.append({"site": site, "seed": seed, "map_sha256": hashlib.sha256(raw).hexdigest(), "transform": data["transform"], "metrics": metrics})
        for view in ["terrain", "soil", "access"]:
            sheet = Image.new("RGB", (CELL*3, HEIGHT*2+72), "#263c3b");draw = ImageDraw.Draw(sheet)
            draw.text((10, 7), f"{site} / generator {source['generator_version']} / {view} / {source['commit'][:12]}", fill="#f8f3e7")
            legend = {"terrain": "Trees green; stone ink; clay red; iron gold; boar pink; other wildlife white.", "soil": "Poor brown / normal meadow / rich dark green. Water blue. Paths cream.", "access": "Shortest steps: <=24 green / <=40 pale green / farther gray / blocked dark. Future flood tan."}[view]
            draw.text((10, 25), legend, fill="#f8f3e7")
            draw.text((10, 43), "Home white outline; protected 8x8 field gold outline. No camera transform applied beyond saved geography.", fill="#f8f3e7")
            for index, data in enumerate(maps):
                x, y = (index%3)*CELL+10, (index//3)*HEIGHT+73
                draw.text((x, y), f"seed {data['seed']} / mirror {data['transform']} / attempt {data['attempt']}", fill="#f8f3e7")
                sheet.paste(panel(data, catalog, view), (x, y+19))
            sheet.save(args.output / f"{site}-{view}.png")
    images = {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in args.output.glob("*.png")}
    (args.output / "review-inputs.json").write_text(json.dumps({"scope": "Generated inspection views; rendering alone does not assert human approval or pin golden expectations", "source_commit": source["commit"], "source_json_sha256": hashlib.sha256((args.report_dir / "source.json").read_bytes()).hexdigest(), "renderer_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), "maps": rows, "images": images}, indent=2)+"\n")
    print(json.dumps({"maps": len(rows), "images": len(images), "output": str(args.output)}))


if __name__ == "__main__": main()
