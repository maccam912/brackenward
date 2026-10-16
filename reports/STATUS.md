# Implementation evidence

Soft soil transitions (16 October 2026): `0.7.111-m7`, unchanged content/schema/
envelope. Baked grass fringes soften poor/rich patch edges in summer and winter
without changing terrain data. All 300 previous atlas regions retain exact bounds
and pixels; sixty new edge regions use the existing tile layer. Mature-colony and
native seasonal captures were inspected. UI passes 843 checks and persistence 511;
content/font validation passes. Evidence: `mature-soil-*`, `season-*`,
`soil-ui.log`, `soil-persistence.log` in visual-polish. Remote build 268 passed.
Weekly usage is 40% remaining; original reset unchanged. Polishing continues.

Responsive forecasts and Android follow-up (16 October 2026): `0.7.110-m7`,
unchanged content/schema/envelope. Forecast cards now use two columns where width
and text size allow, retaining one column elsewhere and reflowing the same cards
on rotation. Native UI passes 840 checks; content/font and string/message checks
pass. Both v109/v110 local Android exports and Kotlin plugin tests pass.

Actual touches on the task-owned Android 35 emulator covered the mature colony,
resident rest disclosure, granary illustration, text-size settings, forecast
scrolling and rotation. The revised two-column landscape layout and return to one
column in portrait were visually verified. Three full codec audits after upgrades
and background checkpoints match every gameplay field of the recorded colony after
normalizing only imported campaign/session IDs. Tick remains 693000. Runtime logs
show only the observed shader-cache recompilation warning, with no script errors
or Android fatal exceptions. Durable evidence and captures are linked in
`reports/ANDROID_VISUAL_REVIEW.md` and `reports/android-visual-v110-evidence.json`.
Physical Android/performance remain unverified. Builds 265-267 remote CI passed.
Weekly usage is 42% remaining; original reset unchanged. Polishing continues.

Object detail illustrations (16 October 2026): `0.7.109-m7`, unchanged content/
schema/envelope. Building/resource/field summaries now show state-accurate atlas
pictures on a meadow backing beside their exact text. Native 150% phone views of
the cart, harvested berry bush and growing field were inspected. UI passes 835
checks, including all cart rotations, ready/depleted berry states, five crop stages,
wrapped large-text geometry and unchanged world fields. Content/font and string/
message checks pass. Evidence: `station-*`, `harvested-*`, `field-*`, `details-*`
in visual-polish. Weekly usage is 45% remaining; reset unchanged. Physical-device
review remains unverified. Polishing continues.

Resident card hierarchy (16 October 2026): `0.7.108-m7`, unchanged content/
schema/envelope. Work preferences/map access now precede cosmetic actions, bed
assignment accompanies bed information, and the long exact food/rest policy uses
a reversible disclosure. Current access/priority/departure warnings remain visible.
Native phone views were inspected; UI passes 823 checks, including expansion,
collapse, exact rule values, primary action order and unchanged state/camera at
100/150% text. The prior rest-text test now expands the disclosure before checking
visible rules. Content/font and string/message checks pass. Evidence:
`person-*` and `person-details-*` in visual-polish. Physical-device review of this
card remains unverified. Polishing continues.

Generated flood preview (16 October 2026): `0.7.107-m7`, unchanged content/schema/
envelope. View flood area now targets the nearest actual forecast-mask tile and
clears resident follow. It uses the pre-sheet visible center when following,
accounting for guidance/inspector reflow. Three new generated-site baseline tests
failed; the final native UI suite passes 817 checks, including correct tile-center
focus on all three sites, released follow, restored prior speed and unchanged
world state. Content/font and string/message checks pass. Evidence:
`flood-camera-{baseline-ui,ui,content}.log` in visual-polish. Weekly usage is
46% remaining; reset unchanged. Polishing continues.

Forecast presentation (16 October 2026): `0.7.106-m7`, unchanged content/schema/
envelope. Separate day cards and seven original static weather symbols clarify
conditions while retaining dates, temperature, exact consequences and flood
exposure/action controls. Native normal/150% phone views were inspected. UI passes
814 checks, including every weather at both text sizes, distinct rendered symbols,
unchanged world state and the nested flood action. The existing action test now
searches within the day card; an invalid test-only byte-array hash call was fixed
before the passing run. Content/font and string/message checks pass. Evidence:
`weather-390x844*`, `weather-1100x720.png`, `forecast-*` in visual-polish.
Physical-device forecast-card review remains unverified. Polishing continues.

Utility building art (16 October 2026): `0.7.105-m7`, unchanged content/schema/
envelope. Seven utility structures now have distinct original construction: open
racks, slatted granaries, timber barns, stone cellars/wells, planked piers and
braced watchposts. Only their twenty-eight existing rotation regions changed;
all 300 atlas rectangles/dimensions and other pixels are preserved. Native workshop
and 103-structure colony captures were inspected. The recorded input snapshot
remains unchanged and rendering preserves canonical state. Pinned persistence/art
passes 511 checks; content/font validation passes. Evidence: `utility-*`,
`workshop-native.png` and `mature-utility-*` in the local visual-polish folder.
Build 264 remote CI passed; 265-267 were still running. Physical-device review
of these revised sprites remains unverified. Polishing continues.

Floodwater clarity (16 October 2026): `0.7.104-m7`, unchanged content/schema/
envelope. Actual water now uses shallow ground tint, static ripples and perimeter
edges beneath supplies/actors; forecast stripes stay separate and full-bright.
Native generated Reed Bend and authored river views were inspected, including
a resident and cloth stack beside the river. UI passes 799 checks: actual simulator
onset matches visible ground commands exactly, forecast remains distinct, recession
removes every cached water command, and rendering preserves canonical state.
Content/font and string/message validations pass. Evidence: `flood-*` under the
local visual-polish folder. Weekly usage is 48% remaining; original reset unchanged.
Physical-device flood presentation remains unverified. Polishing continues.

Weather atmosphere (16 October 2026): `0.7.103-m7`, unchanged content/schema/
envelope. Rain/flood, snow/cold snap, drought and fog now have restrained landscape
palettes; fog has a static veil and moving snow has varied bounded flakes. Battery
and reduced-motion modes retain the atmosphere while suppressing precipitation.
The native seven-weather gallery was visually inspected. UI passes 796 checks,
including unchanged canonical state, identical Battery/reduced-motion weather
pixels and exact restoration of clear-weather pixels. Content/font, string/message
and fixture-checkout checks pass. Evidence: `weather-*` under the local visual-
polish folder. Builds 262 and 263 remote CI passed; 264/265 were still running.
Weekly usage is 49% remaining; reset unchanged. Physical-device weather review
remains unverified. Polishing continues.

Android visual review and header spacing (16 October 2026): `0.7.102-m7`,
unchanged content/schema/envelope. Exported Android review found a 150% text
status header overlapping map controls. Controls now track the real wrapped header
height while the map keeps stable geometry. Seven new baseline spacing checks
failed before the fix. An initial approach moved the viewport and failed existing
camera/marker tests; it was replaced. The final pinned UI suite passes 783 checks,
including notice reflow without camera movement at phone, landscape and Android
density/safe-area sizes. Content/font and string/message validation pass.

Local Android export and Kotlin plugin tests pass. On a new task-owned Android 35
arm64 Pixel 5 emulator, actual ADB touches exercised setup, scrolling, Build/Work
thumbnails, People portraits/needs, 100/125/150% text, portrait/landscape, native
document import and direct stockpile inspection. The rebuilt header has clear
spacing. The fresh seed-104729 Standard colony matches the retained full initial
generation reference. A 103-structure/eight-resident recorded colony imported into
a separate slot matches every migrated gameplay field after normalizing the new
campaign ID and pending-command session IDs. Runtime logs contain a shader-cache
recompile warning, with no observed script errors or Android fatal exceptions.

Durable captures and evidence are in `reports/ANDROID_VISUAL_REVIEW.md` and
`reports/android-visual-v102-evidence.json`; detailed local logs remain under
`reports/visual-polish/`. This software-rendered emulator run does not certify
physical Android appearance/performance. Weekly usage is 50% remaining; the
original reset has not occurred, and polishing continues.

Natural resource clarity (16 October 2026): `0.7.101-m7`, unchanged content/
schema/envelope. Five resource sprites now distinguish berries, leafy herbs,
layered clay, faceted stone and iron. Three appended depleted sprites keep
harvested renewable patches recognizable without ripe produce. Exhausted finite
deposits remain hidden. Resource cards explain growing days/winter pauses, and
gathering labels use catalog names instead of internal IDs. The atlas now has
300 regions at the unchanged 1024x418 size; every earlier rectangle is preserved.

Pinned native UI passes 766 checks and persistence/art passes 511. Native checks
cover depleted membership, visibly changed pixels, actual simulator regrowth,
exact restoration of ready pixels and unchanged rendering state. The old full-
rebuild comparison initially expected harvested patches to disappear; its
independent catalog-based visibility rule now reflects the intended contract.
Content/font, string/message and fixture-checkout checks pass. Native source,
gathering-menu, large-text resource-card and developed-colony views were inspected.
Evidence: `resources-*`, `regrowth-*`, `mature-resources-*` in the visual-polish
folder and `reports/regrowth-{ready,depleted}.png`. Weekly usage is 54% remaining;
physical Android remains unverified.

Connected construction art (16 October 2026): `0.7.100-m7`, unchanged content/
schema/envelope. Fences use open rails and posts; palisades use pointed stakes;
timber and stone walls have restrained material details. Floors and bridges have
staggered plank joints. Only eight floor/bridge atlas regions changed, preserving
all semantic rectangles. A native disposable gallery covers straight walls,
corners, T junctions, isolated segments and ruins without mutating canonical state.

Pinned native UI passes 762 checks, including actual seam pixels, mixed-material
junctions, destroyed-wall gaps and unobscured interiors. Content/font and fixture
checkout validations pass. Evidence: `walls-*` in `reports/visual-polish/`. Weekly
usage is 55% remaining. Physical Android remains unverified; polishing continues.

Cultivated field art (16 October 2026): `0.7.99-m7`, unchanged content/schema/
envelope. Quieter brown earth replaces orange soil; the five existing crop stages
now show distinct barley, flax, vegetable and cavecap growth. Exactly thirty crop
and three soil regions changed; all other atlas pixels, dimensions and semantic
rectangles remain unchanged. Source art and the native developed-colony field view
were inspected. Pinned persistence/art passes 511 checks, content/font validation
and checked import/capture pass. Evidence: `crops-*` and `mature-crops-*` under
`reports/visual-polish/`. Physical Android remains unverified.

Stockpile clarity and inspection (16 October 2026): `0.7.98-m7`, unchanged
content/schema/envelope. Painted zones now have quiet outer boundaries beneath
goods; the ordinary orange wash and internal white grid are removed. Tapping a
zone opens its existing Storage sheet, highlights selected cells without tinting
items, pauses, and restores the previous speed on close. Filter buttons show
adaptive item thumbnails. Native developed-colony and large-text portrait views
were inspected.

The native pixel/map-tap regression failed three checks against the old renderer
and now passes; the full pinned UI suite passes 762 checks. Content/font, string,
message and fixture-checkout validations pass. Evidence: `storage-*` and
`mature-storage-*` in `reports/visual-polish/`. Weekly usage is 56% remaining;
physical Android remains unverified and visual polishing continues.

Distinct material piles (16 October 2026): `0.7.97-m7`, unchanged content/schema/
envelope. Wood, grain, fiber, cloth, leather and brick have clearer original
silhouettes across all three quantity tiers. Exactly eighteen item regions changed;
all other atlas pixels/rectangles and source dimensions remain unchanged. The
contact sheet and a recorded 103-structure, eight-resident developed colony were
inspected with the native renderer. The read-only review tool verifies unchanged
input bytes and canonical state after rendering its disposable daylight copy.

Pinned persistence/art passes 511 checks; content/font validation and checked
import/capture pass. Evidence is in `reports/visual-polish/items-*` and
`mature-items-*`. Physical Android remains unverified. The developed-colony review
identified overbearing stockpile overlays as the next visual-polish target.

Ground contact and beacon alignment (16 October 2026): `0.7.96-m7`, unchanged
content/schema/envelope. People and animal sprites have small baked contact shadows
inside their original frame bounds. Every old opaque pixel is unchanged, atlas
dimensions/pose regions are identical, and portraits remain byte-identical. The
beacon ceremony flame now sits in its raised basket; inactive/destroyed beacons
remain unlit. No extra runtime texture, node, light or saved field was added.

Native camp, animal/visitor and close beacon views were inspected. Pinned native
UI passes 758 checks, including inactive, Active, Complete and destroyed beacon
states; persistence/art passes 511 and content/font validation passes. Evidence:
`reports/visual-polish/grounding-*`, `beacon-lit.png`, and native animal capture.
Weekly usage is 59% remaining. Physical Android remains unverified; work continues.

Building render reuse (16 October 2026): `0.7.95-m7`, unchanged content/schema/
envelope. Off-screen buildings defer visual synchronization until camera return.
Visible building state is reused between unchanged ticks, while camera/zoom/size,
selection, room reveal and flame-frame changes invalidate the cache. Live records
and world references remain current. The foreground profiler now accepts/forwards
the existing food-checkpoint argument; its stale override previously failed parse.

Pinned UI passes 754 checks, including off-screen fuel/destruction, camera return,
zoom without ticks and independent flame frames. Four native camera views are
pixel-identical to the original renderer. Content/font and fixture checkout checks
pass. Evidence: `reports/visual-polish/cull-*`, `render-cache-*`, `render-stress-*`.

Sequential 60-second native CPU probes used the same synthetic 20-resident,
400-structure input and advanced 600 ticks each. Close-view culling alone reduced
prop-update p95 from 1637 to 914 microseconds. The final fully zoomed-out run reduced
view-update median from 2348 to 937 microseconds and prop-sync calls from 1800 to
722; p95 remained similar (4744 vs 4797 microseconds). An earlier culling candidate
added overhead and was replaced. Reports retain unchanged-source/input evidence
and no invariant/storage errors. These are local callback timings, not GPU,
physical Android, ordinary-play balance or full-frame performance certification.
The remaining simulation/frame spikes and physical release gates remain open.

Seasonal landscape (16 October 2026): `0.7.94-m7`, unchanged content/schema/
envelope. Broadleaf trees turn gold/copper in autumn and show full-height bare
branches in winter; evergreens retain needles. Winter grass uses quiet dormant
colors and spring restores the original palette. Thirteen new atlas regions bring
the total to 297 at 1024x418 without moving earlier rectangles. Cached terrain
refreshes on season boundaries; no per-frame texture generation or new simulation
fields were added. Water, paths, crops, tree quantities and movement remain intact.

Native four-season river views were inspected, and checked capture is error-free.
Pinned UI passes 749 checks, including winter entry/spring return, real source
selection, unchanged paths/water and canonical state. Persistence/art passes 511
with all regions in bounds and the seasonal tree anchor contract; content/font
validation passes. Evidence: `reports/visual-polish/season-*`. Physical Android
appearance and performance remain unverified; the visual polish run continues.

Workshop and landmark silhouettes (16 October 2026): `0.7.93-m7`, unchanged
content/schema/envelope. Original drawing code improves the cart, four industrial
stations, garden bench, bell, memorial and beacon. The editable atlas/contact sheet
and asset manifest were regenerated; all 284 regions, footprint sizes and anchors
remain unchanged. Native full-building gallery and labeled contact sheet were
inspected. Checked native capture reports no engine errors. Pinned persistence/art
checks pass 510, native UI passes 746, and content/font validation passes. Evidence
is in `reports/visual-polish/workshop-*`; the new capture tool uses a disposable
fixture and never opens player saves.

Build 251 completed all remote jobs successfully, including Windows, Intel/ARM Mac
and Linux replays plus the complete generation sweep. Later builds are separate.
Physical Android remains unverified. Weekly usage is 63% remaining; work continues.

Illustrated site selection (16 October 2026): `0.7.92-m7`, unchanged content,
schema and envelope. New Colony shows a static meadow/forest/river vignette using
the actual atlas. Selecting a site updates the illustration with its description.
It ignores input and requires no generated preview world or additional assets.
Native views of all three sites at portrait/landscape widths and 150% text were
inspected. The native UI suite passes all 746 checks, including setup creation and
scroll gestures. Initial preview atlas-key errors were fixed before the final
error-free capture and isolated UI run; concurrent GUI runs are not validation.
Evidence: `reports/visual-polish/sites-*` and `new-colony-*`. Weekly usage is 64%
remaining; visual polish continues. Physical Android remains unverified.

Resident needs and menu lifetime (16 October 2026): `0.7.91-m7`, unchanged
content/schema/envelope. Resident details now pair the portrait with four labeled
needs bars and exact values, including the distinct 100-point health scale. Activity
and traits precede appearance actions. Native portrait/landscape and 150% text
captures were inspected. The compact map inspector retains its existing layout.

Repeated menu visits exposed a growing registry of freed buttons: the regression
reproduced 712 entries with only 30 live controls. Layout now prunes freed entries.
The regression verifies bounded live controls, retained navigation and unchanged
world state. Pinned native UI passes 746 checks; content/font, string/message and
Git checkout fixture checks pass. Needs tests cover zero/full values and health 37;
the text test now checks the four exact captions and adaptive heading placement.
Evidence: `reports/visual-polish/needs-*` and `menu-lifetime-*`. Build 251 remote
Windows replay and full generation sweep passed; Intel Mac remains in progress.
Physical Android remains unverified. Weekly usage is 65% remaining; work continues.

Recognizable People list (16 October 2026): `0.7.90-m7`, unchanged content,
schema and envelope. Resident rows show their saved clothing/hair/skin portrait
beside the existing name. The existing portrait atlas/shader is reused; pictures
ignore input and adapt their width before sacrificing name space. Native button
text, tooltip, callbacks and M0 compatibility remain intact.

Pinned native UI passes 742 checks. Native People captures in portrait/landscape
and at 150% text were inspected, with no renderer errors. Content/font validation
passes. Evidence is in `reports/visual-polish/people-*`. No CPU recolor loop or new
asset was introduced; physical Android and performance claims remain separate.
Build 251's repaired extended Windows/generation jobs are still running; Linux
and ARM Mac replays have passed. Continue visual polish with periodic usage checks.


Atmosphere and control feedback (16 October 2026): `0.7.89-m7`, unchanged
content/schema/envelope. Dawn and dusk briefly warm the world tint while exact
white daylight and the existing readable cool night endpoint remain. Live hearths
cast a slightly wider, night-strengthened warm pool centered beneath the fire ring.
A discovered presentation bug is fixed: destroyed hearths with leftover fuel no
longer emit a false glow. The existing sixteen-visible-source bound remains.

Active top-level menus and actual selected speed now retain their pressed styling;
rejected speed actions restore the real state, and clock/layout updates follow
pause/resume. Existing action callbacks, pause policy and quiet-sleep behavior are
unchanged. Selected-button text contrast measures 4.60:1. Native portrait/landscape
and 150% captures were inspected, along with camp at noon, dawn, dusk and night.
Pinned native UI passes 742 checks, including destroyed-hearth feedback; persistence
and asset checks pass 510. Content/font validation remains part of the checkpoint.
Evidence is in `reports/visual-polish/lighting-*` and `control-feedback-*`.
Build 251 has passed all remote core jobs and published; repaired extended checks
are still running. Physical Android/performance gates remain open. Weekly usage
is 67% remaining and visual work continues.


Path shoulders (16 October 2026): `0.7.88-m7`, unchanged content/schema/envelope.
Dirt paths have quiet, irregular grass shoulders matched to adjacent soil, with
coordinate-hashed texture variation. Detail remains inside actual path cells and
below built floors/bridges. The derived membership table and cached rectangles
rebuild on terrain refresh/world adoption and never enter saves.

Pinned native UI passes 741 checks, including six new checks across all three
sites: each path/river detail stays inside its logical cell, rebuilds exactly and
preserves the complete canonical world. Native camp/river rendering was inspected.
`tools/visual_review.gd` also captures camp at dawn/dusk/night for subsequent
lighting review. Logs are in `reports/visual-polish/path-*`. The accompanying CI
byte/UID correction is separately committed and described below. Remote repaired
checks and physical Android appearance/performance remain unverified. Weekly
usage is 69% remaining; the authorized visual polish run continues.


Extended CI repair (16 October 2026): Build 247 published after passing all core
jobs, then its Windows replay failed the frozen v7 producer-byte check while all
three snapshot rows and the journal fold passed. Actual Git checkout with
`core.autocrlf=true` reproduces changed SHA-256 values for both v7/v8 producer
scripts. Their new LF attributes preserve the original expected hashes; recursive
snapshot/journal attributes prevent newline conversion in nested fixture folders.
No frozen source, snapshot, expected digest or gameplay field is rewritten.

Three new actual-checkout/UID-presence tests pass with the fix; the old attributes
reproduce both producer failures and nested-fixture conversion. Native v7/v8
acknowledgement audits pass, and actionlint passes. The test is part of core CI.
Build 247's generation job refused a dirty import because the new visual UI
capture script lacked its committed UID; that UID is included in Build 249.
A fresh Build 249 worktree, with LFS materialized, stays clean after checked
Godot import and passes a three-site independent map smoke (three maps only,
not the full sweep). The first local worktree import before LFS checkout failed;
its logs remain retained. Full repaired Windows CI and 768-map remote generation
validation remain pending. Existing failed jobs retain their original results.


Foliage and camp materials (16 October 2026): `0.7.87-m7`, unchanged content,
schema and envelope. Evergreen branches now form a readable tiered silhouette;
broadleaf crowns use clustered shading inside the retained CC0 silhouette.
Hearths have an original ground-level stone ring with separate live flames.
Blankets have folds and woven stripes, and wooden work surfaces catch a small
edge highlight. These baked edits retain all 284 atlas rectangles, dimensions,
foot anchors, runtime nodes and fuel/animation logic. Original source files stay
retained; the provenance note distinguishes the newly authored evergreen.

Pinned native UI 735, persistence/asset checks 510 and content/font validation
pass. Actual camp and river views were inspected in the native renderer; the
atlas contact sheets are regenerated alongside the exported texture. Local logs
and captures are in `reports/visual-polish/foliage-*` and `camp-*`. Physical
Android appearance/performance is unverified. Builds 247 and 248 have published
APK/build-metadata/checksum assets; their extended CI was still running when
last checked. Weekly usage is 70% remaining; visual polishing continues.


Illustrated action menus (16 October 2026): `0.7.86-m7`, unchanged content,
schema and save envelope. Build and gathering rows now show the actual atlas art
with a consistent square thumbnail column and left-aligned labels. Pictures shrink
or hide when needed to preserve action/cost text at larger type sizes. Ordinary
button semantics, touch scrolling, tooltips, placement and unlock rules remain.
The first 150% portrait capture exposed a truncated lodge cost; the adaptive
thumbnail correction retains the complete label in the final inspected capture.

Pinned native UI passes all 735 checks after the correction. Content/font
validation passes. Isolated native Build/Work/resident/HUD captures cover portrait
and landscape, plus both illustrated menus at 150% text. Logs/captures are in
`reports/visual-polish/illustrated-*` and the corresponding PNGs. Physical Android
and remote publication remain separate. At this boundary weekly usage is 71%
remaining; the authorized visual-polish run continues.


Visual terrain checkpoint (16 October 2026): `0.7.85-m7`, unchanged content
`colony-v11`, schema 24 / envelope 5. Quieter grass, closer poor/rich soil
shades and coordinate-hashed variants reduce the repeating ground pattern.
Cached river-bank strips follow actual water edges below floors/bridges, tint
with the world and remain static in Battery/reduced motion. Natural-resource
sprites carry small baked contact shadows within their existing bounds.
Original CC0 source bytes, map generation, footprints and saved fields remain
unchanged. Two isolated native capture scripts provide camp/river day/night
and portrait/landscape interface views without opening player saves.

Local pinned Godot 4.7.2 validation passes native UI 735, persistence 510
(including all 284 semantic atlas regions and source-license checks), nature 33,
content/font validation and the real 60-frame Compatibility startup with audio
drained. Native day/night terrain captures were inspected. Preliminary captures
used PATH Godot 4.7; final captures/tests use the pinned 4.7.2 executable. Logs
and images are retained locally in `reports/visual-polish/`. Physical Android
appearance/performance and remote publication remain separate gates.

The user resumed visual polishing until the weekly reset or less than 25%
weekly usage remaining. Initial account reading was 73% remaining; continue
in verified batches and check usage at boundaries. This replaces the previous
stop-for-testing instruction. Foliage, camp furniture and build/work menu
visual presentation are the next candidates; no gameplay additions are implied.



Bedtime hunger follow-up (15 October 2026): `0.7.84-m7`, content `colony-v11`,
unchanged schema 24 / envelope 5. Actual Working sleep halves hunger drain,
using the existing saved integer remainder; awake metabolism and zero-fullness
starvation timing are unchanged. This follows sleeping activity, including
Night shift/daytime sleepers, rather than rewarding residents working at night.
Before needed sleep, residents above critical rest seek reachable allowed food
below 650 fullness. Extra raw portions can top up to that threshold; missing
supplies do not create a wait for nonessential food production. Routine hunger
waits until rest 700; fullness 100 or below can wake someone for available food.
With no ready portion, critical hungry sleepers can prepare food after rest 300.
Camp sleep follows the same hunger rate/food thresholds and retains real cargo
consumption. Stored runway remains conservative at awake demand.

Controlled tests cover a real bedtime meal, one uninterrupted bedroll sleep to
900 rest, exact half-rate/remainder continuation across reload and both shifts,
raw portions, absent supplies, ordinary/critical waking, starvation damage and
camp rations. No acknowledged v10 needs/jobs/maps/IDs are rewritten on load;
only validated content headers change. The v10 trace and goldens remain intact.
A fresh ten-day ordinary first-week run passes 72,000 ticks with zero
zero-fullness ticks and minimum health 100; its original 69 accepted commands
supply the separate v11 replay and save-continuation baseline. The old timed
v10 research request no longer follows Farming completion under new sleep
scheduling; its expected receipt was not changed.

Final sequential validation passes all 28 core suites / 3,067 checks
(27 headless / 2,335 and native GUI / 732), plus tutorial flows on all three
sites. The 500 scheduler checks include 19 new bedtime cases. All 49 recursive
snapshot fixtures pass the independent codec/writer comparisons. Python 142,
content/font/messages, the Android 0.7.84-m7 APK export/metadata and four cached
Kotlin results pass. A fresh 69-command replay matches canonical checkpoints at
7,200 and 72,000 with exact saved continuation and all older acknowledgement
audits. The exported macOS app starts its real Compatibility renderer and exits
after 60 smoke frames with audio drained. `reports/bedtime-v84-evidence.json`
and `bedtime-final-*` logs retain those scopes.

Commit/push this verified follow-up and check its numbered development APK
publication. Physical Android and M7 performance/human release gates remain
separate.

Player survival/building feedback (15 October 2026): `0.7.83-m7`, content
`colony-v10`, schema 24 / envelope 5. Hungry residents stop unrelated work
when no reachable portion is available, prefer enabled food supply tasks over
pinned construction, and retain marked work that reopens door access to food.
Tired residents head to their safe assigned bed, including at rest 100 or lower;
old unexplained ground-collapse sleeps redirect there on the next assignment
check. The explicit unreachable-bed fallback remains. Hungry cooks/foragers can
finish making food above critical rest without a release/reacquire loop.

The existing clock now names Dawn/Day/Dusk/Night and the world has a visibly
cooler night tint with smooth dawn/dusk transitions and full-bright essential
cues. Walls/palisades default to hollow rectangle painting; Shape switches to
lines, taps remain one cell, and exact perimeter costs/omissions are previewed.
Doors placed on planned walls cancel the wall/helpers and return unconsumed
materials. Built walls receive real demolition work before door construction;
progress, cancellation, recovered materials and saved dependencies are tested.
A stump card offers Remove stump for 4 WU of Gathering, without wood yield.
Removed sites disappear and cannot be automatically replanted by forest zones.

Schema migration only adds the false tree-site flag and declared headers;
existing acknowledged state and source fixtures remain intact. New replay
fixtures retain 80 public commands from a fresh ordinary first-week run.
The old v9 timed raid-payment trace is retained unchanged; its incident timing
differs under the new resident schedule, so its receipts were not rewritten.

Final sequential local validation passes all 28 core suites / 3,048 checks
(27 headless suites / 2,316 plus native GUI / 732), and tutorial flows on all
three sites. Python discovery passes 142 tests; content/font/message validation
passes. The fresh replay verifies all 80 original accepted commands, canonical
checkpoints at 7,200/72,000, saved continuation and every retained older
acknowledgement audit. A ten-day ordinary first-week campaign advances 72,000
ticks with zero zero-fullness ticks, minimum health 100 and a passing goal.
Android APK export/metadata succeeds at 0.7.83-m7 (local debug code 119), and
four cached Kotlin test results pass. The macOS export launches through its
real Compatibility renderer and exits after 60 smoke frames with audio drained.
`reports/needs-v83-evidence.json` and `needs-final-*` logs retain these scopes.
Native rendered outline previews were inspected in portrait/landscape at 150%
text; sampled night readability passes. No phone performance claim is made.

Push this verified batch with its numbered development tag. Remote CI and APK
publication are checked after the push; physical Android behavior remains for
the user's testing. M7 performance, localization and human/device release gates
remain open.

Isolated desktop output fix (15 October 2026): run `38847287321` failed the
first Windows export because its `build/` output directory did not exist.
The former sequential job obtained that directory from the Android build;
the split desktop job now creates it explicitly before exporting. The
parallel release gate and all existing checks remain intact.

