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
