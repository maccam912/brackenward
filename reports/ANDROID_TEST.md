# M0 physical phone task battery

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
