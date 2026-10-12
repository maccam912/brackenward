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
