#!/usr/bin/env python3
"""Check the current M0 catalog, media provenance and font coverage; no full-catalog claim."""
from pathlib import Path
import hashlib
import json
import re
import struct
from gdscript_strings import extract_strings
from ui_messages import load_catalog

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

environment_sources = root / "data/environment_sources.json"
if any(asset["id"] == "woodland_environment" for asset in manifest):
    sources = json.loads(environment_sources.read_text())
    assert sources["pack"] == "Tiny Town 1.1" and len(sources["components"]) == 19
    assert sources["license_sha256"] == "c483c167cc3bdfe17c15f957ff847d409f64d81b410b28783636cf3b2b7814c5"
    for semantic, component in sources["components"].items():
        assert component["author"] == "Kenney" and component["license"] == "CC0-1.0" and component["edited"] is False
        assert component["path"].startswith("assets/source/tiny-town/") and ".." not in Path(component["path"]).parts
        content = (root / component["path"]).read_bytes()
        assert hashlib.sha256(content).hexdigest() == component["sha256"], semantic
        assert struct.unpack_from(">II", content, 16) == (16, 16), semantic
        rectangle = component["packed_atlas_rectangle"]
        assert len(rectangle) == 4 and rectangle[2:] == [16,16] and rectangle[0] % 16 == 0 and rectangle[1] % 16 == 0
        assert 0 <= rectangle[0] < 192 and 0 <= rectangle[1] < 176
        assert hashlib.sha256((root / component["evidence"]).read_bytes()).hexdigest() == sources["license_sha256"]
    artwork = json.loads((root / "data/environment_art.json").read_text())
    media = next(asset for asset in manifest if asset["id"] == "woodland_environment")
    assert media["semantic_layout"] == "data/environment_art.json"
    width, height = struct.unpack_from(">II", (root / media["path"]).read_bytes(), 16)
    assert width <= 2048 and height <= 2048
    for semantic, (x,y,w,h) in artwork["rectangles"].items():
        assert all(type(n) is int for n in (x,y,w,h)) and min(x,y) >= 0 and min(w,h) > 0
        assert x+w <= width and y+h <= height, semantic
    print(f"Validated 19 retained CC0 component files/licenses and {len(artwork['rectangles'])} environment atlas rectangles.")

# Validate every shipped string character, including legacy facts displayed by
# current UI. En dashes have one explicit presentation-only ASCII substitution.
required_text = set(chr(cp) for cp in range(32, 127))
for script in (root / "src").rglob("*.gd"):
    for value in extract_strings(script.read_text()):
        required_text.update(ch for ch in value.replace("\u2013", "-") if ord(ch) >= 32)
for path in (root / "data/catalogs").glob("en*.json"):
    def strings(value):
        if isinstance(value, str):
            yield value
        elif isinstance(value, dict):
            for child in value.values():
                yield from strings(child)
        elif isinstance(value, list):
            for child in value:
                yield from strings(child)
    for value in strings(json.loads(path.read_text())):
        required_text.update(ch for ch in value.replace("\u2013", "-") if ord(ch) >= 32)

ui_messages = load_catalog(root / "data/catalogs/en_ui.json")
ui_references = {value for script in (root / "src").rglob("*.gd")
                 for value in extract_strings(script.read_text()) if value.startswith("ui.")}
assert ui_references == set(ui_messages), f"UI message coverage: missing {ui_references-set(ui_messages)}, unused {set(ui_messages)-ui_references}"
print(f"Validated {len(ui_messages)} referenced English UI keys, named parameters and complete plural forms.")

# TrueType cmap format 4; Mini is the sole explicit fallback for Bold.
for name in ("kenney_mini.ttf", "kenney_bold.ttf"):
    assert "allow_system_fallback=false" in (root / "assets/exported/fonts" / (name + ".import")).read_text(), name
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
    for cp in sorted(ord(ch) for ch in required_text):
        for i in range(segments):
            lo = struct.unpack_from(">H", data, start + i * 2)[0]
            hi = struct.unpack_from(">H", data, end + i * 2)[0]
            if lo <= cp <= hi:
                shift = struct.unpack_from(">h", data, delta + i * 2)[0]
                offset = struct.unpack_from(">H", data, ranges + i * 2)[0]
                glyph = ((cp + shift) & 65535) if offset == 0 else struct.unpack_from(">H", data, ranges + i * 2 + offset + (cp - lo) * 2)[0]
                if offset and glyph:
                    glyph = (glyph + shift) & 65535
                if glyph:
                    supported.add(chr(cp))
                break
    required = required_text if name == "kenney_mini.ttf" else set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .!?")
    missing = required - supported
    assert not missing, f"{name}: missing shipped text characters {missing}"
