#!/usr/bin/env python3
"""Check the current M0 catalog, media provenance and font coverage; no full-catalog claim."""
from pathlib import Path
import hashlib
import json
import re
import struct

root = Path(__file__).resolve().parents[1]
fixture = json.loads((root / "data/prototype.json").read_text())
assert fixture == {
    "schema_version": 1, "content_version": "m0-touch-1", "map_size": 128,
    "tick_rate": 10, "start_tick": 1800, "resident_names": ["Mira", "Oren", "Tavi", "Sela"],
    "purpose": "M0 touch and platform fixture; no colony economy yet",
}, "M0 fixture differs from its contract"
manifest = json.loads((root / "assets/licenses/manifest.json").read_text())
paths = set()
for asset in manifest:
    assert asset["path"] not in paths, "duplicate media path"
    paths.add(asset["path"])
    assert asset["license"] in ("CC0-1.0", "Original project asset")
    assert (root / asset["evidence"]).is_file()
    assert hashlib.sha256((root / asset["path"]).read_bytes()).hexdigest() == asset["sha256"], asset["path"]
for media in (root / "assets/exported").rglob("*"):
    if media.is_file() and not media.name.endswith(".import"):
        assert str(media.relative_to(root)) in paths, "unmanifested media: " + str(media)

# TrueType cmap format 4, validating Basic Latin actually present in both licensed fonts.
for name in ("kenney_mini.ttf", "kenney_bold.ttf"):
    data = (root / "assets/exported/fonts" / name).read_bytes()
    tables = struct.unpack_from(">H", data, 4)[0]
    cmap = next(struct.unpack_from(">I", data, 12 + i * 16 + 8)[0]
                for i in range(tables) if data[12 + i * 16:16 + i * 16] == b"cmap")
    subtables = struct.unpack_from(">H", data, cmap + 2)[0]
    formats = [cmap + struct.unpack_from(">I", data, cmap + 4 + i * 8 + 4)[0] for i in range(subtables)]
    fmt = next(offset for offset in formats if struct.unpack_from(">H", data, offset)[0] == 4)
    segments = struct.unpack_from(">H", data, fmt + 6)[0] // 2
    end = fmt + 14
    start = end + segments * 2 + 2
    delta = start + segments * 2
    ranges = delta + segments * 2
    supported = set()
    for cp in range(32, 127):
        for i in range(segments):
            lo = struct.unpack_from(">H", data, start + i * 2)[0]
            hi = struct.unpack_from(">H", data, end + i * 2)[0]
            if lo <= cp <= hi:
                shift = struct.unpack_from(">h", data, delta + i * 2)[0]
                offset = struct.unpack_from(">H", data, ranges + i * 2)[0]
                glyph = ((cp + shift) & 65535) if offset == 0 else struct.unpack_from(">H", data, ranges + i * 2 + offset + (cp - lo) * 2)[0]
                if glyph:
                    supported.add(chr(cp))
                break
    required = set(chr(cp) for cp in range(32, 127)) if name == "kenney_mini.ttf" else set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .!?")
    missing = required - supported
    assert not missing, f"{name}: missing Basic Latin {missing}"
for folder in ("src/sim", "src/generation"):
    if (root / folder).exists():
        for script in (root / folder).rglob("*.gd"):
            assert not re.search(r"\b(randf|randi|randomize|seed|randf_range|randi_range)\s*\(", script.read_text()), script
print(f"Validated M0 fixture, {len(manifest)} media entries, two fonts and pure RNG boundaries. Full-release catalogs are not implemented.")

catalog = json.loads((root / 'data/catalogs/m1.json').read_text())
assert set(catalog) == {'version','items','buildings','resources','recipes'}
assert catalog['version'] == 'm1-loop-1'
translations = json.loads((root / 'data/catalogs/en_m1.json').read_text())
base = {'id','name_key','description_key','icon_id','schema_version'}
fields = {
 'items': {'stack_limit','fullness','tags','shelf_ticks','barter_value'},
 'buildings': {'width','height','materials','work_milli','solid','room_boundary','health','unlock','storage_capacity'},
 'resources': {'item','yield_count','work_milli','solid','per_unit','regrow_ticks'},
 'recipes': {'station','alternatives','food_count','materials','outputs','work_milli','skill','unlock'},
}
by_kind = {}
for kind in fields:
 by_kind[kind] = {}
 for definition in catalog[kind]:
  assert set(definition) == base | fields[kind], (kind,definition['id'])
  assert re.fullmatch('[a-z][a-z0-9_]*', definition['id'])
  assert definition['id'] not in by_kind[kind], 'duplicate definition'
  assert definition['schema_version'] == 1
  assert definition['name_key'] in translations and definition['description_key'] in translations
  assert definition['icon_id'] == definition['id'], 'M1 procedural icon registry uses explicit definition IDs'
  for key,value in definition.items():
   if isinstance(value,(int,float)) and not isinstance(value,bool): assert type(value) is int and value >= 0, key
  by_kind[kind][definition['id']] = definition
for kind in ['buildings','recipes']:
 for d in catalog[kind]:
  for item,count in d['materials'].items():
   assert item in by_kind['items'] and type(count) is int and count > 0
for r in catalog['resources']:
 assert r['item'] in by_kind['items'] and r['yield_count'] > 0 and r['work_milli'] > 0
for r in catalog['recipes']:
 assert r['station'] in by_kind['buildings'] and r['alternatives'] and r['food_count'] > 0
 assert all(i in by_kind['items'] for i in r['alternatives'])
 for item,count in r['outputs'].items(): assert item in by_kind['items'] and 0 < count <= by_kind['items'][item]['stack_limit']
assert by_kind['buildings']['bed']['materials'] == {'wood':6,'fiber':2}
assert by_kind['recipes']['cook_meals']['outputs'] == {'meal':2}
print('Validated M1 subset catalogs and translation keys; full M4 catalogs remain pending.')
