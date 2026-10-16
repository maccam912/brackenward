# Brackenward

A woodland colony simulation built from [DESIGN.md](DESIGN.md). The current runnable checkpoint is **M7 in progress: release art, accessibility and polish**, version `0.7.123-m7`. Four residents gather, haul, cook, build, eat, and sleep using real inventories, reservations and work progress. Automated full Charter campaigns pass on all three Standard sites and Pine Hearthside under their pinned content/generator versions. Physical Android testing is deferred to the user and does not block further implementation.

![Current colony artwork](reports/visual-polish-final-colony.png)

Native daylight view of a recorded colony. [Android screenshots and verification](reports/ANDROID_VISUAL_REVIEW.md) show the exported phone layouts; [preview provenance](reports/visual-polish-final-evidence.json) records this capture.

Use Godot **4.7.2 Standard**, Compatibility renderer. The editor and export-template archives are SHA-512 pinned in `toolchain.lock.json`. Git LFS is required for fonts and raster/binary media.

```sh
git lfs install
git lfs pull
python3 tools/bootstrap.py
tools/godot.sh
```

Bootstrap supports macOS universal, Linux x86-64 and Windows x86-64. Set `BRACKENWARD_GODOT` to its printed executable when the shell launcher cannot locate it. `python tools/bootstrap.py --editor-only` installs only the verified native editor for replay checks. Repeated installs preserve an already verified executable.

Begin opens a paused map. Tap a traveler, use Follow, drag to pan, or use the camera buttons. Work offers resource gathering orders. Build offers stockpiles, turnip fields and initial structures; tap a tree or plant for a gathering card. Placement keeps your current camera position and zoom. Build -> Paint stockpile opens a one-tile preview at the visible center. Tap to start a fresh single tile (including doors and walls), or drag a line/rectangle; nudge it, then Confirm. Confirmation immediately shows a persistent hatched order, including while paused, and allows another placement without advancing time. It restores your speed from before opening the tool; paused entry stays paused. Workers carry at most eight units and fetch inputs before work; canceling unfinished orders returns unconsumed supplies. Pause / 1x / 2x / 4x control time; safe quiet sleep automatically accelerates to 12x until someone wakes or needs attention. Menu offers verified local save/load and document import/export; Menu > Manage saves deletes campaigns or named saves. Resident and bed cards offer assignment and unassignment, showing safety, ownership and actual rest rates. Assignment reserves a bed; residents still walk there to sleep and wake when rested. Tired residents top up below 650 fullness when reachable food is available. Actual sleep halves hunger drain; routine food trips wait until rest 700, with fullness 100 or lower allowing an earlier meal. Missing top-up supplies never delay otherwise-needed sleep. Closing an ordinary panel restores the speed from before it opened; paused entry stays paused. Backgrounding freezes time and cancels touches; returning stays paused. Zoom spans 2–64 dp per tile.

Desktop shortcuts: WASD/arrows pan; Space toggles pause; 1/2/3 select speeds; B/J/P/V/L open Build/Work/People/Valley/Journal; Escape closes the top interaction, then opens Menu. Zoom uses the wheel or buttons. Menu > Settings offers keyboard rebinding, accessibility preferences and independent sound controls.

```sh
python3 tools/checked_godot.py -- --headless --editor --import
python3 tools/validate_content.py
python3 tools/check_suite.py unit
python3 tools/check_suite.py integration
python3 tools/check_suite.py colony
python3 tools/check_suite.py survival
python3 tools/check_suite.py persistence
python3 tools/check_suite.py seasons
python3 tools/check_suite.py people
python3 tools/check_suite.py production
python3 tools/check_suite.py care
python3 tools/check_suite.py generation
python3 tools/check_suite.py tutorial_flow --site meadow_reach
python3 tools/check_suite.py tutorial_flow --site pine_shelf
python3 tools/check_suite.py tutorial_flow --site reed_bend
python3 tools/check_suite.py ui
```

JUnit and native screenshots go in ignored `reports/` files. The UI suite resizes real Controls, injects touch events, and checks safe insets/text scales. It supplements physical testing. Acceptance IDs in test names refer only to the tested prototype subset, not the full release cases in the design.

