# Runtime CPU comparisons

The original phone report is preserved in
[ANDROID_DEVICE_EVIDENCE.md](ANDROID_DEVICE_EVIDENCE.md). These later source
comparisons run on the Apple M5 Pro with the pinned Godot 4.7.2 Compatibility
build. They do not establish current physical Android frame times or memory.
Long campaign/generation workers were active on the same host, so the paired
complete-tick CPU measurements are distinct from an isolated frame-rate gate.

## 0.7.69 diagnostic heap ownership

The native development probe adds a separate bounded frame-boundary heap trace
and snapshot/writer ownership flags. Context is privately captured only on a new
maximum;32high-water events remain. Initial baseline or unsupported values stay
null. Context includes source/capture/journal ticks,retired groups and cache sizes.
Collector allocations are included. Concurrent ownership does not assign an
allocation cause; this is separate from the unchanged periodic20MiB proxy and
physical memory gates. No application src,data,scene or save rule changes.
Five collector regressions,persistence477,eight Python audit tests,graphical-only
compile guard and Android108 export pass. The first frozen native trace remains
pending; later evidence must retain any failure and original67peak unchanged.

## 0.7.68 stable job-release reads

The complete full-history release loop remains. Hoist its normalized reservation
policy/jobID after unchanged callbacks,and read each live stack location once.
Every depleted carry/escrow coordinate/owner/job/reservation mutation remains,
along with recursive callback order. The full originaldefdc91 method is retained.

| Case | Ticks | Original median us | Hoisted median us | Result |
| --- | ---: | ---: | ---: | --- |
| Ordinary20 retained endpoint | 720 | 3117584.5 | 3013387 | 3.34% lower |
| Fresh revision2 Meadow104729 | 7200 | 1143907.5 | 1138812.5 | 0.45% lower |
| Retained stress/rations | 720 | 3200260.5 | 3185287.5 | 0.47% lower |

Four alternating final pairs preserve complete unsorted values,invariants and
unchanged source/input. The small-case differences are not material. Earlier
separate traces show27release calls median285856.5to199035us (about30% lower),
with complete state equality; nested traces are not added to whole-tick timings.
Prototype/early pairs share current67's native4x probe; corrected final pairs
share bounded headless checks after it ends. No isolated/phone/frame/heap claim.
Four new history/recursion/future/reload regressions,scheduler425,persistence472,
UI670,replay62/all old acknowledgements and Android107 export pass. Initial mixed-
indentation prototype failure and a corrected unsupported reload-key-order test
assumption remain retained. [release-hoist-v68-evidence.json](release-hoist-v68-evidence.json)
records exact inputs,sources,medians and failure hashes.

## 0.7.67 adaptive quiet-night tiers

A12x sleep boost with sustained backlog now tries8x and6x before disabling bonus
playback for the sleeping period. The8ms/eight-tick batch budgets remain. Each
tier still needs more than one second of bonus backlog for three consecutive
seconds before stepping down. Selected manual speed, exact complete world ticks,
wake/alert boundaries and the final suppression notice remain unchanged. A pause
keeps the learned tier; waking or changing the setting resets it. The HUD shows
actual sleep speed. Diagnostic histograms separate6x/8x and remain bounded to91
rows and64KiB JSON. No phone-throughput claim follows from injected-clock tests.
Scheduler421 passes including sustained8x/6x complete-state twins, brief stalls,
all-tier exact wake/fire stops and the unchanged final manual-fallback checks.
Persistence472,replay62/all old acknowledgements,graphical UI670 and Android106
export/metadata also pass. Inspected HUD shows8x sleep with retained4x tooltip;
remote67CI/publication and physical throughput remain separate.

## 0.7.66 background-worker latency

The local report adds save_worker and snapshot_worker wall timings. A timestamp
immediately before Thread.start and a timestamp after the worker's owned-data
cleanup measure scheduling plus worker work. Foreground capture and a delayed
poll/join are excluded. These parallel wall timings overlap CPU callbacks and
must not be added to them. Each operation retains its original capture tick and
actual playback speed, including12x; pausing before polling cannot relabel it.
Successful and failed saves and explicit preparation joins are recorded once.
A headless queue without presentation context adds no invented speed sample.
No owned payload, acknowledgement, durability deadline or thread policy changes.
The collector remains bounded:13stages times5speeds=65histograms,32slow events,
14bins and the unchanged64KiB export cap. Two keyed English stage labels are added.

