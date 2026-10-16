#!/usr/bin/env python3
"""Original missing colony art, composed with the explicitly reviewed CC0 tiles.

Requires Pillow. Source components, their hashes, layout and contact sheets remain
editable in the repository. Gameplay never runs this authoring pipeline.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFilter
import math

ROOT = Path(__file__).resolve().parents[1]
INK, DEEP, MOSS, MEADOW = "#263C3B", "#375749", "#77915A", "#A6B878"
CREAM, CLAY, ROOF, WATER, LIGHT = "#F3E8CC", "#B96C50", "#716D88", "#5F98AC", "#E9BA67"
STONE, SHADE, WOOD = "#A4ADA4", "#687C78", "#895B44"
SOURCES = json.loads((ROOT / "data/environment_sources.json").read_text())
CATALOG = json.loads((ROOT / "data/catalogs/colony_v2.json").read_text())
PALETTE = {(63, 38, 49): INK, (132, 198, 105): MEADOW, (139, 155, 180): ROOF,
           (140, 156, 181): ROOF, (189, 108, 74): CLAY, (192, 203, 220): "#BDB8C6",
           (234, 165, 108): "#D3A77D", (71, 159, 74): DEEP, (82, 96, 124): "#555668",
           (90, 105, 136): "#66667A", (118, 59, 54): WOOD, (253, 190, 83): LIGHT,
           (101, 165, 86): MOSS, (139, 216, 125): "#93A96B", (227, 134, 40): "#D08336",
           (255, 255, 255): "#F8F3E7"}


def tile(name, stone=False):
    source = SOURCES["components"][name]
    path = ROOT / source["path"]
    assert hashlib.sha256(path.read_bytes()).hexdigest() == source["sha256"]
    art = Image.open(path).convert("RGBA")
    mapping = PALETTE.copy()
    if name=="grass_flowers": mapping.update({(253,190,83):"#D7D3A3",(227,134,40):MEADOW})
    if stone:
        mapping.update({(139, 155, 180): STONE, (140, 156, 181): STONE,
                        (192, 203, 220): "#CCD1BC", (82, 96, 124): SHADE, (90, 105, 136): "#84938C"})
    pixels = []
    for r, g, b, a in art.get_flattened_data():
        color = mapping[(r, g, b)] if a else INK
        pixels.append(tuple(bytes.fromhex(color[1:])) + (a,))
    art.putdata(pixels)
    return art


def ground(kind, variant):
    if kind == "grass":
        image = tile(["grass_plain", "grass_speckled", "grass_flowers"][variant])
        # Keep the inspected shapes, with quieter tufts behind people and props.
        replacements = {tuple(bytes.fromhex(MOSS[1:])): (151, 170, 111),
                        tuple(bytes.fromhex(DEEP[1:])): (139, 160, 103)}
        image.putdata([replacements.get(pixel[:3], pixel[:3]) + (pixel[3],)
                       for pixel in image.get_flattened_data()])
        return image
    image = Image.new("RGBA", (16, 16), {"poor": "#9DAD77", "rich": "#9BAF72", "water": WATER, "path": "#BBA980", "soil": CLAY}[kind])
    d = ImageDraw.Draw(image)
    if kind == "water":
        for x, y, length in [(1 + variant, 4, 5), (8 - variant, 11, 6)]: d.line((x, y, x + length, y), fill="#80AFBA")
    elif kind == "soil":
        for y in range(3, 16, 4): d.line((1, y, 14, y), fill=WOOD)
    else:
        for index in range(2 if kind in ("poor", "rich") else 4):
            x, y = (index * 7 + variant * 3) % 14, (index * 5 + variant * 7) % 14
            d.rectangle((x, y, x + 1, y + 1), fill="#91A16E" if kind == "poor" else ("#A99A75" if kind == "path" else "#8EA368"))
    return image


def leafy_crown(variant):
    """Original clustered shading inside the retained CC0 crown silhouette."""
    source = tile("round_canopy")
    mask = source.getchannel("A")
    interior = mask.filter(ImageFilter.MinFilter(3))
    painted = Image.new("RGBA", source.size, DEEP)
    d = ImageDraw.Draw(painted)
    mid = "#7F995F" if variant == 1 else "#8C9F64"
    light = "#A3B578" if variant == 1 else "#B2BA7D"
    d.polygon([(2,6),(4,3),(8,2),(12,4),(14,8),(12,11),(8,13),(3,10)], fill=mid)
    d.polygon([(3,5),(5,3),(9,3),(12,5),(10,7),(6,8),(3,7)], fill=light)
    d.polygon([(3,10),(6,9),(9,10),(8,12),(5,12)], fill=MOSS)
    for x,y in [(5,4),(8,4),(4,6),(10,8),(12,9)]:
        d.line((x,y,x+1,y),fill=light if y>7 else "#BDC48B")
    crown = Image.composite(painted, source, interior)
    crown.putalpha(mask)
    if variant == 2: crown=crown.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return crown.resize((24,24),Image.Resampling.NEAREST)


def resource(kind, variant):
    image = Image.new("RGBA", (32 if kind == "tree" else 24, 40 if kind == "tree" else 24))
    d = ImageDraw.Draw(image)
    # Compact contact shadows are baked into the existing sprite bounds.
    # Their position follows the same foot anchor as the visible resource.
    d.ellipse((5, 34, 27, 39) if kind == "tree" else (3, 19, 21, 23),
              fill=(38, 60, 59, 48))
    if kind == "tree":
        if variant == 0:
            # Tiered original branches keep the evergreen silhouette readable
            # beside round crowns, without repeating pale circular leaf marks.
            d.rectangle((14,25,17,38),fill=WOOD,outline=INK)
            d.line((15,28,15,37),fill="#C4966B")
            for top, bottom, radius in [(6,19,7),(12,27,10),(20,34,12)]:
                d.polygon([(16,top),(16-radius,bottom-2),(11,bottom-1),
                           (16,bottom+1),(22,bottom-1),(16+radius,bottom-2)],fill=DEEP,outline=INK)
                d.polygon([(16,top+2),(18,bottom-4),(15,bottom-2),
                           (18-radius,bottom-3)],fill="#638354")
                d.line((15,top+5,13,bottom-5),fill=MOSS)
        else:
            base = tile("conifer_base").crop((0, 8, 16, 16));image.alpha_composite(base, (8, 32))
            canopy = leafy_crown(variant)
            image.alpha_composite(canopy, (4, 8))
    elif kind == "sapling": image.alpha_composite(tile("sapling"), (4, 8))
    elif kind == "stump":
        d.ellipse((7, 16, 17, 22), fill=WOOD, outline=INK);d.ellipse((8, 15, 16, 19), fill="#D3A77D", outline=INK)
        d.line((11, 16, 14, 18), fill=WOOD)
    elif kind in ("stone_node", "clay_bank", "iron_seam"):
        for x, y, radius in [(3, 15, 6), (11, 10, 8), (17, 17, 5)]:
            d.ellipse((max(0, x-radius//2), y-radius//2, min(23, x+radius), min(23, y+radius//2)), fill=CLAY if kind == "clay_bank" else STONE, outline=INK)
            d.line((x, y-radius//2+1, min(23,x+radius//2), y-radius//2+1), fill=LIGHT if kind == "clay_bank" else CREAM)
        if kind == "iron_seam":
            for x in [6, 12, 18]: d.line((x, 13, x+2, 17, x, 19), fill=INK, width=2)
    else:
        for x, y in [(5, 16), (12, 11), (18, 17)]:
            if kind == "mushroom_patch":
                d.rectangle((x-1, y, x+1, min(23,y+4)), fill=CREAM)
                d.ellipse((x-4,y-3,x+4,y+1), fill=ROOF, outline=INK)
                d.point((x-1,y-2), fill=CREAM)
            else:
                d.ellipse((x-4,y-4,x+4,y+4), fill=DEEP, outline=INK)
                d.line((x-2,y-2,x,y), fill=MOSS)
                d.rectangle((x+1,y-2,x+2,y-1), fill=CLAY if kind == "berry_bush" else CREAM)
    return image


def crop(kind, stage):
    image = ground("soil", 0)
    d = ImageDraw.Draw(image)
    if stage == 0: return image
    for x, y in [(4, 5), (11, 5), (4, 12), (11, 12)]:
        if stage == 1: d.point((x,y), fill=CREAM);continue
        length = 2 if stage == 2 else 4
        d.line((x,y,x,y-length), fill=DEEP)
        d.line((x,y-1,x-2,y-length), fill=MOSS)
        d.line((x,y-1,x+2,y-length+1), fill=DEEP)
        if stage < 4: continue
        if kind == "turnip": d.ellipse((x-2,y-1,x+2,y+2), fill=CREAM, outline=INK)
        elif kind == "squash": d.ellipse((x-3,y-1,x+2,y+2), fill=LIGHT, outline=CLAY)
        elif kind == "barley":
            d.line((x,y-5,x,y), fill=LIGHT)
            for height in [2,4]: d.line((x-1,y-height-1,x+1,y-height+1), fill=LIGHT)
        elif kind == "flax": d.rectangle((x-1,y-5,x+1,y-3), fill=WATER);d.point((x,y-4), fill=CREAM)
        elif kind == "healing_leaf": d.polygon([(x,y-6),(x-3,y-2),(x,y),(x+3,y-2)], fill=DEEP);d.line((x,y-5,x,y), fill=MOSS)
        else:
            d.rectangle((x,y-1,x+1,y+1), fill=CREAM);d.ellipse((x-3,y-5,x+3,y-1), fill=ROOF, outline=INK);d.point((x-1,y-3), fill=CREAM)
    return image


def structure(kind, width, height, rotation, roof=False):
    w, h = width * 16, height * 16 + 12
    image = Image.new("RGBA", (w, h));d = ImageDraw.Draw(image)
    if roof:
        if kind != "barn": return image
        for y in range(0,h-8,16):
            for x in range(0,w,16): image.alpha_composite(tile("roof_shingles"), (x,y))
        mask=Image.new("L",(w,h));ImageDraw.Draw(mask).polygon([(0,12),(w//2,0),(w-1,12),(w-1,h-16),(w//2,h-28),(0,h-16)],fill=255)
        image.putalpha(mask)
        d.line((0,h-16,w//2,h-28,w-1,h-16), fill=INK, width=2)
        d.line((w//2,0,w//2,h-28), fill="#BDB8C6")
        return image
    if kind in ("wood_floor", "stone_path", "bridge"):
        if kind == "stone_path": image.alpha_composite(tile("stone_path", True), (0,12))
        else:
            d.rectangle((0,12,w-1,h-1), fill=WOOD)
            for y in range(12,h,4): d.rectangle((0,y,w-1,min(h-1,y+2)), fill="#C4966B")
        return image
    if kind in ("wood_wall", "palisade", "stone_wall"):
        d.rectangle((1,7,w-2,h-2), fill=SHADE if kind == "stone_wall" else WOOD, outline=INK)
        if kind == "stone_wall": image.alpha_composite(tile("stone_wall",True).crop((0,0,14,16)), (1,8))
        else:
            for x in range(3,w-2,4): d.line((x,8,x,h-3), fill=CLAY)
        d.rectangle((0,5,w-1,9), fill=STONE if kind == "stone_wall" else "#D3A77D", outline=INK)
        if kind == "palisade":
            for x in range(2,w,5): d.polygon([(x,1),(x-2,6),(x+2,6)], fill=WOOD)
        return image
    if kind in ("door", "reinforced_gate"):
        for x in range(0,w,16): image.alpha_composite(tile("stone_door" if kind == "reinforced_gate" else "wood_door"), (x,h-18))
        return image
    if kind in ("fence", "pen_gate"):
        part=tile(["fence_left","fence_middle","fence_right","fence_middle"][rotation])
        if rotation%2:part=part.transpose(Image.Transpose.ROTATE_90)
        image.alpha_composite(part, (0,h-16))
        if kind == "pen_gate": d.line((4,h-9,13,h-3), fill=CREAM)
        return image
    if kind == "hearth":
        # A stone fire ring rests on the ground, rather than a wooden table.
        cx, cy = w//2, (h+12)//2
        d.ellipse((2,15,w-2,h-1),fill=(38,60,59,48))
        d.ellipse((4,16,w-5,h-5),fill=INK)
        for index in range(10):
            angle=index*math.tau/10
            x=round(cx+math.cos(angle)*(w/2-6))
            y=round(cy+math.sin(angle)*((h-12)/2-5))
            d.polygon([(x-3,y-2),(x,y-3),(x+3,y-1),(x+3,y+2),
                       (x,y+3),(x-3,y+1)],fill=STONE if index%2 else SHADE,outline=INK)
            d.line((x-2,y-1,x+1,y-2),fill="#CCD1BC")
        d.line((cx-5,cy+2,cx+5,cy+7),fill=WOOD,width=3)
        d.line((cx-5,cy+6,cx+5,cy+1),fill="#A47B52",width=2)
        return image
    if kind == "supply_cart":
        # Open wooden wagon: recessed bed, iron-bound wheels and bundled canvas.
        # Cargo is decorative equipment, never a claim about stored quantities.
        d.ellipse((1,h-10,w-2,h-1), fill=(38,60,59,48))
        for x in [1,w-7]:
            d.ellipse((x,h-15,x+5,h-2),fill=INK)
            d.ellipse((x+1,h-13,x+4,h-4),fill=WOOD)
            d.line((x+2,h-12,x+2,h-5),fill="#C4966B")
            d.point((x+3,h-9),fill=STONE)
        d.rectangle((4,10,w-5,h-10),fill=INK)
        d.rectangle((6,12,w-7,h-12),fill=WOOD)
        for y in range(14,h-12,5):d.line((6,y,w-7,y),fill="#A47B52")
        d.rectangle((5,7,8,h-8),fill="#C4966B",outline=INK)
        d.rectangle((w-9,7,w-6,h-8),fill=WOOD,outline=INK)
        d.line((w-8,8,w-8,h-10),fill="#C4966B")
        d.rectangle((8,13,17,25),fill="#BDB49A",outline=INK)
        d.rectangle((9,12,16,15),fill=CREAM,outline=INK)
        d.line((13,16,13,24),fill=WOOD)
        d.rectangle((18,18,w-10,29),fill=ROOF,outline=INK)
        d.line((19,20,w-11,20),fill="#BDB8C6")
        d.line((21,19,21,28),fill=CREAM)
        d.rectangle((4,h-14,w-5,h-8),fill=WOOD,outline=INK)
        d.line((5,h-13,w-6,h-13),fill="#D3A77D")
        d.line((6,h-10,w-7,h-10),fill="#A47B52")
        for x in [5,w-7]:d.rectangle((x,h-14,x+1,h-8),fill=SHADE)
        return image
    if kind in ("charcoal_kiln", "brick_kiln", "smelter", "smithy"):
        # Masonry bodies have their own silhouette instead of a generic table.
        cx=w//2
        d.ellipse((1,h-10,w-2,h-1),fill=(38,60,59,48))
        color=CLAY if kind=="brick_kiln" else SHADE
        if kind=="charcoal_kiln":
            d.ellipse((3,12,w-4,h-4),fill=INK)
            d.ellipse((4,12,w-5,h-7),fill=SHADE,outline=INK)
            d.arc((6,14,w-7,h-9),190,290,fill=STONE,width=2)
            for y in [23,29]:d.line((5,y,w-6,y),fill="#52645F")
            d.rectangle((cx-3,8,cx+3,14),fill=STONE,outline=INK)
            d.rectangle((cx-2,8,cx+2,10),fill=INK)
        else:
            top=7 if kind=="smelter" else 15
            left=4;right=w-5
            d.rounded_rectangle((left,top,right,h-4),radius=6,fill=color,outline=INK)
            d.line((left+2,top+5,left+2,h-8),fill="#D3A77D" if kind=="brick_kiln" else STONE)
            for y in range(top+8,h-7,6):
                d.line((left+2,y,right-2,y),fill=WOOD if kind=="brick_kiln" else "#52645F")
                for x in range(left+5+(3 if y%12 else 0),right-2,8):d.line((x,y-4,x,y-1),fill=INK)
            d.rectangle((w-13,3,w-6,top+10),fill=color,outline=INK)
            d.rectangle((w-14,2,w-5,5),fill=STONE,outline=INK)
            d.line((w-12,3,w-7,3),fill=INK)
        # Opening sits under the existing state-driven flame anchor.
        d.rounded_rectangle((cx-6,h-21,cx+6,h-6),radius=5,fill=INK)
        d.line((cx-6,h-6,cx+6,h-6),fill=STONE)
        d.line((cx-4,h-9,cx+4,h-9),fill=WOOD,width=2)
        if kind=="smithy":
            # A small separate anvil reads at normal zoom beside the forge.
            d.rectangle((3,h-11,11,h-4),fill=WOOD,outline=INK)
            d.polygon([(2,h-17),(15,h-17),(12,h-13),(9,h-12),(10,h-10),(4,h-10),(5,h-14)],fill=SHADE,outline=INK)
            d.line((3,h-16,13,h-16),fill=STONE)
        return image
    if kind in ("bell", "memorial", "beacon"):
        cx=w//2
        d.ellipse((1,h-7,w-2,h-1),fill=(38,60,59,48))
        if kind=="bell":
            d.rectangle((2,h-6,w-3,h-3),fill=SHADE,outline=INK)
            for x in [2,w-4]:d.rectangle((x,6,x+1,h-6),fill=WOOD)
            d.rectangle((1,5,w-2,7),fill="#C4966B",outline=INK)
            d.polygon([(cx-2,9),(cx+2,9),(cx+3,16),(cx+5,18),(cx-5,18),(cx-3,16)],fill=LIGHT,outline=INK)
            d.line((cx-1,10,cx-2,16),fill=CREAM)
            d.line((cx,19,cx,21),fill=INK)
        elif kind=="memorial":
            d.rectangle((2,h-7,w-3,h-3),fill=SHADE,outline=INK)
            d.line((3,h-6,w-4,h-6),fill=STONE)
            d.rounded_rectangle((4,5,w-5,h-7),radius=3,fill=STONE,outline=INK)
            d.line((5,9,5,h-9),fill="#CCD1BC")
            d.line((7,11,w-7,11),fill=SHADE)
            d.line((7,14,w-7,14),fill=SHADE)
            d.line((w-6,h-6,w-4,h-9),fill=MOSS)
            d.point((w-4,h-10),fill=CREAM)
        else:
            # A stepped masonry landmark with iron basket and cloth pennants.
            # The brass-colored basket is static metal, never a simulated fire.
            d.rectangle((3,h-12,w-4,h-3),fill=SHADE,outline=INK)
            d.rectangle((6,h-15,w-7,h-8),fill=STONE,outline=INK)
            d.line((7,h-14,w-8,h-14),fill="#CCD1BC")
            d.polygon([(cx-7,15),(cx+7,15),(cx+9,h-15),(cx-9,h-15)],fill=STONE,outline=INK)
            d.polygon([(cx+2,16),(cx+7,16),(cx+8,h-16),(cx+2,h-16)],fill=SHADE)
            for y in range(24,h-17,7):d.line((cx-6,y,cx+7,y),fill=SHADE)
            d.line((cx-5,17,cx-6,h-17),fill="#CCD1BC")
            d.rectangle((cx-13,10,cx+13,12),fill=INK)
            for x,flip in [(cx-12,False),(cx+8,True)]:
                d.polygon([(x,13),(x+4,13),(x+4,30),(x+2,27),(x,30)],fill=ROOF,outline=INK)
                d.line((x+1,14,x+1,24),fill="#BDB8C6")
            d.polygon([(cx-8,3),(cx+8,3),(cx+5,14),(cx-5,14)],fill=LIGHT,outline=INK)
            d.line((cx-7,4,cx+7,4),fill=CREAM)
            for x in [cx-4,cx,cx+4]:d.line((x,5,x,12),fill=WOOD)
        return image
    # Furniture and stations have a visible front apron and top work surface.
    d.rectangle((2,14,w-3,h-3), fill=WOOD, outline=INK)
    d.rectangle((2,12,w-3,h-8), fill="#C4966B", outline=INK)
    d.line((3,13,w-4,13),fill="#D3A77D")
    for x in [3,w-5]: d.rectangle((x,h-7,x+2,h-1), fill=INK)
    cx, cy = w//2, (h+8)//2
    if kind in ("bed", "bedroll"):
        if kind == "bedroll":
            image=Image.new("RGBA",(w,h));d=ImageDraw.Draw(image)
        d.rectangle((3,14,w-4,h-4), fill=ROOF, outline=INK)
        pillow = (4,15,min(w-5,11),h-6) if rotation%2==0 else (4,15,w-5,min(h-5,23))
        d.rectangle(pillow, fill=CREAM)
        if rotation%2==0:
            d.line((12,15,12,h-5),fill="#BDB8C6")
            d.line((13,h-5,w-5,h-5),fill="#555668")
            for x in [w-10,w-8]:d.line((x,15,x,h-6),fill="#9B96AA")
        else:
            d.line((4,24,w-5,24),fill="#BDB8C6")
            d.line((w-5,25,w-5,h-5),fill="#555668")
            for y in [h-10,h-8]:d.line((4,y,w-6,y),fill="#9B96AA")
        if kind == "bedroll":d.line((3,h-4,w-4,h-4), fill=LIGHT)
        elif rotation%2==0:d.rectangle((1,10,4,h-2),fill=WOOD,outline=INK)
        else:d.rectangle((2,11,w-3,14),fill=WOOD,outline=INK)
    elif kind in ("table", "garden_bench"):
        if kind == "table": d.rectangle((cx-3,cy-2,cx+3,cy+2), fill=CREAM);d.ellipse((cx-2,cy-2,cx+2,cy+2), fill=MOSS)
        else:
            d.rectangle((2,7,w-3,13), fill=WOOD, outline=INK)
            for y in [8,11]:d.line((3,y,w-4,y),fill="#C4966B")
            d.rectangle((3,15,w-4,h-8),fill="#A47B52",outline=INK)
            d.line((4,16,w-5,16),fill="#D3A77D")
    elif kind in ("rack", "granary", "barn"):
        for y in range(14,h-6,9):
            d.rectangle((3,y,w-4,y+3), fill=CLAY, outline=INK)
            for x in range(5,w-6,10): d.ellipse((x,y-6,x+7,y+1), fill=LIGHT if kind == "granary" else CREAM, outline=INK)
        if kind == "barn":
            for x in [1,w-5]: d.rectangle((x,10,x+3,h-3), fill=WOOD, outline=INK)
            d.line((2,11,w-3,11), fill=CLAY, width=3)
            image.alpha_composite(tile("wood_door"),(cx-8,h-18))
    elif kind == "cellar":
        d.rectangle((2,12,w-3,h-2), fill=SHADE, outline=INK)
        d.rectangle((8,16,w-9,h-7), fill=INK)
        for y in range(18,h-8,5): d.line((9,y,w-10,y), fill=STONE, width=2)
        d.line((6,13,6,h-3), fill=CREAM)
    elif kind == "well":
        d.ellipse((3,h-22,w-4,h-3), fill=STONE, outline=INK);d.ellipse((7,h-20,w-8,h-8), fill=WATER, outline=INK)
        for x in [4,w-6]: d.rectangle((x,5,x+2,h-14), fill=WOOD, outline=INK)
        d.rectangle((3,4,w-4,8), fill=CLAY, outline=INK);d.line((cx,8,cx,h-12), fill=CREAM)
    elif kind == "fishing_pier":
        for y in range(12,h-3,5): d.line((3,y,w-4,y), fill=WOOD)
        d.line((w-7,8,w-4,h-10), fill=CREAM);d.arc((w-13,8,w-3,20),0,180,fill=INK)
    elif kind in ("workbench", "loom", "herbal_bench", "research_desk"):
        if kind == "workbench": image.alpha_composite(tile("hammer"), (w//2-8,12));image.alpha_composite(tile("farm_fork"), (2,h-20))
        elif kind == "loom":
            d.rectangle((5,5,w-6,h-7), outline=INK, width=2)
            for x in range(8,w-7,3): d.line((x,6,x,h-8), fill=CREAM)
            d.line((7,cy,w-8,cy), fill=ROOF, width=3)
        elif kind == "research_desk":
            d.rectangle((cx-7,14,cx+7,h-6), fill=CREAM, outline=INK);d.line((cx,15,cx,h-7), fill=WOOD)
            d.line((cx-5,18,cx-2,18), fill=ROOF);d.line((cx+2,20,cx+5,20), fill=ROOF)
        else:
            for x in range(6,w-5,6): d.ellipse((x-2,16,x+2,20), fill=DEEP, outline=INK);d.line((x,18,x+2,14), fill=MOSS)
    elif kind == "watchpost":
        for x in [3,w-6]: d.rectangle((x,4,x+2,h-3), fill=WOOD, outline=INK)
        d.rectangle((1,9,w-2,16), fill=CLAY, outline=INK)
        for y in range(19,h-3,5): d.line((cx-3,y,cx+3,y), fill=CREAM)
    else: raise AssertionError("Missing original building artwork: " + kind)
    return image


def item(kind, tier):
    image = Image.new("RGBA", (16,24));d=ImageDraw.Draw(image)
    for level in range(tier+1):
        y=20-level*4;x=2+(level%2)*2
        if kind in ("wood","stone","clay","iron_ore","charcoal"):
            color={"wood":WOOD,"stone":STONE,"clay":CLAY,"iron_ore":SHADE,"charcoal":INK}[kind]
            d.ellipse((x,y-5,min(15,x+10),y+1),fill=color,outline=INK)
            d.line((x+3,y-3,x+7,y-3),fill=CLAY if kind=="wood" else CREAM)
        elif kind in ("iron","brick","cloth","leather","fiber"):
            color={"iron":STONE,"brick":CLAY,"cloth":ROOF,"leather":WOOD,"fiber":MOSS}[kind]
            d.rectangle((x,y-5,min(15,x+10),y),fill=color,outline=INK)
            d.line((x+2,y-4,x+8,y-4),fill=CREAM)
        elif kind in ("toolkit","forged_toolkit","bow","spear"):
            if kind=="spear":d.line((4,22,12,7),fill=WOOD,width=2);d.polygon([(10,7),(14,4),(13,10)],fill=CREAM,outline=INK)
            else:image.alpha_composite(tile("bow" if kind=="bow" else ("axe" if kind=="forged_toolkit" else "hammer")),(0,8))
        elif kind in ("cloak","vest"):
            d.polygon([(6,8),(10,8),(14,21),(2,21)],fill=ROOF if kind=="cloak" else STONE,outline=INK)
            d.rectangle((6,8,9,11),fill=INK)
        elif kind in ("milk","medicine"):
            d.rectangle((5,y-7,10,y),fill=CREAM if kind=="milk" else DEEP,outline=INK)
            d.rectangle((6,y-10,9,y-7),fill=WOOD,outline=INK)
            if kind=="medicine":d.line((6,y-4,9,y-4),fill=CREAM);d.line((8,y-6,8,y-2),fill=CREAM)
        elif kind=="egg":d.ellipse((x+1,y-7,x+6,y),fill=CREAM,outline=INK)
        elif kind=="fish":
            d.ellipse((2,y-5,12,y),fill=WATER,outline=INK);d.polygon([(11,y-3),(15,y-6),(15,y+1)],fill=WATER,outline=INK);d.point((4,y-3),fill=CREAM)
        elif kind=="mushroom":
            d.rectangle((7,y-4,9,y),fill=CREAM);d.ellipse((3,y-8,13,y-3),fill=ROOF,outline=INK);d.point((6,y-6),fill=CREAM)
        else:
            color={"vegetable":MOSS,"grain":LIGHT,"berry":CLAY,"herb":DEEP,"meat":WOOD,"meal":MOSS,"travel_ration":CLAY}.get(kind)
            assert color is not None,kind
            d.ellipse((2,y-5,13,y),fill=WOOD,outline=INK)
            for px in [4,8,11]:d.ellipse((px-2,y-7,px+2,y-3),fill=color,outline=INK)
            if kind in ("grain","travel_ration"):d.line((4,y-2,11,y-2),fill=CREAM)
    return image


def main():
    images={}
    for kind in ["grass","poor","rich","water","path","soil"]:
        for variant in range(3 if kind!="water" else 2): images[f"ground/{kind}/{variant}"]=ground(kind,variant)
    for definition in CATALOG["buildings"]:
        for rotation in range(4):
            w,h=definition["width"],definition["height"]
            if rotation%2:w,h=h,w
            images[f"building/{definition['id']}/{rotation}"]=structure(definition["id"],w,h,rotation)
            if definition["id"]=="barn":images[f"roof/barn/{rotation}"]=structure("barn",w,h,rotation,True)
    for kind in [r["id"]for r in CATALOG["resources"]]+["sapling","stump"]:
        for variant in range(3 if kind=="tree" else 1):images[f"resource/{kind}/{variant}"]=resource(kind,variant)
    for definition in CATALOG["crops"]:
        for stage in range(5):images[f"crop/{definition['id']}/{stage}"]=crop(definition["id"],stage)
    for definition in CATALOG["items"]:
        for tier in range(3):images[f"item/{definition['id']}/{tier}"]=item(definition["id"],tier)
    for frame in range(2):
        fire=Image.new("RGBA",(16,24));d=ImageDraw.Draw(fire)
        d.polygon([(2,23),(1,17),(5,10+frame*2),(7,14),(11,3+frame*3),(13,12),(15,18),(13,23)],fill=LIGHT,outline=INK)
        d.polygon([(5,22),(6,17),(9,11+frame),(11,20),(10,23)],fill=CLAY)
        d.line((8,21,9,17),fill=CREAM,width=2)
        images[f"effect/flame/{frame}"]=fire
    sheet=Image.new("RGBA",(1024,2048));x=y=row_height=0;layout={}
    for name,art in images.items():
        w,h=art.size
        if x+w+2>1024:x=0;y+=row_height+2;row_height=0
        assert y+h<=2048,(name,y,h)
        sheet.alpha_composite(art,(x,y));layout[name]=[x,y,w,h];x+=w+2;row_height=max(row_height,h)
    sheet=sheet.crop((0,0,1024,y+row_height))
    destination=ROOT/"assets/exported/environment/woodland.png";destination.parent.mkdir(parents=True,exist_ok=True);sheet.save(destination,optimize=True)
    (ROOT/"data/environment_art.json").write_text(json.dumps({"version":1,"rectangles":layout,"source_components":"data/environment_sources.json","foot_anchor":"bottom center; source footprint is 16 pixels per logical tile"},indent=2)+"\n")
    for category,names in [("buildings",[n for n in images if n.startswith("building/")and n.endswith("/0")]),("plants",[n for n in images if n.startswith(("resource/","crop/"))]),("items",[n for n in images if n.startswith("item/")and n.endswith("/2")])]:
        columns=5;cell_w=160;cell_h=118
        preview=Image.new("RGB",(columns*cell_w,((len(names)+columns-1)//columns)*cell_h),CREAM);d=ImageDraw.Draw(preview)
        for index,name in enumerate(names):
            art=images[name].copy()
            if name=="building/barn/0":art.alpha_composite(images["roof/barn/0"])
            factor=min(3,96//max(art.size));art=art.resize((art.width*factor,art.height*factor),Image.Resampling.NEAREST)
            px=index%columns*cell_w+(cell_w-art.width)//2;py=index//columns*cell_h
            preview.paste(art,(px,py),art);d.text((index%columns*cell_w+3,py+98),name.split("/")[1]+(" / "+name.split("/")[2]if category=="plants"else""),fill=INK)
        preview.save(ROOT/f"assets/licenses/environment_{category}_preview.png")
    path=ROOT/"assets/licenses/manifest.json";manifest=[a for a in json.loads(path.read_text())if a["id"]!="woodland_environment"]
    manifest.append({"id":"woodland_environment","path":str(destination.relative_to(ROOT)),"source":"tools/author_environment.py; inspected components in data/environment_sources.json","author":"Brackenward project and Kenney","license":"Original project asset","sha256":hashlib.sha256(destination.read_bytes()).hexdigest(),"edited":True,"evidence":"assets/licenses/environment_art.md","semantic_layout":"data/environment_art.json"})
    glow=Image.new("RGBA",(64,64))
    for gy in range(64):
        for gx in range(64):
            radius=math.hypot((gx-31.5)/31.5,(gy-31.5)/31.5)
            alpha=round(max(0,1-radius)**2*110)
            glow.putpixel((gx,gy),(233,186,103,alpha))
    glow_path=destination.with_name("warm_glow.png");glow.save(glow_path,optimize=True)
    manifest=[a for a in manifest if a["id"]!="warm_hearth_glow"]
    manifest.append({"id":"warm_hearth_glow","path":str(glow_path.relative_to(ROOT)),"source":"tools/author_environment.py","author":"Brackenward project","license":"Original project asset","sha256":hashlib.sha256(glow_path.read_bytes()).hexdigest(),"edited":False,"evidence":"assets/licenses/environment_art.md"})
    path.write_text(json.dumps(manifest,indent=2)+"\n")
    print(f"Authored {len(images)} semantic sprites on {sheet.width}x{sheet.height} shared atlas")


if __name__=="__main__":main()
