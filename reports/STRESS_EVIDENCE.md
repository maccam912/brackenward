# Synthetic crowded-colony measurements

These are development profiling results on macOS, separate from ordinary-play
campaign evidence and physical Android release requirements. The full release
stress gate, all-alert variant, thirty-minute soak, PSS/battery/thermal measurements
and low-tier/Mali phone matrix remain incomplete.

## Fixture and measurement contract

`tools/stress_fixture.gd` constructs an isolated synthetic object-load fixture using
actual campaign records, geometry and inventory ledgers. It never touches player
saves. Construction fails unless the resulting world passes invariants and an
exact canonical save-codec round trip. Its declared initial load is:

| Load | Count |
| --- | ---: |
| Residents | 20 |
| Domestic animals | 12 |
| Wildlife | 32 |
| Active hostiles | 6 |
| Stable neutral road visitors | 8 |
| Completed structures | 400 |
| Nonempty item stacks | 1,000 |
| Construction targets | 256 |
| Crop tiles | 192 |
| Chronicle entries | 1,000 |
| Weather | Rain |

The eight neutral visitors are downed members of two resolved road parties. Six
additional active threats deliberately exceed the normal shared arrival capacity
reservation; admission rules are unchanged. This fixture tests an upper load and
does not claim ordinary play can admit that combination. It also does not yet
exercise every UI alert. Its people, jobs and inventory continue through the real
simulation without runtime grants or replenishment; report ending counts, since
threats retreat and work completes. Do not describe these as thirty seconds with
all original actors still active.

The original schema-22/content-v2 initial canonical hash is
`d58ddba9cd57e6cbf36a25668e1de2f836645abe5bfc22d77454c8d21d706843`.
The retained local snapshot is 912,039 bytes with SHA-256
`427e716b0583ebf73da9e82d090167c9c5799d57bc1be419594ebed3662b3d68`.
Its header contains a creation timestamp; regenerating it can change byte hashes
while the canonical hash remains identical. Generated raw reports/snapshots/logs
are ignored; the editable generator and acceptance checks are committed.

The foreground profiler uses actual GameSession, rendering, saving and audio
callbacks, with isolated preferences/saves and Dummy audio. Optional instrumented
ticks retain the ordinary simulator's canonical state. One second of paused
render warmup precedes measurement. Duration uses monotonic wall time, avoiding
engine-timer delta clamping after a slow callback. The report separately records
processed engine delta, ticks, requested/final speed and outstanding logical time.
It checks unchanged source/media/profiling fingerprints before and after each run.
CPU measurements exclude GPU/audio-thread costs and do not certify physical phone
frame rate, memory or thermals. Nested phase totals overlap.

Reproduce locally after importing the project:

```sh
python3 tools/checked_godot.py -- --headless --script tools/create_stress_snapshot.gd -- --snapshot reports/stress.brackenward
python3 tools/checked_godot.py -- --audio-driver Dummy --script tools/profile_foreground.gd -- --snapshot reports/stress.brackenward --seconds 30 --speed 4 --camera far --trace-spikes true --report reports/stress-far-4x.json
```

Quality defaults to Balanced (30 FPS); `--quality Smooth` measures the 60 FPS
preset. A 1,800-second run requires the guard's explicit `--timeout 2100` option.
Use one native graphical run at a time and avoid concurrent heavy work when
comparing timings.

## 0.7.6 local optimization checkpoint

The first twelve-second engine-timer run exposed raid goods selection taking up
to 10.18 seconds per phase. That search repeatedly inspected all 400 structures
for every explored map neighbor. Packed walkability/distance masks and cached door
footprints retain the exact former target order. Completing the nearest layer
containing the best possible preference rank permits safe early exit; unreachable
preferred goods still require exhausting the reachable component.

The same fixture exposed repeated sorting/scoring and food-input searches during
the first large assignment pass. Scheduling now precomputes the unchanged score
and consumes it through a disposable heap. Failed hauling probes share storage
occupancy only within their current consecutive search; real reservations end the
search. Small food/material requests select only the needed prefix of the former
expiry/distance/item/ID order. Large requests keep full sorting. The optimization
does not discard jobs/history, alter priorities or change material transactions.

Sixteen direct comparisons with the prior dictionary flood fill pass on legacy
and all three generated sites, with open/closed gates and an enclosed unreachable
preferred good. Queue order, partial-input order, actual hauling reservations,
carried capacity and cancellation have separate regressions. Frozen replay and
foreign-save continuation retain their original hashes.

Final isolated runs use Apple M5 Pro / macOS 26.6.2 / OpenGL 4.1, 960x600,
Balanced/30 FPS, version `0.7.6-m7`. Runtime/media/profiling source fingerprint
`1a96d67439b56ae3bcc1a2f2e4667014886d09217daab17dad9f4a2cbd1270da`
is identical before and after all four runs. The earlier close/1x run overlapped
the end of the headless suite; its original report is retained and was replaced
for this table by an isolated run.

