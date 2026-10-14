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

## 0.7.9 search-local positions and admission work

A matched close/4x pair uses the same v3 snapshot, 960x600 Balanced preset and
camera center 68,72. Both runs overlap the same three-worker frozen Winter matrix;
these are provisional comparisons under competing CPU work, not isolated release
measurements. Baseline is frozen `fe118288c17efc56a252318d042c4bc1af1c2ac6` with
source fingerprint `e749114e7bbf87f1165b3cd0e5d925b5d87fe19057c3bb75e652e920fced75ff`;
final source fingerprint is
`a43cfd294951943300f196e65cae4b8d5af2d70c6a5d3772c83f72cc0e8fa9aa`.
Each fingerprint matches before/after its run. The final profiler additionally
clears warmup phase traces and reports post-measurement save draining separately.

| Metric | Frozen baseline | Final 0.7.9 candidate |
| --- | ---: | ---: |
| Measured wall seconds | 30.024 | 30.008 |
| Logical ticks | 1,199 | 1,199 |
| Tick p50 / p95 / max ms | 8.975 / 37.782 / 165.668 | 7.320 / 35.790 / 151.979 |
| Main callback p95 / max ms | 55.241 / 166.584 | 44.640 / 152.960 |
| Main callbacks >50 ms | 49 | 29 |
| Hauling reservation phase peak ms | 49.280 | 4.436 |
| Admission phase peak ms | 41.201 | 17.285 |
| Frame-gap max ms | 179.163 | 164.276 |
| Frame gaps >50 ms | 104 | 86 |

The two end-load counts match: twenty residents, twelve domestic animals,
thirty-two wildlife, eight neutral visitors, no remaining active threats, 401
structures, 1,059 nonempty stacks, 267 active targets, 192 crops, 1,041 Chronicle
entries and rain. Both retain requested 4x speed and under 0.1 second backlog,
with clean invariants/storage. The final diagnostics count 491 executable tasks,
655 queued orders and 1,366 total unfinished records; the remainder waits on
future retries. The 4 ms tick budget and frame requirements still fail.

The final source uses one search-local owned-work-position map for consecutive
failed unowned hauling probes, precomputed admission sort keys and no redundant
start-of-tick admission on unchanged ticks. The full former three-pass schedule
and explicit tuple comparator match all canonical fields at each of 300 crowded
ticks in an extended local comparison; the regular suite retains 120 ticks to
fit CI's timeout. Frozen ordinary-play replay and schema-22 gameplay hashes also
match. These checks constrain behavioral changes but do not replace device tests.

## 0.7.11 typed admission and perishable/heating work

The fixed-tick benchmark preserves its full final hash after typed/preallocated
admission and a separate perishable inventory view. Average instrumented admission
cost changes from 2.610 to 2.267 ms per tick; living/aging changes from 0.973 to
0.557 ms. Uninstrumented 1,200-tick totals are 13.096 and 12.231 seconds. The former
heating loop remains a test reference, including cold weather and same-room warmth.
An actual snowy Winter save also matches frozen source after 1,200 more ticks;
full hashes/provenance are recorded in STATUS.md.

The final native rows retain the v3 fixture and camera center 68,72, Balanced/30
FPS, 960x600, with three frozen Winter workers running concurrently. Source
fingerprint `c4b27906ac2ff0ebcc231ad15d904e427c9e745e46daf18f12fb047ce3826607`
matches before/after every run. These remain provisional CPU measurements.

| View / speed | Wall seconds | Logical ticks | Main p95 / max ms | Main callbacks >50 ms | Tick p50 / p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Close / 1x | 30.023 | 299 | 14.432 / 154.660 | 12 | 6.787 / 46.874 |
| Close / 4x | 30.009 | 1,199 | 45.818 / 154.812 | 31 | 6.651 / 35.190 |
| Far / 1x | 30.020 | 299 | 14.096 / 150.050 | 13 | 6.759 / 44.533 |
| Far / 4x | 30.009 | 1,199 | 44.278 / 150.590 | 32 | 6.581 / 35.335 |

Max frame gaps are 171.772, 170.941, 166.035 and 164.782 ms respectively, with
20, 76, 20 and 72 gaps over 50 ms. Every run retains its requested speed and under
0.1 second logical backlog, with clean invariants/storage. The end loads match
the corresponding 0.7.7 1x/4x rows: active threats retreat, 1x ends with 400
structures/1,035 stacks/268 targets, 4x with 401/1,059/267; the other actor/crop
counts and rain remain. The tick and frame requirements still fail, and these
runs do not satisfy any physical performance gate.


