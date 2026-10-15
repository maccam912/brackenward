# Exported Android touch and paused-save evidence

Local debug build 0.7.49-m7, Android version code 88, content colony-v6,
schema 23/envelope 5/settings 6/generator 2. Tested on the task-owned Android 35
arm64 Pixel 5 emulator, 1080×2340 at density 440, SwiftShader/ANGLE. This is
exported-app execution and real ADB touch input; it does not certify physical
CPH2655 frame rate, PSS, thermal behavior or battery use. The original phone
report remains in [ANDROID_DEVICE_EVIDENCE.md](ANDROID_DEVICE_EVIDENCE.md).

Only task-created campaign 5 and named snapshot Touch49 were deleted. Original
campaigns 1–4 remain. Local screenshots, private save copies, action trace and
machine-readable audits are retained under the ignored `android-v48-upgrade/`.
Selected non-player-data results and evidence hashes are recorded in
[android-touch-v49-evidence.json](android-touch-v49-evidence.json).

## Confirmed interaction checks

- A fresh Standard Meadow Reach colony, seed 104729, was created through the
  setup controls. Its entire initial decoded world matches the inspected
  revision-2 expectation after normalizing only its random campaign/session ID
  in a private copy. Tick 1800, all terrain, supplies, residents and other state
  match; expected canonical SHA-256
  `0ecd4b3675fe4b910d4003cd51f599b9b0bb8d9612c42a3fa9c28b63d105bf26`.
  This was independently checked in exported builds 48 and 49. The read-only
  `check_initial_golden_save.gd` first validates the full codec and verifies that
  regenerated reference state still matches the existing inspected fixture.
  Changed-rest, advanced-tick and damaged-checksum synthetic copies are rejected;
  the original input and all checked source/golden files remain unchanged.
- After panning the camera, a door tap selected exactly one cell. Confirm showed
  the marked work immediately at 06:00 while paused. The wall tool rejected an
  overlap with that pending door, then accepted an adjacent one-cell wall without
  advancing time. A dragged 2×2 turnip field also confirmed while paused. The
  resulting three queued orders marked six cells. A static cart pixel region
  remained exactly identical across six placement screenshots, confirming the
  observed camera did not jump.
- Starting a one-cell wall from 4× paused the preview at 06:07; Confirm resumed
  4×, visible at 06:11. A later explicit Pause stopped at 06:14. Workers then
  carried actual construction inputs; this was ordinary gameplay.
- Repeated zoom-out presses displayed the entire 128×128 map, retaining a fixed
  size portrait and four-person cluster pin. After backgrounding, the saved
  campaign camera retains the minimum 2 dp/tile zoom and its panned position.
- A named Touch49 snapshot was saved. Canceling its deletion preserved its exact
  bytes; confirming the next deletion removed that named file while retaining
  both autosnapshots. Android Back returned to the map. Campaign 5 deletion
  displayed its three-file/1.29 MiB review; confirming emptied only that campaign.
  All 29 original files in campaigns 1–4 matched the earlier paused backup.

## Additional bug found and repaired

Build 48 correctly displayed confirmed work, but the first two paused orders
after fresh campaign creation were absent from its periodic on-disk save. The
initial verified snapshot still contained zero pending commands. Backgrounding
did save all three orders at tick 1800; that separate success did not repair the
missing periodic behavior.

`ColonyStore.adopt` moved the verified staging directory, then cleared the
acknowledged payload when selecting the destination slot. Its unchanged tick
masked a changed command ID. Build 49 retains the independent verified staged
payload, complete snapshot/journal metadata and rebased verified file paths.
It shares no mutable live command array. No save schema, catalog, simulation rule
or expectation hash changes.

Five persistence and four native UI checks reproduce four failures in each
suite before the fix; both suites pass after it: first/second paused commands recover exactly without ticks or manual
saves, and the first advanced tick appends a verified delta against the original
unchanged base. Persistence passes 350; native UI passes 667. The maintained
28-suite total becomes 2,658, with unaffected suites retaining their previously
recorded scope. Full historical replay passes all 62 commands, both reviewed
hashes and save continuation. Catalog/media validation and Android export pass.

In the newly exported build 49, a fresh task-created colony at tick 1800 received
one door confirmation. Without running, manual Save or backgrounding, periodic
persistence wrote snapshot 2 with exactly that one pending command. Only
`pending_commands` and `next_command_id` differ from its initial decoded world.
Snapshot SHA-256:
`a6fb12f26e36eac57f2d99a6748e428cb40b9c0a16985215d04509f6610e0962`.
The observed read followed a screenshot delay; it is not a precise latency
benchmark.

## Upgrade and CI boundaries

Before the 48→49 update the app was force-stopped and all 35 private files were
backed up. All 35 remained byte-identical after installation and before launch.
The updated app recovered all three previously background-saved pending orders
immediately while paused. The older M5→48 observation was less controlled: 32 of
33 files matched, with an older generation absent after an in-flight rotation.
Its exact cause is unproven; the failed strict preservation observation and full
backup remain retained. Do not describe that earlier update as byte-identical.

[Build 48 CI](https://github.com/maccam912/brackenward/actions/runs/38676179076)
passed all four native generation/replay jobs, each with 167 generation checks
and matching JUnit SHA-256
`b350f64793b8cd969fef7ef5485706ba6ed01450c56f3e0dcca111eb5d75b460`.
The separate prototype job exceeded its 120-second generation limit, so the
overall workflow failed and publication was skipped. Build 49 uses a bounded
360-second generation allowance and 240 seconds for the scheduler, whose prior
passing CI run took about 111 seconds. The original timeout log remains.

[Build 47 CI](https://github.com/maccam912/brackenward/actions/runs/38675588522)
and its three published assets were separately verified. Its
[APK prerelease](https://github.com/maccam912/brackenward/releases/tag/dev-5fa7e821484c)
has SHA-256
`3c22f356a2069bd8f6ff1292f18c9e51322291a983babaccd9353ad1592d9149`.
Build 49 remote CI/publication must be observed separately after its commit.


## Ordinary first-night observation

The fresh four-person colony ran through its first night using the selected 4x
speed, its original bedrolls and food, and only the accepted door/wall orders.
The second capture retains 181 frames at roughly two-second intervals. The HUD
visibly reports `12x sleep` during sampled intervals 22:17–22:47 and 04:37–04:57;
it returns to 4x with the explicit quiet-sleep CPU-limit notice. This contended
emulator run exercises the fallback and retention of the selected speed. It is
not proof of sustained 12x on a phone or an exact wake-tick visual test; the
existing automated runner checks retain their separate exact cutoff scope.

After explicit Pause and background, the unmodified endpoint fully decodes and
passes invariants at tick 10734 (Spring 2, 11:46). Both construction receipts are
accepted, both structures exist at their confirmed cells, no commands remain
pending, and all four residents are alive at health 100, awake and idle. Rest
values are 817/819/809/806, below the wake threshold after subsequent waking time.
The night did not end in fully rested residents asleep at 21:00. Endpoint input,
codec audit, screenshots, manifest and the final private backup have retained
SHA-256 values in the evidence summary. The emulator app was force-stopped after
its background save; these files and original campaigns remain recoverable.
