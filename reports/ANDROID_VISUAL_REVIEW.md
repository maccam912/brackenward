# Android visual review, 16 October 2026

Local debug version `0.7.102-m7`, Android code 119, pinned Godot 4.7.2,
content colony-v11/schema 24/envelope 5. This review used a new task-owned
Android 35 arm64 Pixel 5 AVD at 1080 × 2340, density 440, SwiftShader/ANGLE.
The existing emulator campaigns and physical devices were not used.

## Header correction found on Android

At 150% text, wrapped clock/notice lines made the status panel taller than its
reserved layout space. The old map buttons overlapped its lower edge. Controls
now follow the actual panel height; the map viewport retains its geometry so
notices do not move the scene. Seven baseline spacing cases failed. The final
native UI suite passes 783 checks, including all existing camera/marker tests and
eight additional notice-reflow stability cases.

| Before, 0.7.101 | After, 0.7.102 |
| --- | --- |
| ![Header overlaps map controls](android-visual-v101-header.png) | ![Map controls clear the wrapped header](android-visual-v102-header.png) |

## Exported visual and interaction checks

Actual ADB touches exercised the site preview and seed input, scroll cancellation,
Build/Work material thumbnails, People portraits, exact need bars, 100/125/150%
text and portrait/landscape layouts. The initial Meadow Reach Standard seed
104729 save matches the retained complete generation reference at tick 1800.

A recorded 103-structure, eight-resident colony was imported through Android's
native document picker into empty campaign slot 2. Its entire migrated gameplay
state matches the source after privately normalizing only the new campaign ID
and pending-command session IDs. Rendering, menus and camera changes stayed
paused at tick 693000. Directly tapping a painted stockpile opened its Storage
sheet with actual capacity, counts and item thumbnails.

![Developed colony in the exported Android app](android-visual-v102-colony.png)

The screenshot shows dawn in the actual imported campaign, not the desktop
review tool's daylight copy. Its crops, storage, masonry stations, furniture,
hearths and beacon use the current shared atlas. Local capture/action logs and
full audit inputs remain in the ignored `reports/visual-polish/` directory.
[Machine-readable checks, hashes and boundaries](android-visual-v102-evidence.json)
retain the initial-generation and full-import audit results.

Local export and Kotlin plugin unit tests passed. Runtime logs contained a
cached-shader recompilation warning, with no observed script errors or Android
fatal exceptions. This is an emulator appearance/interaction check, not physical
Android frame-rate, memory, thermal, battery or device-appearance certification.
The local debug APK differs in signing/version metadata from numbered CI releases.

## 0.7.109 and 0.7.110 follow-up

The same task-owned Android 35 emulator received the two local APK updates. The
103-structure/eight-resident review colony remained at tick 693000. Full codec
comparisons after upgrade and after background checkpoints match every original
gameplay field after normalizing only the imported campaign/session IDs.

Actual touches exercised the revised People/Mira card, expansion and collapse of
the exact food/rest rules, the actual granary detail card, menu text settings at
100/125/150%, forecast scrolling and portrait/landscape rotation. The initial
landscape forecast used too much width for one card per row. Version 0.7.110 now
uses two columns when width allows; rotation back to portrait restores one column.
The v109 Android 150% view remains readable, and native v110 tests cover the
large-text column fallback. The native suite passes 840 checks.

Both local exports and Kotlin plugin tests passed. Runtime logs show a shader-cache
recompile warning, with no observed script errors or Android fatal exceptions.
The emulator was stopped after the final verified background checkpoint. This
remains software-emulator evidence, not physical Android or frame-rate certification.

- [Resident rest details](android-visual-v110-rest-details.png) (captured in v109)
- [Granary detail](android-visual-v110-granary.png) (captured in v109)
- [Landscape before](android-visual-v110-forecast-before.png) (v109)
- [Landscape after](android-visual-v110-forecast-after.png) (v110)
- [APK/source/screenshot hashes and full-state audits](android-visual-v110-evidence.json)

Detailed native/ADB logs and intermediate captures are local under
`reports/visual-polish/`, including the `android-v109-*` and `android-v110-*` files.

## 0.7.117 and 0.7.118 follow-up

The updated landscape Research view exposed excess summary height. Whole
label/value groups now flow across available width. Healthy stations put their
recipes before rename/repair; damaged stations retain prominent Repair. Actual
touches exercised Research and production at 100/150% text and both orientations.

| Before, 0.7.117 | After, 0.7.118 |
| --- | --- |
| ![Research before](android-visual-v118-research-before.png) | ![Research after](android-visual-v118-research-after.png) |

![Production at 150 percent](android-visual-v118-production150.png)

![Updated mature colony](android-visual-v118-map.png)

The full layout review preceded a final type-safety guard for residents named
ResearchSummary. The final rebuilt APK separately passed People/Research smoke
and a full checkpoint audit. All three new audits match every gameplay field
of the original imported colony at tick 693000. Native UI passes 885 checks.
[Exact APK/source hashes and screenshot provenance](android-visual-v118-evidence.json)
distinguish these builds. Exports and Kotlin plugin tests passed; captured runtime
logs contain no script errors or Android fatal exceptions. These remain emulator
checks; physical-device appearance and performance are unverified.

## 0.7.123 animal and environment follow-up

The task-owned emulator received the latest regrowth, item, water and animal-card
art. Actual wildlife list scrolling and deer/boar selection were reviewed at
100/150% text and after rotation. Native fixtures additionally cover adult and
juvenile hens/goats at both text sizes; those livestock states were not exercised
in this Android colony.

The long boar behavior paragraph initially wrapped beside the picture. The final
layout puts health beside the portrait and behavior across the full width below.

| Initial layout, 150% | Final layout, 150% |
| --- | --- |
| ![Initial boar warning](android-visual-v123-boar-before.png) | ![Full-width boar warning](android-visual-v123-boar-after.png) |

![River in the exported game](android-visual-v123-river.png)

Both Android checkpoints match every gameplay field of the original imported
colony at tick 693000; settings ended at 100% text and portrait. The final native
UI suite passes 913 checks, persistence/art passes 518, and export/plugin tests
pass. Captured logs contain no script errors or Android fatal exceptions.
[Build hashes, screenshot provenance and codec audits](android-visual-v123-evidence.json)
distinguish the two APKs sharing the local version label. Physical Android and
device performance remain unverified.
