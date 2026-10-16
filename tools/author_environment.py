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
    image = Image.new("RGBA", (16, 16), {"poor": "#9DAD77", "rich": "#9BAF72", "water": WATER, "path": "#BBA980", "soil": "#927453"}[kind])
    d = ImageDraw.Draw(image)
    if kind == "water":
        for x, y, length in [(1 + variant, 4, 5), (8 - variant, 11, 6)]: d.line((x, y, x + length, y), fill="#80AFBA")
    elif kind == "soil":
        for y in [6,13]:
            d.line((0,y,15,y),fill="#796248")
            d.line((0,y+1,15,y+1),fill="#A1875D")
        for x,y in [(1,2),(8,9),(14,3)]:d.point((x,y),fill="#A1875D")
    else:
        for index in range(2 if kind in ("poor", "rich") else 4):
            x, y = (index * 7 + variant * 3) % 14, (index * 5 + variant * 7) % 14
            d.rectangle((x, y, x + 1, y + 1), fill="#91A16E" if kind == "poor" else ("#A99A75" if kind == "path" else "#8EA368"))
    return image


def winter_ground(art):
    art=art.copy()
    pixels=[]
    for r,g,b,a in art.get_flattened_data():
        light=round(0.3*r+0.59*g+0.11*b)
        pixels.append((min(255,light+23),min(255,light+21),min(255,light+7),a))
    art.putdata(pixels)
    return art


def soil_edge(kind, mask):
    # Ordinary meadow nibbles into soil patches only along actual grass edges.
    # No new fertility, randomness or runtime geometry is introduced.
    art=ground(kind,0);d=ImageDraw.Draw(art)
    for side in range(4):
        if not mask & (1<<side):continue
        for segment in range(8):
            depth=1+(segment*7+side*3+mask)%3
            start=segment*2
            if side==0:box=(start,0,start+1,depth-1)
            elif side==1:box=(16-depth,start,15,start+1)
            elif side==2:box=(start,16-depth,start+1,15)
            else:box=(0,start,depth-1,start+1)
            d.rectangle(box,fill=MEADOW)
    return art


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
    elif kind == "clay_bank":
        # Low layered earth instead of the same round boulders as stone.
        d.polygon([(1,18),(5,14),(9,14),(10,10),(16,8),(21,11),(22,20),
                   (17,22),(7,22)],fill=WOOD,outline=INK)
        d.polygon([(3,17),(8,15),(12,16),(12,11),(17,10),(20,12),
                   (19,18),(14,20),(5,20)],fill=CLAY)
        d.line((4,17,8,16,12,17),fill="#D39262")
        d.line((13,12,17,11,19,12),fill="#D3A77D")
        d.line((12,18,17,16,20,16),fill="#895B44")
        d.line((7,21,12,21),fill=CLAY)
    elif kind in ("stone_node", "iron_seam"):
        for x,y,w,h in [(1,16,8,6),(8,10,12,10),(16,18,7,5)]:
            d.polygon([(x,y+2),(x+2,y),(x+w-3,y),(x+w,y+3),
                       (x+w-1,y+h-1),(x+3,y+h),(x,y+h-2)],fill=SHADE,outline=INK)
            d.polygon([(x+1,y+2),(x+3,y+1),(x+w-3,y+1),
                       (x+w-2,y+3),(x+3,y+3)],fill="#CCD1BC")
            d.polygon([(x+2,y+4),(x+w-2,y+4),(x+w-2,y+h-2),
                       (x+3,y+h-1)],fill=STONE)
        if kind=="iron_seam":
            # Rusty dark mineral facets leave the host rock visible.
            for x,y in [(11,14),(16,12),(18,20)]:
                d.polygon([(x-1,y),(x+1,y-1),(x+2,y+1),(x,y+3)],fill=INK)
                d.line((x,y,x+1,y+1),fill=WOOD)
                d.point((x,y+2),fill=CLAY)
    elif kind=="herb_patch":
        for x,y in [(6,19),(13,14),(18,20)]:
            d.polygon([(x,y+3),(x-4,y),(x-4,y-3),(x-1,y-1),
                       (x,y-6),(x+2,y-3),(x+2,y-1),(x+5,y-3),
                       (x+4,y+1)],fill=DEEP,outline=INK)
            d.line((x,y+2,x,y-4),fill=MOSS)
            d.line((x,y+1,x+3,y-1),fill="#93A96B")
            d.line((x-3,y-2,x-1,y),fill=MOSS)
            if x==13:
                d.line((x,y-2,x+1,y-7),fill=MOSS)
                d.point((x,y-7),fill=CREAM);d.point((x+2,y-7),fill=CREAM)
    else:
        for x, y in [(5, 16), (12, 11), (18, 17)]:
            if kind == "mushroom_patch":
                d.rectangle((x-1, y, x+1, min(23,y+4)), fill=CREAM)
                d.ellipse((x-4,y-3,x+4,y+1), fill=ROOF, outline=INK)
                d.point((x-1,y-2), fill=CREAM)
            else:
                assert kind=="berry_bush",kind
                d.ellipse((x-4,y-4,x+4,y+4), fill=DEEP, outline=INK)
                d.ellipse((x-3,y-3,x+2,y),fill="#638354")
                d.line((x-2,y-2,x,y-2),fill=MOSS)
                for dx,dy in [(1,-1),(-2,1),(2,2)]:
                    d.point((x+dx,y+dy),fill="#D39262")
                    d.point((x+dx,y+dy+1),fill=CLAY)
    return image