Android development: JDK 17, SDK 36, build-tools 36.1.0, NDK 29.0.14206865, and CMake 3.10.2.4988404. Gradle 8.11.1 / AGP 8.6.1 / Kotlin 2.1.21 match the pinned template. Set `JAVA_HOME` and `ANDROID_HOME` if their default local paths differ, then run `tools/build_android.sh`. Bootstrap creates an isolated editor/settings directory for these builds, preserving the installed editor settings. Retain that directory to preserve the debug signing identity across APK updates. Checked main-branch commits publish downloadable APK prereleases at https://github.com/maccam912/brackenward/releases. CI uses the retained development identity from a repository Actions secret, so its APKs can update one another. Production signing is a later gate. The original Kotlin v2 plugin uses Android's document picker, temporary content-URI grants, request IDs, byte limits and verified writes. It requests no broad storage permission. Generated AARs/APKs and Gradle files are ignored and reproducible from source.

Development releases are named **Build N (development)** and tagged `v0.0.N-dev`; higher numbers are newer. Download `brackenward-build-000NNN.apk` from the highest numbered release. The build number is 100 plus the full Git commit count, so every new main commit increases it, even when checks finish out of order. Retries reuse the same number and release. This sequence also supplies Android's update version code and the build suffix in its version name; the game's milestone version remains separate. CI retains the exact commit and workflow run in `build.json`. Numbers may skip when intermediate commits do not publish an APK.

CI runs Android/content checks, graphical UI tests, desktop exports and five balanced simulation jobs concurrently. Each job uses its own checkout, user data and evidence artifacts; all core jobs must pass before publishing the development APK. Verified engine/template downloads and Gradle dependencies are cached between runs. The four native replay jobs and the larger map sweep run after the publication attempt, with their own success/failure results and evidence. Download once **Publish development APK** succeeds; the overall workflow can still be running or later fail on extended validation. These checks also run on pull requests, where publication is skipped, and after a build/publication failure unless the run is cancelled. Release notes link to their live status; publication alone does not certify cross-platform replay or physical-phone testing.

After validating and committing main, run `python3 tools/push_checkpoint.py` to push the commit and its exact numbered development tag atomically. The helper requires a clean main checkout and full Git history, preserves divergent remote work and conflicting tags, and never forces an update. CI checks the tag against the tested source before publishing; the tag alone is not a checked APK release. Reserving it with the push prevents a later workflow change from blocking an older successful run's release. Existing hash-tagged releases retain their original download links.

Colony development saves live in private `user://campaigns/slot-N`, keep three verified immutable generations, and preserve movement, needs, reservations, held inputs, work, and receipts. The `brackenward-development-colony` version 5 format is distinct from retained M0 touch fixtures in `user://m0`. Earlier M1/M2 colonies in `user://m1` are recovered into slot 1 without deleting their original files. Commands and complete-tick markers are also journaled every 1 foreground second and restored from exact parent-linked state deltas after recovery (format-3/4 full-state markers and older frozen M1/M2 command replay remain supported); torn final frames are ignored, earlier checksum failures preserve evidence and fall back to an earlier generation. Checkpoints rotate to a verified immutable snapshot before exceeding the journal frame or total-size bounds. Five campaign slots and ten named snapshots per campaign are available in Menu. Imports choose an empty slot or confirm replacement; the previous campaign is archived only after the staged import verifies. A write failure pauses the colony and offers Retry, Export, and explicit Continue without saving.

