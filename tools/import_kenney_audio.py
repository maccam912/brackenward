#!/usr/bin/env python3
"""Copy only the approved CC0 sounds; preserve exact source bytes and licenses."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
LICENSES = {
    "Interface Sounds": "f7966c773bbed0eca6a9c75081c44a178b38eae112724dbb5fdfbd4192d118a9",
    "RPG Audio": "7dc7dac2e06d170a6f91bc58c2a3c1a35a9ab9c711b893a52539eb709826312d",
}
SOUNDS = {
    "ui_select": ("Interface Sounds", "select_001.ogg"),
    "ui_confirm": ("Interface Sounds", "confirmation_001.ogg"),
    "ui_cancel": ("Interface Sounds", "back_001.ogg"),
    "ui_error": ("Interface Sounds", "error_001.ogg"),
    "chop": ("RPG Audio", "chop.ogg"), "cloth": ("RPG Audio", "cloth1.ogg"),
    "book": ("RPG Audio", "bookFlip1.ogg"),
    "door_open": ("RPG Audio", "doorOpen_1.ogg"), "door_close": ("RPG Audio", "doorClose_1.ogg"),
    **{f"footstep_{index}": ("RPG Audio", f"footstep0{index}.ogg") for index in range(5)},
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path.home() / "Downloads/Kenney Game Assets All-in-1 3.5.0")
    args = parser.parse_args()
    base = args.source / "Audio"
    evidence = {}
    for pack, digest in LICENSES.items():
        source = base / pack / "License.txt"
        assert hashlib.sha256(source.read_bytes()).hexdigest() == digest, "Unreviewed license source: " + str(source)
        path = ROOT / "assets/licenses" / ("kenney_" + pack.lower().replace(" ", "_") + ".txt")
        shutil.copyfile(source, path)
        evidence[pack] = str(path.relative_to(ROOT))
    path = ROOT / "assets/licenses/manifest.json"
    manifest = [asset for asset in json.loads(path.read_text()) if asset["id"] not in SOUNDS]
    exported = ROOT / "assets/exported/audio"
    exported.mkdir(parents=True, exist_ok=True)
    for ident, (pack, filename) in SOUNDS.items():
        original = base / pack / "Audio" / filename
        copied = exported / (ident + ".ogg")
        shutil.copyfile(original, copied)
        digest = hashlib.sha256(original.read_bytes()).hexdigest()
        assert hashlib.sha256(copied.read_bytes()).hexdigest() == digest
        manifest.append({"id": ident, "path": str(copied.relative_to(ROOT)),
            "source": f"Kenney Game Assets All-in-1 3.5.0/Audio/{pack}/Audio/{filename}",
            "author": "Kenney", "license": "CC0-1.0", "sha256": digest,
            "edited": False, "evidence": evidence[pack]})
    path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Copied {len(SOUNDS)} approved sounds and both pinned CC0 license files; original bytes retained.")


if __name__ == "__main__":
    main()