Local clean-source validation reproduces the missing-directory failure, then
passes Windows, macOS and Linux exports after creating the directory, without
any generated Android build state. Logs are in `reports/desktop-clean-*.log`.
Actionlint and whitespace checks pass. Remote desktop launch/publication for
this correction remain pending separately from these local export checks.

Parallel core CI (15 October 2026): the previous successful prototype job in
run `38814033122` took 16m48s: sequential simulation suites 12m07s,
Android/Kotlin 2m03s, graphical UI 50s, desktop exports 22s, plus setup and
uploads. Suite summaries identify persistence 131.6s, scheduler 134.0s and
generation 118.7s as the largest contributors. The 30 headless suite/site
invocations now run in five isolated matrix jobs, balanced at 99–141s of
observed test time per group (plus setup and the prepared-defense scenario).
Android/content/Kotlin, UI and desktop export/launch run alongside those
groups. All core jobs still gate publication; extended validation still runs
after the publication attempt. Fail-fast is disabled across simulation groups.

Gradle dependencies and pinned engine/template archives are cached; archives
are still verified on installation, and project/user/signing state is excluded.
Android and desktop each stamp the same full-history source independently.
Evidence is uploaded per job without duplicating the APK inside desktop
artifacts. `DESIGN.md` §23.3 and `README.md` describe the parallel release gate.
Local actionlint, shell syntax and whitespace checks pass. Parsed-workflow
checks preserve all 31 suite/site invocations including UI exactly once with
their original arguments/timeouts, the tool/content, APK, desktop, UI and
prepared-defense commands, real failures, and the existing follow-up jobs.
The estimated release path is roughly 3–5 minutes before runner queue delays;
actual remote timing and publication for this checkpoint remain unverified.

Development APK before extended validation (15 October 2026): CI now runs
the existing core simulation/UI/Kotlin/build/export job, publishes the exact
commit's APK, then starts the four native replay jobs and the independent
generation sweep. Extended failures remain real failed checks with their
existing evidence uploads, and cannot delay an already published download.
They also run after failed build/publication attempts and skipped PR
publication unless the workflow is cancelled. The publication summary links
directly to the download; release notes link to the follow-up check results
without claiming those checks passed. `DESIGN.md` §23.3 and `README.md` describe
the ordering and separate certification status. No gameplay, save format,
core validation, platform coverage, signing or exact-source tag guards changed.

Local validation: actionlint and whitespace checks pass. Parsed-workflow
checks verify the acyclic build → publish → replay/sweep dependencies, the
PR/upstream-failure scheduling condition, all four platforms, preserved
failure reporting, unchanged core jobs/evidence and exact-source release
guards. Remote execution and APK publication for this checkpoint remain
pending; they are separate from this local workflow validation.

Hauling-priority feedback (15 October 2026): `0.7.82-m7`, content `colony-v9`,
unchanged schema 23 / envelope 5. Starting residents and newcomers default
Hauling to Last while retaining their other specialties/preferences. Ordinary
Last hauling is a true fallback after every other enabled, feasible task,
including other Last work; age/Urgent priority cannot lift it above that work
or scheduled leisure. Failed higher-tier reservations still permit useful
hauling. Off, manually raised Normal/First, pinned work, emergencies and
fetching a job's own supplies retain their explicit behavior. Work preferences
explain the rule. Existing saves retain every work setting; set Hauling to Last
under Work → resident to opt existing residents into the fallback behavior.

Local validation passes 15 affected suites / 2,544 assertions, including
scheduler 468, native UI 716, population 58 and persistence 510. Content,
English messages (5), GDScript strings (7) and merchant/map audit tooling (19)
pass. Frozen v8 snapshots and a 600-tick journal preserve exact original fields,
preferences and bytes with untouched migration backups; all v3-v7 audits also
pass. New v9 recording and independent verification accept all 62 public
commands, match ticks 7,200/72,000 and continue saved state identically. Only
the observed payment target changes from v8 raid 3850 to v9 raid 3835; every
earlier fixture remains unchanged. `reports/hauling-v9-validation.json` records
the exact source hashes and local scopes. Current-v9 remote CI/publication,
physical-phone and long-campaign balance checks remain pending separately.


Player-feedback checkpoint (15 October 2026): `0.7.81-m7`, content
`colony-v8`, unchanged campaign schema 23 / envelope 5. Ordinary hunger now
finishes the current carried load, recipe/gathering/crop action, or whole work
unit for construction/research before eating. Partial mixed loads deliver
immediately; the deposit checkpoint prevents another pickup before eating.
Starvation, critical rest, emergencies and blocked routes retain their existing
interruptions. Nested ordinary panels and optional paused citizen inspectors
restore their exact entry speed; explicit pauses, alerts, backgrounding,
storage errors and world adoption cancel that resume. Build hides every
structure whose research is incomplete. Room and barn roofs are hidden;
optional room outlines leave interiors clear. Neighboring wall/fence segments
join across corners and junctions and update after destruction. Turnips now
need four normal-soil days (3.2 on rich soil); planting help and the design's
food arithmetic reflect the new duration.

Local validation: 15 affected suites / 2,496 assertions pass, including native
UI 713, scheduler 453, persistence 506, and an eight-day four-person farming
and foraging run. Native rendered wall seams and open room interiors pass
pixel checks; `reports/feedback-open-rooms-connected-walls.png` was inspected.
Content validation, English messages (5), GDScript string checks (7), and
merchant audit tooling (18) pass. Frozen v7 loaded-work snapshots and its
600-tick journal retain all acknowledged fields and untouched migration
backups; older v3-v6 acknowledgement audits also pass. Current replay and
save continuation use new v8 fixtures; all 62 receipts remain accepted, with
only the observed raid payment target updated from 3976 to 3850. Earlier
fixtures remain unchanged. Exact final validation is recorded in
`reports/feedback-v8-validation.json`.

This checkpoint is local. Previous published/CI results and long-campaign
balance evidence retain their original source/content scopes; current-v8
cross-platform CI, APK publication, physical-phone and long-campaign balance
validation are separate, pending checks.


Development release numbering (15 October 2026): checked APK releases now use
`Build N (development)`, semantic tags `v0.0.N-dev`, and sortable download names
`brackenward-build-000NNN.apk`. N is 100 plus the full Git commit count, shared
with Android's version code and its visible build suffix. The next checkpoint
is build 239, above the latest published APK's code 234. Main advances without
force; new commits increase N and retries retain the same tag/release. CI fetches
full history, and shallow publishers fail before reserving a number. The atomic
checkpoint helper reserves the numbered tag and retains its exact-source,
conflicting-tag, and divergent-main protections. Existing hash-tagged release
links remain available. No gameplay or save format changed.

Local validation: seven package-stamping and seven isolated-Git publication
tests pass, including increasing numbers, repeatable retries, filename sorting
across 999/1000, shallow-history refusal, and conflict preservation. Actionlint
and diff checks pass. A disposable full-history clone verifies the stamped
package/provenance fields and renamed-asset checksum handling; it uses fixture
APK bytes, not an Android export. Remote CI/APK publication for this checkpoint
will be checked after pushing; physical-device validation is separate.

Prior checkpoint: `0.7.80-m7` (campaign schema 23, device settings schema 6), content `colony-v7`, development colony envelope version 5 with a canonical catalog hash. New colonies use generator revision 2; saved revision 0/1 maps and historical revision 1 replay remain unchanged. The M0 touch fixture and its separate saves remain available to the regression suite. Version 3 adds campaign/sequence/time/generator metadata and complete-tick recovery states. Implementation was authorized on 12 October 2026. The user authorized M1 and later implementation without a physical-device gate and subsequently tried an Android build, providing UI and resource-designation feedback. Physical release gates remain pending.

