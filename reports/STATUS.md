# Implementation evidence

Checkpoint: `0.7.13-m7` in progress (campaign schema 23, device settings schema 4), content `colony-v3`, development colony envelope version 5 with a canonical catalog hash. The M0 touch fixture and its separate saves remain available to the regression suite. New campaigns use checked deterministic three-site terrain generation; older campaigns retain their saved authored geography. Version 3 adds campaign/sequence/time/generator metadata and complete-tick recovery states. Implementation was authorized on 12 October 2026. The user authorized M1 and later implementation without a physical-device gate and subsequently tried an Android build, providing UI and resource-designation feedback. Physical release gates remain pending.

| Gate | Status | Evidence / remaining work |
| --- | --- | --- |
| Godot 4.7.2 Standard / Compatibility | Pass | Exact official build `ed1daf0bf`; macOS and template archives match the official SHA-512 sums in `toolchain.lock.json` |
| Pure deterministic prototype state | Pass | 72,000-tick 1x/2x/4x trace hashes match; Park-Miller golden stream; atomic designation / duplicate-command / session rejection |
| Gestures and button alternatives | Pass, local subset | Pan, tap, long press, second finger, paint preview, explicit Confirm, double submit, zoom/camera/nudge buttons; Android emulator citizen tap verified; touch-generated mouse events filtered so they do not become a second finger; physical phone gestures still Not run |
| Portrait / landscape / large text | Pass, local subset | Real Controls at 360x640, 390x844, 640x360, 800x1280, 1280x800, 960x600; 100/125/150% text; nonzero safe insets; visible buttons >=48 logical units; native screenshots inspected |
| Prototype save recovery | Pass, local subset | Checksum/schema/bounds rejection, pending command and movement round trip, three verified immutable generations, interrupted temp ignored, damaged latest falls back |
| Background / return | Pass, local subset | Simulation stops, gestures canceled, resume paused; Android 35 emulator also preserved the 4x2 unconfirmed preview across rotation; physical task battery still Not run |
| Android storage plugin | Pass, build/unit/emulator subset | Original Kotlin v2 plugin; 4 JUnit bounded-stream tests; source builds debug/release AARs; Android 35 arm64 emulator picker export/import passed: checksum verified, tick 1861 restored to exported tick 1800; Home froze the imported state; export and import cancellations left state unchanged; same-identity APK update preserved three private saves |
| Android arm64 APK | Pass, debug/emulator subset | Current debug export passes; min SDK 29 / target 36; arm64-v8a only; merged manifest requests only optional-feature VIBRATE; earlier revisions installed and launched on Android 35 emulator (SwiftShader/ANGLE), not a physical phone |
| macOS native launch | Pass | macOS 26.6.2, Apple Silicon, Apple M5 Pro, OpenGL 4.1 Compatibility via Metal 90.5; native scene/UI runner launched |
| Physical Android installation/input/rotation/storage | User-tested subset | User installed and tried a phone build; reported oversized/clipped controls and fuzzy rendering. Smaller controls, arrow buttons, MSDF fonts and area designations are implemented and emulator-tested. Rotation/storage/performance task battery is still pending |
| Physical memory/battery/thermal baseline | Not run | Requires exact phone model, OS, GPU, brightness and measured battery/memory |
| Desktop export packages | Pass, build subset | macOS universal ZIP, Windows x86-64 EXE/PCK, Linux x86-64 executable/PCK exported locally; only macOS native launch exercised |
| Remote CI | Pass at `9ddd782`; newer revisions separate | [Observed workflow](https://github.com/maccam912/brackenward/actions/runs/38587051481) passed the full suite, all four desktop replay/startup targets, exports and publication, including actual exported Linux startup from an empty directory. The earlier `3820789` Windows startup access violation passed one retry; its original log remains retained. Physical phone certification remains pending. |
| M1 visible work loop | Pass, automated/native subset | Four actual residents, starting supplies/equipment, A* movement, atomic reservations, 8-unit hauling, build escrow, seven structures, gathering, cooking, eating and sleep; 72,000 ticks at 1x/2x/4x match; real UI orders and native screenshots inspected |
| M1 cancellation and saves | Pass | Build/cook cancellation in Fetching/Delivering/Working; haul cancellation in Fetching/Delivering; ledger conservation, duplicate receipts, mid-edge/held-input save continuation, schema/checksum rejection |
| M2 durable journal foundation | Pass, filesystem/replay subset | Commands and complete-tick markers checkpoint every 2 foreground seconds, frames verify length/checksum/sequence; exact replay, torn-tail retention and damaged-latest fallback tests pass. Background still freezes and snapshots. Five campaign slots, ten named snapshots, verified staged import/replacement and storage-failure choices are implemented |
| M2 sustainable food / storage / rooms | Pass, automated subset | Four residents survive eight days without starvation damage using 16 actual turnip tiles and default cooking; crop rates at 75/100/125% and dormancy, food aging through transfers, granary/cellar ratios, door-bounded rooms and wall removal, food runway with spoilage and reserve policy pass |
| M1 to M2 save continuity | Pass | Original committed M1 fixture migrates; old journals replay under frozen M1 code before migration; verified untouched backups precede subsequent snapshots |
| M3–M6 gameplay and progression | Pass, automated campaign/native subset | Three-site generation, production, wildlife/domestic animals, care, fire, defense, trade, expeditions, incidents, Chronicle, all Charter stages and onboarding have automated coverage. All three Standard-site and Pine Shelf Hearthside vegetarian Charters pass, including ceremony, Continue and later play. The pinned 30-run Winter matrix also passes; M7 and physical/human gates remain. |
| M7 release quality | In progress | Animated citizens/animals/guests, matching portraits, editable cosmetics, environment art, audio, accessibility, diagnostics and rebinding are implemented. Localization, balance/playtesting, stress optimization and platform/human release gates remain. |
| Development APK publication | Pass at `9ddd782` | [Downloadable APK prerelease](https://github.com/maccam912/brackenward/releases/tag/dev-9ddd782d1585); checked commits publish stable-identity APKs, provenance and checksums. Production signing/store publication remain pending. |

Current local validation baseline plus current targeted reruns: 28 GDScript suites, 2,057 checks, zero failures, including 517 native UI checks. Three real tutorial flows pass 22 checks each. Catalog/media validation passes. Frozen replay and save-continuation evidence is recorded in the latest checkpoint below. Tests fail closed on script errors, timeout, missing results or zero tests. Acceptance IDs cover only their stated scope; they do not imply complete release certification. Generated JUnit/XML/screenshots/logs/builds are ignored; committed reports describe the observed results.

Design amendment: Android compile/target SDK 36, build-tools 36.1.0, NDK 29.0.14206865, Gradle 8.11.1, AGP 8.6.1, Kotlin 2.1.21 match the downloaded 4.7.2 template. The original design's SDK 35 / NDK 28 pins conflicted with that template. No gameplay numbers changed. The template emits an AGP compile-SDK support warning; it remains recorded rather than treated as device validation.

Current weekly quota policy (user updated 13 October): continue implementing and polishing against DESIGN.md until weekly remaining usage is below 50%, checking live limits periodically and at checkpoint boundaries. Starting remaining usage is 99%. If the game is complete earlier, continue useful polish to the cutoff. Physical-device and human release gates remain distinct from implementation. Earlier thresholds in historical checkpoint notes are superseded.

Local generated APKs are ignored and may predate the source tree. Use the versioned development release and its published checksum for a specific build; build success, emulator execution and physical-phone behavior are separate evidence.

Record lookups are cached by table identity and ID, with invalidation after import and field removal. The 33-check colony suite still matches speed/save traces and takes about 8 seconds locally after this optimization. UI suites now use isolated temporary save directories; a rendered-pixel regression verifies workers remain visible over field terrain. Calendar labels show season/day/year.

Campaign management: new/continued slots stay independent; named snapshots require selecting an occupied slot before replacement; autosave rotation leaves named saves intact. Import stages and verifies before archiving/adopting a selected campaign. Closing a write-error panel cannot silently resume; an explicit unsaved choice leaves a persistent notice until a verified retry. UI tests exercise real write failure, text-entry spaces, named-save completion and clone import into a separate slot. Startup recovers the existing campaign and will not overwrite a failed recovery with the placeholder preview.

Phone-feedback revision: default body text is 16 dp, the status panel is shorter, and directional controls draw full arrows within the existing 48 dp targets. Font imports use MSDF so the UI is not scaling small raster glyphs on high-density phones; world sprites explicitly use nearest filtering. Gather resource actions enter a rectangle preview, count only eligible resources, and submit all matching targets atomically. Queued trees retain check marks until complete/canceled, and Gathering workers take the next job automatically. Mineral-area orders repeat per-unit work until the marked node empties. Automated tests cover six-tree completion by one eligible worker, Off preferences, repeat areas, cancellation, invalid-area atomicity, pending-command saves and deterministic continuation. The native UI test routes touch/drag/release through the viewport from a fresh selection and verifies a single Confirm transaction. It caught an oversized invisible placement-container area intercepting map touches; overlay layout containers now ignore input, leaving actual buttons active. Device preferences retain the last campaign, camera, text scale and handedness independently of imported snapshots; corrupt preference files are preserved.

Interaction reference: [Ludeon's RimWorld designator update](https://ludeon.com/blog/page/2/) describes click-and-drag order tools; Brackenward retains the explicit Confirm step specified for touch. No RimWorld assets or code are used.

Android 35 arm64 emulator (1080x2340, density 2.75, SwiftShader/ANGLE): installed the updated APK over existing private campaigns. Real ADB touch drag selected six trees, preview displayed six unmarked trees, Confirm created six jobs, and 4x simulation completed all six. The verified private snapshot at tick 3002 contained six Complete gathering jobs and ledger produced wood 92 (44 initial including hearth fuel + 48 gathered). Native screenshots show the compact status panel, complete directional arrows and sharply scaled text. No GDScript/runtime errors appeared in logcat; one cached-shader recompilation warning occurred after the APK update. This verifies the emulator interaction, not physical-phone rendering or performance.

M3 weather checkpoint: saved three-day forecasts, dedicated Park-Miller weather stream, exact day/season weights and extreme spacing, temperature effects, flood preview/actual coverage, one-time crop/food losses, protected stores/carriers, growth pause until 18:00, and early harvest after 50% growth are implemented. Rain/snow movement carries exact fractional progress; a normal tile takes 10 ticks, wet soil 15, snow 12 before personal modifiers. Twenty-three new checks cover 300 forecast days across reload, exact movement, hazard exposure/repetition, real early-harvest work/output, public M2 fixture migration, frozen M2 journal replay/backups, new recovery checkpoints and foreign-campaign rejection. Forecast and flood-preview UI tests and a native rendered screenshot passed. Weather uses the authored fallback river; it does not imply that the complete three-site generator exists.

Persistence: immutable M2 simulators/catalogs preserve `978b6d5` rules, including rectangle commands. New journal complete-tick frames include validated authoritative state, permitting recovery across later additive gameplay changes without rerunning acknowledged progress under different rules. Command records/checksums/sequences remain. Frame/journal bounds remain enforced; long-campaign size/performance measurement is still a release gate. Snapshots include campaign ID, generator version, sequence, engine and human timestamp; timestamps are excluded from simulation hashes.

Android emulator abrupt termination: while campaign 2 ran at 4x, the last verified journal marker was tick 3135. SIGKILL via the app's own UID avoided the background-save callback. Relaunch selected campaign 2, recovered the same session at tick 3135, stayed paused, and a subsequent verified snapshot preserved that tick. Campaign 1 and the device preferences were retained.

Phone-feedback commit `978b6d5` passed [remote CI](https://github.com/maccam912/brackenward/actions/runs/38275219438), and its [APK release](https://github.com/maccam912/brackenward/releases/tag/dev-978b6d512f94) is published. New M3 checks/builds are local until their following pushed checkpoint completes CI.

Android emulator M2-to-M3 APK update: retained campaign 2 at tick 3135 with the same session, created an untouched migration backup, and wrote a checksum-verified format-3 snapshot. Its forecast persisted Clear/Rain/Clear/Rain for the current and following three days. Updated APK launch had no GDScript/runtime errors.

Touch lists now use a small original touch-scroll container: drags begin on action rows, cancel button activation once the 8 dp threshold is crossed, retain mouse-wheel/trackpad/scrollbar support, and release mouse capture correctly. Viewport tests cover scrolling, no action on swipe release, and a fresh tap activating exactly once. The Menu version label reads the actual project build version. The format-3 Android recovery fixture is committed as UTF-8 JSON for future migrations.

Android native touch-list check: a swipe beginning over the Named snapshots action scrolled the Menu to its lower rows without opening a save panel. The following tap opened Weather forecast exactly once; the card showed Clear today, then Rain/Clear/Rain, while the colony stayed paused. No script/runtime errors appeared. This complements the viewport cancellation/release regression.

M3 social checkpoint (format 3, additive schema revision 2): initial symmetric bonds, deterministic single-partner conversations, trait-adjusted daily gains, eight-day decay, friend/solo leisure memories, shared-building and rescue credit, bounded room disagreements, real 12 WU Care mediation, oldest-resident optional offers and four-day promises are implemented. Accepted request deadlines and memories survive snapshots/journal checkpoints; format-3 revision-1 saves gain the new state through a pure additive migration. People cards expose needs, traits, active morale causes, relationships, mediation and request terms. Work now opens per-person preferences instead of presenting forty category rows at once. Multiple preference edits can be staged while paused, remain visibly pending, and apply in order on the next tick. Wells restore drought growth within exactly eight Manhattan tiles, with the affected crop reason visible.

Thirty-three social/irrigation checks and six additional UI checks pass. The 72,000-tick speed/save colony suite passes in about 18 seconds after limiting leisure candidates and avoiding per-tile scans of historical jobs; the earlier unoptimized leisure search timed out and was corrected before publication. Remaining social integration includes full production/research/expedition fulfillment sources and complete population/appearance progression; existing request conditions use real current state rather than granting placeholder outcomes.

Weather checkpoint `ded5971` passed [CI](https://github.com/maccam912/brackenward/actions/runs/38280562573) and [APK publication](https://github.com/maccam912/brackenward/releases/tag/dev-ded597149d36). Current social changes remain local pending their checked commit.

Native Android social UI: the updated APK retained the existing campaign and showed Mira's needs, Kind/Homebody traits, current warmth modifier, initial Oren relationship 20 and other bonds 0. Work preferences opened from the person card with all categories available in a touch-scroll list. Additive migration now retains both original snapshot and journal backups before writing current state; a dedicated revision-1 fixture/journal test verifies this.

Android native staged-preference check: Growing and Gathering were changed to First in Mira's paused panel, both rows showed Pending, then one resume applied both. A verified private snapshot retained schema revision 2, the new preferences and initial bond 20, with no pending commands. Its UTF-8 JSON fixture is retained for the next additive migration.

M4 production checkpoint (format 4, additive schema revision 4): the complete design catalog contains 28 items, 34 structures, seven resource types, 13 recipes, six crops and twelve research projects totaling 4,700 points. Legacy catalogs remain immutable. Workstations expose Repeat/ Maintain orders, ingredient filters, priority and suspension; real workers fetch, escrow, produce and haul every batch. Maintain counts reserved hauling goods and incoming batches to prevent overshoot. Explicit hearth policies take precedence over the initial automatic meal policy. Ingredient selection orders expiry, retrieval distance and item ID; spoiled batches retain completed WU and replace from allowed alternatives. Research uses one active project, two desks, a three-project queue, retained progress, contributor XP awarded on completion, Curious memories and banked insight capped at 1,000 without granting XP. All catalog unlocks are visible in Research. Existing worn equipment now participates in the conservation ledger and forged kits apply the exact 15% bonus.

Thirty-four production/research checks and six new real-Control checks pass, including physical two-batch completion, maintained quantity, exact 4,700-point research, real scheduler completion, switching, queued insight, spoilage substitution, explicit hearth policies, round-trip saves and retained M3 social/equipment state. This catalog does not imply that currently absent wildlife, region, injury or special placement behaviors are implemented. These remain the next milestones.

Current local checkpoint totals: 19 unit, 6 prototype integration, 42 colony, 25 survival, 28 campaign/persistence, 23 weather, 33 social, 34 production, 137 native UI and 4 Kotlin checks (351). Android debug export passes. Android 35 emulator update retained campaign 2 at tick 3265, both staged work preferences and initial bonds/equipment, and created an untouched format-3 migration backup. Native Work -> Research displayed the complete nodes/unlocks and a touch selection set Storecraft. Background save verified format 4 / schema 4 at tick 3415; this UTF-8 fixture is committed for future migrations. No GDScript/runtime errors appeared. The stock catalog labels were then refined to use player-facing names.

Care checkpoint (format 4, additive schema revision 6): attack downing caps health at 10 and excludes downed targets; bleeding costs exactly 2 health/hour until stabilized. Workers physically carry patients with both hands and a 25% movement penalty to the closest reachable bed or cart rally. If moving would exceed the bleeding window, urgent treatment in place overrides Care Off. Treatment consumes a real herb or medicine atomically, or stabilizes without inputs; the strongest active recovery rate is used for twelve hours, then resting heals 2/hour. Patients are fed through real two-WU jobs, wait for requested treatment and recover before ordinary work resumes at 50 health. Interrupted carrying drops the patient without loss. A missing dressing can fall back to stabilization while preserving WU. Hard rest refuses ordinary work even when food is missing. Herbal benches default to maintaining four medicines after Herbalism, requiring actual cloth/herbs.

Standard deaths retain a snapshot of the resident and relationships once, drop carried goods and all worn gear without changing conservation totals, and create a body with a twelve-WU player-marked burial task. Nearby remains impose one -40 penalty; friend/other grief declines linearly over three/two days. No living residents freezes the colony into an epilogue with load, same-seed restart and menu choices. Hearthside has no death at zero health: two days of recovery, then waking at 40, preserving equipment and needs. A new downing pauses before another simulation tick. Care cards display health, fullness, rest, bleed/recovery timing, exact inputs/WU and an explicit treatment-worker choice. Bodies/patients/carriers have distinct original visual states.

Forty-one care checks and seven additional real-Control checks pass. The initial distant-patient test took 34 seconds; caching reachable bed choices by patient position and occupied beds, with invalidation on navigation changes, reduced the whole care suite to under one second without changing outcomes. M4 native save migration retained campaign 2 at tick 3415, Storecraft and equipment, and preserved its revision-4 snapshot before writing revision 5. The Android document picker imported an isolated downed-patient fixture into empty campaign 3; the native care card showed the bleed deadline and complete treatment choices, with time paused. This verifies emulator behavior, not the physical-phone task battery. Wildlife/combat damage sources and industrial fire remain next work.

Native Android treatment: tapping Treat with Mira and resuming 4x completed the physical rescue and a 16-WU herb dressing. The verified background snapshot at tick 2860 showed Tavi stabilized at health 27, fullness 603, recovering in place, one herb consumed, and both care jobs Complete. The source is retained as a UTF-8 revision-5 fixture. Revision 6 adds independently expiring treatment windows so applying a weaker dressing cannot prolong medicine-strength healing, and preserves that native treatment through migration. Local current totals are 399 checks across simulation, native UI, persistence and Kotlin; CI status is reported separately.

The final revision-6 APK update retained the native care campaign at tick 2860 and health 27, inferred its existing herb recovery window, and preserved the prior revision-5 snapshot as a migration backup. Launch had no GDScript/runtime errors; only the known shader-cache recompilation warning.

Generation checkpoint (format 4, schema revision 7, generator version 1): new colonies choose one of the three sites, a displayed unsigned 32-bit seed and a mode. Dedicated Park-Miller streams create coarse soil, the curved four-cell river/floodplain, ridges/uplands, protected home/starter field, repaired boundary trails and four starting bridge tiles, guaranteed/ambient resource nodes and sixteen unique habitat positions. Global mirrors preserve every footprint and stored supply position. Saved terrain is authoritative and never regenerated; older campaigns receive an empty legacy geometry marker. Crops use saved fertility, movement rejects height cliffs, bridges support river traversal, and flood forecasts use the actual saved river. Creation runs in an isolated worker thread and prevents time advancing while the result is checked and adopted. A fresh installation does not save its placeholder before a colony is chosen.

Seventy-one generation checks pass across twelve seed/site combinations, covering deterministic reproduction, exact saved-map round trips, guaranteed resources, protected fields, transformed footprints, real new-map farming, fallback validity and legacy map preservation. Eight additional real-Control checks verify seed bounds, asynchronous paused creation, independent slots, site/mode selection and transformed field preview. Final ambient feasibility removes only unguaranteed placements that have no reachable adjacent work tile. This reduced the suite from 87 to 15.5 seconds; all twelve cases now pass attempt zero. The fallback design was clarified without changing its 80-extra-tree budget: eight trees form the upland groves necessary for valid boar habitat; seventy-two retain expanding-ring placement. Wildlife entities and regional gameplay are not inferred from habitat positions.

Current local totals: 19 unit, 6 prototype integration, 42 colony, 25 survival, 28 campaign/persistence, 23 weather, 33 social, 34 production, 41 care, 71 generation, 152 native UI and 4 Kotlin checks (478). Full generation Android validation follows before the next pushed checkpoint.

Native Android generation: the setup card displayed seed 3492740710 before creation. Selecting Pine Shelf and creating empty campaign 4 produced an attempt-zero map with 4,306 natural resource objects, four bridge tiles and 6/4/2/4 distinct hare/deer/boar/goose habitat positions. The checksum-verified initial snapshot retained generator version 1 and both 16,384-cell terrain arrays. Existing campaign 3 retained generator version 0, Tavi health 27 and tick 2860 through the schema-7 APK upgrade, with an untouched backup. The setup descriptions were then shortened. The native popup path exposed inconsistent touch ordering and a macOS focus crash during injected touch release, so small lists now use original 48-unit tap-to-change buttons. Real-Control tests verify canceled choice swipes and the following tap changing exactly once.

Final native setup check: an ADB swipe beginning on the Meadow Reach choice left it unchanged; the following tap selected Pine Shelf exactly once without a popup. All setup choices use the same original 48-unit release buttons as Work preferences. The compact default form shows Create on the first screen. Android launch logged no script/runtime errors, apart from the known shader-cache warning.

Forestry/fishing checkpoint: schema 8 adds saved tree growth, nonoverlapping forest zones with rounded-up 50/75/100% reserves, automatic cost-free 4 WU replanting, eight non-winter days to maturity, and 2 WU sapling clearing with no yield. Individual cuts can intentionally go below the reserve. A 2×2 pier requires two land/two river tiles, consumes real construction materials and creates 12 WU/two-fish batches with eight per pier/sixteen per river per day, reset at 06:00. Suspension and two output-stack buffers prevent unbounded work. Migration leaves existing maps and care intact. Eighteen simulation checks and three UI checks cover these behaviors. Current totals: 19 unit, 6 prototype integration, 42 colony, 25 survival, 28 campaign, 23 weather, 33 social, 34 production, 41 care, 71 generation, 18 nature, 155 UI and 4 Kotlin (499). Local Android debug export succeeded. The generator checkpoint passed remote CI and published [its APK](https://github.com/maccam912/brackenward/releases/tag/dev-016d46ca28e2).

Schema-8 Android APK upgrade: the emulator retained campaign 4 at tick 1800 with seed 3492740710, identical full terrain arrays and all 4,306 resource records. The private snapshot checksum verified and the original schema-7 snapshot was archived untouched. No regeneration occurred.

Wildlife/hunting checkpoint: content v2 adds the exhaustive six-animal, three-enemy, eight-expedition, three-community, four-minor-event and five-charter catalogs. Original v1 data stays immutable with checksum-checked forward migration. The added future catalog rows do not imply those remaining systems are implemented. Six hares/four deer/two boars/four geese have saved independent streams, exact movement remainders, hourly reachable forage, fleeing, one daily crop bite and capped fourth-dawn replenishment. Hunters must be armed; boar hunts reserve an armed Guard escort unless Solo is explicitly confirmed. Named hunter selection can pin a bow user for faster wildlife. Simultaneous attacks use exact weapon damage/cooldowns/LOS, vest armor, retreat at 40 and attack-capped downing. Boars never target downed people. Kills leave carcasses for real species-specific butchering and hauling; two-day spoilage cancels work without food. Canceling a hunt also cancels its escort. Existing campaigns acquire initial wildlife only after the old state validates; maps, goods, care and IDs are retained. Thirty wildlife checks and four new UI checks pass, along with existing suites: 533 total including the four unchanged Kotlin tests. Android debug export succeeds. [Forestry/fishing CI](https://github.com/maccam912/brackenward/actions/runs/38308452307) and [APK publication](https://github.com/maccam912/brackenward/releases/tag/dev-43731582ad6d) passed.

Danger routing: ordinary workers avoid the visible eight-tile boundary around marked boar hunts or attacking boars. A civilian already inside it chooses a reachable safe escape before ordinary work. Escorts wait for an armed hunter and retreat to safety when the hunter stops. Thirty wildlife checks cover blocked unsafe work and physical escape targets; these derived danger caches are excluded from authoritative saves.

Native Android wildlife upgrade: the checksum-verified schema-9/catalog-v2 snapshot kept campaign 4, tick 1800, seed 3492740710, complete saved terrain/resources, care state, forestry/fishing state and the conservation ledger identical to schema 8. It added exactly 6/4/2/4 wildlife on existing habitats. The original snapshot was backed up; no script/runtime errors appeared in current-process logcat. The known cached-shader recompilation warning remains. Physical phone hunting is deferred to user testing.

Livestock checkpoint: schema 10 adds enclosed connected pens, four free interior tiles per animal, six shelter slots per touching/enclosed barn and the twelve-animal colony cap. Fields/stockpiles/pens reject overlap. Acquisition reserves actual space and creates Animals leading jobs that use pen gates; animals cannot be obtained from a player-facing spawn action. Trade and expedition acquisition remain the next integration. Animals workers physically transport grain/vegetables into a 24-unit barn feed buffer without consuming or refreshing them. Dawn consumes exact feed once, products accrue for at most two days and require 4 WU collection into a 24-unit output buffer. Goats away consume no home feed and produce no milk. Two unfed days are a visible grace period, later days lose 10 health; feeding restores 10/day. An open fence does not arbitrarily disable still-accessible feed. Optional eight-day breeding checks two fed adults and actual spare capacity, creates one juvenile with four-day maturation and alternating integer hen feeding, and never queues blocked births. Optional named slaughter requires a separate confirmation and 10 WU for exact yields. Overlapping map objects now have ranked named chooser rows, including livestock. Twenty-eight livestock checks and five UI checks pass; 566 total including unchanged Kotlin checks. Existing colony, survival, campaign, care, production, forestry/fishing and wildlife suites pass. [Wildlife CI](https://github.com/maccam912/brackenward/actions/runs/38310629270) and its [APK release](https://github.com/maccam912/brackenward/releases/tag/dev-581d1d601d01) are verified.

Native schema-10 Android upgrade: the checksum-verified campaign snapshot preserved every schema-9 authoritative field, including all sixteen animals and their individual streams, and added empty domestic state. The original schema-9 snapshot was archived untouched. This is upgrade/startup verification; domestic acquisition awaits the trade/expedition integration.

Construction checkpoint: schema 11 adds saved blueprint groups and one helper per active construction target. Up to two workers reserve distinct perimeter positions, fetch the original shared materials, sum exact WU into one progress/receipt and receive XP only on parent completion. Cancellation returns escrow and releases both workers. Walls/fences/gates use axis-aligned painting, floors/paths use rectangular painting and bridges retain water validation. Preview shows dimensions, complete material cost and exact valid/omitted counts; invalid cells stay red with their cause. Floors/paths permit the specified furniture/wall overlays without creating duplicate overlays. The four-bed lodge uses 23 walls, one south door and four rotated beds: W73 F8, 206 WU, 28 ordinary editable blueprints and a 24-tile roofed interior. Its closing wall waits for the beds/door; explicitly canceled blueprint prerequisites do not trap editing. A full physical simulation completes four assigned roofed beds with exact material conservation. Twenty-one construction checks and six UI checks pass, along with existing suites; 593 total including unchanged Kotlin checks. Starting a fresh preview correctly repairs Confirm state after campaign replacement. [Livestock CI](https://github.com/maccam912/brackenward/actions/runs/38312505718) and [APK](https://github.com/maccam912/brackenward/releases/tag/dev-f574b1f790a9) passed.

Native Android construction: a real Wood wall touch selection showed a 4×1 preview, four valid cells and eight wood total. Confirm submitted one area order. The first native run exposed an idle resident standing in the final unfinished wall; three completed and the fourth correctly paused, but idle behavior did not clear its worksite. The fix makes idle/resting workers step aside without interrupting held material deliveries; it also excludes unreachable loose input stacks. After an APK update, that same stalled save continued and completed all four walls, with one Complete step-aside job and exactly eight wood consumed in a checksum-verified snapshot. The old schema-10 snapshot was archived. Native screenshots show full arrows and sharply scaled text.

Equipment checkpoint: schema 12 adds saved per-resident/per-slot replacement and upgrade policies. The wearer physically fetches an accessible unreserved toolkit/weapon/cloak/vest and spends 2 WU; old gear drops as a real reusable stack. Equipment transfers change ownership, never inventory production/consumption totals. Only the wearer can take that Hauling task; Hauling Off and ordinary health/needs remain respected. Automatic replacements default on, upgrades off; forged tools require an explicit upgrade choice. Spears/bows have equal automatic tiers with the preferred weapon retained. Unequipping disables replacement for that slot, preventing a silent re-equip. Cancellation returns held new gear and preserves the old worn slot. People cards link to Equipment, explain gear effects, missing stock, work requirements and policy choices. Seventeen gear checks and four UI checks pass; 614 total including unchanged Kotlin checks. Existing production, care, construction, livestock, colony, survival and persistence checks pass. [Construction CI](https://github.com/maccam912/brackenward/actions/runs/38315697837) and its [APK](https://github.com/maccam912/brackenward/releases/tag/dev-c1817aaea371) passed.

Native Android equipment upgrade: the checksum-verified schema-12 campaign retained every schema-11 authoritative field, including completed painted walls, material consumption, wildlife streams and geometry. It initialized replacements-on/upgrades-off policies for all four residents and preserved the original snapshot untouched. Physical equipping is covered by simulation and real-Control checks; this native run verifies upgrade/startup.

Maintenance checkpoint: schema 13 adds exact repair quantities and saved physical move phases, plus explicit recovered/traded/expedition/lost/looted ledger buckets. Repairs use the largest construction material (item-ID tie), ceil(restored HP/50) units and 0.1 WU per HP. Demolition costs ceil(original WU/2), returns floor(each material/2), drops surviving contents/fuel with age retained, clears bed/store/services and retains a nonblocking ruin record. Rebuild uses full normal costs. Furniture movement validates/reserves its destination, uses the full original WU across dismantling/rebuilding, keeps identity/health/settings, physically carries retained materials in loads <=8, resumes station policies and preserves bed assignment. Cancel after dismantling leaves actual materials available. Cart movement costs 20 WU then pushes the real cart along a clear 2×2 route; contents move with it, and handoff meets the partly moved cart without teleporting. Built-in roofs now match catalog flags; removed buildings lose collision/roof/services, rebuilt barns reassign occupants, and legacy bridges actually become passable. Flood loss uses the explicit lost ledger bucket. Multi-item recipe fetching fills a shared eight-unit carry instead of separate trips for each ingredient. Thirty-two maintenance/movement checks and eight UI checks pass, plus existing suites: 654 total including unchanged Kotlin tests. [Equipment CI](https://github.com/maccam912/brackenward/actions/runs/38317084341) and [APK](https://github.com/maccam912/brackenward/releases/tag/dev-c03236ed099f) passed.

Native maintenance upgrade: checksum-verified schema 13 retained all prior authoritative fields, every existing work record and every original conservation balance. It added empty work memos/zero repair amounts and the explicit new ledger categories. The original schema-12 snapshot was archived untouched. Local APK export and emulator startup passed; physical maintenance movement is covered by simulation/UI tests, with device performance still pending.

Population checkpoint: schema 14 supports arbitrary stable citizen IDs and the twenty-resident cap, with saved newcomer/name streams, four-day offers from day four, two-day expiry, explicit sleeping/food prerequisites, compatible traits and exact starting skills/needs. Accepted residents enter through a safe boundary wearing their own equipment, walk to the cart and deposit four rations exactly once. Self-care and treatment interrupt arrival. Relationships, gear policies, selection and inspectors support new IDs. Thirty-eight population checks (including twenty residents/190 pairs), three real-Control checks and all existing suites passed: 695 total including four unchanged Kotlin checks. Local APK export passed. Android emulator upgrade checksum matched and every prior schema-13 field survived unchanged; the original snapshot was retained. Maintenance [CI](https://github.com/maccam912/brackenward/actions/runs/38320985073) and [APK](https://github.com/maccam912/brackenward/releases/tag/dev-0edad196e0b4) passed. Physical phone QA remains deferred. Last observed weekly remaining: 75%.

Trade checkpoint: schema 15 adds guaranteed merchant visits, one-day notice, safe physical boundary entry, a twenty-four-hour stay starting at the cart, queued parties, saved reputation tiers and standard delivery cooldowns. Trades quote exact per-unit ceiling prices and surplus gifts, reserve both sides atomically, physically carry payment in <=8-unit loads, and release goods only at an immutable payment receipt. Self-care interruptions retain payment reservations, early cancellation frees them, unpaid purchases cancel on merchant departure, and accepted standard deliveries wait for another visit without expiry. Hens/goats require Husbandry and enough pen/barn/global capacity; purchases arrive at the cart and require handlers. Valley/cart panels expose offers, shortages, prices, relations and receipts; merchants render and can be selected on the map. Twenty-seven simulation and four UI checks plus colony, survival, generation and persistence regressions pass: 726 total including unchanged suites/Kotlin. APK export and checksum-verified native schema-14→15 upgrade passed, preserving every prior field and original snapshot. Population [CI](https://github.com/maccam912/brackenward/actions/runs/38322329257) and [APK](https://github.com/maccam912/brackenward/releases/tag/dev-a65b3199959b) passed. Latest weekly remaining: 74%.

Regional checkpoint: schema 16 adds deterministic north-up 9×9 topology, all eight sites/three communities, Trailcraft/season/repeat gates and saved single-expedition phases. Packing atomically reserves real items at the cart; two to four healthy residents and up to two adult goats must physically meet before a separate Depart command. Quotes expose exact rations/feed/contract/cargo limits, skills removed from home and a food forecast that excludes departing supplies. Departure freezes readiness; off-map residents retain ordinary hunger/rest and camp morale, consume actual cargo, and produce no home work. Midpoint choices pause once, preserve return reserves and have a free Continue; optional rewards have eight-day cooldowns and survive recall. Collection applies exact full/75%/unprepared bands, one injury-only medicine, stabilized bounded injury, successful contract/relations/insight and one-time leftover pickup. Recall preserves unconsumed cargo and uses elapsed outbound time; local recall does not teleport. Return walks to the cart, restores home workers and physically unloads eight-unit loads before completing; blocked storage remains visible. Hens/goats retain capacity, feed and handler rules. Ninety-five regional checks cover all eight full/failure/recall outcomes, community delivery, pickup, medicine, forecasts and phase saves. Twelve UI additions cover viewport width, 48 dp two-axis map panning, separate packing/departure, off-map visibility and modal choices; all affected regressions pass: 833 total including unchanged suites/Kotlin. APK export passed. Native schema-15→16 checksum and original fields were preserved; original snapshot retained. Emulator touch opened Valley, map and Berry hollow; an actual clipped checkbox row was fixed and checked after reinstall, with rules behind an optional disclosure. Trade [CI](https://github.com/maccam912/brackenward/actions/runs/38323051394) and [APK](https://github.com/maccam912/brackenward/releases/tag/dev-24915daf5a2a) passed. Weekly remaining last observed 74%. Physical phone QA remains deferred.

Industrial fire checkpoint: schema 17 adds saved fire roots, rain/damage/spread clocks, target work and destroyed-building history. Structures lose 2 HP/second (1 in rain); raw wood/fiber/cloth lose one unit/second, half-rate in rain. Orthogonal spread selects north/east/south/west then ID every thirty seconds, sixty in rain; one root pauses once. The cart is indestructible and food cannot propagate flame. Destroyed stores drop surviving goods with age preserved and lose services. Care workers fetch an abstract water load for 2 WU at the nearest reachable well/bank, visibly carry it, then spend 8 WU; interruptions discard water and retain applied progress/XP. Care Off remains respected. Burning inputs/stations/storage are unavailable and the response panel offers work, well and camera actions. Combat resolves before queued work, water and dismantling completions; an actual boar downing prevents an otherwise completed gather transaction. Fog now reduces bow range by two, including hunt approach; ruins no longer block shots. Twenty fire/combat checks and three UI additions pass, with broad affected regressions including all 95 expedition cases: 856 total including unchanged suites/Kotlin. APK export and checksum-verified Android schema-16→17 upgrade passed, preserving every prior field and the original snapshot. Scheduled ignition and raids are next director work. Regional [CI](https://github.com/maccam912/brackenward/actions/runs/38326699684) and [APK](https://github.com/maccam912/brackenward/releases/tag/dev-cc74852598f4) passed. Last weekly remaining 73%.

Defense/director checkpoint: schema 18 adds fixed announced road parties, validated boundary entry, exact catalog combat, deterministic focus/attacking/nearest/ID targets, rallies, explicit Stand fast, forty-health retreat, shelter/passage/stand down and enemy selection. Actual stock theft respects preference and four-unit caps; downing floors enemies at one, makes them stable/neutral, returns stolen goods with age retained and prevents execution. They recover to twenty-five after twelve hours; voluntary care gives three Road reputation once per person. Supply offers reserve real goods worth eight times budget, deliver them physically under a six-hour ceasefire and give a one-hour failure warning; the absolute six-hour raid cap still prevents renewed violence once elapsed. A retreating party cannot restart. The director derives public food/downed/health/destruction/morale pressure, considers Standard raids and unsafe fixed industrial targets from day-eight dawn, protects shown extreme weather and seventy-two-hour start spacing, and records forty-eight-hour recovery. Hearthside schedules no human raids; suspending/clearing the fixed overheating target prevents ignition. Twenty-five defense, nineteen director and six new UI checks pass, plus affected regression suites: 906 total including unchanged suites/Kotlin. APK export and checksum-verified native schema-17→18 upgrade passed, retaining all prior fields and snapshots. Fire [CI](https://github.com/maccam912/brackenward/actions/runs/38328491028) and [APK](https://github.com/maccam912/brackenward/releases/tag/dev-903015e9127e) passed. Minor events, fuller chronicle, charter and release polish remain work. Weekly remaining last observed 73%.


M5 correction and opportunities checkpoint (`0.5.2-m5`, schema 19): all four catalog minor events now use physical visitors, real reserved goods and assigned work, exact deadlines and eight-day repeat cooldowns. Shared study binds the two named friends to a real research desk. Storytelling starts after the visitor reaches the table, requires uninterrupted nearby half-hour leisure, and grants the specified one-day morale memory. Expiry, cancellation, relocated carts, held inputs and saved immutable receipts are covered. The visitor list, terms, work inspectors and world actors are playable; the native portrait screenshot was inspected and its long header shortened.

Review of prior implementation fixed both-sided ceasefires, retreating actors retaining unfinished movement edges, capped Guard experience, emergency firefighting overriding Care Off, fire/attack damage resolving together after movement, kiln process inputs being distinguished from hazardous surrounding storage, expedition return waiting through an active raid, and exact 72-hour spacing across evening fire and extreme-weather onsets. These restore specified behavior; no economy values changed. Schema 18 campaigns gain opportunity state and Guard counters additively. Existing committed M1–M4 fixtures continue to migrate and retained backups remain verified.

At this checkpoint native macOS launch and UI checks passed. Full new physical Android and Windows/Linux launches have not been exercised in this turn. The richer causal chronicle, charter/communal supper, mature onboarding, real multi-season campaign traces, final art/audio/accessibility, stress performance and remaining platform/human release gates are still unfinished. Their new source work is kept out of this checkpoint until integrated and verified. Earlier build records below describe their own commits and are not certification of this source revision.

Current M5 local validation: 24 GDScript suites, 992 checks, zero failures. Catalog/media validation and native UI screenshots passed. New dedicated totals: opportunity 57, defense 40, fire 23, region 98, director 27 and UI 214. The director includes 96-day Standard and Hearthside scheduling sweeps with controlled incident resolution; this is distinct from an ordinary-play survival trace. Remote CI for prior commit a21436b passed; new source CI status is checked after publication.


## M6 Charter and Chronicle checkpoint — 12 October 2026

All five ordered Charter stages now record permanent evidence and award insight once. The cart exposes the checklist, settlement name and free cosmetic banner/palette/plaque/sign controls. Communal supper physically reserves two meals per home resident, seats residents in stable ID waves, consumes exactly one meal per attendee and requires 150 seated ticks; interruptions, cancellation, inaccessible seats, spoiled food and emergency hunger retain real conservation. The final two-hour ceremony records its start conditions, cancels on hostile arrival, pauses for the factual epilogue and supports continuing the same settlement.

The simulation emits a bounded rich Chronicle with independent event IDs, name snapshots, participants, locations, actual item deltas and explicit causal links. Injury/downing/rescue, requests, friendship, research, trades, expeditions, supper and Charter transactions carry their actual evidence. The daily journal selects at most three distinct chains at 22:00; causal snapshots survive eviction; the epilogue selects eight chains. Person cards show up to three timed morale memories with exact modifiers, expiry and available event links, plus ten historical highlights. Version-19 saves gain both systems through a pure migration. Malformed supper banks/slots are rejected before cross-record validation.

Additional scheduler fixes prevent empty cooking outputs from blocking all later batches, retain the fixed eating rate in cold weather, respect breaks and explicit Stand fast, let emergency rescue interrupt noncritical sleep, choose safe alternate work positions and reachable edible stacks, and move trapped civilians to the safest reachable point. Citizens are processed in stable ID order. A dedicated scheduler suite covers the reproduced failures.

The new ordinary-command campaign harness records initial/final snapshots, ordered commands and hourly/daily evidence. Seed 104729 survived eight days on Meadow Reach, Pine Shelf and Reed Bend with minimum health 100, no starvation damage or departures, and an earned shelter stage. These are real generated-map survival runs, not completed Charter campaigns. Longer winter/vegetarian/Charter traces remain in progress. The pure tutorial model and per-campaign device preference migration are tested; guided UI integration remains next.

Native macOS Charter, Chronicle, cart rewards and ending UI screenshots were inspected. Windows/physical Android launch, cross-platform campaign replay, complete Charter routes and release media remain open gates. Latest weekly usage check: 49% remaining (baseline72%); no reset increase observed. Stop work at a clean checkpoint if remaining falls below10% or increases above the previous observed reading.

Local checkpoint validation: 28 GDScript suites, 1153 checks, zero failures; content/catalog/media validator and `git diff --check` passed. Native UI suite exercised 230 checks. Remote checks for this checkpoint begin after push.


## M6 onboarding, campaign diagnostics and platform replay — 12 October 2026

Version `0.6.1-m6`, Android code 21, unchanged schema 20. Seven opening lessons and four contextual lessons now connect to real map targets and existing controls. Show me opens the relevant action, while Skip and Hide retain accurate device-local completion state. Begin focuses a real resident while paused; map pulses and gesture hints follow available targets. The persistent food card shows stored runway, daily consumption and food-crop maturity with explicit weather/harvesting caveats. Short labels, including Pause, are measured at enlarged text sizes; the guidance card leaves speed controls accessible in portrait and landscape. The native macOS UI suite passes 256 checks, with the follow, enlarged landscape and pinned-food screenshots inspected.

The design's sixth opening lesson now says to inspect/confirm Mira's Cooking First preference (and change it if needed), because the normative starting preferences already set it to First. This resolves a contradictory tutorial action without changing the initial simulation.

Ordinary campaign diagnostics exposed sleepers ignoring hunger until zero fullness despite available food. They now seek food at 350 and resume sleeping after eating; life-critical rest remains protected. The 23-check scheduler suite includes the actual meal/sleep continuation and conservation. Daily scenario checkpoints decode and compare canonical hashes before being reported as verified. Resume checks the source report, seed, site, mode, tick and save hash, retaining original start/command lineage and accumulated metrics. A one-day plus resumed one-day trace matches an uninterrupted two-day run.

Measured simulation work avoids repeated drought-well scans, wildlife field scans and empty-stack processing, and uses ordered lookup for Chronicle facts. On one unchanged real day-nine snapshot, 7,200 ticks fell from 11.483s to 9.983s, with exactly matching canonical hashes before and after the optimization. This is local CPU evidence, not the physical-device stress gate. The profiling tool checks its instrumented world against the normal simulator.

The new native replay matrix targets Windows x86-64, Linux x86-64, macOS Apple Silicon and macOS Intel. It verifies pinned editor archives and the exact official engine build, fixed ordinary commands, tick 7,200/72,000 canonical states, snapshot round trips and continuation from the committed Mac save. APK publication waits for this matrix as well as existing simulation/UI/Android/export checks. Installer regressions cover idempotence and preserving a prior executable when staged verification fails. Current matrix and complete-campaign results are pending until observed; source/editor checks remain distinct from exported-app, GPU and physical Android certification.

Follow-up onboarding review fixed three reproduced failures: explicit hearth `cook_meals` orders now complete the cooking lesson; adopting a verified import or loading an occupied slot clears the first-launch placeholder gate so play/saving/tutorials work; field suggestions avoid pending lodge footprints and future roofs. Field designation rejects active construction/move destinations with an actionable explanation. Real-Control tests cover first-launch import, saving new progress and loading another campaign. The tutorial suite covers actual explicit meal production and unfinished-lodge field selection on all three sites.

The ordinary first-winter Meadow Reach trace (seed 104729) passed 237,600 elapsed ticks and 792 invariant checks with eight living residents, minimum health 100, no starvation-grace exceedance, 58 completed improvements and eight food days. Shelter and Provision were earned. Four announced raids were supplied. This run began before the sleep correction and recorded 4,337 zero-fullness ticks within the grace period; it is winter-survival evidence, not a zero-hunger or complete-Charter certificate. Current-code whole-campaign continuations and a fresh Pine Shelf Hearthside route remain running.

Checkpoint validation: 28 GDScript suites, 1,201 checks, zero failures, including 256 native UI and 36 tutorial checks; catalog/media validation passes. Four portable installer regressions pass. The independent frozen replay passes all 64 accepted commands, 234 invariant checkpoints and exact canonical/save continuation comparisons at ticks 7,200 and 72,000. Actual local source-project graphical startup uses OpenGL 4.1 Compatibility on Apple M5 Pro / Metal and exits without script/runtime errors. Cross-platform results await the pushed workflow.


## M6 long-session reliability checkpoint — 12 October 2026

Version `0.6.2-m6`, Android code 22, unchanged schema 20. Adopting a campaign now clears all prior campaign alert counters, selection and ending presentation state, so an active fire or raid is shown even when the previous campaign had a higher alert serial. Three real UI regressions cover loaded warnings and stale selection.

A bounded opening trace now drives actual controls on all three generated sites at seed 104729. It completes all seven lessons through real gathering, cooking, sowing and work assignment, restarts the entire session midway through gathering, and verifies exact save recovery plus independent tutorial/accessibility settings after cloning. The three site runs each pass 22 checks. These traces are automated onboarding evidence; human comprehension and physical touch remain untested. The permanent generation boundary suite now includes all six specified seeds on every site, without treating repeated generation as an independently reviewed golden.

The prior workflow matched the committed campaign replay on Linux, Windows and Apple Silicon and launched the source project graphically. Linux used Mesa llvmpipe and Windows used Microsoft's software Basic Render Driver through ANGLE; neither proves hardware GPU performance. Intel Mac reached the replay runner's 780-second timeout without a reported mismatch, so publication correctly remained blocked. The next workflow gives that slower host a bounded longer allowance.

Long campaign inspection found abandoned eat/sleep/leisure jobs accumulating as Ready or Blocked even though they cannot be reassigned. Interrupted or failed personal activities now retire through the existing cancellation path, releasing reservations and physically dropping carried goods. The first work pass also reconciles unowned personal activities in older saves without deleting their history; owned rest and ordinary blocked colony work remain intact. Nine additional scheduler checks cover these cases. This fixes the observed accumulation, but does not certify the separate global 512-job release stress gate or long-term history capacity.

The journal previously accepted a write it could not read back: a valid day-19 campaign produced a 2,548,189-byte tick record above its 2 MiB record limit. Checkpointing now preflights individual frames and the 64 MiB journal total, rotating through the verified immutable snapshot path before append when necessary. Failed rotations retain old bytes, sequence bookkeeping and pending commands for retry. The actual day-19 campaign now recovers its latest acknowledged tick exactly. Sixteen added persistence checks cover oversized state and command frames, aggregate limits, real filesystem failures and recovery after retry; the persistence suite passes 44 checks. Limits and format remain unchanged. Large-campaign snapshot latency still requires physical-device performance measurement.

Reconciliation of an actual day-34 save reduced active jobs from 724 to 64, retained all 4,990 history records and an identical material ledger, and passed invariants plus exact save roundtrip. This makes the observed old campaigns recoverable without changing their supplies or completed evidence.

Checkpoint validation: all 28 GDScript suites pass, 1,259 checks total; all three real tutorial flows pass another 66 checks. The UI run was repeated in isolation after a concurrently launched graphical smoke caused a focus-loss pause; its final 259 checks pass. Native graphical startup, content validation and four smoke-classification regressions pass. The reviewed 64-command input remains unchanged; the personal-job correction updates the tick-72,000 golden to `f134fd4e3f2489dbdfc7d7e3ec373e9cce4107a3ac0301cc66bbd13e38d7582f`. A separate 204-second run verifies both checkpoints, all 234 invariants and saved-world continuation. Remote CI for this revision remains pending until observed.

Long campaigns also exposed an expensive repeated route search for an unreachable assigned bed (Reed Bend, tick 47,750). Its saved reproduction and phase timings are preserved. The cause and any performance correction remain separate work; full Charter completion and M7 release gates are still pending.


## M6 measured work-history optimization — 12 October 2026

Version `0.6.3-m6`, Android code 23, unchanged schema 20. Production now builds temporary indexes of occupied stations, pending output, research assignments and physical stock once per work-creation pass. Newly queued batches update those indexes immediately, preserving stable order and shared Maintain targets. Hauling similarly indexes active source assignments once instead of scanning completed work for every loose stack. History, reserves, materials, priorities and simulation rules are retained. A new production regression covers three stations sharing one Maintain target with a higher-priority duplicate station order.

On the preserved day-34 save, 1,000 ticks retain canonical hash `182085ad25ce9dbc089ed2a50f5d69cfe16580790a0410e6b26a3dd4e26f2ec7`. The measured simulation fell from 27.66 seconds to 15.61 seconds; instrumented production work fell from 12.14 to 2.09 seconds and default work creation from 5.16 to 1.34 seconds. This is a local fixed-snapshot measurement, not the physical-device stress or complete-campaign gate.

The separate route experiment did not improve its repeated unreachable-bed benchmark and was reverted. The repeated large A* search remains unresolved; its exact saved reproduction is retained under local `reports/fixtures/reed-sleep-route-*`. It does not justify changing player needs, path order or bed assignment without further review.

A final post-revert measurement confirms the same 1,000-tick hash in 15.61 seconds. Focused final-source suites pass Production 37, Scheduler 32, Defense 40, Maintenance 32 and Region 98. The full 28-suite reliability checkpoint remains separately recorded above. To reproduce the unresolved movement hotspot:

```sh
tools/godot.sh --headless --script tools/profile_campaign.gd -- reports/fixtures/reed-sleep-route-47749.brackenward 1
```

At the next tick, Oren (ID 2) at `(53,63)`, rest 299, repeatedly searches for unreachable assigned bed 2920 at `(61,66)`; the recorded route search costs 3.54 seconds. A route backoff or reachable-rest rule requires a deliberate gameplay regression before implementation.

The final performance replay retains the unchanged reviewed golden: all 64 commands, tick-7,200/tick-72,000 hashes, 234 invariant checks and saved-world continuation pass (208 seconds). The final post-revert fixed-snapshot run and focused movement suites confirm the retained changes. Work stops at 9% weekly remaining (baseline 72%), with no observed reset. Resume from the verified local campaign paths in `CAMPAIGN_EVIDENCE.md`, address the preserved unreachable-rest pathfinding case, then finish the remaining M6 campaign/platform gates before M7. Physical Android, human comprehension, final art/audio/accessibility and release stress tests remain pending.


## M6 placement feedback fixes — 13 October 2026

Version `0.6.4-m6`, Android code 24, unchanged schema 20. A tap starts a fresh one-cell stroke for walls, doors and other painted structures, replacing both corners of any previous preview. Drags retain their own start/end, with the existing axis-aligned wall behavior. Confirm still submits once. All placement entry points preserve camera position and zoom and stop following; previews begin at the visible map center. This includes stockpiles, fields, forests, resources, pens, buildings, lodge, furniture/cart moves and rallies. The revised interaction contract is recorded in DESIGN.md §4.2.

Native UI validation passes 303 checks, including 44 new portrait/landscape camera, touch, mouse and single-cell confirmation regressions. The rendered single-door preview was inspected. Unit/content checks and the Meadow Reach real tutorial flow (22 checks) pass. Older construction fixtures now explicitly select their intended coordinates. Physical Android feedback validation remains pending.

On resume, the previous `a0a9fe1` workflow was observed passing on all four desktop targets, including Intel Mac, and publishing its development APK. The preserved unreachable-bed reproduction still takes approximately 3.0 seconds for one tick locally. That hotspot and the remaining full Charter campaign evidence are the next work.


## M6 unreachable-bed recovery and route performance — 13 October 2026

Version `0.6.5-m6`, Android code 25, unchanged schema 20. A binary heap replaces repeated full frontier sorts in A*, retaining f/h/row-major ordering. Forty frozen obstacle/directed-edge maps reproduce their exact old routes. The preserved Reed Bend slow tick falls from 3.016 seconds to 0.558 seconds with identical canonical state.

When an assigned bed has no route and the resident occupies safe walkable ground, the resident now rests there for this sleep period instead of repeatedly generating failed sleep jobs. The assignment remains, the visible activity explains clearing access or reassigning, and ground rest uses exactly 80 points/hour with no assigned-bed memory. Actual bed position/health is checked for rest credit. This deliberate rule clarification is recorded in DESIGN.md §5.2. Five new scheduler/save regressions cover fallback, exact rest, stable job count, truthful memories, recovery and ordinary reachable-bed sleep. The old pure-rate fixtures now place their sleepers at their actual beds.

All 28 GDScript suites pass 1,310 checks, including 303 native UI checks. Frozen replay retains all 64 commands, tick-7,200/tick-72,000 goldens, 234 invariants and foreign-host saved-world continuation (166 seconds locally). No golden or committed foreign save was replaced. Ordinary Charter continuations are running from the four retained quota-stop reports.

The user also reported periodic gameplay freezes. Local profiling identifies synchronous persistence as a separate material hotspot: a new colony checkpoints in 3–6 ms, but the preserved day-35 campaign takes 2.26–3.39 seconds per checkpoint and about 21 ms to copy its state. Periodic saving still runs on the drawing thread at this checkpoint; moving that work off-thread with verified recovery and lifecycle coordination is the immediate next fix.


## M6 periodic-save stutter correction — 13 October 2026

Version `0.6.6-m6`, Android code 26, unchanged schema 20 and envelope/journal formats. The user reports periodic freezes on a physical Android phone, including fresh colonies. A fresh generated map already has a 447 KB snapshot; synchronous checkpoints took 53–102 ms on Apple M5 Pro before this change, growing with the journal. The preserved day-35 colony took 2.26–3.39 seconds per checkpoint. These local measurements explain a material cause but do not certify phone frame times.

Periodic saves now capture a deep immutable state copy and run serialization, filesystem writes, readback and validation on one worker. The live simulator retains commands accepted after capture. Explicit saves and lifecycle/campaign operations join the writer; storage errors preserve the existing Retry/Export/Continue flow. One-second captures and a visible 1.75-second durability guard preserve the existing loss bound without blocking drawing while storage is slow. DESIGN.md §22.1 records the concurrency and recovery contract.

Checkpoint verification checks the exact earlier-prefix digest and parses the newly written tail, avoiding repeated JSON parsing of all older complete states. Immutable generations already decoded by this writer use exact byte hashes before pruning; changed files still receive full validation and corrupt evidence remains. No snapshot schema, world state, replay golden, content number or save limit changed.

Persistence passes 60 checks, including controlled concurrent progress, exact recovery, later-command retention, write failures/retry, journal-prefix corruption and generation-cache corruption. Native UI, prototype integration/unit checks, content validation and all three real tutorial flows pass. The Android debug APK builds locally; new physical-phone smoothness remains unverified. A 12-second fresh-map foreground CPU profile completes 120 ticks with no storage pause/error: p95 game callback 1.14 ms and maximum save-capture cost 1.75 ms. One 84 ms callback remains; a separate cold reachability rebuild measures 62–65 ms and is the next CPU hotspot to investigate. CPU callback timings are not GPU/frame-rate certification.


## M6 reachability spike correction — 13 October 2026

Version `0.6.7-m6`, Android code 27, unchanged schema 20. Rebuilding reachability now uses packed passability, bridge and visited cells plus a bounded integer queue, avoiding repeated structure scans and per-neighbor water/height queries. Built bridge lookup shares the existing navigation invalidation. The debug tile dictionary is materialized only when inspected. Actual movement, river/height rules and resident-seeded components are unchanged.

The exact full-map reachability bitmaps match the original authored map and all three generated sites at seed 104729. Eleven added generation checks cover those goldens, disconnected/trapped/dead/multiple resident components, wall removal and bridge destruction. A fresh generated rebuild falls from 62–65 ms to 12–14 ms locally. The same 12-second foreground profile has no callback above 50 ms (maximum 29.1 ms, p95 1.05 ms), save captures below 2.1 ms and no storage pauses/errors. These are local CPU measurements, not physical Android certification.

All 28 GDScript suites pass 1,345 checks, including 311 native UI checks. Frozen replay preserves all 64 commands, both reviewed hashes, 234 invariant checks and the foreign-host save continuation (150 seconds locally). The original replay inputs, hashes and foreign save remain unchanged. The placement-fix workflow `2aa63df` is now observed passing on all four desktop targets and publishing its downloadable APK. Async-save and spatial-fix workflows are separate later revisions.

The Meadow Reach ordinary vegetarian trace has now earned all five stages, completed its ceremony at tick 271,801 and used Continue settlement. Its saved day-41 state remains healthy with more than nine food days. Final continuation verification remains running. The Pine/Reed runs exposed residents unable to reserve an eating task while another person sleeps on the shared cart tile; that needs-priority defect is the next campaign correction.


## M6 shared-tile meals, raid-history saves and first completed campaign — 13 October 2026

Version `0.6.8-m6`, Android code 28, unchanged schema 20. An eating task now reserves its real portion without reserving a productive work position. Two travelers can eat separately while someone rests on the cart tile; eating also does not block productive work there. This fixes a reproduced ordinary-campaign needs deadlock. Five new scheduler checks cover independent food reservations, actual consumption, no starvation, mid-meal save and exact continuation. The obsolete failed-meal-position fixture now checks that sharing creates one meal task without repeated canceled attempts. DESIGN.md §5.2 clarifies the existing safe-in-place behavior.

A second real-campaign failure rejected saves containing a canceled earlier raid payment after a retry changed the raid's current payment ID. Canceled unowned history may now refer to its original real raid; live/completed payments must still match the raid's current job. Missing raids and unlinked active jobs still reject. Five added defense checks cover rejection, cancellation, retry, exact reservations and strict malformed-state handling. The previously rejected Meadow/Pine snapshots decode to their original report hashes with no edits to items, history or world state.

Affected suites pass 503 checks plus 311 native UI checks. Ordinary-command replay was deliberately recaptured after the eating correction changed job allocation: the same 64 command times/actions/accepted receipts remain, with only the real raid target ID updated from 4000 to 3993. The reviewed tick-72,000 golden is `68b17b7d2877566ab5e3318216e5236d258c441cc0de3f3dc8f2d8806927c70f`. Recording and an independent 139-second verification both pass 234 invariants and saved-world continuation. The original tick-7,200 foreign save remains byte-for-byte unchanged. Fixture provenance explains the change.

The full ordinary vegetarian Meadow Reach Charter now passes through tick 316,800 (Day 45), with all five stages, the ceremony at tick 271,801, Continue settlement and more than six subsequent game days. The final snapshot verifies exactly; 1,050 invariant checkpoints pass. Eight residents remain alive, minimum health is 100, no starvation-grace exceedance occurs, and the final stock has 204 portions with 9 days 05:45 stored runway. Meat/leather consumption remains zero and Husbandry is unresearched. The retained lineage includes 3,908 zero-fullness citizen-ticks within grace, so this is not a zero-hunger certificate. Final canonical `fc0c571da69ae1bd0694b6f529cab8227c9d91a71894c2f310b67c449728239b`; artifacts use `reports/charter-verified-20261013-meadow`. Other Standard sites and Hearthside continue from retained verified saves.


## M6 expedition preparation needs — 13 October 2026

Version `0.6.9-m6`, Android code 29, unchanged schema 20. Real Pine/Reed traces could wait for days because dispatch requires fullness/rest 500 while ordinary needs activate at 350/300. Selected travelers now seek ordinary physical meals at fullness 500 and sleep at rest 500 during Preparing/Ready, returning to the cart afterward. They spend real portions, work, travel and rest time; normal wake rules and all hard departure/health requirements remain. Home residents retain the ordinary thresholds, cancellation restores them, and departure still needs its separate explicit action. The status card explains preparation behavior. DESIGN.md §14.1 records this clarification.

Seven added expedition checks cover the threshold, unchanged home needs, mid-preparation save, actual rest/food, real readiness, separate departure and cancel recovery; a native UI check covers the explanation. All 28 GDScript suites pass 1,363 checks, including 312 native UI checks. A fresh 145-second frozen replay verifies all 64 accepted commands, 234 invariant checkpoints, both reviewed hashes and continuation from the unchanged foreign save. Catalog validation and diff checks pass. Physical phone retesting remains separate.

The other ordinary campaigns were frozen only after their report and snapshot SHA-256 matched, preserving their exact initial/final files and command lineage. `reports/preparation-checkpoint-preservation.json` records those checkpoints. Current continuations use `reports/charter-prepared-20261013-{pine-standard,reed,pine-hearthside}`. Meadow's completed, verified Charter remains recorded above.

The placement/camera/periodic-save/reachability build `7291234` is now observed passing remote CI on all four desktop targets and publishing [its Android APK](https://github.com/maccam912/brackenward/releases/tag/dev-729123473caf). Later campaign corrections have separate pending workflows. M6 still needs the remaining site/mode Charter completions. An audit also found ordinary meals still eating at their pickup/original work location instead of using available nearby table seats; §5.2 requires that physical dining behavior, so it remains implementation work. Final art/animation/audio, accessibility/rebinding, release stress/balance and physical/human gates remain M7 work. Latest observed weekly remaining: 98%.

## M6 physical table dining and seasonal scenario planning — 13 October 2026

Version `0.6.10-m6`, Android code 30, unchanged schema 20. Ordinary residents now reserve a real portion, fetch it, carry it to a free table seat within 12 safe path tiles of pickup, and eat for 2 WU before consumption. Selection uses actual path distance, table ID and row-major seat ties. Other active tasks and communal suppers keep their seats. Without an eligible table, the resident eats at pickup. Food, work and nutrition rates are unchanged. Nineteen dining checks cover physical carrying/consumption, safe routes, cliffs, the distance boundary, seat reservations, exact saves and continuation of an unchanged earlier M6 save.

The scenario planner cancels packing when a destination closes for the season, using the public cancellation command and real cargo refunds. It considers open destinations and quotes smaller eligible parties where capacity permits. Four policy tests distinguish queued public actions from test-fixture setup; this planner correction changes no game rules. Pine/Reed/Hearthside continuations retain their original acknowledged states and lineage; `reports/dining-checkpoint-preservation.json` records the verified copies.

All 28 GDScript suites pass 1,386 checks, including 312 native UI checks; all three tutorial flows pass 22 checks each. A fresh ten-day ordinary first-week run passes with all 62 public commands accepted and an exact final snapshot. Physical dining changes work timings, so the previous frozen schedule no longer met its Farming prerequisite. The new trace retains those 62 ordinary commands with strict accepted receipts. Recording and independent verification pass both checkpoints, 234 invariants and foreign-save continuation (139 and 152 seconds). The old foreign bytes are separately retained as `m6-before-table-dining-7200.brackenward`. Fixture provenance records source and current hashes. Remote CI and physical phone behavior of this new revision remain separate.

A 30-run Standard first-Winter release sweep has started across all three sites and ten fixed seeds each, including the six boundary/golden seeds. No gate is claimed before results. Late Reed profiling identifies a further real CPU hotspot: on the preserved day-35 world, 20 ordinary ticks take 1.416 seconds, chiefly repeated agricultural scans over 15,075 historical jobs (838 ms), followed by assignment (350 ms). The instrumented and normal simulations match exactly. History-preserving job-query optimization is the next performance task. Latest observed weekly remaining: 97%.

## M6 unfinished-work query performance — 13 October 2026

Version `0.6.11-m6`, Android code 31; schema, catalogs and replay goldens unchanged. Crop job creation indexes unfinished operations once instead of scanning all historical jobs for every field. The world keeps a derived append-only query list for unfinished work; same-tick additions, cancellation and completion remain visible, queries preserve original order and return separate lists for caller sorting. A new tick prunes ended references, imported/replaced/shrunk arrays rebuild, and every historical job remains in the authoritative save. Active-only scheduling queries now use that view across construction, care, animals, expeditions and other systems. This cache changes no task priorities, work, route, IDs or saved state.

Twelve added scheduler checks cover 5,000 retained historical tasks, blocked/ready jobs, same-tick additions and terminal transitions, nonterminal release, caller isolation, array replacement/clear, snapshot import and duplicate crop operations. All 28 GDScript suites pass 1,401 checks, including 312 native UI checks. Fresh frozen replay passes 62 accepted commands, both unchanged canonical goldens, 234 invariants and exact foreign-save continuation (156 seconds). Catalog/media validation passes.

The preserved day-35 Reed snapshot's same 20 ticks fall from 1,416 ms to 177 ms locally, with identical canonical state `bb91d1e4a4324827fb3a2dae1b1868d9f4520a5fd3f2728ac2597ba842fa8eb7`; the instrumented simulator also matches. Fresh-map foreground profiling completes 120 ticks in 12 seconds, p95 callback 1.394 ms, maximum 35.921 ms, captures below 2.4 ms, no storage pauses/errors. These remain CPU measurements, not physical-phone frame-rate certification.

The old 10 MiB campaign still has a separate saving limit: its 12-second foreground profile pauses simulation once to protect the durability bound, advances 18 ticks, has two callbacks above 50 ms (maximum 98.605 ms), and takes up to 47.422 ms to capture state. The background writer does not lose progress or report an error, but long-save copying/validation needs further optimization; this is not a completed late-game performance gate.

The ordinary scenario planner also detects spoiled cargo after a completed packing job and cancels through the public command before preparing again; it does not cancel unfinished packing. Three policy checks cover physical packing, natural spoilage/ledger conservation and the queued cancel. Other site/mode campaigns continue from the exact checkpoints in `reports/job-query-checkpoint-preservation.json`. Latest observed weekly remaining is 96%, so work continues.

## M6 large-save serialization work — 13 October 2026

Version `0.6.12-m6`, Android code 32, unchanged schema/envelope/journal formats and frozen replay bytes. Schema field checks use native dictionary membership with exact counts instead of allocating, stringifying and sorting two lists for every record. An extra/missing/substituted or incorrectly typed field key still rejects. Decimal-string ID conversion uses the same 55 field names in a constant membership set. Snapshot envelopes wrap the same canonical payload as before.

Once an encoded state is known to exceed a journal frame, subsequent progress goes directly to a verified immutable snapshot instead of first serializing that same oversized state into a rejected journal frame. This derived hint follows the isolated writer and resets when a campaign slot changes or a later smaller snapshot is encoded. No save size, durability or corruption checks were relaxed. Existing large-history failure/recovery tests still preserve previous files and acknowledged commands.

All 28 GDScript suites pass 1,404 checks, including 312 native UI checks. The fresh native replay passes 62 commands, both unchanged goldens, 234 invariants and foreign-save continuation (153 seconds). `tools/profile_persistence.gd` isolates copying, JSON, pack/unpack, schema, invariants, verified writes and exact recovery in a temporary directory. The unchanged 10.5 MB Reed snapshot's checkpoint falls from 2,199 ms to 1,532 ms locally; schema validation falls from 445 ms to about 331 ms and encoding from 528 ms to 479 ms. All profiled recovery states match exactly.

This is not a completed late-game performance fix. The same 12-second foreground run still triggers one protective pause: 18 ticks, p95 callback 8.128 ms, maximum 93.349 ms, and capture up to 47.530 ms. Full-state encoding/validation still limits long-colony durability throughput. Further work must retain exact acknowledged state and the existing loss bound rather than hiding the pause. The table-dining revision `c92e500` is now observed passing remote CI and publishing its development APK; later revisions have separate workflows.

Two additional asynchronous size-hint tests verify that a stale conservative hint rotates safely, refreshes from the actual smaller payload and returns to journaling. Persistence now passes 63 checks. The local debug APK export succeeds with verified package metadata `0.6.12-m6` / code 32; the four Kotlin tests pass. No new phone execution is claimed.

## M6 exact delta checkpoints and preserved recovery evidence — 13 October 2026

Version `0.6.13-m6`, Android code 33, unchanged schema 20 and catalogs; development envelope format 5. Periodic tick markers now hold exact data patches against the previous acknowledged state instead of serializing the whole history every second. Dictionary edits, changed records and ordered array prefixes retain every authoritative record. Each marker checks the campaign, base tick and parent digest; scalar integer updates and record-order IDs preserve decimal spelling. Written tails must reproduce the immutable capture exactly before acknowledgment. Recovery folds the chain without rerunning gameplay, then fully validates schema, references and conservation. Frame, journal, tick-range and snapshot-growth limits still rotate to a verified full snapshot.

Original format-4 snapshots/full-state journals restore exactly and receive untouched backups before the next format-5 generation. The foreign format-4 replay fixture remains byte-for-byte unchanged, as do both canonical goldens. Missing/changed base snapshots, missing journals, unanchored prefixes, torn writes, foreign chains, invalid record layouts and mismatched parents fail without acknowledging new progress. Pruning now binds its cache to both snapshot and journal bytes, retains damaged pairs, and deletes a journal only alongside an intentionally pruned verified snapshot. Unexpected orphan journals remain evidence. This repairs an audit finding where later rotation could remove a damaged journal whose snapshot still decoded.

All 28 GDScript suites pass 1,433 checks, including 87 persistence and 312 native UI checks. Three real tutorial flows pass 22 checks each. Fresh frozen replay passes all 62 accepted commands, both unchanged goldens, 234 invariants and foreign-save continuation (157 seconds). Catalog/media validation passes. The local APK exports with verified `0.6.13-m6` / code 33 package metadata. Placement action widths follow actual font metrics; the inspected door screenshot shows the full Cancel/Confirm/Pan labels and a one-cell preview.

On the unchanged 10.5 MB Reed save, the final verified checkpoint measures 189 ms versus 1,532 ms at the previous checkpoint and 2,199 ms before serialization work. Exact recovery passes. The 12-second late-colony foreground run completes 120 ticks with no storage pause/error, versus 18 ticks previously. Remaining capture and completion costs are still visible: capture reaches 47 ms and completion about 50 ms, producing occasional callbacks around 95 ms. The 60-second run also reaches one protective pause during a periodic full snapshot, advances 311 ticks, and has a 208 ms maximum callback. These are local CPU measurements, not a physical-phone or completed long-game performance gate. Releasing old payloads off-thread, reducing capture allocations and coordinating full-snapshot preparation are next work.

The ordinary planner now includes an eligible cook when real cargo capacity requires four travelers and the enlarged home forecast still permits it. Storage expansion uses up to two normal sixteen-tile stockpile commands when hauling explicitly reports no space, protecting existing fields, furniture, table seats and planned rooms. Eight active-only planner queries avoid rescanning old jobs. Five additional policy checks pass, and a fresh ordinary ten-day first-week source has exactly the same canonical state and all 62 commands as its prior source. No resources, skills or needs are granted.

The full Hearthside vegetarian Charter now passes through tick 619,200 (Day 87), all five stages, ceremony completion at 581,101 and Continue settlement with over five later days. Eight residents remain alive, minimum health 100, no starvation-grace exceedance, and 2,058 invariant checks pass with an exact final snapshot. Canonical `e89ab3b4364dfc1011c4adc478847f8ebd0f11cf6f8ece347a7d66d295d165c1`; artifacts `reports/charter-planner-20261013-pine-hearthside`. Standard Pine has reached Connection but a resident still uses a bedroll while a completed roofed bed is unassigned. The game currently lacks a reassignment control; that remaining needs/UI gap is next. Reed and the 30-run Winter sweep continue, with six Meadow boundary-seed runs currently observed passing.

Remote CI `7d648ec` passes all four native targets and publication. The `3820789` Linux/Apple Silicon/Intel Mac replays/startups and main build/tests pass, but its first Windows native launch exits with access violation while using ANGLE over the hosted Microsoft Basic Render Driver. Its replay passes; publication is blocked by the startup failure. The Windows launch and publication pass on one failed-job retry; the initial access-violation log remains retained and its underlying cause is unconfirmed. The new format-5 revision has its own forthcoming workflow. Latest observed weekly remaining: 95%, so implementation continues.

## M6 visible-camera stability and capture cleanup — 13 October 2026

Version `0.6.14-m6`, Android code 34, unchanged schema 20, envelope 5 and catalogs. Free-camera layout now preserves the actual viewport center as guidance, inspectors and placement panels change their focus offsets. Entering placement from a following resident restores the view from before the Build sheet, stops following, and initializes the preview after layout. Device preferences save that actual visible center. Thirty-two new native checks cover both phone orientations, active guidance, map edges, fractional centers, inspector changes, cancellation, following and preference restoration; existing placement/gesture checks remain.

The save thread now binds a small request holder and releases its large capture before returning. Replaced acknowledged baselines and command evidence retire on the next writer instead of being destroyed during the foreground completion callback. Captures reuse exact unchanged records and native-compared 256-record blocks; all owned nested arrays/dictionaries are read-only, and mutable live data never crosses the thread boundary. Loading/adoption primes the first capture while paused. Eleven new persistence checks cover ownership, nested changes, record additions/removals/reordering across blocks, Chronicle growth, same-campaign world replacement and mutable exact delta reconstruction. Existing gated-writer tests still prove capture isolation, later-command retention and verified recovery/failure behavior.

All 28 suites pass 1,476 checks, including 98 persistence and 344 native UI checks. Three real tutorial flows pass 22 checks each. Catalog/media validation and local Android export pass; package metadata is verified as `0.6.14-m6` / code 34. The independent frozen replay passes all 62 accepted commands, both unchanged goldens, 234 invariants and foreign-save continuation (132 seconds).

On the unchanged 10.5 MB Reed fixture, the 12-second foreground run advances all 120 ticks with no storage pause/error. Main-thread capture is 15–18 ms rather than roughly 40–47 ms, and completion is at most 0.13 ms rather than roughly 50 ms. A fresh generated colony advances all 120 ticks with 1.44 ms maximum capture and 26.6 ms maximum callback, no callback over 50 ms and no storage pause/error. The 60-second late-colony run still reaches one protective pause during full snapshot rotation: 312 ticks, capture at most 19 ms, completion at most 1.01 ms, callback at most 189 ms, and no storage/invariant error. Full-snapshot coordination remains performance work. These Mac CPU measurements do not certify the user's physical Android phone.

Remote format-5 checkpoint `f434972` now passes the full workflow, all four native replay/startup targets and [APK publication](https://github.com/maccam912/brackenward/releases/tag/dev-f434972d0f79). Current source has its own subsequent workflow. Weekly remaining last observed 94%; work continues toward bed reassignment, remaining campaign gates and release quality.

## M6 bed assignment and reachable maintenance — 14 October 2026

Version `0.6.15-m6`, Android code 35, schema 21, unchanged envelope 5 and catalogs. Resident cards, map inspectors and bed cards now expose actual assignment/unassignment. Confirmation names the bed and location; occupied choices name their owner, and unsafe, burning, destroyed, away or unreachable cases explain recovery. Applying the public `assign_bed` command frees the previous bed and reserves the new one without moving residents, granting rest or changing goods. Existing sleep tasks retarget physically while preserving fractional edge movement. Exhausted residents keep safe-ground sleep for this rest period; downed patients are not moved. Consecutive assigned-bed sleep resets; already earned timed memories remain. New arrivals prefer roofed beds, then outdoor beds, roofed bedrolls and outdoor bedrolls, with stable ID ties. Nineteen needs/population/save checks and sixteen native UI checks cover these behaviors, including 150% text in both phone orientations. Native confirmation screenshots were inspected.

Schema-20 migration changes only the revision header; no resident, bed, geography or history is edited. The original foreign tick-7,200 bytes remain unchanged. Both recorded replay checkpoints, with only the revision header restored to 20, reproduce their complete previous canonical hashes. The same 62 commands and accepted receipts remain. The pre-dining regression likewise verifies every acknowledged field under its original header before continuing under current rules. Scenario resume checks the original report against the validated envelope's exact payload digest, then uses the explicit forward migration; original report and save files remain untouched.

The ordinary planner now assigns spare real beds through the public command. It protects existing/planned door approaches when choosing new rooms and can order real demolition work for the specific adjacent-lodge layout found in old traces. A regression reproduced the blocked door at Pine (60,70), with another lodge's wall at (60,71). It also exposed a game defect: an outside builder always chose the nearer sealed side of a maintenance target, repeatedly failing its route despite a reachable other side. Home-reachable repair/demolition workers now skip work positions outside their reachable home component. Trapped workers retain their inside work option. Two scheduler checks cover both directions; nine planner checks include actual demolition, recovered material conservation and both rooms remaining roofed and reachable.

All 28 suites pass 1,522 checks, including 57 population, 69 Charter/planner, 75 scheduler, 98 persistence and 360 native UI checks. All three real tutorial flows pass 22 checks each, and catalog/media validation passes. The independent 145-second replay passes the same 62 commands, both schema-21 goldens, 234 invariants and unchanged foreign-save continuation. Final Android export and four Kotlin tests pass; package metadata is verified as `0.6.15-m6` / code 35. The full-snapshot performance pause and remaining site/mode campaign gates stay open. `bed-access-checkpoint-preservation.json` records the exact retained Pine/Reed continuation inputs; only task-owned CLI runs were stopped. The first Pine repair attempt published no new daily checkpoint before its blocked-work-position defect was corrected, so its unchanged tick-439,200 source is retained. Reed's verified tick-453,600 daily checkpoint is preserved. Current continuations are `charter-access-20261014-*`, using ordinary public commands and no state grants.

Remote `e40f11b` passes all four native replay/startup targets, build/tests and development APK publication. Weekly remaining last observed 93%; implementation continues. Physical Android performance, human comprehension, final art/animation/audio, accessibility/rebinding and remaining release gates are still pending.

## M6 full-snapshot preparation without durability pauses — 14 October 2026

Version `0.6.16-m6`, Android code 36, unchanged schema 21, envelope 5, catalogs and replay goldens. A separate worker now encodes and fully validates an immutable full-snapshot capture entirely in memory. The single disk writer continues ordinary delta checkpoints while preparation runs. At rotation it first checkpoints its newest capture on the old chain, retains intervening public-command evidence, and writes an exact catch-up delta against the prepared payload digest. Both staged files receive exact read-back verification. Publishing the catch-up journal before its snapshot prevents recovery from selecting the older preparation tick without the latest captured progress. Previous valid generations remain until the replacement pair verifies. Recovered worlds still receive full schema/reference/invariant validation.

The sequence allocator reserves orphan journals and staged snapshot/journal files, so a later retry cannot overwrite interrupted-rotation evidence. Explicit saves, world adoption, backgrounding and exit join/discard unused preparation and save the current world. An oversized catch-up uses an ordinary verified full snapshot. The existing 1.75-second durable-progress guard stays active. Captures remain owned/read-only and only foreground polling changes the live store acknowledgment.

Twenty-three new persistence checks cover full preparation validation, mutable/invalid-source rejection, exact catch-up and pending-command continuation, retained intervening command evidence, payload/campaign mismatch, failed publication with the old chain still at the newest tick, retained orphan/staging evidence, safe sequence retry, ordinary checkpoints during a deliberately gated slow encoder, exact capture acknowledgment and later-command retention. Four additional real UI checks cover periodic preparation, concurrent ordinary durability, joining preparation on background and returning paused. The final local set comprises 27 headless suites plus the isolated native UI suite: 1,549 checks, including 121 persistence and 364 UI, zero failures or engine errors. An initial native rerun exposed an allocator directory-list error in the existing intentional file-as-directory failure fixture; it now returns the normal save error without an engine error, and the storage/UI suites pass again. An overlapping local native test launch also blocked a gated test on focus loss; the task-owned run was stopped and the final UI run was isolated. Original failed logs remain evidence; no test retry was added to CI.

The 60-second preserved 10.5 MB Reed foreground run advances all 600 ticks with no storage pause/error, versus 312 ticks and one protective pause before preparation. A 120-second run completes 1,200 ticks and three preparations/rotations with no storage pause/error or invariant failure. Its maximum capture is 28.2 ms, preparation capture 15.9 ms and completion 0.93 ms; callbacks still reach 204 ms in the older large simulation, so simulation/rendering optimization remains open. A fresh generated colony advances all 650 ticks over 65 seconds, crosses two preparations/rotations, has 1.61 ms maximum save capture, 0.99 ms preparation capture, 0.67 ms completion and 28.5 ms maximum callback. It has no callback over 50 ms and no storage/invariant error. These are Mac CPU measurements, not a physical-phone/GPU certificate.

The independent 147-second frozen replay passes all 62 accepted commands, both unchanged schema-21 goldens, 234 invariants and the unchanged foreign-save continuation. Catalog/media validation and final Android export pass, including four Kotlin tests; package metadata is verified as `0.6.16-m6` / code 36. Pine Standard has now earned all five stages, completed its ceremony at tick 440,401 and used Continue, with eight residents, minimum health 100 and no starvation-grace exceedance; the ongoing ordinary continuation is checking later days. Reed retains its earlier lineage's minimum health 64 and 4,965 starvation-grace-exceeded citizen-ticks, with no increase observed through tick 475,200. That historical limit must accompany any eventual Reed Charter certificate. The 30-seed Winter sweep is a separate current-code/provenance audit, with 17 completed runs currently observed passing.

Remote bed/access checkpoint `3375a84` now passes all four native replay/startup targets, build/tests and development APK publication. Current preparation source has a subsequent workflow. Latest observed weekly remaining is still 93%; implementation continues.

## M6 live-inventory queries and drawing cost — 14 October 2026

Version `0.6.17-m6`, Android code 37, unchanged schema 21, envelope 5, catalogs, frozen input and goldens. Depleted stacks remain complete authoritative history. Runtime transfers create new records, and physical storage merging only targets a still-positive record; depleted records never refill. A derived append-only query scans new records, retires depleted references, preserves source order and returns a fresh caller-owned list. Imports and frozen worker worlds reset the cache. No history, quantities, locations, ages, reservations, IDs or ledger entries are compacted or rewritten.

Food aging/forecasts/selection, quantity totals, active production/input choice, equipment/animal/trade candidates, hauling destination accounting and physical storage merging use the nonempty view. Mutation/reference validation loops retain their full-history scans. Work creation uses the existing unfinished-job query where it already excluded terminal jobs. World drawing uses unfinished work and nonempty goods instead of rescanning all historical records each frame. Eleven new checks cover 5,000 depleted records, same-tick creation/consumption, caller sorting/clearing, live physical merging without tombstone revival, unchanged payload hashes, full-history save imports, array replacement/shrink and exact spoilage/ledger behavior.

All 28 suites pass 1,560 checks, including 86 scheduler and 364 native UI checks. A fresh 140-second frozen replay passes the same 62 accepted commands, both unchanged schema-21 goldens, 234 invariants and original foreign-save continuation. Final storage-merging/destination changes also pass the targeted scheduler, production and eight-day survival checks.

On the same preserved Pine tick-439,200 fixture, 20 ticks fall from 309.8 ms to 128.0 ms, with exactly the same final canonical `662b27df1d2f735b0500c8ce12dd11af4d8536e956e63b1a5a86f8e1b7485e7a`. The instrumented and normal worlds match. Work creation's two calls fall from 107.4 ms total to 24.3 ms; food/living time falls from 80.7 ms to 26.2 ms across 20 calls. The 120-second Reed foreground run advances all 1,200 ticks with three preparations and no storage pause/error or invariant failure. Median callback falls from 4.50 ms to 0.65 ms; p95 is 18.2 ms and seven callbacks exceed 50 ms, with a 223 ms maximum. Those remaining spikes and physical Android smoothness remain open. The measurements are Mac CPU scope, not GPU/device certification.

The ordinary Pine and Reed continuations retain their original sources and current progress. Pine has all stages, ceremony and Continue with no starvation-grace exceedance; Reed has now prepared and dispatched the real four-person causeway trip with exact supplies and a full readiness band. The separate first-Winter sweep has 20 of 30 runs observed passing, with source-provenance review still required. Local Android export passes with four Kotlin tests and verified `0.6.17-m6` / code 37 metadata. Remote `1b6f2d7` remains in progress; this source has its own subsequent workflow. Latest observed weekly remaining: 93%.

## M6 geometry spikes and completed site campaigns — 14 October 2026

Version `0.6.18-m6`, Android code 38, unchanged schema 21, envelope 5, catalogs and replay inputs/goldens. Room flood fill uses packed visited cells and one preallocated row-major queue, preserving neighbor order, component IDs, the 64-tile limit, open/water behavior and built-in roof precedence. Forty geometry fingerprints were frozen from the old algorithm before editing, across authored geography and three generated sites. They cover 64/65 tiles, partitions/doors, removed walls, map edges, water/bridges and built-in roofs, including insertion order. All match. The same Reed room-map digest stays `82c3b0ffb0141279f5dadd8dac58fd19f3681429b420da2f3426957`; median uncached computation falls from 17.6 ms to 9.63 ms, with unchanged authoritative state.

Per-phase foreground tracing identified hourly wildlife wandering as a remaining 112–118 ms spike: every tested tile rescanned all building footprints. A navigation-derived occupied-building mask now preserves the distinct animal rules in constant-time lookups. People still traverse furniture/doors; wildlife avoids them, while floors/paths/bridges remain usable. Build/dismantle/move/destroy and import invalidate the view. Ten new wildlife checks use actual furniture movement, immediate dismantling/rebuilding, door destruction, imported geometry and a river bridge. Existing positions/streams, crop bites, hunting, fencing and save continuations remain covered.

The trace also identified a 159 ms failed assigned-bed route. Walkable endpoints on opposite sides of the known home component now return the same no-route result without a full A* search. The request still consumes its normal slot, and ground fallback retains its exact rest rate/assignment/explanation. Unknown components and obstructed starts retain A*; two new checks prove budget preservation and stepping out from an obstructed tile. Full schema restoration explicitly invalidates all geometry caches.

The final local set passes 1,613 checks across 28 suites: the 1,611-check complete run plus the two subsequent scheduler regressions, with the final scheduler (88), colony and region suites passing after the route shortcut. Native UI passes 364 checks. The independent final 103-second replay passes all 62 accepted commands, both unchanged goldens, 234 invariants and original foreign-save continuation. `profile_foreground.gd --trace-spikes true` optionally reports inclusive phases and slow jobs; normal profiling remains available. In the same late-colony 65-second traced run, all 650 ticks complete without a storage pause/error. Wildlife's maximum falls to 2.73 ms and no job exceeds 10 ms. Maximum callback falls from about 197 ms to 51.6 ms, with one callback over 50 ms; p95 is 16.7 ms. Physical phone and release stress results remain separate.

Pine Standard's full ordinary vegetarian trace passes through tick 489,600, ceremony 440,401 and almost seven later Continue days, with eight living residents, minimum health 100, no zero-fullness or starvation-grace exceedance, and 1,626 invariant checkpoints. Canonical `910fb2328b22d2f878ec2ccb7e1c73452983b8f9d9ae99969dc1174601f164ad`. Reed Standard now also passes through 583,200, ceremony 535,201 and almost seven later Continue days; eight residents are currently at 100 health and 1,938 invariants pass. Canonical `4b93eb710af1c3e036029c17a8a051fcf7ee58fede772fe37d7bdcb3e4b7b31d`. Reed's historical minimum health 64 and 4,965 starvation-grace-exceeded citizen-ticks remain recorded, with no increase in the latest continuation. No counters or state were reset to obtain a pass.

All three Standard sites plus Pine Hearthside now have full local vegetarian Charter/ceremony/Continue evidence, meeting the M6 campaign subset. `7089f14` passes all four native replay/startup targets and APK publication; `1b6f2d7` also passes. Current geometry source has its own subsequent workflow. The separate mixed-source Winter sweep currently has 24 of 30 observed passes and still needs provenance/current-source review. M7 original art/animation/audio, accessibility/rebinding, release stress/balance, physical Android and human gates remain open. Weekly remaining last observed 92%; implementation proceeds into release quality.

The final fresh-colony 65-second traced run advances all 650 ticks, crosses two preparations, and has no storage/invariant error or protective pause. Maximum callback is 18.6 ms (none over 50 ms), save capture 1.92 ms, preparation capture 1.11 ms and completion 0.68 ms. Final Android export passes with four Kotlin tests and verified `0.6.18-m6` / code 38 metadata. The final route-sensitive colony/region/scheduler suites pass after the shortcut. M7 work follows this checkpoint; no physical-phone performance certificate is claimed.


## M7 original citizens and migration checkpoint — 14 October 2026

Version `0.7.0-m7`, Android build 39, adds eight original adult clothing silhouettes,
eight independent hair shapes, six skin colors, eight hair colors and independent
eight-color coats/scarves. The shared indexed atlas authors all 99 poses for each
body/hair combination: all thirteen states and the specified four-direction states.
Movement follows authoritative grid progress, action frames follow actual jobs, and
visual rates cap at 10 fps at 4×. Real tools and task hats render separately. Hurt,
downed, sleep, meal, supper conversation and the Charter cheer have distinct states.
No animation callback affects simulation completion. Portraits use the same clothing,
hair and palette at 64 pixels. Eight original trait pictograms appear with labels.
Editable source, original-asset provenance, exported masks, layout metadata and
visually inspected contact sheets are retained in the repository. M0's frozen SVG
travelers remain for prototype regression only. Animal/environment animation and
final audio are still outstanding; this is a character-art subset of M7.

The resident Appearance action opens a Style card. Changes preview locally, Cancel
discards, and Save queues one exact `citizen_appearance` command for the next tick.
Schema 22 adds only cosmetic dictionaries and a header change; deterministic defaults
consume no RNG stream, resources or entity IDs. A 100-tick comparison verifies that
changing appearance does not alter gameplay. Both old frozen replay checkpoints,
with only cosmetics removed and the old header restored, equal their exact previous
hashes. Input bytes and the original foreign-save bytes are unchanged.

A retained schema-21 snapshot plus two real command/delta checkpoints exposed the
need to fold journals against their original raw schema before migrating the final
acknowledged payload. Recovery and pruning now use that path. Tests verify every old
acknowledged field, exact original bytes and both migration backups. Malformed and
out-of-range appearance records/pending commands fail validation.

Local validation passes 1,643 checks across 28 suites: the complete 27-headless-suite
run plus corrected final population/scheduler reruns and 376 final native UI checks.
The two reruns corrected test expectations for the declared cosmetics; the dining
normalization also needed its own deep copy so it could not mutate the loaded world.
Three tutorial flows pass 22 checks each. Native GPU sampling verifies selected skin
colors; portrait/landscape 150% text screenshots were inspected. The sheet header now
stays compact, and twelve independent shape/color controls remain at least 48 dp.
Autosave lifecycle tests remain separate from the appearance fixture's UI rendering.
The final independent replay passes 62 accepted commands, 234 invariant checkpoints,
both reviewed schema-22 hashes and the retained foreign-save continuation in 100.4 s.
Tick 7200: `b90bc5f56f4270729272a1a83909868162ddf83917e9ceddac4e6185c11c0e7f`.
Tick 72000: `94c0be9713bdac78577ceca26375a44c5efdc48eafa07f4cfcd786c91f35c14a`.
Catalog/provenance validation passes 24 shipped media entries. Local Android export
passes, with four Kotlin tests and verified `0.7.0-m7` / build 39 package metadata.

The fresh 65-second foreground CPU run advances 650 ticks across two snapshot
preparations without storage pause, storage error or invariant failure. Maximum
callback 20.15 ms, none over 50 ms; maximum checkpoint capture 2.34 ms, preparation
capture 1.22 ms and completion 0.67 ms. This measures macOS callbacks, not physical
phone/GPU performance. The M6 `88ee5e8` workflow passes all four native replay/startup
targets and APK publication. The original mixed-revision 30-seed Winter sweep finished
30/30; a fresh matrix now runs against a clean managed checkout pinned to exactly
`88ee5e83861b8bd639a2237deca0fb9ae838e2a6`. The sweep utility records source/harness
provenance, exact snapshots, logs and a separate fail-closed audit. Its evidence stays
outside the frozen checkout. Current-source certification waits for that full matrix.
Weekly remaining is still 91%; authorized release work continues.


## M7 accessibility, controls and pause policy — 14 October 2026

Version `0.7.1-m7`, Android build 40, implements saved reduced motion,
high-contrast selection, pause-on-inspect (default off), graphics FPS selection,
individual automatic-pause toggles and rebinding for all fourteen keyboard actions.
Default primary keys and WASD/arrow aliases remain available; modifier shortcuts
are supported. Capture waits through modifier presses, names conflicts, cancels
with Escape or the visible Cancel control, and can restore all defaults. The pause
binding works with Button focus, while text entry keeps its normal keys. Manual
camera pan releases follow and stays blocked behind modal sheets. Every function
continues to have a touch control.

Reduced motion freezes nonessential character poses and tutorial pulses while
retaining authoritative movement and static guidance. High-contrast selection adds
light/dark outlines and crosses on invalid preview cells. Battery/Balanced cap at
30 FPS; Smooth caps at 60 with unchanged simulation. The additional particle/water
visual differences arrive with the remaining environment media. UI text colors are
explicit across button states. Actual theme-color contrast checks meet 4.5:1 for
body and normal/hover/pressed/disabled buttons; pressed violet is slightly darker
than the roof color to retain that threshold. Long titles move into the scrollable
body when they cannot fit next to Close/Pause, keeping the 48 dp top strip and full
readable title. Benign repeated pause boilerplate no longer fills those panels;
critical and error notices remain visible.

All six automatic pauses default on: downing, hostile arrival, new fire, expedition
decision, departure ultimatum and food runway below half a day. Food uses the existing
one-second foreground forecast cadence. Disabling a pause retains the notice without
forcing a modal sheet. Expedition decisions pause once per trip/state rather than
blocking every resume. Departure notices name the resident even when disabled, and
resident/inspector cards show the remaining game hours and morale-300 recovery
threshold. Inspectors optionally pause while preserving previous speed. Game ending,
Charter epilogue, storage protection and backgrounding keep their mandatory behavior.
No saved gameplay fields, simulation RNG, recipes or population rules change.

Device settings schema 3 adds only device-local presentation/control policies.
Schema-1/2 upgrades preserve all cameras, handedness, text size, last slot and
per-campaign lessons; malformed new settings retain safe defaults. Imported campaigns
cannot replace those preferences. The simulator owns only pure pause defaults;
keyboard/OS translation stays in presentation. The campaign remains schema 22 and
its frozen hashes/foreign fixture bytes are unchanged.

Local validation passes 1,697 checks across 28 suites: all 27 headless suites (1,286)
and final native UI (411). Persistence (156), care (41) and region (107) also pass
following the final notice-policy change. Native portrait/landscape 150% screenshots
were inspected, including full titles, modifier capture, at-least-48-dp controls,
disabled fire/food/departure pauses, exact departure recovery and GPU palettes.
An independent 100.2-second replay retains all 62 accepted commands, both unchanged
schema-22 hashes, 234 invariants and the original foreign-save continuation. Content
validation and local Android export pass, with four Kotlin tests and verified
`0.7.1-m7` / build 40 metadata. The fresh 65-second foreground callback run completes
650 ticks and two snapshot preparations without storage pause/error or invariant
failure. Maximum callback 20.06 ms, none over 50 ms; checkpoint capture 2.02 ms,
preparation capture 0.86 ms, completion 0.95 ms. These are macOS CPU results, separate
from physical Android/GPU/battery certification.

The previous character checkpoint `e7623d7` passes all four native replay/startup
jobs, builds and [APK publication](https://github.com/maccam912/brackenward/releases/tag/dev-e7623d78ffd0).
The pinned M6 Winter matrix currently has twelve passes with no observed failure;
it remains running. Remaining M7 work includes original animal/environment media,
audio, optional haptics, final rendering/balance/stress, and physical/human release
gates. Implementation continues under the user's weekly-usage stop rule.

All three real tutorial flows also pass 22 checks each after the device-settings upgrade. Latest weekly remaining is 90%; the next batch is audio and further release media.

## M7 audio and frozen Winter matrix — 14 October 2026

Version `0.7.2-m7`, Android build 41, adds three original 90-second music loops,
four environmental loops, three short bell/pluck cues and fourteen licensed Kenney
interface/work/door/footstep clips. The original score, deterministic synth sources,
container durations, decoded measurements and SHA-256 values are retained. Native
libsndfile/Vorbis performs Ogg encoding; no commercial samples are used. Both copied
Kenney licenses retain their exact source bytes. The manifest verifies all 48 shipped
media entries. No human-listening or physical audio certificate is inferred.

The presenter reuses twelve prioritized effect players plus three streaming music
players. Critical cues displace lower voices and duck the background; work variants
share a three-per-second cap. Footsteps require twelve-tile visible proximity. Real
work progress, door crossings, arrivals and hazards drive cues without changing any
world field, RNG stream or gameplay time. Tension starts only with active arrived
enemies, ordinary music crossfades over four seconds, and danger exit fades over
eight. A bounded monotonic presentation clock avoids losing a fresh cue after a
slow preceding frame. Music and ambient loops share stable phases.

Device settings schema 4 adds Master/Music/Effects/Interface volume and haptics off
by default. Exact schema-1/2/3 upgrades preserve existing settings; invalid keys,
nonfinite/range-invalid volumes and malformed booleans retain defaults. Imported
campaigns do not replace preferences. Touch volume sliders preserve a press until
release, distinguish horizontal adjustment from vertical scrolling, filter duplicate
emulated mouse events and retain keyboard/mouse operation. Portrait and landscape
150% screenshots were inspected; the four sliders retain 48 dp targets. Optional
Android vibration uses the normal VIBRATE permission; no network, microphone,
notification, contact, location or broad storage permission is requested.

Backgrounding stops sound before save I/O and resume takes a fresh observation
baseline without replaying old cues. Controlled exit waits up to one second for
weak playback references to clear across real AudioServer updates, failing closed
if they remain. Forced engine shutdown had exposed retained streaming resources;
its original diagnostic log is retained. The corrected native startup harness uses
an isolated temporary campaign/preferences directory, requires sixty real processed
frames and an explicit audio-drained exit marker, and treats the engine frame limit
only as a failure fallback. Final native launch and all UI teardown logs are clean.

All 27 headless suites pass 1,317 checks and the final native UI suite passes 438
(total 1,755 across 28 suites). Three real tutorial flows pass 22 each; five native
startup-parser tests and four Kotlin plugin tests are separate. The independent
82.4-second replay retains 62 accepted commands, 234 invariant checkpoints, both
unchanged schema-22 hashes and the exact original foreign-save continuation. The
65-second fresh-colony CPU profile advances 650 ticks over two snapshot preparations
with no storage pause/error or invariant failure: callback maximum 19.02 ms, none
over 50 ms; separate audio-update maximum 0.384 ms, median 0.025 ms; checkpoint
capture 2.16 ms, preparation capture 0.75 ms, completion 0.96 ms. These measure macOS
callbacks with dummy audio, not the audio thread, GPU or physical phone.

The frozen `88ee5e83861b8bd639a2237deca0fb9ae838e2a6` first-Winter sweep
finishes 30/30 at tick 239,400, all minimum health 100, no starvation-grace violations.
A separate audit verifies every exact report/snapshot pair, clean unchanged source,
all site/seed combinations, zero script/engine errors and successful process exits.
The current schema-22 upgrader also passes all thirty final saves: removing only the
declared cosmetics/header upgrade reproduces each exact schema-21 gameplay hash;
current round trips pass and source bytes stay unchanged. Detailed source/digest
evidence is in CAMPAIGN_EVIDENCE.md. The now-unused managed validation checkout
was archived after its clean-source check; raw evidence stays in this workspace.

The preceding `8b65337` checkpoint passed remote CI, all four native replay/startup
targets, exports and APK publication. This audio checkpoint's remote result is
reported separately after push. Local APK export and package metadata are recorded
after completion below. Remaining M7 work includes animal/environment media, final
rendering/balance/stress, diagnostics, localization coverage and physical/human gates.
Latest weekly remaining is 88%; work continues under the authorized stop rule.

Local Android export passes with four Kotlin tests. `aapt` verifies `0.7.2-m7` / build 41, min SDK 29, target 36, arm64 only and VIBRATE as the sole permission. Native startup, content validation and APK construction are distinct from physical audio/listening/performance.

## M7 animals and visiting people — 14 October 2026

Version `0.7.3-m7`, Android build 42, replaces animal/guest placeholder shapes with
original animation and the existing adult character system. One nearest-filtered
384x672 animal atlas contains 268 authored nonempty frames: hare, deer, boar, marsh
goose, hen, goat and merchant pack goat; four facings, two idle/eat, four walk and
one downed per facing, plus four boar charge frames. Goats share body/horns and
merchant luggage adds no world inventory, capacity or collision. Source/layout and
complete labeled contact sheet are retained. The contact sheet and actual native
960x600 map screenshot were inspected. Media provenance passes 49 shipped entries.

Movement reads exact saved edges/progress; leading livestock uses its real handler's
edge. Feeding poses follow a new real feed/bite change and do not replay earlier
feeding after adoption. Juveniles scale cosmetically; paused/reduced-motion poses
stay still, and accelerated visual cadence caps at ten frames/second. Carcasses use
a downed pose until actual butchering/spoilage removes them. Human visitors use the
shared adult atlas/palettes, travel staffs, merchant hats and visible weapons.
Bandanas are neutral; threat diamonds become a different neutral marker for stable
downed/leaving people. No character art grants or resolves an attack.

Pooled actor membership refreshes only on completed tick/world change; ordinary
render frames reuse nodes. Departures, carcass completion and campaign switches
release old views. Stable global-ID tree order resolves equal foot-y ties. Hunt
marks use the unfinished-job view instead of a full history scan for each animal
each frame; map blueprint hit tests also use that derived query. The remaining
prop/environment renderer will join these actors in the same depth order.

A native touch test exposed old map hit testing against a moving animal's previous
tile. All animal/visitor/merchant/hostile hit tests now share the visible edge
position; the real WorldView touch sequence selects a body at 90% edge progress
beyond the old tile's radius. No command, saved gameplay field, catalog or RNG
changes. All 27 headless suites pass 1,337 checks; corrected final persistence
passes 207 and final native UI passes 450, for 1,787 across 28 suites. The initial
animal fixtures incorrectly assumed the legacy map had generated wildlife; their
script-error logs are retained and the fail-closed runner rejected them. Corrected
fixtures explicitly spawn the tested animals and all final logs are clean.

The independent 74.0-second replay passes 62 accepted commands, 234 invariant
checkpoints, both unchanged schema-22 hashes and original foreign-save continuation.
Final native startup passes on Apple M5 Pro/OpenGL 4.1 with isolated sixty-frame
application exit and drained audio. Local Android export passes with the same four
Kotlin plugin tests; package metadata is checked separately below. The preceding
audio commit `78e5641` passes all CI/native replay/startup jobs and APK publication.
Physical phone performance/audio, human comprehension and original environment
media, diagnostics, localization and final stress/rendering gates remain. Weekly
remaining is still 88%; implementation continues.

Final 65-second fresh-colony CPU profile advances 650 ticks with no storage pause,
error or invariant failure: main callback maximum 19.37 ms, none over 50 ms; map
update maximum 0.74 ms / p95 0.148 ms, drawing-command callback maximum 1.44 ms /
p95 1.131 ms, audio update maximum 0.431 ms. Capture maximum 2.47 ms, snapshot
preparation capture 1.10 ms, save finish 0.78 ms. These measure separate macOS CPU
callbacks with dummy audio and are not GPU, audio-thread or physical phone results.
`aapt` verifies build 42 / `0.7.3-m7`, min SDK 29, target 36, arm64 only and VIBRATE
as the sole permission.

## M7 local performance report — 14 October 2026

Version `0.7.4-m7`, Android build 43, adds Menu > Performance report for diagnosing
the user's intermittent phone stalls. Collection stays in memory, has no network or
file I/O, and retains at most forty fixed histograms plus the latest thirty-two
callbacks over 50 ms. Measurements separate paused/1x/2x/4x and distinguish actual
wall-clock frame gaps, main session callbacks, simulation batches, map updates,
drawing commands, audio updates, save capture/preparation/completion and explicit
saves. Counts, means and maxima are exact; p95/p99 are labeled histogram upper
bounds, with null for overflow above 1,000 ms. Nested callbacks overlap and cannot
be summed. Background time is excluded, resume stays paused, reset clears only
measurements, and campaign adoption clears old measurements/preview so old events
cannot be mislabeled with a new map seed. No world field or RNG changes.

The report previews build/engine, device/OS/GPU, viewport/quality/FPS cap, seed/tick,
object counts, writer flags, engine static memory (null when unavailable), timing
buckets, slow events and fixed counters. Resident names, campaign/session IDs, save
payloads, document paths and credentials are excluded. Engine static memory is not
Android proportional-set size; these CPU/wall-clock data do not measure GPU/audio
thread, battery or thermals. Copy/export is an explicit player action; nothing is
uploaded automatically. The exact frozen JSON preview survives opening/closing its
raw view. Export caps UTF-8 bytes at 64 KiB and uses the existing verified Android
document writer or desktop picker/readback. Late callbacks from completed/canceled
requests and stale desktop dialog callbacks cannot write, import or clear a newer
operation. Completed desktop dialogs release their Nodes. Save export still uses
its own schema validation, never diagnostic JSON validation.

The native report UI passes actual 360x640/640x360 screenshots at 150% text, with
48 dp controls and vertical scrolling. Review/export/copy actions precede detailed
measurements; long explanatory text no longer pushes every action off the portrait
screen. Tests cover exact 50 ms boundaries, percentile overflow, long-session memory
bounds, separate speed buckets, report size, preview ownership, independent reset,
background clock exclusion, exact native/desktop export bytes, cancellation/stale
callbacks, no accidental import, normal subsequent save export and campaign adoption.
Final native UI passes 466 checks; persistence passes 219. All three real tutorial
flows pass 22 checks each. The preceding animal checkpoint `f62049a` passes remote
CI, all four native replay/startup targets, exports and APK publication.

The first instrumented profiler also retained an initial explicit 68.7 ms startup
save before its ordinary 65-second measurement began. Its raw log remains intact;
the profiler now resets the in-game collector alongside its other warmup arrays.
Initial timing context is seeded with the actual campaign tick before the first
frame, avoiding a misleading tick-zero label for startup actions. Final warm-run,
APK metadata and complete-suite evidence follow below. Physical phone measurements
remain pending; the report enables collecting them without inferring from a Mac.
Weekly remaining is 87%; work continues on the remaining M7 scope.

Complete local validation passes all 27 headless suites (1,349 checks) and the final
native UI suite (466), total 1,815 across 28 suites, with no failures/script errors.
Catalog/media validation remains 49 entries. The warm 65-second fresh-colony run
advances 650 ticks across two preparations with no storage pause/error or invariant
failure. Main callback maximum 20.35 ms, none over 50 ms; map update 0.706 ms,
drawing commands 1.575 ms, audio update 0.452 ms. Checkpoint capture 2.024 ms,
preparation capture 0.751 ms, completion 0.772 ms. Its in-game collector agrees: no
slow callbacks/counters, wall-clock frame-gap maximum 43.287 ms, zero over 50 ms.
The coarse p95/p99 frame-gap bucket upper is 50 ms; it is not an exact percentile
or an Android performance certificate. APK export passes; `aapt` verifies build 43
/ `0.7.4-m7`, min SDK 29, target 36, arm64 only and VIBRATE as its sole permission.

## M7 woodland environment and checked exports — 14 October 2026

Version `0.7.5-m7`, local Android build 44, replaces the colony's primitive world
art with a shared 1024x360 atlas containing 284 semantic regions. It covers all 34
structures in four rotations, four barn roofs, seventeen ground variants, eleven
trees/resources/nature views, six crops in five distinct stages, 28 items in three
pile tiers and two fire frames. Nineteen inspected Tiny Town 1.1 components retain
their exact source bytes and pinned CC0 license; missing artwork, composition and
a separate additive warmth gradient have editable original sources. The manifest
now has 51 media entries. Contact sheets and source/license evidence are retained;
the original M0 touch fixture remains unchanged.

Ground uses shared TileMapLayers plus visible cached drawing chunks, with no node
per crop tile or stack. Resource rows batch by camera chunk and immutable global-ID
interval, preserving shared foot-y/ID depth order with citizens, guests, animals
and structure props. Actual world data chooses crop stages, supply-pile heights,
station output piles, nature regrowth and fuel/work-dependent flames. Cold stations
do not burn. Carried goods now recognize the actual `carry` stack location, fixing
the missing carry pose during real fetching. Quantities remain exact in selection
cards and only show on selected world piles.

Enclosed room and barn roofs fade to 20% for inspected occupants/interior objects
and Map and seed > Rooms overlay. Trees covering the selected resident fade to 40%.
Native sampled pixels confirm night world luminance stays at least 70% of day.
Selection, blueprint progress/delivered-material badges, danger and actual fire
feedback draw above roofs at full brightness. Battery/reduced motion stop decorative
water and rain/snow animation; balanced/smooth water has two frames and weather
marks are capped at forty-eight. Warm sprites use actual heat sources and a maximum
of sixteen visible emitters. No dynamic shadows or simulation-field/RNG writes.

World adoption clears every pooled environment reference even when terrain refresh
is explicitly called first. Native tests cover this prior stale-world path, actual
public construction/fetched carry poses, room reveal, selected-tree fading, water
quality, night pixels and unchanged authoritative hashes. Drawing diagnostics now
aggregate all custom drawing callbacks once per frame, retaining the original
tick/speed context; the number excludes engine-native sprite/GPU work.

Final validation passes 27 headless suites / 1,362 checks and native UI / 485,
total 1,847 checks across 28 suites. Persistence contributes 232. Three actual
tutorial flows pass 22 each. The independent frozen replay passes 62 commands and
234 invariants in 75.393 seconds with the unchanged schema-22 golden hashes and
foreign-save continuation. The warm 65-second fresh-colony profile advances 650
ticks with no storage pauses, errors or invariant failures. Main CPU callback max
21.743 ms, zero above 50 ms; map update max 3.403 ms / p95 0.922 ms; aggregate
custom drawing max 0.382 ms / p95 0.235 ms; audio max 0.461 ms. Save capture max
1.776 ms, preparation capture 0.799 ms, finish 0.848 ms. Wall-clock frame gap max
43.25 ms, zero over 50 ms. These are macOS CPU observations with Dummy audio,
not physical Android, GPU, audio-thread, thermal or PSS certification.

An intermediate local export exposed Godot returning zero after a GDScript parse
error. The unpublished invalid APK was quarantined and never published; retained
logs show the failed run. `checked_godot.py` now rejects script/engine errors for
imports, exports and exported runtime startup even with exit zero. Eight subprocess
boundary tests and an actual invalid-script run verify that behavior. Five existing
native evidence parser tests also pass. Exported runtime checks require a positive
OpenGL renderer and sixty-frame isolated, audio-drained application exit, and run
from an empty directory so source files cannot conceal missing packaged resources.

The final guarded Android export and four Kotlin tests pass; `aapt` confirms
`0.7.5-m7` / 44, min SDK 29, target 36, arm64 only and VIBRATE as the sole permission.
Both source and actual exported macOS application start cleanly on Apple M5 Pro /
OpenGL 4.1. The macOS bundle previously defaulted to version 1.0.0; package stamping
now synchronizes its short/build versions and Windows numeric versions with the
project/Android build. Local synchronization preserves CI commit suffixes and exact
provenance. Four disposable-checkout stamping tests pass, and the rebuilt macOS
plist reports 0.7.5 / 44. Remote checks/publication for this revision remain separate
until observed. Physical Android stutter, human art/audio/comprehension, localization
and the final stress/release gates remain. Weekly remaining is 86%; work continues.

## M7 crowded-colony targeting and scheduling — 14 October 2026

Version `0.7.6-m7`, local Android build 45, adds the isolated synthetic object-load
fixture and fixes several measured simulation hotspots. The fixture validates,
round-trips through the real codec and continues identically after saving. Its
twenty residents, twelve domestic animals, thirty-two wildlife, six hostiles,
eight neutral road visitors, 400 structures, 1,000 nonempty stacks, 256 targets,
192 crop tiles, 1,000 Chronicle entries and rain are explicitly synthetic;
ordinary admission rules remain unchanged. See [STRESS_EVIDENCE.md](STRESS_EVIDENCE.md)
for exact input/source fingerprints, separate camera/speed results and limits.

The first overload run exposed a roughly ten-second raid-targeting phase caused
by structural scans at every explored neighbor. Goods queries now use packed
walkability/bridge masks, cached door footprints and exact BFS distances. A safe
early exit completes the nearest layer containing the globally best possible
preference; unreachable preferred goods still require full reachability search.
Sixteen comparisons against the former algorithm pass on legacy and every site,
open/closed gates, enclosed preferred stock and distance/ID ties.

Scheduling computes the unchanged score once and lazily pops a disposable max
heap, rather than sorting every eligible job before trying the first candidate.
Consecutive unsuccessful hauling probes may share their current search's storage
occupancy; the next resident and different task types start fresh. Reservations,
carried goods, stockpile tile occupancy, item/tag compatibility and cancellation
retain their exact behavior. Small ingredient requests choose only the needed
prefix of the former ordering; larger requests retain complete sorting. No
priority, material contract, historical record or canonical gameplay field changes.

The profiler now uses monotonic wall duration, a paused render warmup, independent
speed/camera/quality choices, real initial/final counts and source fingerprints.
It records actual processed delta, tick timings and remaining logical time, with
an explicit guard timeout for long runs. Four isolated thirty-second overload
runs keep their requested 1x/4x speeds with no storage error or invariant failure.
Main maxima are about 135-141 ms; tick p95 is 35-37 ms, which still fails the
4 ms budget. Rendering frame gaps also exceed 50 ms. Automatic executable work
still exceeds the separate 512-job requirement. All-alert and thirty-minute
stress/device gates remain incomplete; these are useful diagnoses, not a release
performance pass.

The new-colony 65.033-second warm CPU run advances 650 ticks with main max 3.283 ms,
tick p95 0.767 ms and no callback over 50 ms. Its initial room/render preparation
occurs in the extra warmup, so maxima are not directly comparable with older
profiles that included those callbacks. Physical Android performance remains
unverified. Final local validation passes 27 headless suites / 1,395 checks plus
485 native UI checks, total 1,880. Persistence is 236, scheduler 101, defense 61.
All three tutorial flows pass 22 each. Frozen replay passes 62 commands and 234
invariants in 73.976 seconds with unchanged golden hashes and imported-save
continuation. Media validation remains 51 entries; eight guarded-process and four
version-stamping tests pass. The four Kotlin tests and guarded APK export pass;
`aapt` confirms 0.7.6-m7 / 45, min SDK 29, target 36, arm64 only and sole VIBRATE
permission. Native source startup passes with isolated sixty-frame/audio-drained
exit. The preceding environment commit `e985246` passes every remote check and
published its APK; this revision's remote results remain separate until observed.
Weekly remaining is 84%; implementation continues.

## M7 bounded work and preserved order intent — 14 October 2026

Version `0.7.7-m7`, local Android build 46, introduces content `colony-v3` and
campaign schema 23. The retained v2 catalog is immutable; the new catalog changes
only its version. At most 512 tasks are executable, reserving one place per living
resident and one communal-supper bank. Excess targets retain their immutable IDs,
geometry, materials, contracts and progress in a visible Queued state. Admission
keeps owned work, then emergency/pinned work, categories with an enabled home
worker, aged priority and ID order. Disabling Building cannot starve usable Cooking.
Future blocked retries do not consume capacity. An uncached oracle checks the
derived admission fingerprint tick for tick across retries, commands and preferences.

The Work sheet renders thirty-two order controls per page and shows exact total
and queued counts. Paging keeps the order section visible; cards explain retained
materials/progress and expose Priority/Do next. Actual touch tests cover 640 public
floor targets at 360x640 and 640x360 with 150% text, twenty pages and queued cards;
camera and canonical simulation state remain unchanged by browsing. Native images
were inspected. Diagnostics distinguish unfinished, executable and queued totals.
Static path/bridge membership now shares navigation invalidation; twenty reference
comparisons preserve actual movement costs across sites, weather and destruction.

Older journals fold against their original schema/catalog before migration. V2
import checks its original catalog hash and preserves even reordered full storage
filters. A committed schema-22 fixture was produced with public commands under
`0a4712485e7b443dea847cbfb6f4358513240130`, without grants or edited needs. Frozen
replay now passes an additional fail-closed old-gameplay audit: only declared
headers and empty queue metadata are removed, and the original initial/7,200/
72,000-tick hashes match exactly. Actual capacity deferral fails this strict audit.
The original foreign-host fixture bytes remain unchanged. CI invokes the audit
automatically for schema 23 on every replay platform.

All thirty pinned late-Winter saves pass a separate explicit intent-preservation
upgrade audit. Twenty-nine retain execution states; Reed Bend seed 2147483647
defers thirty orders. Reconstructing only each reported Queued record's previous
state recovers every original gameplay field exactly. The initial strict failure
is retained; this declared-deferral audit does not certify unchanged execution or
v3 Winter survival. The existing 30/30 survival evidence remains pinned to its v2
source, and a full v3 matrix is still required.

Final local validation passes 27 headless suites / 1,432 checks plus 497 native UI
checks (1,929 total), three tutorial flows / 66 checks, 51-entry media/catalog
validation, eight guarded-process tests, four version tests and four Kotlin tests.
The normal replay verifies 62 commands and 234 invariants in 76.113 seconds,
including imported-save continuation and the schema-22 gameplay audit. Guarded
Android export passes; `aapt` confirms 0.7.7-m7 / 46, min SDK 29 / target 36 and
sole VIBRATE permission. Native source startup reaches its isolated sixty-frame,
audio-drained exit. `0a47124` passed remote CI and APK publication; this revision's
remote results remain separate until observed.

Four isolated crowded-colony CPU profiles preserve their exact source fingerprint
and meet the executable-job limit, but still fail performance: tick p95 is
39.864–44.081 ms and main callbacks reach 137.686–147.494 ms. Details, changed
camera center and fixture hashes are in STRESS_EVIDENCE.md. The separate warm
65.033-second new-colony profile advances 650 ticks with main max 3.311 ms,
tick p95 0.805 ms and no frame gap over 50 ms. These runs dismiss the tutorial;
active guidance and physical Android remain to be measured. Weekly remaining is
82%; implementation and performance work continue.

## M7 active lodge guidance cost — 14 October 2026

Version `0.7.8-m7`, local Android build 47, removes a repeated outward lodge search
from active tutorial refreshes. The earlier fresh-colony baseline dismissed the
tutorial. Two isolated twenty-second native profiles with active lessons measured
lodge guidance p50 23.357 / p95 and max 24.578 ms over nineteen refreshes; the field
lesson measured p50 0.271 / max 0.279 ms. Both keep the actual new colony, saving,
renderer and audio paths. This identifies a recurring CPU cost, not a proven cause
of the reported phone freeze.

GameSession now owns a transient suggestion cache, cleared on world adoption and
also checked against the actual world instance. Every refresh and Show me fully
revalidates the selected lodge's placement, access, starter-field separation and
danger. Invalid targets trigger the original ordered search. A still-valid target
stays stable when nearer space opens. No simulation field, ID, RNG stream or save
schema changes. Initial searches and the no-valid-footprint case remain synchronous
and require further worst-case measurement.

A twenty-second follow-up, while three frozen Winter simulations ran concurrently,
measured nineteen refreshes at p50 2.536 / p95 and max 2.657 ms. Main callback max
5.116 ms, no callbacks over 50 ms, clean invariants/storage and unchanged measured
source fingerprint. This is provisional timing under competing work, not an
isolated comparison or physical-device certification. The profiler now exposes
`--tutorial LESSON`, final active lesson and a separate guidance timing series.

Tutorial tests pass 46 checks, including actual 28-blueprint revalidation, exact
canonical-state preservation, fields, structures, resources, queued construction,
furniture moves, resident occupancy, fire, stable valid targets and world changes.
Native UI passes 498 checks; Show me uses the current revalidated target. Each of
the three real tutorial flows passes 22 checks (3.380/3.802/3.504 seconds). Together
with the unchanged 0.7.7 suite baseline this gives 1,940 checks. Guarded Android
build and four Kotlin tests pass; `aapt` confirms 0.7.8-m7 / 47, SDK 29/36 and sole
VIBRATE permission. Native source startup passes sixty-frame/audio-drained exit.
Remote publication is recorded separately after observation.

The full v3 Winter rerun is active on frozen `fe118288c17efc56a252318d042c4bc1af1c2ac6`.
The first setup attempts are retained as failures: the first imported the wrong
checkout and the next found Git LFS pointer text instead of decoded media. Restoring
the existing LFS objects, restoring only this newly created worktree's generated
import metadata, and repeating the guarded import produced a clean frozen source
before the new matrix began. Failed setup directories are never counted as passes.

## M7 hauling positions and admission scoring — 14 October 2026

Version `0.7.9-m7`, local Android build 48, extends consecutive failed hauling
searches' disposable storage context with owned non-eating work positions. Only
unowned haul candidates use this map; other/direct/owned reservations retain the
full reference scan. The context ends before another task kind, a successful
reservation or a different resident. Actual reservation/cancellation comparisons
cover empty positions, sleeping owners, shared eating tiles, other hauling work
and full stores, matching all canonical fields.

Admission precomputes its unchanged emergency/pin/enabled-category/aged-priority
keys instead of recalculating them in every comparison. The explicit old comparator
remains the migration/reference path. Eight 1,200-record comparisons include high
IDs, all priority values, retries, pins, emergency work, owned tasks and unavailable
home workers. Unchanged ticks omit the redundant admission pass at their start;
command batches, pre-assignment creation and every complete tick still reconcile.
The former unconditional three-pass/reference comparator matches every canonical
field at each of 300 crowded-fixture ticks in the extended local run, and 120 ticks
in the regular regression. Existing command/retry/preference comparisons also pass.

The profiler now clears warmup phase/slow-event traces at measurement start and
captures foreground completion timings/diagnostics before a separately reported
post-measurement save drain. Earlier frame/tick totals already excluded warmup;
old phase peaks could include it. The final thirty-second 4x profile still fails
the tick budget: p50 7.320 / p95 35.790 / max 151.979 ms. Main callback p95 is
44.640 / max 152.960 ms, with 29 callbacks over 50 ms. The matched frozen baseline
and final run both overlap three Winter workers; see STRESS_EVIDENCE.md for this
limited comparison rather than a release certification. The current active-lodge
twenty-second run measures nineteen guidance refreshes at p50 2.502 / max 2.775 ms,
main max 5.554 ms, no callbacks over 50 ms and clean invariants/storage.

All 27 headless suites pass 1,466 checks, including scheduler 162; native UI passes
498, total 1,964. The full replay passes 62 commands, 234 invariants, foreign-save
continuation and exact schema-22 gameplay preservation in 110.232 seconds under
concurrent validation. Catalog/media checks pass. Guarded Android export and four
Kotlin tests pass; `aapt` confirms 0.7.9-m7 / 48, SDK 29/36 and sole VIBRATE
permission. Native source startup passes its isolated sixty-frame/audio-drained
exit. The preceding tutorial commit `9c9f759` passed all four remote replay targets,
prototype checks and APK publication; this revision's remote results remain separate.

The frozen v3 Winter matrix has three completed passes and remains active. Font
inspection found one unsupported punctuation character and enabled system fallback
in both font imports; that separate M7 audit is next. Weekly remaining is 82%; the
game is not declared complete and work continues.

## M7 font coverage and text-entry recovery — 14 October 2026

Version `0.7.10-m7`, local Android build 49, disables system font fallback in both
licensed font imports. Headings use only Kenney Bold with an explicit Kenney Mini
fallback; the body has no fallback. The glyph-table audit now checks all 99 current
runtime/catalog text characters, including escaped characters, both quote styles
and GDScript multiline literals, excluding comments. Seven Python inventory tests
cover comments/apostrophes, escaped quotes, Unicode, multiline/raw strings and
unterminated input; CI runs them before media validation. Exact licensed font
binary hashes and the 51-entry media manifest remain unchanged.

The audit found an en dash in historical supper facts and snapshot errors that
neither face contains. Display uses its Basic Latin hyphen equivalent; actual
factual text, canonical fields and save bytes remain unchanged. A real scheduled
supper command and codec round trip prove this boundary. Other unavailable imported
characters show `?`, with a visible explanation in body/full headings or a row
tooltip; originals remain in saves. This does not broaden the supported input
alphabet. New ASCII text takes a native fast path rather than a scripted per-character
loop. Native 150% portrait/landscape font images were inspected for glyphs and bounds.

Citizen/place names, optional moment notes and named snapshots validate before
submitting or closing. Invalid input remains editable; the form error survives an
unrelated forecast/status notice and clears when the text changes. Corrected text
uses the ordinary command/save path. Empty optional notes remain valid. Snapshot
names now enforce their existing 64-character limit with printable Basic Latin at
both the UI and store boundary; rejected replacements leave original bytes intact
and cannot reach replacement confirmation. Existing imported metadata is still
accepted and displayed through the recovery above.

Current targeted validation passes persistence 246 checks and native UI 517.
Together with the preceding full suite baseline this is 28 suites / 1,993 checks.
The nineteen new native checks include real touch at 360x640 and 640x360 with 150%
text, invalid
and corrected names/notes/snapshots, optional blank notes, original replacement
bytes, unrelated notices and audio cleanup. Initial UI attempts missed controls
because the fixture scrolled before layout settled; the failed reports remain,
and the corrected actual-touch runner passes. A first guarded import also rejected
an invalid constant-resource setter before it could become an export. No failed
intermediate output is counted as a pass.

Guarded Android export and four Kotlin tests pass; `aapt` confirms 0.7.10-m7 / 49,
SDK 29/36 and sole VIBRATE permission. Native source startup reaches sixty-frame,
audio-drained exit. The twenty-second new-colony active-lodge profile overlaps the
three Winter workers: main p95 0.938 / max 5.222 ms, guidance p50 2.464 / max
2.586 ms across nineteen refreshes, max frame gap 35.342 ms with none over 50 ms.
Invariants/storage are clean; source fingerprint
`30b3c2ea3ee8606b3db4c2277b87300dc4dcbf00141a623ac147f3db8c1f715d`
is unchanged before/after. This remains provisional desktop CPU evidence.

`b3bbd03` passed all remote replay/prototype/export/startup checks and published its
APK. This revision's remote results remain separate until observed. The frozen v3
Winter matrix has nine completed passes and remains active. Localization keys and
plural forms, crowded-colony timing, physical readability/performance and other
M7 human/platform gates remain open. Weekly remaining is 81%; work continues.

## M7 admission inputs, perishables and heating — 14 October 2026

Version `0.7.11-m7`, local Android build 50, preallocates the exact admission
fingerprint length and uses typed local record terms without changing its bits or
ordering. Validation now rejects priorities outside 1–3, negative/future creation
ticks and negative retries; these invalid inputs could previously violate the
packed score's bounded-field assumptions. Six malformed scheduling cases reject
without clamping data. Legitimate earlier fixtures and replay saves still pass.

The inventory query cache now retains a separate positive perishable view based
on immutable item shelf lifetimes. Aging still applies every tick with the live
location, storage denominator and fractional remainder; it does not become lazy.
New same-tick goods/consumption, caller-owned ordering, full-history round trips,
array replacement and clearing have eight dedicated checks. Depleted history and
all saved fields remain intact. Heating skips occupancy/room work when temperature
is at least 8 C or the hearth is destroyed/unlit, and stops after finding an occupant.
Ten reference checks cover Spring/Summer, Winter, cold snaps, no occupants, no fuel
and a resident farther than three tiles away in the same enclosed room. Fuel and
the retained 1,800-tick heating counter match the former loop.

The fixed 1,200-tick crowded benchmark retains canonical hash
`b9cfe7a9c9e5469082a9aec02f0a075b7e165581c1b8f5a4cecaa1d22d5cc771`
before/after each optimization, also matching its instrumented counterpart.
Measured admission cost falls from 2.610 to 2.267 ms per tick, living/aging from
0.973 to 0.557 ms, and total uninstrumented time from 13.096 to 12.231 seconds.
These measurements overlap three Winter workers and are provisional CPU diagnoses.

A verified actual Pine Shelf seed-4567 Winter checkpoint was captured from frozen
`fe118288c17efc56a252318d042c4bc1af1c2ac6`: tick 223200, snow, original SHA-256
`29a40c8fa7e2d63e6f503f7c6c6c2052e455df54064962148db84aba32dc4350`,
canonical `d404a9db8010c66bcbaf61d0bd20fbbf22732eb6f9403a0d594a286c4e79b138`.
The immutable local copy and provenance remain under reports. Continuing exactly
1,200 ticks under both frozen and optimized sources reaches tick 224400 with
identical full canonical hash
`dc4cec824baf861a3f693a934c4667f109d4b2839a7c28c9c343f63c189723a8`.
Each source also matches its own instrumented continuation. This supplements the
isolated cold tests without claiming a newly completed Winter survival matrix.

All 27 headless suites pass, with the final added cold-room check bringing the
baseline plus targeted rerun to 1,500 checks; native UI passes 517 (2,017 total).
Survival is 76, scheduler 176 and persistence 246. Frozen replay verifies 62 commands,
234 invariants, imported-save continuation and exact schema-22 gameplay preservation
in 105.795 seconds. Catalog/media/glyph checks and seven text-inventory tests pass.
Guarded Android export and four Kotlin tests pass; `aapt` confirms 0.7.11-m7 / 50,
SDK 29/36 and sole VIBRATE permission. Native source startup passes sixty-frame,
audio-drained exit. `a7aa241` passed all remote checks and published its APK; this
revision's remote results remain separate until observed.

Four thirty-second native crowded profiles retain their exact runtime fingerprint
and clean invariants/storage, but remain timing failures: tick p50 6.581–6.787 ms,
p95 35.190–46.874 ms, main maxima 150.050–154.812 ms. They overlap the three frozen
Winter workers; detailed rows are in STRESS_EVIDENCE.md. The frozen matrix now has
eighteen passes and remains active. Further admission/search work, localization
and physical/human release gates remain open; implementation continues.


## 0.7.12 logical admission deadlines

The trusted complete-tick path now reuses unchanged admission decisions rather
than inspecting every queued record while workers only walk or make progress.
Creation, reservation/assignment attempts, block/release/completion, command batches
and the pre-assignment creation stage invalidate it. A compact living/category/pin
signature, source-array identity/count, clock reversal and exact retry/aging deadlines
cover changes outside those hooks. Even a released Ready order retaining a future
retry contributes its deadline: the inspection itself may defer that order.
Explicit reconciliation still reads all live records for direct-edit fixtures/tools.
No derived cache enters saves, IDs or RNG streams.

The full former three-pass/tuple oracle still matches every compared complete tick.
Sixteen new checks cover 200 unchanged ticks, reduced full inspections, deadlines
between assignment ticks, category changes, away/downed/recovered workers, pins,
living capacity, array replacement, deliberate direct edits and release/retry
retention. The final scheduler suite passes 192 checks. The 27-suite baseline
passed 1,514 checks before the final conservative retry fix; its targeted scheduler
rerun adds two checks, yielding 1,516 headless plus 517 native UI (2,033 total).
The final replay passes in 92.287 seconds, including 62 commands, 234 invariants,
foreign-save continuation and strict schema-22 field preservation. The actual
snowy Winter reference retains the exact 1,200-tick continuation hash recorded
above. Catalog/media/glyph checks and seven inventory-parser tests pass.
Android export, four Kotlin checks and native source startup pass; `aapt` confirms
0.7.12-m7 / 51. `b396793` passed all remote jobs and published its checked APK;
this revision's remote results remain separate until observed.

The final crowded 1,200-tick benchmark remains canonically identical to the
previous checkpoints and its instrumented twin: uninstrumented 8.782 seconds,
instrumented 8.903 seconds, inclusive admission 0.787 ms per tick. Background Winter
workers finished during this profiling interval, so wall-time differences from
older runs do not isolate the code change. Four native thirty-second profiles
sample two Winter workers at each start/end; tick medians are 5.107–5.293 ms,
with assignment spikes still reaching 142–154 ms. All retain speed, sub-0.1-second
backlog and clean invariants/storage. Timing gates still fail; see STRESS_EVIDENCE.md.

The frozen current-content first-Winter matrix has now completed and independently
audited 30/30 runs at unchanged `fe118288c17efc56a252318d042c4bc1af1c2ac6`.
Every run retains eight residents at minimum health 100, with zero starvation-grace
exceeded ticks and 792 invariant checkpoints. This is a new colony-v3 simulation
matrix, distinct from the earlier v2 upgrade audit. Its detailed evidence and
current-code loading audit are being recorded separately. Performance, localization,
physical devices and human release gates remain open; implementation continues.


## 0.7.13 reservation searches and current-content Winter evidence

A resident's assignment search lazily filters owned jobs once in original history
order, sharing live dictionaries for workstation, position and hauling-capacity
checks. Releases remain visible; successful ownership acquisition ends the search,
and every exit clears the view before another resident searches. Direct reservation
and storage queries retain full-history behavior. This preserves conflict messages
even for imported history reordered independently of IDs. The crowded complete-tick
oracle now runs the full former admission schedule and an independent full-history
reservation path. Four additional regressions cover ordered conflict reasons,
early-return cleanup, release/next-search visibility and direct-call fallback.

Danger-source rebuilds collect unfinished hunt targets once, lazily for a living
peaceful boar. Queued/blocked hunts remain dangerous and completed/canceled hunts
do not. Twenty reference comparisons cover all three generated sites, duplicate
hunts, those states, attacking/dead/unhunted boars, the legacy no-boar world and
mixed boars/hostiles/fire source order. Canonical state is unchanged by each query.

All 27 headless suites pass 1,540 checks; native UI passes 517 (2,057 total).
Scheduler is 196 and wildlife 63. The ten-day replay passes in 73.989 seconds,
including its strict schema-22 preservation audit and foreign-save continuation.
The crowded 1,200-tick benchmark retains full canonical hash
`b9cfe7a9c9e5469082a9aec02f0a075b7e165581c1b8f5a4cecaa1d22d5cc771`,
also matching its instrumented twin. The actual snowy Winter reference still
reaches `dc4cec824baf861a3f693a934c4667f109d4b2839a7c28c9c343f63c189723a8`
after 1,200 ticks. Catalog/media/glyph validation and seven parser tests pass.
Android export and four Kotlin tests pass; `aapt` confirms 0.7.13-m7 / 52.

The independently audited v3 Winter matrix passes 30/30 at unchanged frozen
`fe118288c17efc56a252318d042c4bc1af1c2ac6`. All eight residents survive each run
at minimum health 100, with no zero-fullness/grace-exceeded ticks or departure.
Current code additionally loads all thirty final saves, checks invariants and
round trips, preserving every canonical field and input file byte without advancing
time. Full hashes and provenance are recorded in WINTER_MATRIX.md. The managed
validation checkout was archived after completion; raw evidence stays outside it.
This differs from the earlier v2 intent-upgrade audit and does not certify later
code by rerunning thirty complete Winters. Physical/human, localization and
performance release gates remain separate.


All four thirty-second crowded native rows retain source fingerprint
`899bb9826fd05b3c2c1d924611be9d0d347ca6b3ebb288ac309aadc26883997d`.
No other Godot jobs were observed at the start/end of each. Tick p50 is
2.454–2.693 ms, p95 32.140–37.499 ms, and maxima 110.822–131.455 ms.
Storage/invariants remain clean, requested speeds hold and backlog stays below
0.05 seconds. These still fail the timing gates; STRESS_EVIDENCE.md retains the
full rows. A separate fixed-tick run takes 7.091 seconds, instrumented 7.163,
with the exact crowded canonical hash above. Background host activity differs
from older concurrent-Winter measurements, so those are not matched comparisons.

A twenty-second fresh-colony profile with the lodge lesson active has 200 ticks:
tick median 0.587 / p95 0.818 ms, session max 4.480 ms, guidance median 2.403 /
max 2.810 ms, maximum frame gap 35.325 ms and no >50 ms callbacks/gaps. Its
source fingerprint stays unchanged, with clean invariants/storage. This is host
CPU evidence, not a physical-phone fix certificate. Native source launch passes
sixty frames and drained audio exit. `9ddd782` passed all remote checks and
published its checked development APK; this revision's remote status follows
its own push. Further ingredient-selection/assignment optimization and the
remaining M7 release gates continue.