Existing colonies retain their authored maps. New campaigns offer Meadow Reach, Pine Shelf and Reed Bend with a displayed unsigned 32-bit seed and Standard/Hearthside choice. Deterministic generation saves all terrain, fertility, resources, habitat positions and transforms, validates safe home/field/water/resource/boundary access, retries invalid maps and retains a checked fallback. Generation runs off the UI thread while time stays paused. M2 adds crop preparation/sowing/growth/harvest, spoilage, regrowing wild plants, rooms, heating, morale causes, leisure, work shifts, food forecasts and M1 save migration. Work exposes rectangle resource orders, all preferences, shifts, priorities, pinned jobs and storage filters. Choose Gather wood, drag around trees, and Confirm; eligible Gathering workers finish all marked trees without further clicks. Fonts scale sharply on high-density screens, directional arrows avoid clipped labels, and the default UI uses compact 16 dp text while retaining 48 dp touch targets. Last campaign, camera, text size and handedness survive restart as device preferences. M3 adds saved three-day forecasts, season weather, exact wet/snow movement, forecast flood overlays, protected storage, one-time flood losses, well irrigation and early harvest. Residents converse during leisure, form friendships, retain morale memories, mediate disagreements and offer optional four-day personal requests. People cards explain morale and relationships; Work links to each resident’s preferences, with multiple edits queued while paused. Android emulator abrupt termination recovered the exact durable tick and last active campaign; physical storage/performance validation remains outstanding. All 28 items, 34 structures, 13 recipes, six crops and 12 research projects are defined. Tap a built workstation to create Repeat or Maintain orders with ingredient filters and priority, or suspend it. Work -> Research selects a project and queues up to three; two desks can contribute, progress survives switches, and research opens recipes/buildings/crops. Physical ingredients are fetched and consumed only at batch completion; spoilage retains partial work and accepts allowed replacements. Initial equipment is now included in conservation checks. M1/M2/M3 saves migrate forward with original files retained. Injuries now produce visible rescue, strongest-available treatment, feeding, resting recovery and explicit Care Off overrides. Standard deaths drop real equipment, retain relationships/history, create markable burials and declining grief; Hearthside instead wakes a resident at 40 health after two days. New downings pause immediately, and a colony with no living residents ends in a save/restart epilogue. Schema revision 20 migrates earlier campaigns additively. New terrain includes clay/ore and playable river bridges; crop growth reads real soil fertility, movement respects height transitions and forecast floods use the saved river. Forest zones preserve a rounded-up 50/75/100% reserve and automatically replant cleared tree sites. Replanting takes real work, saplings mature over eight non-winter days, and clearing a sapling gives no wood. Fishing piers require two land and two river tiles, produce two physical fish per 12 WU batch, and share an eight-per-pier/sixteen-per-river daily cap reset at 06:00. Six hares, four deer, two boars and four geese now forage, flee and consume at most one crop unit per day. Hunt cards show weapon reach, named hunter choice, boar escorts and a separate Solo hunt confirmation. Attacks resolve together, armor and retreat are explicit, and kills leave two-day carcasses requiring real butchering and hauling. Dawn replacement is capped and saves retain each animal stream. Older campaigns gain wildlife on their saved geography after validation. Husbandry now supports enclosed pens, six-slot barns, real 24-unit feed/output buffers, handler-led gate passage, dawn feeding, 4 WU product collection, bounded breeding, juvenile maturation and named slaughter confirmation. Hens and pack goats can be bought from merchants after Husbandry, with actual pen/barn capacity reserved and handler-led arrivals. Walls/palisades default to hollow rectangle outlines, with a Shape button for lines; fences use lines and floors use rectangles. A door placed over a wall replaces its blueprint or queues demolition before rebuilding. Tap a stump and choose Remove stump for a real 4 WU removal task. Hungry residents prioritize food work over construction, tired residents seek assigned beds even at critical rest, and Dawn/Day/Dusk/Night are visible on the clock with a stronger night tint; previews show exact costs and valid/omitted cell counts, with reasons retained on red cells. The four-bed lodge preset creates its 28 normal blueprints at W73 F8/206 WU, finishing beds and door before enclosure. Construction admits two workers at distinct positions, sharing escrow/progress and awarding completed WU once. People -> Equipment now fetches and equips tools, weapons, cloaks and vests through physical 2 WU wearer jobs, returning old gear without duplicating or consuming it. Slot policies default to replacements on and upgrades off; forged-tool upgrades require an explicit choice, and removing a slot stops automatic replacement. Maintenance supports proportional repairs, half-cost demolition, rebuilding ruins and physical furniture movement at full original WU with retained material bundles, health, identity and settings. The cart can be pushed for 20 WU with its stored goods aboard. Rebuilt barns reassign shelter; catalog buildings provide their built-in roofs. Recipe workers collect multiple reserved items in an eight-unit load. Newcomer offers begin on day four and recur every four days, show full skills/traits, check a free reachable sleeping place and two food days for the enlarged household, and expire without penalty after two days. Accepted residents physically walk from the boundary, wear their own toolkit/cloak and deposit four rations once at the cart. Saves, selection, work, care, relationships and equipment support up to twenty residents with arbitrary stable IDs. Valley and the cart offer merchant trades, community relations and deliveries. Merchants announce a day ahead, walk from a safe boundary, stay twenty-four hours after reaching the cart, and queue later visits. Payment and merchant goods reserve together, workers carry payment in eight-unit loads, and a saved final receipt releases bought goods at the cart. Cancellations before payment commit free supplies; standard community deliveries wait without a hidden deadline and have an eight-day cooldown. Per-unit prices use exact rounded reputation tiers and explicitly show any surplus gift. The seeded regional map now exposes all eight sites and three communities. Expeditions require two to four healthy residents, two left home, real cart packing, a separate Depart action, rations/feed/capacity previews and fixed departure readiness. Residents walk to the boundary, retain needs/equipment off-map, pause for a stable midpoint choice and review exact rewards and bounded injuries before committing. Recall uses elapsed route time; medicine is consumed only on injury, contract payments only on successful/partial outcomes, and leftovers permit one pickup without new loot. Return walks back, restores home workers, and unloads in physical eight-unit trips; full stores explain the blocked unload. Community visits deliver contracts without creating merchant stock. Saves retain every phase and cargo record. Industrial fire now damages real structures/stacks, propagates to orthogonally touching fuel in stable order, honors rain, and preserves surviving goods on destruction. Available residents fetch abstract water, visibly carry it, and extinguish with retained partial effort; critical firefighting overrides ordinary Care Off, as emergency rescue does. Burning work/storage is unavailable, fire opens a response panel, and unsafe operating stations show prevention rules. Work and fetched-water completion now commit after simultaneous combat damage, so downed workers cannot finish a transaction. The director now shows public pressure, considers raids/unsafe industrial fires at dawn from day eight, respects seventy-two-hour start spacing, forty-eight-hour recovery and already shown extreme weather, and keeps Hearthside free of scheduled raids. Raid composition is fixed at warning, arrives through a validated boundary, seeks four physical goods per member and stops after six hours. Squad cards support map rallies, focus, explicit Stand fast, automatic retreat, shelter, passage and stand down. Supplying eight times the incident budget in barter value reserves and physically delivers goods under a ceasefire, with visible failure grace. Downed attackers remain stable and neutral, drop stolen goods, recover after twelve hours and may receive one reputation reward for voluntary care. Visitors now offer storytelling, cart repairs, surplus harvest exchanges and shared study. Accepting reserves payment, real workers deliver and work at the required cart or desk, and visitors physically enter and leave. Storytelling begins only at the table and needs a continuous half-hour of shared leisure. Offers, deadlines, attendance and one-time receipts survive save/load. Ceasefires stop both sides, retreating actors retain their current movement edge, Guard experience has its specified daily cap, and simultaneous fire/combat resolves before completed work. Major weather/incident spacing uses exact onset times. Full art/audio and remaining release accessibility/performance work are still planned. All five Charter stages, physical communal suppers, the final ceremony, factual epilogue and Continue settlement are playable. The causal Chronicle preserves event evidence and daily story chains. First steps now guide seven real opening actions, with later lessons for winter, injuries, research and expeditions. The ? button reopens or replays lessons; Skip does not mark a lesson complete. The food forecast can remain pinned on the map. Tutorial progress belongs to each local campaign and does not alter simulation state.

