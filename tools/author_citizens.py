#!/usr/bin/env python3
"""Original pixel artwork source. Requires Pillow only when rebuilding assets.

Eight clothing silhouettes, eight independent hair shapes, 99 authored poses.
RGB cube corners are palette indices, decoded by citizen_palette.gdshader.
The source, exported masks and matching portrait masks are project artwork.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
MASK = [(0, 0, 0, 255), (0, 0, 255, 255), (0, 255, 0, 255), (0, 255, 255, 255),
        (255, 0, 0, 255), (255, 0, 255, 255), (255, 255, 0, 255), (255, 255, 255, 255)]
STATES = [("idle", 2, 4), ("walk", 4, 4), ("carry", 4, 4), ("work", 3, 4), ("plant", 3, 4),
          ("eat", 2, 1), ("talk", 2, 1), ("sleep", 2, 1), ("melee", 3, 4), ("shoot", 3, 4),
          ("hurt", 1, 1), ("downed", 1, 1), ("cheer", 3, 1)]
PALETTE = ["263C3B", "716D88", "4C3531", "F3E8CC", "C98D66", "375749", "E9BA67", "F8F3E7"]
TRAITS = {
    "kind": '<path d="M32 49 14 31C1 15 21 8 32 22 43 8 63 15 50 31Z" fill="#B96C50"/>',
    "homebody": '<path d="M10 30 32 12 54 30M17 26V52H47V26M27 52V36H37V52"/>',
    "steady": '<path d="M32 14V46M15 32C15 55 49 55 49 32M10 37 15 31 21 37M43 37 49 31 54 37M23 25H41"/><circle cx="32" cy="13" r="5"/>',
    "sociable": '<circle cx="21" cy="22" r="7"/><circle cx="44" cy="22" r="7"/><path d="M10 48C10 32 32 32 32 48M33 48C33 32 55 32 55 48M25 13 32 7 39 13"/>',
    "outdoorsy": '<path d="M13 48C7 20 30 11 51 13 53 35 40 53 21 49M16 47 42 22M27 35V23M28 35H42" fill="#77915A"/>',
    "restless": '<path d="M14 38C-1 18 31 3 43 16M36 10 45 17 36 23M50 26C65 46 33 61 21 48M29 41 19 47 29 54"/>',
    "curious": '<circle cx="28" cy="27" r="15"/><path d="M39 39 53 53M23 23C23 16 36 19 29 26L28 31M28 36H28"/>',
    "private": '<path d="M15 13H44V52H15Q9 48 15 43H44M19 13V43M32 21V34L36 31 40 34V21Z"/><path d="M15 48H43"/>',
}


def pose(body, hair, state, frame, direction):
    image = Image.new("RGBA", (16, 24))
    d = ImageDraw.Draw(image)

    def box(rect, color, outline=False):
        d.rectangle(rect, fill=MASK[color], outline=MASK[0] if outline else None)

    side = direction in (1, 3)
    back = direction == 2
    breath = frame % 2 if state in ("idle", "talk", "sleep") else 0
    crouch = 3 if state == "plant" else 0
    lift = -1 if state == "cheer" and frame == 1 else 0
    top = 10 + crouch + lift
    head = 2 + crouch + lift + breath
    hem = [18, 20, 17, 19, 19, 18, 20, 19][body]
    half = [4, 5, 4, 4, 5, 4, 5, 4][body]
    step = [0, -1, 0, 1][frame % 4] if state in ("walk", "carry") else 0
    # Boots and legs stay at the same ground anchor. Coats never change collision.
    box((5, 17, 7, 22 - step), 5, True)
    box((9, 17, 11, 22 + step), 5, True)
    box((4, 22 - step, 7, 23 - step), 0)
    box((9, 22 + step, 12, 23 + step), 0)
    # Arms behind the torso. All four facings have their own silhouettes.
    left_y, right_y = top + 2 + step, top + 2 - step
    if state in ("work", "melee"): right_y = [top + 3, top - 2, top + 1][frame]
    if state == "shoot": left_y = right_y = top + 1
    if state == "cheer": left_y = right_y = top - 3 - (frame == 1)
    if state in ("carry", "eat"): left_y = right_y = top + 1
    box((2 if not side else 4, left_y, 5, left_y + 5), 1, True)
    box((11 if not side else 10, right_y, 14 if not side else 12, right_y + 5), 1, True)
    box((3 if not side else 4, left_y + 4, 4 if not side else 5, left_y + 5), 4)
    box((12 if not side else 11, right_y + 4, 13 if not side else 12, right_y + 5), 4)
    box((8 - (3 if side else half), top, 8 + (3 if side else half), hem), 1, True)
    # Distinct seams, hems, wraps, aprons and closures for eight silhouettes.
    if body in (0, 1, 5):
        box((7, top + 2, 8, hem - 1), 3)
        if body == 1: box((4, hem - 2, 12, hem - 1), 6)
        if body == 5: box((6, top + 2, 9, top + 5), 3)
    if body == 2: box((5, hem - 1, 11, hem - 1), 6)
    if body == 3:
        box((6, top + 2, 10, hem - 1), 3)
        box((7, top + 5, 9, top + 6), 1)
    if body == 4:
        d.line((4, top + 2, 12, top + 6), fill=MASK[6], width=2)
        box((4, hem - 1, 12, hem - 1), 6)
    if body == 6:
        d.polygon([(8, top), (3, hem), (13, hem)], fill=MASK[1], outline=MASK[0])
        box((7, top + 1, 9, top + 3), 6)
    if body == 7: box((6, top + 2, 10, hem - 2), 6)
    if not back:
        box((5 if not side else 7, top + 1, 11, top + 2), 6)
        box((10, top + 2, 11, top + 5), 6)
        if body in (0, 1, 2, 5): box((5, hem - 4, 6, hem - 3), 7)
    # Neck, adult head, ears, face and eight independent hair shapes.
    box((7, head + 7, 9, top + 1), 4)
    box((4 if not side else 5, head + 1, 11, head + 6), 4, True)
    box((3 if not side else 4, head + 3, 12 if not side else 11, head + 4), 4)
    box((5, head, 10, head + 2), 2)
    box((4, head + 1, 11, head + 2), 2)
    if hair == 0: box((4, head + 2, 5, head + 3), 2)  # swept crop
    if hair == 1:
        box((3, head + 1, 5, head + 6), 2);box((10, head + 1, 12, head + 6), 2)
    if hair == 2:
        box((5, head - 1, 7, head + 1), 2);box((9, head - 1, 10, head), 2)
        box((3, head + 2, 4, head + 4), 2);box((11, head + 2, 12, head + 4), 2)
    if hair == 3:
        box((7, head - 2, 9, head), 2);box((10, head + 2, 12, head + 3), 2)
    if hair == 4:
        box((4, head + 2, 5, head + 9), 2);box((10, head + 2, 11, head + 9), 2)
    if hair == 5:
        box((10, head + 2, 12, head + 7), 2);box((11, head + 7, 13, head + 8), 2)
    if hair == 6:
        box((5, head, 10, head), 4);box((5, head + 1, 6, head + 1), 4)
    if hair == 7:
        box((3, head + 1, 5, head + 6), 2);box((11, head + 1, 12, head + 8), 2)
        box((4, head + 7, 5, head + 10), 2)
    if back:
        box((5, head + 2, 10, head + 5), 2)
    elif side:
        box((10, head + 3, 10, head + 3), 0);box((11, head + 4, 12, head + 4), 4)
    else:
        box((6, head + 3, 6, head + 3), 0);box((9, head + 3, 9, head + 3), 0)
        box((7, head + 5, 8, head + 5), 3)
    if state == "carry":
        box((3, top + 4, 13, top + 8), 3, True)
        box((4, top + 5, 12, top + 5), 6)
        box((5, top + 7, 11, top + 7), 6)
        box((3, top + 4, 4, top + 5), 4);box((12, top + 4, 13, top + 5), 4)
    if state == "eat":
        box((9, top + 2 - frame, 12, top + 3 - frame), 3, True)
        box((10, top + 1 - frame, 11, top + 1 - frame), 6)
    if state in ("sleep", "downed"):
        image = Image.new("RGBA", (16, 24));d = ImageDraw.Draw(image)
        box((1, 15 + breath, 5, 19 + breath), 4, True)
        box((1, 14 + breath, 4, 16 + breath), 2)
        box((5, 14, 14, 21), 1, True)
        box((6, 15, 13, 16), 6)
        if state == "downed": box((7, 16, 11, 20), 3, True)
    if state == "hurt": box((3, top + 4, 6, top + 5), 4)
    if direction == 3: image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return image


def recolor(image, palette):
    result = image.copy()
    remap = dict(zip(MASK, [tuple(bytes.fromhex(c)) + (255,) for c in palette]))
    result.putdata([remap.get(pixel, (0, 0, 0, 0)) for pixel in image.get_flattened_data()])
    return result


def main():
    exported = ROOT / "assets/exported/citizens"
    sheet = Image.new("RGBA", (8 * 11 * 16, 8 * 9 * 24))
    portraits = Image.new("RGBA", (8 * 64, 8 * 64))
    metadata, index = {}, 0
    for state, count, directions in STATES:
        metadata[state] = {"first": index, "frames": count, "directions": directions}
        for direction in range(directions):
            for frame in range(count):
                for body in range(8):
                    for hair in range(8):
                        art = pose(body, hair, state, frame, direction)
                        sheet.paste(art, ((body * 11 + index % 11) * 16, (hair * 9 + index // 11) * 24))
                index += 1
    assert index == 99
    for body in range(8):
        for hair in range(8):
            bust = pose(body, hair, "idle", 0, 0).crop((0, 0, 16, 19)).resize((48, 57), Image.Resampling.NEAREST)
            portraits.paste(bust, (body * 64 + 8, hair * 64 + 7))
    exported.mkdir(parents=True, exist_ok=True)
    sheet.save(exported / "adults.png", optimize=True)
    portraits.save(exported / "portraits.png", optimize=True)
    (ROOT / "data/citizen_animation.json").write_text(json.dumps({"version": 1, "frame_size": [16, 24], "columns": 11, "rows": 9, "frames_per_body": 99, "bodies": 8, "hair_shapes": 8, "states": metadata}, indent=2) + "\n")
    # Contact sheet is evidence, not shipped gameplay media.
    preview = Image.new("RGB", (13 * 72 + 60, 8 * 100 + 24), "#F3E8CC")
    d = ImageDraw.Draw(preview)
    for col, (state, _, _) in enumerate(STATES): d.text((60 + col * 72, 8), state, fill="#263C3B")
    coats = ["716D88", "B96C50", "375749", "5F98AC", "77915A", "D08336", "81656E", "8B7651"]
    skins = ["F0C8A0", "DEAE82", "C98D66", "AA704D", "86533C", "603B30"]
    for body in range(8):
        d.text((3, 36 + body * 100), str(body + 1), fill="#263C3B")
        for col, (state, count, _) in enumerate(STATES):
            palette = PALETTE.copy();palette[1] = coats[body];palette[4] = skins[body % 6]
            art = recolor(pose(body, body, state, min(1, count - 1), 0), palette).resize((48, 72), Image.Resampling.NEAREST)
            preview.paste(art, (60 + col * 72, 24 + body * 100), art)
    preview.save(ROOT / "assets/licenses/citizen_animation_preview.png")
    manifest_path = ROOT / "assets/licenses/manifest.json"
    trait_directory = ROOT / "assets/exported/ui/traits"
    trait_directory.mkdir(parents=True, exist_ok=True)
    for name, drawing in TRAITS.items():
        (trait_directory / (name + ".svg")).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><circle cx="32" cy="32" r="30" fill="#F3E8CC"/><g fill="none" stroke="#263C3B" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">' + drawing + '</g></svg>\n')
    new_ids = ["adult_animations", "adult_portraits"] + ["trait_" + name for name in TRAITS]
    manifest = [asset for asset in json.loads(manifest_path.read_text()) if asset["id"] not in new_ids]
    for name, ident in [("adults.png", "adult_animations"), ("portraits.png", "adult_portraits")]:
        path = exported / name
        manifest.append({"id": ident, "path": str(path.relative_to(ROOT)), "source": "tools/author_citizens.py", "author": "Brackenward project", "license": "Original project asset", "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "edited": False, "evidence": "assets/licenses/citizen_art.md"})
    for name in TRAITS:
        path = trait_directory / (name + ".svg")
        manifest.append({"id": "trait_" + name, "path": str(path.relative_to(ROOT)), "source": "tools/author_citizens.py", "author": "Brackenward project", "license": "Original project asset", "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "edited": False, "evidence": "assets/licenses/citizen_art.md"})
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
