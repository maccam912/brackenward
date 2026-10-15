# Synthetic crowded-colony measurements

These are development profiling results on macOS, separate from ordinary-play
campaign evidence and physical Android release requirements. The frozen v6 thirty-minute native source case now passes its strict sampled
engine-heap/FPS proxies. The full physical release stress gate, all-alert variant,
PSS/battery/thermal measurements and low-tier/Mali phone matrix remain incomplete.

## 0.7.74 ten-minute4x sampled proxy passes; late frame transient remains

Frozen30db9fa completes600.009101seconds after60seconds warmup,24001ticks4204to
28205,20residents and zero counters. Lowest one-second FPS28.564,logical time,
invariants,source/input,roundtrip and audio drain pass. Periodic sampled peak
13,949,006bytes and ending10,012,328 pass the unchanged20MiB proxy plus independent
second audit. Sampling is every5seconds,denser than earlier67; this is not the
required30-minute2x or physical case. Original67's failure stays failed.

The separate frame trace reaches34,749,968bytes at tick27199/574.843seconds with
live writer/capture27196/journal27158,no preparation worker/retired groups and
stable navigation. This extends beyond the earlier three-minute cases; no causal
allocation or regression ratio is assigned. Collector allocations are included.
No other GUI/emulator runs; code/text edits,headless import/unit/message/control
checks share host. The late transient remains unresolved. Actual same-input67/74
endpoints compare exactly after one current tick alignment,no field normalization.
[native-soak-v74-4x-evidence.json](native-soak-v74-4x-evidence.json).

## 0.7.72 short diagnostic trace: encoding gain does not resolve session peak

This180.018198-second4x case completes7200ticks,20residents,zero counters and lowest
one-second FPS28.645. Periodic peak7,196,632 bytes passes its20MiB proxy and second
audit. Frame peak29,856,564 bytes at tick5396 has live writer/capture5380/journal5345,
no preparation/retired groups and stable navigation. There are5399valid frame
observations; bounded collector allocations are included. No other GUI/emulator
runs. Read-only73prototype, code/import/persistence share host. The component
encoder gain does not resolve the session transient or certify physical gates.
[native-heap-v72-observation-evidence.json](native-heap-v72-observation-evidence.json).

## 0.7.71 short diagnostic trace: whole-session peak unresolved

The180.016457-second4x case completes7200ticks,20residents,zero counters and lowest
one-second FPS29.464. Periodic peak7,944,796 bytes passes its20MiB proxy and separate
second audit. A separate frame peak30,249,953 bytes at tick5395 has a live writer,
capture tick5381, journal tick5344, no preparation/retired groups and stable
navigation.5399 frame observations include bounded collector allocations. No other
GUI/emulator runs; read-only 72 prototypes, code/import and the beginning of bounded
persistence share host. The buffer-lifetime component improvement does not resolve
this session peak. Physical,30-minute and prior failed scopes remain separate.
[native-heap-v71-observation-evidence.json](native-heap-v71-observation-evidence.json).

## 0.7.70 short diagnostic trace: frame peak remains

This180.022838-second4x case after60-second warmup completes7200ticks,20residents,
zero counters and lowest one-second FPS29.413. Periodic peak growth7,660,230 bytes
passes its20MiB proxy and independent second audit. The separate frame-boundary
trace reaches30,358,802 bytes at tick11071 with live writer, capture tick11068,
journal tick11028, no preparation/retired groups and stable navigation caches.
There are5399valid frame samples; collector allocations are included. No other
GUI/emulator runs. Bounded headless import/persistence and inspection share host.
This retains the unresolved transient; it is not a30-minute or physical pass.
[native-heap-v70-observation-evidence.json](native-heap-v70-observation-evidence.json).

## 0.7.69 short diagnostic trace: periodic pass, frame heap unresolved

The180.0317-second4x case after60-second warmup completes7201ticks,5399valid
frame observations and its unchanged periodic20MiB proxy plus independent audit.
Periodic peak growth is14,858,736 bytes; separate frame-boundary growth reaches
30,205,169 bytes at tick11055, with writer busy/alive, captured tick11051,
journal tick11009, no preparation/retired groups and stable navigation caches.
This concurrent ownership narrows measurement targets without assigning cause.
Collector allocations remain included. No other graphical game/emulator runs;
read-only inspection shares the host. Memory remains unresolved. This is not the
required30-minute2x or physical gate. Earlier failures remain failed;70's decoder
component comparison requires a new whole-writer trace.
[native-heap-v69-observation-evidence.json](native-heap-v69-observation-evidence.json).

## Current0.7.67 ten-minute4x run fails transient heap growth

The4x development probe completes600.02469seconds after60seconds warmup,
24001logical ticks4205to28206,twenty residents and zero diagnostic counters.
Lowest one-second FPS28.988,logical time,invariants,source/input,exact roundtrip
and audio drain pass. Sampled peak heap growth25009847bytes (23.851MiB) exceeds
the unchanged20MiB limit; ending growth9552980bytes. The peak is the first60-second
sample at6605. Whole-run and independent second audit therefore remainfailed.

Actual background worker maximums are744.073ms(save) and282.787ms(preparation),
while foreground captures stay below17ms. The sample lacks current writer/
preparation ownership flags,so no allocation cause is assigned. Read-only release
prototypes and bounded headless checks share host; no other graphical game or
emulator runs. This ten-minute4x case does not certify30-minute2x or physical
Android/PSS/thermal/battery gates. [native-soak-v67-4x-failure-evidence.json](native-soak-v67-4x-failure-evidence.json)
retains the strict failure and all valid subsets; later optimization remains
separate and no memory/durability guard is relaxed.

