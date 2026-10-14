#!/usr/bin/env python3
"""Retain only inspected Tiny Town components for the environment authoring tool."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
LICENSE_SHA = "c483c167cc3bdfe17c15f957ff847d409f64d81b410b28783636cf3b2b7814c5"
# Coordinates were reviewed on reports/tiny-town-contact.png, never guessed.
TILES = {"grass_plain": (0, 0), "grass_speckled": (1, 0), "grass_flowers": (2, 0),
         "conifer_top": (4, 0), "conifer_base": (4, 1), "round_canopy": (5, 0),
         "sapling": (5, 1), "fence_left": (8, 3), "fence_middle": (9, 3),
         "fence_right": (10, 3), "roof_shingles": (1, 4), "stone_wall": (5, 6),
         "wood_door": (1, 7), "stone_door": (5, 7), "hammer": (7, 9),
         "farm_fork": (8, 9), "bow": (10, 9), "axe": (11, 9), "stone_path": (6, 10)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path.home() / "Downloads/Kenney Game Assets All-in-1 3.5.0/2D assets/Tiny Town")
    args = parser.parse_args()
    license_source = args.source / "License.txt"
    assert hashlib.sha256(license_source.read_bytes()).hexdigest() == LICENSE_SHA, "Unreviewed Tiny Town license"
    evidence = ROOT / "assets/licenses/kenney_tiny_town.txt"
    shutil.copyfile(license_source, evidence)
    destination = ROOT / "assets/source/tiny-town"
    destination.mkdir(parents=True, exist_ok=True)
    atlas = Image.open(args.source / "Tilemap/tilemap_packed.png").convert("RGBA")
    records = {}
    preview = Image.new("RGB", (5 * 144, 4 * 106), "#F3E8CC")
    labels = ImageDraw.Draw(preview)
    for index, (semantic, (x, y)) in enumerate(TILES.items()):
        filename = f"tile_{y * 12 + x:04d}.png"
        source = args.source / "Tiles" / filename
        copied = destination / filename
        shutil.copyfile(source, copied)
        pixels = Image.open(copied).convert("RGBA")
        assert pixels.size == (16, 16) and pixels.tobytes() == atlas.crop((x * 16, y * 16, x * 16 + 16, y * 16 + 16)).tobytes(), semantic
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        records[semantic] = {"source": f"Kenney Game Assets All-in-1 3.5.0/2D assets/Tiny Town/Tiles/{filename}",
                             "path": str(copied.relative_to(ROOT)), "sha256": digest,
                             "packed_atlas_rectangle": [x * 16, y * 16, 16, 16], "author": "Kenney",
                             "license": "CC0-1.0", "evidence": str(evidence.relative_to(ROOT)), "edited": False}
        position = (index % 5 * 144 + 36, index // 5 * 106)
        art = pixels.resize((64, 64), Image.Resampling.NEAREST)
        preview.paste(art, position, art)
        labels.text((index % 5 * 144 + 3, index // 5 * 106 + 70), semantic, fill="#263C3B")
        labels.text((index % 5 * 144 + 3, index // 5 * 106 + 85), f"{filename} ({x},{y})", fill="#263C3B")
    (ROOT / "data/environment_sources.json").write_text(json.dumps({"pack": "Tiny Town 1.1", "license_sha256": LICENSE_SHA, "components": records}, indent=2) + "\n")
    preview.save(ROOT / "assets/licenses/tiny_town_used_preview.png")
    print(f"Retained {len(records)} inspected components, their exact source bytes and the pinned license")


if __name__ == "__main__":
    main()