## 0.7.12 admission invalidation and deadlines

The source fingerprint `073da11c0b57c45f5d3198eb3a043d1b25df19a17a02b756b7e3e87283205647`
remains unchanged across all four thirty-second native runs. The v3 fixture,
camera center 68,72, Balanced/30 FPS and 960x600 remain as above. Two frozen Winter
workers were observed immediately before and after each run; that is not a
continuous concurrency sample or an isolated device benchmark.

| View / speed | Wall seconds | Logical ticks | Main p95 / max ms | Main callbacks >50 ms | Tick p50 / p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Close / 1x | 30.024 | 299 | 12.725 / 150.204 | 12 | 5.167 / 44.697 |
| Close / 4x | 30.017 | 1,199 | 41.788 / 143.520 | 23 | 5.168 / 36.478 |
| Far / 1x | 30.025 | 299 | 13.130 / 155.026 | 12 | 5.293 / 40.076 |
| Far / 4x | 30.010 | 1,199 | 42.843 / 142.592 | 23 | 5.107 / 35.712 |

All retain requested speed, under 0.1 second logical backlog and clean
invariants/storage. Ending actor/crop/weather and load counts match the preceding
corresponding 1x/4x rows. Tick maxima are 149.190, 142.224, 153.977 and 141.808 ms.
The 4 ms tick and frame requirements still fail.

A separate fixed 1,200-tick final benchmark retains full canonical hash
`b9cfe7a9c9e5469082a9aec02f0a075b7e165581c1b8f5a4cecaa1d22d5cc771`,
also matching its instrumented twin. Uninstrumented/instrumented totals are
8.782/8.903 seconds. Inclusive admission is 0.787 ms per tick, work 1.839 ms,
assignment 1.540 ms and work creation 0.915 ms. The remaining Winter workers
completed around this interval; differences from older benchmarks cannot be
attributed solely to the optimization. The exact replay/oracle and cold-save
continuation comparisons establish behavior preservation, not phone performance.


## 0.7.13 owned-job reservation view and single hunt lookup

Four native thirty-second rows use the same v3 fixture, 960x600, Balanced/30 FPS,
camera center 68,72. Runtime/media/profiler fingerprint
`899bb9826fd05b3c2c1d924611be9d0d347ca6b3ebb288ac309aadc26883997d`
stays unchanged. No other Godot process was observed before or after any row;
the Winter sweep had finished. Other host activity is not controlled. Older rows
with competing Winter workers are not matched timing comparisons.

| View / speed | Wall seconds | Logical ticks | Main p95 / max ms | Main callbacks >50 ms | Tick p50 / p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Close / 1x | 30.022 | 300 | 11.679 / 120.329 | 11 | 2.693 / 36.357 |
| Close / 4x | 30.016 | 1,200 | 42.384 / 132.219 | 20 | 2.584 / 37.499 |
| Far / 1x | 30.017 | 300 | 9.257 / 119.570 | 9 | 2.657 / 35.103 |
| Far / 4x | 30.035 | 1,200 | 38.600 / 111.550 | 14 | 2.454 / 32.140 |

Frame-gap maxima are 131.792, 140.161, 127.833 and 124.448 ms, with 13, 48,
11 and 31 gaps over 50 ms respectively. Tick maxima are 119.047, 131.455, 118.694
and 110.822 ms. Requested speeds are retained, backlog stays below 0.05 seconds,
and all storage/invariant checks are clean. End loads match the prior corresponding
1x/4x rows. Typical ticks are cheaper, but the p95 4 ms and frame requirements
still fail. The close-1x trace records an inclusive assignment peak of 79.011 ms
and cooking reservation peak of 39.923 ms.

A separate unopposed fixed 1,200-tick run finishes in 7.091 seconds; its instrumented
twin takes 7.163 seconds and retains the same full canonical hash as earlier runs.
Inclusive assignment is 1.257 ms/tick, work creation 0.903 ms, admission 0.786 ms
and work 0.749 ms. These are host CPU diagnostics, separate from Android/GPU,
memory, thermal and thirty-minute soak certification.


The same final source's twenty-second fresh-colony lodge-lesson run has 200
logical ticks: median 0.587 / p95 0.818 ms, session max 4.480 ms, guidance
median 2.403 / max 2.810 ms and maximum frame gap 35.325 ms, with no >50 ms
callbacks/gaps. Invariants/storage are clean and source fingerprint is unchanged.
This checks the reported early-colony path on the host; phone behavior remains
unmeasured.