## Same-source 0.7.63 retry passes in a separate directory

The clean frozen357fa04 retry completes1800.023079seconds at2x after60seconds
warmup,36001ticks3002to39003,twenty residents and zero diagnostic counters.
Sampled engine-heap peak grows15328444bytes (14.618MiB),ending15320492bytes;
lowest one-second FPS28.134 and no sustained below24 streak. Full source/input,
invariants,save roundtrip,audio drain and the independent second audit pass.
Every authoritative world field equals the prior native62 endpoint at39003.

The emulator and long scenario/generation workers were stopped. Bounded headless
save/scheduler/unit/replay checks,imports/Android exports and artifact downloads
shared the host; this is lower contention,not an isolated benchmark or causal
explanation of the earlier failure. Earlier failed63 remains failed. Later64–67
runtime changes and physical Android/PSS/thermal/battery gates remain separate.
[native-soak-v63-retry-evidence.json](native-soak-v63-retry-evidence.json) retains
both audits,complete source/input/report/save hashes and earlier-world equality.

## Frozen 0.7.63 run fails after a protective save pause

The requested1800-second2x run stops at1576.563294seconds, tick34533,
with one slow-storage pause. The unchanged1.75-second undurable-progress guard
pauses simulation, so completion and the separate second audit fail. This stays
a failure. The valid subsets include31531ticks matching floor nominal,20living,
16536832-byte sampled peak growth, lowest one-second FPS28.434, full roundtrip,
unchanged source/input and audio drain. No storage error or saving-disabled flag
appears. Save capture/finish callbacks do not measure actual worker wall latency,
so the report cannot attribute the cause to host load or the diagnostics change.

Native63 shares the host with ordinary20/merchant work, headless suites/probes
and editor/export work, including three failed reference-compilation probes.
[native-soak-v63-failure-evidence.json](native-soak-v63-failure-evidence.json)
retains every source/report/save hash and the failed second audit. Earlier passing
native62 stays a separate pinned result. Physical release gates remain open.

## 0.7.64 share repeated keys in privately decoded worlds

Fresh external JSON conversion now shares equal String dictionary keys through
one bounded per-load pool. It retains key types, insertion order and private
container identities. No string value or history record changes. Integer maps,
coordinates, depth limits, full schema/reference/conservation checks and public
restore remain unchanged. The complete0.7.63 decoder and prior converter remain
the independent reference. All39 immutable fixtures and malformed-input gates
pass, including complete future-state and roundtrip comparisons.

| Retained input | Prior CPU ms | Shared CPU ms | Prior peak MiB | Shared peak MiB | Prior ending MiB | Shared ending MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Synthetic native44 endpoint | 214.170 | 239.350 | 47.840 | 47.848 | 26.168 | 18.719 |
| Ordinary20 generator2 endpoint | 3285.532 | 3565.311 | 730.430 | 730.414 | 393.791 | 274.718 |

Four alternating background complete-load pairs preserve every authoritative
field and unchanged input/source. Ending world allocation falls28.5%/30.2%; CPU
is about9–12% higher and peak is effectively unchanged. The one-world attribution
probe separately identifies equal key buffers as the retained cost. The host
also runs frozen native63, generation and an ordinary20 campaign; these results
are not physical Android PSS, frame pacing or load latency certification.
[snapshot-keys-v64-evidence.json](snapshot-keys-v64-evidence.json) retains the
medians, full reports, independent reference proof and immutable-input hashes.

## Frozen 0.7.62 native continuation passes

Clean424f897 completes1800.029161 seconds at selected2x after60seconds warmup,
36001 logical ticks3002 to39003. Twenty residents remain. Peak sampled engine
heap growth is20271140 bytes (19.332 MiB), ending15311524 bytes (14.602 MiB),
below the unchanged20MiB bound. Lowest one-second FPS is28.429; the below24
streak is zero. All five diagnostic counters are zero; full source/input,
invariants, storage, codec roundtrip and audio drain pass. The separate second
audit passes, and every gameplay field equals the earlier v7 native59 endpoint
at the same tick. Earlier failing runs retain their original outcomes.

[native-soak-v62-evidence.json](native-soak-v62-evidence.json) retains exact hashes.
There was no second graphical game or emulator during measurement; headless
post-Charter, generation, profiling, suites, replay and exports shared the host.
This is a desktop development proxy; Android PSS longevity, physical frame pacing,
battery and thermals remain separate release gates.

## Frozen 0.7.59 native byte-backed preparation subset passes

Clean487bb1d completes1800.020424 seconds at selected2x after60s warmup,
36001 logical ticks3002→39003 versus36000 floor nominal, within the unchanged
no-drop/window gate. Twenty residents remain. Peak and ending sampled engine
heap growth are15345852 bytes (14.635 MiB), below20 MiB; lowest one-second FPS
is28.605, with zero below-24 streak. Full final codec roundtrip, invariants,
storage, source and audio drain pass; all five diagnostic counters are zero.
The separate second audit passes. Its entire same-tick gameplay matches native55
after only two content headers normalize; that earlier heap failure stays Fail.

[native-soak-v59-evidence.json](native-soak-v59-evidence.json) retains all raw
source/report/save/comparison hashes. No second graphical Godot runs during
measurement; headless Winter, Charter then post-Charter, profile/suite/replay and
export work share the host. This is not a pristine or causal whole-native ratio,
constant all-alert load, physical Android/PSS/battery/thermal or full release
certificate. Overall0.7.59 CI separately fails its empty-hash probes; the measured
nonempty native subset remains valid. Later loader/UI revisions are separate.

## 0.7.61 avoid a private catalog-header deep copy

