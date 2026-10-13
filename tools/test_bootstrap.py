#!/usr/bin/env python3
"""Portable installer regression checks; fixtures never touch the shared engine cache."""
import tempfile
from pathlib import Path
import unittest
from unittest.mock import patch
import zipfile

import bootstrap

class InstallerTests(unittest.TestCase):
    def test_supported_archives_are_locked(self):
        for host in ["darwin", "linux", "win32"]:
            self.assertIn(bootstrap.platform_archive(host), bootstrap.LOCK["archives"])
        with self.assertRaises(SystemExit):
            bootstrap.platform_archive("unsupported")

    def test_repeated_install_keeps_executable_inode_and_mtime(self):
        with tempfile.TemporaryDirectory() as folder:
            cache = Path(folder)
            archive = cache / "test.zip"
            with zipfile.ZipFile(archive, "w") as source:
                source.writestr("engine", b"verified fixture bytes")
            destination = cache / "install"
            binary = destination / "engine"
            with patch.object(bootstrap, "CACHE", cache), patch.object(bootstrap, "verify_engine"):
                self.assertTrue(bootstrap.install_editor(archive, destination, binary))
                before = binary.stat()
                self.assertFalse(bootstrap.install_editor(archive, destination, binary))
                after = binary.stat()
                self.assertEqual((before.st_ino, before.st_mtime_ns), (after.st_ino, after.st_mtime_ns))

    def test_failed_staged_verification_preserves_installed_binary(self):
        with tempfile.TemporaryDirectory() as folder:
            cache = Path(folder)
            archive = cache / "test.zip"
            with zipfile.ZipFile(archive, "w") as source:
                source.writestr("engine", b"new bytes")
            destination = cache / "install"
            destination.mkdir()
            binary = destination / "engine"
            binary.write_bytes(b"old executable")
            before = binary.stat()
            with patch.object(bootstrap, "CACHE", cache), patch.object(bootstrap, "verify_engine", side_effect=RuntimeError("wrong build")):
                with self.assertRaises(RuntimeError):
                    bootstrap.install_editor(archive, destination, binary)
            self.assertEqual(binary.read_bytes(), b"old executable")
            self.assertEqual(binary.stat().st_ino, before.st_ino)

    def test_changed_engine_companion_requires_atomic_reinstall(self):
        with tempfile.TemporaryDirectory() as folder:
            cache = Path(folder)
            archive = cache / "test.zip"
            with zipfile.ZipFile(archive, "w") as source:
                source.writestr("engine_console.exe", b"console launcher")
                source.writestr("engine.exe", b"real engine")
            destination = cache / "install"
            binary = destination / "engine_console.exe"
            with patch.object(bootstrap, "CACHE", cache), patch.object(bootstrap, "verify_engine"):
                self.assertTrue(bootstrap.install_editor(archive, destination, binary))
                (destination / "engine.exe").write_bytes(b"wrong engine")
                self.assertTrue(bootstrap.install_editor(archive, destination, binary))
                self.assertEqual((destination / "engine.exe").read_bytes(), b"real engine")

if __name__ == "__main__":
    unittest.main()