## 0.7.14 precomputed ingredient keys

`tools/profile_inputs.gd` compares the former explicit expiry/distance/item/ID
selector with precomputed native keys on the same 1,000 positive stacks. It
alternates execution order, discards five warmups and times eighty calls per
selector/request size. Exact selections and all canonical fields match.

| Requested units | Former total ms | Current total ms |
| ---: | ---: | ---: |
| 1 | 158.727 | 63.888 |
| 4 | 155.574 | 62.954 |
| 16 | 316.156 | 76.040 |
| 40 | 1,117.561 | 223.139 |

This is a paired selector CPU diagnosis, not a full-game speedup or phone result.
The fixed 1,200-tick stress continuation also retains the full previous canonical
hash and matches its instrumented counterpart. Its 7.986/8.048-second totals
overlap campaign and validation processes and are not isolated comparisons.

Four final native thirty-second runs retain runtime/media/profiler fingerprint
`76c5e9f60cbd2c49f9cb3ecf8cd1eb62f903995f3edb5bbaf3f19fd66b0bf59e`.
The v3 fixture, 960x600, Balanced/30 FPS and center 68,72 remain unchanged.
Two frozen Charter workers are observed at every start/end; concurrency is not
sampled continuously. The preceding unopposed rows are not matched comparisons.

| View / speed | Wall seconds | Logical ticks | Main p95 / max ms | Main callbacks >50 ms | Tick p50 / p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Close / 1x | 30.038 | 300 | 11.119 / 133.109 | 12 | 2.899 / 38.578 |
| Close / 4x | 30.041 | 1,201 | 40.296 / 132.268 | 20 | 2.730 / 35.603 |
| Far / 1x | 30.031 | 300 | 10.664 / 140.105 | 11 | 2.968 / 44.282 |
| Far / 4x | 30.018 | 1,200 | 42.212 / 142.268 | 23 | 2.798 / 35.036 |

Maximum frame gaps are 141.813, 144.666, 153.259 and 151.315 ms, with 14, 47,
16 and 50 over 50 ms respectively. Tick maxima are 132.175, 131.355, 139.110 and
141.292 ms. All retain requested speed, less than 0.04 seconds backlog, clean
invariants/storage and the corresponding prior 1x/4x end loads. The tick and frame
gates still fail. Further work must address scheduling peaks; this checkpoint
does not claim the isolated selector gain fixes whole-game stalls.


## 0.7.15 food-shortage interruption / content v4

The controlled hungry-cook case makes no meals, records 903 jobs and ends at
health 36/rest 0 under v3. The same starting snapshot continued under corrected
v4 rules makes eight real meals, eats, ends at health 100/rest 1000 and records
43 jobs. Its original acknowledged state is preserved during loading. This is a
controlled regression with explicit extra grain, not an ordinary balance run.

The 1,200-tick crowded continuation under v4 has canonical hash
`46cc90218fa6bbf435dfed45acec80cfb6a80e2357600dd392b06e9284e5f919`;
restoring only its original v3 header yields the exact earlier
`b9cfe7a9c9e5469082a9aec02f0a075b7e165581c1b8f5a4cecaa1d22d5cc771`.
Its instrumented twin matches. The actual snowy save likewise matches frozen
continuation under its original header, with full current v4 hash
`3169d6dd685eaa1fe7d8271849d88bec8292709ca366ae613de637adeb02c598`.
Profiler clones now explicitly reset derived indexes after copying state. Header
normalization is reported unavailable instead of hashing an empty representation
when older schemas cannot represent actual capacity deferral.

Four final thirty-second native profiles use the same v3 input fixture, loaded
through current migration, 960x600, Balanced/30 FPS and center 68,72. Scoped
runtime/media/profiler fingerprint
`5e313a313355041ce806d16997695ba9b3667ff5beb684488608074e9b4fe049`
remains unchanged. Two Charter workers are observed at each start/end; concurrency
is not sampled continuously and these are not isolated hardware measurements.

| View / speed | Wall seconds | Logical ticks | Main p95 / max ms | Main callbacks >50 ms | Tick p50 / p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Close / 1x | 30.025 | 300 | 11.394 / 135.960 | 12 | 2.988 / 46.005 |
| Close / 4x | 30.033 | 1,200 | 40.261 / 127.447 | 26 | 2.790 / 35.838 |
| Far / 1x | 30.034 | 300 | 10.572 / 143.163 | 11 | 2.988 / 43.674 |
| Far / 4x | 30.038 | 1,200 | 40.306 / 134.548 | 18 | 2.840 / 34.016 |