print(f"Validated {len(required_text)} shipped text characters against actual licensed font glyphs, explicit punctuation mapping and disabled system fallback.")
for folder in ("src/sim", "src/generation"):
    if (root / folder).exists():
        for script in (root / folder).rglob("*.gd"):
            assert not re.search(r"\b(randf|randi|randomize|seed|randf_range|randi_range)\s*\(", script.read_text()), script
print(f"Validated M0 fixture, {len(manifest)} media entries, two fonts and pure RNG boundaries. Remaining release media are still in progress.")

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
print('Validated M1 subset catalogs and translation keys; the complete catalog is checked below.')

m2 = json.loads((root / 'data/catalogs/m2.json').read_text())
assert set(m2) == {'version','items','buildings','resources','recipes','crops'}
assert m2['version'] == 'm2-survival-1'
m2_translation = json.loads((root / 'data/catalogs/en_m2.json').read_text())
m2_fields = fields | {'buildings':fields['buildings']|{'age_denominator'},'crops':{'item','yield_count','growth','seasons','unlock','roof','prepare_milli','sow_milli','harvest_milli'}}
m2_ids = {}
for kind, extra in m2_fields.items():
 m2_ids[kind]={}
 for d in m2[kind]:
  assert set(d)==base|extra,(kind,d['id'],'unknown/missing fields')
  assert d['id'] not in m2_ids[kind]
  assert d['name_key'] in m2_translation and d['description_key'] in m2_translation
  assert re.fullmatch('[a-z][a-z0-9_]*',d['id'])
  for key,value in d.items():
   if isinstance(value,(int,float)) and not isinstance(value,bool): assert type(value) is int and value>=0,key
  m2_ids[kind][d['id']]=d
for d in m2['crops']:
 assert d['item'] in m2_ids['items'] and d['seasons'] and all(type(s) is int and s in range(4) for s in d['seasons'])
 assert d['growth']>0 and d['yield_count']>0 and type(d['roof']) is bool
for d in m2['buildings']:
 assert d['age_denominator'] in [1,2,4] and 1<=d['width']<=4 and 1<=d['height']<=4
 assert type(d['solid']) is bool and type(d['room_boundary']) is bool
 for item,count in d['materials'].items(): assert item in m2_ids['items'] and type(count) is int and count>0
for r in m2['recipes']:
 assert r['station'] in m2_ids['buildings'] and all(i in m2_ids['items'] for i in r['alternatives'])
print('Validated M2 agriculture/storage subset; release acquisition chains are checked below.')

m3=json.loads((root / 'data/catalogs/m3.json').read_text())
assert m3['version']=='m3-people-seasons-1'
assert {k:v for k,v in m3.items() if k!='version'}=={k:v for k,v in m2.items() if k!='version'}, 'M3 weather checkpoint retains the validated crop/job catalog'
print('Validated immutable M3 weather-checkpoint catalog and M1/M2 compatibility catalogs.')

full=json.loads((root / 'data/catalogs/colony_v1.json').read_text())
full_text=json.loads((root / 'data/catalogs/en_colony_v1.json').read_text())
assert full['version']=='colony-v1'
assert len(full['items'])==28 and len(full['buildings'])==34 and len(full['resources'])==7 and len(full['recipes'])==13 and len(full['crops'])==6 and len(full['research'])==12
catalog_ids={kind:{d['id']:d for d in defs} for kind,defs in full.items() if isinstance(defs,list)}
for kind,defs in catalog_ids.items():
 assert len(defs)==len(full[kind]), 'duplicate catalog ID'
 for identifier,d in defs.items():
  assert re.fullmatch('[a-z][a-z0-9_]*',identifier)
  assert d['name_key'] in full_text and d['description_key'] in full_text
  if 'unlock' in d: assert d['unlock']=='initial' or d['unlock'] in catalog_ids['research']
  for item,n in d.get('materials',{}).items(): assert item in catalog_ids['items'] and type(n) is int and n>0
