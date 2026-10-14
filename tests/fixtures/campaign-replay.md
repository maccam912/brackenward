# Native campaign replay fixture

`campaign-replay-input.json` freezes ordinary public player commands from a
Standard Meadow Reach campaign with seed 104729. The trace begins at the normal
tick 1800 start. Every recorded command must receive `accepted`; the replay does
not inject resources, complete work, force weather, or run an adaptive policy.

`campaign-replay-golden.json` records the canonical hashes at ticks 7200 and
72000, exact input bytes, catalog hash, and save schema. The accompanying
`campaign-replay-7200.brackenward` is a snapshot made by the baseline host. Every
native verification loads that same committed snapshot at tick 7200 and runs
the remaining commands in parallel with its fresh world. Both worlds must
match at tick 72000, with invariants checked every 300 ticks and immediate
snapshot round trips at both checkpoints.

Run from the repository root with the pinned editor:

```sh
python tools/bootstrap.py --editor-only
python tools/replay_campaign.py --report reports/replay-local.json
python tools/native_smoke.py --report reports/replay-local-native-smoke.json
```

On a Linux CI host without a display, run the graphical smoke under `xvfb-run
-a`. The smoke uses an actual compatibility renderer and rejects a headless
display. Replay evidence and graphical launch evidence are separate reports.

After an intentional deterministic gameplay change, review the accepted command
trace and explicitly regenerate the golden and tick 7200 save:

```sh
python tools/replay_campaign.py --record-golden --report reports/replay-local.json
python tools/replay_campaign.py --report reports/replay-local-verified.json
```

Do not replace expected accepted receipts with rejections to accommodate a
changed entity ID. Recapture the input from ordinary play when the original
actions are no longer valid. Commit input, golden and save together. A replay
failure must block publishing; CI never regenerates the baseline.

The CI matrix runs the pinned native editor on macOS ARM64 and x86-64, Linux
x86-64, and Windows x86-64. These source-project checks do not prove exported
package startup, installation/upgrade behavior, physical Android execution, or
the remaining Android portion of DESIGN SAVE10.


13 October shared-tile eating correction: ordinary meals can share the cart with
resting residents. Removing failed meal retries changes later runtime IDs. A
separate ordinary-command recapture accepted all 64 actions and passed 234
invariant checkpoints. Only command 60's raid target changes from 4000 to the
actual announced budget-2 raid 3993; times, payment quantities and all accepted
receipts remain fixed. The tick-72,000 golden is now
`68b17b7d2877566ab5e3318216e5236d258c441cc0de3f3dc8f2d8806927c70f`.
The tick-7,200 canonical state and original foreign snapshot bytes remain
unchanged (`9d1636a4bc1b2764b49b85578c8aff224f44e6922205b2cad1f15dd7b234aa4a`).
A separate non-recording replay verifies both checkpoints and continuation from
that retained snapshot. Future receipt failures retain a diagnostic snapshot.