| Gate | Status | Evidence / remaining work |
| --- | --- | --- |
| Godot 4.7.2 Standard / Compatibility | Pass | Exact official build `ed1daf0bf`; macOS and template archives match the official SHA-512 sums in `toolchain.lock.json` |
| Pure deterministic prototype state | Pass | 72,000-tick 1x/2x/4x trace hashes match; Park-Miller golden stream; atomic designation / duplicate-command / session rejection |
| Gestures and button alternatives | Pass, local subset | Pan, tap, long press, second finger, paint preview, explicit Confirm, double submit, zoom/camera/nudge buttons; Android emulator citizen tap verified; touch-generated mouse events filtered so they do not become a second finger; formal physical gesture/task battery still Not run |
| Portrait / landscape / large text | Pass, local subset | Real Controls at 360x640, 390x844, 640x360, 800x1280, 1280x800, 960x600; 100/125/150% text; nonzero safe insets; visible buttons >=48 logical units; native screenshots inspected |
| Prototype save recovery | Pass, local subset | Checksum/schema/bounds rejection, pending command and movement round trip, three verified immutable generations, interrupted temp ignored, damaged latest falls back |
| Background / return | Pass, local subset | Simulation stops, gestures canceled, resume paused; Android 35 emulator also preserved the 4x2 unconfirmed preview across rotation; physical task battery still Not run |
| Android storage plugin | Pass, build/unit/emulator subset | Original Kotlin v2 plugin; 4 JUnit bounded-stream tests; source builds debug/release AARs; Android 35 arm64 emulator picker export/import passed: checksum verified, tick 1861 restored to exported tick 1800; Home froze the imported state; export and import cancellations left state unchanged; same-identity APK update preserved three private saves |
| Android arm64 APK | Pass, debug/emulator subset | Current debug export passes; min SDK 29 / target 36; arm64-v8a only; merged manifest requests only optional-feature VIBRATE; earlier revisions installed and launched on Android 35 emulator (SwiftShader/ANGLE), not a physical phone |
| macOS native launch | Pass | macOS 26.6.2, Apple Silicon, Apple M5 Pro, OpenGL 4.1 Compatibility via Metal 90.5; native scene/UI runner launched |
| Physical Android installation/input/rotation/storage | User-tested subset | User installed and tried a phone build; reported oversized/clipped controls and fuzzy rendering. Smaller controls, arrow buttons, MSDF fonts and area designations are implemented and emulator-tested. Rotation/storage/performance task battery is still pending |
| Physical memory/battery/thermal baseline | Not run | The user supplied a CPH2655/Adreno 830/Android 36 CPU/frame-gap report from 0.7.24, retained in ANDROID_DEVICE_EVIDENCE.md. Android PSS, brightness-controlled battery and thermal measurements remain Not run. |
| Native thirty-minute twenty-resident proxy | Pass at `4515ea6` / v7; later revisions separate | Frozen 75 completes 1,800.006347 seconds at 2x, 36,000 ticks from 3,002 to 39,002, twenty residents and zero counters; lowest one-second FPS is 28.587. Sampled peak/ending growth of 15,468,248 bytes passes the unchanged 20 MiB proxy and separate second audit. Actual endpoint matches the old 63 retry after one current alignment tick, without normalization. A late frame peak of 36,017,872 bytes remains unresolved. Earlier failures and physical/PSS/thermal gates remain separate. |
| Twenty-resident simulation tick budget | Not yet met in latest native proxy | The 36,000 individual ticks in 75 average 5.033 ms, with a 91.190 ms maximum. The p95/p99 bucket upper bound is 33.334 ms; p95 is above 25 ms versus the 4 ms target. Frame-gap p95/p99 bounds are 36/50 ms at the 30 FPS cap. Wall callbacks include host scheduling and worker overlap. Further scheduler/route work and physical validation remain. |
| Desktop export packages | Pass, build subset | macOS universal ZIP, Windows x86-64 EXE/PCK, Linux x86-64 executable/PCK exported locally; only macOS native launch exercised |
| Remote CI | Pass at `25cb2c0`; current revision separate | [Observed workflow](https://github.com/maccam912/brackenward/actions/runs/38786789304) passes 28 suites / 2,892 assertions, Kotlin 4, 768 maps and all four actual native replay/migration/persistence/startup targets. native-ci-v78-evidence.json audits the exact artifacts and publication. Current 79 CI and physical certification remain separate. |
| M1 visible work loop | Pass, automated/native subset | Four actual residents, starting supplies/equipment, A* movement, atomic reservations, 8-unit hauling, build escrow, seven structures, gathering, cooking, eating and sleep; 72,000 ticks at 1x/2x/4x match; real UI orders and native screenshots inspected |
| M1 cancellation and saves | Pass | Build/cook cancellation in Fetching/Delivering/Working; haul cancellation in Fetching/Delivering; ledger conservation, duplicate receipts, mid-edge/held-input save continuation, schema/checksum rejection |
| M2 durable journal foundation | Pass, filesystem/replay subset | Commands and complete-tick markers checkpoint every 2 foreground seconds, frames verify length/checksum/sequence; exact replay, torn-tail retention and damaged-latest fallback tests pass. Background still freezes and snapshots. Five campaign slots, ten named snapshots, verified staged import/replacement and storage-failure choices are implemented |
| M2 sustainable food / storage / rooms | Pass, automated subset | Four residents survive eight days without starvation damage using 16 actual turnip tiles and default cooking; crop rates at 75/100/125% and dormancy, food aging through transfers, granary/cellar ratios, door-bounded rooms and wall removal, food runway with spoilage and reserve policy pass |
| M1 to M2 save continuity | Pass | Original committed M1 fixture migrates; old journals replay under frozen M1 code before migration; verified untouched backups precede subsequent snapshots |
| M3–M6 gameplay and progression | Implemented; pinned v7 Charter/Winter/raid and broader v6 evidence | Frozen current-v7 generator-2 policies pass all four 96-day Charters and separate no-barter/import audits, all 30 first-Winter maps, and 30 paired prepared-defense/physical-ransom cases. All four v7 post-Charter origins also complete96additional days (192 total), preserving original command prefixes with no zero fullness/grace violations. Four current-v7 imported-cloth economies also pass24days with exact physical purchases/sewing/delivery and eight healthy residents. The v7 ordinary twenty-person seasonal rerun now passes its full96days and separate audit:20home residents for every tick of both seasonal windows,health100 within each window and whole-campaign minimum72. Pinned generator-2 v6 ordinary twenty-resident seasonal windows, four additional 96-day post-Charter cases, first-week and merchant-material economies pass in their recorded scopes; earlier failures remain retained. M7 physical/human gates remain open. |
| Revision-2 release map sweep | Pass, pinned current v7 | Current-v7 source `424f897` passes all30,000 maps (10,000/site), independent geometry/quantity checks and separate second audit, zero retries/fallbacks. Original v6 full sweep/boundary goldens remain untouched. Balance and physical/human gates remain separate. |
| M7 release quality | In progress | Animated citizens/animals/guests, matching portraits, editable cosmetics, environment art, audio, accessibility, diagnostics and rebinding are implemented. Localization, balance/playtesting, stress optimization and platform/human release gates remain. |
| Development APK publication | Pass at `25cb2c0` | [Downloadable APK prerelease](https://github.com/maccam912/brackenward/releases/tag/dev-25cb2c097d10), code 231 / 0.7.78-m7+25cb2c0, APK SHA-256 `a1e7e5c3eac078074cc803eb715dbb67359aed3102263ab9369087aebed1ee68`. Four-host artifacts, 28 suites / 2,892 assertions, Kotlin 4 and exact published assets audited. Current 79 publication and production signing/store release remain separate. |

Prior 0.7.80 recorded validation: 28 maintained GDScript suites / 2,902 assertions. Current 0.7.80 freshly passes scheduler 438 (five new checks), persistence 502, unit 24, care 55, fire 23, defense 81, replay 62/all retained acknowledgements, catalog/font 671, messages 5 and Android 119 export/metadata. Cached Kotlin 4 XML is inspected. The other 21 headless suites and native GUI 679 retain their fresh 79 scopes; presentation/persistence/generation/scenes/catalogs/immutable fixtures are unchanged. Complete original-search four-pair timing and full unsorted state/invariant comparisons pass. Native 79 completes ten minutes at 4x with twenty residents and both audits passing its periodic heap/time/counter proxies. Separate frame peaks, the 4 ms tick target and physical/human gates remain open. Version 78/code 231 is last fully audited remote publication; current 79/80 remote scopes remain separate.

Design amendment: Android compile/target SDK 36, build-tools 36.1.0, NDK 29.0.14206865, Gradle 8.11.1, AGP 8.6.1, Kotlin 2.1.21 match the downloaded 4.7.2 template. The original design's SDK 35 / NDK 28 pins conflicted with that template. No gameplay numbers changed. The template emits an AGP compile-SDK support warning; it remains recorded rather than treated as device validation.

Current weekly quota policy (user updated 16 October): continue polishing against DESIGN.md, prioritizing visuals, until the weekly reset occurs or weekly remaining usage falls below 25%, checking live limits periodically and at checkpoint boundaries. Starting remaining usage for this run was 73%. If the game is complete earlier, continue useful polish to the cutoff. Physical-device and human release gates remain distinct from implementation. Earlier thresholds in historical checkpoint notes are superseded.

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


## 0.7.14 ingredient-order keys and planner defense recovery

Ingredient selection computes each stack's exact expiry, distance, lexical item
ordinal and immutable ID once, then compares native integer keys. Small requests
still return only the required prefix without sorting the caller's array; large
requests retain the full in-place sort. The former comparator remains independent.
Fifteen additional reference comparisons cover three origins, short/large requests,
reserved quantities, ground and granary/cellar aging, item ties, full return values
and caller-array behavior, with no canonical mutation.

A paired microbenchmark alternates former/current order after five warmups, eighty
calls each, against the same 1,000-stack synthetic fixture. For requests of 1, 4,
16 and 40 units, former/current totals are respectively 158.727/63.888,
155.574/62.954, 316.156/76.040 and 1,117.561/223.139 ms. Every selection matches,
and canonical state is unchanged. These are selector CPU measurements, not a
whole-game or phone certificate. The complete crowded 1,200-tick benchmark still
matches its instrumented twin and all prior canonical hashes; its provisional
7.986/8.048-second totals overlap campaign workers and other validation.

The 27-suite headless baseline passes 1,555 checks; four subsequent planner
regressions bring the baseline plus targeted rerun to 1,559. Native UI passes 517
(2,076 total). Scheduler is 211, production 37 and the final Charter suite 73.
The final ten-day replay passes in 84.184 seconds, including strict schema-22
preservation and foreign-save continuation. The actual snowy continuation retains
its full frozen hash after 1,200 ticks. Catalog/media/glyph checks and seven parser
tests pass. Final Android export/four Kotlin checks and native source launch pass;
`aapt` confirms 0.7.14-m7 / 53. `a853f3b` passed all remote jobs and published its
checked development APK; this revision's remote results follow its own push.

A new four-case, 96-day Charter sweep runs from frozen clean `a853f3b`, all three
Standard sites plus Pine Hearthside, seed 104729. The harness retains original
source identity, process/error status, raw reports and exact final snapshots;
passes require all five stages, ceremony, Continue and at least another day,
eight living residents and no departure. It never retries a failed run or
replaces earlier evidence. This sweep is not yet complete: Pine Standard failed
through ordinary settlement loss at tick 155759, minimum health 4, with retained
hunger counters and an exact verified final save. That is a recorded failure.

The preserved tick-151200 Pine checkpoint has all three raids Resolved but four
residents still drafted. The planner sampled every 300 ticks and could miss the
brief Retreating state, after which its early return failed to issue Stand down.
The corrected planner queues that public command when no raid remains; four
regressions verify no command in a quiet undrafted colony, missed-window recovery,
pending-command deduplication and actual normal command application without
material grants. Manual player drafting rules are unchanged. The running frozen
sweep retains its original planner; a fresh corrected-plan run is still required.
The crisis evidence remains in the ignored pine-v3-drafted-crisis-151200 directory.
A separate controlled hungry-cook experiment also fails to prepare food despite
supplies and has no invariant error; its interruption/recovery behavior is under
investigation, separate from the identified planner defect. No recovery pass is
claimed. Performance, localization and physical/human gates remain open.


Final native crowded profiles retain source fingerprint
`76c5e9f60cbd2c49f9cb3ecf8cd1eb62f903995f3edb5bbaf3f19fd66b0bf59e`.
Two Charter workers are observed at each start/end. Tick medians are
2.730–2.968 ms, p95 35.036–44.282 ms, with maxima 131.355–141.292 ms.
All keep requested speeds, clean storage/invariants and sub-0.04-second backlog.
These remain timing failures and are not matched against the preceding unopposed
rows. Full rows and selector measurements are in STRESS_EVIDENCE.md.


## 0.7.15 food-shortage recovery / content v4

A controlled legacy-map fixture with grain, wood and one Cooking worker exposed
a real interruption loop. Starting at fullness 200, the old scheduler prepared
no meals in one day, made 903 job records and left its cook at health 36/rest 0.
The same supplies with an initially fed cook produced eight meals and 44 records.
The corrected hungry case produces eight real meals, first at tick 2313, eats at
2343, retains health 100/rest 1000 and creates 43 records. This controlled fixture
is not an ordinary campaign certificate and contains explicitly supplied grain.
Its original v3 snapshot and raw provenance are retained.

Before abandoning a task for hunger, the scheduler now checks exactly what food
would be available after release, without mutating the task or inventory. Own
releasable reservations and dropped carried food count; protected trade/packing/
payment/opportunity/supper-bank stock and retained ordinary escrow remain reserved.
A safe feasible portion still interrupts work normally. Otherwise workers and
sleepers keep progressing, rather than repeating input fetching or sleep jobs.
A redundant defense assignment also bypassed the life-critical hunger decision;
it is removed. A starving guard can prepare/eat food, retains the draft flag and
resumes defense once fed. Rest thresholds, food costs, hunger damage and all other
job priorities remain unchanged.

Content `colony-v4` declares the corrected future scheduling; campaign schema stays
23 and envelope 5. Its catalog hash is
`9050640ffbad94cff96a3ffd74251185e1b4c43e197c74a9dacf6d711166021e`.
Every released numeric definition is identical to retained v3. The codec verifies
old v2/v3 hashes and upgrades only headers, preserving existing state rather than
healing damage or granting materials. Unknown catalogs remain rejected; a newer
content error identifies both requested and supported versions.

Fifty independent preview comparisons actually release a deep-copy reference for
ten task kinds and five inventory locations, preserving the original canonical
state. Seven recovery checks cover real cooking, conservation, critical sleep,
starving guards, resumed defense and critical-rest precedence. Fifteen migration
checks cover five frozen v3 acknowledgements, the untouched schema-20 foreign
fixture, exact delta bytes, catalog/version rejection, backup retention and later
play. The v3 600-tick delta is folded before upgrading. Its acknowledged state
matches the original even though replaying those ticks under v4 would differ;
the migrated cook subsequently recovers and checkpoints exactly.

All 27 headless suites pass 1,631 checks; native UI passes 517 (2,148 total).
Scheduler is 268, persistence 261 and Charter 73. Three real tutorial flows pass
22 checks each. Catalog/media/glyph validation and seven parser tests pass.
Final ordinary replay passes in 91.595 seconds with 62 commands/234 invariants,
current save continuation, strict original schema-22 gameplay equality and the new
six-save acknowledgement migration audit. The original replay input/goldens and
foreign fixture remain untouched; the separate v4 golden retains that same raw
foreign fixture SHA `ed04e21b0da3c5076fc66da1e27246257f6dbdf77fd9bbfaf00bc8b9bec318f9`.
Current canonical initial/7200/72000 hashes are
`2463a273b157ffa445ea25231ffd1d23641bf727f48501fb5650bfb2075ff42e`,
`6dd1f932024049d125986be770973e714a6dc8164cd159c138ebdbfe58ec23de`,
`dcda1d2f1dcff062223fc37d54ff9f4563fb2b7103241bb418cc9d95d14d3784`.

All thirty frozen v3 Winter saves also preserve every gameplay field under their
original content header and pass current invariants/round trips without advancing
time. This is a migration audit, not thirty new v4 Winter simulations. The actual
snowy 1,200-tick continuation matches its instrumented twin and frozen source
under the old header (`dc4cec824baf861a3f693a934c4667f109d4b2839a7c28c9c343f63c189723a8`);
the crowded continuation likewise retains its old-header hash
`b9cfe7a9c9e5469082a9aec02f0a075b7e165581c1b8f5a4cecaa1d22d5cc771`.
The profiler now resets derived indexes after copying a world and reports when
normalization to an older header is representable.

Android export/four Kotlin checks and native sixty-frame, audio-drained startup
pass; `aapt` confirms local 0.7.15-m7 / 54. `977313e` passed all remote jobs and
published its checked APK. This revision's remote status follows its own push.
The original a853f3b Charter sweep retains its Pine settlement loss and Meadow's
one-hour timeout/partial checkpoints; neither is a 96-day pass. A separate clean
977313e Pine Standard run uses the corrected public Stand down planner, has reached
all five Charter stages and continues toward its requested endpoint. Its final
certificate and the remaining original cases are still pending. Performance,
localization, v4 long campaigns and physical/human release gates remain open.


Final crowded native rows retain runtime/media/profiler fingerprint
`5e313a313355041ce806d16997695ba9b3667ff5beb684488608074e9b4fe049`.
Tick medians are 2.790–2.988 ms, p95 34.016–46.005 ms, with maxima
126.690–142.196 ms. Two campaign workers are observed at every start/end.
Requested speeds, sub-0.1-second backlog and clean invariants/storage hold, but
simulation/frame gates still fail. Full rows are recorded in STRESS_EVIDENCE.md.
Further history-query optimization and the remaining M7 work continue.


## 0.7.16 historical inventory reads

Trusted complete-tick reservation, fetching, cargo-count and food searches borrow
the existing live stack view instead of repeatedly scanning all depleted records.
The view is private and read-only; filtering creates a separate array. Delivery,
release and completion retain their full-history metadata writes. Direct calls
outside a tick retain their original full-history behavior. No saved field,
content version, ordering, reservation rule or material ledger changes.

The scheduler suite passes 272 checks. A new reference comparison runs 1,200 ticks
with 8,000 historical zero-count carry records alongside a real cooking job; the
full-history and optimized worlds match at four checkpoints. All historical rows
still receive delivery location/owner metadata. All 27 headless suites plus native
UI pass 2,152 checks. The native frozen replay passes 62 commands and 234 invariant
checks in 105.482 seconds, including both old-schema gameplay and six-save v3
acknowledgement preservation. Snowy and crowded 1,200-tick continuations retain
the preceding v4 hashes and match their independently instrumented twins.

A benchmark checkpoint derives from the corrected 977313e Pine Standard run's
verified Day 86 partial save at tick 612,000 (10,183 stack / 13,228 job records).
Loading through v4 and advancing 2,400 ordinary ticks without the planner produces
the daytime benchmark at 614,400: 10,209 stack records, 590 positive stacks,
13,260 jobs, eight residents and 104 structures. The source partial is retained;
this derived snapshot is profiling evidence, not an ordinary campaign certificate.
Its raw SHA-256 is `a4306a225e39ab1701275a7815b6ad8ac57031679fd989e4ca1ac9bfe3cabd99`.
The 1,200-tick canonical result matches frozen eabef3b exactly:
`38c3c1ff65e2bfd52b6a79e5c0d3ff1b2416ffafd36720add35e71d100654506`.
Observed uninstrumented CPU time falls from 10.410 to 6.151 seconds; instrumented
work callbacks fall from 4.326 to 0.650 seconds. Both short runs overlap the old
Charter worker; these are development observations, not physical-phone timings.

The corrected 977313e Pine run timed out after one hour. Its last verified daily
checkpoint at tick 612,000 has eight living residents, minimum health 100, no
starvation beyond grace, all five stages, completed ceremony at 373,501 and
Continue. It does not satisfy the requested 96-day endpoint. The obsolete a853f3b
sweep still retains the Pine settlement loss and Meadow/Reed timeouts; remaining
Hearthside evidence is pending. A fresh 30-case v4 Winter matrix is running from
clean frozen eabef3b, separately from the v3 migration audit.

Remote eabef3b CI completed successfully on all jobs and published its checked
APK. This revision's remote status follows its own push. Current local Android
export/four Kotlin checks pass, with aapt reporting 0.7.16-m7 / 55. Physical-phone,
human and final stress gates remain open. Weekly remaining is 77%; work continues.

Four thirty-second native profiles retain the same runtime fingerprint. Fresh
lodge at 1x/4x has main maxima 5.317/5.451 ms and tick p95 0.854/0.817 ms,
with no callbacks above 50 ms. Late 1x/4x still reaches 188.775/148.219 ms
main maxima and tick p95 27.475/30.472 ms. All keep requested speed, clean
invariants/storage and backlog below 0.1 second. They overlap campaign validation
workers; STRESS_EVIDENCE.md records source, loads and contention. Performance
remains incomplete.


## 0.7.17 indexed job/stack ID lookup

Complete derived ID maps serve job and stack lookups only during trusted ticks.
They scan appended records, retain the original dictionaries and answer absent
IDs without full-history scans. Source replacement/shrink and import/generation
reset the maps. Other tables and direct calls preserve their original behavior.
The maps do not enter saves or alter immutable IDs, material accounting or ordering.

Nine new scheduler checks exercise identity, absent IDs, append-after-miss,
record mutation, array replacement/shrink, explicit reset and non-world arrays.
The full-history oracle now also overrides history lookup. The scheduler passes
281 checks, including the 8,000-record continuation and exact crowded tick order.
All 28 suites pass on the initial wider index implementation; narrowing it to
job/stack tables is followed by final scheduler 281, persistence 261, native UI
517 and frozen replay reruns. The baseline plus final targeted coverage is
2,161 checks, with zero failures. The final replay passes 62 commands and 234
invariant checks in 94.781 seconds, including schema-22 gameplay and six-save v3
acknowledgement preservation.

The first attempt indexed five tables; alternating tests exposed a cold-save
regression, so small citizen/structure/resource tables retain their earlier lookup.
The final four-pair comparisons retain exact state for fresh, snowy, late and
crowded continuations. Median original/current CPU seconds for 1,200 ticks are
0.431493/0.430595, 2.854603/2.865872, 7.021411/6.684699 and
8.656637/8.744747 respectively. This is about a five-percent improvement in the
large-history late save, with no useful gain in the other fixtures. Background
Winter workers overlap; STRESS_EVIDENCE.md records scope and reproducible tools.
It does not demonstrate lower frame-time tails or physical-phone performance.

The obsolete frozen a853f3b four-case Charter sweep is now finished: one actual
Pine Standard settlement loss and three one-hour timeouts, source unchanged and
zero completed 96-day certificates. Verified periodic Meadow/Reed/Pine Hearthside
snapshots all completed Charter and Continue; their health/food outcomes remain
explicitly separate. The corrected 977313e Pine Standard partial is healthy at
Day 86. CAMPAIGN_EVIDENCE.md records endpoints, hashes and failed-audit provenance.
The two finished validation checkouts are archived after evidence retention.
Fresh v4 Winter validation has three passes recorded so far and remains running.

Final Android export/four Kotlin checks and native sixty-frame/audio-drained
startup pass; aapt reports 0.7.17-m7 / 56. Prior 44fffb9 remote CI passed every
job and published its checked APK; this revision's CI follows its own push.
M7 localization, further performance/balance and physical/human gates remain open.
Live weekly remaining is 76%; work continues.


## 0.7.18 English message keys and placement plurals

The English presentation catalog has 292 referenced keys: 265 keys replace 290
static control/help call sites, and 27 keys cover placement messages and named
parameters. All converted static calls retain their exact English text and order.
The formatter substitutes original template tokens once, keeps braces in inserted
player text literal, selects singular only at count one and never mutates supplied
arguments. It does not change saved names, facts, command identifiers or simulation
state. English remains the release language; there is no new language selector.

Placement now says one tile/tree/resource and one blocked cell stays unsubmitted;
zero/many use their plural forms. Six formatter checks and six real UI checks
cover those branches and prove preview rendering leaves the canonical world and
pending commands untouched. Persistence passes 267 checks and native UI 523;
the existing baseline plus targeted reruns is 2,173 GDScript checks. All three
real tutorial flows pass 22 checks each. Five new Python catalog-contract checks
and seven string-lexer checks pass; CI runs both. Content validation rejects
duplicate/missing/unused UI keys, malformed placeholders and inconsistent plural
branches, and checks all catalog characters against the licensed fonts.

Final Android export/four Kotlin checks pass, with aapt reporting 0.7.18-m7 / 57.
The APK contains the compiled formatter and the exact catalog bytes. Two native
thirty-second fresh-lodge profiles at 960x600 / Balanced retain unchanged scoped
fingerprint `d69d0a461d4a586d3bf6a47b8e001581c453b6621215880256ab7671ee9fc3b4`
(296 files). At 1x/4x, main p95 is 0.990/1.350 ms, main max 4.476/5.244 ms,
and tick p95 0.856/0.805 ms. No callback exceeds 50 ms; speed, sub-0.1-second
backlog and clean storage/invariants hold. Background Winter/validation work
overlaps these source measurements; they do not certify phone performance.

This is the shared-controls/static-help and placement portion of localization.
Dynamic reports, sheet titles, remaining UI templates and presentation of canonical
activity/fact text still require the wider M7 audit. The v4 Winter matrix has six
passes recorded and remains running. Prior 36ca85d CI is still pending at this
checkpoint; each later revision retains its own remote status. Further performance,
localization and the physical/human release gates remain open.

The final sixty-frame native main-scene startup passes with audio drained. Live
weekly remaining is 76%; implementation and polish continue.


## 0.7.19 owned-job order and inactive previews

Within trusted ticks, assignment enumerates the few reciprocal citizen/job links
instead of filtering every retained job record. Derived ID maps now hold row
offsets, so sorting those references preserves original imported array order,
including accepted terminal jobs that still own workers. Same-search releases
remain visible, the next search rebuilds, and direct calls preserve the full-history
path for deliberately incomplete fixtures. There are no new save fields, material
changes, command changes or content/schema increments.

Five new scheduler checks cover accepted terminal ownership, reversed row/ID
order, live release, next-search rebuilding and direct-call fallback. The scheduler
passes 286 checks; all 27 headless suites plus native UI pass 2,182 checks, including
527 real UI and 267 persistence checks. The frozen replay passes 62 commands and
234 invariant checks in 103.864 seconds, including both migration-preservation
audits. Paired four-round measurements against the retained 2f1a8fb reservation/
lookup implementation preserve every final hash/invariant. Median old/new CPU
seconds for 1,200 ticks are fresh 0.393062/0.400365, cold 2.858674/2.807195,
late 6.782724/5.926181 and crowded 8.952732/8.965696. The late-save improvement
is about thirteen percent; the other cases show little change. Background Winter
workers overlap these development measurements; frame/hardware gates remain separate.

A second concrete UI issue was repeated validation of canceled/confirmed painting
footprints while the controls were hidden. A fresh-colony reproduction paints a
256-cell floor preview, cancels it without submitting work, then runs at 1x/4x.
The old UI still computes preview text on every frame and revalidates on changing
ticks. The fix skips that hidden presentation work. Four native UI regressions
exercise a real visible area, canceled area during time progression, changed
geometry after reopening and accepted construction after confirmation. Hidden
validation is zero in both inactive cases; active validation still runs.

Two thirty-second profiles per implementation use the same setup, Balanced,
960x600 and actual center 68,63. Before/after source manifests differ only in
GameSession's guard and project version within the measured scope. At 1x, main
CPU p95 falls 8.813 -> 0.906 ms; at 4x, 9.743 -> 1.309 ms. Old preview p95
is 7.850/8.713 ms across 901 calls per row; the fix makes zero calls. Final
speed, sub-one-tick backlog, clean storage/invariants and unchanged object loads
hold. The profile harness explicitly checks setup did not submit work, reports
preview state/timing and resets every derived cache on trace cloning. Full hashes,
context and callback counts are in STRESS_EVIDENCE.md. This is Mac CPU evidence,
not a physical Android freeze/performance certificate.

Android export/four Kotlin checks and native sixty-frame/audio-drained startup
pass; aapt reports 0.7.19-m7 / 58. Both 36ca85d and 2f1a8fb passed every remote
job and published their checked APKs. This revision's remote status follows its
own push. The v4 Winter matrix has twelve passes recorded and is still running.
Localization, broader performance/balance and physical/human release gates remain
open. Live weekly remaining is 76%; work continues.


## 0.7.20 bounded creation reads and native soak preparation

Equipment proposals and construction-helper parent searches borrow private live
job/inventory containers in trusted ticks. Their original state/count predicates
still exclude same-tick ended/depleted rows, queued equipment still prevents
duplicate proposals, and direct calls keep full-history behavior for incomplete
or reopened fixtures. Public unfinished-job results remain fresh, immediately
filtered caller-owned lists. Cancellation/completion metadata scans stay intact.
The full-history scheduler oracle also overrides the new borrowed job view.

Seven new creation checks use real shared-material table work plus 8,000 terminal
job and 8,000 zero-stock records. The accepted/conserved fixture compares retained
04500fb creation code with current proposals, repeated calls, queued equipment,
same-tick depletion/new stock and direct fixture reopening. Scheduler 293,
equipment 17, construction 21, production 37, persistence 267 and native UI 527
pass. Prior full baseline plus these final targeted checks totals 2,189. Content,
five UI-message checks, seven lexer checks and six new soak-audit checks pass.
The final frozen replay passes 62 commands/234 invariant checks in 85.911 seconds,
including both migration-preservation audits. Cold/crowded continuations retain
the preceding hashes and their instrumented twins match. The 1,200-tick late
continuation is 4.844 seconds, exact canonical result
`38c3c1ff65e2bfd52b6a79e5c0d3ff1b2416ffafd36720add35e71d100654506`.

A separate creation microbenchmark alternates four old/current pairs with 200
creation calls at one fixed tick, including initial derived-view setup. Median
milliseconds per 200 calls are fresh 2.761/3.071, cold 461.737/48.018,
late 2,049.268/85.531 and crowded 123.690/123.255. All final hashes/invariants
match. These operation timings are not whole-tick/frame or ordinary-play claims.

Two thirty-second native late-save runs at Balanced, 960x600 and center 68,63
retain fingerprint `7b512c1765e4fa0202fe745e28f7b534e06d675f4b4e1231d9157afe067278de`
(296 files), unchanged. At 1x/4x, tick p95 is 15.662/12.914 ms and maxima
55.075/52.978 ms; main CPU p95 is 13.644/26.612 ms. Each has one main/tick
callback above 50 ms. One frozen Winter worker is present at every endpoint.
Requested speeds, clean invariants/storage and sub-one-tick backlogs hold; actor/
object counts and full rows are in STRESS_EVIDENCE.md. The 4 ms simulation gate
still fails; this does not certify physical-phone behavior.

The new native soak uses the actual GameSession, bounded product diagnostics,
minute invariant/engine-heap/RSS samples and one-second drawn-frame counters. It
requires logical time, resident population, source/input hashes, private saving,
audio drain and an exact final snapshot round trip; pauses/failures remain retained.
The Python launcher freezes provenance, bounds/kills its process tree on timeout,
refuses old output directories and independently audits report/log/snapshot pairs.
Audit checks reject incomplete/dropped time, zero-exit engine errors, changed files,
missing snapshots, population loss and memory/storage/invariant failures. Engine
heap/RSS and the drawn-frame floor are local proxies, not Android PSS/thermal or
complete release gates. A three-second native canary at 2x/one-second warmup passes
with twenty residents, valid round trip and unchanged source; the thirty-minute
case remains pending and cannot be inferred from it.

Android export/four Kotlin checks and native sixty-frame/audio-drained startup
pass; aapt reports 0.7.20-m7 / 59. Remote 04500fb passed every job and published
its APK. This revision's CI follows its own push. The frozen v4 Winter sweep has
29 passes and one case still running. Remaining M7 scope and physical/human gates
stay open. Weekly remaining is 76%; work continues.

## 0.7.21 food-aging lookups, HUD refreshes and fresh Winter results

Food aging looks up each store owner's preservation rate once per Living advance,
including the missing-building case for painted stores. Positive food still ages
every tick and retains exact fractional age, spoilage, reservations and held-input
cancellation. Seven checks compare the entire retained cf34471 advance path with
current behavior across cart/granary/cellar/painted stock, same-tick transfers,
destroyed storage and reserved-food expiry. A 200-stack fixture makes sixteen
structure lookups across four advances versus at least eight hundred previously.
No persistent rate cache or authoritative payload change is introduced.

The calendar/stock label reuses its text across unchanged display frames, refreshes
on tick/world-instance/speed changes and uses nine new English message keys (301
total), including traveler plurals. Native controls exercise repeated refreshes,
real accessible stock, adoption at an equal tick, immediate pause/4x display,
season/year rollover and zero/one/many prototype travelers. The simulation remains
unchanged by presentation queries; the stock line now follows same-frame food
warning pauses.

All thirty fresh v4 Winter cases at eabef3b pass independently: eight residents,
minimum health 100, zero zero-fullness/starvation-beyond-grace ticks and 23,760
invariant checks. A second 0.7.20 audit loads/round-trips every exact endpoint
without advancing time or changing source bytes. The per-case hashes and audit
digests are in WINTER_MATRIX.md. This is current v4 survival evidence; the fresh
v4 96-day Charter sweep remains running from unchanged cf34471 source.

The first thirty-minute native probe stopped during warmup at tick 1802 with
speed zero and no storage/invariant failure; it did not complete measured play.
Its exact final save and failed audit remain in native-soak-v4-cf34471. The earlier
harness reset diagnostics before retaining the pause origin, so that cause is
unproven. The revised harness settles startup window notifications while paused,
then still fails on later pauses/focus loss, and retains bootstrap/warmup failure
context. A 60-second warmup plus 3.033-second measured native canary passes:
61 ticks, twenty residents, minimum drawn-window 29.964 FPS, peak sampled engine
heap growth 164,584 bytes and exact final codec round trip. This does not count as
a thirty-minute pass or Android memory/thermal/performance certification.

The new 1,200-tick late/cold/crowded continuations match their frozen canonical
results and instrumented twins. Late is 4.064 uninstrumented CPU seconds, cold
2.225 and crowded 9.049, with concurrent Charter/native/headless work. These
contended single observations do not establish a device performance budget.
Final checks: survival 83, persistence 267 and native UI 538 pass; the retained
full baseline plus these targeted additions totals 2,207. All 301 catalog keys,
five UI-message checks and six soak-audit checks pass. The first clock fixture
used wrong stock values and a nonexistent helper; the guard rejected its script
error despite continued suite output. Both are corrected and its final native
rerun passes all eleven additions. Frozen replay passes 62 commands/234 invariant
checks in 81.709 seconds, with both preservation audits passing. Android export
and four Kotlin checks pass. Native sixty-frame/audio-drained startup passes; aapt reports 0.7.21-m7 / 60.
All cf34471 remote jobs passed and its stable-identity debug APK is published;
this revision's remote checks follow its own push. Weekly remaining is 74%;
implementation/polish continues.

## 0.7.22 shared recipe selection and production reads

Production proposals and maintained-stock counting borrow the trusted-tick live
job/inventory views with original state/count predicates. Queued work, same-tick
cancellation/depletion/new stock and direct fixture reads remain visible. Explicit
food recipes reuse the existing exact prefix-selection helper, preserving expiry,
distance, item and ID order without another comparator/sort implementation.
Cancellation/completion/history metadata writes remain full scans.

Twelve new production checks retain cc84275 creation/stock functions plus its
complete step with only the production call changed to the reference. Accepted,
conserved fixtures include real Maintain/Repeat recipes, research, 120 food stacks,
8,000 terminal jobs and 8,000 depleted rows. They compare complete payloads across
proposals, duplicates, cancellations, stock depletion/append, direct reopening and
six complete-tick checkpoints through 600 ticks. Production 49, scheduler 293 and
persistence 267 pass; the retained full baseline plus additions totals 2,219.
Native UI's 538-check baseline is from 0.7.21; no local graphical rerun occurs while
the frozen thirty-minute soak runs. Current revision CI includes its UI run.

Four alternating old/current pairs of full 1,200-tick continuations retain identical
hashes/invariants in every pair. Median old/current CPU seconds are fresh
0.416156/0.413192, cold 2.473606/2.468693, late 4.527185/4.525181 and crowded
8.613415/8.500077. Most are near neutral; the crowded difference is small. The
headless comparisons overlap two Charter workers, the native soak and other tests,
so they do not establish phone/frame-budget compliance. The full old step stays
as an independent oracle rather than measuring the optimized implementation twice.

Frozen replay passes 62 commands/234 invariant checks in 83.397 seconds, with
strict schema-22 gameplay and all six frozen acknowledgement-preservation audits
passing. Content validation, Android export and four Kotlin checks pass; aapt
reports 0.7.22-m7 / 61. Native startup remains the successful 0.7.21 source run
while the graphical host is reserved for the frozen soak; this revision's fresh
native launch/UI/replay/export checks also run in its own remote workflow. The frozen v4 Charter and native-soak runs remain active.
Weekly remaining is last observed 74%; implementation/polish continues.

## 0.7.23 forecast, panel and diagnostic presentation keys

Ninety-six new keys cover food runway/demand/harvest explanations and all 75 fixed
panel headings. A further fifteen cover bounded performance-report stages, sample
counts, device line and copy/size notices: 412 validated English keys total.
Portions, days, hours, raw-food units and diagnostic samples use exact one/other
forms. The initial stock label and quarter-hour forecast rounding stay unchanged.
No language selector or translated release is added.

Fixed panels carry an explicit title key alongside their original internal route
identifier. Heading, adaptive full heading, navigation caption and tooltip use
the display text; body dispatch, keyboard callbacks and icon paths keep the fixed
identifier. Dynamic literal names keep their braces and bypass key lookup. The
79 literal title/key call sites match their original English values. Saved
expedition quote labels, rejection receipts, crop reasons and canonical facts
remain untouched; numeric forecasts render separately from their old English
labels. Remaining dynamic title/report/control templates and canonical activity/
fact presentation are still an open localization audit.

Twelve new headless text checks cover saved-label/input immutability, no residents
versus no food, singular/plural/quarter-hour timing, next harvest, literal reason
braces, all 75 English title mappings and every bounded diagnostic stage, including
an overflow percentile that must remain >1000 rather than a finite value.
Persistence 279 passes, as do catalog/font validation and five Python UI-message
checks. All three real-control tutorial flows pass 22 checks each from generated
sites. Three new native UI assertions cover title/route separation, literal names
and keyboard navigation. After the frozen soak stopped, the current native UI
runner passed all 541 checks; the retained local baseline plus additions is 2,234.
The rendered 360x640/150% performance panel was inspected: its adaptive title,
scrolling report controls and fixed Pause/navigation remain accessible.

ANDROID_TEST.md now starts with current-colony placement/camera regression and
manual diagnostic collection steps; it retains the historical M0 battery under
an explicit historical heading. The updated document does not mark physical
phone tests complete. The 0.7.21 workflow passed every job and published its APK;
0.7.22 remote checks remain separate. This presentation-only revision retains the
preceding replay evidence; its own CI runs the full suite/replay and native UI.
Android export and four Kotlin checks pass; aapt reports 0.7.23-m7 / 62.
Native sixty-frame/audio-drained startup passes.

The cf/cc native-soak outcomes remain failed evidence. The cc84275 run completed
819.099 measured seconds at requested 2x, then paused on the durable-progress guard:
one slow-storage pause, no background/speed-reduction/storage-alert count, writer
busy, twenty residents and clean invariants. It advanced 16,366 ticks before the
pause (nominal 16,381), verified/drained and wrote an exact final save. Maximum
simulation batch was 175.540 ms and session 177.279 ms; histogram p95 bounds are
50 ms, with frame-gap p95 bound 100 ms. These are contended source callbacks,
not individual-tick percentiles or physical Android measurements.

At the endpoint are 483 intact structures, 1,355 positive stacks, 1,785 unfinished
jobs (496 executable/1,108 queued) and 1,426 Chronicle entries. Hostiles and visitors
have left; this declining synthetic load is not the full all-alert release scene.
Sampled engine heap ends 21,423,840 bytes above the warmed baseline, with a
49,995,928-byte transient peak. The independent audit correctly fails completion,
time/speed and the conservative peak-heap proxy. Sustained Android PSS/thermal
behavior remains unmeasured. All raw data and the failed source remain retained.
A 120-tick current-code continuation from that save matches its instrumented twin;
assignment accounts for 1.410 of 2.545 instrumented CPU seconds, guiding the next
optimization. Pine Standard has independently finished its fresh 96-day Charter
case at tick 693,000; the other cases still run, so no four-case pass is claimed.

## 0.7.24 reservation input scans and assignment breakdown

A reservation attempt aggregates its held escrow/carry/reservation/move-bundle
quantities by item before committing any input, and groups candidate source rows
by item in the trusted-tick path. It preserves direct-call source behavior, input
iteration/order, reasons, partial/held goods and atomic reservation. Food
replacement collects escrow and candidates together instead of rescanning every
stack separately for each allowed ingredient. Temporary views live only inside
the call; full history metadata writes remain unchanged. Gameplay/content stays
v4, with no catalog, field or future-state changes.

Eleven new scheduler checks retain the complete 2e4d4c1 reservation/food paths,
accepted conserved cooking fixtures, 8,000 zero-count carry-history rows, actual
Fetching/Delivering/Working/Complete phases and released partial escrow. Every
complete-tick checkpoint matches through 600 ticks. Scheduler 304, production 49,
maintenance 32, trade 27, region 107 and native UI 541 pass; the retained baseline
plus additions totals 2,245. Frozen replay passes 62 commands/234 invariant checks
in 83.196 seconds, including both preservation audits.

The new headless assignment profiler retains the current assignment search with
three timed static prechecks and method timings; its ordinary complete-tick twin
must match. On the retained failed-soak state, 144 cooking-reservation calls
accounted for 655.066 ms out of 1.376 assignment CPU seconds across 120 ticks.
Consolidated scans reduce that callback observation to 456.342 ms, with exact
canonical result 79e27f51bd8c69c2ed41147f5be3de2d17c67bbdbdc286ecb53c64122389a910.
Four alternating full 120-tick old/current pairs retain all hashes/invariants:
median 2.784311/2.590877 seconds, about 7% less CPU time in this contended case.
This does not satisfy the frame/tick budget or repair the remaining scheduling
cycle. All four old/current pairs of each 1,200-tick input retain exact hashes/invariants.
Median seconds are fresh 0.478119/0.478933, cold 2.394684/2.399340, late
4.640473/4.658494 and crowded 8.507721/8.572756. Those small regressions are near
neutral and are reported explicitly; the gain is in the observed reservation-heavy
state, not a broad phone/frame speed claim. These headless runs overlap Charter,
replay, tests and import work.

Investigation also isolates a separate scheduler defect: ordinary needs release
an owned cook for low rest even when the later sleep branch refuses ordinary
sleep because fullness is low. The resident then reserves that same cook again.
The retained soak endpoint has twelve owned Fetching cook jobs and hungry workers
with rest around 230. A separate exact instrumentation probe confirms 144 owned cook releases and 144
successful reacquisitions over 120 ticks, zero meals produced and unchanged
canonical outcome; its raw result is sleep-cycle-v4-before.log. This is an observed
bug, not a passing gameplay gate. Its behavior fix is deliberately separate from
this exact-state optimization and still needs regression/migration validation.
Android export/four Kotlin checks pass; aapt reports 0.7.24-m7 / 63, and native
sixty-frame/audio-drained startup passes. The 0.7.22 workflow passed all jobs and
published its APK; this revision's CI follows its push. Weekly remaining is now
73%; work continues.

## 0.7.25 feasible sleep interruption / content v5

Ordinary needs previously released an assigned job at low rest even when the
later sleep branch rejected ordinary sleep because the resident was hungry.
The same cook was then reserved again. The retained failed-soak save demonstrates
144 owned-cook releases and 144 successful reacquisitions in 120 v4 ticks, with
no meals produced. The corrected v5 run from the same input records zero of each;
its counter-only instrumentation matches the ordinary simulator exactly.

Interruption and task selection now share sleep eligibility: needs sleep, and
fullness >350 or rest <=100. Feasible eating, critical rest, emergencies and
existing sleep retain their priorities. Eleven new regressions cover fullness
0/200/350 at rest 200, actual physical cooking and eating, critical/ordinary sleep,
food availability and preserving a hungry sleeper. A conditional resident-card
explanation shows the low-food/rest rule without expensive feasibility queries.
No food, work, rest or health is granted.

This is a declared future-rule correction: content v5 hash
5ec5ef41a343f0fae9fe4b016b0b462182f7ed9ec28d5d23fa55b07691a46576.
The v4 catalog remains immutable; every definition except the version is identical.
Schema 23, envelope 5, settings 4 and generation 1 remain. Imports verify the
released v4 hash, normalize only content headers after folding old deltas, and
retain exact originals/backups. Five v4 acknowledgements and a 600-tick v4 journal
were captured from frozen fdadd7b before changing code, with a pinned producer and
manifest. Their full fields, original bytes and codec round trips pass. The old
acknowledged low-rest colony remains hungry/tired as saved, then returns to eating
through later real work; its test does not require unearned healing. Six older
v3/foreign acknowledgements and strict schema-22 replay gameplay also still pass.

All 28 suites are freshly run: 2,270 checks, including scheduler 315, persistence
292 and native UI 542. The first failures were a stale expected v4 label and a
test incorrectly demanding full health after continuing an already-hungry old
acknowledgement. The label is updated, its exact old-field checksum stays fixed,
and the latter requires genuine later food recovery/alive residents while pure
loading still preserves health exactly. Failed raw logs remain retained. All 413
UI keys/font glyphs/catalog contracts validate. Separate v5 replay goldens retain
the original foreign save bytes; the final replay passes 62 commands/234 invariant
checks in 71.753 seconds, including schema-22, v3 and v4 preservation audits.

New canonical hashes: initial
6aa7855780cba1bc14a389f7f0e8a92697120238fd7460817d835f57cab993a7;
tick 7,200 09f767be351ebd13046add506fd4e159c3edf37c03acc575c61f7a6631243f48;
tick 72,000 82c84fd7703f16634a4683eda11fe8a5add36bcf071c5102852319dc7b09aff1.
The v4 golden/fixtures remain unchanged. The synthetic failed-state 120-tick
future result intentionally differs at
5b3f08c1f78936a1f73574edddd9e03808dae3863eecea75c36d8236f0bddc35.
Separate contended observations reduce its uninstrumented CPU time from 2.278 to
1.109 seconds; assignment timing falls from 1.183 to 0.293 seconds. These are
behavior-changing comparisons from the same acknowledged input, not equality or
physical-phone/frame-budget certificates. A 1,200-tick v5 continuation separately
matches its instrumented twin at
7a5453430dde249e9f76a9de5f09738683350264beb816fe83aacd9524a3d2cc.

Fresh v4 Charter validation finishes 4/4 at frozen cf34471: Standard at all three
sites plus Pine Hearthside, 96 days through tick 693,000, eight living residents,
all stages/ceremony/Continue and 9,216 invariant checks. Meadow's minimum health 4
and 56,992 starvation-beyond-grace ticks remain a balance/recovery limitation;
Pine Standard minimum 90 has no beyond-grace ticks, and Reed/Pine Hearthside stay
100 with none. Full hashes/source/audit digests are in CAMPAIGN_EVIDENCE.md. All
four load under v5 with exact old fields and round trips, without advancing time;
the thirty Winter endpoints also pass that v5 loading audit. These are v4
campaign certificates and later migration checks, not fresh v5 campaign runs.
The local Android debug export and four Kotlin tests pass; aapt confirms
0.7.25-m7 / code 64. Native startup completes 60 frames and drains audio. Two
separate 30-second Balanced native profiles use the retained failed-soak input:
1x advances 289 ticks, 4x advances 1,160, with requested speed retained, no
background/storage alerts/reductions, clean invariants and unchanged source.
Both retain severe first/occasional simulation spikes (maximum batch 1,166.620 ms
at 1x and 1,139.843 ms at 4x). Session p95 histogram bounds are 16/100 ms and
frame-gap bounds 50/100 ms. These are short CPU observations of a heavily loaded
save, not a soak pass or physical Android result. Raw sleep-v5-native-1x/4x
reports remain retained for follow-up. Fresh v5 long runs remain open.

Remote fdadd7b now passes the full checked workflow and APK publication; this
revision will have a separate workflow. Weekly remaining usage last observed
72%; authorized work continues. The new phone export and latest requested
placement, deletion, zoom, sleep pacing and quiet-night acceleration work are
tracked in ANDROID_DEVICE_EVIDENCE.md and remain subsequent work.


## 0.7.26 immediate placement feedback, speed restoration and wider zoom

Confirmed commands now immediately derive hatched placement/resource marks from
pending saved state. They do not advance the simulation or grant inventory/work.
A subsequent preview has its own enabled Confirm; repeated Confirm on the hidden
previous preview stays idempotent. Pending building footprints prevent duplicate
claims on the same layer, while floor-under-building remains supported. Invalid
paint cells keep their existing visible reasons. All receipt IDs are reconciled,
including rejections, and the pending marks retire after actual tick processing.
The M0 fixture's distinct command shape remains supported.

Placement records entry speed before the first menu pause, carries it through
nested menus and restores precisely 1x/2x/4x after confirmation. Paused entry stays
paused. Cancel, explicit Pause, backgrounding and world replacement clear the
resume intent; guarded storage/ending checks still apply. Paused new commands
trigger a full verified snapshot at the same logical tick rather than being
skipped by the journal's equal-tick guard. Another same-tick command is captured
again. Durable-progress checks include queued command IDs.

Maximum zoom-out is now 2 logical pixels per tile, versus 16, retaining the
64-pixel close limit and cursor/pinch anchor. Settings schema 5 accepts and
retains this wider range; v4 upgrades preserve every previous setting and the
original preference file until an explicit save. Nonfinite camera data rejects.

Fresh native UI passes 584 checks, including real pixel changes for a confirmed
paused marker, consecutive field/stockpile/build orders, pending-state recovery,
layer overlap, exact speed restoration through direct/nested entry, cancellation,
explicit Pause and portrait/landscape anchored zoom/preference restoration.
Persistence passes 295 checks, including v4 preference preservation and far-zoom
restart. The initial UI attempt caught an M0 command-shape omission, retained red
cell expectations and stale placement IDs in tests that directly swap worlds;
those are corrected, original failures retained, and the final suite passes.
Source/world changes invalidate placement receipt ownership. Local rendered
placement-confirmed-paused.png was inspected. Catalog validation passes all 416
referenced UI keys. Final Android debug export passes (0.7.26-m7 / code 65); all four Kotlin tests
pass. The native 60-frame startup/audio-drain check passes. Unit/integration
suites freshly pass 20/6 checks. Remote CI for 7015cc4 and this revision is
separate. Physical phone retesting remains pending.


## 0.7.27 campaign and named-snapshot deletion

Campaigns now offers Delete per occupied/retained slot; Named snapshots offers
Delete per existing named slot, including damaged copies. A review names the
selection and counts verified files/bytes, with Cancel and Permanently delete.
Campaign scope explicitly includes autosaves, named saves, replacement archives
and slot-1 legacy fallback. Named deletion includes valid, damaged and partial
copies of that slot alone. Other campaigns and named slots remain unchanged.

The private deletion helper hashes a sorted manifest, rejects linked/unreadable
paths and requires unchanged review evidence before detaching targets. Rename
failures roll back; cleanup failures leave a visible error and a retry control.
Cleanup recognizes exact random owned names, not arbitrary matching prefixes.
The campaign list uses cheap existence checks rather than hashing every campaign.
A Save problem panel also exposes Manage saves to permit freeing space.

The writer/preparation is joined/discarded before review; automatic saves stop
while its review is open. Deleting the current campaign retires its world and
returns to an unsaved first-colony placeholder. Logical time, Home/return and
Resume cannot recreate its files. Repeated/stale confirmation cannot delete
another slot or another adopted campaign. Storage failures preserve truthful
partial/cleanup status instead of claiming that bytes were reclaimed.

Persistence passes 308 checks, including exact other-slot bytes, damaged/partial
named copies, changed-review rejection, rename rollback, cleanup failure/retry,
owned cleanup names and a real macOS symlink boundary. Native UI passes 592
checks, including review/Cancel, repeated confirmation, other-campaign survival,
writer join and no active-campaign resurrection. Initial checks caught noisy
missing-directory enumeration and an incorrect fixture file-count assumption;
those were corrected and the original failed logs remain. The final
phone-sized rendered review is inspected, local Android export passes at code 66,
and final native 60-frame/audio-drain startup passes. Remote publication remains
a separate pending gate.
Schema 23/content v5/envelope 5/settings 5 remain unchanged.

The reviewed phone-sized delete-campaign screenshot is readable with both
48-pixel controls visible. New reviews clear stale success notices. The local
Android debug export passes (0.7.27-m7 / code 66) and the 60-frame native
startup/audio drain passes; final targeted reruns follow the evidence addition.

Remote 7015cc4 passes its main build and three native targets, but Windows
publication is blocked by the content-v4 preservation audit. Its gameplay
replay and all five acknowledgement rows pass. Reproducing Git's Windows
core.autocrlf filter identifies the frozen producer's 45 converted line endings:
expected LF hash 222dfdb75ea303e1c1997df64e79ef14f09023ca20ca2ebf594e7870e8a5b293,
CRLF hash df9ffc0e98e010b1eb46a935e7ffc642b0ff273351efae99c1a801ec6c8d0c1b.
An explicit LF checkout attribute now preserves that producer, and snapshot/frame
fixtures are explicitly binary. The same Windows-filtered local check now matches
the original producer hash exactly, with zero CRLFs. No frozen bytes or expected
hashes changed and the strict gate remains; individual delta/producer evidence
is now included in audit reports so a failure is directly diagnosable. Remote
verification/publication of this fix remains pending.


## 0.7.28 independent sleep pacing and idle research queues / content v6

Residents wake at rest 900 at any clock time. Sunrise alone no longer wakes a
still tired sleeper, and the preferred sleep window only starts sleep below
rest 600. Ordinary tiredness remains 300, preparation 500 and critical rest 100.
Beds recover 75/hour, bedrolls 60 and ground 45. Waking drain is exactly 37.5/hour
through alternating integer numerators, preserving the existing /300 saved
remainder unit. A normal bed balances sixteen waking hours with eight hours of
recovery from 300 to 900. Night shift offsets the preferred window, and energetic
residents do not all go to bed just because it is night. Camp sleep shares these
rules and rates. Resident and bed cards expose the actual policy.

A real low-rest migration regression caught a hungry cook staying asleep too
long under slower recovery. Hungry sleepers now recover to rest 300, then may
rise to obtain or prepare food even if no portion is yet feasible. Below that
minimum they retain sleep; the existing feasible-food and critical-rest rules
stay in force. Productive hungry cooks still avoid release/reacquisition churn.
The retained old low-rest colony again returns to real eating within its existing
4,800-tick check; no healing, food, rest or completed work is injected in play.

The new replay also exposed idle research queues: queuing after a completed
project could leave the queue waiting forever. A shared selection rule now
starts a ready head on idle Queue, the next real creation pass, or completion,
with actual prerequisites, order and banked insight preserved. Tests cover idle
selection, insight, a blocked head, eligible saved queues and three queued plus
one active project. A former insight test now selects its intended first project
before queueing; it keeps its exact discoveries, insight and XP expectations.

This is a declared future-rule change, content v6 hash
eb5fd60496e154184057859aad76683ffdd91acd839cf9335fa48293e3f6a9b5.
The v5 catalog remains unchanged; every definition except the version is identical.
Schema 23/envelope 5/settings 5/generation 1 remain. Six v5 acknowledgements and
a 600-tick v5 sleep journal were captured from clean 245f935 before changing rules.
Its fully rested residents remain asleep through 01:00 in the original state,
proving the reported clock gate. The immutable producer hash is
17e95a3e914fdd5771f314391ed1ff9371c10402eb1141a57adedec54f49d4b7, with
explicit LF checkout. Imports fold old deltas before header-only migration and
preserve all fields, needs/remainders/jobs, source bytes and backups; only future
play wakes those old sleepers. Six older v3 and five v4 acknowledgements still pass.

All 28 suites are freshly run: 2,367 checks, including scheduler 331, persistence
319 and native UI 593. New rest regressions cover independent tiredness/night
shift, exact physical 8/10/13h20m recovery, fully rested waking, needed sleep past
sunrise, exact sixteen-hour drain/reload and hungry cooking. Older numeric rate
expectations now assert the declared new values. The real first-day loop now
observes thirty hours rather than ending before a slower bedroll night can finish;
it retains the same real gather/haul/cook/build/eat/sleep, rest, food and conservation
requirements. Original failures remain retained, with final reruns of each affected
suite; no expected receipt or checksum was relaxed.

A separate v6 input retains all 62 ordinary commands and their times, using nine
Queue actions to preserve unfinished research rather than switching it away,
and the actual announced budget-2 raid 3976 instead of the earlier trace's 3979.
Its 16-wood price, strict accepted receipts, seed and other actions remain.
Original input/goldens/foreign bytes are untouched. Four failed recording attempts
retain prerequisite/full-queue/stale-ID evidence; the corrected recording and
independent verification pass 234 invariant checkpoints in 79.003/70.067 seconds.
The new v6 tick-7,200 save is newly captured on this host and is the next native
CI matrix's shared import, not a claim that its cross-host test has already run.

New initial hash c40f4e6b8f2fffc3b1806cef288ec9ed21c0147745adf419f1a453ce9a65a7b7;
tick 7,200 50bb80a8c127473adf03f8882bef3f0ac6b09844c42c14bc0cce3816cf7b920e;
tick 72,000 b996c5f4e4d953d234b3d967fc931582dbd426fc527e410e6dc92af5bee707d6.
The new foreign-save input SHA is
dbc248d219c6f2ee783ed802ea7e7a6a786db09f916064229b39095fd2401621.
Schema-22 preservation now explicitly audits frozen acknowledged endpoints; its
old future trace is not asserted equal to intentionally changed v6 sleep rules.
Fresh v6 replay independently checks the new future behavior.

Local APK export passes 0.7.28-m7 / code 67. The native sixty-frame/audio-drain
startup passes, and all three current tutorial flows pass 22 checks each. Catalog
validation covers 430 referenced UI keys. Separate 30-second Balanced native
profiles from the unchanged failed-soak input advance 290 ticks at 1x and 1,156
at 4x, retaining requested speed with no background/storage alert/pause/reduction,
clean invariants and unchanged source. Maximum simulation batches remain
1,155.267/1,156.637 ms; session p95 bounds are 8/100 ms and frame-gap bounds
50/100 ms. The largest first 1x assignment callback is 1,097.616 ms. These
short heavy-save CPU observations are neither a soak pass nor a phone certificate;
the assignment spike remains a performance target. Quiet-sleep acceleration above 4x remains
next work. Fresh v6 long-campaign/balance evidence and physical Android retesting
remain open. Weekly remaining last observed 70%; authorized work continues.

Current 0.7.28 header-only loading audits pass all thirty frozen v4 Winter
endpoints and all four v4 Charter endpoints, preserving every acknowledged field,
raw input byte and codec round trip without advancing time. Winter audit SHA
46e5ee5464c5902edfaa67070117e6352a85c16058f7af40e2c334d3ec2deb17;
Charter audit SHA 0143f08a723251fffc8933b5720fd0aa5f6e52cd9e9b31e45af32a7f80608f3a.
These are migration audits, not new v6 campaign/balance passes.


## 0.7.29 quiet-sleep playback and current validation

Quiet nights now automatically run at 12x while every living resident is actually
sleeping and no important event needs attention. Selected speed stays 1x/2x/4x;
the first waking or event tick ends acceleration exactly, without using leftover
bonus time on awake work. Walking to bed, hunger, downed/drafted residents,
departures, danger, flooding, warnings, pending orders, visitors/recruitment,
merchants and expedition decisions prevent the boost. The clock labels it
“12x sleep” and explains the retained speed. Pause/backgrounding stops time.
Settings offers an opt-out, enabled by default. Settings schema 6 adds only this
boolean and retains every prior schema-5 value; loading leaves original bytes
unchanged. Campaign schema 23/content v6/envelope 5/generation 1 remain.

An injected presentation clock limits a sleep batch to eight completed ticks and
checks an 8 ms CPU budget between ticks. Persistent bonus backlog suppresses the
boost for that sleeping period, reports a separate counter/notice and retains the
selected speed. Waking resets suppression. World rules/RNG/save facts never read
wall time. Fixed-speed profiles/soaks disable the optional boost unless requested;
profilers report selected versus actual playback and hash the exact executed
harness as well as product sources. The current harness also ran successfully
against clean frozen 0.7.28, which has no sleep-speed API or setting.

Twenty-four new scheduler checks cover deterministic twins, exact waking at each
selected speed, first-event cutoff with auto-pause enabled/disabled, foreground
budget/fallback, food and visitor/recruiter guards, pending commands and prototype
timing. Nine native UI checks cover the displayed clock, opt-out, background and
confirmation/speed interactions. Two persistence checks cover settings migration
and retained opt-out. Final scheduler 355, persistence 321, colony 42 and UI 602
pass; the maintained 28-suite total is 2,402. An attempted nonexistent diagnostics
suite was rejected by the CLI without executing; diagnostics are covered by the
passing persistence suite. Six Python soak-runner tests also pass. The generic
status notice now agrees with running/paused time; meaningful warnings remain.
The rendered phone-sized quiet clock was inspected.

A separate controlled input places four actual bedroll sleepers near waking;
it is a playback integration fixture, not campaign/balance evidence. In the final
12.033-second native run, exactly 100 accelerated ticks span 25 frames and stop
at tick 7,000 when a resident wakes, returning to selected 4x. Total ticks advance
6,900 to 7,448. Source bytes remain unchanged, invariants are clean, no background,
quiet-speed limit, storage alert/pause or manual-speed reduction occurs. The
12x simulation batch maximum is 1.162 ms, session maximum 1.319 ms and frame-gap
maximum 35.311 ms. Raw input/report/log and the earlier run remain under
quiet-sleep-v29-*. This is Apple M5 Pro/macOS 26.6.2/Balanced30 at 960x600,
concurrent with headless campaign validation, not physical Android certification.

Final Android export passes 0.7.29-m7 / code 68; aapt verifies that package version.
Native sixty-frame startup and audio drain pass. Content/media validation passes
438 referenced English UI keys. Previous ffdce48 CI passes all four native replay/
startup targets, build/tests and development publication; its APK, provenance
and checksum assets were explicitly verified. Current revision CI is separate.
The ffdce48 frozen v6 long campaigns remain running: two Charter and eight Winter
cases have completed successfully so far; daily/interim reports are not passes.
The heavy-save assignment spike and physical-phone freeze diagnosis remain open.
Weekly remaining last observed 69%; authorized work continues.


## 0.7.30 recovery-bed search and accurate sleep cards

The retained failed stress-soak save reproduces a large assignment stall at tick
19,500: several residents cross below 50 health together, and each independently
runs A* to every available recovery bed. The original 240-tick assignment trace
spends 1,208.311 ms in thirteen destination queries. An 18-second foreground
trace reaches a 1,310.760 ms simulation batch / 1,314.416 ms session callback at
that tick. This local reproduction is separate from the user's smaller CPH2655
colony and does not establish that every phone stall has the same cause.

Recovery selection now runs one breadth-first distance search per resident,
retaining exact passability/elevation/bridge rules, occupancy, lowest-ID distance
ties, first-record behavior when already at a bed and original cart-perimeter
fallback. Derived caches retain their previous position/occupancy/navigation
invalidation. No saved field, rate, ID, resource or content/schema value changes.
The original per-bed A* implementation is retained independently in
care_read_tests.gd. Fourteen new checks cover legacy/all generated sites, map
corners, occupied/departed residents, navigation changes, tie ordering, blocked
beds, cart fallback, complete-tick equality and save/reload.

The same thirteen queries take 7.695 ms in the new 240-tick trace, with exactly
the original final canonical hash
e5d422c8cebc73a575724a1e18852151a81f40d5e3cbc7d8baa4987367fe549e.
Four alternating full-tick pairs against the retained original all match hashes
and clean invariants; median full/fast elapsed times are 4,593,212.5 / 3,099,060.5
microseconds (about 32.5% lower). Both snapshot and complete declared source hashes
stay unchanged. Earlier runs and the exact source/oracle evidence are retained
under assignment-v30-* and care-search-v30-*.

The foreground 1x comparison reduces the problem tick's simulation phase to
144.939 ms, including 7.394 ms for recovery destinations; maximum session is
148.647 ms and frame gap 162.274 ms. The later 18.008-second 4x run advances
19,368 to 20,085 with the selected speed retained, no background/storage/error/
quiet-speed fallback/reduction, clean invariants and unchanged source. Its maximum
simulation batch is still 209.071 ms (session 210.883, frame gap 226.036), with
p95 bounds 100/100/250 ms respectively. Hauling storage queries and periodic work
creation remain material. These are short Apple M5 Pro/macOS 26.6.2 CPU profiles,
concurrent with other headless validation, not an uncontended performance budget,
thirty-minute soak pass or physical Android certificate.

Bed/bedroll station cards and the unassignment confirmation still contained old
hardcoded rates despite the corrected person/assignment descriptions. They now
read the same policy constants: 75/60/45 per hour. Two new station-card UI checks
and both existing orientation-specific unassignment checks assert these actual
rates. The design's building table also now agrees with the rest section; frozen
older catalogs remain untouched. The current catalog validates 440 UI keys.

Care 55, scheduler 355, persistence 321, colony 42 and isolated native UI 604 pass;
the maintained 28-suite total is 2,418. The initial final-UI attempt was invalidated
by overlapping graphical focus checks and stopped early with seven failures and
an array-access error; that raw log remains. The corrected isolated UI run passes
all 604 checks. The separately sequenced native sixty-frame/audio-drain smoke
passes. Independent current replay passes all 62 commands, both unchanged v6
72,000-tick goldens, 234 invariants, old acknowledged migrations and foreign-save
continuation in 101.301 seconds. Android code/name metadata was initially stale
in a local export; the corrected final export passes, and aapt explicitly verifies
0.7.30-m7 / code 69. The earlier export is retained as a metadata failure.

Frozen v6 campaign checks continue independently on ffdce48: twelve completed
Winter cases retain health 100, and the two completed 96-day Standard Charters
retain eight residents, all stages and Continue with zero zero-fullness or
starvation-grace ticks. Meadow/Pine minimum health is 82/87; those are scenario
results, not zero-damage claims. Remaining cases and independent completion
audits are still pending. Weekly remaining last observed 69%; work continues.


## 0.7.31 fewer assignment snapshots

Trusted-tick assignment now filters terminal/Queued rows in one ordered snapshot
instead of first copying public unfinished work and then filtering it again.
Direct calls retain the earlier public-query membership. The first matching
arrival is looked up from that same snapshot only if the search reaches that
branch, rather than allocating another full list even for an owned worker who
returns early. Record references/order, releases, priorities and reservations
remain unchanged; no content/schema/settings migration is needed.

The complete d6b3dab assignment method is retained in assignment_read_tests.gd.
Eleven new checks compare full ticks and save/reload for two thousand historical
jobs, hungry personal tasks, an actual accepted newcomer/arrival, the crowded
hazard/reservation fixture, Queued work and direct cached/reopened membership.
Scheduler now passes 366, colony 42, population 57, region 107 and native UI 604;
the maintained 28-suite total is 2,429. Independent replay passes the same 62
commands, both unchanged v6 goldens, all 234 invariants, frozen acknowledgements
and foreign-save continuation in 98.356 seconds. Content validation retains
440 referenced UI keys. Android export passes and aapt explicitly verifies
0.7.31-m7 / local code 70. Native startup/audio drain is separately sequenced.

Four final alternating 240-tick pairs from the unchanged failed-soak snapshot
match exact state and clean invariants; median original/fast CPU is
3,471,310.5 / 3,302,921.5 microseconds, about 4.9% lower. The earlier paired run
showed about 6.5%; both remain retained, rather than selecting the larger gain.
The final harness hashes all declared src/data/project/reference files before
and after and verifies they stay unchanged (source SHA
281ab7e4384a0902d0db1731bf0c48fb603868b9a8312b7480fb28a397c54a69).
A separate 720-tick instrumented run matches the ordinary twin; construction
step-aside and work creation still dominate its assignment/creation costs.

The final 18.023-second native 4x profile advances 19,368 to 20,087, retains
selected 4x, clean invariants and unchanged source, and records zero backgrounds,
quiet-speed limits, storage pauses/alerts or manual-speed reductions. Maximum
session/simulation-batch/frame-gap remains 196.250/194.514/207.845 ms, with
p95 bucket bounds 100/100/100 ms. Storage-context totals still produce a large
frame peak, so this is not a performance-budget or phone-freeze pass. All these
CPU measurements are Apple M5 Pro/macOS 26.6.2/Balanced30, concurrent with other
headless validation; physical Android and thirty-minute stress gates remain open.

5cf3cca now passes the full remote workflow, all four native targets and debug
APK publication; its APK/build.json/SHA256SUMS assets were explicitly verified.
The d6b3dab workflow and this revision remain separate pending observations.
Frozen v6 long runs now have thirteen completed Winter cases and two completed
Charters; remaining cases and independent audits continue. Weekly remaining last
observed 68%; authorized implementation/polish continues.


## 0.7.32 construction views and urgent-haul context reuse

Construction step-aside now reads a borrowed live-job view in trusted ticks,
retaining explicit terminal-state guards and Queued/partial blueprints. Direct
calls keep public-query membership. It preserves neighbor order, blocked exits
and in-progress movement. The complete earlier predicate remains independently
retained with the d6b3dab assignment oracle. Six new checks cover same-tick
Complete/Canceled rows, Ready/Queued work, all blocked neighbors and mid-edge
movement. The physical builder/idle-resident construction regression still passes.

The profiler now retains eight worst frames as well as its original first 64 slow
frames, plus the frame-end tick for each phase peak. This exposed the later
20,060-tick frame: before-leisure urgent work retried many old haul jobs, building
storage context afresh for each. The normal candidate loop already shared one.
Emergency and urgent-before-leisure scans now use that same conservative rule:
share only consecutive failed unowned hauls, clear before every other kind, end
on success and start fresh for each resident. A preliminary build-probe reuse
was tested but not retained; it did not explain this stress save's repeated work.
Its original logs remain. The retained change introduces no broader cache lifetime.

Six further regressions compare both urgent branches against original full ticks:
one exact context across failed hauls, no partial reservations or ledger change,
and a fresh context when the next resident sees newly available storage. Scheduler
passes 378; construction 21, persistence 321, colony 42 and native UI 604 pass.
The maintained 28-suite total is 2,441. Independent replay passes all 62 commands,
both unchanged v6 goldens, all 234 invariants, old acknowledgements and foreign-save
continuation in 84.496 seconds. Catalog/media validation retains 440 UI keys.
Android export passes; aapt verifies 0.7.32-m7 / local code 71. Native sixty-frame
startup/audio-drain passes separately after the UI run.

In the same 720-tick stress trace, storage-context builds fall from 320 (about
130–141 ms total) to two (1.536 ms total), one normal and one urgent sequence,
with exactly identical full state and clean invariants. Four final alternating
720-tick pairs against the retained d6b3dab search/predicate all match state:
median original/fast elapsed CPU is 7,361,512.5 / 6,526,943 microseconds (about
11.3% lower, including the prior assignment snapshot optimization). The declared
source remains unchanged, SHA
8a5664701975723bbba743c74c129149b906429a050757152d6db785c21f9f74.
These working-source timings preceded the final version-only package stamp.

The foreground 4x comparison's tick-20,060 frame drops from 195.552 to 83.591 ms,
and its storage-context aggregate from 102.156 to 0.740 ms. In the final
18.017-second run, 720 ticks advance 19,368 to 20,088, selected 4x remains,
invariants/source are clean/unchanged and all five counters stay zero. Maximum
session/simulation-batch/frame-gap is 105.853/104.162/121.998 ms; p95 bounds remain
100 ms. Periodic creation and assignment still miss the performance budget.
These are short Apple M5 Pro/macOS 26.6.2/Balanced30 CPU observations under
changing concurrent validation load, not physical Android or uncontended/soak
certification. The user phone report remains separately preserved.

The frozen ffdce48 v6 Charter matrix completes 4/4 with independent audit: all
four run 96 days to tick 693,000, retain eight residents/all five stages/ceremony/
Continue, zero zero-fullness/grace ticks and 2,304 invariants each. Minimum health
is Meadow 82, Pine Standard 87, Reed 100, Pine Hearthside 100. Current 0.7.32
loading preserves every acknowledged field, input byte and round trip with no
time advance. Full hashes and source/completion/audit provenance are recorded
in CAMPAIGN_EVIDENCE.md. Fresh v6 Winter remains in progress (sixteen cases
completed at this observation); physical/human and M7 performance gates remain.
Both d6b3dab and b2870e7 remote workflows pass all four native targets and debug
publication; b2870e7 APK/provenance/checksum assets were explicitly verified.
Current revision CI is separate. Weekly remaining last observed 67%; work continues.


## 0.7.33 literal detail titles and discoverable save management

Opening a resident/building/animal whose cosmetic name matched Build, Menu or
Work previously also populated that navigation panel. The same caption was
used by save/recovery and deletion guards. Detail cards now retain their exact
literal headings while a separate explicit action route controls navigation,
autosave/recovery handling, Work-page scrolling and delete callbacks. Modal
presence checks the actual panel. Built-in panels retain their prior routes,
keys/actions and captions; no world field, command, need, resource or saved format
changes. Other dynamic detail/lesson titles use the same literal boundary.

Ten name-collision cases cover residents and stations named Build, Menu, Work,
Delete saves and Save problem, preserving read-only state, exact headings,
paused time and normal closing. Two controls verify real Build/Menu navigation
still populates its intended actions. A separate isolated filesystem/UI regression
keeps a stale delete callback, opens a resident named Delete saves, emits that
old callback and verifies both snapshots and world remain unchanged. Actual
explicit deletion still works afterward. Current Menu now labels Campaign slots
as Manage saves, making the requested deletion path clearer; it opens the same
campaign management. Named snapshots retain their own delete controls.

Native UI passes 617 checks and persistence 321; the maintained 28-suite total
is 2,454. The first new UI run had one menu-label assertion failure before the
intentional label change; its log remains. The second run passes all 617,
including the full prior placement/camera/save/audio/viewport battery. Current
content/media validation passes. Native sixty-frame startup/audio drain passes,
and Android export/aapt verify 0.7.33-m7 / local code 72. Simulation code is
unchanged from the independently replayed 0.7.32 checkpoint; current remote CI
and physical Android remain separate. A longer frozen-source native soak is
next, with graphical tests serialized around it. Weekly remaining last observed
67%; authorized implementation and polish continue.


## 0.7.34 domestic creation reads and failed long-run evidence

Animal feed/product proposals now share only per-call live job and inventory
reads during an authoritative tick. Pending feed and animal actions are indexed
once, including Queued jobs; Complete/Canceled history is excluded explicitly.
Barn feed totals and age/ID-ordered candidate food are built lazily. Proposals
still reserve no food, retain exact order/quantity/IDs, and every later call sees
cancellation, depletion and new inventory. Direct calls outside a tick retain
the original full query path. Empty domestic state returns without scans.

The complete original 445f183 creation body is retained as an independent test
oracle. Twelve new checks cover aged food, two barns/twelve animals, 2,000 ended
jobs/zero-count records, Queued duplicates, cancellation, depletion, proposal
ordering, exact saves and 720 actual feed/collection continuation ticks.
Domestic passes 40 checks. Scheduler 378, persistence 321, region 107 and native
UI 617 pass. The maintained 28-suite total is 2,466. Replay passes 62 commands,
234 invariants, unchanged v6 goldens, all old acknowledgements and foreign-save
continuation in 87.451 seconds. Native sixty-frame startup/audio drain passes;
Android export/aapt verifies 0.7.34-m7 / local code 73. Original failed fixture
validation (a missing historical job input) remains retained; the fixture was
repaired before successful runs, without relaxing the codec.

Four alternating original/fast 720-tick stress pairs all produce exactly the same
full state. Median elapsed CPU is 6,894,287 / 6,099,239.5 microseconds, about 11.5%
lower. Declared 117-file source remains unchanged, SHA
`df085a415793da9d04302e986a434f8fea4446d7bc0920787886ab2bb64a7bbc`.
This compares only domestic creation against the original 445f183 body. These
Apple M5 Pro timings are local observations, with other validation active;
physical Android behavior and the 30-minute release gate remain unverified.
A short native 18.027-second/4x run retains all twenty residents and selected
speed, zero diagnostic counters, exact source and clean invariants. Maximum
session/simulation-batch/frame gap is 81.769/79.893/94.198 ms, still outside
the budget. STRESS_EVIDENCE.md records the full measurement scope.

The separate frozen 445f183 standard 30-minute/2x stress attempt fails after
1,214.875 measured seconds: twenty residents fall to zero, settlement end pauses
at tick 27,299, and the probe exits 1. Invariants, exact round trip, input/source
bytes and audio drain pass, but population, duration and heap-growth proxy fail.
Peak sampled engine heap growth is 53,836,730 bytes; final growth 12,517,070.
Lowest sampled one-second FPS is 26.127, without a low-FPS streak; declining load
and synthetic overload prevent a performance certification. The fixture exceeds
ordinary shared admission with downed guests plus hostiles and is not ordinary
balance evidence. All output and failed audit remain in native-soak-v6-445f183.
Input SHA is 3a65112145f5bf35ee179d02075d48a2accc037dd611630021c43d4460128e32;
final snapshot is 9447071783359673e28eb3ee78618374c9beaad6fda2e2a1934cb1bf3d1e8d54.
Audit SHA is 1ecfe5dcccc69ae4cc739a1d11c2fe640338b9df7d830f3025ff3dceec712c5c.

Fresh v6 Winter completes 29/30; Pine Shelf seed 73 reaches health 53 with
13,674 starvation-beyond-grace resident ticks despite stored food. This is under
causal diagnosis. A recorded temporary untracked-file mistake also makes the
completion's clean-source flag false; the aggregate audit exits 1. See
WINTER_MATRIX.md and WINTER_V6_AUDIT_DEVIATIONS.md. Neither failed run is
promoted to a pass. The earlier frozen v6 Charter 4/4 remains independently
verified. Remote 445f183 CI passes all four targets and publication; current
revision CI is separate. Weekly remaining last observed 66%; work continues.


The retained-command diagnostic helper checks exact original daily canonical
hashes, keeps initial/report files unchanged and writes a separate observed
snapshot. Initial canaries pass through ticks 7,200 and 14,400 on current 0.7.34.
The first attempt omitted commands queued by the ordinary policy before a daily
sample and correctly failed at tick 14,400. Replaying those pending commands
before comparing that checkpoint restores exact equality; no assertion or saved
state was relaxed. Original failed artifacts remain. This diagnostic invokes the
main checkout's toolchain explicitly and reports its actual source version;
it is separate from the frozen Winter sweep and cannot repair its audit status.


## 0.7.35 accessible entrances and causal hunger explanations

Exact replay of 264 commands reaches the Pine-73 pre-starvation tick 134,159,
matching all eighteen original daily hashes on current 0.7.34. Four newcomers
have fullness 1 and no feasible food inside the lodge at (68,60). Tree 2110,
replanted by command 135 at tick 65,401, is now solid at (72,66), immediately
outside the only door (72,65). The other residents can reach 22 meals, 156
mushrooms and 260 vegetables. No danger, flood or expedition explains the split.
The later recorded tree cut reopens access. This establishes an avoidable planner
obstruction; it does not change the failed Winter/soak reports into passes.

The ordinary-command planning policy now protects built/unfinished and planned
door approaches, avoids future-solid saplings at lodge/grow-room entrances, and
repairs older entrance trees through actual clear/gather work. It grants no
resources, instant destruction, movement or workers. Read-only approach queries
include rotated doors and gates; the policy builds one per-call approach set.
Runtime planting, maturity, food, activity strings and saved formats are unchanged.
Resource cards explain that maturity makes trees solid and point out entrance
sites while retaining normal actions. Hungry residents with stocked food but
no feasible safe portion get a detail-card access warning covering entrances,
danger and reservations. The warning disappears after access reopens without
a simulation tick. Existing meal/patient/expedition states retain their context.

Sixteen new policy regressions include real blocked-room geometry, physical
cutting and eating, exact save continuation, Queued door proposals, planned rooms,
rotations, duplicate suppression and normal public replanting. Six new native UI
checks exercise literal names, both tree states, paused/read-only observations,
instant access updates and excluded resident states. Charter passes 89, native
UI 623, nature 18 and persistence 321; the maintained 28-suite total is 2,488.
Native sixty-frame startup/audio drain and final Android export pass; aapt verifies
0.7.35-m7 / local code 74. Content/media validation passes 443 UI keys and unchanged
v6 gameplay catalog hash. Fresh clean-source Winter validation and current remote
CI remain separate. Weekly remaining last observed 66%; work continues.


## 0.7.36 cooking, fuel and hauling proposal reads

Core work creation now inspects live jobs, output records and usable wood/meal
stocks once per call. Cooking alternatives are read lazily once while each hearth
still selects its own exact expiry/distance/item/ID input order. Queued proposals
prevent duplicates; same-tick Complete/Canceled rows do not. Explicit recipe orders,
suspended/destroyed hearths, output record limits, home-resident demand and original
proposal/ID order remain exact. New proposals reserve no stock, so each still sees
the original shared quantities. Personal-job reconciliation remains before all
inventory reads, retaining actual drops and zero-record metadata writes. No cache
survives the call; outside-tick calls use the original public-query membership.

The complete original 7059064 creation method is independently retained and
byte-compared after indentation normalization (SHA
ce8d32402819bf052534fdf59223936631e838fb2468e783c2f9615908cc8c92).
Seventeen new regressions cover four hearths, 2,000 ended jobs and depleted stacks,
expiry ordering, duplicate/Queued/ended states, custom recipes, output records,
no home demand, direct calls, consumed inputs, real fuel/cook/haul work, reloads
and valid orphaned eating escrow. The first new run had two wrong fixture
expectations: the starting hearth already had four fuel, and mushrooms expired
before the initially aged vegetables. Reference and optimized states matched.
The fixture's vegetable age was corrected to exercise the intended expiry switch;
expected fuel proposals now reflect the actual initial stock. Original failures
remain, followed by 392 and final 395 passing scheduler checks. UI 623,
persistence 321, region 107 and colony 42 pass; maintained total is 2,505 across
28 suites. Replay passes 62 commands, both unchanged goldens, 234 invariants,
all old acknowledgements and foreign-save continuation in 94.018 seconds.

Four final alternating 720-tick original/fast pairs all retain identical complete
state and clean invariants. Median elapsed CPU is 7,478,766.5 / 6,097,987.5 us,
about 18.5% lower; the earlier four pairs observed about 15.6%. Declared source
remains unchanged (118 files), SHA
ce7a46647e820398b6cc03f13a3888737062e24b52b250c7860620c848452ce1.
Native 18.018-second/4x observation retains twenty residents and speed 4, zero
counters, clean invariants and unchanged source. Maximum session/batch/frame-gap
is 77.247/75.229/91.642 ms; p95 bounds remain 100 ms. Largest per-frame creation
aggregate is 8.293 ms, compared with the prior observation's 31.945 ms at a
different frame boundary. These concurrent Apple M5 Pro observations do not
certify physical Android, uncontended timing or the full release stress gate.
Native sixty-frame startup/audio drain and Android export pass; aapt verifies
0.7.36-m7 / local code 75. Catalog/media checks pass with 443 UI keys.

A public-command repair branch from the exact retained pre-starvation Pine-73
snapshot cuts tree 2110 normally, produces eight wood, and physically feeds all
four newcomers by tick 134,752 (593 elapsed ticks), retaining health 100 and clean
invariants without grants. Its report SHA is
99b8762d8fa8424d61e9f0e47778fe658d13e3186df5d3eddee687bdf9e58ef4.
The new frozen 7059064 Winter sweep is running separately: the first two cases
pass with minimum health 100 and no starvation. This is not a completed matrix.
Remote b47c183 CI passes all four native targets and publication, with APK,
build.json and checksum assets explicitly verified. Current revision CI and
physical Android remain separate. Weekly remaining last observed 65%; work continues.


## 0.7.37 reuse unchanged resource drawing groups

A new foreground environment-stage observer identifies resource grouping as the
fresh-colony far-zoom cost: 3,031 resources in 1,192 rows are sorted and regrouped
on every changed tick. Resource rendering now retains groups while visible IDs,
positions and actor/prop depth-partition IDs are unchanged. Live records still
redraw each tick, so sapling growth/maturity, depletion, tint and selection remain
current. Index rebuild and world adoption invalidate the cache, including equal-ID
replacement dictionaries. The original row/chunk/global-ID partition sort remains
unchanged when membership changes. This adds only presentation state.

The complete prior 603c1d0 refresh method is independently retained and compared
byte-for-byte after indentation normalization (SHA
08d64dbed1ef300b2147d086e6ce7efae4089a933401d31306654bd9cd320307).
Twenty-three native checks compare real row membership, depth metadata, current
record references, read-only world state and eleven rendered pixel buffers against
that original method. They cover unchanged ticks, selection, depletion, growing/
mature trees, a new prop, camera chunks, equal-ID table replacement, night tint
and campaign adoption. The first run's two reference assertions used the simulation
lookup cache after deliberately swapping a resource table without the normal
adoption reset. Both renderers already held the correct live records and all
pixels matched. The check now compares directly to the actual resource table;
no renderer behavior or assertion was weakened. The first log remains retained.
Final native UI passes 646, persistence 321; maintained total is 2,528 across
28 suites. Current game simulation is unchanged from replayed 0.7.36. Native
sixty-frame startup/audio drain and Android export pass; aapt verifies 0.7.37-m7 /
local code 76. Content/media checks pass 443 referenced UI keys.

Four alternating 100-call CPU pairs keep exact rows/world state and unchanged
six-file declared source (SHA
9eb232a513103b0fb585126964f6bd2b6549e0441b204c365e2e0b7e2499acd1).
Median full/retained refresh costs are 1,252,092.5 / 114,312 us per 100 calls.
The native fresh-colony 18-second/4x far observation lowers median map update
12.228 to 1.868 ms, and p95 12.639 to 1.972 ms. Resource refresh median lowers
11.858 to 1.521 ms; 541 callbacks each, ticks 1,800–2,521, exact source per run.
A final close-camera observation reports median/p95 map update 0.314/0.355 ms
and resource refresh 0.105/0.122 ms, unchanged source, no invariant failure and
selected speed 4. These Apple M5 Pro/macOS/Balanced30 results include concurrent
headless campaign work and exclude physical Android/GPU/thermal certification.
The original phone report remains unchanged and requires a later device retest.

The fresh clean frozen 7059064 Pine Shelf seed-73 repeat completes 33 days to
tick 239,400: eight residents, minimum health 100, zero zero-fullness/grace ticks,
792 invariant checks, exact final snapshot and round trip. Source/completion
remain clean/unchanged; full hashes are in WINTER_MATRIX.md. The separate full
30-case revised-policy sweep has four passing cases at this observation and is
still running. Its earlier failed run remains preserved. Remote 7059064 CI passes
all four native targets and publication; APK/build.json/checksum assets are
explicitly verified. Current revision CI and physical Android remain separate.
Weekly remaining last observed 65%; work continues.


## 0.7.38 readable resident overview and direct selection

The expanded zoom now retains recognizable residents: below 16 dp/tile, a fixed
32 dp card contains a 24 dp recolored portrait. Nearby residents share a stacked
pin and count, selected members supply its portrait and thicker outline, and a
cross marks downing or carrying a patient. Stable ID processing and a 64 dp
merged-bounds limit keep clustering deterministic and local. Pins sit above world
roofs/night tint and reuse a pool bounded by twenty residents. Cached styles and
portrait materials update only as needed; explicit drawing CPU is included in the
existing map timing counter. This is presentation state, with no world progress,
commands, resource transactions or saved-format changes.

Map selection uses each pin's displayed mean of actual interpolated actor points.
The existing 48 dp target, ranking and full chooser therefore include every member;
portraits ignore GUI events so real touch still reaches the map. Eligibility is
shared with actual sprites: dead/departed/carried/offsite actors get no ghost pin
or selection ring. Normal zoom restores ordinary sprite points. Explicit Follow
from overview zoom returns to a comfortable 32 dp/tile; placement retains its prior
camera contract. People help explains counts, tapping and care-cross shapes.

Seventeen new native checks cover actual touchscreen delivery through the new
Controls, complete/stable chooser membership, real resident selection, explicit
Follow, paused palette changes, care/high-contrast shapes, fractional movement,
eligibility, a valid twenty-person fixture, bounded node reuse, campaign adoption
and enlarged portrait/landscape layouts. The first movement assertion mistakenly
included hidden pooled actors from earlier fixtures; it now compares the four
actually visible actor positions, retaining the failed log and strict world-state
check. Native UI passes 663; persistence 321 passes; maintained total is 2,545
across 28 suites. Eleven original-resource image comparisons still match exactly.
Native sixty-frame startup/audio drain and final Android export pass; aapt verifies
0.7.38-m7 / local code 77. Content/media checks pass 444 UI keys. Actual far-phone,
care, 390x844/150% and 640x360/150% screenshots were inspected; portraits, care
crosses, counts and speed controls remain legible and separate.

A working-source 18.032-second/4x fresh far observation retains selected speed 4,
clean invariants, exact source and all five counters zero. Map-update median/p95
is 1.888/2.087 ms, retaining the prior resource-cache improvement; resource refresh
is 1.500/1.671 ms. Explicit draw callbacks are 2.969/3.347 ms. This is an Apple
M5 Pro/macOS/Balanced30 CPU observation with concurrent headless work, before the
later Follow-only callback finalization, not physical Android certification.
Simulation remains unchanged from independently replayed 0.7.36. The clean frozen
revised-policy Winter sweep currently has twelve passing cases; its complete gate
remains pending. Remote ed28488 CI passes all four native targets and publication,
with APK/build.json/checksum assets explicitly verified. Current revision CI and
physical Android remain separate. Weekly remaining last observed 65%; work continues.


## 0.7.39 prepared longevity fixture without runtime grants

The synthetic stress generator now optionally queues the existing normal
food_policy command to permit its already supplied travel-ration reserve. The
option defaults off, preserving the original fixture and all failed evidence.
No goods, people, health, work, weather or other initial field differs: only the
pending command and next command ID change. The command stays unapplied in the
snapshot and takes effect on the first ordinary tick. Counts remain exactly
20/12/32 residents/domestic/wildlife, six hostiles/eight neutral visitors,
400 structures, 1,000 positive stacks, 256 active targets, 192 crops, 1,000 Chronicle
facts and rain. Admission overload remains explicitly synthetic. The future probe
must retain ending counts and cannot certify a constant hostile/visitor load.

Three new checks compare the complete initial payloads, verify durable pending
policy/no load progress, and apply it through real first-tick simulation with an
identical save continuation and real food forecast. Persistence passes 324;
maintained 28-suite total is 2,548, including the unchanged 663 native UI checks
from 0.7.38. Native startup/audio drain, content/media validation and Android export
pass; aapt verifies 0.7.39-m7 / local code 78. Runtime gameplay/UI is unchanged.
The snapshot writer accepts --use-rations true|false and now refuses an existing
output. A deliberate attempted overwrite of the retained failed-soak input exits
nonzero and leaves its original SHA
3a65112145f5bf35ee179d02075d48a2accc037dd611630021c43d4460128e32
unchanged. A separate smoke snapshot passes, canonical
16bda08ba7d67f228f637684ac0bacd864f599d91931905a821084a803e4bb2a.
The next frozen-source native longevity run uses a newly named input; no outcome
is assumed yet. Physical Android and full M7 gates remain open. Current revision
CI is separate. Weekly remaining last observed 64%; authorized work continues.


## 0.7.40 natural twenty-resident seasonal planning and trade-free audit

The new twenty_colony scenario grows through sixteen ordinary newcomer offers,
with real bed/food acceptance checks, five actual lodges, three constructed
roofed farm rooms and scaled public field/recipe commands. Initial population,
inventory, weather and incident rules remain unchanged. The default eight-person
policies retain their exact target values. Meal-order expansion first cancels
its actual unfinished batch, then disables/replaces the old order using normal
commands, releasing held inputs and the occupied station. Resume recovers all
three room origins from accepted construction history.

Its strict acceptance windows cover every tick of year-three Summer and Winter:
57,600 ticks each with twenty home residents, no zero-fullness ticks, no deaths
or departures, no campaign beyond-grace starvation and at least one final day of
edible reserve. Ordinary recruitment cannot reach twenty before day 64. The
runner records the complete commands, daily canonical snapshots and final codec
round trip; run_large_colony.py requires clean frozen source and audits all
sixteen accepted admissions. No full twenty-person campaign outcome is assumed
at this checkpoint. The ninety-six-day post-Charter requirement remains separate.

Seventeen new synthetic planning/gate checks pass: real eligible ninth admission,
public designation of exactly seventy-two roofed crop tiles, unchanged world
outside queued commands, room/resume protection, actual reserved-batch
cancellation/replacement and exact seasonal boundary coverage. Charter passes
106; persistence passes 324. Maintained 28-suite total is 2,565 including the
unchanged 663 native UI checks. Catalog/media validation and Android export pass;
aapt verifies 0.7.40-m7 / local code 79. Runtime gameplay/UI is unchanged from
0.7.38, so native graphical tests are deferred while the isolated soak runs.

An independent read-only audit also verifies all four retained ffdce48/v6 Charter
endpoints as trade-free: no executed/pending barter command, historical trade
job, exchange, imported-goods ledger entry or opportunity receipt. Their original
audited snapshot hashes, ordinary campaign checks, complete source/completion
provenance and unchanged input bytes pass. Three Python tests reject hidden
transaction evidence while permitting expeditions and raid tribute. This is a
new audit of existing ninety-six-day campaigns, not four new simulations.
See CAMPAIGN_EVIDENCE.md for its exact digest.

Remote CI and APK publication pass for both 0.7.38 and 0.7.39, with APK, build
metadata and checksum assets explicitly verified. The revised frozen Winter
sweep has 24/30 passing cases so far. The ration-enabled native soak retains
twenty residents and clean invariants/storage at 27 minutes; completion and its
strict memory audit remain pending. Physical Android, broader scenario coverage
and human release gates remain open. Weekly remaining last observed 64%.


## 0.7.41 share the immutable background-save base

The completed frozen 0.7.39 native soak retains all twenty residents and runs
all 36,000 expected ticks over 1,800.013 measured seconds, with valid invariants,
round trip, source and audio drain. It fails the unchanged memory proxy: final
heap growth 26,896,076 bytes, sampled peak 58,547,825. Lowest one-second FPS is
27.911, all diagnostic counters zero, and there is no storage failure. This is
Mac native evidence with concurrent headless work, not Android PSS/thermal/frame
certification. STRESS_EVIDENCE.md records every endpoint/provenance digest and
the full failed outcome; no earlier failed result is overwritten.

The background writer was deep-copying its entire already immutable capture
to retain the journal base after every successful save/checkpoint/rotation.
Its CapturedStore now retains that exact recursively read-only capture instead.
The writer never steps a world; all live changes continue in separate mutable
records. Direct saves retain their independent deep copy. Existing durable
validation, crash order, limits, original history, pending commands and save
formats are unchanged.

Four alternating pairs on the retained final twenty-person snapshot compare
complete payloads and preserve source/input bytes and canonical state. Median
retention CPU drops from 8,510.5 to 34 microseconds and removes a 17,043,556-byte
(16.25 MiB) retained allocation. This small operation is not a whole-save peak
or passing soak claim. Eight new checks verify direct-world isolation, immutable
identity/unchanged-history sharing, exact recovery, pending command continuation,
prepared catch-up and cache replacement. Persistence passes 332; native UI passes
663 including asynchronous save/backgrounding tests. Maintained total is 2,573
across 28 suites. Native sixty-frame launch/audio-drained exit, content/media
validation, six soak-harness checks and Android export pass; aapt verifies
0.7.41-m7 / local code 80. A new frozen longevity result is still required.

The natural twenty-person run is frozen at 4540f9b/0.7.40 and is in progress
(day 19/eight residents with no beyond-grace ticks at last observation). The
revised-policy full Winter sweep remains 26/30 passing so far. Physical Android,
other outstanding scenarios and human gates remain open. Remote current-revision
CI is checked separately after publication. Weekly remaining last observed 63%.


## 0.7.42 consume only owned snapshot JSON during preparation

Full-snapshot preparation no longer retains/reparses its temporary escaped
envelope while constructing a second complete decoded tree. It checks the normal
envelope's exact size bound, releases that wrapper, and decodes its own newly
parsed, unaliased payload containers in place. Public decoding is unchanged and
remains nonmutating. Catalog/identity/type/depth validation, full restored-world
schema/reference/conservation checks, exact captured-payload equality, digest
checks and normal published envelope/byte readback are retained. No live/captured
world tree is modified; no simulator, content or saved-format change occurs.

The full original 6f4dc91 method is retained independently. Thirteen new checks
compare exact preparation and external codec results, invalid metadata/schema,
all encoding boundaries, four hundred generated representations with Unicode
and all thirty-two retained save fixtures after migration, preserving their
original bytes. Persistence passes 345; maintained total is 2,586 in 28 suites.
The latest local native UI result is 663 passing at 0.7.41. Further graphical
runs are deferred during that revision's isolated thirty-minute native soak;
current CI runs the complete UI/native matrix separately. Content/media and
Android export pass; aapt verifies 0.7.42-m7 / local code 81.

Four final alternating pairs on the retained twenty-resident endpoint preserve
all payload text/digests, input bytes, source fingerprints and world canonical
state. Median temporary sampled heap drops from 81,678,512 to 40,851,078 bytes;
CPU from 339,662 to 313,252 microseconds. This is a scoped headless preparation
observation, not a passing whole-session soak/PSS/frame certificate. Exact raw
report hashes and experimental source retention are in STRESS_EVIDENCE.md.

The revised Winter sweep is 29/30 passing at last observation; the natural
twenty-person campaign has fourteen residents around day 41 and no beyond-grace
starvation. The 0.7.41 soak remains alive with twenty residents and clean
invariants/storage so far. Full outcomes remain pending; physical Android and
human gates remain open. Remote 0.7.40 CI passes; current-revision publication
is separate. Weekly remaining last observed 63%; authorized work continues.


## 0.7.43 complete v6 Winter gate and explicit post-Charter continuation

The clean revised-policy first-Winter matrix at 7059064/0.7.35 completes 30/30
and passes independent audit, retaining unchanged source. Every case keeps eight
residents and records zero zero-fullness/beyond-grace ticks; all 23,760 invariant
checks, full-save checksums and round trips pass. There are 215 actual recorded
major incidents. Minimum health is 100 except Reed seeds 1 and 73 at 92, reported
without a zero-damage claim. The former Pine73 blockage case now has health 100
and no hunger/grace failures. Its original failed run and causal-repair evidence
remain retained. WINTER_MATRIX.md records all exact source/completion/audit
digests. Current 0.7.42 pure-loading audit passes all thirty endpoints, every
field/input byte and round trip without advancing time.

post_charter_sweep.py now requires the complete independently audited four-case
Charter origins before continuing each for ninety-six additional ordinary days.
It hashes twenty original evidence files, preserves initial bytes and the full
command prefix, links each endpoint canonically, requires another 2,304 invariant
checks, eight living residents without replacements/departures, no accumulated
beyond-grace starvation and one day's final edible reserve. A four-hour per-case
bound retains partial outcomes; outputs use a new directory and source stays
frozen. Six Python fault-injection tests reject short runs, missing invariants,
wrong source links/removed history, shortages, dead replacements, modified initial
bytes, failed processes and wrong snapshot digests. All four real origin reports
also pass the new input verification without modification. Full continuation
outcomes are not assumed. No runtime gameplay/UI changes from 0.7.42. Content/media validation and local Android export pass; aapt verifies 0.7.43-m7 / local code 82. The maintained GDScript total remains 2,586; graphical checks remain deferred during the isolated soak and current CI validates them separately.

The ordinary twenty-person run has sixteen residents around day 49, no beyond-
grace ticks and a substantial food reserve at last observation. The isolated
0.7.41 memory soak continues with twenty residents and clean invariants/storage.
M7 remains open for those outcomes, remaining economy/recovery scenarios, full
performance/physical-platform and human gates. Weekly remaining last observed
63%; authorized work continues.


## 0.7.44 exact checkpoint tags and durable publication

All simulation/UI/Kotlin/export and four native replay/startup jobs pass at both
6f4dc91 and 0a6d37c. Their first publication attempts failed with GitHub's
workflow-permission restriction after a later workflow edit landed on main.
Precreating their tags alone did not bypass the older workflow's explicit
target_commitish check. The exact successful CI APKs were downloaded, their
source metadata and SHA-256 verified, and matching drafts reserved through the
authorized local GitHub account. Retrying only the failed publication jobs then
passes both complete workflows. The separate 4042af1 workflow also passes every
job and publishes all APK/build.json/checksum assets.

New tools/push_checkpoint.py atomically pushes a clean committed main and its
exact lightweight development tag through the existing Git credential. It never
forces, replaces a tag or discards divergent remote work. Five real isolated-Git
tests pass for exact identity/idempotent retry, dirty/detached refusal, divergent
main and conflicting tags. The publisher verifies that the existing tag names
the checked commit, then creates its release with --verify-tag and no conflicting
older target_commitish. Untagged normal tip commits have a guarded fallback; an
older missing tag stops explicitly. No repository permission or secret changes.
See GitHub's release API workflow-authorization note:
https://docs.github.com/en/rest/releases/releases#create-a-release .

The frozen 0.7.41 soak stops at 1,364.757 seconds/tick 30,296 because the ordinary
durable-save guard pauses once, with a busy writer and no storage error/alert.
All twenty residents survive; invariants, exact final snapshot/round trip, source
and audio drain pass. Logical progress keeps up until stopping. Ending heap
growth is 13,718,932 bytes, sampled peak 53,558,932; duration, guard continuity
and the unchanged peak-memory proxy fail. Its concurrent headless campaigns,
local builds and artifact transfers are recorded context, not an inferred cause.
The complete failed outcome is retained. The next latest-source run temporarily
suspends the other headless campaigns to reduce host contention; ordinary-
campaign elapsed wall times will include that suspension.

No game runtime changes from 0.7.43. The natural colony has twenty residents
with no beyond-grace starvation, and post-Charter cases continue normally at last
observation. Current M7 gates remain explicit. Weekly remaining last observed
63%; authorized work continues.

Local 0.7.44 checks: all five Git-publication tests, six post-Charter verifier
tests and three trade-free verifier tests pass, as do content/media validation
and Android export (aapt 0.7.44-m7 / local code 83). The 28-suite GDScript
maintained total remains 2,586. New source has no runtime game changes.

## 0.7.45 final resource-distance guarantees and independent map validation

Fresh colonies now use generator revision 2. Independent raw-map BFS found
Pine Shelf seed 1's fourth extra stone 41 legal work-approach steps from the
cart; only 1,400 of the promised 1,600 stone units were within 40. Revision 2
protects actual short resource approaches against later solids and checks the
final 24/40-step quantities. Revision-1 generation matches the retained full
reference across eighteen boundary maps and all three fallbacks. Saved maps
and historical replay remain unchanged. See [GENERATION_EVIDENCE.md](GENERATION_EVIDENCE.md)
for exact scope, initial failed diagnostics, observer correction and commands.
The independent eighteen-map working-tree diagnostic passes; full frozen sweep,
inspected new golden hashes and revision-2 campaign balance are still pending.

All 28 suites were freshly run: 2,622 checks, including 663 graphical UI checks,
zero remaining failures after explicitly retaining revision 1 in old geometry
fixtures. Three tutorial flows, 234 historical replay checks, native launch,
catalog/media validation and Android export pass (local code 84 / 0.7.45-m7).
The 22 new Python observer/sweep-contract checks pass. A separate CI generation
job adds 256 hashed seeds at each site and gates APK publication; it is not the
30,000-map release certificate. Content/schema/envelope/settings are unchanged.

The clean ordinary revision-1 twenty-colony campaign at
`4540f9b0aea0169723b602354bfe5b49fb414c9a` completes all 96 days and audits Pass.
Sixteen normal newcomer acceptances grow four residents to twenty. Both full
year-three summer/winter windows have 57,600 home ticks with twenty living,
zero zero-fullness ticks and minimum health 100/76; whole-campaign minimum is
73, with no beyond-grace starvation or replacements. Final canonical hash is
`3041d1f00daf5c0f59b78054b8ffd556e97778c227d35343a191085e3442bdfe`,
snapshot SHA-256 `41495c97032fcb2bd56317b927ba55eea16332ac0a3866c835842b781d311175`.
Directory `large-colony-v6-4540f9b-meadow/`: source SHA-256
`70b7dcc3905ec84746948d6d3f8226b02300fef01b3d19f9f969006131a66c47`,
completion `8d2e91e120a1b5438ce98531d0edbe616a1a311ce416207faf1099625c88c76b`,
audit `01e3ff68ad75b8b951c9278430ed9d69cb7381926909dc4523e9f6f8c96e5e54`.
This is one ordinary seed/site, separate from native stress and new-map balance.

The complete native 0.7.44 quiet-host soak runs 1,800.03343 measured seconds,
all 36,000 nominal ticks, twenty survivors, no diagnostic counter increments,
clean invariants/storage and exact final save round trip. Ending heap growth
is 15,303,720 bytes, sampled peak 23,889,077. The unchanged conservative peak
proxy still fails, so the probe/audit remain Fail. Concurrent campaign processes
were suspended and resumed around measurement; the scheduling record is kept.
Full hashes and limits are in [STRESS_EVIDENCE.md](STRESS_EVIDENCE.md).
Remote 0.7.44 CI and all three published assets were verified; the
[checked APK](https://github.com/maccam912/brackenward/releases/tag/dev-cd5d75141fc6)
has SHA-256 `e920288dc542f89ff08b9383155dd0295479198f39fe73be91c9fe72a1bc1b84`.
Current physical Android behavior/PSS/battery/thermals remain unmeasured.

## 0.7.46 inspected generation expectations

The exact frozen 0.7.45 boundary export and independent audit pass all eighteen
maps with zero fallbacks. Nine rendered terrain, soil and shortest-access/flood
sheets were visually inspected before pinning eighteen revision-2 whole-world
canonical hashes. The new fixture records source/raw-map/audit/renderer/image
identities; old replay and geometry expectations remain untouched. See
[GENERATION_EVIDENCE.md](GENERATION_EVIDENCE.md) for hashes and observations.
The expanded generation suite passes 167 checks, bringing the maintained total
to 2,641 across 28 suites. Runtime generation is unchanged from 0.7.45. The full
30,000-map release sweep and fresh revision-2 first-Winter matrix remain running;
the older revision-1 post-Charter continuation also remains in progress.
Catalog/media validation and local Android export pass; aapt verifies
0.7.46-m7 / local code 85. No runtime gameplay rule changes in this checkpoint.

## 0.7.47 fewer repeated storage reads during assignment

A completed ordinary twenty-resident campaign exposed repeated full structure
scans for every tile of a painted stockpile during failed hauling probes.
The association lookup now runs once per eligible store, preserving the exact
candidate list, sort, ties, returned shape and all capacity/tag/fire rules.
Eight regressions compare the retained original query, 576 quotes, lookup count,
complete crowded ticks, save round-trip and continuation. Scheduler passes 403;
maintained total is 2,649. Persistence 345, colony 42, production 52, UI 663 and
the full frozen replay/acknowledgement audits pass without expected-hash changes.

Four alternating 720-tick pairs at the original twenty-colony endpoint reduce
median CPU 13.47%, with exact complete state and unchanged input bytes. The
crowded stress endpoint improves 1.60%; the longer fresh 7,200-tick comparison
changes by +0.034%, and a noisy shorter regression is retained. See
[RUNTIME_PERFORMANCE.md](RUNTIME_PERFORMANCE.md) for all hashes and limits.
This is a measured late-game source improvement; current Android remains
unmeasured. Content v6/schema 23/generator 2 are unchanged.
Catalog/media checks and local Android debug export pass; aapt verifies
0.7.47-m7 / local code 86. Remote CI/publication is checked separately.

## 0.7.48 generation expectations on every native CI host

The native Windows, Linux, Apple Silicon and Intel Mac matrix now checks the
167-case generation suite in addition to unchanged historical replay/save
continuation. Per-host artifacts include the generation log and JUnit results.
The runner directly launches the checksum-installed, version-verified native
editor and supports bounded longer native timeouts. Ten Python tests exercise
portable paths, invocation and missing/zero/duplicate/error/timeout rejection.
Actual local generation 167, UI 663 and Reed tutorial flow 22 pass through this
runner; media/content and Android export pass (local code 87 / 0.7.48-m7).
Maintained GDScript total stays 2,649. New native CI results remain pending;
configuration alone does not certify them. Runtime simulation and hashes are
unchanged. The full map, fresh Winter/Charter and old post-Charter runs continue.

Remote 0.7.46 completes all CI jobs and publishes its three checked assets.
[Its APK](https://github.com/maccam912/brackenward/releases/tag/dev-8c0e060bd8b2)
SHA-256 is `8d7ac800c3484a6317f44192234c3e049faa529fbb08d118609f6f62a512fc41`.
This older native matrix retains the historical-replay scope described above.


## 0.7.49 exported Android touch checks and fresh paused-save repair

Real Android 35 emulator touches now verify the one-cell door/wall brushes,
repeated paused field/build confirmation, immediate marks, preserved panned
camera, exact 4x restoration, wider whole-map zoom and reviewed named/campaign
save deletion. The 48→49 install preserves all 35 private files byte-for-byte
before first launch. Only task-created campaign 5/Touch49 were deleted; all 29
original campaign 1–4 files remain identical at that deletion boundary.
The ordinary first night visibly enters 12x sleep, shows the CPU fallback while
retaining 4x, and ends with all four healthy and awake; its exact saved endpoint
passes full codec/invariants. Minimum 2 dp/tile zoom persists on background.
Full evidence, limitations and retained hashes are in
[ANDROID_TOUCH_EVIDENCE.md](ANDROID_TOUCH_EVIDENCE.md).

The exported-app check found an additional real bug: freshly adopted campaigns
lost their acknowledged payload baseline, masking first same-tick commands from
periodic autosaving. Build 48 saved them only after a tick or explicit/background
save. Build 49 carries the verified independent staging baseline and complete
metadata through adoption, rebasing verified paths. Five persistence and four
native UI checks reproduce four failures in each suite before the repair; both
suites pass afterward (350/667).
The actual APK now periodically saves a confirmed door at tick 1800 without
running, manual Save or backgrounding. Full decoded state changes only its
pending commands/next ID. The read-only initial-save checker also proves that
new exported-app generator-2 maps match inspected expectations after normalizing
only the random session ID; three synthetic negative copies are rejected.

Historical replay, catalog/media validation and local Android export pass
(0.7.49-m7/local code 88). The maintained 28-suite total is 2,658. Schema 23,
envelope 5/settings 6/content v6/generator 2, historical fixtures, foreign saves
and expected hashes remain unchanged. Physical phone performance is unverified.

Build 47 remote CI and publication pass. Build 48's four native generation jobs
all pass 167 checks, including Windows and both Macs; its separate prototype
generation job timed out at 120 seconds, failing the overall workflow and
skipping publication. Build 49 raises that bounded allowance to 360 seconds and
the near-limit scheduler to 240 seconds, preserving the original failure log.
New remote CI/publication is separate. Full generator-2 maps/Winter/Charter and
old generator-1 post-Charter evidence continue in frozen checkouts. The stale
SIM06 acceptance-table arithmetic now agrees with the already implemented v6
rates and passing tests (rest 100 + four hours gives 400/340/280). Weekly
remaining last observed 58%; authorized work continues.


## 0.7.50 completed generation/post-Charter gates and merchant economy scenario

The frozen revision-2 release map sweep and explicit independent second audit
pass all 30,000/30,000 cases (10,000 unique seeds/site), zero retries/fallbacks,
minimum safe building area 11,002 and wild food 588. This closes the independent
map-geometry gate; [GENERATION_EVIDENCE.md](GENERATION_EVIDENCE.md) retains exact
source/completion/audit hashes and scopes. The completed frozen checkout now
runs the separate generator-2 twenty-resident seasonal campaign.

All four retained generator-1 Charters also pass ninety-six additional ordinary
days, 693,000→1,384,200, with original input bytes/command prefixes intact. Each
adds 2,304 invariants, keeps exactly eight residents, records zero starvation/
grace ticks and retains at least one food day. An explicit second audit passes.
[CAMPAIGN_EVIDENCE.md](CAMPAIGN_EVIDENCE.md) retains the actual endpoint hashes;
these are not fresh generator-2 claims. That separate Winter/Charter matrix
continues without editing its frozen source.

The new merchant_economy scenario observes/queues ordinary commands, buys eight
cloth on each of two scheduled Riverward visits, physically sews spare cloaks,
and completes the listed Road Fellowship three-cloak delivery. It keeps the
starting worn equipment, makes no local cloth, pays normal prices/reservations,
and retains all weather/incidents. The documented 24-day acceptance contract
requires exact imported-material provenance, physical receipts, eight living equipped
residents, a final food day and no starvation. The independent Python auditor checks actual
snapshots/commands/receipts/quantities; fifteen synthetic counterexample tests
pass and do not certify a real campaign. Fourteen GDScript policy/physical
transaction checks pass (trade 41); charter 106 also passes. A one-day bounded
run correctly returns incomplete with 24 invariant checks and no script errors.
The full four-case frozen matrix is not yet a completed gate.

Maintained local total is 2,672 across 28 suites, including the previously
verified UI 667 and persistence 350. Runtime rules, content v6/schema 23/envelope
5/settings 6/generator 2, inspected expectations and historical replay inputs
remain unchanged; this checkpoint extends the verification harness/design.
Catalog/media validation and local Android export pass (0.7.50-m7 / local code 89).
Weekly remaining last observed 57%; authorized work continues.


## 0.7.51 fresh Charters, save-screen localization and trade-policy repair

All four fresh generator-2/content-v6 Charters at frozen d870381 now complete
96 days with eight living residents, all five stages, ceremony and Continue,
zero zero-fullness/grace-exceeded ticks and 9,216 total invariant checks. A
second audit passes, and a separate audit preserves all twenty input files while
proving no barter/import/opportunity-reward dependency. Actual minimum health
is 90/92/92/100. See [CAMPAIGN_EVIDENCE.md](CAMPAIGN_EVIDENCE.md) for hashes.
Winter and the separate ordinary twenty-person seasonal run remain independent.

Twenty-one campaign/import/named-snapshot captions, form prompts and notices now
use named English catalog keys. Existing wording, callbacks, commands, saved
names and route IDs stay the same; substituted player braces remain literal.
Catalog/media/glyph validation passes 465 referenced keys; unit 20 and native
UI 667 pass. Trade/economy 41 also passes. Maintained total stays 2,672.
Local Android export passes at 0.7.51-m7 / code 90.

The first frozen 24-day merchant-policy attempt retains actual failures: the
all four cases keep eight residents with zero starvation and ample final food,
but spend their early wood on construction, miss the first Riverward purchase,
and therefore miss the earlier Road delivery. Their first completed purchase
occurs at the second scheduled visit. The original observer also rejected legal numeric merchant references against
string entity IDs; the corrected read-only audit retains every input byte and
confirms the actual policy failures. Sixteen synthetic audit checks now pass.
The revised policy assigns the first
newcomer to Gathering through normal preferences and keeps four tree tasks and
a 200-wood target, preserving the forty-wood purchase reserve and unchanged
24-day/receipts/material criteria. Its full frozen rerun is pending; a planning
failure is not presented as a game simulation defect or a passing gate.

The ordinary Charter runs contain no actual fires. Code/evidence review found
normal Working→batch-gap transitions can cancel the twelve-hour overheating
warning. Runtime fire rules remain unchanged while the requested cancellation
preference is pending. [OVERHEAT_DESIGN_GAP.md](OVERHEAT_DESIGN_GAP.md) records
the exact Pine warning and the distinction from clock-jumping unit fixtures.
Other authorized work continues independently.

Build 49 passes all CI jobs, including four native generation/replay targets and
publication. Its three assets were downloaded and checked: provenance names
564565c00e4b336ae86e5d7404aaad724f3ea1b7, run 38680622803; the actual APK is
0.7.49-m7+564565c / CI code 202, SHA-256
`d3acf9983f08b2020917b5cb5f26a12bf1c1030b9d29d5058986ffaf6d4eed3e`.
[Download](https://github.com/maccam912/brackenward/releases/tag/dev-564565c00e4b).
The separately tested local emulator build used code 88; its APK bytes differ from the CI asset. Build 50/current CI and physical-phone retesting remain separate.
Content v6/schema 23/envelope 5/settings 6/generator 2 and all immutable
expectations remain unchanged. Weekly remaining last observed 57%.


## 0.7.52 merchant construction budget checkpoint

The gatherer-only frozen retry also fails all four unchanged 24-day economy
cases: all eight residents survive without starvation/grace violations, but
construction still consumes the first visit's payment reserve. Its independent
audit now completes without observer errors. Both failed matrices and their
hashes remain in [MERCHANT_ECONOMY_EVIDENCE.md](MERCHANT_ECONOMY_EVIDENCE.md).
The planner now defers its optional second lodge until the first imported cloth
is physically paid, keeping normal original bedroll capacity and the first
lodge. No price, reserve, required receipts, survival metric or duration changes.
The next complete frozen matrix is pending. Trade 41 and sixteen Python observer
checks pass; maintained GDScript count stays 2,672. The report runner now ignores
its own generated directory immediately after checking that it was empty.

The allocation diagnosis uses the exact failed-soak endpoint without advancing
it. Two instrumented headless preparations reproduce identical payload bytes and
all validation, with unchanged inputs/source. The largest temporary growth is
about 39 MiB at full JSON parsing/decoding. A bounded private encoding/parsing
prototype is preserved separately; it is not in this checkpoint's runtime and
has not passed a native soak. The original 20 MiB peak proxy still fails.

Build 50 CI completes successfully and all three downloaded assets verify;
its APK SHA-256 is `deb19019be885b199f1355e47ba32e3fb1ad9ad63cc3530e6a04f12bebe46e22`.
Local Android 0.7.52/code 91, catalog/media validation and all targeted checks
pass. New remote CI/publication remains separate.
The overheating cancellation preference remains pending, and fire rules are
unchanged. Fresh Winter and twenty-resident seasonal runs continue. Weekly
remaining last observed 56%; authorized work continues.


## 0.7.53 bounded snapshot memory and completed balance cases

Full snapshot preparation now parses its exact private serialized buffer in
bounded native-JSON blocks, checking every boundary/byte and all original
integer/map/tile/depth rules. Full schema/reference/conservation validation and
exact capture equality remain. Releasing the complete private validation tree
before materializing full payload text cuts sampled temporary preparation heap
about 24.3% on the retained synthetic endpoint and 23.3% on the ordinary twenty-
resident endpoint; CPU rises about 1.6%/2.4% in four alternating pairs each.
All 32 immutable save fixtures match complete original bytes in each comparison.
[STRESS_EVIDENCE.md](STRESS_EVIDENCE.md) records exact inputs, sources, hashes,
remaining large-colony memory and limits. The native twenty-MiB peak proxy is
still unproven for this change until its new frozen thirty-minute run.

Persistence 377 (27 new checks), UI 667, historical replay/foreign continuation,
catalog/media and Android export pass; maintained total is 2699 in 28 suites.
Local Android is 0.7.53-m7 / code 92. Native CI now also runs full persistence on
all four editor targets and retains logs/JUnit; those new results are pending,
with bounded 35-minute jobs / 50-minute Intel jobs accommodating replay, maps,
persistence and smoke. Configuration is not observed platform certification.
No schema/content/catalog/generator/save-format or expectation change occurs.

Fresh generator-2 Winter passes all 30/30 independent cases and a second audit,
with eight survivors, zero grace violations and 23760 invariant checks. All four
24-day merchant-material cases now also pass independent audits: two real cloth
purchases, seven sewn cloaks, three-cloak delivery, eight healthy residents and
zero starvation. Both failed planner revisions remain intact. See the dedicated
Winter and merchant reports. All four fresh eight-day cases with exactly four
residents pass, with health 100, food/improvements and inspected initial goldens;
a separate read-only endpoint audit preserves every source byte. Fresh generator-
2 additional post-Charter continuation is now running from its audited origins.
The twenty-person seasonal campaign now also passes its independent second audit: all twenty home for both full 57600-tick windows, health 100 in each and no starvation/grace violations. Physical/human gates remain separate.

The overheating cancellation preference is still pending; fire rules remain
unchanged. Weekly remaining last observed 56%; authorized work continues.


Builds 51 and 52 separately pass all CI jobs and their three downloaded assets
verify against exact source provenance/checksums. Build 52's
[APK](https://github.com/maccam912/brackenward/releases/tag/dev-f0e36da64d60)
SHA-256 is `7bc2343bc883104c2529bb382e10484446132960810a9fa018e9702fd0f2ee25`
(CI code 205). Those older native matrices retain their replay/generation/startup
scope; the added native persistence matrix begins at 53 and is not certified by
an earlier green workflow.


Build 53 now passes all CI jobs, including actual native persistence on Linux,
Windows, Apple Silicon and Intel Mac. Downloaded replay/generation/JUnit/startup
artifacts independently verify in `native-ci-v53-evidence.json`: generation 167
each, persistence 377 on Unix and 376 on Windows (the Unix symlink case is
intentionally absent). All 27 bounded snapshot checks pass on every host;
historical 62-command replay and exact saves remain unchanged. The Intel Mac
startup uses Apple Software Renderer, which the original report mislabeled as
hardware; its raw result is retained and the derived evidence corrects that
attribution. This remains source launch, not exported interaction or GPU proof.
The three published assets verify exact source/run provenance. APK SHA-256:
`abad2a12723dab0e2297f428432d8d40a8e3d97bb04194bcfa1e209350140a2b`,
CI code 206 / `0.7.53-m7+fbd5638`. The native memory soak remains separate.


## 0.7.54 smaller journal verification and release checks

Every ordinary checkpoint and prepared catch-up previously deep-cloned the old
complete world to verify its reparsed delta. The writer now compares that exact
parsed patch against the immutable before/after captures with identical
reconstruction semantics. All unchanged fields, dictionary updates/erasures,
record identities/order, unused changes, depth and integer rules still count;
inputs remain unchanged. External recovery retains its original reconstruction
and full final schema/reference/conservation validation. Save formats and all
simulation/content/generator rules remain unchanged.

Four alternating component pairs after 360 real ticks reduce median verification
CPU 21.145→7.387 ms on the crowded endpoint and 297.857→115.507 ms on the
ordinary twenty-resident generator-2 endpoint. Sampled temporary engine heap
falls 17.936→0.304 MiB and 261.592→8.313 MiB. Full captures, sources and input
bytes match. These are contended local component measurements, separate from
snapshot-preparation costs or live/physical performance. Exact evidence and the
retained failing native run are in [STRESS_EVIDENCE.md](STRESS_EVIDENCE.md).

The completed frozen 0.7.53 native thirty-minute run passes duration/population/
logical-time/fps/storage/invariants/roundtrip/source checks, with twenty alive,
all counters zero and an exact complete endpoint matching 0.7.44. It still fails
the strict 20 MiB peak proxy: sampled growth 68.6 MiB, ending growth 14.6 MiB.
It remains Fail in both probe and independent audit; all task-owned campaign
workers were confirmed resumed. The new journal comparison does not relabel it.

The performance report now distinguishes 33.334/34/36/40/50 ms bounds so normal
30 FPS pacing jitter no longer jumps straight to a 50 ms percentile bound. The
strict slow-event threshold remains over 50 ms and reports stay within 64 KiB.
The native-startup classifier now correctly labels the observed Intel Mac
Apple Software Renderer, retaining the earlier original report unchanged.

Persistence passes 392 (eleven reconstruction-equivalence and four timing
additions), native UI 667; maintained count is 2714 in 28 suites. The new verifier
agrees with the unchanged oracle on malformed operations, 80 frozen generated
cases and all 32 immutable saves. Nineteen Python audit counterexamples support
the paired raid harness; the exploratory Meadow/104729 pair and independent
raw-save audit pass. That mutable-source pilot is not the required thirty-map
release result. CI now runs/audits one real pair and retains its complete saves;
[PREPARED_DEFENSE_EVIDENCE.md](PREPARED_DEFENSE_EVIDENCE.md) defines the separate
frozen release sweep. Merchant audit contracts now also run explicitly in CI.

Native memory, Android physical/PSS/battery/thermals, exported interaction and
human comprehension remain distinct open gates. The overheating preference is
still pending and no fire rule changed. Weekly remaining last observed 54%;
authorized work continues.


Local Android 0.7.54-m7 / code 93 exports successfully with all four Kotlin
tests. Historical replay preserves all 62 commands, both reviewed endpoints,
foreign-save continuation and schema-22/content-3/4/5 acknowledgements; no
expected bytes change. Catalog/media, string/audit contracts and workflow shell/
Python parsing pass. `release-polish-v54-evidence.json` retains exact local
logs/artifact hashes and confirms that both component measurements still match
every executed runtime/catalog source. New remote CI and frozen matrices are
checked after this source is published.


## 0.7.55 bounded journal retention and interception fixtures

Prepared rotation now validates every old journal frame before retaining only
commands strictly newer than the preparation tick. It checks all checksums,
sequences, JSON values and schemas, counts even unselected frames, rejects torn
or malformed evidence, and preserves command order. Only fresh private parser
data is consumed in place; unselected trees die before the next frame. The
complete external reader and on-disk history retain their existing behavior.

Twelve new persistence checks compare against the complete a230331 reference,
including original result shape, nonmutation, strict cutoff, every torn boundary,
malformed unselected frames/depth and all four historical journals. Persistence
404 and native UI 667 pass; maintained total is 2726 in 28 suites. Historical
62-command replay, foreign continuation and schema-22/content-3/4/5 preservation
also pass. No schema/content/catalog/generator/gameplay rules or reviewed bytes
change. [STRESS_EVIDENCE.md](STRESS_EVIDENCE.md) records the three actual native-
53 journals: sampled retention falls from 42–65 MiB to 11–12 MiB; CPU is slightly
higher on the contended host. Exact final runtime/input/report fingerprints are
in `journal-selection-v55-evidence.json`; intermediate attempts stay preserved.
A complete new native soak and physical/PSS/battery/thermal gates remain separate.

The first frozen thirty-map prepared matrix at a230331 completes and retains its
independent Fail audit: cart defense 21/30; real ransom delivery 30/30. All sixty
branches keep four residents at health 100, without zero-fullness or theft, and
all actual save hashes/roundtrips verify. Every failed defense first retreats at
the six-hour timer with no downed enemy then; one Reed case downs an attacker
later during retreat. That later action cannot satisfy the pre-timer criterion.
The revised plan issues ordinary draft orders at the midpoint of a real announced
approach. An independent BFS/terrain/solid/bridge check validates the contiguous
shortest route and midpoint. The formerly failing Pine/0 pilot now repels at 9958,
with all four at health 100; its ransom commits at 10317. Twenty-five Python
contracts pass. This is a mutable-source pilot, not the full revised frozen
matrix. See [PREPARED_DEFENSE_EVIDENCE.md](PREPARED_DEFENSE_EVIDENCE.md).

All build-54 remote CI jobs now pass, including the real paired raid CI case,
four native persistence/replay/generation/launch jobs and publication. Downloaded
assets and native evidence are checked separately from that workflow status.

The weekly meter changed from 54% remaining to 99% remaining with a new reset
window while this checkpoint was being finished. No reset was requested/redeemed
by the agent. A budget question was raised after applying an older quota-stop
note too broadly: that note governed resuming an already stopped run. This goal
remains active under the current user's standing instruction to continue until
live weekly remaining is below 50%, so that cutoff continues through this reset.
The question is optional steering; an explicit Stop answer supersedes continued
work. No answer or preselected option is inferred as a new authorization. Fire
behavior remains unchanged while its separate design preference is pending.


Build 54's downloaded native artifacts independently verify all four source
replay/generation/persistence/startup targets: 167 generation each and 392
persistence on Unix / 391 on Windows (Unix-only symlink case). All eleven
read-only delta checks pass on every host. The Intel software renderer is now
correctly attributed. `native-ci-v54-evidence.json` retains exact hashes and the
observed paired-CI-step result. All three published assets verify provenance;
APK SHA-256 `85ba5180ac37835fbdef3ba76c65cbaf4fc69353dc5ea238918c0c0f0fc488f9`,
CI code 207 / `0.7.54-m7+a230331`. Local build 55 exports as code 94 with
four passing Kotlin tests. `release-polish-v55-evidence.json` records exact
local validation/APK hashes and confirms every final comparison source remains
unchanged. New remote CI and full revised matrix/soak are observed separately.


The frozen revised interception matrix at `6685958` now passes all thirty
defense and thirty physical ransom cases, with a separate second audit. Every
branch keeps the original four residents at health 100, without zero-fullness
or theft. Thirty distinct maps/entries, all independent geometry, eighteen
inspected initial goldens, real shortest-route midpoint rallies, exact orders/
receipts, active-incident reloads and all saved bytes verify. Defense retreats
9366–10176; ransom commits 10297–10442, both before the 10800 timer. The earlier
21/30 cart-plan failure stays intact. `prepared-defense-v55-evidence.json` and
the dedicated report retain all sources and hashes. The final frozen native
soak has completed with a separate second Fail audit: 30.25 MiB peak exceeds
the strict 20 MiB proxy; all other duration/population/invariant/storage/fps/
roundtrip/source checks pass. Its original failed result is retained.


Build 55's downloaded native artifacts independently verify all four targets:
167 generation checks each, 404 persistence on Unix / 403 on Windows, all twelve
new journal-selection checks, the unchanged 62-command replay/checkpoints,
foreign-save continuation, schema-22/content-3/4/5 preservation and native startup.
Intel correctly reports Apple Software Renderer. All three uploaded release
assets match exact provenance/digests; APK
`f2ad5838ace1b09a5d3d286fc348c7da10675e46a18ea8be3c35fd02dd31c63a`
is CI code 208 / `0.7.55-m7+6685958`. Exact evidence is
`native-ci-v55-evidence.json`.

All four fresh generator-2 post-Charter continuations now pass their separate
second audit: another 96 days each, eight survivors, exact original initial saves
and command prefixes, no zero-fullness/grace violations, and a final food day.
Each reaches 1384200 with 4608 total invariant checks. Exact endpoints, retained
inputs and file hashes are in `post-charter-gen2-v52-evidence.json` and
[CAMPAIGN_EVIDENCE.md](CAMPAIGN_EVIDENCE.md). This completes that simulation gate;
physical performance and human playtesting remain separate.


## 0.7.56 bounded snapshot verification and envelope escaping

Full immutable-capture schema/reference/conservation validation now runs before
serialization and must restore an identical payload without migration/mutation.
Actual serialized nested fields and at-most-256-record blocks are then parsed
with the native JSON parser and matched completely against that validated capture,
retaining all original state/depth/integer/map/tile and byte-coverage rules.
Private blocks are released rather than retaining a second complete decoded world.

A diagnostic phase probe isolated the remaining full escaped UTF-32 envelope
copy. Preparation and prepared publication now escape at most 4096 Unicode code
points per native string block and assemble the same normal UTF-8 envelope.
Fixed-time reference comparisons cover exact metadata/payload/digests/escaping,
Unicode/control/chunk boundaries and the unchanged 64 MiB bound. External loading
and direct saves keep their original codec; publication still reads back exact
bytes. Twenty-seven added persistence checks pass, including all 32 historical
saves, full validation rejections and external decoding; persistence is 431,
native UI 667, maintained total 2753 across 28 suites.

Four alternating final-source pairs reduce sampled temporary preparation heap
from 29.490 to 11.381 MiB on the retained synthetic endpoint, and from 448.025 to
172.492 MiB on the fresh-generator-2 ordinary twenty endpoint (about 61% each).
CPU is about 1.9% higher / 1.8% lower. Complete payload text/digest/ownership and
all 32 historical fixtures agree with the independently retained 6685958 factory
and decoder. Final source/input/report fingerprints and caveats are retained in
`snapshot-capture-v56-evidence.json` and [STRESS_EVIDENCE.md](STRESS_EVIDENCE.md).
The returned large ordinary payload text itself remains substantial. These are
component comparisons; a fresh frozen native soak and physical Android tests are
separate gates. All earlier failed memory evidence remains unchanged.


Local 0.7.56 Android export passes as code 95; all four Kotlin storage checks
pass. Historical replay retains all 62 commands, both reviewed checkpoints,
foreign-host save continuation and content-3/4/5/schema-22 preservation.
Content validation and native import pass without script errors. Exact local
APK/log/replay/source-comparison fingerprints are in
`release-polish-v56-evidence.json`. Publication and the fresh frozen native soak
are observed separately. Standing work continues against the live weekly
remaining threshold; the meter most recently showed 97% remaining after reset.


## 0.7.57 Windows Unicode log output

Build 56's Windows native job completed 430 persistence checks with zero JUnit
failures, then its Python launcher failed while printing U+FFFD through CP1252.
The redirected log is empty, so the original workflow remains Fail and Windows
startup/publication cannot be inferred from JUnit alone. Raw job/artifact hashes
are retained in `native-ci-v56-windows-failure-evidence.json`; Linux and Apple
Silicon replay/generation/persistence/startup jobs passed at last observation.

The suite, checked-command, replay and native-smoke entry points now explicitly
configure UTF-8 output, preserving Unicode logs under redirected Windows consoles.
Engine error detection and positive/complete-summary requirements are unchanged.
Two new regressions use actual CP1252 text wrappers, preserve U+FFFD/Unicode, and
prove script errors still fail; one also exercises a real subprocess. Eleven
suite-launcher, nine checked-command and six renderer checks pass locally.
Runtime/schema/content/generator/gameplay are unchanged from 56. Its frozen native
soak continues separately; new CI must verify the complete fixed Windows path.


Local 0.7.57 persistence passes 431 with zero script errors. Android debug
exports as code 96; the storage plugin's unchanged four checks pass. All runtime
and data files are byte-identical to e4003fb, verified independently of package
metadata. `utf8-v57-evidence.json` retains exact output-helper/test/log/APK hashes.
No GUI suite was repeated during the separately frozen native soak; prior UI
coverage keeps its recorded source scope. Combat correction work is preserved
separately and has not entered this logging repair.


## 0.7.58 in-range hostile self-defense and preserved v6 progress

A v6 goods-distance filter prevented an adjacent intercepted raider from
counterattacking a guard far from its chosen supplies. Controlled actual-combat
twins reproduce the bug with clear sight and valid invariants. Content v7 now
allows its normal in-range defense anywhere on the approach, keeping movement
toward goods and every original weapon/range/sight/cooldown/ceasefire/retreat
rule. Definitions are identical to v6 except the declared version; schema23,
envelope5, generator revisions and settings remain unchanged.

Six frozen e4003fb acknowledgements and a real 600-tick old journal preserve all
saved gameplay and untouched originals/backups. Header migration never reruns
old combat or retroactively applies damage; corrected retaliation starts only
on a later tick. Thirteen persistence and twenty combat regressions pass.
New v7 replay files are separate and use the unchanged 62-command input; both
actual checkpoints retain every v6 gameplay field after only content headers
normalize. A normal rerun passes, including all older acknowledgement audits;
record mode refuses to replace reviewed files. Old inspected initial-map goldens
also remain unchanged: exact catalog-definition/header checks precede full-state
normalization, with negative tests against wrong headers and altered gameplay.

All 28 local suites pass 2788 checks: persistence444, defense81, generation169,
native UI667 and 1427 checks in the other24. A mutable Meadow104729 pair passes
normal interception and physical ransom, with an independent full Python audit.
The complete frozen v7 campaign/raid/platform/physical gates remain separate.
[RAIDER_SELF_DEFENSE_EVIDENCE.md](RAIDER_SELF_DEFENSE_EVIDENCE.md) describes exact
scopes and preserved inputs.

Build57 Windows stopped in the new log regression because its legacy text
wrapper emitted CRLF while the assertion expected LF. The original failed job
is retained in `utf8-v57-windows-failure-evidence.json`. The shared output helper
now explicitly emits UTF-8/LF, and both tests explicitly start with CP1252/CRLF
streams on every OS. All local launcher/error checks pass; fixed-source Windows
CI still must verify the full path.

The separately frozen v6 0.7.56 native soak and its second audit now pass the
unchanged strict memory/FPS proxies: 1800.003209 seconds, 36000 logical ticks,
twenty residents, 14.597 MiB sampled peak/ending growth, minimum one-second
FPS27.316, all five diagnostic counters zero. Full final codec roundtrip and
source/invariants/storage pass. A separate private extra tick aligns its endpoint
with native55 and matches every saved field exactly. Original measured endpoints
and earlier failures are untouched. `native-soak-v56-evidence.json` retains all
fingerprints and concurrency limits. This is a native synthetic proxy; current v7
and physical Android/PSS/battery/thermal testing remain separate.


Local Android0.7.58 exports successfully as code97; four Kotlin storage checks
pass. Eighteen merchant and twenty-five prepared-defense Python checks pass,
including exact header/catalog normalization without ignoring any gameplay.
The separate mutable paired pilot keeps health100 and passes its independent
BFS/full-initial/command/save audit. `self-defense-v58-evidence.json` records
all28 suite counts/logs, original67 fixture/catalog byte comparisons, source
fingerprints, replay/golden/foreign-save checks and local APK provenance.
Weekly remaining last observed96%; authorized work continues against the live
below50% cutoff. New source publication and frozen v7 reruns are separate.


## 0.7.59 keep prepared saves as validated UTF-8 bytes

The prepared payload now retains its checked UTF-8 buffer and computes/rechecks
the actual byte digest before publication. Production wraps those bytes directly;
tools/tests can still request the same legacy text view. Fragment boundaries keep
complete code points, native UTF-8 roundtrip and JSON escaping, and the unchanged
64-MiB limits. Full capture/schema/reference/conservation validation, exact byte
coverage/readback, save format/schema/content/generator and immutable ownership
remain unchanged. Explicit scalar record aliases preserve the original String
storage in all retained reference factories instead of silently changing their
benchmark behavior.

Six added persistence assertions pass, including all 39 recursive immutable v1–v7
fixtures, Unicode cuts/escaping, byte/text tampering and actual caps. Persistence
records 450 assertions, but its runner correctly rejects two empty-hash engine
errors; the original pass claim was incorrect and is corrected below. Native
UI 667 passes; maintained assertion total 2794 in 28 recorded suites.
The fixed62-command v7 replay and all older acknowledgement audits pass. Four
alternating component pairs reduce ending heap growth8.155→2.931 MiB on the
synthetic endpoint and125.220→33.016 MiB on the ordinary twenty-person endpoint;
peak11.384→10.061 and172.492→80.303 MiB. CPU differs less than1% on a contended
host. `snapshot-bytes-v59-evidence.json` retains exact source/input/report
fingerprints, original-reference checks and measurement limits.

The frozen current-v7 0.7.58 native run now independently passes:1800.011566
seconds,36000 ticks, twenty residents,15.763 MiB strict sampled peak and lowest
one-second FPS27.765, zero diagnostic/storage/invariant errors and full roundtrip.
Complete gameplay equals native56 after only content headers normalize.
`native-soak-v58-evidence.json` records concurrency and physical limits. The v7
raid matrix and second audit also pass all30 defense and30 physical ransom
cases with unchanged outcome/input/geometry/receipt/reload gates; see
`prepared-defense-v58-evidence.json`. V7 Winter/Charter and the new byte-backed
runtime remain separate ongoing checks.

All four build 58 native jobs now pass, including Windows full engine checks;
`native-ci-v58-evidence.json` verifies their actual artifacts, replay hashes,
169 generation checks each and 444 persistence checks (443 on Windows).
the overall workflow remains Fail because its separate map-batch tool still
loaded v6 definitions while correctly exported v7 maps declared the new hash.
The original identity failure/audit remains in `map-catalog-v58-failure-evidence.json`.
The tool now derives and checks its catalog from the source's declared content
version and fingerprints that actual catalog plus declaration/loader. Sixteen
Python checks and six actual hashed-map exporter/independent geometry/identity
smoke cases pass. No map/seed/definition/golden or validation gate is rewritten;
full fixed-source CI/publication remains required.

Local Android 0.7.59 exports as code 98; four Kotlin checks, catalog/media
validation and the unchanged independent reference-source proof pass.
`release-polish-v59-evidence.json` retains these local check/log/APK hashes.
No physical Android retest is inferred.


## 0.7.60 loader ownership and corrected empty-hash gate

The original 0.7.59 persistence pass claim was incorrect: all 450 assertions
passed, but two empty-buffer HashingContext.update calls logged engine errors.
The fail-closed runner rejected both the local run and the remote prototype job;
publication is blocked. Raw logs and the original commit are retained, and
release-polish-v59-evidence.json now explicitly corrects the mistaken claim.
The independently measured nonempty preparation pairs, UI/replay and local export
retain their stated scopes. empty-hash-v59-failure-evidence.json records the
failure. The helper now finishes its initialized SHA-256 context without updating
an empty buffer, preserving the exact native empty digest and all error gates.

External decode releases its already verified payload text before unpacking and
uses the existing checked owned-JSON converter only on fresh parser containers.
It releases parser/envelope references before full restoration. Public restore,
all migrations/schema/invariant/identity validation and external encoding remain
byte-identical to 487bb1d; ordinary shared/read-only restore inputs are not consumed.
The complete earlier decode body and independent nonmutating ColonyState.unpack
are retained as the comparison path. Five new checks cover all 39 recursive
immutable saves, full Unicode/metadata state, 29 envelope failures with identical
messages, 12 payload encoding/schema/reference failures, and read-only restore.
Current persistence passes 455 with zero assertions or engine errors; v7 replay
passes all 62 commands plus every older acknowledgement audit. The maintained
assertion total is 2799; the other suite scopes remain recorded separately,
including UI667 at 0.7.59. A fresh UI run waits for the isolated native measurement.

Four alternating full-decode background pairs retain exact complete worlds and
all 39 fixtures. Synthetic sampled peak falls 81.507 to 52.827 MiB; ordinary
20-resident peak falls 1243.165 to 805.392 MiB. Ending worlds are unchanged at
26.138 and 393.496 MiB; CPU differs by about -0.1/0.9 percent on this contended host.
This is allocation reduction, not a phone speed or PSS claim. The ordinary
endpoint has 49,894 retained job records and 41,618 stack records in a 39,339,607
byte envelope; retained history and large-colony memory remain open performance
work. snapshot-load-v60-evidence.json records sources, inputs, raw logs and medians.

The frozen current-v7 Charter matrix now passes all four 96-day cases with eight
residents, zero zero-fullness/grace ticks, 2304 invariant checks per case, all
stages/ceremony and Continue. The separate second audit and no-barter/import
read-only audit pass; charter-v58-evidence.json records all endpoints and source
hashes. Its separate 96-day post-Charter continuations now run from those exact
preserved origins. V7 Winter and the byte-backed native soak remain in progress.

Local Android 0.7.60 exports successfully as code 99; four Kotlin checks pass.
release-polish-v60-evidence.json records fresh fail-closed validation and exact
local APK/log hashes; full current CI/publication and physical QA remain separate.


## 0.7.61 avoid the private header-migration copy

After checking the exact released v2–v6 catalog, external decode can normalize
only its two content headers in the fresh parser-owned root. Public/shared
restore still takes the original deep copy, and an older-content read-only
capture remains unchanged even after stepping its independently restored world.
The shared restoration body is proved byte-identical to fd29cfe after replacing
only that conditional copy with its original unconditional line. External encode,
all schema/reference/invariant checks, migrations, state conversion, quantities,
history, canonical state and wire format remain unchanged. The complete prior
decode body with the original-copy public restore is retained independently.

Three new checks compare all 39 immutable fixtures, shared-capture independence
and invalid catalog/schema/reference/newer-version rejection. Fresh fail-closed
persistence passes 458; exact v7 replay passes 62 commands plus all older
acknowledgement audits. Maintained assertion total is 2802; fresh local UI remains
deferred while the prior frozen native soak is running, with UI667 last recorded
at 0.7.59. Full current CI/publication and physical Android are separate.

Four alternating full-decode background pairs reduce sampled peak52.826 to
47.846 MiB on the synthetic input and805.392 to730.419 MiB on the ordinary
20-person input. CPU212.178 to199.911 ms and3519.236 to3310.099 ms is about6%
lower on this contended host. Ending growth increases slightly:26.138 to26.168
and393.496 to393.791 MiB; complete restored payloads remain identical. This
changes private allocation only, with no history loss or raised save/count caps.
snapshot-migration-v61-evidence.json retains exact sources, inputs, logs and pairs.
The large ordinary save's retained history/memory remains open performance work.

The actual 0.7.59 independent map artifact is now audited:768/768 hashed v7 maps,
256 per site, zero retries/fallbacks and unchanged source. Its exact raw geometry,
quantities and current catalog identity pass; map-catalog-v59-ci-evidence.json
retains all shard/manifest hashes. This subset does not replace the full30,000
pinned generator-2 release sweep. Overall0.7.59 CI still fails its empty-hash
persistence gate and publishes nothing. The corrected0.7.60 workflow is pending.

Local Android 0.7.61 export/code 100 and four Kotlin checks pass;
release-polish-v61-evidence.json retains exact validation/log/APK hashes.


## 0.7.62 settings and work-panel text audit

Sixty-one additional named messages bring the English UI catalog from 465 to 526 keys.
Settings, audio percentages, graphics choices, handedness and automatic-pause
labels now use it. Work/resource/field/storage details, priority/preference values,
order paging/counts and pending-order notices use named parameters. Early harvest
uses1 unit instead of1 units; other English wording and numeric truncation remain
unchanged. Names, canonical saved activity/reason text, command/route/setting IDs,
callbacks and all simulation/persistence/generation/catalog definitions remain
unchanged. Every one of the465 earlier messages is byte-equivalent as a value.
No language selector or translated content is added; other dynamic panels and
canonical activity/fact presentation remain part of the M7 text audit.

Content/font validation passes all 526 keys, named parameters and plural forms;
the shipped99-character set stays unchanged. Five Python message-validator checks
pass. Fresh fail-closed persistence 458 and the original graphical UI 667 pass; the expanded corrected run passes 669. Large-text
Settings portrait360x640 and Auto pauses landscape640x360 screenshots were
inspected: full headings, scrollable body, persistent notice and48-dp controls.
The native screenshot generator and original control/layout/placement/speed
regressions remain unchanged. Current Android export succeeds as localcode101;
emulator update/interaction checks now pass in the scope recorded below, separate from physical QA.

The frozen487bb1d/0.7.59 native source case and separate second audit pass:
1800.020424 measured seconds at2x after60s warmup,36001 ticks3002→39003 against
36000 floor nominal, twenty residents. Strict sampled peak/ending growth is
14.635 MiB and lowest one-second FPS28.605; no below-24 streak and all five
counters zero. Full roundtrip, source, storage/invariants and audio drain pass.
Complete gameplay at tick39003 matches the earlier native55 endpoint after only
the two content headers normalize; native55's heap failure stays Fail.
native-soak-v59-evidence.json records exact inputs/source/report/comparison hashes
and concurrent headless campaign/profile/suite/export work. No second graphical
Godot ran during measurement. This is a native subset, not a pristine/causal
comparison or Android PSS/thermal/battery certification. Its overall0.7.59 CI
still fails the separately recorded empty-hash probes; all four actual native
failure artifacts are audited in native-ci-v59-failure-evidence.json.

The corrected0.7.60 prototype artifact freshly verifies all28 suites/2799
assertions and Kotlin4, plus exact APK/code213/provenance/checksum agreement
across both uploaded artifacts. prototype-v60-evidence.json retains those facts.
Map and Windows/Linux/Apple Silicon native jobs pass; Intel macOS and publication
are still pending at this checkpoint. Current0.7.61 CI is separately running.


The Android test exposed a preexisting CycleChoiceButton defect: assigning its
selected index did not refresh the caption. Reopening graphics displayed Battery
while the retained setting was Smooth (initial Balanced likewise displayed
Battery). Both native regressions reproduce it before repair:669 checks/two
failures. The selected property now refreshes text without emitting item_selected;
user selection still emits exactly once. The expanded669-check runner passes.
The fixed APK shows Smooth on reopening with every device-preference value
identical to its before-fix record. Tap-to-change help now uses the message catalog.

Android0.7.62/code101 update preserves all45 existing files before first launch.
The originals are then isolated, with a fresh task sandbox for all interactions.
Actual taps exercise settings/text scales100/125/150 and portrait/landscape. An
unchanged private clone of old v6 campaign5 is loaded and explicitly saved while
paused at tick10734: every gameplay field matches after only the two content
headers normalize, and the original migration-backup bytes match exactly. All45
original files are restored byte-for-byte, task data removed, rotation preferences
restored and the emulator stopped. android-touch-v62-evidence.json retains exact
APK/before-after/frame/archive/manifest hashes. This is Android35 arm64,
1080x2340/density440, SwiftShader/ANGLE, not a physical CPH2655/PSS/thermal test.

The frozen v7 Winter matrix completes30/30, minimum health87, with23760 invariant
checks and every original scenario/save/source/grace gate retained. Its separate
second audit passes; winter-v58-evidence.json records the source and endpoints.
Four v7 post-Charter continuations remain in progress. Both0.7.60 and0.7.61 now
pass every remote job and publication. Actual native artifacts/prototype suites
and published APKs are audited in native-ci-v60-evidence.json and
native-ci-v61-evidence.json; code213/214 and exact source/checksum/asset agreement
are verified. Neither those runs nor current emulator checks certify physical or
human release gates.


## 0.7.63 individual tick and explicit Android memory diagnostics

The report now records each completed `world.step` separately from its containing
simulation batch/session, at the actual playback speed. Tick timing excludes
runner alert/pause work. Headless runners without a presentation clock/observer
perform no added clock reads. State, selected speed, backlog and every immutable
replay expectation stay unchanged. The bounded collector grows from50 to55
histograms, retaining32 slow events, fixed bins and the64KiB export cap.

An explicit Android report queries `Debug.MemoryInfo.totalPss` once, converts
KiB to bytes, and retains the source and query duration. Missing samples remain
null. Preview/copy/export reuse the same frozen report; playing never polls
process memory. One sample does not establish longevity, battery or thermals.
Three new regressions verify exact tick counts/times and complete-world equality
at1x/2x/4x, the missing-clock boundary, exact memory units and unavailable samples.
Fresh persistence461 and UI669 pass; unit20/integration6/scheduler403, exact
replay62/all old acknowledgements,528-key content validation and local APK102
with Kotlin4 pass.

The first actual APK exposed an unsupported JNI `has_method` guard that skipped
the memory query despite the packaged method being callable. That failed report
and APK are retained; the guard was removed before publication. Actual Android
bridge/export and final preservation results are recorded in the compact report.

The frozen0.7.62 desktop soak independently passes its30-minute2x case with
36001ticks,20residents, peak sampled engine-heap growth20271140bytes and lowest
one-second FPS28.429, zero diagnostic counters, full source/input/storage/codec
checks and second audit. Every gameplay field matches the earlier v7 same-tick
endpoint. Concurrent headless work makes this a development proxy, with no
physical performance claim. `native-soak-v62-evidence.json` retains the details.
All four current-v7 Charter origins also pass96additional days (192total),
no zero fullness/grace violations, exact command prefix and final food reserves;
`post-charter-v58-evidence.json` includes their independent second audit. The
current-v7 ordinary20 seasonal campaign and full30000-map sweep continue.


The fixed actual APK exports a10410-byte valid report through Android's document
provider. PSS is247602176bytes, within0.12% of the separate near-time system
reading247307264bytes; explicit query96312us, and472 timed4x ticks have exact
histogram sums. This is emulator binding/export evidence only. Original45 files
are preserved before first launch, isolated for testing and restored exactly;
rotation preferences are restored, task files removed and emulator stopped.
`android-diagnostics-v63-evidence.json` records the failure and fixed artifacts.
The graphical suite separately verifies frozen preview/export reuse. All actual
0.7.62 CI artifacts and code215 published assets now audit successfully in
`native-ci-v62-evidence.json`. Current0.7.63 CI/publication is still pending.


## 0.7.64 retain fewer duplicate String keys after external load

The isolated key-sharing attribution probe preserves complete unsorted serialized
state, canonical hash and invariants while releasing7810632bytes on the synthetic
endpoint and124856776bytes on the ordinary20 endpoint. Its input bytes and
sources are unchanged. This motivates a per-load pool in fresh private JSON
conversion, capped at2048 distinct keys and128-key record dictionaries.
Only equal String key buffers are shared; every value, key type, key insertion
order and private dictionary/array identity remain. Integer-keyed map semantics,
coordinate/depth/null rejection, public restore, complete validation, all history,
content/schema/envelope and external save bytes remain unchanged.

The complete357fa04 decoder and its prior converter remain independent. Source
proof verifies the exact reference body, an unchanged prior converter file and
only one production decoder call replacement. Four regressions compare all39
immutable saves,20 boundary shapes, a5000-record pool-cap/identity/order case,
and complete720-tick future state plus roundtrip. Persistence465 passes with no
engine errors. The exact v7 replay still verifies62commands, both fixed goldens,
foreign continuation and every older acknowledgement. Unit20/integration6 and
528-key content checks pass. UI669 remains the fresh0.7.63 local result while
its frozen graphical soak runs; current remote UI and actual Android remain
separate.

Four alternating full-load pairs retain26.168 to18.719MiB on the synthetic input
and393.791 to274.718MiB on the ordinary20 input. CPU214.170 to239.350ms and
3285.532 to3565.311ms is about9–12% higher. Sampled peak remains essentially the
same at47.8/730.4MiB. This trades a modest measured load cost for lower retained
memory; it is not a load-speed or peak-memory improvement. Frozen native63,
generation and ordinary20 workers share the host. `snapshot-keys-v64-evidence.json`
retains raw/reference/input/source identities; physical Android remains open.


Local0.7.64 Android export succeeds as code103 with all four Kotlin checks.
The exact APK/log hashes are included in snapshot-keys-v64-evidence.json.
Current CI/publication and graphical/emulator reruns remain separate; the
unchanged UI last passes669 locally at0.7.63. The native63 soak stays frozen.


## 0.7.65 avoid repeated empty resource-regrowth scans

A derived view includes every resource row with a positive timer,
in original order and as live references. The agriculture loop retains all old
predicates and each tick of winter delay. Commands,gather depletion,legacy
replant completion,regrowth completion,generation and array changes invalidate
it; direct calls outside trusted ticks use the original full scan and reset it.
No resource/history record, timer, save field, schema/content, generator rule or
canonical expectation changes. The complete original702b20b agriculture loop
and a full-scan reference world remain independent, with explicit source proof.

Five new tests cover resource kinds and season boundaries, real gather and legacy
replant, replacement/direct-call boundaries, complete future state/reload and a
dormant legacy timer on an available tree. The last test reproduced a bug in the
initial zero-remaining-only filter; the corrected view tracks timer membership
and checks changing quantity live. The failing regression remains retained.
Nature23,persistence465,generation169,survival83,seasons26,UI669 and replay62/all
older acknowledgements pass. The first copied-oracle runs failed compilation
because season() needed class qualification; fail-closed runners rejected those
runs despite their other assertion summaries. Their logs remain retained.

Four alternating complete-tick pairs preserve every unsorted state value and
invariant with unchanged inputs/sources. Fresh generated Meadow7200ticks falls
2172799.5 to1229035us (43.44%); ordinary20/720ticks3523698.5 to3370859us
(4.34%); retained stress/rations input is essentially unchanged,3772261 to
3766852us (0.14%). These are contended desktop simulation CPU measurements,not Android
frame or thermal claims. `regrowth-v65-evidence.json` retains the comparisons.

Current-v7 full generation now passes all30000maps and separate audit, recorded
in `generation-v7-v62-evidence.json`. Four current-v7 imported-cloth campaigns
pass24days and a separate audit: two actual8cloth imports for40wood each, seven
sewing jobs and a real3cloak delivery, exact material ledger, eight residents at
health100 and food reserves. `merchant-v64-evidence.json` retains those records.
Both0.7.63 and0.7.64 remote jobs/publication pass; actual full native/28-suite/
Kotlin/published-asset audits are `native-ci-v63-evidence.json` and
`native-ci-v64-evidence.json`, code216/217 respectively.

The frozen native63 requested30-minute run stops at1576.563294seconds after one
protective slow-save pause. It fails completion and its separate second audit.
Twenty residents, full roundtrip, memory/FPS/input/source subsets still pass,
which does not turn the whole run into a pass. Actual save-worker wall latency
is not recorded by foreground capture/finish callbacks, so the cause remains
unresolved; the1.75-second protection remains. `native-soak-v63-failure-evidence.json`
retains the failure and host-concurrency scope. A later retry remains separate.


The current-v7 ordinary20 campaign also finishes96days and passes its independent
second audit. Sixteen public newcomer admissions yield20living residents; each
year-three Summer/Winter window includes all57600home ticks at20 residents,
minimum health100 and zero empty-fullness ticks. Whole-run minimum health72,
no starvation-grace overrun, full snapshots/source/checksums/invariants and final
food reserve gates pass. `large-colony-v62-evidence.json` preserves that scope.


Local0.7.65 exports as Android code104 with four Kotlin checks; the version name
is verified as0.7.65-m7. The focused Android test uses a fresh isolated sandbox,
with45 original private files quarantined and later restored byte for byte. Real taps already show a one-cell door and a one-cell wall, both
confirmed/marked at the initial paused time, with another Confirm enabled before
any simulation tick. Real4x entry/confirmation restores4x; the whole map fits at2dp zoom. The final
corrected APK preserves all11 sandbox files before first launch, recovers the
same paused tick10052, deletes the reviewed test campaign and reopens New Colony
after restart with no ghost save. All45 originals are restored exactly, task
files are removed, and the emulator is stopped. android-touch-v65-evidence.json
retains separate initial/final APK scopes, archives, settings, screenshots and logs.


Four current-v7 first-week cases also pass8days and the separate audit: three
Standard sites plus Pine Hearthside, four living residents at health100,
no starvation-grace overrun, at least three real improvements and a final food
day. Every complete initial payload matches the unchanged inspected boundary
after only verified content headers/Hearthside preset normalization. All eight-day
source/report/snapshot hashes are retained in first-week-v64-evidence.json.


Focused Android65 testing also observes the quiet-sleep CPU fallback notice at
night, retaining4x. This is fallback evidence, not a sustained12x pass on this
emulator; older native49/automated12x results remain separate. Its report records
384 bonus ticks but very slow SwiftShader wall frames, while simulation callback
cost stays small. This does not identify physical-phone GPU/frame behavior.


The Android morning snapshot at tick9786 has four Working sleep jobs, rest
843/840/856/861,health100 and fullness641 each. No working sleeper has reached
the900 wake threshold. This is one observed recovery endpoint, not a full sleep
or12x performance certificate. Its explicit settings save records the whole-map
2dp zoom and actual panned camera center65.5387878417969,64. Earlier settings
reads predated the pan and are not used as live-camera numeric proof. Explicit
saves before/after entering and canceling field mode preserve that actual camera
exactly and every saved world value. At tick10052,two residents are awake while
two lower-rest residents still sleep; neither sleeper has reached900. This
observes independent waking and gradual recovery without a fully rested sleeper.

A separate same-source63 retry uses a new lower-contention report directory,
with the emulator stopped and long scenario/generation workers completed. Any
headless validation sharing the host is recorded separately; the failed original
run and unchanged1.75-second protection remain. The retry is still running.


## 0.7.66 measure background-worker wall latency

The local report adds save_worker and snapshot_worker, measured immediately
before starting the thread through completion of its explicit owned-data cleanup.
This includes scheduling and worker work, excludes foreground capture and later
poll delay, and overlaps CPU callback timings. Capture tick and actual playback
speed remain attached even if polling happens paused or at a different speed.
Successful/failed saves and explicit preparation joins are consumed once.
Headless queues without presentation context add no invented speed sample.
The owned payload, acknowledgements,1.75-second guard, thread policy and save
schema/content/generator/replay expectations do not change. Collector bounds are
13stages times5speeds=65histograms,14bins,32slow events and64KiB JSON. Two English
stage keys bring the catalog to530messages.

Seven new gated-worker checks pass. Full persistence472 and replay62/all older
acknowledgements pass. The first invocation failed because the new global class
had not been imported. Two later runs failed three assertions because their test
timers could consume time from earlier in the long startup frame; actual worker
latency could be2.258ms. Requiring monotonic elapsed wall time fixes that test
assumption without changing production timings. All failed logs are retained.
Android105/version0.7.66-m7 export and metadata pass; unchanged cached Kotlin4
XML is inspected. Fresh current graphical/native checks remain separate: the
publication workflow requires all native,prototype/UI and generation jobs to
pass. Local GUI waits until the frozen63 probe finishes.
The frozen63 retry shares the host with these bounded headless checks and export,
with no other graphical game/emulator and no long scenario/generation workers.


## 0.7.67 adapt quiet nights before returning to manual speed

Quiet sleep begins at12x and, after more than one second of bonus backlog lasts
three consecutive seconds, tries8x and then6x. Each step drops only unused wall
backlog and resets the overload clock. If6x cannot keep up either, retain the
selected1x/2x/4x speed and suppress bonus playback until someone wakes. Brief
stalls do not downgrade; a pause retains the learned tier for that sleeping
period, and waking or explicitly changing the setting resets it. No world tick,
event check,alert,save rule or selected speed is skipped or changed. The HUD
shows the actual12x/8x/6x sleep speed and the existing tooltip retains the selected
speed; Settings says Up to12x. Final manual fallbacks remain a separate counter.
Diagnostic speed buckets add6x/8x:13stages times7speeds=91histograms,with the same
32slow-event,14bin and64KiB bounds.

Scheduler421 passes. Injected per-tick CPU budgets settle at8x or6x and every
saved state equals an ordinary complete-tick twin. All three tiers stop on the
exact first waking tick, restoring each selected1x/2x/4x speed; actual fires stop
at one tick with either alert-pause policy. Full manual fallback and per-sleep
suppression checks remain. Persistence472,replay62/all prior acknowledgements,
graphical UI670 and Android106 export/metadata also pass. The inspected390x844
HUD displays8x sleep while retaining4x; diagnostics carry actual8x. These tests
do not establish physical-device throughput. quiet-tiers-v67-evidence.json
retains source/log/APK/screenshot hashes. New67remote gates remain separate.


0.7.65 source1bf6067 passes every remote job and publishes code218. Actual
four-host artifacts,28suite XMLs totaling2816,Kotlin4,768map subset and exact
three published assets pass the independent audit in native-ci-v65-evidence.json.


The66 prototype CI fails at its default120-second persistence timeout after all
seven new timing checks printPASS. This remains a failed run with no published66
APK. Its independent native Linux472-check suite passes in99.768seconds,compared
with65's96.908seconds. The prototype bound is now explicitly180seconds,matching
local checks; assertions,error rejection and game durability guards are unchanged.
ci-v66-timeout-failure-evidence.json retains actual failed log and native XML/log
hashes. New67CI must complete independently.


The same-source63 retry finishes1800.023079seconds at2x,36001ticks3002to39003,
twenty residents,no diagnostic counters and14.618MiB peak/14.611MiB ending sampled
engine-heap growth. Lowest one-second FPS28.134,zero sustained sub24 streak;
full source/input/invariants/roundtrip/audio checks and independent second audit
pass. Every complete authoritative value equals the previous passing62 endpoint.
No other graphical game/emulator ran; bounded headless suites,replay,imports,
exports and artifact downloads shared the host after long campaign workers ended.
This comparison does not assign the earlier failure's cause. Both original failed
and new passing63 reports remain retained; later67runtime/physical gates stay
separate. native-soak-v63-retry-evidence.json records exact hashes.


## 0.7.68 hoist stable job-release reads

Release still visits every historical stack. After unchanged callbacks,compute
its normalized keep-reservations policy and jobID once,then read each stack's
current location once. Every reservation erase/reinstatement,zero-count carry
and escrow coordinate/owner/job reset,worker cleanup and recursive callback
retains its original order. The complete originaldefdc91 method remains an
independent oracle; no save/content/generator/rule/golden or history changes.
Four new checks cover20kind/cancel/history cases,explicit depleted carry cleanup,
recursive real helper cancellation and complete ordinary future/reload equality.
Scheduler425,persistence472,UI670,replay62/all historical acknowledgements,
530-key content validation and Android107 export/metadata pass.

Four alternating final pairs preserve every unsorted payload/invariant/input/
source. Ordinary20/720ticks median3117584.5to3013387us (3.34% lower); fresh7200
1143907.5to1138812.5us and stress720ticks3200260.5to3185287.5us are essentially
unchanged (0.45%/0.47%). Earlier independent trace medians for27release calls
fall285856.5to199035us,with complete state equality; nested trace timings remain
separate from production pair results. Prototype/early runs overlap current67's
native4x probe; corrected pairs share bounded headless checks after it ends.
These are desktop CPU observations,not physical phone/frame or heap claims.
release-hoist-v68-evidence.json retains each source/input/report/log/APK hash.

The initial temporary prototype fails mixed-indentation compilation. The fourth
new test initially requires String-key order across save/load,which the unchanged
sorting encoder does not preserve. Raw diagnosis proves every value,canonical
hash and future invariant matches. The corrected test retains strict unsorted
in-memory twin checks and complete value equality across reload. All failures
remain retained. New68remote publication/native/physical gates remain separate.

Current67's ten-minute4x probe completes600.02469seconds and24001ticks at4x,
twenty residents,zero pause/reduction/storage counters,lowest one-second FPS28.988
and exact roundtrip/source/audio gates. It fails the strict sampled-heap proxy:
25009847bytes transient growth at60seconds/tick6605 against20971520bytes;
ending growth9552980bytes. Its separate second audit also fails. Actual worker
maximums are744.073ms save and282.787ms preparation; foreground captures stay
below17ms. Sample rows lack ownership flags,so the transient's cause remains
unattributed. native-soak-v67-4x-failure-evidence.json retains the failed case;
this is not a30-minute2x or physical gate pass. The20MiB/game1.75second guards
remain unchanged. Snapshot ownership/allocation is the next measurement target.


All67remote jobs and publication pass. Actual four-host artifacts,28suite XMLs
totaling2842,Kotlin4,768map subset and exact three published assets are audited
in native-ci-v67-evidence.json; code220 APK SHA-256 is
`84a3a69e7066baa89802c25835032079634bdde34a6b2084669c3b12c7538ec4`.


## 0.7.69 trace frame-boundary heap ownership in the native probe

This checkpoint changes development tooling; src,data and scenes are unchanged
from007c70b. Native samples add writer/alive/preparation/ready flags,capture and
journal ticks,retired payload groups and navigation-cache sizes. A separate
observer reads process heap at frame boundaries and retains only the last32new
high-water contexts,creating private context data only when the maximum rises.
Its source is fingerprinted. Unknown baselines/unsupported reads stay null;
reports cannot alias or mutate source contexts. Collector allocations are part
of the declared scope. These observations describe concurrent ownership,not
causal allocation or physical Android/PSS/thermal certification. The existing
periodic20MiB proxy,1.75-second game protection,world state and all save rules
remain unchanged. New trace schema/count/maximum/history checks reject malformed
additive data while retaining older audit compatibility.

Five new collector checks and full persistence477 pass; eight native-auditor
Python tests pass. The native harness compiles and still rejects headless use
with exit2/no output report. Current Android108 export/metadata and530-key content
checks pass; unchanged cached Kotlin4 XML is inspected. Maintained total is2851
GDScript assertions. Application UI/replay behavior retains the previous source
scope; first frozen-source native tracing and69remote publication are pending.
heap-trace-v69-evidence.json retains exact source/log/APK hashes.


## 0.7.70 private journal readback without a second decoded tree

Only the two internal writer-verification calls consume fresh private parser
containers through the existing checked owned decoder. Public recovery uses its
unchanged nonmutating reader. Framing, checksums, sequence/schema checks, complete
returned field/key order and types, and integer/map/tile/depth rejection remain.
The independent reference is the complete126407a journal source except its class
name. Four new tests compare five immutable journals and structured/corrupt/torn
frames, input/container isolation and complete delta replay plus120future ticks.
Persistence481, UI670, replay62/all retained acknowledgements, content530 and
Android109 export pass; cached Kotlin4 XML is inspected. Maintained total:2855.

On the unchanged real786,536-byte writer frame from retained failed67scratch,
four alternating pairs show median sampled decoder heap growth18,914,044 to
14,275,700 bytes (24.5% lower), CPU33,580.5 to33,842.5 microseconds (0.8% higher),
and identical ending allocation9,345,160 bytes and complete unsorted output hash.
This measures a decoder component, not whole-writer memory or phone frame rate.
The initial undrained prototype's ending allocation is invalid and retained;
the corrected prototype informed candidate choice, while final production pairs
supply the reported figures. journal-read-v70-evidence.json records hashes.

The preceding69native diagnostic finishes180.0317seconds/7201ticks at4x with5399
valid frame observations. Periodic peak14,858,736 bytes passes its20MiB proxy;
a separate frame peak30,205,169 bytes occurs with a live writer, no preparation
worker and stable navigation caches. Memory remains unresolved and no causal
allocation is assigned. native-heap-v69-observation-evidence.json retains this
scope;67's earlier strict failure remains. New70whole-writer tracing is pending.

Both68and69remote jobs and actual artifacts now pass their independent audits:
four native targets, all28 prototype XMLs, Kotlin4,768maps and exact three
published assets. native-ci-v68-evidence.json records code221;69records code222.
No physical Android, battery, thermal or human certification is inferred.


## 0.7.71 retire temporary writer buffers before later work

The disk worker releases its producer patch after framing, keeps the next parent
as a digest instead of a redundant frame, and releases read-back/append bytes
before matching the parsed patch. It drops verified trees before retaining the
acknowledged base. Prepared rotation releases checked old-journal bytes and
consumed command records before serializing the catch-up marker. Oversized
fallbacks release obsolete encoding buffers before the full snapshot. Every
change replaces a local reference; shared captures and evidence are unchanged.
Durability, error handling, exact bytes, size limits and acknowledgement order stay.

Three new twins retain the complete7698c08 checkpoint/prepared methods as an
independent reference. They compare metadata, exact journals, snapshot envelopes
with only wall timestamps normalized, pending commands, recovery plus60future
ticks, and failed full rotation with retained trace/evidence and successful retry.
Persistence484, UI670, replay62/all old acknowledgements, content530 and Android110
export/metadata pass. Kotlin4 remains an inspected unchanged cached result.

Four alternating full checkpoint pairs on the original checked snapshot22,
12-frame prefix and actual13th marker keep identical appended bytes, metadata and
complete recovery. Both paths use production-equivalent owned capture retention.
Median sampled peak growth falls22,327,414 to15,881,104 bytes (28.9%); checkpoint
wall time96,676 to97,689.5 microseconds is essentially unchanged (+1.0%). Ending
allocation is1,404 bytes for both. This includes the append/readback/patch match,
thread lifecycle and disk cache; it is not a whole-session or physical claim.
The first harness incorrectly used recovered-store metadata as a live append
anchor and correctly failed parent validation. Its raw failure remains; the
corrected harness derives all anchors from the fully validated original chain.
Production recovery still requires a new snapshot. writer-buffers-v71-evidence.json
records source/input/log/APK hashes. Frozen71whole-session measurement is next.

The preceding70diagnostic completes180.022838seconds/7200ticks at4x,20residents,
zero counters and lowest one-second FPS29.413. Its periodic peak7,660,230 bytes
passes the proxy and separate second audit. Frame-boundary peak30,358,802 bytes
still occurs during live writer ownership with no preparation and stable caches.
The decoder improvement therefore does not resolve whole-session memory.
native-heap-v70-observation-evidence.json retains that scope and earlier failures.


## 0.7.72 bound native packing during internal journal framing

Four internal writer calls use a private encoder that walks sorted string-keyed
dictionaries and native-packs at most256 array rows or integer-map entries per
block. IDs, tags, sorted integer keys, escaping and every framed byte stay exact.
The original public frame encoder and recovery reader remain unchanged. Unsupported,
deep or size errors fall back to the original encoder; caller bounds and snapshot
fallbacks still apply. Inputs, captures, durability and acknowledgements stay.

Three new checks compare every record in five immutable journals against the
complete independent native encoder, exercise0/1/255/256/257/512/513 row boundaries,
mutable/frozen inputs, integer maps, IDs, tags, Unicode/escaping, and deep fallback.
Persistence487 also passes the prior complete writer/reference twins. Native
UI670, replay62/all old acknowledgements, content530 and Android111 export pass;
Kotlin4 is an inspected unchanged cached result. Maintained total:2861.

Four alternating real-frame encoder pairs produce identical786,572framed bytes
(payload786,536). Median sampled peak growth falls9,633,600 to2,075,580 bytes
(78.5%); encoding time30,139.5 to27,834 microseconds (7.6% lower), ending allocation
1,180,098 bytes for both. Full checkpoint pairs against7698c08, including the71
buffer-lifetime change, remain exact in bytes, metadata and recovery: peak
22,343,648 to15,484,270 bytes, wall time98,944.5 to99,141 microseconds and ending
1,404 bytes. This cumulative comparison does not isolate72 whole-writer benefit;
the complete checkpoint still has a large transient peak. Thread lifecycle,
sampling, disk cache and concurrent bounded UI/replay checks remain in scope.
journal-frame-v72-evidence.json retains source/input/log/APK hashes and both
read-only candidate prototypes. No physical/session-level gain is inferred.

The71 short native case completes180.016457seconds/7200ticks,20residents,zero
counters and lowest one-second FPS29.464. Periodic peak7,944,796 bytes passes its
proxy and separate second audit. Frame-boundary peak30,249,953 bytes remains at
tick5395 during live writer ownership, no preparation/retired groups and stable
navigation. native-heap-v71-observation-evidence.json retains the unresolved scope.
Current72 frozen-session measurement is next; prior failures remain failed.


## 0.7.73 retain immutable capture values while constructing writer patches

Only CapturedStore uses the private owned-after delta helper. Its after-state is
an owned, recursively read-only ColonyCapture tree and equals the writer's frozen
world. Changed records and whole replacement values can remain referenced until
framing completes. Public mutable delta creation and direct ColonyStore calls
still clone them. Reconstruction returns independent mutable state. Patch fields,
order, integer handling, wire bytes, matching and save rules stay unchanged.

Four new checks retain the complete2446783 delta source independently and cover
unsorted patch equality, records/maps/reordering/empty/wide values, explicit frozen
sharing versus public mutable isolation, independent mutable reconstruction and
120 real future ticks through the captured/direct writer methods. Persistence491,
UI670, replay62/all old acknowledgements, content530 and Android112 export pass.
Kotlin4 is an inspected unchanged cached result. Maintained total:2865.

Four alternating real26426/26466 capture pairs keep exact patch hash, full restore
and matching, input/source unchanged. Median patch-construction time falls11,264
to8,662 microseconds (23.1%), sampled peak5,705,560 to180,076 bytes (96.8%), ending
5,705,560 to128,764 bytes. Complete checkpoint comparison against7698c08 includes
71/72/73: wall time97,678 to90,751 microseconds, peak22,371,854 to15,481,666 bytes
and identical ending1,404 bytes, appended bytes, metadata and recovery. It cannot
isolate73's whole-writer effect, and a large checkpoint peak remains. No other
native GUI/emulator or benchmark runs during final pairs; thread lifecycle,
sampling and disk cache remain included. owned-delta-v73-evidence.json records
source/input/log/APK hashes. Current73whole-session tracing remains separate.

The72short native case completes180.018198seconds/7200ticks,20residents,zero
counters and lowest one-second FPS28.645. Periodic peak7,196,632 bytes passes its
proxy and independent audit. Frame-boundary peak29,856,564 bytes remains during
live writer ownership without preparation and with stable caches. The component
encoder improvement therefore does not resolve the session transient.
native-heap-v72-observation-evidence.json retains this scope and earlier failures.

Remote70jobs succeed.71's first Intel generation job reaches its existing600second
timeout after GEN/pine1_reference_extra_requires_forty_one_real_path_steps; it has
no passing generation result. The prototype and three other native jobs succeed,
publication is skipped in that attempt, and generation/src/sim/data are unchanged
from70. Raw partial artifacts and job/run logs remain retained in
ci-v71-timeout-failure-evidence.json. A same-source failed-job retry is requested;
limits are unchanged and no host-load cause is assigned. Later attempts need their
own actual-artifact/publication audit; this first attempt remains failed.


## 0.7.74 prove an empty catch-up without reparsing a verified prefix

The store retains only a private maximum command tick, prefix digest and validated
frame count. They derive from fully read-back/checked acknowledged tails, not
from pending/live command guesses. Full snapshots reset to zero commands; cold
loads are unknown. When the known maximum is no later than preparation, its
metadata still matches and the actual nonempty prefix length/SHA-256 match, no
newer commands exist. That case avoids the second whole-journal JSON parse.
Unknown/mismatched metadata or later commands use the unchanged full selector.
An empty digest cannot prove a nonempty journal. Failures retain the old bound;
verified publication derives the new one. Queue capture/poll and adoption carry
three primitive fields. Nothing is added to saves, world state or diagnostics.
Readback, checksums, schema/value matching, byte/sequence bounds, publication order
and the1.75-second durability guard remain unchanged.

Five new checks compare complete9905cf2 checkpoint/prepared methods independently:
no commands and already-covered commands take no fallback read; later commands,
unknown bound, wrong digest/count retain full reading; changed bytes reject before
acknowledging pending work. Failed snapshots preserve evidence/bounds, successful
ones reset, and real queue/preparation/adoption carry them correctly. Journals,
authoritative metadata, snapshots with only wall timestamps normalized, recovery
and future ticks stay exact. Persistence496, UI670, replay62/all old acknowledgements,
content530 and Android113 export pass; unchanged cached Kotlin4 is inspected.
Maintained total:2870 GDScript assertions.

Four alternating full rotations rebuild the original31-frame8,213,290-byte journal
through actual save/checkpoint/readback. Preparation is at tick27166, newest capture
27194; the foreground durable base remains held through the worker measurement.
Reference full reading runs once per case, current fallback reads zero. All original
journal bytes, new journal, normalized snapshot, authoritative metadata, complete
recovery, inputs and source match. Median rotation wall time falls660,702.5 to
273,368 microseconds (58.6%); sampled peak growth25,048,073.5 to17,457,759 bytes
(30.3%), ending growth2,040 bytes for both. No other native GUI/emulator/benchmark
runs during final pairs; thread lifecycle, sampling and disk cache stay included.
This is a rotation component result, not a session/phone certificate.

The first retained experiment prepared much earlier at25967 and omitted the
foreground base owner. It passed functional equivalence but negative ending growth
included releasing that base; it is not used for queue-heap inference. Its raw
harness/results remain. prepared-bound-v74-evidence.json records authoritative
near-head-held pairs, source/input/log/APK hashes and the initial scope. A frozen
ten-minute4x run is next; every earlier failed scope remains unchanged.

Actual70remote artifacts now pass their independent audit: four native targets,
28 suites/2855 assertions,Kotlin4,768 maps and exact three published assets.
native-ci-v70-evidence.json records code223 and APK SHA-256
`5e9726e744d4e4f0951a1b7463cb95ab72ce4c005e39e2422e9cb0c9c481b971`.
71's first Intel timeout remains retained while same-source attempt2 runs. Later
CI/publication, physical memory/battery/thermal and human gates remain separate.


## 0.7.75 paused shift feedback and citizen/work text audit

Original real controls reproduced a paused scheduling bug: both taps queued
Night shift while the caption stayed Normal; one tick then applied Night twice.
The control now cycles from its latest queued choice and immediately updates its
pending caption/tooltip. Reopening retains that choice without a tick or camera
move. Two taps queue Night then Normal and apply once in order on the next complete
tick. The shared button wrapper preserves its selection sound; a work-pane identity
guard keeps the callback tied to its active pane. Preference tooltips also track
their updated captions. Four new real-control regressions pass headless and in
the full graphical674-check suite,including next-tick receipts and invariants.

Forty-eight additional English messages bring the catalog530to578. Citizen and
inspector summaries, work categories/preferences, bed assignment, recipe choices
and colony-mode labels use named templates. All530previous values remain exact.
Stored shifts/categories/modes, routes/callback IDs, names/facts, numerical rest
rules, core persistence/simulation/generation/scenes and99-character font coverage
stay unchanged. Shared/canonical descriptions and activity/fact/trait/food-tag
presentation remain later audit; no translated language selector is added.

Fresh unit20,five Python message checks,578-key/font validation,UI674 and Android114
export/metadata pass; cached Kotlin4 XML is inspected. Core source is unchanged
from74's persistence496/replay62/retained acknowledgements. Maintained total:2874.
Final native150%text portrait360x640 and landscape640x360 captures were inspected:
the pending caption is visibly inside the scroll area,249px text plus16px insets
fits320/600px-wide,48px-high controls. The original unscrolled/horizontal-only
captures remain retained; final captures prove actual visibility. Final GUI674
and APK validation follow restoration of the common sound wrapper and tooltips.
work-text-v75-evidence.json retains source/log/image/APK hashes and original repro.

Frozen74's ten-minute4x probe completes600.009101seconds and24001ticks4204to28205,
20residents,zero counters,lowest one-second FPS28.564 and exact roundtrip/source/
input/audio/invariant gates. Periodic sampled peak13,949,006bytes and ending
10,012,328 pass the unchanged20MiB proxy and a separate second audit. A separate
frame-boundary peak34,749,968bytes at tick27199/574.843seconds occurs during live
writer ownership,no preparation worker and stable navigation. It lies beyond the
older three-minute runs and is not a regression ratio. Memory remains unresolved.
Same-input actual67/74endpoints are identical in every field after one current
alignment tick28205to28206,canonical hash
`de1c7f25827172b86cc842a706f91aeb45424e0b3f502474733725e35c7aeba4`.
No normalization or input replacement occurs;67's failed heap case stays failed.
native-soak-v74-4x-evidence.json retains both valid subsets and unresolved scope.
A latest30-minute2x rerun and physical gates remain separate.

Actual71attempt2,72,73and74remote artifacts now pass independent audits: all four
native targets,28 prototype suites,Kotlin4,768maps and exact three published
assets per revision. Published codes224/225/226/227 retain their respective source
identities.71's earlier Intel timeout stays failed in separate evidence; the
latest Intel artifact is selected instead of its retained earlier partial one.
74actual artifacts and exact published APK also pass; native-ci-v74-evidence.json records code227 and its source identity.


## 0.7.76 synchronous route task context

A read-only complete-tick subsystem breakdown identified route/assignment spikes
in the late twenty-resident input. Its instrumented late2240ticks and fresh3600ticks
match ordinary twins in every unsorted field and invariant. Callback/observer and
host scheduling overhead remain included; these are headless diagnostic timings,
not native frame/phone causes. The full original step matches the phase harness
after unwrapping timing callbacks and its equivalent domestic wrapper.

Citizen A* previously found the same current task and chose its cart-edge policy
at every examined edge. It now reads both once per synchronous search and passes
the same live task to the danger predicate. Ordinary callers still inspect current
work. Each new search rechecks phase/state; final live edge validation,request
slots,no-route handling,unreachable-bed safe-ground rest and every ordering rule
remain. Nothing survives the call or enters world/save data. Catalog7/schema23,
all gameplay numbers,wire bytes and old acknowledgements remain unchanged.

The independent reference retains complete4515ea6 walk and danger bodies,verified
byte-for-byte apart from private qualification. Four new checks cover seven task/
fence/cart policies,meet/push/state changes between searches,four-request and
unreachable-bed fallback behavior,and a real1200-tick cart move plus reloaded future.
All27headless suites/2204 assertions pass. With75's unchanged674GUI source at its
original scope,the maintained count is2878. Replay62/all retained migrations,
578messages/font validation and five Python message checks pass. Android115 exports;
metadata/hash and unchanged cached Kotlin4 XML are audited. The initial launcher
did not retain its shell return code; explicit export completion,clean engine-log
scan and artifact metadata checks are retained. The host adb daemon connection
refusal is recorded; no emulator/physical install is claimed.

Final versioned four-pair comparisons preserve every complete unsorted state and
invariant,all source fingerprints and input/base state. Fresh7200ticks improve
median1,145,977to1,137,040.5us (0.78%);late1200ticks4,500,362.5to4,447,107.5us
(1.18%). This is small,not a phone-freeze fix certificate. Native75longevity,
bounded headless checks/replay/import/export and75artifact downloads share the
host; no other GUI/emulator runs. Early edge-only/pre-version comparisons remain.
The first direct load of an unregistered new reference class printed a parse error
despite exit0; no result was accepted. After editor import,fail-closed validation
and exact twins pass. route-context-v76-evidence.json retains source/log/proof/
profile/APK hashes,including that initial error.

Actual75remote artifacts now pass four-host replay/migrations/persistence/startup,
28suites/2874 assertions,Kotlin4,768maps and exact three published assets.
native-ci-v75-evidence.json records code228/APK SHA-256
`1e1783a6d1fbb919634996d061630985eed43b8d1008e972aa0ebd5d4a5c84c4`.
The latest thirty-minute2x75probe is still running; previous failures,late frame
heap peaks,physical Android/PSS/thermal and human gates remain separate.


## 0.7.77 person/care text and latest native-duration audit

Ninety-three English messages bring the catalog from 578 to 671, with every prior
value unchanged. All 54 known fixed activity phrases, eight traits, eight food
tags and seven skills use exact-value presentation maps. Unknown or composed saved
activities and reasons stay literal, including braces. Trait asset paths and
stored IDs are unchanged. Bed descriptions use the actual 75/60/45 recovery rates
and match the unchanged simulator description for unassigned, destroyed, outdoor
and roofed beds. Care summaries, bleeding/treatment/Hearthside timelines and named
actions, plus newcomer summaries, skills, deadlines, readiness and accept/decline
actions, use named templates. Rates, world/save fields, action IDs and routes stay
unchanged. No language selector is added.

Six new pure checks pass in persistence 502; five new real-control checks pass both
headless and in the full native GUI 679 suite. Unit 24, catalog/font validation,
five Python message checks and Android 116 export/metadata pass. Cached Kotlin 4
XML is inspected. An independent headless comparison loads actual 75 and current
77 controls: all 56 text nodes across five panels, world hashes, visible world
focus and pending newcomer acceptance bytes match exactly, without normalization.
Care callbacks retain real patient/worker IDs. The first camera assertion compared
raw camera_tile across a layout offset change; diagnosis showed correct text and
state already. Final checks compare the preserved camera_center. Both initial
failures remain retained. The route oracle loses only its trailing blank separator;
no executable code changes. Core persistence/simulation/generation/scenes and
immutable fixtures remain exact from 76. Maintained total: 2,889.
person-text-v77-evidence.json retains source, proof, log and APK hashes. Composed
activities, facts/morale, shared descriptions and remaining templates stay in the
M7 audit.

Frozen 75 completes 1,800.006347 seconds at 2x: 36,000 ticks from 3,002 to 39,002,
twenty residents, zero counters and lowest one-second FPS 28.587. Snapshot roundtrip,
source/input, logical time, invariants and audio checks pass. Periodic sampled peak
and ending growth are 15,468,248 bytes, within the unchanged 20 MiB proxy; both
independent audits pass. Actual 63-retry and 75 endpoints match every field and
canonical hash at tick 39,003 after one current 77 alignment tick. No header or
gameplay normalization occurs; both retain the same original input.

The separate frame-boundary peak is 36,017,872 bytes at tick 37,383 and 1,719.065
seconds, with a live writer, no preparation worker and stable navigation. Its
cause remains unproven. Individual ticks average 5.033 ms, peak at 91.190 ms and
have p95/p99 bucket bounds of 33.334 ms; p95 exceeds 25 ms and does not meet the
4 ms target. At the 30 FPS cap, frame-gap p95/p99 bounds are 36/50 ms. Worker maxima
of 223.755 ms for saves and 295.074 ms for snapshots are parallel wall latency and
must not be added to CPU totals. No other GUI/emulator runs during measurement;
bounded headless work, source edits, replay/import/export and artifact downloads
share the host. native-soak-v75-evidence.json retains valid subsets and unresolved
scopes. Earlier 63-original storage-pause and 67-heap failures remain failed;
physical Android/PSS/battery/thermal and human certification stay open.


## 0.7.78 direct assignment eligibility filtering

A read-only breakdown of 1,200 late-colony ticks matches its ordinary twin exactly.
The instrumented 4.318-second run spends 492,201 microseconds in 2,400 repeated
open-job filters, about 11% of its total. Timers and nested phases overlap; this is
headless diagnosis, not native-frame or phone causation. The original assignment
body is verified after stripping only added timing statements.

During trusted complete ticks, a direct typed loop now collects eligible jobs
instead of calling a filter callback for each row. It excludes exactly Complete,
Canceled and Queued, retains original order and live record references, and returns
a newly owned list. Direct calls outside a tick keep the original query/filter.
No cache, saved field, rule, admission change or historical mutation is added.
The independent reference retains the full f887763 assignment-search method;
the current method differs only in its helper call.

Three new scheduler checks cover all nine states across 576 records, ownership
and live references, same-tick appends/endings/releases, array replacement/shrink
and unchanged direct-call state. Scheduler 428, persistence 502, unit 24, replay 62
and every retained acknowledgement pass. Catalog/font validation, five message
checks and Android 117 export/metadata pass; cached Kotlin 4 XML is inspected.
The unchanged presentation keeps 77's GUI 679 at its original scope. Maintained
total: 2,892. assignment-view-v78-evidence.json retains source, proof, log, profile
and APK hashes.

Final versioned four-pair medians preserve every complete unsorted state,
invariant, source fingerprint and input/base state. Late 1,200 ticks improve from
4,374,820.5 to 4,145,258.5 microseconds (5.25%); fresh 7,200 ticks from 1,137,910 to
1,131,134.5 (0.60%). The legacy v6 ordinary-twenty endpoint at tick 693,000 is loaded
through current migration, then compared for 720 current future ticks: 2,925,097 to
2,875,179 microseconds (1.71%). This is not a new 96-day campaign certificate. Its
shorter 120-tick case, including one slower pair, remains retained; the longer
case examines that variation without assigning a cause. No other GUI, emulator
or benchmark runs during final timings. Subsequent headless checks and artifact
downloads run afterward. The 4 ms tick target and physical gates remain open.

Actual 76 and 77 remote artifacts pass four-host replay, migrations, persistence
and startup checks, their complete 28-suite totals, Kotlin 4, 768 maps and exact
three published assets. native-ci-v76/77-evidence.json retain source identities and
published codes 229/230. Version 77 is the latest fully audited download. Current
78 CI/publication and physical Android/PSS/thermal/battery/human gates remain
separate; prior failed scopes remain retained.


## 0.7.79 lazy edible-definition candidate view

Repeated food selection now borrows a derived edible-definition view during a
trusted tick. Its key includes both the logical tick and borrowed inventory
identity, with an appended-prefix count and replacement/shrink/reset invalidation.
Every location and travel ration is included regardless of current policy; zero
rows still present in the borrowed inventory remain candidates. The unchanged
selector reads all quantities, reservations, release projections, policy, ages,
preferred tags, ordering, safety and routes live. Direct calls clear the view and
use the original positive-inventory query. Four derived fields never enter saves.
The complete original 25cb2c0 selector remains an independent oracle.

Five new checks cover membership, shared records, policy/location changes,
appends/depletion, equal-size borrowed-source replacement, reservations/release
predictions and hungry save/reload continuation. The equal-size replacement check
failed the initial three-field prototype; its exact source/test and failure are
retained. Adding the identity guard passes all five targeted checks and the final
full suite. All 27 headless suites / 2,218 checks and native GUI 679 freshly pass,
for 2,897 maintained checks. Replay 62 retains both goldens and all old
acknowledgements. Catalog/font 671, messages 5, Android 118 export/metadata and
cached Kotlin 4 XML pass. food-view-v79-evidence.json records these scopes.

The final four alternating complete-tick pairs retain every unsorted field,
invariant, source/input fingerprint and initial state. Late 1,200 ticks improve
4,093,545.5 to 4,079,412 microseconds (0.35%); their shared worst tick 26,280 improves
67,945.5 to 64,878.5 microseconds (4.51%). Late p95 and p99 are slightly higher,
17,455.5 to 17,532 and 24,042.5 to 24,343.5 microseconds. Fresh 7,200 ticks improve
0.20%; 720 future ticks from the migrated legacy twenty-resident endpoint improve
0.47%. These are essentially unchanged average times, not a broad tick-budget fix.
The legacy case is not a new 96-day campaign certificate. No other native GUI,
emulator or benchmark runs during final timing; host scheduling and the per-tick
observer remain included.

A separate complete-state diagnostic observes 20 food calls at tick 26,280,
reusing the same candidate array 19 times and narrowing 1,059 inventory rows to
139 candidates. Nested phase timings overlap and the old/current component
samples are diagnostic rather than a paired phone/CPU estimate. The obsolete
pre-version three-field profile remains retained. Version 78 remote artifacts,
all four native hosts, 2,892 prototype assertions, Kotlin 4, 768-map subset and
exact three published assets pass the independent audit (code 231). Current 79
native/CI/publication and physical Android/PSS/thermal/battery/human gates remain
open. Native 75's duration pass and unresolved frame-growth/tick-budget evidence
retain their original scope; earlier failures stay failed.


## 0.7.80 direct treatment/emergency existence scans and testing handoff

Two trusted-tick assignment probes now use direct typed loops over the same
search-local open-job list, retaining exact predicates, predicate order and first
match short circuit. Both read target, state, worker, retry and tick live. Calls
outside trusted ticks retain the original callbacks. No new cache, persistent
field, rule, admission or wire behavior is added. The complete original 476bdd0
assignment-search method remains an independent oracle.

Five new scheduler checks cover all nine states, treatment kinds/targets,
emergency worker/retry boundaries, same-tick mutations/appends/replacements,
short circuit and unchanged direct-call state. Two real 700-tick treatment/fire
cases compare every unsorted field against the complete original search, reload
both at tick 90, require observed waiting/emergency ownership and actual job
completion, and retain invariants. The initial test reloaded only one twin and
failed dictionary insertion-order equality at the reload despite equal canonical
hashes. Its exact source, failure and diagnosis stay retained. The corrected test
compares before and after the same reload on both twins; product code is unchanged.
A wrong message-test discovery pattern ran zero tests and exited 5; that result is
rejected and retained. The corrected pattern freshly runs all five tests.

Scheduler 438, persistence 502, unit 24, care 55, fire 23, defense 81, replay 62
and every old acknowledgement pass. Catalog/font 671, Python messages 5, Android
119 export/metadata and cached Kotlin 4 XML pass. Presentation and other production
paths are unchanged; 79's fresh other 21 headless suites and native GUI 679 retain
their scopes. Maintained total: 2,902. assignment-probes-v80-evidence.json retains
source, independent method proof, logs, actual APK and complete-tick comparisons.

Final late four-pair total medians: 4,176,351.5 to 4,122,712.0 microseconds (1.28% reduction). All full unsorted states, invariants, inputs, initial states and source fingerprints match.
Final fresh four-pair total medians: 1,144,078.5 to 1,137,500.5 microseconds (0.57% reduction). All full unsorted states, invariants, inputs, initial states and source fingerprints match.
Final ordinary20 four-pair total medians: 2,943,680.5 to 2,899,702.5 microseconds (1.49% reduction). All full unsorted states, invariants, inputs, initial states and source fingerprints match.
These final timings run after the native 79 soak ends, with no other GUI,
emulator or benchmark active. Per-tick observer and host scheduling remain
included. The legacy case loads the actual old v6 ordinary-twenty endpoint at
693,000, then compares 720 current future ticks; it is not a new 96-day certificate.
The 4 ms tick budget and physical-phone behavior remain unresolved.

Frozen 79 completes 600.015925 seconds at 4x, advancing
24,000 ticks from 4,205 to 28,205, retaining twenty residents
and zero counters. Lowest one-second FPS is 28.832. Periodic peak growth is
9,723,279 bytes and ending growth 9,639,316; both
independent audits pass the unchanged 20 MiB proxy, logical time, exact final
snapshot, audio, source/input and invariants. The separate frame-boundary peak is
34,618,920 bytes and remains an unresolved observation. This ten-minute
4x result is separate from 75's thirty-minute 2x pass and from the full physical
stress matrix. Main 80 headless checks, replay, import/export and edits share the
host; no other native GUI/emulator runs. native-soak-v79-evidence.json records the
original scope. No native 80 performance claim is made.

Actual 74 and 79 native endpoints both reach tick 28,205 and compare equal in
every unsorted field without alignment ticks or normalization, retaining canonical
hash ffcf2b76e7a999e6d8659f98d256b1a6e7eae1667f7dbf3180ca47e9120b5944.
Native 79 individual ticks average 4.396 ms, max 74.354 ms, p95/p99 bucket upper
bounds 25/33.334 ms. The 4 ms target is still not met. Frame-gap p95/p99 bounds
are 36/50 ms at the 30 FPS cap; the separate frame peak is 34,618,920 bytes.

On 15 October the user asked to finish the current work, commit and push, then
stop for their testing. This supersedes the earlier autonomous continuation to
50% weekly remaining. Finish this verified batch and publish it; do not start
another development batch until the user resumes. M7 performance/localization and
physical/human release gates remain open; the game is not certified complete.
