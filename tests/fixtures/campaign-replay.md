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

13 October physical table dining: meals now include a real walk to an available
table seat within 12 safe path tiles of pickup. This intentionally changes work
timing; the previous fixed schedule attempted its later action before Farming
was complete. A fresh ordinary ten-day `first_week` run passed with 62 accepted
public commands and exact final snapshot round trip. All 62 commands before
tick 72,000 were captured with their original times and order; verification
does not run the adaptive policy. Input provenance records the source report
digest and canonical hash. Both expected receipts and prerequisites stay strict.

The new canonical hashes are
`7ca1d514105bbdffce924e17ab43b5eeb87d3c255e5057de5edeec95acb63a20`
at 7,200 and
`70095612774548710d434881d0902802d86ed71aefb33c6c4e98dd41fa474b65`
at 72,000. The current foreign save SHA-256 is
`ed04e21b0da3c5076fc66da1e27246257f6dbdf77fd9bbfaf00bc8b9bec318f9`.
The unchanged earlier foreign bytes remain in
`m6-before-table-dining-7200.brackenward`; scheduler tests verify its original
acknowledged state and exact continued simulation under the current rules.

14 October bed-assignment command: schema 21 declares support for the additive
`assign_bed` command in pending saves. Migration changes only the revision
header. The same 62 frozen commands, input bytes, catalogs and foreign schema-20
snapshot are retained. Both recorded checkpoint payloads, after changing only
`schema_revision` back to 20, reproduce their previous complete canonical
hashes above. No gameplay fields or accepted receipts were rebased. The new
schema-21 hashes are
`3f6f39218476c9e1b023487ad55370f0ae5aa1b8716404d9c91b45ee2638700f`
at 7,200 and
`a3acab0583d26caf61996e8f2680245f30bfda976808c17be8fda31b9867441f`
at 72,000. `beds-metadata-rebaseline.json` records the comparison; the ordinary
non-recording replay must still pass both checkpoints and foreign continuation.


14 October content v6 rest pacing: current replay uses separate
`campaign-replay-v6-input.json`, `campaign-replay-v6-golden.json` and
`campaign-replay-v6-7200.brackenward`. All older inputs, goldens and saves remain
immutable. The same 62 public actions/times now queue nine subsequent research
projects instead of replacing unfinished work; the budget-2 raid target is the
actually observed 3976, with the same 16 wood. Expected receipts remain accepted.
The idle-queue bug found during recording is fixed through real scheduling.
Recording plus separate verification pass 234 invariant checks and current-rule
continuation. The new save is locally produced; matching native CI imports on
other hosts remain a separate gate. The earlier original foreign save keeps SHA
ed04e21b0da3c5076fc66da1e27246257f6dbdf77fd9bbfaf00bc8b9bec318f9.

Current v6 canonical hashes: initial
c40f4e6b8f2fffc3b1806cef288ec9ed21c0147745adf419f1a453ce9a65a7b7;
7,200 50bb80a8c127473adf03f8882bef3f0ac6b09844c42c14bc0cce3816cf7b920e;
72,000 b996c5f4e4d953d234b3d967fc931582dbd426fc527e410e6dc92af5bee707d6.
The new save SHA is dbc248d219c6f2ee783ed802ea7e7a6a786db09f916064229b39095fd2401621.
Content-v3/v4/v5 acknowledgements and old schema-22-compatible endpoints retain
every acknowledged field after header normalization; the old future trace is
not claimed equal after intentional rest-rule changes. Separate v6 replay
goldens constrain the new simulation instead.


15 October content v8 hunger checkpoints and four-day turnips: current replay
uses the separate `content8/` input, golden and locally produced tick-7200 save.
All 62 public actions, execution times, payment quantities and accepted
receipts remain. The actually announced budget-2 raid is 3850 instead of 3976;
the retained diagnostic at tick 52201 supplies that observed target, and input
provenance records its digest. Every earlier fixture remains unchanged. The
first unreviewed attempt is retained in reports and is not the current golden.
Recording and independent non-recording verification must both pass. Native
CI on other hosts remains separate from this local baseline and continuation.
Frozen `content7-work/` snapshots and a 600-tick journal verify preservation of
acknowledged v7 jobs/cargo/needs/history before v8 scheduling begins.
