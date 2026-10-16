"""Exercise actual Git checkout rules used by Windows and clean-source CI."""
import hashlib
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class FixtureCheckoutTests(unittest.TestCase):
    def checkout(self, samples):
        with tempfile.TemporaryDirectory(prefix="brackenward-checkout-") as directory:
            root = Path(directory)
            def git(*args):
                return subprocess.run(["git", *args], cwd=root, check=True,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            git("init", "-q")
            (root / ".gitattributes").write_bytes((ROOT / ".gitattributes").read_bytes())
            for name, data in samples.items():
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
            git("-c", "core.autocrlf=false", "add", ".")
            for name in samples:
                (root / name).unlink()
            git("-c", "core.autocrlf=true", "checkout-index", "--all")
            return {name: (root / name).read_bytes() for name in samples}

    def test_frozen_producer_hashes_survive_windows_checkout(self):
        names = ["tools/record_content7_work_fixture.gd",
                 "tools/record_content8_priority_fixture.gd"]
        samples = {name: (ROOT / name).read_bytes() for name in names}
        for name, actual in self.checkout(samples).items():
            with self.subTest(file=name):
                self.assertEqual(hashlib.sha256(actual).digest(),
                                 hashlib.sha256(samples[name]).digest())

    def test_nested_snapshot_and_journal_bytes_are_never_normalized(self):
        samples = {"tests/fixtures/nested/a.brackenward": b"first\nsecond\n",
                   "tests/fixtures/nested/b.frames": b"header\nrecord\n"}
        self.assertEqual(self.checkout(samples), samples)

    def test_every_tracked_godot_script_has_its_tracked_uid(self):
        files = set(subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
                    .decode("utf-8").split("\0"))
        missing = sorted(name for name in files
                         if name.endswith(".gd") and name + ".uid" not in files)
        self.assertEqual(missing, [], "A fresh editor import would dirty the source")


if __name__ == "__main__":
    unittest.main()