Seven new gated-worker tests inspect real verified saves, exact live world state,
original timing context, failed writes and once-only collection. Early tests
incorrectly assumed a newly created SceneTree timer represented that much real
wall time even in a long startup frame. Retained failures show a2.258ms worker
with no actual60ms wait. The corrected test waits against monotonic elapsed time;
focused checks pass. Initial missing-class import failure is retained separately.
Full current persistence472 and replay62/all older acknowledgement checks pass;
Android105 export/metadata pass with unchanged cached Kotlin4 XML;
current graphical validation remains separate and pending.

## 0.7.65 resource regrowth view

The agriculture loop now visits only resources with positive regrowth timers during
trusted ticks. It retains the original row order and predicates, every tick of
winter delay and all historical records. Commands, gathering depletion, legacy
replant completion, regrowth completion, generation and resource-array changes
invalidate the view. Direct calls use the full scan. The complete original702b20b
agriculture loop and a full-scan world remain independent references. Dormant legacy
timers remain candidates while resources are positive; quantity is checked live
so a later gathering job cannot hide an existing timer.

Four alternating complete-tick pairs preserve complete unsorted state, canonical
hashes and invariants, with unchanged sources and inputs:

| Case | Ticks per run | Original median CPU us | Derived median CPU us | Result |
| --- | ---: | ---: | ---: | --- |
| Fresh revision2 Meadow104729 | 7200 | 2172799.5 | 1229035 | 43.44% lower |
| Ordinary20 retained endpoint | 720 | 3523698.5 | 3370859 | 4.34% lower |
| Retained stress/rations input | 720 | 3772261 | 3766852 | 0.14% lower |

These are desktop simulation CPU comparisons, with local suites and a paused Android emulator sharing
the host. They do not establish Android frame-time or thermal behavior. The
small-resource stress result shows no material change. Five new regressions
cover winter/boundary timers, actual gather and legacy replant, array/direct-call
boundaries, complete future state/reload and dormant positive legacy timers;
nature23, persistence465,
generation169,survival83,seasons26 and graphical UI669 pass. Earlier copied-oracle
compilation failures are retained and were rejected by the fail-closed runners.
The fifth regression first reproduced the dormant-timer bug in the initial
zero-remaining-only filter; the corrected candidate set passes. Earlier source
measurements remain retained separately.
[regrowth-v65-evidence.json](regrowth-v65-evidence.json) records exact evidence.

## 0.7.64 read-only complete-tick and work breakdown

The retained ordinary20 generator2 endpoint has3079 resource records, none
regrowing, and21 planted saplings. A720-tick instrumented twin matches all
canonical state. One base trace takes3388441us (4.706ms/tick); its nested work,
assignment,living,agriculture and nature phases total768691,454133,385808,
307548 and242439us respectively. These are stage attribution, not a paired
speedup or physical-device result.

A second complete-work twin also matches, baseline3645218us over720ticks.
Its nested work/walk phase takes348379us/6850calls; release313824us/27calls;
finish190460us/22calls. This identifies historical inventory cleanup as a later
spike target. The full scans update historical zero-count metadata, so replacing
them with a positive-only inventory list would change saved state and is not an
acceptable shortcut. Raw logs retain the complete rankings and harness hashes.
Meanwhile the resource regrowth loop checks every resource on every tick even
when none has a timer, providing a separate simpler CPU target.

## 0.7.47 repeated storage association reads

The completed ordinary twenty-colony endpoint has 232 structures, 26,871 job
records (390 active), 18,150 stack records (695 positive), and 260 farm tiles at
tick 693,000. An instrumented 120-tick run matches a normal twin exactly. Work
assignment spends 259,247 microseconds in 592 destination queries, nested in
367,715 microseconds of assignment and 1,186,245 microseconds of ordinary ticks.
Nested timings overlap and must not be summed.

