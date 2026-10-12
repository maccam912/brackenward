# Brackenward

A woodland colony simulation built from [DESIGN.md](DESIGN.md). The current runnable checkpoint is **M0: platform and touch prototype**, version `0.0.1-m0`. Colony gathering, cooking, construction and survival are not implemented yet. Physical Android testing is deferred to the user before M1.

Use Godot **4.7.2 Standard**, Compatibility renderer. The editor and export-template archives are SHA-512 pinned in `toolchain.lock.json`. Git LFS is required for fonts and raster/binary media.

```sh
git lfs install
git lfs pull
python3 tools/bootstrap.py
tools/godot.sh
```

On Linux, set `BRACKENWARD_GODOT` to the executable printed by bootstrap. On other hosts, install the exact pinned Standard editor/templates and set that variable. Bootstrap currently supports macOS universal and Linux x86-64.

Begin opens a paused map. Tap a traveler, use Follow, drag to pan, or use the camera buttons. Build -> Paint area opens a preview. Drag/tap/nudge it, then Confirm. The designation stays pending until the next simulation tick. Pause / 1x / 2x / 4x control time. Menu offers verified local save/load and document import/export. Closing a panel leaves time paused. Backgrounding freezes time and cancels touches; returning stays paused.

Desktop shortcuts: WASD/arrows pan; Space toggles pause; 1/2/3 select speeds; B/J/P/V/L open Build/Work/People/Valley/Journal; Escape closes the top interaction, then opens Menu. Zoom uses the wheel or buttons. Rebinding and the remaining accessibility/audio settings are later work.

```sh
tools/godot.sh --headless --editor --import
python3 tools/validate_content.py
tools/godot.sh --headless --script tools/run_suite.gd -- --suite unit
tools/godot.sh --headless --script tools/run_suite.gd -- --suite integration
tools/godot.sh --script tools/run_suite.gd -- --suite ui
```

JUnit and native screenshots go in ignored `reports/` files. The UI suite resizes real Controls, injects touch events, and checks safe insets/text scales. It supplements physical testing. Acceptance IDs in test names refer only to the tested prototype subset, not the full release cases in the design.

Android development: JDK 17, SDK 36, build-tools 36.1.0, NDK 29.0.14206865, and CMake 3.10.2.4988404. Gradle 8.11.1 / AGP 8.6.1 / Kotlin 2.1.21 match the pinned template. Set `JAVA_HOME` and `ANDROID_HOME` if their default local paths differ, then run `tools/build_android.sh`. Bootstrap creates an isolated editor/settings directory for these builds, preserving the installed editor settings. Retain that directory to preserve the debug signing identity across APK updates. The original Kotlin v2 plugin uses Android's document picker, temporary content-URI grants, request IDs, byte limits and verified writes. It requests no broad storage permission. Generated AARs/APKs and Gradle files are ignored and reproducible from source.

Prototype saves live under Godot's private `user://m0`, keep three verified immutable generations, and recover an older valid generation if the newest is damaged. They are clearly separate from future campaign saves. M2's durable journal, campaign slots and migration matrix are not claimed by this checkpoint.

See [reports/STATUS.md](reports/STATUS.md) for actual gates and [reports/ANDROID_TEST.md](reports/ANDROID_TEST.md) for the phone task battery. No production signing key, public release, store publication, or telemetry is created.
