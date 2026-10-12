#!/usr/bin/env python3
"""Prepare the pinned template without checking generated Gradle files into Git."""
from pathlib import Path
import hashlib, json, os, sys, zipfile
root = Path(__file__).resolve().parents[1]
lock = json.loads((root / "toolchain.lock.json").read_text())
if sys.platform == "darwin":
    templates = Path.home() / "Library/Application Support/Godot/export_templates/4.7.2.stable"
else:
    templates = Path.home() / ".local/share/godot/export_templates/4.7.2.stable"
source = templates / "android_source.zip"
if not source.is_file():
    raise SystemExit("Install Godot 4.7.2 export templates first (tools/bootstrap.py).")
android = root / "android/build"
if not (android / "config.gradle").is_file():
    with zipfile.ZipFile(source) as archive:
        archive.extractall(android)
if hashlib.sha256((android / "config.gradle").read_bytes()).hexdigest() != lock["template_config_sha256"]:
    raise SystemExit("Android template config differs from toolchain.lock.json; refusing an unpinned build.")
(root / "android/.build_version").write_text("4.7.2.stable")
sdk = Path(os.environ.get("ANDROID_HOME", Path.home() / "Library/Android/sdk"))
java = Path(os.environ.get("JAVA_HOME", "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"))
for directory in (android, root / "platform/android_save"):
    (directory / "local.properties").write_text("sdk.dir=" + str(sdk) + "\n")
for required in ("platforms/android-36", "build-tools/36.1.0", "ndk/29.0.14206865"):
    if not (sdk / required).is_dir():
        raise SystemExit("Missing Android SDK package: " + required)
# Editor path settings stay local and contain no signing credentials.
settings_dir = Path.home() / ("Library/Application Support/Godot" if sys.platform == "darwin" else ".config/godot")
settings_dir.mkdir(parents=True, exist_ok=True)
settings = settings_dir / "editor_settings-4.7.tres"
if settings.exists():
    text = settings.read_text()
else:
    text = '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
import re
for key, value in {"export/android/android_sdk_path": str(sdk), "export/android/java_sdk_path": str(java)}.items():
    line = key + " = " + json.dumps(value)
    pattern = r"^" + re.escape(key) + r" = .*?$"
    text = re.sub(pattern, line, text, flags=re.M) if re.search(pattern, text, flags=re.M) else text + line + "\n"
settings.write_text(text)
print("Pinned Android template ready.")