The external decoder owns its fresh converted JSON. For exact verified v2–v6
catalogs with identical definitions, it changes only the two content headers in
that private root before the unchanged full restoration. Public/shared restore
keeps its original copy behavior; no capture or live-world data enters the
consuming path. The complete prior decoder remains the reference, with source
proof for the full restoration body and unchanged validators/migrations/codec.
Persistence458, exact replay62 and all39 immutable save comparisons pass.

| Retained input | Prior CPU ms | Owned CPU ms | Prior peak MiB | Owned peak MiB | Prior ending MiB | Owned ending MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Synthetic native44 endpoint | 212.178 | 199.911 | 52.826 | 47.846 | 26.138 | 26.168 |
| Ordinary20 generator2 endpoint | 3519.236 | 3310.099 | 805.392 | 730.419 | 393.496 | 393.791 |

Four alternating background full-decode pairs, approximately1ms sampled process
engine heap; ending read before diagnostic equality. Every complete world is
identical; sources/inputs/all39 fixtures stay unchanged. Peak falls about9.3%
and CPU about6%, while ending allocation is slightly higher. The host also runs
frozen native, Winter and post-Charter work; no physical Android or uncontended
whole-native ratio is inferred. The ordinary retained-history cost remains open.
[snapshot-migration-v61-evidence.json](snapshot-migration-v61-evidence.json)
records all inputs, source fingerprints, raw reports and medians.

## 0.7.60 reduce external decode peak

The loader releases checked payload text, converts only fresh owned parser
containers in place using the existing integer/map/tile/depth rules, then
releases parser/envelope references before full restoration. The complete prior
decoder and independent ColonyState.unpack remain the reference; restoration,
migrations, external encoding and all validation are unchanged. All 39 recursive
fixtures restore identical complete state and bytes remain unchanged. Persistence
455 and the exact 62-command replay pass; later graphical/physical runs remain
separate.

| Retained input | Original CPU ms | Owned CPU ms | Original peak MiB | Owned peak MiB | Ending world MiB (both) |
| --- | ---: | ---: | ---: | ---: | ---: |
| Synthetic native44 endpoint | 201.536 | 201.333 | 81.507 | 52.827 | 26.138 |
| Ordinary20 generator2 endpoint | 3356.286 | 3387.676 | 1243.165 | 805.392 | 393.496 |

Four alternating background pairs, roughly 1-ms sampled engine heap, ending read
before diagnostic state comparison. This contended host also runs frozen native,
Winter and Charter/post-Charter work. CPU differs by less than one percent; the peak decrease
is about 35 percent on both inputs. The ordinary endpoint remains expensive:
49,894 retained jobs and 41,618 stack records. No history is dropped, save bound
raised or phone improvement inferred. [snapshot-load-v60-evidence.json](snapshot-load-v60-evidence.json)
retains exact source/input/report fingerprints.

The original 0.7.59 persistence pass claim is corrected: 450 assertions passed,
but two empty-buffer hash engine errors made the runner fail locally and in CI.
[empty-hash-v59-failure-evidence.json](empty-hash-v59-failure-evidence.json) retains
that failure. The empty-buffer SHA helper now skips update and finishes the
initialized context, preserving its native digest; current persistence passes
without engine errors. Other independently measured nonempty preparation scopes
remain intact.

## 0.7.59 retain validated UTF-8 prepared payloads

Preparation and prepared publication now keep the exact verified UTF-8 buffer
instead of retaining a full UTF-32 String between the two stages. The digest is
computed directly from those bytes and rechecked before publication. A legacy
text view remains available for tools/tests; production uses bytes directly.
The envelope builder handles at most4096 UTF-8 bytes per fragment, moves cuts to
complete Unicode code points, checks native decode/encode roundtrip, and uses
native JSON string escaping. Metadata, payload checksum and every output byte
match the unchanged String/native-envelope references at a fixed timestamp.
The original64-MiB input/output limits, full validation, immutable ownership,
wire format and exact publish readback remain unchanged.

The complete1270652 factory and original String-backed record/matcher are the
independent references. Older retained factories now use that same scalar record
through an explicit class alias, so their storage/performance behavior does not
silently change with the production class. Source checks verify the complete
factory body, record fields/matcher, String envelope and unchanged external codec.
Six new persistence checks cover multibyte cuts/escaping/headers, actual size caps,
exact bytes/text view/digest/capture identity, byte/text tampering, and all39
recursive immutable save fixtures including new v6/v7 acknowledgements. Full
persistence records 450 passing assertions but its runner rejects two empty-hash
engine errors. The original pass claim is corrected in STATUS.md and
release-polish-v59-evidence.json; UI/replay/export have separate recorded results.

| Retained input | String CPU ms | UTF-8 CPU ms | String sampled peak MiB | UTF-8 peak MiB | String ending growth MiB | UTF-8 ending MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Native-44 synthetic endpoint | 290.262 | 288.697 | 11.384 | 10.061 | 8.155 | 2.931 |
| Fresh-generator-2 ordinary twenty endpoint | 4611.336 | 4595.805 | 172.492 | 80.303 | 125.220 | 33.016 |

Four alternating background pairs reproduce complete payload text, digest,
validation and capture identity; all39 recursive fixtures agree per run. Roughly
1-ms sampling measures process engine heap. Ending growth is read immediately
after the worker, before the diagnostic text view/equality check. Baselines
retain reference text. Peak falls about11.6% /53.4%, and ending growth falls
64.1% /73.6%; CPU is within about1% on this contended host. Frozen raid/then-Winter,
Charter and native jobs run concurrently; these are component observations,
not physical Android or a causal comparison of native end-to-end runs.
[snapshot-bytes-v59-evidence.json](snapshot-bytes-v59-evidence.json) retains exact
inputs, original/current runtime/reference fingerprints, reports/logs and medians.

