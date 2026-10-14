#!/usr/bin/env python3
"""Keep native package versions in sync; CI also writes exact source provenance."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def replace_one(text, pattern, replacement):
    result, count = re.subn(pattern, replacement, text, flags=re.MULTILINE)
    if count != 1:
        raise ValueError(f"Expected one version field matching {pattern!r}, found {count}")
    return result


def sync_desktop_versions(text, project_version, code):
    match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)(?:-[A-Za-z0-9.-]+)?", project_version)
    if not match or not 1 <= code <= 65535:
        raise ValueError("Native versions require major.minor.patch and build code 1..65535")
    parts = tuple(int(part) for part in match.groups())
    if any(part > 65535 for part in parts):
        raise ValueError("Windows version components must fit unsigned 16-bit fields")
    short = ".".join(str(part) for part in parts)
    for field, value in (("file_version", f"{short}.{code}"),
                         ("product_version", f"{short}.{code}"),
                         ("short_version", short), ("version", str(code))):
        text = replace_one(text, rf'^application/{field}="[^"]*"$', f'application/{field}="{value}"')
    return text


def stamp(root, local=False, environ=None):
    environ = os.environ if environ is None else environ
    preset = root / "export_presets.cfg"
    text = preset.read_text()
    version = re.findall(r'^config/version="([^"]+)"$', (root / "project.godot").read_text(), re.MULTILINE)
    codes = re.findall(r'^version/code=(\d+)$', text, re.MULTILINE)
    if len(version) != 1 or len(codes) != 1:
        raise ValueError("Missing or ambiguous project/Android version")
    code = int(codes[0]) if local else 100 + int(environ["GITHUB_RUN_NUMBER"])
    text = sync_desktop_versions(text, version[0], code)
    if not local:
        commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
        run_id = environ["GITHUB_RUN_ID"]
        text = replace_one(text, r'^version/code=\d+$', f'version/code={code}')
        text = replace_one(text, r'^version/name="[^"]+"$', f'version/name="{version[0]}+{commit[:7]}"')
        (root / "data/build.json").write_text(json.dumps({"commit": commit,
            "run_number": int(environ["GITHUB_RUN_NUMBER"]), "version_code": code,
            "run_id": run_id, "kind": "development_debug"}, indent=2) + "\n")
        print(f"Development version code {code}; source {commit[:12]}")
    preset.write_text(text)
    if local:
        print(f"Desktop package versions synchronized with {version[0]}, build {code}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--local", action="store_true", help="Sync desktop metadata only, preserving CI Android/provenance fields")
    args = parser.parse_args()
    stamp(ROOT, args.local)