Frame-gap maxima are 149.206, 140.239, 152.056 and 144.556 ms, with 20, 39,
21 and 40 over 50 ms respectively. Tick maxima are 134.896, 126.690, 142.196
and 133.558 ms. All preserve requested speed, sub-0.1-second backlog and clean
invariants/storage. End loads match the preceding corresponding 1x/4x rows.
The tick and frame requirements still fail. The food fix prevents a real shortage
livelock; it does not by itself meet the crowded-colony performance budget.


## 0.7.16 late-history inventory reads

The scheduler borrows the existing live stack view during trusted ticks for
quantity/reservation/food reads. History remains authoritative for metadata writes;
no depleted records are removed from saves. A controlled 8,000-record cooking test
matches a full-history reader for 1,200 ticks, including delivery metadata on every
zero-count record. The frozen replay, snowy and crowded canonical continuations
remain exact.

The Day 86 partial from the corrected 977313e Pine run contains 10,183 stacks and
13,228 jobs at tick 612,000. A v4-loaded daytime continuation reaches tick 614,400
with eight residents, 104 structures, 124 crop tiles, 10,209 stack records (590
positive) and 13,260 jobs. It is a derived profiling fixture, not a 96-day pass.
Raw SHA-256: `a4306a225e39ab1701275a7815b6ad8ac57031679fd989e4ca1ac9bfe3cabd99`.
The 1,200-tick result has the exact frozen eabef3b canonical hash
`38c3c1ff65e2bfd52b6a79e5c0d3ff1b2416ffafd36720add35e71d100654506`.
Observed baseline/current uninstrumented CPU time is 10.410/6.151 seconds;
instrumented work is 4.326/0.650 seconds. One old campaign worker overlaps each
short run; this is not an isolated or phone benchmark.

The following thirty-second native source measurements use 960x600, Balanced,
close view centered at 68,63, active saves and Dummy audio. The late rows use that
snapshot; fresh rows use an ordinary generated four-resident colony with the lodge
guide active. Scope fingerprint is
`22c714886e42c33f095c1fc9acd7a110854e20208711fe64ceb4733a991fca72`
(293 runtime/media/profiler files), unchanged for every row. Four background
campaign workers are present at each endpoint; replay and export/profile work also
overlap part of the late rows. These are explicitly contended development timings.

| Case | Wall seconds | Ticks | Main p95 / max ms | Main >50 ms | Tick p50 / p95 / max ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Late / 1x | 30.007 | 299 | 19.611 / 188.775 | 10 | 2.496 / 27.475 / 187.852 |
| Late / 4x | 30.008 | 1,199 | 42.292 / 148.219 | 28 | 2.499 / 30.472 / 147.557 |
| Fresh lodge / 1x | 30.033 | 300 | 0.989 / 5.317 | 0 | 0.613 / 0.854 / 3.403 |
| Fresh lodge / 4x | 30.032 | 1,201 | 1.393 / 5.451 | 0 | 0.600 / 0.817 / 3.309 |

Requested speed, clean invariants/storage and backlog below 0.1 second hold in
all rows. Late 1x ends with 588 positive stacks / one target; late 4x has 602 / zero.
All other late actor/structure/crop counts remain as above. The fresh cases retain
four residents, ten structures, seven positive stacks and sixteen wildlife, with
no active target, crop, domestic animal, visitor or hostile. Fresh guidance is
smooth on this host; late-game and crowded tick budgets still fail. Android,
all-alert stress, thirty-minute soak and hardware memory/thermal gates remain open.


## 0.7.17 complete ID maps for retained history

Job and stack lookup uses complete derived ID maps within trusted ticks. The map
scans only appended records, answers absent IDs immediately and retains original
dictionary references. It resets on import/generation, source-array replacement
or shrink. Fields, stores, other small tables and direct calls retain their original
lazy/full-scan behavior. No saved field, selection order, ledger or content rule
changes. History is never removed. The extra maps cost memory proportional to
retained job/stack IDs; they are not a hardware memory certification.

An initial attempt applied complete maps to five tables. It preserved state but
slowed the cold fixture in every alternating pair, so that broader path is not
shipped. Final code limits maps to the two large histories and avoids empty range
allocation/cache-map writes on repeated reads. `tools/profile_history.gd` retains
the original 44fffb9 positive-only lazy lookup, alternates execution order over four
pairs, compares complete final hashes/invariants and records snapshot hashes.
Every measured continuation is 1,200 ticks; timing excludes clone creation and
post-run hashes/invariants. Three frozen Winter workers overlap these runs;
scheduler checks also overlap the fresh/cold cases. They remain contended local
CPU observations, not isolated, foreground-frame or physical-device measurements.

