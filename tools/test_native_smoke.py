#!/usr/bin/env python3
"""Regression checks for actual native CI renderer evidence and false successes."""
import unittest

from native_smoke import inspect_output, is_software_renderer


class NativeSmokeTests(unittest.TestCase):
    def test_windows_angle_warp_is_graphical_software_rendering(self):
        renderer = "OpenGL API OpenGL ES 3.0 (ANGLE 2.1.1 git hash: aaebda1c5a40) - Compatibility - Using Device: Google Inc. (Microsoft) - ANGLE (Microsoft, Microsoft Basic Render Driver (0x0000008C) Direct3D11 vs_5_0 ps_5_0, D3D11-10.0.20348.5386)"
        self.assertFalse(inspect_output(renderer, 0, True)["failures"])
        self.assertTrue(is_software_renderer(renderer))

    def test_linux_llvmpipe_is_graphical_software_rendering(self):
        renderer = "OpenGL API 4.5 (Core Profile) Mesa 25.2.8-0ubuntu0.24.04.4 - Compatibility - Using Device: Mesa - llvmpipe (LLVM 20.1.2, 256 bits)"
        self.assertFalse(inspect_output(renderer, 0, True)["failures"])
        self.assertTrue(is_software_renderer(renderer))

    def test_mac_renderer_is_not_mislabeled_as_software(self):
        renderer = "OpenGL API 4.1 Metal - 90.5 - Compatibility - Using Device: Apple - Apple M5 Pro"
        self.assertFalse(inspect_output(renderer, 0, True)["failures"])
        self.assertFalse(is_software_renderer(renderer))

    def test_headless_or_failed_engine_cannot_pass(self):
        self.assertTrue(inspect_output("Godot Engine\n", 0, True)["failures"])
        renderer = "OpenGL API 4.1 - Compatibility - Using Device: Apple - GPU\n"
        self.assertTrue(inspect_output(renderer, 1, True)["failures"])
        self.assertTrue(inspect_output(renderer + "\x1b[31mSCRIPT ERROR: failed\x1b[0m\n", 0, True)["failures"])


if __name__ == "__main__":
    unittest.main()
