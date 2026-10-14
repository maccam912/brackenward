#!/usr/bin/env python3
"""Exercise disposable package stamping and preserve published Android identity."""
import contextlib
import io
import json
import re
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from stamp_build import ROOT, stamp


class StampBuildTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / "data").mkdir()
        (self.root / "project.godot").write_text('config/version="0.7.5-m7"\n')
        self.preset = self.root / "export_presets.cfg"
        text = (ROOT / "export_presets.cfg").read_text()
        for pattern, value in ((r'^version/code=\d+$', 'version/code=543'),
                               (r'^version/name="[^"]*"$', 'version/name="0.7.5-m7+abc1234"'),
                               (r'^application/short_version="[^"]*"$', 'application/short_version="1.0.0"'),
                               (r'^application/version="[^"]*"$', 'application/version="1"')):
            text = re.sub(pattern, value, text, flags=re.MULTILINE)
        self.preset.write_text(text)

    def invoke(self, local, environ=None):
        with contextlib.redirect_stdout(io.StringIO()):
            stamp(self.root, local, environ)

    def test_local_sync_preserves_ci_android_and_provenance(self):
        provenance = self.root / "data/build.json"
        provenance.write_text('{"existing":"untouched"}\n')
        original = self.preset.read_text()
        self.invoke(True, {})
        updated = self.preset.read_text()
        self.assertIn('application/short_version="0.7.5"', updated)
        self.assertIn('application/version="543"', updated)
        self.assertIn('application/file_version="0.7.5.543"', updated)
        self.assertIn('application/product_version="0.7.5.543"', updated)
        self.assertEqual(original.split('[preset.1]')[0], updated.split('[preset.1]')[0])
        self.assertEqual('{"existing":"untouched"}\n', provenance.read_text())

    def test_ci_exact_source_is_repeatable_and_all_versions_match(self):
        source = '0123456789abcdef0123456789abcdef01234567'
        with patch('stamp_build.subprocess.check_output', return_value=source + '\n'):
            for _ in range(2):
                self.invoke(False, {"GITHUB_RUN_NUMBER": "512", "GITHUB_RUN_ID": "987"})
        updated = self.preset.read_text()
        self.assertIn('version/code=612\n', updated)
        self.assertIn('version/name="0.7.5-m7+0123456"', updated)
        self.assertIn('application/version="612"', updated)
        self.assertIn('application/file_version="0.7.5.612"', updated)
        self.assertEqual({"commit": source, "run_number": 512, "version_code": 612,
                          "run_id": "987", "kind": "development_debug"},
                         json.loads((self.root / "data/build.json").read_text()))

    def test_invalid_version_or_windows_overflow_does_not_modify_files(self):
        for version in ('invalid', '0.7.65536', '0.7.5'):
            (self.root / 'project.godot').write_text(f'config/version="{version}"\n')
            original = self.preset.read_text()
            env = {"GITHUB_RUN_NUMBER": "65436", "GITHUB_RUN_ID": "987"} if version == '0.7.5' else {}
            with self.assertRaises(ValueError):
                self.invoke(version != '0.7.5', env)
            self.assertEqual(original, self.preset.read_text())
            self.assertFalse((self.root / 'data/build.json').exists())

    def test_missing_or_duplicate_field_fails_before_writing(self):
        original = self.preset.read_text()
        for broken in (original.replace('application/version="1"\n', ''),
                       original + '\napplication/short_version="1.0.0"\n'):
            self.preset.write_text(broken)
            with self.assertRaises(ValueError):
                self.invoke(True, {})
            self.assertEqual(broken, self.preset.read_text())


if __name__ == "__main__":
    unittest.main()