See [reports/STATUS.md](reports/STATUS.md) for actual gates and [reports/ANDROID_TEST.md](reports/ANDROID_TEST.md) for the phone task battery. Development APK publishing is authorized. Production signing, store publication, and telemetry remain later work.

Ordinary-play campaign evidence can be generated without material grants or direct state edits:

```sh
tools/godot.sh --headless --script tools/simulate.gd -- --scenario vegetarian_charter --seed 104729 --site meadow_reach --mode Standard --days 48 --report reports/charter.json
python3 tools/replay_campaign.py --report reports/replay-local.json
```

The scenario harness saves verified daily checkpoints, original/final snapshots and its public command trace. Add `--resume reports/charter-latest.json` with a different output report to continue that exact save; `--days` then means additional days. Policy success is measured separately from simulation invariants. Replay uses frozen commands, canonical hashes at ticks 7,200 and 72,000, and continuation from a committed foreign-host save. CI runs it on Windows, Linux, Apple Silicon and Intel Mac; a workflow configuration alone is not a passing platform result.

The first M7 art checkpoint adds original animated adult citizens, matching portraits, independent cosmetic choices in People > Appearance, and labeled trait pictograms. The indexed art uses one shared atlas and per-citizen palette materials. Original authoring sources and inspected contact sheets are retained.

Menu > Settings contains reduced motion, high-contrast selection, pause-on-inspect, 30/60 FPS graphics presets, individual automatic pauses and keyboard rebinding (including modifier shortcuts). Device preferences upgrade separately from campaign saves. Automatic warnings remain visible when their pause is disabled; a departure card shows its remaining game time and recovery threshold.

Original day/night/tension music and environmental loops now accompany licensed interface/work sounds. Settings offers Master, Music, Effects and Interface volumes; optional Android vibration starts off. Backgrounding stops sound and resume discards old cues. Essential warnings retain their visible notices when muted. The pinned thirty-run first-Winter matrix passes on all sites; physical audio/performance and human listening gates remain separate.

Wildlife and livestock now use an original shared atlas with four facings, idle/walk/eat/downed states and boar charge. Visitors, merchants and attackers reuse the adult character system; weapons, travel gear and threat/neutral markers distinguish them. Taps follow their visible movement positions.

Menu > Performance report previews local CPU timings and frame gaps by play speed. After a stutter, open it to view, copy or export a bounded JSON report. Reports include device/build and map seed, omit names/saves/document paths, and stay local until you choose to share them. Reset starts a fresh measurement; background time and earlier campaigns are excluded.

