# Frozen v6 Winter run audit deviation

On 14 October 2026 at approximately 23:35 UTC, a diagnostic-script creation
command used the Winter checkout as its working directory instead of the main
checkout. It created an untracked, non-class script at
`tools/replay_scenario.gd`. The attempted invocation referenced the main path,
which did not yet exist; Godot rejected that invocation without running it.
The error log is retained as `winter-pine73-canary.log`.

At 23:35:37 UTC, that task-owned file was moved to the main checkout. The Winter
checkout's `git status --short` became empty and `git diff --exit-code` passed.
No tracked game, catalog, simulation or sweep-harness file changed. The running
Winter processes were already loaded, and the new script had no class_name or
editor import. Nevertheless, the checkout briefly contained an untracked file,
and completion.json correctly records source_unchanged:false. The aggregate audit exits 1 (29/30); an uninterrupted clean-checkout assertion for the whole run fails.
Retain numeric scenario/checksum data as diagnostic evidence and preserve the
normal source/completion/audit results. Do not promote this run to an unqualified
clean-source release certificate. The Pine Shelf seed-73 failure had already
completed before the file was created; its starvation report remains a real
failed scenario requiring diagnosis.

The separate native-soak checkout and the previously completed Charter audit
were not changed by this command. Corrected diagnostic invocations load the
main checkout's external script without writing into the frozen Winter tree.