| View / speed | Wall seconds | Logical ticks | Main p95 / max ms | Main callbacks >50 ms | Tick p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Close / 1x | 30.037 | 300 | 13.640 / 138.587 | 9 | 35.348 |
| Close / 4x | 30.018 | 1,200 | 43.471 / 135.258 | 14 | 36.334 |
| Far / 1x | 30.007 | 299 | 13.982 / 141.142 | 7 | 35.135 |
| Far / 4x | 30.032 | 1,200 | 44.990 / 140.290 | 22 | 37.167 |

Final speeds stay requested; remaining logical time is under 0.1 second in every
run, with no speed reduction, storage pause/error or invariant failure. Main
callback timings are not frame timings. Wall-clock frame gaps reach 148.672,
144.708, 154.651 and 154.159 ms respectively, with 12, 67, 11 and 80 gaps above
50 ms. These remain failures to address, and tick p95 misses the 4 ms requirement.
No platform performance gate passes from these measurements.

Every end state retains twenty residents, twelve domestic animals, thirty-two
wildlife, eight neutral visitors, 192 crop tiles and rain. Active threats have
retreated by the end. Close/far 1x ends with 400 structures, 1,035 nonempty stacks
and 268 construction/production targets; 4x ends with 401 structures, 1,061 stacks
and 267 targets. The simulation also creates too many executable automatic jobs;
the independent 512-job requirement remains unfinished.

A separate 65.033-second new-colony warm run advances 650 ticks: main callback
max 3.283 ms, none over 50 ms; tick p95 0.767 ms, max 3.183 ms. Map update max
0.965 ms and custom drawing max 0.300 ms; audio max 0.048 ms. Save capture max
2.145 ms, preparation capture 0.679 ms and completion 0.729 ms. No storage pause,
error or invariant failure. Its extra paused warmup moves initial room/render
preparation outside measurement, so its maximum is not a direct comparison with
older profiles that included those first callbacks. Physical new-colony Android
stutter still needs actual phone evidence.

## 0.7.7 bounded-work checkpoint

Schema 23/content v3 retains all order targets and limits executable work to 512;
the Work sheet pages thirty-two controls at a time. This closes the independent
job-count contract, while timing remains a failing gate. Admission and static
movement-cost caches have exact uncached/reference regressions. No history or
material record is discarded to improve timing.

The v3 fixture has the same declared object load, canonical hash
`6f87e9c02248e6ccdd4753a3c46c0d1a14e42c71676275e0e7ed1fc067357610`,
917,415 bytes and SHA-256
`5ec03da3bd7ed46cd7ba32042699643e43827920e4d505b24d4030db9303fd5c`.
The final runs use `--center 68,72` to include the busiest pile area, rather than
the former default 68,63; these render timings are not direct camera-matched
comparisons with 0.7.6. Host, viewport and Balanced/30 FPS are unchanged.
Runtime/media/profiling source fingerprint
`e749114e7bbf87f1165b3cd0e5d925b5d87fe19057c3bb75e652e920fced75ff`
matches before and after all four runs.

| View / speed | Wall seconds | Logical ticks | Main p95 / max ms | Main callbacks >50 ms | Tick p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Close / 1x | 30.045 | 300 | 19.432 / 137.686 | 13 | 44.081 |
| Close / 4x | 30.001 | 1,199 | 50.354 / 139.563 | 46 | 40.043 |
| Far / 1x | 30.004 | 299 | 19.751 / 140.530 | 14 | 44.021 |
| Far / 4x | 30.003 | 1,199 | 51.444 / 147.494 | 45 | 39.864 |

Wall-clock frame gaps reach 149.593, 150.499, 151.064 and 157.891 ms respectively,
with 17, 97, 17 and 96 gaps over 50 ms. Requested speeds remain unchanged, logical
backlog remains below 0.1 second, and no storage pause/error or invariant failure
occurs. Every end state retains twenty residents, twelve domestic animals,
thirty-two wildlife, eight neutral visitors, 192 crop tiles and rain. Threats
retreat. Both 1x runs end with 400 structures, 1,035 stacks and 268 active targets;
both 4x runs end with 401 structures, 1,059 stacks and 267 targets. These are
changing real simulation loads, not sustained constant peak load.

The separate new-colony run measures 65.033 seconds and 650 ticks: main callback
p95 0.859 / max 3.311 ms, tick p95 0.805 / max 3.212 ms, frame-gap max 35.310 ms
with none over 50 ms. Save capture max 2.181 ms, preparation capture 0.677 ms and
completion 0.719 ms. Its tutorial is dismissed; active guidance needs its own
measurement. Physical Android stutter, the 4 ms stress tick target and all full
release performance gates remain open.
