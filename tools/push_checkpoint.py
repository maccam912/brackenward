#!/usr/bin/env python3
"""Atomically publish committed main and its exact development tag. Never force."""
from pathlib import Path
import subprocess
import sys


class CheckpointError(RuntimeError):
    pass


def git(root, *args):
    result = subprocess.run(["git", *args], cwd=root, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        raise CheckpointError(result.stderr.strip() or "Git operation failed")
    return result.stdout.strip()


def publish(root):
    if git(root, "branch", "--show-current") != "main": raise CheckpointError("Publish from main after committing the reviewed checkpoint")
    if git(root, "status", "--porcelain"): raise CheckpointError("Commit or preserve unfinished work before publishing the checkpoint")
    commit = git(root, "rev-parse", "HEAD")
    tag = "dev-" + commit[:12]
    git(root, "fetch", "--no-tags", "origin", "main")
    ancestor = subprocess.run(["git", "merge-base", "--is-ancestor", "origin/main", commit], cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if ancestor.returncode: raise CheckpointError("Remote main has new work; integrate it before publishing. Nothing was forced")
    remote = git(root, "ls-remote", "origin", "refs/heads/main", "refs/tags/" + tag)
    refs = {line.split()[1]: line.split()[0] for line in remote.splitlines()}
    if refs.get("refs/tags/" + tag, commit) != commit: raise CheckpointError("Existing remote development tag differs from this exact commit; retained unchanged")
    local = subprocess.run(["git", "rev-parse", "--verify", "refs/tags/" + tag], cwd=root, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if local.returncode == 0 and local.stdout.strip() != commit: raise CheckpointError("Existing local development tag differs from this exact commit; retained unchanged")
    if git(root, "rev-parse", "HEAD") != commit or git(root, "status", "--porcelain"): raise CheckpointError("Checkpoint changed during validation; nothing was pushed")
    if local.returncode: git(root, "tag", tag, commit)
    git(root, "push", "--atomic", "origin", commit + ":refs/heads/main", "refs/tags/" + tag + ":refs/tags/" + tag)
    return {"commit": commit, "tag": tag}


def main():
    try:
        result = publish(Path(__file__).resolve().parents[1])
    except CheckpointError as error:
        print(str(error), file=sys.stderr);raise SystemExit(1)
    print("Published main and " + result["tag"] + " at " + result["commit"])


if __name__ == "__main__":
    main()
