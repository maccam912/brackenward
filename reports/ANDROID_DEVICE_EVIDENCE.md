# User phone evidence and requested follow-up

The user supplied this exported report while playing 0.7.24-m7/content v4 on
14 October 2026. The complete transcribed export, including all 26 histograms
and 32 retained slow events, is [android-cph2655-0.7.24-user.json](android-cph2655-0.7.24-user.json).
Histogram sums were independently checked against each sample count. This is
user-provided evidence; the agent did not operate or reproduce the phone session.

Device: CPH2655, Adreno (TM) 830, Android OS build
36.V.R4T3.11539b9_104b3a5_fc6d39; Compatibility renderer, Balanced/30 fps,
1440×3168 viewport. The final metadata describes Meadow Reach seed 3062536897,
tick 21816, four residents, 58 structures, 45 positive stacks, 23 executable jobs,
no pending orders, writer idle, and engine static heap 106,194,866 bytes. Those
are final measurements, not proof that every histogram sample had that load.

| Callback | Speed | Samples | Mean ms | Maximum ms | Over 50 ms | p95 / p99 upper bound ms |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| Frame gap | Paused | 7,145 | 33.304 | 122.653 | 46 | 50 / 50 |
| Frame gap | 1× | 305 | 33.319 | 65.884 | 1 | 50 / 50 |
| Frame gap | 4× | 14,897 | 33.431 | 115.109 | 73 | 50 / 50 |
| Session | 4× | 14,897 | 6.540 | 86.419 | 68 | 16 / 25 |
| Simulation batch | 4× | 14,864 | 5.304 | 85.812 | 16 | 16 / 25 |
| Map update | 4× | 14,897 | 7.602 | 35.460 | 0 | 16 / 16 |
| Map draw commands | 4× | 14,897 | 2.522 | 16.320 | 0 | 4 / 8 |
| Save capture | 4× | 501 | 10.593 | 18.336 | 0 | 16 / 25 |
| Save finish | 4× | 14,897 | 0.020 | 5.884 | 0 | 4 / 4 |

Four backgrounds; zero slow-storage pauses, speed reductions or storage alerts.
At 4×, about 0.49% of measured frame gaps exceed 50 ms. The 30 fps cap explains
an ordinary frame gap near 33.3 ms; histogram upper bounds are not exact
percentiles. Nested callback timings overlap and must not be added. The report
supports occasional simulation/session spikes, with map CPU also material, but
contains no half-second measured gap in this sample. It does not disprove the
user's separately reported freezes, measure GPU/PSS/thermal/battery behavior, or
establish a causal fix. No save payload is included, so the exact live state
cannot be reconstructed from these counters alone.

The user also requested these concrete interaction changes, now prioritized:

- Confirmed placement/painting remains visibly marked immediately while paused;
  another preview can be confirmed without running a simulation tick.
- Confirm restores the exact entry speed; entry while paused remains paused.
- Campaign and named-snapshot deletion controls with a clear review step.
- A substantially wider maximum camera zoom-out.
- Residents independently sleep when tired, wake once rested, and recover rest
  gradually enough that an ordinary night's sleep does not finish around 21:00.
- Quiet periods with all residents asleep automatically run faster than 4×,
  ending as soon as someone wakes or something needs attention. Preserve the
  player's chosen speed and responsiveness; never skip simulation/alerts.

Placement feedback, multiple paused confirmations, exact entry-speed restoration
and wider zoom are implemented in 0.7.26. Campaign/named-snapshot deletion is
implemented and locally checked in 0.7.27. Independent sleep pacing and recovery rates are implemented and locally checked
in 0.7.28. Automatic 12x quiet-sleep playback, exact waking/event cutoff, retained
selected speed, an opt-out and CPU fallback are implemented and locally checked
in 0.7.29. Physical retesting remains distinct
from local automated checks.


## 0.7.62 emulator update and settings/migration subset

Android35 arm64 brackenward_m0,1080x2340 at440dpi, actual SwiftShader/ANGLE
Compatibility; local0.7.62/code101 debug APK. Update preserves all45 prior private
files before first launch. Original files are isolated for testing, then restored
exactly; task data is removed, rotation preferences restored and emulator stopped.
Actual taps/settings at100/125/150% and portrait/landscape are inspected. Reopening
graphics reproduces a Battery caption versus saved Smooth before the selection
setter fix; the fixed APK shows Smooth with identical preferences. Two native UI
regressions fail before and the expanded669 checks pass after. An untouched v6
campaign5 clone loads/saves paused at10734 with every gameplay field preserved
after only two content headers normalize; its original backup bytes remain exact.
See android-touch-v62-evidence.json for all file/APK/frame/manifest hashes. The
retained first-launch shader-cache recompilation warning is diagnostic; no script,
missing-message, parse or Android runtime crash is observed. This is separate from
physical CPH2655 performance, Android PSS/battery/thermal and the full human task
battery; the user's original0.7.24 report remains unchanged above.


## 0.7.63 emulator diagnostics bridge and export

The local code102 APK runs on the same Android35 arm64 emulator at1080x2340,
density440, SwiftShader/ANGLE. The first actual report retains null PSS because
Godot JNI singletons do not implement Object.has_method for plugin methods.
That failed APK/report is retained. The packaged Kotlin method was callable;
removing the unsupported guard yields247602176 bytes (236.132MiB), close to the
separate near-time `dumpsys meminfo` reading247307264 bytes. The explicit query
itself takes96312us on this emulator; no query runs on the gameplay frame path.
The report contains472 individually timed4x ticks, with exact histogram sums.
These are binding/unit/export checks, not phone performance measurements.
Frozen preview reuse is covered by the native UI suite. Actual export and original-file restoration are audited in
[android-diagnostics-v63-evidence.json](android-diagnostics-v63-evidence.json).