for recipe in full['recipes']:
 assert recipe['station'] in catalog_ids['buildings'] and recipe['skill'] in ['Cooking','Craft','Care']
 assert all(item in catalog_ids['items'] for item in recipe['alternatives'])
 assert recipe['food_count'] in [0,4] and bool(recipe['alternatives'])==(recipe['food_count']>0)
 for item,n in recipe['outputs'].items(): assert item in catalog_ids['items'] and 0<n<=catalog_ids['items'][item]['stack_limit']
for resource in full['resources']: assert resource['item'] in catalog_ids['items'] and resource['yield_count']>0
assert sum(r['points'] for r in full['research'])==4700
finished=set()
while len(finished)<len(full['research']):
 ready={r['id'] for r in full['research'] if set(r['prerequisites'])<=finished}-finished
 assert ready, 'research cycle/missing prerequisite'
 finished |= ready
for r in full['research']:
 for unlock in r['unlocks']:
  kind,identifier=unlock.split(':')
  assert identifier in catalog_ids[{'building':'buildings','recipe':'recipes','crop':'crops'}[kind]]
assert not catalog_ids['buildings']['supply_cart']['buildable']
assert catalog_ids['buildings']['garden_bench']['materials']=={'wood':6}
for kind in ['items','buildings','resources','recipes','crops']:
 for old in m3[kind]:
  for key,value in old.items():
   if key=='alternatives':assert set(value)<=set(catalog_ids[kind][old['id']][key])
   else:assert catalog_ids[kind][old['id']][key]==value, (kind,old['id'],key,'released contract changed')
print('Validated complete 28-item, 34-structure, 13-recipe, 12-research catalog, all references, 4700 points and released numeric contracts.')

next_catalog=json.loads((root / 'data/catalogs/colony_v2.json').read_text())
next_text=json.loads((root / 'data/catalogs/en_colony_v2.json').read_text())
assert next_catalog['version']=='colony-v2'
for kind in ['items','buildings','resources','recipes','crops','research']:
 assert next_catalog[kind]==full[kind], 'released numeric contract changed'
new_ids={kind:{d['id']:d for d in next_catalog[kind]} for kind in ['animals','enemies','expeditions','communities','events','charter']}
assert [len(new_ids[k]) for k in new_ids]==[6,3,8,3,4,5]
for kind,definitions in new_ids.items():
 assert len(definitions)==len(next_catalog[kind])
 for d in definitions.values():
  assert d['name_key'] in next_text and d['description_key'] in next_text
  for field in ['outputs','slaughter_outputs','rewards','payment','delivery']:
   for item,n in d.get(field,{}).items(): assert item in catalog_ids['items'] and type(n) is int and n>0
  for faction in d.get('reputation',{}) if isinstance(d.get('reputation'),dict) else []: assert faction in new_ids['communities']
for d in new_ids['communities'].values():
 for item,n in d['stock'].items():assert (item in catalog_ids['items'] or item in new_ids['animals']) and type(n) is int and n>0
assert sum(d.get('initial_count',0) for d in new_ids['animals'].values())==16
assert sum(d['cost'] for d in new_ids['enemies'].values())==7
print('Validated additive wildlife, enemy, expedition, community, event and charter catalogs; released v1 contracts remain immutable.')
budget_catalog=json.loads((root / 'data/catalogs/colony_v3.json').read_text())
assert budget_catalog['version']=='colony-v3'
assert {**budget_catalog,'version':'colony-v2'}==next_catalog, 'Work-budget content revision may not change released recipes, quantities, geometry or progression'
print('Validated work-budget content v3; every catalog value except the version is identical to retained v2.')

current_catalog=json.loads((root / 'data/catalogs/colony_v4.json').read_text())
assert current_catalog['version']=='colony-v4'
assert {**current_catalog,'version':'colony-v3'}==budget_catalog, 'Food interruption correction must retain every released recipe, quantity, geometry and progression rule'
print('Validated food-interruption content v4; definitions are identical to retained v3 except the declared version.')

feasible_sleep_catalog=json.loads((root / 'data/catalogs/colony_v5.json').read_text())
assert feasible_sleep_catalog['version']=='colony-v5'
assert {**feasible_sleep_catalog,'version':'colony-v4'}==current_catalog, 'Feasible sleep correction must retain every released recipe, quantity, geometry and progression rule'
print('Validated feasible-sleep content v5; definitions are identical to retained v4 except the declared version.')
