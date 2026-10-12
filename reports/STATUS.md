# Implementation evidence

Checkpoint: `0.0.1-m0`, content `m0-touch-1`, prototype save envelope `brackenward-m0` version 1. The complete release generator and campaign format do not exist yet. Implementation was authorized on 12 October 2026. The user deferred physical-phone testing until later; M1 waits for the M0 device gate.

| Gate | Status | Evidence / remaining work |
| --- | --- | --- |
| Godot 4.7.2 Standard / Compatibility | Pass | Exact official build `ed1daf0bf`; macOS and template archives match the official SHA-512 sums in `toolchain.lock.json` |
| Pure deterministic prototype state | Pass | 72,000-tick 1x/2x/4x trace hashes match; Park-Miller golden stream; atomic designation / duplicate-command / session rejection |
| Gestures and button alternatives | Pass, local subset | Pan, tap, long press, second finger, paint preview, explicit Confirm, double submit, zoom/camera/nudge buttons; Android emulator citizen tap verified; touch-generated mouse events filtered so they do not become a second finger; physical phone gestures still Not run |
| Portrait / landscape / large text | Pass, local subset | Real Controls at 360x640, 390x844, 640x360, 800x1280, 1280x800, 960x600; 100/125/150% text; nonzero safe insets; visible buttons >=48 logical units; native screenshots inspected |
| Prototype save recovery | Pass, local subset | Checksum/schema/bounds rejection, pending command and movement round trip, three verified immutable generations, interrupted temp ignored, damaged latest falls back |
| Background / return | Pass, local subset | Simulation stops, gestures canceled, resume paused; Android 35 emulator also preserved the 4x2 unconfirmed preview across rotation; physical task battery still Not run |
| Android storage plugin | Pass, build/unit/emulator subset | Original Kotlin v2 plugin; 4 JUnit bounded-stream tests; source builds debug/release AARs; Android 35 arm64 emulator picker export/import passed: checksum verified, tick 1861 restored to exported tick 1800; Home froze the imported state; export and import cancellations left state unchanged; same-identity APK update preserved three private saves |
| Android arm64 APK | Pass, debug/emulator subset | 80 MiB; min SDK 29 / target 36; arm64-v8a only; merged manifest requests no permissions; installed and launched on Android 35 emulator (SwiftShader/ANGLE), not a physical phone |
| macOS native launch | Pass | macOS Apple Silicon, Apple M5 Pro, OpenGL 4.1 Compatibility via Metal 90.5; native scene/UI runner launched |
| Physical Android installation/input/rotation/storage | Not run | User will test later; emulator does not certify this gate |
| Physical memory/battery/thermal baseline | Not run | Requires exact phone model, OS, GPU, brightness and measured battery/memory |
| Desktop export packages | Pass, build subset | macOS universal ZIP, Windows x86-64 EXE/PCK, Linux x86-64 executable/PCK exported locally; only macOS native launch exercised |
| Remote CI | Pass at code checkpoint `8030a22` | [Linux checks, Kotlin tests, Android APK, all desktop exports and exported Linux launch](https://github.com/maccam912/brackenward/actions/runs/38251297873); all 111 local/CI checks pass, including rendered-preview and keyboard-focus regressions |
| Colony work loop (M1) and later milestones | Not implemented | Gather/haul/cook/build/needs, then sustainable colony, people/seasons, production/region, combat/story, campaign and release quality |
| Production signing / public release / store publication | Not run | Separate later authorization |

Local suites: 19 unit checks, 6 integration checks, 82 UI checks, 4 Kotlin JUnit tests. Test names using release acceptance IDs only cover the stated M0 subset. No release gate is certified merely by those names. Generated JUnit/XML/screenshots/logs/builds are ignored; committed reports describe the actual results.

Design amendment: Android compile/target SDK 36, build-tools 36.1.0, NDK 29.0.14206865, Gradle 8.11.1, AGP 8.6.1, Kotlin 2.1.21 match the downloaded 4.7.2 template. The original design's SDK 35 / NDK 28 pins conflicted with that template. No gameplay numbers changed. The template emits an AGP compile-SDK support warning; it remains recorded rather than treated as device validation.

Weekly quota policy: read the account limits before work and at build/checkpoint boundaries; stop autonomous work if remaining weekly usage reaches 50% or less, preserving a validated commit first when possible. Latest observed at this checkpoint: 86% remaining. Do not resume past that boundary automatically.

Local sideload artifacts (code checkpoint `8030a22`, debug builds):

| Artifact | Bytes | SHA-256 |
| --- | --- | --- |
| `build/brackenward-debug.apk` | 84142751 | `0314fe89ca7170690e2bfaee11cc7b1ff5aeac2127ee2207ebff12c483213bab` |
| `build/brackenward-macos.zip` | 64796343 | `7c077b9866d91b1a684794fdb16a3158918871c163c8b374996dc2d944b4f507` |