| Fixture | Original median seconds | Current median seconds | State equality |
| --- | ---: | ---: | --- |
| Fresh Meadow Reach / seed 104729 | 0.431493 | 0.430595 | All eight worlds exact |
| Actual snowy checkpoint | 2.854603 | 2.865872 | All eight worlds exact |
| Day 86 daytime continuation | 7.021411 | 6.684699 | All eight worlds exact |
| Synthetic crowded | 8.656637 | 8.744747 | All eight worlds exact |

The late continuation improves about 5%; the other fixtures show no useful speedup.
These results do not establish lower frame-time tails. Full current canonical
hashes remain `3169d6dd685eaa1fe7d8271849d88bec8292709ca366ae613de637adeb02c598`
(cold), `38c3c1ff65e2bfd52b6a79e5c0d3ff1b2416ffafd36720add35e71d100654506`
(late) and `46cc90218fa6bbf435dfed45acec80cfb6a80e2357600dd392b06e9284e5f919`
(crowded). Runtime-canonical and conservation checks pass; the crowded-colony,
Android, all-alert and long-soak gates remain open.


## 0.7.18 localization cost check

Two thirty-second native fresh Meadow Reach/104729 profiles keep the lodge guide
active, real foreground saves, close camera at 68,63, 960x600, Balanced and Dummy
audio. Runtime/media/profiler fingerprint
`d69d0a461d4a586d3bf6a47b8e001581c453b6621215880256ab7671ee9fc3b4`
(296 files) is unchanged. Background Winter workers overlap both; tutorial/export
validation also overlaps part of the measurements. These are contended CPU source
measurements and establish no phone, GPU, PSS or thermal result.

| Speed | Wall seconds | Ticks | Main p95 / max ms | Tick p95 / max ms | Guide refresh p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1x | 30.033 | 300 | 0.990 / 4.476 | 0.856 / 3.334 | 2.689 |
| 4x | 30.000 | 1,200 | 1.350 / 5.244 | 0.805 / 3.135 | 2.527 |

No measured main/tick callback exceeds 50 ms. Requested speed is maintained,
backlogs are 0.033369/0.004765 seconds and storage/invariants remain clean. Both
retain four residents, ten structures, seven positive stacks and sixteen wildlife;
no active targets, crops, domestic animals, hostiles, visitors or Chronicle entries
are present. The formatter/catalog have no observed fresh-guide timing regression
on this host. Crowded, late-campaign and physical Android gates remain open.


## 0.7.19 reciprocal ownership and hidden preview work

`tools/profile_history.gd -- SNAPSHOT 1200 reservation` retains the exact 2f1a8fb
reservation/filter and dictionary-reference lookup path. Four alternating pairs
compare it with current reciprocal ownership enumeration and ID-to-row offsets.
Every complete result hash and invariant set matches. Median original/current CPU
seconds are fresh 0.393062/0.400365, cold 2.858674/2.807195, late
6.782724/5.926181 and crowded 8.952732/8.965696. The late case improves about
13%; the others show little change. Three frozen Winter workers overlap these
contended development measurements. The existing three snapshot hashes remain
exact; no new resource grants, save fields, content rule or order changes occur.

The foreground harness adds an explicit canceled-floor setup: begin a real floor
preview at 50,48 through 65,63 (256 cells), compute it, then cancel. It refuses
setup if any command was submitted or the placement controls remain visible.
Measure 30 seconds at each speed, 960x600, Balanced, Dummy audio, close camera
center 68,63. Before/after code shares the final simulation optimization and the
same profiler; only GameSession's hidden-preview guard and project version differ
within the 296-file scoped source manifests. The saved pre-fix GameSession bytes
and both per-file manifests remain in ignored reports. All traces reset derived
record/job/stack/navigation/room state after cloning.

Before fingerprint:
`e7ba7d0f3b7718be230453ada549de6314e5698e4da3885a636edcc1607a51bc`.
After fingerprint:
`b4240276e5896dc1553c16bc19d36e288055b51aa622b810449679e43e41a05e`.
Each remains unchanged during both of its rows. Three frozen Winter workers are
present at each endpoint; concurrency is not sampled continuously. No other GUI
profile runs simultaneously. Timing is foreground CPU work, not GPU/phone timing.

