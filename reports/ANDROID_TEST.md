# Current Android regression and performance task battery

The user has installed a phone build and reported placement/camera defects and
periodic freezes even in a new colony. The fixes and local/native/CI evidence are
tracked in STATUS.md. A user-supplied CPH2655/Adreno 830 report from 0.7.24 is
retained in [ANDROID_DEVICE_EVIDENCE.md](ANDROID_DEVICE_EVIDENCE.md); the full
physical regression battery is **Not run**. A model,
OS/GPU, APK version/checksum and orientation are required to attach a result to a
specific device/build. No desktop result certifies this battery.

Use the debug APK and matching `build.json`/`SHA256SUMS.txt` from one checked
per-commit development release. Install over the existing application with its
stable debug identity and confirm the prior colony/save slots remain selectable.
The ignored local APK can predate source; identify the tested build in Menu.

1. In a new colony, pan/zoom to a chosen tile. Open Build, select Door and tap once
   away from its initial preview. Exactly one cell previews there; Confirm queues
   one cell. Repeat for a one-cell wall and floor, then a drag with each. A new tap
   replaces the prior stroke. Repeat in portrait and landscape with one-cell nudge
   controls, and confirm twice rapidly to check one transaction.
2. Pan and zoom away from the cart before starting a field, stockpile, wall,
   resource rectangle or lodge. Starting the tool preserves that camera and zoom;
   it begins at the current view. Repeat with a resident previously followed,
   pinned food guidance visible, 150% text, rotation and the sheet Close action.
3. For the reported freezes, open Menu > Performance report > Reset measurements,
   close the panels and play a **new colony** at 1x through several stalls. Open
   the report and choose Export this report; the picker writes the exact preview
   as `brackenward-performance.json`. Retain the file before resetting or changing
   campaign. Repeat at 4x and with the real colony that showed the problem.
4. Record quality, camera/zoom, approximate wall time, storage free space and
   whether the stall coincides with a visible warning, save, new order or rotating
   the phone. The report includes build/device/OS/GPU, seed/tick/object counts,
   per-speed CPU/frame-gap histogram bounds and the latest slow callbacks. It
   contains no resident names or save payload. Inspect before exporting; no
   automatic upload occurs. CPU callbacks and wall gaps do not measure GPU time,
   Android PSS, battery or thermal throttling.
5. Separately execute the declared crowded close/far 1x/4x profiles and thirty-
   minute 2x task from DESIGN.md, recording Android PSS, frame timing, thermal
   behavior and same-brightness battery measurements. Keep actual population and
   changing loads in the report; a declining-load development soak is a different
   scope. A return to baseline after a worker-allocation peak must be distinguished
   from sustained memory growth. Retain failed/partial outcomes.
6. Verify Home/lock/return freezes logical time and returns paused; rotate an
   unconfirmed one-cell/area preview without moving it or submitting it. Export,
   cancel and reimport a verified campaign through the document picker. Force-
   stop/recover and stable-identity update checks remain required independently.

Mark each case Pass / Fail / Not run with exact reproduction, version and saved
logical ticks. Physical readability, audio focus, gestures, storage, performance,
memory/battery/thermal and the supported phone matrix remain separate gates.
The historical M0 instructions below describe the retained prototype only.

# Historical M0 physical phone task battery

Status: **Not run**, deferred by the user. Install `build/brackenward-debug.apk` (application ID `dev.brackenward.game`) on an Android 10+ arm64 phone. This is a debug prototype, not a release campaign build. Keep debug signing identity consistent for upgrade checks; no production key is part of the repository.

Record phone model / OS / GPU / display density, source commit, engine 4.7.2, APK SHA-256, orientation, text scale and tap errors. Record initial PSS/frame times and battery drain on the same brightness and device for later comparisons. A desktop touch trace or Android emulator cannot mark these physical gates Pass.

1. Begin. Verify paused Spring 1 06:00, four travelers, visible Pause and five navigation entries.
2. Tap Mira, choose Follow, then 1x. Confirm visible one-tile-per-second placeholder movement. Pause.
3. Pan with one finger, zoom with pinch, and repeat using only zoom/camera buttons. A drag, second finger, or long press must never submit an area.
4. Build -> Paint area. Tap/drag an 8-tile rectangle, adjust with nudge buttons, switch Pan mode, then Confirm. Tap Confirm twice quickly: exactly one pending action. Resume: one accepted area. No colony resources are implied or spent in this prototype.
5. Begin another preview; rotate the device twice. Preserve the unconfirmed area, remain paused, and confirm only when explicitly tapped. Repeat while a panel is open and at 125% and 150% text. Navigation and Close/Pause must remain usable inside safe insets.
6. Menu -> Save. Confirm a verified saved tick. Export using Android's document picker, then Import the same file. Check traveler movement progress and accepted area survive. Cancel both pickers separately and confirm saves are unchanged.
7. While moving at 4x, press Home, lock/unlock, and return after at least a minute. The saved tick must not advance while absent; no held finger completes an action; return is paused with the away message.
8. Use Android Back during preview, inspector, sheet, and ordinary map. Cancel only the current uncommitted interaction / close the top panel, then show Menu; never quit unexpectedly.
9. Force-stop and restart; Load prototype recovers a verified generation. Install an updated APK with the same debug identity and verify private saves remain available. This M0 save service does not claim M2's two-second durable journal window.

Mark each case Pass / Fail / Not run, with the relevant saved tick, screenshot or exact reproduction steps. Do not mark the full M0 exit gate Pass until the physical installation, touch, lifecycle, picker and baseline measurements are complete.
