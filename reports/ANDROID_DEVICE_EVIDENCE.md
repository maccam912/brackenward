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

These entries record intent, not completed implementation. Each subsequent
checkpoint must replace its own pending statement with actual behavior and
validation. Physical retesting remains distinct from local automated checks.