| Case | Wall seconds | Ticks | Main CPU p95 / max ms | Preview calls / p95 ms | Tick p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before / 1x | 30.033 | 300 | 8.813 / 11.891 | 901 / 7.850 | 0.841 |
| Before / 4x | 30.032 | 1,201 | 9.743 / 13.718 | 901 / 8.713 | 0.808 |
| After / 1x | 30.000 | 299 | 0.906 / 3.102 | 0 / no samples | 0.843 |
| After / 4x | 30.033 | 1,201 | 1.309 / 3.767 | 0 / no samples | 0.804 |

Every row keeps its requested speed, clean storage/invariants and backlog below
0.1 second (after 1x ends at 0.099337 seconds, within one pending logical tick).
No main/tick callback exceeds 50 ms. All initial/final loads remain four residents,
ten structures, seven positive stacks, sixteen wildlife and clear weather; no
targets, crops, domestic animals, hostiles, visitors or Chronicle entries are present.
The controls remain hidden throughout measurement. UI regression tests separately
prove visible previews still refresh and confirmation submits/executes real work.
The broad crowded/late/Android, all-alert and thirty-minute-soak gates remain open.

The earlier 0.7.16 and 0.7.18 camera-center descriptions above were corrected to
68,63 from their actual recorded camera_center fields; their measured values and
scope fingerprints are unchanged.


## 0.7.20 creation-read bounds

Equipment pending/stock reads and construction-helper parent discovery use private
borrowed views during ticks. Predicates still test actual state/count, direct
calls retain full history, and public query lists remain caller-owned. Independent
04500fb creation functions compare against real shared-material work with 8,000
terminal jobs/8,000 depleted rows, same-tick stock changes and queued proposals.
The first malformed fixture was rejected; final accepted fixtures pass all seven
new checks. The scheduler has 293 passing checks and canonical continuations remain
unchanged.

Four alternating microbenchmark pairs make 200 creation calls at one unchanged
tick, including first derived-view setup, without intervening simulation work.
These are creation-operation timings, not tick/frame or survival evidence.
Median original/current milliseconds are fresh 2.761/3.071, snowy
461.737/48.018, late 2,049.268/85.531 and crowded 123.690/123.255. Every
final hash/invariant matches; background Winter/test work overlaps these runs.
The actual 1,200-tick late continuation separately matches the frozen result and
its instrumented twin in 4.844 uninstrumented / 4.757 instrumented CPU seconds.

Two thirty-second late-save native profiles use Balanced, 960x600, close center
68,63 and Dummy audio. Scoped fingerprint
`7b512c1765e4fa0202fe745e28f7b534e06d675f4b4e1231d9157afe067278de`
(296 files) is unchanged. One Winter worker is recorded at each start/end; these
remain contended source CPU observations.

| Speed | Wall seconds | Ticks | Main p95 / max ms | Tick p50 / p95 / max ms | Main / tick calls >50 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1x | 30.032 | 300 | 13.644 / 55.881 | 2.243 / 15.662 / 55.075 | 1 / 1 |
| 4x | 30.033 | 1,201 | 26.612 / 56.390 | 2.462 / 12.914 / 52.978 | 1 / 1 |

Both keep requested speed, clean storage/invariants and backlogs
0.041293/0.063946 seconds. Input/end counts remain eight residents, 104
structures, 124 crop tiles, sixteen wildlife, 2,065 Chronicle entries and fog;
positive stacks change 590 -> 588/602 and targets one -> one/zero. The late
simulation p95 still exceeds the 4 ms gate. Physical Android, GPU, memory/thermal,
all-alert and thirty-minute release gates remain open.

A bounded native longevity probe is now available via `tools/run_soak.py`. It
uses the real session/lifecycle/saving and bounded diagnostics, periodic invariant,
engine-heap/RSS samples and drawn-frame windows. The independent audit verifies
source provenance, process/log completion, logical time, resident population,
source/input stability and final snapshot/report checksums. A three-second canary
validates harness plumbing and exact round trip at twenty residents; it does not
satisfy the thirty-minute case. Desktop RSS and sampled engine heap are explicitly
separate from Android PSS, battery/thermal and full stress certification. The long
run is being prepared from a clean frozen checkout.

## 0.7.21 storage-rate reuse and clock updates

Food aging retains the full cf34471 reference path in seven new survival checks.
Per-call storage-rate reuse reduces a 200-stack/four-store fixture from at least
800 structure reads across four advances to sixteen, retaining full payloads,
age remainders, transfer/destruction behavior and reserved-input spoilage.
The HUD skips accessible-stock scans on unchanged display frames while refreshing
on logical ticks, world adoption and speed changes. All caches remain derived.

