#!/usr/bin/env python3
"""Editable original pixel animals, using Pillow. No borrowed or generated art.

24x24 frames, anchored at bottom center. Each species owns a 16x4 frame block;
four directions and mirrored sides keep all states on the same shared texture.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
KINDS = ["hare", "deer", "boar", "marsh_goose", "hen", "pack_goat", "merchant_pack"]
STATES = [("idle", 2), ("walk", 4), ("eat", 2), ("downed", 1)]
INK = "#263C3B"
CREAM = "#F3E8CC"
CLAY = "#B96C50"
MOSS = "#77915A"


def pose(kind, state, frame, direction):
    image = Image.new("RGBA", (24, 24))
    d = ImageDraw.Draw(image)
    side = direction in (1, 3)
    back = direction == 2
    bird = kind in ("marsh_goose", "hen")
    small = kind in ("hare", "hen")
    goat = kind in ("pack_goat", "merchant_pack")
    colors = {"hare": ("#D9CEAB", "#B4AA8C"), "deer": (CLAY, "#895B44"),
              "boar": ("#716D88", "#554F63"), "marsh_goose": (CREAM, "#C6C7AD"),
              "hen": ("#E9BA67", "#B79055"), "pack_goat": ("#C6C7AD", "#858F7B"),
              "merchant_pack": ("#C6C7AD", "#858F7B")}
    coat, shade = colors[kind]

    def box(rect, color, outline=False):
        d.rectangle(rect, fill=color, outline=INK if outline else None)

    def oval(rect, color, outline=True):
        d.ellipse(rect, fill=color, outline=INK if outline else None)

    if state == "downed":
        oval((4 if small else 2, 15, 20, 21), shade)
        oval((16, 15, 22, 20), coat)
        d.line((18, 17, 20, 17), fill=INK)
        if kind == "hare":
            box((9, 14, 18, 15), coat)
            box((8, 16, 16, 17), coat)
        if goat or kind == "deer": d.line((18, 15, 16, 12), fill=CREAM)
        if bird: d.polygon([(22, 17), (23, 18), (22, 19)], fill=CLAY)
        return image.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if direction == 3 else image

    step = [0, -1, 0, 1][frame % 4] if state in ("walk", "charge") else 0
    bob = (frame % 2) if state in ("idle", "walk", "charge") else 0
    eating = state == "eat"
    if side:
        if bird:
            oval((5 if kind == "hen" else 3, 12 + bob, 17, 20), coat)
            oval((7, 14 + bob, 14, 18 + bob), shade, False)
            neck = 11 + (4 if eating else 0) + bob
            box((15, neck, 18, 17), coat, True)
            oval((15, neck - 4, 21, neck + 1), coat)
            d.polygon([(21, neck - 2), (23, neck - 1), (21, neck)], fill=CLAY)
            d.point((19, neck - 2), fill=INK)
            d.polygon([(5, 14 + bob), (2, 12 + bob), (4, 17 + bob)], fill=shade)
            for x, shift in [(8, step), (14, -step)]:
                d.line((x, 20, x + shift, 22), fill=CLAY)
                d.line((x + shift - 1, 22, x + shift + 1, 22), fill=CLAY)
            if kind == "hen":
                box((17, neck - 5, 20, neck - 4), CLAY)
                box((17, neck + 1, 18, neck + 2), CLAY)
        else:
            low, high = (13, 19) if small else (10, 18)
            for x, shift in [(6, step), (15, -step)]:
                box((x, high - 1, x + 2, 21 + shift), shade)
                box((x - 1, 21 + shift, x + 2, 22 + shift), INK)
            oval((3, low + bob, 17, high + bob), coat)
            d.line((5, high - 1 + bob, 14, high - 1 + bob), fill=shade)
            head_y = low - (4 if goat or kind == "deer" else 1) + bob + (5 if eating else 0)
            if kind == "boar" and state == "charge": head_y += 2
            oval((14, head_y, 21, head_y + 6), coat)
            box((20, head_y + 3, 22, head_y + 5), shade, True)
            d.point((19, head_y + 2), fill=INK)
            if kind == "hare":
                oval((1, 16 + bob, 5, 20 + bob), CREAM)
                box((15, head_y - 7, 17, head_y), coat, True)
                box((19, head_y - 6, 21, head_y), coat, True)
                d.line((16, head_y - 5, 16, head_y - 1), fill=shade)
            elif kind == "deer":
                d.line((16, head_y, 14, head_y - 5, 14, head_y - 7), fill=CREAM)
                d.line((14, head_y - 4, 11, head_y - 5), fill=CREAM)
                d.line((19, head_y, 20, head_y - 5, 22, head_y - 6), fill=CREAM)
                d.polygon([(3, 12 + bob), (1, 10 + bob), (2, 15 + bob)], fill=CREAM)
                for xy in [(6, 13), (10, 12), (12, 15)]: d.point(xy, fill=CREAM)
            elif kind == "boar":
                d.line((21, head_y + 6, 23, head_y + 3), fill=CREAM, width=1)
                for x in range(5, 14, 2): d.line((x, low + 1, x, low - 1), fill=INK)
                d.line((3, 15, 1, 14, 1, 12), fill=INK)
            elif goat:
                d.line((16, head_y, 14, head_y - 4, 15, head_y - 6), fill=CREAM)
                d.line((19, head_y, 19, head_y - 5, 20, head_y - 6), fill=CREAM)
                d.polygon([(17, head_y + 6), (19, head_y + 9), (20, head_y + 6)], fill=shade)
                d.line((3, 12, 1, 10), fill=CREAM)
    else:
        # North-facing heads sit behind the body. South-facing faces stay readable.
        body_y = 14 if small else 11
        head_y = body_y - (4 if goat or kind == "deer" or bird else 2) + bob
        if eating: head_y += 5
        for x, shift in [(7, step), (14, -step)]:
            box((x, 17, x + 2, 21 + shift), CLAY if bird else shade)
            box((x - 1, 21 + shift, x + 2, 22 + shift), CLAY if bird else INK)
        if back: oval((8, head_y, 16, head_y + 6), coat)
        oval((5 if small else 4, body_y + bob, 19, 20), coat)
        oval((7, body_y + 2 + bob, 17, 18), shade, False)
        if not back:
            oval((8, head_y, 16, head_y + 6), coat)
            for x in [10, 14]: d.point((x, head_y + 2), fill=INK)
            if bird: d.polygon([(11, head_y + 4), (13, head_y + 4), (12, head_y + 6)], fill=CLAY)
            else: box((11, head_y + 4, 13, head_y + 5), shade)
        else:
            oval((10, 18, 14, 21), CREAM if kind in ("hare", "deer") else shade, False)
        if kind == "hare":
            for x in [8, 14]: box((x, head_y - 7, x + 2, head_y), coat, True)
        elif kind == "deer":
            for x, dx in [(8, -2), (16, 2)]:
                d.line((x, head_y, x + dx, head_y - 5, x + dx, head_y - 7), fill=CREAM)
                d.line((x + dx, head_y - 4, x + dx * 2, head_y - 5), fill=CREAM)
        elif goat:
            for x, dx in [(9, -2), (15, 2)]: d.line((x, head_y, x + dx, head_y - 5), fill=CREAM)
            if not back: d.polygon([(10, head_y + 6), (12, head_y + 9), (14, head_y + 6)], fill=shade)
        elif kind == "boar":
            for x in [7, 17]: d.line((x, head_y + 5, x + (1 if x == 7 else -1), head_y + 2), fill=CREAM)
        elif kind == "hen": box((11, head_y - 2, 13, head_y), CLAY)
    if kind == "merchant_pack":
        # The packs are cosmetic and add no cargo/collision capacity.
        box((4, 11 + bob, 10, 17 + bob), CLAY, True)
        box((12, 11 + bob, 18, 17 + bob), "#716D88", True)
        d.line((7, 11 + bob, 7, 17 + bob), fill=CREAM)
        d.line((15, 11 + bob, 15, 17 + bob), fill=CREAM)
    return image.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if direction == 3 else image


def main():
    sheet = Image.new("RGBA", (16 * 24, len(KINDS) * 4 * 24))
    layout = {"version": 1, "frame_size": [24, 24], "columns": 16, "rows_per_kind": 4, "kinds": {}}
    preview = Image.new("RGB", (1120, len(KINDS) * 110 + 30), CREAM)
    label = ImageDraw.Draw(preview)
    for row, kind in enumerate(KINDS):
        states = STATES + ([("charge", 4)] if kind == "boar" else [])
        block, first = {}, 0
        label.text((4, row * 110 + 52), kind, fill=INK)
        col = 0
        for state, count in states:
            block[state] = {"first": first, "frames": count, "directions": 4}
            for direction in range(4):
                for frame in range(count):
                    art = pose(kind, state, frame, direction)
                    sheet.paste(art, ((first % 16) * 24, (row * 4 + first // 16) * 24))
                    first += 1
                art = pose(kind, state, min(1, count - 1), direction).resize((48, 48), Image.Resampling.NEAREST)
                x = 120 + col * 48
                preview.paste(art, (x, row * 110 + 30), art)
                label.text((x, row * 110 + 82), state[:3] + str(direction), fill=INK)
                col += 1
        assert first <= 64
        layout["kinds"][kind] = {"block_row": row, "states": block, "frames": first}
    destination = ROOT / "assets/exported/animals/woodland.png"
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination, optimize=True)
    preview.save(ROOT / "assets/licenses/animal_animation_preview.png")
    (ROOT / "data/animal_animation.json").write_text(json.dumps(layout, indent=2) + "\n")
    manifest_path = ROOT / "assets/licenses/manifest.json"
    manifest = [asset for asset in json.loads(manifest_path.read_text()) if asset["id"] != "woodland_animals"]
    manifest.append({"id": "woodland_animals", "path": str(destination.relative_to(ROOT)),
                     "source": "tools/author_animals.py", "author": "Brackenward project",
                     "license": "Original project asset", "sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
                     "edited": False, "evidence": "assets/licenses/animal_art.md"})
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
