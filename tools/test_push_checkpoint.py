#!/usr/bin/env python3
"""Real isolated Git remotes prove tag identity, idempotence and no forced loss."""
from pathlib import Path
import subprocess
import tempfile
import unittest

from push_checkpoint import CheckpointError, git, publish
from stamp_build import development_build, development_tag


class CheckpointTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.parent = Path(self.temp.name)
        self.remote = self.parent / "remote.git";self.root = self.parent / "work"
        self.remote.mkdir();self.root.mkdir()
        git(self.remote, "init", "--bare", "--initial-branch=main")
        git(self.root, "init", "--initial-branch=main")
        self.identity(self.root)
        git(self.root, "remote", "add", "origin", str(self.remote))
        self.commit("initial")
        git(self.root, "push", "origin", "main")

    @staticmethod
    def identity(root):
        git(root, "config", "user.name", "Checkpoint test")
        git(root, "config", "user.email", "checkpoint@example.invalid")
        git(root, "config", "commit.gpgsign", "false")
        git(root, "config", "tag.gpgsign", "false")

    def commit(self, text, root=None):
        root = self.root if root is None else root
        (root / "content.txt").write_text(text)
        git(root, "add", "content.txt");git(root, "commit", "-m", text)
        return git(root, "rev-parse", "HEAD")

    def test_atomic_main_and_tag_and_idempotent_retry(self):
        commit = self.commit("ready")
        result = publish(self.root)
        self.assertEqual(result["commit"], commit)
        self.assertEqual(result["tag"], "v0.0.102-dev")
        self.assertEqual(git(self.remote, "rev-parse", "refs/heads/main"), commit)
        self.assertEqual(git(self.remote, "rev-parse", "refs/tags/" + result["tag"]), commit)
        self.assertEqual(publish(self.root), result)

    def test_next_commit_increments_the_reserved_build(self):
        first = publish(self.root)
        self.commit("next build")
        second = publish(self.root)
        self.assertEqual(first["tag"], "v0.0.101-dev")
        self.assertEqual(second["tag"], "v0.0.102-dev")
        self.assertEqual(git(self.remote, "rev-parse", first["tag"]), first["commit"])
        self.assertEqual(development_build(self.root, first["commit"]), 101)

    def test_shallow_clone_cannot_reserve_reused_build_numbers(self):
        self.commit("history")
        publish(self.root)
        shallow = self.parent / "shallow"
        subprocess.run(["git", "clone", "--depth", "1", self.remote.as_uri(), str(shallow)],
                       check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.identity(shallow)
        self.commit("new shallow checkpoint", shallow)
        with self.assertRaisesRegex(CheckpointError, "full Git history"):
            publish(shallow)
        self.assertEqual(git(self.remote, "rev-parse", "main"), git(self.root, "rev-parse", "HEAD"))

    def test_dirty_work_does_not_publish(self):
        original = git(self.remote, "rev-parse", "main")
        commit = self.commit("unfinished checkpoint")
        (self.root / "untracked.txt").write_text("unfinished")
        with self.assertRaises(CheckpointError): publish(self.root)
        self.assertEqual(git(self.remote, "rev-parse", "main"), original)
        self.assertEqual(git(self.remote, "tag", "--list"), "")
        self.assertNotEqual(original, commit)

    def test_remote_divergence_is_preserved(self):
        other = self.parent / "other"
        subprocess.run(["git", "clone", str(self.remote), str(other)], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.identity(other)
        remote_commit = self.commit("other developer", other)
        git(other, "push", "origin", "main")
        self.commit("our distinct work")
        with self.assertRaises(CheckpointError): publish(self.root)
        self.assertEqual(git(self.remote, "rev-parse", "main"), remote_commit)
        self.assertEqual(git(self.remote, "tag", "--list"), "")

    def test_wrong_existing_tag_cannot_be_overwritten(self):
        old = git(self.root, "rev-parse", "HEAD")
        commit = self.commit("new checkpoint")
        tag = development_tag(development_build(self.root, commit))
        git(self.root, "tag", tag, old);git(self.root, "push", "origin", "refs/tags/" + tag)
        with self.assertRaises(CheckpointError): publish(self.root)
        self.assertEqual(git(self.remote, "rev-parse", "main"), old)
        self.assertEqual(git(self.remote, "rev-parse", "refs/tags/" + tag), old)

    def test_detached_checkout_cannot_publish(self):
        git(self.root, "checkout", "--detach")
        with self.assertRaises(CheckpointError): publish(self.root)
        self.assertEqual(git(self.remote, "tag", "--list"), "")


if __name__ == "__main__":
    unittest.main()
