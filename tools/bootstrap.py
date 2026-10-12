#!/usr/bin/env python3
"""Install verified editor and templates in a task-specific cache. No binary enters Git."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import sys
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
LOCK = json.loads((ROOT / "toolchain.lock.json").read_text())
CACHE = Path(os.environ.get("BRACKENWARD_TOOLCHAIN", Path.home() / ".local/share/brackenward/toolchain"))
CACHE.mkdir(parents=True, exist_ok=True)

def archive(name):
    info = LOCK["archives"][name]
    path = CACHE / name
    if not path.exists() or hashlib.sha512(path.read_bytes()).hexdigest() != info["sha512"]:
        print("Downloading", name, flush=True)
        temp = path.with_suffix(path.suffix + ".partial")
        urllib.request.urlretrieve(info["url"], temp)
        if hashlib.sha512(temp.read_bytes()).hexdigest() != info["sha512"]:
            raise SystemExit("Archive checksum mismatch: " + name)
        temp.replace(path)
    return path

platform = "macos.universal" if sys.platform == "darwin" else "linux.x86_64"
editor = archive(f"Godot_v4.7.2-stable_{platform}.zip")
destination = CACHE / "4.7.2"
destination.mkdir(exist_ok=True)
with zipfile.ZipFile(editor) as source:
    source.extractall(destination)
binary = destination / ("Godot.app/Contents/MacOS/Godot" if sys.platform == "darwin" else "Godot_v4.7.2-stable_linux.x86_64")
binary.chmod(0o755)
templates = archive("Godot_v4.7.2-stable_export_templates.tpz")
template_root = Path.home() / ("Library/Application Support/Godot/export_templates" if sys.platform == "darwin" else ".local/share/godot/export_templates") / "4.7.2.stable"
template_root.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(templates) as source:
    for entry in source.infolist():
        if entry.is_dir():
            continue
        target = template_root / Path(entry.filename).name
        with source.open(entry) as incoming, target.open("wb") as output:
            shutil.copyfileobj(incoming, output)
print("Verified Godot 4.7.2:", binary)
print("Set BRACKENWARD_GODOT to this executable on Linux.")
