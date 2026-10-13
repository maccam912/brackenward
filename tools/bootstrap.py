#!/usr/bin/env python3
"""Install verified editor and templates in a task-specific cache. No binary enters Git."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
LOCK = json.loads((ROOT / "toolchain.lock.json").read_text())
CACHE = Path(os.environ.get("BRACKENWARD_TOOLCHAIN", Path.home() / ".local/share/brackenward/toolchain"))

def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha512").hexdigest()

def archive(name):
    info = LOCK["archives"][name]
    path = CACHE / name
    if not path.exists() or digest(path) != info["sha512"]:
        print("Downloading", name, flush=True)
        temp = path.with_suffix(path.suffix + ".partial")
        urllib.request.urlretrieve(info["url"], temp)
        if digest(temp) != info["sha512"]:
            raise SystemExit("Archive checksum mismatch: " + name)
        temp.replace(path)
    return path

def platform_archive(host=None):
    host = sys.platform if host is None else host
    platforms = {"darwin": "macos.universal", "linux": "linux.x86_64", "win32": "win64.exe"}
    if host not in platforms:
        raise SystemExit("Unsupported editor platform: " + host)
    return f"Godot_v{LOCK['godot_version']}-stable_{platforms[host]}.zip"

def engine_binary(host=None):
    host = sys.platform if host is None else host
    names = {"darwin": "Godot.app/Contents/MacOS/Godot", "linux": f"Godot_v{LOCK['godot_version']}-stable_linux.x86_64", "win32": f"Godot_v{LOCK['godot_version']}-stable_win64_console.exe"}
    platform_archive(host)  # Reject unrecognized hosts instead of assuming Linux.
    return CACHE / LOCK["godot_version"] / names[host]

def verify_engine(binary):
    expected = f"{LOCK['godot_version']}.stable.official.{LOCK['godot_build'][:9]}"
    result = subprocess.run([str(binary), "--version"], capture_output=True, text=True, timeout=30, check=True)
    if result.stdout.strip() != expected:
        raise SystemExit("Pinned official Godot build required: " + expected)

def matches_editor_archive(source, destination):
    # The Windows console launcher loads its neighboring executable. Check every
    # shipped file so a matching launcher cannot hide a replaced engine/library.
    for entry in source.infolist():
        if entry.is_dir():
            continue
        installed = destination / entry.filename
        if not installed.is_file() or installed.stat().st_size != entry.file_size:
            return False
        with source.open(entry) as incoming:
            expected = hashlib.file_digest(incoming, "sha512").hexdigest()
        if digest(installed) != expected:
            return False
    return True

def install_editor(editor, destination, binary):
    """Never rewrite an executable inode: running macOS binaries can be killed."""
    member = binary.relative_to(destination).as_posix()
    with zipfile.ZipFile(editor) as source:
        if binary.exists() and matches_editor_archive(source, destination):
            verify_engine(binary)
            return False
        with tempfile.TemporaryDirectory(prefix="install-", dir=CACHE) as staging_name:
            staging = Path(staging_name)
            source.extractall(staging)
            staged_binary = staging / member
            staged_binary.chmod(0o755)
            verify_engine(staged_binary)
            destination.mkdir(exist_ok=True)
            for entry in staging.iterdir():
                target = destination / entry.name
                if entry.is_dir() and target.exists():
                    # Keep the prior application recoverable, including any running inode.
                    backup = Path(tempfile.mkdtemp(prefix="previous-editor-", dir=CACHE)) / entry.name
                    target.rename(backup)
                    try:
                        entry.rename(target)
                    except OSError:
                        backup.rename(target)
                        raise
                else:
                    os.replace(entry, target)
    return True

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--editor-only", action="store_true", help="Skip export templates for source replay jobs")
    args = parser.parse_args()
    CACHE.mkdir(parents=True, exist_ok=True)
    editor = archive(platform_archive())
    binary = engine_binary()
    destination = CACHE / LOCK["godot_version"]
    installed = install_editor(editor, destination, binary)
    if not args.editor_only:
        (binary.parent / "_sc_").touch()
        editor_data = (binary.parents[3] if sys.platform == "darwin" else binary.parent) / "editor_data"
        editor_data.mkdir(exist_ok=True)
        templates = archive(f"Godot_v{LOCK['godot_version']}-stable_export_templates.tpz")
        if sys.platform == "win32":
            template_base = Path(os.environ["APPDATA"]) / "Godot/export_templates"
        else:
            template_base = Path.home() / ("Library/Application Support/Godot/export_templates" if sys.platform == "darwin" else ".local/share/godot/export_templates")
        template_root = template_base / f"{LOCK['godot_version']}.stable"
        template_root.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(templates) as source:
            for entry in source.infolist():
                if entry.is_dir():
                    continue
                target = template_root / Path(entry.filename).name
                with source.open(entry) as incoming, target.open("wb") as output:
                    shutil.copyfileobj(incoming, output)
        isolated_templates = editor_data / "export_templates"
        isolated_templates.mkdir(exist_ok=True)
        link = isolated_templates / f"{LOCK['godot_version']}.stable"
        if not link.exists():
            if sys.platform == "win32":
                shutil.copytree(template_root, link)  # No developer-mode/symlink privilege needed.
            else:
                link.symlink_to(template_root, target_is_directory=True)
    print("Verified Godot " + LOCK["godot_version"] + ":", binary)
    print("Installed atomically." if installed else "Reused verified executable without rewriting it.")
    print("Set BRACKENWARD_GODOT to this executable for shell tools.")

if __name__ == "__main__":
    main()