## Frozen 0.7.58 current-v7 native and raid gates pass

The separate1270652 native source run and independent second audit complete
1800.011566 seconds at2x with exactly36000 ticks and twenty residents. The strict
20-MiB sampled proxy passes at15.763 MiB; lowest one-second FPS is27.765. Source,
roundtrip, invariants/storage, audio drain and logical time pass; all five
counters are zero. Its complete final gameplay equals native56 after only the
two content headers normalize. No second graphical Godot runs during measurement;
two Charter workers, two raid/then-Winter workers and main headless/profile/export
work share the host. This is not physical Android/PSS/battery/thermal/human or
complete release certification. Exact evidence is
[native-soak-v58-evidence.json](native-soak-v58-evidence.json).

The frozen v7 paired raid matrix and second audit also pass30/30 defense and
30/30 physical ransom on thirty distinct maps/entries, retaining every initial
geometry/header/inspected-map, order/receipt, walking, reload and outcome check.
[prepared-defense-v58-evidence.json](prepared-defense-v58-evidence.json) retains
the detailed rows and manifest hashes. V7 Winter/Charter and the new UTF-8 runtime
have separate ongoing validation; older failed native/cart results stay intact.

## Frozen 0.7.56 thirty-minute native proxy passes

Clean unchanged `e4003fb1eb532f76b2d747975075244f09a221d4` completes
1800.003209 measured seconds after sixty seconds of warmup at selected 2x,
advancing exactly 36000 ticks against 36000 nominal (3002 to 39002). Both the
original probe and separate second audit pass. All twenty residents remain;
invariants/storage/logical time, full final round trip, source identity and
audio drain pass. All five diagnostic counters are zero. Lowest one-second
FPS is 27.316, without a below-24 streak.

Peak and ending sampled engine-heap growth are 15305596 bytes (14.597 MiB),
below the unchanged strict 20 MiB proxy. The measured final canonical hash is
`3cdeb39092ecb0d5a1a4a17e898330a0b22b7d86ad3de1b7217ce2cc7e31890d`.
A separate private extra tick aligns this 36000-tick run with native55's
36001-tick endpoint and reproduces its entire payload exactly, canonical
`4a8fee28b0a01de385fc3bb8bfe48f7df5706c1b291760e7dca36c530303f881`.
Neither measured endpoint/save is changed by that separate comparison. Earlier
native44/53/55 failures remain intact; unaligned samples are not a causal ratio.

No second graphical Godot ran during measurement. Separate controlled probes,
headless suites/replays and Android export ran on the host; all earlier long
campaign workers had finished. This is not a pristine-host, Android PSS/battery/
thermal or overall release certificate. Raw files are
`native-soak-v6-e4003fb-quiet-host/`; exact source/completion/probe/audit/save,
second-audit and aligned-state fingerprints are retained in
[native-soak-v56-evidence.json](native-soak-v56-evidence.json).
The later v7 combat change requires its own current frozen run.

## 0.7.56 bounded snapshot verification and envelope escaping

Preparation first fully validates its recursively immutable capture, requires
an equal restored payload, and releases that private validation world. It then
encodes sorted nested string dictionaries and array blocks of at most 256
records, including terrain habitat lists. A checker rereads every actual byte,
key/punctuation/span, value and complete field/array coverage using the original
root-relative integer/map/tile/depth rules. Each decoded block must equal its
validated capture counterpart. Integer-key maps and tagged dictionaries retain
native state semantics. This avoids a second complete decoded validation tree.

A phase probe found that the final envelope still created a complete escaped
UTF-32 copy. Preparation and prepared publication now assemble that same normal
envelope in UTF-8 with at most 4096 Unicode code points per native JSON string
escape. Metadata/digests/escaping match the independent unchanged native encoder
byte for byte at a fixed timestamp; every published byte is still read back.
External full decoding and ordinary direct saves retain their original paths.
The 64 MiB cap, durability guard, schema/content/generator and reviewed fixtures
remain unchanged. No partial oversized envelope can be published.

Twenty-seven new persistence checks cover array boundaries, nested habitats,
complete grammar/coverage, empty/incomplete/oversized hostile blocks, wrong
values/counts/types, original depth/integer/map/tile rejection, immutable ownership,
full schema/reference/conservation and migration rejection, literal header strings,
control/Unicode escaping and chunk boundaries, the output cap, all 32 historical
save fixtures and the complete external codec. Persistence 431 and native UI 667
pass. The complete 6685958 factory/decoder, legacy encoder and unchanged external
codec are independently source-checked references.

| Retained input | Reference CPU ms | Candidate CPU ms | Reference sampled heap MiB | Candidate MiB |
| --- | ---: | ---: | ---: | ---: |
| Native-44 synthetic endpoint | 252.183 | 256.897 | 29.490 | 11.381 |
| Fresh-generator-2 ordinary twenty endpoint | 4252.551 | 4176.367 | 448.025 | 172.492 |

Four alternating background pairs per input reproduce complete payload text,
digest, validation and capture identity. All 32 immutable historical saves match
in each run. Final temporary preparation peaks fall about 61.4% / 61.5%; CPU is
about 1.9% higher / 1.8% lower. The ordinary returned payload text alone retains
about 125 MiB; this is not a claim that all large-save memory has been removed.
Roughly 1-ms sampling observes process engine heap, with the reference text
already retained in each baseline. All long campaign workers had finished and
no other Godot ran during final pairs. The old 0.7.53 ordinary comparison used a
different earlier endpoint; its numbers are not a same-input improvement ratio.