The actual 1,200-tick late, cold and crowded continuations retain canonical hashes
38c3c1ff65e2bfd52b6a79e5c0d3ff1b2416ffafd36720add35e71d100654506,
3169d6dd685eaa1fe7d8271849d88bec8292709ca366ae613de637adeb02c598 and
46cc90218fa6bbf435dfed45acec80cfb6a80e2357600dd392b06e9284e5f919.
Their instrumented twins match. Uninstrumented CPU seconds are 4.064, 2.225 and
9.049, with concurrent headless/native/Charter work. These are state-preservation
checks and single contended timings, not paired speed claims or phone budgets.

The cf34471 thirty-minute attempt failed during warmup at tick 1802/speed zero;
its failed independent audit and exact save are retained. No measured thirty-
minute interval occurred. The original harness did not retain pause-origin
context, so startup focus is only a hypothesis. Startup settling and bootstrap/
failure context are now explicit; later focus, speed or storage interruptions
still stop the real session. A revised sixty-second-warmup/three-second canary
passes with twenty residents, 61 ticks and exact round trip. It is plumbing
validation, not a long soak. The full case needs a new clean frozen revision.

## 0.7.22 production selection and borrowed reads

Explicit food recipe proposals now share the prefix helper already used by default
cooking and replacement inputs. Production/live-stock reads borrow private views
only inside trusted ticks; all original state/quantity predicates stay in place.
Twelve independent checks retain cc84275 creation, maintained-stock and complete-
step references, accepted fixtures and exact full-state comparisons through 600
ticks, including same-tick cancellation/depletion/append and direct reopening.

Four alternating original/current full 1,200-tick pairs per input all retain exact
hashes and invariants. Median CPU seconds: fresh 0.416156/0.413192, cold
2.473606/2.468693, late 4.527185/4.525181, crowded 8.613415/8.500077.
Fresh/cold/late differences are near neutral; crowded improves slightly. Inputs
and canonical endpoints are unchanged from the preceding sections. These runs
share a host with two Charter workers, native soak and headless tests; they do
not certify Android, rendering, memory or the 4 ms simulation p95 gate.

## Frozen cc84275 native soak failure

The 0.7.21 source run stops at 819.098966 measured seconds when the real durable-
progress guard pauses it. It advances 16,366 of 16,381 nominal ticks at 2x,
retains twenty residents, clean invariants/storage and verifies its final save.
Diagnostics report exactly one slow-storage pause, zero backgrounds, reductions
or storage alerts, with the disk writer busy. Simulation-batch/session maxima
are 175.540/177.279 ms; their histogram p95 upper bounds are 50 ms and frame-gap
p95 upper is 100 ms. These overlapping CPU callbacks are not single-tick/GPU or
physical-device certification. The run overlaps two Charter workers plus assorted
headless benchmarks/tests/build imports; it is contended evidence.

The initial measurement is tick 3,002; the endpoint is 19,368, with 483 intact
structures, 1,355 positive stacks, 192 crops, 1,426 Chronicle entries, twenty
residents, twelve domestic animals and 32 wildlife. Hostiles/neutral visitors
reach zero; targets/jobs evolve naturally. There are 1,785 unfinished tasks,
496 executable and 1,108 queued, so the 512-executable cap still holds. The
synthetic fixture's incomplete storage-service geometry remains a limitation.
Do not count this evolving, declining-load case as the all-alert release scene.

Warmed engine heap is 128,265,877 bytes. A 60-second sample peaks at 178,261,805
then returns to 131,060,141 at 120 seconds; the drained endpoint is 149,689,717.
Final growth is 21,423,840 bytes and peak growth 49,995,928. The conservative
peak-heap proxy and independent audit fail, along with incomplete duration and
paused/missing logical time. This reports the observed transient and endpoint
separately; neither substitutes for Android PSS/sustained-growth/thermal gates.

| Retained evidence | SHA-256 |
| --- | --- |
| source.json | `65950b26cc5c2ccabae0acea647b91d25a6768ee828aa9b84312eb0983faddc1` |
| completion.json | `e63834fbc673c0c39783ede478dee705ed1548c1b4539e57069818935fb9aea4` |
| independent audit.json | `8ee7b3adebaae82efc90b165cefde6b99a359176f420f8fb0fdfe77ceff478f6` |
| probe.json | `1c0f8f6d1f265754440bce12ee9ceb7c7e0a51a7384920f11ce7343aef4d9315` |
| final snapshot | `61964911706fb6c9efecd189da87825a51073928de2ac5a5bb9fdf9632476326` |