def depleted_resource(kind):
    image=Image.new("RGBA",(24,24));d=ImageDraw.Draw(image)
    d.ellipse((3,19,21,23),fill=(38,60,59,48))
    if kind=="berry_bush":
        image=resource(kind,0)
        colors={tuple(bytes.fromhex(c[1:])) for c in ["#D39262",CLAY]}
        image.putdata([(*tuple(bytes.fromhex(DEEP[1:])),p[3]) if p[:3] in colors else p for p in image.get_flattened_data()])
    elif kind=="herb_patch":
        for x,y in [(6,20),(13,16),(18,21)]:
            d.line((x-3,y-1,x,y+1,x+3,y-1),fill=DEEP,width=2)
            d.line((x,y-2,x,y+1),fill=MOSS)
            d.point((x,y-2),fill="#93A96B")
    else:
        assert kind=="mushroom_patch"
        for x,y in [(5,19),(12,15),(18,20)]:
            d.line((x-2,y+1,x+2,y+1),fill=WOOD)
            d.line((x,y-1,x,y),fill="#BDB49A")
    return image


def crop(kind, stage):
    image = ground("soil", 0)
    d = ImageDraw.Draw(image)
    if stage == 0: return image
    for x, y in [(4, 5), (11, 5), (4, 12), (11, 12)]:
        if stage == 1:
            d.line((x,y,x,y-1),fill=DEEP)
            d.point((x-1,y-1),fill="#B3C080")
            continue
        ripe=stage==4
        if kind == "barley":
            length=2 if stage==2 else (4 if ripe else 3)
            for dx in [-2,0,2]:
                top=y-length+(1 if dx else 0)
                d.line((x,y,x+dx,top),fill=LIGHT if ripe else DEEP)
                if ripe:
                    d.line((x+dx,top-1,x+dx,top+1),fill=LIGHT)
                    d.point((x+dx,top-1),fill=CREAM)
                else:d.point((x+dx,top),fill=MOSS)
        elif kind == "flax":
            for dx in [-2,1]:
                d.line((x,y,x+dx,y-(2 if stage==2 else 4)),fill=DEEP)
                d.point((x+dx+1,y-2),fill=MOSS)
                if ripe:
                    d.line((x+dx-1,y-4,x+dx+1,y-4),fill="#A4B6CF")
                    d.point((x+dx,y-5),fill=WATER)
                    d.point((x+dx,y-4),fill=CREAM)
        elif kind == "cavecap":
            radius=1 if stage==2 else (3 if ripe else 2)
            d.line((x,y-2,x,y+1),fill=CREAM)
            d.ellipse((x-radius,y-4,x+radius,y-1),fill=ROOF,outline=INK)
            if ripe:d.point((x-1,y-3),fill=CREAM);d.point((x+1,y-2),fill="#BDB8C6")
        else:
            radius=2 if stage==2 else 3
            d.polygon([(x,y),(x-radius,y-2),(x-radius,y-3),(x-1,y-2),(x,y-4),
                       (x+1,y-2),(x+radius,y-3),(x+radius,y-1)],fill=DEEP)
            d.line((x,y-1,x-1,y-3),fill=MOSS)
            d.point((x+2,y-2),fill="#93A96B")
            if not ripe:continue
            if kind=="turnip":
                d.ellipse((x-2,y-1,x+2,y+2),fill=CREAM,outline="#6B6450")
                d.line((x-1,y,x+1,y),fill="#BDB8C6")
                d.point((x,y-2),fill=MOSS)
            elif kind=="squash":
                d.ellipse((x-3,y-1,x+2,y+2),fill=LIGHT,outline="#A47B52")
                d.line((x-1,y,x-1,y+1),fill=CREAM)
                d.point((x,y-2),fill=DEEP)
            else:
                assert kind=="healing_leaf",kind
                d.polygon([(x,y-5),(x-2,y-2),(x,y),(x+2,y-2)],fill=MOSS)
                d.line((x,y-4,x,y-1),fill="#B3C080")
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
            d.rectangle((0,12,w-1,h-1), fill="#795E43")
            for row,y in enumerate(range(12,h,4)):
                d.rectangle((0,y,w-1,min(h-1,y+2)), fill="#B08C60" if row%2 else "#BC9769")
                d.line((0,y,w-1,y),fill="#C5A576")
                joint=4 if row%2 else 12
                d.line((joint,y,joint,y+2),fill="#795E43")
                d.point((joint-2,y+1),fill="#927453")
            if kind=="bridge":
                for x in [1,w-2]:d.line((x,12,x,h-1),fill=WOOD)
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
    if kind in ("rack", "granary", "barn", "cellar", "well", "fishing_pier", "watchpost"):
        # Original utility silhouettes. Shelves/bins are fixtures, not fake stock.
        cx=w//2
        d.ellipse((1,h-8,w-2,h-1),fill=(38,60,59,48))
        if kind == "rack":
            for y in [17,27,h-6]:
                d.rectangle((3,y-3,w-4,y+1),fill="#A47B52",outline=INK)
                d.line((4,y-2,w-5,y-2),fill="#D3A77D")
            for x in [2,w-5]:
                d.rectangle((x,9,x+2,h-2),fill=WOOD,outline=INK)
                d.line((x+1,10,x+1,h-4),fill="#C4966B")
            d.line((5,16,w-6,h-7),fill=WOOD)
            d.rectangle((1,7,w-2,10),fill="#A47B52",outline=INK)
        elif kind == "granary":
            d.rectangle((4,15,w-5,h-5),fill=WOOD,outline=INK)
            for x in range(6,w-6,5):
                d.rectangle((x,17,x+2,h-8),fill="#A47B52")
                d.line((x,17,x,h-8),fill="#C4966B")
            for y in [21,h-12]:d.rectangle((4,y,w-5,y+2),fill=SHADE,outline=INK)
            d.polygon([(2,15),(cx,3),(w-3,15),(w-3,20),(2,20)],fill=WOOD,outline=INK)
            d.line((4,14,cx,5,w-5,14),fill="#D3A77D",width=2)
            d.line((4,18,w-5,18),fill="#C4966B")
            # A small grain carving identifies the fixed bin, not its contents.
            d.rectangle((cx-5,26,cx+5,39),fill=INK)
            d.line((cx,29,cx,37),fill=LIGHT)
            for y in [29,32,35]:
                d.line((cx-3,y-1,cx,y+1,cx+3,y-1),fill=LIGHT)
            for x in [5,w-8]:d.rectangle((x,h-6,x+2,h-2),fill=INK)
        elif kind == "barn":
            # Open timber framing keeps residents and stored supplies readable.
            d.rectangle((2,14,w-3,h-4),fill="#927453",outline=INK)
            for y in range(16,h-5,5):d.line((3,y,w-4,y),fill="#A47B52")
            for x in [2,cx-1,w-5]:
                d.rectangle((x,6,x+2,h-4),fill=WOOD,outline=INK)
                d.line((x+1,8,x+1,h-5),fill="#C4966B")
            d.rectangle((1,7,w-2,11),fill=WOOD,outline=INK)
            d.line((2,8,w-3,8),fill="#D3A77D")
            for x in [5,w-14]:
                d.line((x,13,x+8,22),fill=WOOD,width=2)
                d.rectangle((x,25,x+8,h-9),fill=INK)
                for y in range(27,h-10,5):d.line((x+1,y,x+7,y),fill="#C4966B")
            d.rectangle((cx-6,h-6,cx+6,h-3),fill=WOOD,outline=INK)
        elif kind == "cellar":
            d.polygon([(2,16),(8,9),(w-9,9),(w-3,16),(w-3,h-3),(2,h-3)],fill=SHADE,outline=INK)
            d.rectangle((7,16,w-8,h-7),fill=INK)
            for y in range(20,h-9,5):
                inset=max(0,(h-12-y)//9)
                d.rectangle((9+inset,y,w-10-inset,y+2),fill=STONE)
                d.line((9+inset,y+2,w-10-inset,y+2),fill=SHADE)
            d.line((4,17,4,h-7),fill="#CCD1BC",width=2)
            d.line((w-5,17,w-5,h-7),fill=STONE)
            d.line((5,h-5,w-6,h-5),fill=STONE,width=2)
            d.line((8,11,w-9,11),fill=MOSS,width=2)
            for x in range(9,w-10,7):d.line((x,12,x+2,14),fill=DEEP)
        elif kind == "well":
            d.ellipse((3,h-24,w-4,h-3),fill=SHADE,outline=INK)
            for x in [8,16,24]:d.line((x,h-10,x,h-5),fill=INK)
            d.arc((3,h-25,w-4,h-9),0,180,fill=STONE,width=3)
            d.ellipse((3,h-27,w-4,h-11),fill=STONE,outline=INK)
            d.ellipse((7,h-24,w-8,h-15),fill=INK)
            d.arc((8,h-23,w-9,h-16),0,170,fill=WATER)
            for x in [3,w-6]:
                d.rectangle((x,5,x+2,h-17),fill=WOOD,outline=INK)
                d.line((x+1,6,x+1,h-19),fill="#C4966B")
            d.rectangle((2,4,w-3,7),fill="#A47B52",outline=INK)
            d.line((3,5,w-4,5),fill="#D3A77D")
            d.line((5,12,w-6,12),fill=SHADE,width=2)
            for x in range(cx-3,cx+4,2):d.line((x,10,x,14),fill=CREAM)
            d.line((cx,14,cx,h-18),fill=CREAM)
            d.rectangle((w-10,h-10,w-5,h-4),fill=WOOD,outline=INK)
            d.arc((w-10,h-14,w-5,h-7),180,360,fill=SHADE)
        elif kind == "fishing_pier":
            d.rectangle((2,14,w-3,h-4),fill=WOOD,outline=INK)
            for y in range(15,h-5,5):
                d.rectangle((3,y,w-4,y+2),fill="#B08C60")
                d.line((3,y,w-4,y),fill="#D3A77D")
            for x in [1,w-4]:
                for y in [12,h-8]:
                    d.rectangle((x,y,x+2,y+6),fill=INK)
                    d.rectangle((x,y,x+2,y+2),fill="#A47B52")
            d.line((w-9,h-9,w-6,8),fill=WOOD)
            d.line((w-6,8,w-2,15),fill=CREAM)
            d.arc((4,h-17,12,h-9),0,330,fill=CREAM)
            d.arc((6,h-15,10,h-11),0,330,fill="#A47B52")
        else: # watchpost: raised deck, braced supports and a real ladder.
            for x in [3,w-6]:
                d.rectangle((x,8,x+2,h-3),fill=WOOD,outline=INK)
                d.line((x+1,10,x+1,h-4),fill="#C4966B")
            d.line((6,25,w-7,h-6),fill=WOOD,width=2)
            d.line((w-7,25,6,h-6),fill=WOOD,width=2)
            d.rectangle((1,13,w-2,23),fill=WOOD,outline=INK)
            for y in [15,18,21]:d.line((2,y,w-3,y),fill="#C4966B")
            d.rectangle((2,7,w-3,9),fill="#A47B52",outline=INK)
            for x in [2,w-4]:d.rectangle((x,7,x+1,18),fill=INK)
            for x in [cx-4,cx+4]:d.line((x,22,x,h-3),fill="#D3A77D")
            for y in range(24,h-3,5):d.line((cx-4,y,cx+4,y),fill="#C4966B")
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
    else: raise AssertionError("Missing original building artwork: " + kind)
    return image


def seasonal_tree(variant, season):
    """Broadleaf-only seasonal art; evergreen and resource quantities are unchanged."""
    image=Image.new("RGBA",(32,40));d=ImageDraw.Draw(image)
    d.ellipse((5,34,27,39),fill=(38,60,59,48))
    if season=="autumn":
        base=tile("conifer_base").crop((0,8,16,16));image.alpha_composite(base,(8,32))
        crown=leafy_crown(variant)
        # Keep the existing crown mask and clustered value structure.
        palette={INK:INK,DEEP:"#765D40",MOSS:"#A47B52",
                 "#7F995F":"#B58A4F","#8C9F64":"#B96C50",
                 "#A3B578":"#D1AD65","#B2BA7D":"#D39262","#BDC48B":"#E5C286"}
        colors={tuple(bytes.fromhex(key[1:])):tuple(bytes.fromhex(value[1:])) for key,value in palette.items()}
        crown.putdata([(*colors.get(pixel[:3],pixel[:3]),pixel[3]) for pixel in crown.get_flattened_data()])
        image.alpha_composite(crown,(4,8))
    else:
        # Full-height forked branches distinguish a dormant tree from a stump.
        branches=[[(15,37),(16,23),(14,10),(12,5)],
                  [(16,27),(8,21),(5,13)],[(14,17),(22,12),(25,6)],
                  [(16,31),(24,24),(27,17)],[(9,22),(3,19)],
                  [(22,12),(21,6)],[(14,12),(7,8)]]
        for points in branches:d.line(points,fill=INK,width=3)
        for points in branches:d.line(points,fill=WOOD,width=1)
        d.line((15,36,16,25),fill="#C4966B")
        d.line((13,11,11,6),fill="#C4966B")
        if variant==2:image=image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return image


def item(kind, tier):
    image = Image.new("RGBA", (16,24));d=ImageDraw.Draw(image)
    for level in range(tier+1):
        y=20-level*4;x=2+(level%2)*2
        if kind=="wood":
            d.rectangle((x+1,y-5,x+9,y+1),fill=WOOD,outline=INK)
            d.line((x+2,y-4,x+8,y-4),fill=CLAY)
            d.ellipse((x+7,y-5,x+11,y+1),fill="#C4966B",outline=INK)
            d.line((x+9,y-3,x+9,y-1),fill=WOOD)
        elif kind=="grain":
            # Tied sheaves stay legible among planted rows and harvested piles.
            for px,top in [(4,y-7),(8,y-9),(12,y-7)]:
                d.line((8,y+1,px,top),fill=WOOD,width=2)
                d.line((8,y,px,top),fill=LIGHT)
                d.ellipse((px-1,top-1,px+1,top+3),fill=LIGHT,outline="#A47B52")
                d.point((px,top),fill=CREAM)
            d.line((5,y-2,10,y-2),fill=CREAM,width=2)
        elif kind=="fiber":
            d.ellipse((x,y-6,x+11,y+1),fill=MOSS,outline=INK)
            d.arc((x+2,y-5,x+9,y),0,330,fill="#BDC48B")
            d.arc((x+4,y-4,x+7,y-1),20,310,fill=DEEP)
            d.line((x+7,y-1,x+11,y+1),fill="#BDC48B")
        elif kind=="cloth":
            d.rounded_rectangle((x,y-5,x+10,y+1),radius=1,fill=ROOF,outline=INK)
            d.line((x+1,y-4,x+9,y-4),fill="#BDB8C6")
            d.line((x+1,y-1,x+9,y-1),fill="#555668")
            d.line((x+7,y-4,x+7,y),fill=CREAM)
        elif kind=="leather":
            d.polygon([(x+2,y-6),(x+8,y-6),(x+8,y-4),(x+11,y-2),
                       (x+8,y),(x+8,y+1),(x+2,y+1),(x+2,y-1),(x,y-2),(x+2,y-4)],fill=WOOD,outline=INK)
            d.line((x+3,y-5,x+7,y-5),fill="#C4966B")
        elif kind in ("stone","clay","iron_ore","charcoal"):
            color={"stone":STONE,"clay":CLAY,"iron_ore":SHADE,"charcoal":INK}[kind]
            d.ellipse((x,y-5,min(15,x+10),y+1),fill=color,outline=INK)
            d.line((x+3,y-3,x+7,y-3),fill=CLAY if kind=="wood" else CREAM)
        elif kind in ("iron","brick"):
            color={"iron":STONE,"brick":CLAY}[kind]
            d.rectangle((x,y-5,min(15,x+10),y),fill=color,outline=INK)
            d.line((x+2,y-4,x+8,y-4),fill=CREAM)
            if kind=="brick":d.line((x+5,y-3,x+5,y),fill=WOOD)
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
        elif kind=="herb":
            # A tied leaf bundle, distinct from edible berries and vegetables.
            for px,top in [(4,y-8),(8,y-10),(12,y-8)]:
                d.line((8,y+1,px,top+2),fill=DEEP,width=2)
                d.ellipse((px-2,top,px+1,top+4),fill=MOSS,outline=INK)
                d.point((px-1,top+1),fill="#BDC48B")
            d.line((6,y-2,10,y-2),fill=CREAM,width=2)
        elif kind=="vegetable":
            for px,py in [(5,y-2),(10,y-3)]:
                d.ellipse((px-3,py-4,px+3,py+1),fill=CREAM,outline=INK)
                d.line((px+1,py-2,px+2,py),fill="#C6C7AD")
                d.line((px,py+1,px,py+2),fill=CREAM)
                d.polygon([(px,py-4),(px-3,py-7),(px,py-6),(px+2,py-8),(px+2,py-5)],fill=MOSS,outline=DEEP)
        elif kind=="berry":
            d.polygon([(2,y-3),(13,y-3),(12,y+1),(3,y+1)],fill=WOOD,outline=INK)
            for px,py in [(4,y-5),(8,y-6),(11,y-4),(6,y-3)]:
                d.ellipse((px-2,py-2,px+1,py+1),fill="#A85250",outline=INK)
                d.point((px-1,py-1),fill="#D98D78")
            d.line((3,y-1,12,y-1),fill="#C4966B")
        elif kind=="meat":
            d.line((5,y-3,2,y),fill=CREAM,width=2)
            d.point((1,y),fill=CREAM);d.point((2,y+1),fill=CREAM)
            d.ellipse((4,y-7,13,y),fill="#A85250",outline=INK)
            d.arc((5,y-6,12,y-1),150,320,fill="#D98D78")
            d.point((9,y-3),fill=CREAM)
        elif kind=="meal":
            d.polygon([(2,y-3),(13,y-3),(11,y+1),(4,y+1)],fill=WOOD,outline=INK)
            d.ellipse((2,y-6,13,y-1),fill=CREAM,outline=INK)
            d.ellipse((4,y-5,11,y-2),fill="#D39B58")
            for px,py in [(5,y-4),(9,y-3)]:d.point((px,py),fill=MOSS)
            d.point((8,y-4),fill=CLAY)
        elif kind=="travel_ration":
            d.polygon([(3,y-6),(11,y-7),(14,y-3),(12,y+1),(3,y),(1,y-3)],fill="#BDA479",outline=INK)
            d.line((3,y-5,10,y-6,12,y-4),fill=CREAM)
            d.line((7,y-6,8,y),fill=WOOD,width=2)
            d.line((2,y-3,13,y-2),fill=WOOD)
            d.point((8,y-3),fill=CREAM)
        else:
            raise AssertionError(kind)
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
    for season in ["autumn","winter"]:
        for variant in [1,2]:images[f"resource/tree_{season}/{variant}"]=seasonal_tree(variant,season)
    for kind in ["grass","poor","rich"]:
        for variant in range(3):
            images[f"ground/winter_{kind}/{variant}"]=winter_ground(ground(kind,variant))
    for kind in ["berry_bush","herb_patch","mushroom_patch"]:
        images[f"resource/{kind}_depleted/0"]=depleted_resource(kind)
    for season in ["summer","winter"]:
        for kind in ["poor","rich"]:
            for mask in range(1,16):
                art=soil_edge(kind,mask)
                images[f"ground/{season}_{kind}_edge/{mask}"]=winter_ground(art) if season=="winter" else art
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