Exact final source/input/report/log fingerprints and medians are in
[snapshot-capture-v56-evidence.json](snapshot-capture-v56-evidence.json).
Intermediate capture-only/tree-only/earlier-envelope runs remain intact. Separate
phase attribution is diagnostic, not a substitute for these complete pairs or
for the next frozen thirty-minute native soak. The failed 0.7.55 result below
remains failed. Physical Android PSS/frame-time/battery/thermal gates remain open.

## Frozen 0.7.55 thirty-minute result: memory failure retained

Clean unchanged `6685958cc27e85dd0a5ab6ef836e939ed160a2b6` completes
1800.001313 measured seconds after sixty seconds of warmup at selected 2x,
advancing 36001 ticks against 36000 nominal. All twenty residents remain;
invariants/storage/logical time, complete final round trip, source identity and
audio drain pass. All five diagnostic counters are zero. Lowest one-second
FPS is 28.903, without a below-24 streak.

The **strict 20 MiB sampled peak proxy fails**: peak growth 31719296 bytes
(30.25 MiB), ending 15317808 (14.6 MiB). Both the original probe and independent
second audit stay Fail. The final complete payload is byte-identical to the
frozen native-44 endpoint, canonical
`4a8fee28b0a01de385fc3bb8bfe48f7df5706c1b291760e7dca36c530303f881`.
Native-53's earlier 68.6 MiB failure also stays intact; sixty-second samples do
not align allocation phases, so the difference is not a causal improvement ratio.

No second graphical Godot ran. The task's two ordinary campaign workers were
paused/resumed by exact process identity, and then completed their independent
campaign audits. Raw evidence is `native-soak-v6-6685958-quiet-host/`; source,
completion, probe, audit, save and supervisor fingerprints are retained in
[native-soak-v55-evidence.json](native-soak-v55-evidence.json).
This does not certify physical Android PSS/frame times/battery/thermals.

## 0.7.55 bounded retention while rebasing journals

Prepared rotation previously parsed and retained every decoded historical tick
frame in the old journal merely to collect its newer command evidence. It now
validates **every** checksum, sequence, JSON value and frame schema, counts every
frame, and retains only commands strictly after the preparation tick, in original
order. Its fresh private JSON may be consumed in place under the original depth/
integer/map/tile rules; unselected trees/parser buffers are released before the
next frame. Original bytes, size bounds, exact publication verification and
complete external recovery remain unchanged.

The retained a230331 complete reader is the independent reference. Twelve new
persistence checks cover exact result/ownership, strict cutoff, complete counts,
torn prefixes at each frame boundary, malformed unselected checksums/schema/
delta/values/JSON/length/depth, starting sequences and all four immutable historic
journals. Persistence 404 and UI 667 pass; maintained count is 2726 in 28 suites.

All three journals from the completed frozen native-53 scratch campaign were
copied without modifying their original bytes. Four alternating background pairs
per input compare complete retention against the final selector:

| Retained journal | Frames | Bytes | Complete peak MiB | Selected peak MiB | Complete CPU ms | Selected CPU ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 61 | 31 | 5866708 | 64.672 | 11.863 | 294.439 | 300.816 |
| 62 | 32 | 5234922 | 60.446 | 11.396 | 252.922 | 260.296 |
| 63 | 14 | 3404355 | 42.085 | 11.997 | 162.936 | 167.914 |

Medians use roughly 1-ms process engine-heap sampling. Heap retention falls about
71–82%; CPU is slightly higher in these observations. Two ordinary campaign
workers and persistence validation also ran; CPU is descriptive and no precise
phone speed ratio is inferred. These particular journals contain no intervening
commands; separate command-bearing synthetic and historical tests verify selection.
Intermediate retained-tree/early-release comparisons remain preserved and are
not substituted for these final-source results. Exact inputs, runtime/reference
fingerprints, report hashes, medians and caveats are tracked in
[journal-selection-v55-evidence.json](journal-selection-v55-evidence.json).

The strict live native peak proxy still requires a new complete frozen run.
Physical Android PSS/frame times, battery/thermals and the large ordinary
full-snapshot preparation cost remain separate; no failed result below is relabeled.

## 0.7.54 read-only journal verification

The writer now verifies its actual reparsed journal patch directly against the
before/after captures, preserving the complete reconstruction semantics without
allocating another mutable copy of the entire old world. External recovery still
uses the unchanged reconstruction and full final codec validation. Integer
spelling, nesting bounds, all dictionary edits/erasures, unchanged output fields,
record identities/order, unused updates and nonmutation are checked. Eleven new
persistence checks compare against the original reconstruction, including 80
frozen generated cases, malformed inputs and all 32 immutable save fixtures.
Persistence 392 and native UI 667 pass; maintained total is 2714 in 28 suites.

Four alternating pairs use the same reparsed frame after 360 actual simulation
ticks on each retained input. Every pair reproduces the exact complete capture;
all source/input/world identities remain unchanged. Two ordinary campaign workers
had resumed, so this is a contended component comparison, not an isolated OS test.

| Input | Reconstruction CPU ms | Read-only CPU ms | Reconstruction temporary heap MiB | Read-only MiB |
| --- | ---: | ---: | ---: | ---: |
| Native-44 synthetic endpoint | 21.145 | 7.387 | 17.936 | 0.304 |
| Fresh-generator-2 ordinary twenty endpoint | 297.857 | 115.507 | 261.592 | 8.313 |

These are medians of four roughly 1-ms sampled process engine-heap observations.
The comparison reduces temporary verification heap about 98.3% / 96.8% and CPU
about 65.1% / 61.2%. It does not remove the separate full-snapshot preparation
cost or prove a passing native soak, Android PSS/frame times, battery or thermals.
Exact raw report/input/runtime fingerprints and medians are retained in
[delta-verification-v54-evidence.json](delta-verification-v54-evidence.json).
No save format, schema, content, generator or simulation rule changes.