The failed source/input provenance stays in ignored native-soak-v4-cc84275/.
A current-code 120-tick continuation is exact against its instrumented twin:
2.477394 uninstrumented / 2.544576 instrumented CPU seconds. Assignment totals
1.410467 seconds in 240 calls, making it the next concrete profiling target.
The failure is retained rather than rerun unchanged or counted as thirty minutes.

## 0.7.24 per-reservation input views

Held-input aggregation and per-item source grouping are confined to one atomic
reservation attempt, with original count/state predicates and direct-call source
behavior. Food replacement combines its escrow/candidate read pass. Independent
2e4d4c1 full reservation/food paths match eleven accepted/conserved tests, actual
carry/escrow/completion phases, partial release and retained zero-row metadata.
No content or numeric rule changes occur in this checkpoint.

The assignment profiler and ordinary twin match the 120-tick failed-soak
continuation exactly. Cooking reservations fall from 655.066 to 456.342 ms across
144 calls in separate observations. Four alternating full-tick pairs are exact:
median old/current 2.784311/2.590877 seconds (about 7% less) for that 120-tick input.
At 1,200 ticks, all four pairs per input also match: fresh
0.478119/0.478933, cold 2.394684/2.399340, late 4.640473/4.658494 and initial
crowded 8.507721/8.572756 seconds. The small regressions are retained and near
neutral; these are contended CPU observations, not device or release budgets.

A separate counter-only probe of the same failed input confirms 144 noncanceling
owned-cook releases and 144 successful cook reacquisitions over 120 ticks, with no
meals produced and exact ordinary-twin hash
79e27f51bd8c69c2ed41147f5be3de2d17c67bbdbdc286ecb53c64122389a910.
Probe SHA 5cb5505b87074ad91be151cf3fd458988e48b9cb42aed710d225257cbd75b706;
input SHA 61964911706fb6c9efecd189da87825a51073928de2ac5a5bb9fdf9632476326.
The low-rest interruption predicate and subsequent hungry-sleep eligibility
contradict each other. Correcting that gameplay behavior is next work, requiring
an explicit regression and preserved acknowledgements; this checkpoint only
bounds the unchanged reservation reads.


## 0.7.33 frozen native soak: failed, population lost

A clean unchanged 445f183 checkout attempted the standard 1,800-second/2x native
probe with 60 seconds of warmup. It stopped after 1,214.875 measured seconds
at tick 27,299, when settlement end paused the simulator and no residents remained.
It cannot certify the duration or sustained population load. Peak sampled engine
heap growth was 53,836,730 bytes, final growth 12,517,070; the heap proxy fails.
The lowest sampled one-second FPS was 26.127, with no sub-24 streak, but load
was declining. Exact input/source checks, invariants, codec round trip and audio
drain passed. Final stocks included 2,488 travel rations, 6,152 grain and no meals,
vegetables, mushrooms or meat. Travel-ration use remains off in this synthetic
fixture; those stocks do not imply available ordinary meals. A future longevity
fixture needs explicit sustainable food access as well as the stated object load,
without replenishing supplies or people during measurement. This failed result
and its original input must remain retained.

Raw evidence is native-soak-v6-445f183, including failed audit/completion. Source
commit 445f183ecfd8c3e1f7416ff8a07d55c1e659f7be; input snapshot SHA
3a65112145f5bf35ee179d02075d48a2accc037dd611630021c43d4460128e32;
final snapshot 9447071783359673e28eb3ee78618374c9beaad6fda2e2a1934cb1bf3d1e8d54;
audit 1ecfe5dcccc69ae4cc739a1d11c2fe640338b9df7d830f3025ff3dceec712c5c.
This is synthetic/native diagnostic evidence, separate from ordinary survival
balance, physical Android PSS, battery and thermals.

## 0.7.34 domestic read reuse: short native observation

The same retained prior stress endpoint ran 18.027 seconds at 4x, tick 19,368 to
20,089, with twenty residents, clean invariants, unchanged source and all five
counters zero. Maximum session/simulation-batch/frame gap was
81.769/79.893/94.198 ms. Session and frame-gap p95 bounds remain 100 ms, so the
performance budget is still missed. The independent four-pair full-body CPU
comparison and exact-state checks are recorded in STATUS.md. These observations
were made on Apple M5 Pro/macOS 26.6.2/Balanced30 alongside headless validation;
they are neither uncontended benchmarks nor Android improvement certification.
