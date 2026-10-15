# Runtime CPU comparisons

The original phone report is preserved in
[ANDROID_DEVICE_EVIDENCE.md](ANDROID_DEVICE_EVIDENCE.md). These later source
comparisons run on the Apple M5 Pro with the pinned Godot 4.7.2 Compatibility
build. They do not establish current physical Android frame times or memory.
Long campaign/generation workers were active on the same host, so the paired
complete-tick CPU measurements are distinct from an isolated frame-rate gate.

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