## Frozen 0.7.53 quieter-host thirty-minute result: memory failure retained

Clean unchanged source `fbd5638ef564c52310871218873c5e00d5fe782d`
completed 1800.02223 measured seconds after sixty seconds of warmup at selected
2x, advancing 36001 ticks against 36000 nominal. All twenty residents remain;
sampled invariants/storage, logical time, full final codec round trip, unchanged
source and audio drain pass. All five diagnostic counters are zero. Lowest
one-second drawn FPS is 28.149, with no below-24 streak.

The **strict 20 MiB sampled peak proxy fails**: peak growth is 71915981 bytes
(68.6 MiB), ending growth 15310960 (14.6 MiB). The probe and independent second
audit remain Fail. This is a temporary allocation observation, not proof of a
monotonic leak. Worker phases do not align between sixty-second samples in this
and the earlier run, so their peaks are not a causal before/after measurement.
The final complete payload is byte-identical to the native-44 endpoint, canonical
`4a8fee28b0a01de385fc3bb8bfe48f7df5706c1b291760e7dca36c530303f881`.

The same retained ration-enabled input is used without grants or refills. Two
task-owned ordinary campaign workers were suspended/resumed by exact process
identity; both resume states were independently confirmed. Short headless source
checks and one exploratory raid pair also ran; no second graphical Godot ran.
This is a quieter host, not a pristine benchmark or physical release certificate.
Raw data is `native-soak-v6-fbd5638-quiet-host/`; exact source/completion/probe/
audit/save and scheduling hashes are tracked in
[native-soak-v53-evidence.json](native-soak-v53-evidence.json).
The separate 0.7.54 journal comparison above does not relabel this failed run.

## 0.7.53 bounded snapshot preparation: paired local evidence

The in-memory preparation path now encodes sorted fields and top-level arrays
in blocks of at most 256 items. Its private decoder rereads the actual UTF-8
buffer, checks complete byte coverage and all key/colon/comma/bracket/span
boundaries, and applies native JSON parsing plus the original depth/integer/map/
tile rules to every block. Full codec schema/reference/conservation validation
and exact capture equality still run. The private decoded tree is released
before the full payload text/envelope is materialized. External decoding,
64 MiB bounds, immutable capture ownership, digests and exact publish readback
are unchanged. This does not replace verification with a success flag.

A separately retained e8336e4 full-tree implementation supplies the reference.
Four alternating pairs for each exact retained input match full payload bytes,
canonical hash, validation and capture identity. Every pair also checks all 32
immutable save fixtures; no source/input/expected value changes during a run.
Twenty-seven new persistence checks include block boundaries 0/1/255/256/257/
511/512/513, grammar/coverage corruption, depth and malformed value rejection,
nonaliasing, full external codec, conservation and generated revision-2 saves.
Persistence 377 and native UI 667 pass; historical replay preserves 62 commands,
both reviewed hashes and foreign save continuation. Maintained total is 2699.

| Retained input | Old median CPU ms | New median CPU ms | Old sampled temporary heap MiB | New MiB |
| --- | ---: | ---: | ---: | ---: |
| Synthetic native-44 endpoint | 270.283 | 274.643 | 38.961 | 29.489 |
| Ordinary twenty-person 96-day endpoint | 2358.381 | 2415.437 | 311.573 | 239.034 |

Sampled temporary peak falls about 24.3%/23.3%; CPU cost rises about 1.6%/2.4%
on this contended Mac. Baselines include the retained reference text, and roughly
1 ms sampling is a process engine-heap observation. Ordinary preparation still
has a large 239 MiB temporary peak; neither result certifies Android PSS or the
separate native thirty-minute peak/fps proxy. The completed frozen 0.7.53 run
above still fails the peak proxy; the older failed 0.7.44 result remains unchanged.

Exact inputs: native-44 endpoint SHA-256
`00475035bf565d9e27afc7c5e99eed28be3856c1853175f63772d1d007190fda`,
ordinary twenty endpoint
`41495c97032fcb2bd56317b927ba55eea16332ac0a3866c835842b781d311175`.
Reports `snapshot-stream-v53-final-stress.json` /
`snapshot-stream-v53-ordinary20-comparison.json` have SHA-256
`c5cc2a7839b82bc460cb0ecdc5e09973513494bf23567f59f5bff6626a70af85` /
`1e9f0b108d763e2e4cdd4caec36fc96f88a0b86359c1567fc8cd28db6bb466a1`.
The compact tracked [snapshot-encoding-v53-evidence.json](snapshot-encoding-v53-evidence.json)
retains exact medians, hashes and local check evidence; the raw reports retain
all executed runtime/catalog/reference-source fingerprints. One trailing test-file
blank line was removed after measurement; the evidence summary retains both
source digests and the exact reconstructible text-only difference.

## Frozen 0.7.44 quieter-host thirty-minute result

Clean source `cd5d75141fc662761ffd0acc78c3723754c581dc` uses the same
ration-enabled input retained below, with both save-memory improvements.
After sixty seconds of warmup, the probe runs 1,800.03343 measured seconds at
selected 2x and completes all 36,000 nominal logical ticks. Twenty residents
survive; sampled invariants/storage, final exact snapshot round trip, unchanged
source and audio drain pass. Every diagnostic counter is zero. Lowest one-second
FPS is 28.117, with no below-24 streak. The ending synthetic load remains 569
structures, 1,058 positive stacks, 2,264 job records and 99 active targets.