The woodland environment uses a shared atlas for all 34 structures in four rotations, crop stages, deposits, trees and visibly taller supply piles. Actual jobs, fuel and seasons drive the visible states. Map and seed > Rooms overlay reveals enclosed interiors; selecting an occupant also fades its roof and overlapping trees. Battery and reduced motion stop decorative water/weather animation. These effects do not change simulation rules. Source components, original authoring code and exact license evidence are retained.

Build imports and exports reject Godot script/engine errors even if the engine returns zero. Native desktop package metadata follows the project version and Android build number; CI adds exact commit provenance. Exported startup checks run from an empty directory and require the application's graceful, audio-drained exit marker.

The synthetic crowded-colony fixture is separate from ordinary-play evidence. It validates and round-trips through the actual save codec. The foreground profiler accepts speed, close/far camera, graphics quality and up to 1,800 measured wall-clock seconds, records actual load at each end, and checks that runtime/media/profiling sources stayed unchanged. See [reports/STRESS_EVIDENCE.md](reports/STRESS_EVIDENCE.md) for measured results and remaining gates.

Large painted orders retain every tile while at most 512 tasks execute. Waiting targets keep their materials and progress; Work shows their queued count and pages through 32 orders at a time. Emergency, pinned and usable work receive capacity first. Content `colony-v3` / schema 23 imports earlier campaigns without discarding their orders; older builds cannot open new saves. The crowded-colony timing gate still fails and remains under active optimization.

Typography uses only the two approved fonts, with explicit heading-to-body fallback and checked glyph coverage. Name/note forms keep invalid input open with a visible explanation; corrected text follows the normal command or snapshot flow. Historical text is retained exactly in saves while its displayed punctuation uses available glyphs.


Long campaign checks use a clean frozen checkout and a new empty report directory:
`python3 tools/charter_sweep.py --source CLEAN_CHECKOUT --report-dir NEW_DIRECTORY`.
It runs all three Standard sites plus Pine Hearthside through ninety-six days,
retains failed runs and checks ceremony, Continue and later play. Use `--audit`
with the same source/report directory to recheck saved evidence. Results and
known planner failures are recorded in reports/STATUS.md; a running sweep is not
a completed release gate.


Food-shortage recovery now keeps an assigned task or sleep when no reachable
allowed food is available, so a hungry cook can finish making a meal. Starving
residents temporarily yield defense while retaining their draft order. Content v4
keeps the existing campaign schema and preserves old acknowledged state and raw
migration backups; it changes scheduling during subsequent play.


Native longevity checks use a clean frozen checkout and a new empty output directory:
`python3 tools/run_soak.py --source CLEAN_CHECKOUT --snapshot INPUT.brackenward --report-dir NEW_DIRECTORY`.
Defaults are thirty measured minutes at 2x after sixty warmup seconds. The probe
uses the real session, saving and lifecycle policy, bounded diagnostics and minute
samples of engine heap/RSS. It preserves partial failures and verifies the final
snapshot, unchanged source/input and logical time. Use `--audit` with the same
source/directory to recheck artifacts. A short `--seconds 3 --warmup 1
--sample-seconds 1` run is a harness smoke test; it cannot become a thirty-minute
certificate. These source proxies do not replace physical Android PSS, thermal,
battery, all-alert or human checks.

`tools/profile_creation.gd` compares repeated creation reads with retained full
scans at one fixed tick. It is a microbenchmark, separate from actual campaign
continuation and foreground-frame measurements.


Exported Android touch evidence, the fresh-campaign paused autosave repair and
save-update/deletion checks are recorded in
[reports/ANDROID_TOUCH_EVIDENCE.md](reports/ANDROID_TOUCH_EVIDENCE.md).
For a private initial revision-2 boundary save, compare the entire decoded world
with its inspected expectation without advancing play or rewriting the save:
`tools/godot.sh --headless --script tools/check_initial_golden_save.gd -- INITIAL_SNAPSHOT NEW_REPORT`.
Only the random campaign ID is normalized in the private decoded copy. A failed
comparison leaves existing expectations and input bytes intact.


`merchant_economy` is a 24-day ordinary-play scenario: two scheduled cloth
purchases supply real sewing and a three-cloak community delivery, with no local
cloth production or material grants. From a clean frozen checkout run
`python3 tools/merchant_sweep.py --source CLEAN_CHECKOUT --report-dir NEW_DIRECTORY`;
use `--audit` with the same source/directory after completion. Its four-case
release result stays separate from bounded policy tests.