`_destination` checked whether a store had an associated structure inside every
tile iteration. Plain painted stockpiles have no structure, so each tile repeated
a missing-ID scan of the full structure list. The query now performs that pure
association read once per eligible store. Filters, capacity, pile tags/limits,
incoming cargo, burning checks, tile order and the exact existing sort/tie
behavior remain unchanged. No result cache survives the call. No gameplay,
save, content or generator rule changes.

`DestinationReadTests.OriginalWorld` retains the exact 8c0e060 query. Eight new
checks cover 576 original/candidate quotes with and without explicit contexts,
tile ties, building stores, full capacity, priorities, filters, tags, burning,
and empty results. A 32-tile eligible stockpile takes one association lookup
instead of 32. Crowded complete ticks compare all saved state, round-trip, and
continue after reload without changing original expected values. Scheduler
passes 403; maintained total becomes 2,649 across 28 suites.

Four alternating pairs compare the retained full original method with the new
runtime over complete ticks, not a replacement benchmark algorithm:

| Input | Ticks per run | Original median CPU microseconds | New median | Change |
| --- | ---: | ---: | ---: | --- |
| Ordinary twenty-resident endpoint | 720 | 7,322,150 | 6,335,766 | 13.47% lower |
| Retained ration-enabled stress endpoint | 720 | 6,336,510.5 | 6,234,992 | 1.60% lower |
| Fresh revision-2 Meadow seed 104729 | 7,200 | 3,559,136 | 3,560,350.5 | 0.034% higher |

All pairs match their complete canonical states, invariants and source/input
identities. A shorter fresh 720-tick comparison was 6.89% higher amid host load;
it is retained rather than discarded. The longer fresh comparison shows no
material improvement or regression. These results support the late-game case;
they do not demonstrate a phone freeze fix or a universal CPU gain.

Source fingerprint (120 runtime/data/reference/harness files):
`48c5f6ecd65dbeb95a6e0366dd4204a07ab9607f3254068ee16b509e1904253f`.
The ordinary input SHA-256 is
`41495c97032fcb2bd56317b927ba55eea16332ac0a3866c835842b781d311175`;
stress input `d9e17fa699e55192a5fe7ee59cc0a60bc75353083388a6d774ef31112c987fa8`.
No input or original campaign report was rewritten.

| Retained raw log | SHA-256 |
| --- | --- |
| destination-v47-ordinary20-pairs.log | `25d622a60b418cecfbeba1874e1066b1879a5c59a17516d7db10ff579bdcb70b` |
| destination-v47-stress-pairs.log | `09661dd09c25ba2bf0086138f3c92fa2d67cf23e0d082beb7386c14d23c0adae` |
| destination-v47-fresh-long-pairs.log | `25753805904ad2cf47bc17286cbaedd6b8f55d1efc3b0f013eab019476e6e593` |
| destination-v47-fresh-pairs.log | `3642e730c5318b195491f58106e278b163bb91df71e2494e791316ba8e295244` |

Persistence 345, colony 42, production 52 and native UI 663 also pass. The frozen
historical replay and all old acknowledgement/foreign-save continuation audits
pass without golden changes; report SHA-256 is
`efe5adabbf54233a7f3f7e64d6d6784c4e710f831ae52203de1262b15fc54140`.
At this0.7.47 checkpoint the strict memory proxy failed, as documented in
[STRESS_EVIDENCE.md](STRESS_EVIDENCE.md); later pinned results remain separate.


The Android65 whole-map interaction test records the first-night CPU fallback
notice with selected4x retained. At that checkpoint the runner requires sustained
bonus backlog for three seconds before suppressing the boost until a resident
wakes; this was not merely a single slow tick. The explicit morning save has
four sleeping residents below900 rest. These observations preserve the fallback
scope and do not constitute a sustained12x emulator pass. The proposed8x/6x
intermediate tiers are implemented in0.7.67 above; the older65 Android run does
not certify their emulator or physical-device throughput.