Ending heap growth is 15,303,720 bytes (14.6 MiB); sampled peak is 23,889,077
(22.8 MiB). **The unchanged strict 20 MiB peak proxy fails**, so the complete
probe and independent audit remain Fail. Ending growth alone does not satisfy
that proxy. This macOS engine-heap observation does not measure Android PSS,
battery, thermals, current phone frame times or the separate full stress gate.
Headless ordinary campaign processes were SIGSTOP/SIGCONT around measurement;
their source and reports were preserved. Exact PIDs and resume time are retained
in `native-soak-v6-cd5d751-campaign-scheduling.json`. Short tool/unit checks still
ran on the same host; this was not a pristine OS benchmark.

Raw directory: `native-soak-v6-cd5d751-quiet-host/`. SHA-256:

| Evidence | SHA-256 |
| --- | --- |
| source.json | `fc0d4115ae11e4f8f58869b4113dc1c33d4a95f8dbd0c17bfe44b06fe4a6145a` |
| completion.json | `1dd53f7e59fcd94084ec3f0f1a9da61b1db8d6063c86e7a174595889177543b9` |
| probe.json | `f9552d7d4252430fda3a205843d0c2658987021cb32ac6d689e653fb8522c8dc` |
| audit.json | `993a23ebe5bb4b4cf27e5bc87daf2bc53d153026c1a980892893c8d64ddf638e` |
| Final snapshot | `00475035bf565d9e27afc7c5e99eed28be3856c1853175f63772d1d007190fda` |

Final canonical hash:
`4a8fee28b0a01de385fc3bb8bfe48f7df5706c1b291760e7dca36c530303f881`.
Earlier failed storage, starvation and heap results below remain unchanged.

## Frozen 0.7.39 ration-enabled thirty-minute result

The new input queues the ordinary food-policy command so that residents can eat
its existing reserve of travel rations. Clean frozen source
`f5868772d3e6b93edfd383c2d1d168b87b226425`, content v6/schema 23, ran
1,800.01258 measured seconds after sixty seconds of warmup at selected 2x.
All 36,000 expected ticks ran, from 3,002 to 39,002; all twenty residents survive
and every sampled invariant/storage check, final save round trip, source check
and audio drain passes. All five diagnostic counters remain zero. Ending load
is 569 structures, 1,058 positive stacks, 2,264 job records, 99 active
construction/production targets, 192 crop tiles, twelve domestic animals and thirty-two wildlife.
Hostiles and visitors leave through ordinary simulation. This is a changing
synthetic colony, with concurrent headless tests/campaigns on the same Mac.

**The native probe and independent audit fail the unchanged memory gate.**
Engine heap grows 26,896,076 bytes by the post-measurement drain; its sampled
peak increase is 58,547,825 bytes. The first large peak is at sixty measured
seconds. The thirty-minute FPS-floor proxy passes (lowest one-second window
27.911 FPS; no consecutive below-24 window), but this is not the separate
Android p95/p99 or PSS requirement. Frame gaps max at 112.437 ms, with 275/53,974
above 50 ms. Session/batch max is 100.909/98.274 ms; map-update mean/max is
4.001/16.045 ms; save-capture mean/max is 7.417/17.869 ms. Keep this complete
failed result; the next allocation fix must earn new evidence.

Raw directory: `reports/native-soak-v6-f586877-rations/`. SHA-256:

| Evidence | SHA-256 |
| --- | --- |
| Initial snapshot | `6a3d3c4636802ca2374e48c5d423bfd6d939c82e4cd3e179583b21324c76c774` |
| source.json | `94c67a96dc5ef386ad99657f81f1551dce8b2ca5988dc360e55f536fcca6035d` |
| completion.json | `ad59f96675845eb310b78f48ee6b175f4cbc103690f68e3124f8b702339b08c9` |
| probe.json | `4767cf000598ee2a6d69222e0f30df5120aa7aa619debd54715f24efbe63705d` |
| audit.json | `309e3926567334ce59f50433880a78267accb41b395f49a85dce96332997d1da` |
| Final snapshot | `d9e17fa699e55192a5fe7ee59cc0a60bc75353083388a6d774ef31112c987fa8` |

Final canonical hash is
`3cdeb39092ecb0d5a1a4a17e898330a0b22b7d86ad3de1b7217ce2cc7e31890d`.
This result does not replace or amend any earlier failed starvation/storage soak.

## 0.7.41 retaining the already-owned journal base

Only background writers use the new CapturedStore. After a successful save,
journal append or prepared rotation, it retains the exact recursively read-only
capture that the worker already owns. The live mutable world never crosses the
thread boundary. Normal direct ColonyStore calls still deep-copy their durable
base. Capture history reuses unchanged immutable records; no historical row is
deleted, reordered or compacted, and no save format or simulator rule changes.

Four alternating headless pairs on the retained 0.7.39 endpoint compare the old
deep-copy retention with owned retention. Complete payloads match, source/input
bytes and canonical state stay unchanged, and owned results share capture identity.
Median CPU is 8,510.5 versus 34 microseconds. The old retained allocation is
17,043,556 bytes (16.25 MiB); owned retention adds no payload allocation (the
counter moves by -128 bytes of fixed local overhead). This measures one retention
step, not whole-save peaks, frame rate, PSS or a passing longevity probe.
Raw `owned-base-v41-profile.json` SHA-256:
`0da77374703987d0aba6656dac3669fa56a702d9f86d5b25f9b2c8cb8a37cac9`.
Eight new persistence checks cover direct mutable-world isolation, capture identity,
unchanged history sharing, pending command recovery/one-time continuation, prepared
catch-up and cache replacement. Existing asynchronous failure/retry/crash checks
also pass. A new frozen thirty-minute test remains necessary.


