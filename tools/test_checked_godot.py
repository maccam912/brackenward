#!/usr/bin/env python3
"""Exercise real subprocess exit/error/timeout boundaries without an engine install."""
import contextlib
import io
import sys
import unittest
import tempfile
from checked_godot import run_command


class CheckedGodotTests(unittest.TestCase):
    def run_script(self, source, **options):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return run_command([sys.executable, "-c", source], **options)

    def test_clean_zero_exit(self):
        self.assertEqual(0, self.run_script("print('Godot Engine: clean import')"))

    def test_zero_exit_with_script_error_is_rejected(self):
        self.assertEqual(1, self.run_script("print('SCRIPT ERROR: Parse Error: fixture')"))

    def test_zero_exit_with_ansi_engine_error_is_rejected(self):
        self.assertEqual(1, self.run_script("print('\\x1b[31mERROR: broken export\\x1b[0m')"))

    def test_nonzero_exit_without_error_text_is_rejected(self):
        self.assertEqual(1, self.run_script("raise SystemExit(7)"))

    def test_warnings_do_not_become_script_errors(self):
        self.assertEqual(0, self.run_script("print('WARNING: support information')"))

    def test_timeout_has_no_success_result(self):
        self.assertEqual(1, self.run_script("import time; time.sleep(1)", timeout=0.02))

    def test_exported_app_can_run_outside_the_source_checkout(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(0, self.run_script("from pathlib import Path; assert Path.cwd().samefile(" + repr(directory) + ")",
                                               working_directory=directory))

    def test_exported_startup_requires_renderer_and_application_exit(self):
        marker = "BRACKENWARD_NATIVE_SMOKE_EXIT frames=60 audio_drained=true isolated=true"
        renderer = "OpenGL API 4.1 - Compatibility - Using Device: Test GPU"
        self.assertEqual(1, self.run_script("print(" + repr(marker) + ")", require_smoke_exit=True))
        self.assertEqual(1, self.run_script("print(" + repr(renderer) + ")", require_smoke_exit=True))
        self.assertEqual(0, self.run_script("print(" + repr(renderer + "\n" + marker) + ")", require_smoke_exit=True))


if __name__ == "__main__":
    unittest.main()
