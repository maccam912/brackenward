# Runtime CPU comparisons

The original phone report is preserved in
[ANDROID_DEVICE_EVIDENCE.md](ANDROID_DEVICE_EVIDENCE.md). These later source
comparisons run on the Apple M5 Pro with the pinned Godot 4.7.2 Compatibility
build. They do not establish current physical Android frame times or memory.
Long campaign/generation workers were active on the same host, so the paired
complete-tick CPU measurements are distinct from an isolated frame-rate gate.

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
The unchanged strict memory proxy remains failed as documented in
[STRESS_EVIDENCE.md](STRESS_EVIDENCE.md).


The Android65 whole-map interaction test records the first-night CPU fallback
notice with selected4x retained. The runner's existing policy requires sustained
bonus backlog for three seconds before suppressing the boost until a resident
wakes; this was not merely a single slow tick. The explicit morning save has
four sleeping residents below900 rest. These observations preserve the fallback
scope and do not constitute a sustained12x emulator pass. A possible later
presentation improvement is to retain12x where feasible but try8x/6x before
falling back to manual speed; that tiered behavior is not implemented here.