## 0.7.42 lower snapshot-preparation peak

Preparation still generates the exact normal envelope and enforces its existing
64 MiB limit, then releases that temporary wrapper before parsing its own payload.
Its private decoder consumes only the fresh, unaliased JSON tree, replacing
encoded IDs/maps/coordinates in place. It never mutates the immutable capture
or the live world. Public ColonyState.unpack and the external full codec remain
unchanged. Full schema/reference/conservation checks, catalog and identity checks,
exact payload comparison, digest checks and staged byte readback remain required.

PreparationReadTests retains the complete original 6f4dc91 preparation method as
an independent oracle. Thirteen new checks include full four/twenty-person
preparation and external decoding, mutable/missing-identity/wrong-catalog/schema
rejection, parsed-container ownership, scalar/map/tile/depth boundaries, four
hundred encoded representations including Unicode, and all thirty-two immutable
save fixtures after their normal migration. Source bytes/world state do not
change. Persistence passes 345 including existing asynchronous crash/retry paths.

On the same retained 0.7.39 endpoint, four final alternating background pairs
produce identical payload text, digest and validated state. Median CPU is
339,662/313,252 microseconds (original/current); sampled temporary engine-heap
growth is 81,678,512/40,851,078 bytes, approximately halved. Sampling is every
1 ms in a headless comparison with concurrent headless campaigns/native soak;
these are CPU/heap observations, not whole-session memory or physical Android
certification. Runtime/profile/oracle source hashes and unchanged input/canonical
state are recorded. Final raw report preparation-v42-runtime-identity-final.json
SHA-256 b420f354e583e91e8dedc96a3986165a4b3d7e1284b9caae7617898c1ed52f43.
Earlier payload-only and owned-tree experiments retain their exact executed
programs and hashes under ignored reports/preparation-v42-sources/. The separate
frozen 0.7.41 native soak remains in progress; it does not include this change.


## Frozen 0.7.41 result — durable guard pause

The first owned-journal-base probe at clean frozen
6f4dc91072b8e45e098de9d4c0fe9399d6d13e43 fails at 1,364.756837 measured seconds,
not the requested 1,800. Initial/final ticks are 3,002/30,296, 27,294 logical ticks
against 27,295 nominal: time keeps up before stopping. The durable-save guard
pauses once while a writer is busy; there is no storage error or alert. All twenty
residents remain alive and every sampled invariant, final codec round trip,
source check and audio drain passes. Ending heap growth is 13,718,932 bytes,
sampled peak 53,558,932. FPS-floor proxy passes. Duration, continuous requested
speed and peak-memory checks fail. This does not certify a thirty-minute soak.

Concurrent headless campaigns, local builds and CI artifact transfers were active;
they are potential host contention, not a demonstrated cause. Do not relax the
1.75-second durable-progress guard to pass. The later preparation change is not
in this source. The next latest-source probe reduces host contention by temporarily
suspending ordinary headless campaigns; record that scheduling in their wall times.

Raw directory reports/native-soak-v6-6f4dc91-owned/. SHA-256:

| Evidence | SHA-256 |
| --- | --- |
| source.json | `1a83142be89e2b18a99121cd5c52c87a44113b8c79d690ca26ecadabd8998573` |
| completion.json | `14821375ed34fb2a9aff73e535801e048c96404ee94367debd1a531e9c0f3e9c` |
| probe.json | `23a18bd3af25ff942313c9418ac1cc4ccfbbef47236de9f811f1343bccad88b5` |
| audit.json | `35b337da7ac1665b2e018eb65c59f58f371487b549ea2d2d78a022da925889bd` |
| Final snapshot | `2ededd60739c5a6d59b2638a1e797b67a14371d7bf9b92c483b1ea5da536730e` |

Canonical endpoint c873837a869f043e75a245bd654b73d80ea4cccc0f53d4d67027f71be917bc3e.


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


## 0.7.37 fresh-colony map rendering

Resource refresh was measured separately through a presentation-only observer:
in a fresh generated Meadow colony at the widest 2-unit zoom, 3,031 resources
form 1,192 row/depth groups. Reusing unchanged membership reduces the native
18-second/4x map-update median/p95 from 12.228/12.639 to 1.868/1.972 ms;
resource refresh median drops 11.858 to 1.521 ms. Final close-camera map update
is 0.314/0.355 ms median/p95. These are Apple M5 Pro/macOS/Balanced30 observations
with concurrent headless validation, 541 callbacks each, ticks 1,800–2,521,
unchanged source per run and clean invariants. They do not predict a phone ratio.
Four alternating 100-call CPU pairs against the complete 603c1d0 refresh retain
exact world/row data; eleven real image-buffer comparisons remain identical across
membership, growth, tint, selection, camera and adoption changes. STATUS.md records
full source hashes, validation and retained first-test failures. No simulation
rules, target graphics quality, or authoritative ticks were changed.


## Optional prepared-ration longevity input

0.7.39 adds --use-rations true to create_stress_snapshot.gd. This queues the normal
food_policy command before measurement, allowing the existing nonperishable food
reserve. It defaults off; the original failed fixture/input is unchanged. Complete
initial payloads differ only in pending_commands and next_command_id. The saved
command must round-trip unapplied and execute through the first normal tick.
No inventory/actor/health grant or refill occurs during measurement. This prepares
food access, not ordinary shared admission or constant all-actor load. Keep original
failures, declare the new input hash and report ending counts. A prepared run must
pass its own duration/population/heap/source checks; no result is inferred from
configuration. The producer refuses existing output files rather than overwriting
retained evidence.
