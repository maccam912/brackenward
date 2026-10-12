#!/usr/bin/env python3
"""CI provenance/version stamping; modifies only the disposable build checkout."""
import json, os, re, subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
run_number = int(os.environ["GITHUB_RUN_NUMBER"])
code = 100 + run_number
preset = root / "export_presets.cfg"
text = preset.read_text()
text = re.sub(r'version/code=\d+', f'version/code={code}', text)
text = re.sub(r'version/name="([^"]+)"', lambda m: f'version/name="{m[1]}+{commit[:7]}"', text)
preset.write_text(text)
(root / "data/build.json").write_text(json.dumps({"commit": commit, "run_number": run_number,
    "version_code": code, "run_id": os.environ["GITHUB_RUN_ID"], "kind": "development_debug"}, indent=2)+"\n")
print(f"Development version code {code}; source {commit[:12]}")
