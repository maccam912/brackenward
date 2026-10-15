# Ordinary campaign evidence — 12 October 2026

## Frozen v6 96-day vegetarian Charter matrix

All **four cases pass** at clean, unchanged
`ffdce480994ad43c46dee84c5b1ba34d3f17e330` (0.7.28-m7, content v6/schema 23),
including the independent completion audit. Seed 104729 runs from tick 1,800 to
693,000 using ordinary public commands, completes all five stages and the
ceremony, and retains Continue for at least another full day. Every case keeps
eight living residents and passes 2,304 invariant checks (9,216 total), a valid
final save and exact round trip. All four record zero zero-fullness and
starvation-grace-exceeded ticks. Minimum health is reported separately; this
is not a zero-damage claim or physical/human certification.

| Site / mode | Ceremony end | Minimum health | Final canonical hash | Snapshot SHA-256 |
| --- | ---: | ---: | --- | --- |
| meadow_reach / Standard | 270,901 | 82 | `475d85b56fbf4e33d2168212254e665459ac46ab339848de07fe6a9a669d32aa` | `1c193032732a345c39542c899535ad867b701ce0067892380c352a13a7feab8e` |
| pine_shelf / Standard | 391,801 | 87 | `be20dd62ee25061a500ec8e3507ca18d2b47ccb4c77c01e21aa17aa1843ee749` | `17533c1b1affee596bb57efebb83b7e7abb3bba687a171cc6432fa9f2016eae3` |
| reed_bend / Standard | 319,801 | 100 | `df34756479c8b1a0e5954580bf1b0875b0e264392515ae0cef0f2c81fb08a5b0` | `d53a7a36263b235879e5cfa5fb51f3e603d771b83f63d8e5eb43331965cf6ff3` |
| pine_shelf / Hearthside | 312,601 | 100 | `dcf8f8598a5fc7f270c05772ea8550c8ea476423798e67322554a68a99d9cc16` | `7680d7ee975485ce279f7e672a023886961615e4692e607c84332f7cd5153b5e` |

The current 0.7.32 loading audit preserves all four complete payloads, source
bytes, invariants and round trips without advancing time. It is a loading audit,
not a claim that a new 96-day campaign ran on 0.7.32. Frozen raw evidence remains
in `reports/charter-release-v6-ffdce48/`; every exit/log/snapshot and unchanged
source is checked. The revised-policy content-v6 Winter matrix now passes all thirty cases; see WINTER_MATRIX.md.

| Evidence | SHA-256 |
| --- | --- |
| source.json | `4d755562a872851158d7695b55aa9743fa8f74d5096f420f0d83b646101d45f1` |
| completion.json | `120d167d9d81d1011eee18cc536ef0ba62856ad4da08e6d4722b9adf5880ffcf` |
| audit.json | `1c1a7a6951249e840fed1369953d4e4d9d5abb732882c6bf35229447a5b570f6` |
| Current 0.7.32 loading audit | `a8301fabb2e6f2b6ffaf5d7f4bf4d81cddcbb69f259583fa6808595eaa183ac5` |


### Independent no-external-trade coverage

The same four retained v6 runs also pass tools/audit_trade_free_charters.py.
Every original report/log/initial/final snapshot and source/completion/audit file
keeps its bytes. All original endpoint hashes and ordinary-play Charter gates
match. Executed commands and pending commands contain no trade/trade_cancel;
all historical jobs contain no trade work; exchange history and traded_in are
empty, and no opportunity has a reward receipt. Expeditions and raid tribute
are permitted; traded_out includes tribute and is not mislabeled as barter.
This is an additional audit of the already completed runs, not new simulations
or ninety-six days after the Charter. Raw report charter-v6-no-trade-v40-audit.json
SHA-256 775f4b8d763730867c8b935ad5a6823463d2cd3cf91493443eea89ec248fca10.
Three Python checks exercise both command queues and hidden completed/canceled
transaction records and verify that the audit does not mutate its inputs.


## Frozen v4 96-day vegetarian Charter matrix

All **four cases pass** at clean, unchanged cf344711ad8701f5d7fe822bf6c8623d1dacda56
(0.7.20-m7, content v4/schema 23). The public-command policy runs seed 104729 from
1,800 to 693,000, completing all five stages, ceremony and Continue, then at least
one full further day. Every case retains eight living residents, no departure,
valid final save/round trip and 2,304 invariant checks (9,216 total). All process
exits, logs, snapshots and unchanged source are checked independently.

| Site / mode | Ceremony end | Minimum health | Zero-fullness ticks | Beyond-grace ticks | Final canonical hash | Snapshot SHA-256 |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| Meadow / Standard | 399301 | 4 | 71392 | 56992 | `03ce98cf58bb22437ea5cab6aa7bf64f73212259b10ca306c3dabfeecd069bbb` | `0c856dbbcecd2560dbf1535b464a9be8b77cb66c01fbdcd1310eaa2248cd7953` |
| Pine / Standard | 373501 | 90 | 0 | 0 | `957e6026d8c9fd1fcd2ed3a1fbfe1aba3c565fcd9fd681770b6f08e231aed920` | `79d05439afe6e092e8e52dab3da77cd63af04191ca1c703840824758661ab480` |
| Reed / Standard | 262801 | 100 | 0 | 0 | `708830f857dd0ff9f66838aac3bb0a3b5b91807dd1fafd23ee44455341e639b8` | `1f94159ca09ab2c69ec789806245391dc0a489126f3333ca4243157b8bb9b076` |
| Pine / Hearthside | 291001 | 100 | 0 | 0 | `d86d0cef1ad350b05d42993d005d085799ddf0182f1e6852f4eec6927ab730db` | `668f3f666fb65b48c4c2878213a074f481ffb7f158b18cdab8d46959a5ea4bca` |

Meadow reaches its Charter after serious shortages; this is a full Charter/continue
pass, not a zero-starvation or final balance certificate. V5 separately corrects
an observed low-rest/hunger work interruption cycle, so new v5 long campaigns are
required rather than relabeling these v4 simulations.

| Retained evidence | SHA-256 |
| --- | --- |
| source.json | `6197d08046aad367577fc7d1aea5d3fa6b64677c89c74e268542a6f9a811a142` |
| completion.json | `4f6219b528a047e50d473f244d06c6698f7cb7fa7c36b3f7933433c154a9eb17` |
| independent audit.json | `9a8b767d32be42fdce7ac08b4eea3b2adfb81a2217e6ebc47328bcc10837c69f` |
| Current v5 loading audit | `c5b10a30cccd9867c9aafcdcb1fc7bb238e550a37b382c7dda48c041a9e43f3d` |

Raw data stays in ignored charter-release-v4-cf34471/ and
charter-v4-current25-audit.json. The v5 audit checks all four source snapshot byte
hashes, every acknowledged field under its original content header, invariants
and round trips without advancing time or rewriting files. It is migration
validation, not another campaign run. Older results below retain their own scope.


These local macOS runs use Godot 4.7.2, colony-v2 definitions, generator 1,
seed 104729 and public simulation commands. Policies do not spawn resources,
change weather, disable incidents, instant-build or assign nonexistent workers.
Reports and initial/final snapshots are local ignored artifacts beside this file.
They are scenario evidence, not device, comprehension or complete release gates.

| Scenario | Site / mode | Result | Ticks / wall time | Health and food |
| --- | --- | --- | --- | --- |
| First eight days | Meadow Reach / Standard | Pass | 57,600 / 69.782 s | Four residents; minimum health 100; 7.25 food days |
| First eight days | Pine Shelf / Standard | Pass | 57,600 / 81.167 s | Four residents; minimum health 100; 4.35 food days |
| First eight days | Reed Bend / Standard | Pass | 57,600 / 75.401 s | Four residents; minimum health 100; 4.30 food days |
| First Winter | Meadow Reach / Standard | Pass | 237,600 / 2,406.458 s | Eight residents; minimum health 100; 8.00 food days |

First-week artifacts are `first-week-104729-{meadow,pine,reed}.json` and their
`-initial.brackenward` / `-final.brackenward` companions. Each passed 192
conservation/reservation checks, completed 31 improvements and never exceeded
the starvation grace period. The first-winter files use
`first-winter-104729-meadow`; 792 invariant checks passed, 58 improvements
completed, Shelter and Provision were earned, and nobody died or departed.
Its final canonical hash is
`143d10ae9eead0453ece896ed585f0aac1d6f755ef71908a7a797bc05fe45496`.

The Winter trace resolved four announced raids by physically delivering quoted
supplies. Saved raid records retain completed payment jobs and the reason that
supplies arrived; budgets 2, 2, 3 and 4 required 16, 16, 24 and 32 barter value.
No hostile arrival occurred. Warning/resolution times are 52,200/53,048,
73,800/74,856, 131,400/132,014 and 217,800/218,885. This proves that supply
response and recovery occurred; it does not exercise live raid combat.

These early runs began during concurrent, unreleased schema-20 development.
Their Chronicle records predate the `links` field and some final salience rules.
Original files remain unchanged. Their old unlinked narrative facts are not
evidence of the final causal Chronicle implementation or current save loading.
The separately labeled profiling copy backfills only empty links and
request-offered salience; it is not used as an ordinary campaign certificate.

The first-winter run records 4,337 zero-fullness citizen-ticks, all within grace
and with no health loss. The vegetarian policy revealed recurring overnight
zero-fullness warnings despite stocked food: sleep only interrupted at zero.
A separate scheduler fix now wakes hungry sleepers at 350 fullness while
protecting life-critical rest. Current-code continuations are testing that fix.

`tools/simulate.gd` now verifies every daily/final snapshot by decoding and
comparing its canonical state. `--resume REPORT` verifies the report/snapshot
hash, tick, seed, site and mode; retains the original starting snapshot and
full command lineage; and treats `--days` as additional simulated days.
One day plus a resumed day exactly matched uninterrupted two-day state,
commands, policy decisions, health counters and daily samples before the
separate sleep-rule change.

Full vegetarian Charter runs remain in progress. The policy found another
honest blocker: later construction left only three usable table seats. The
public supper explanation identified it. The revised planner protects seats
and orders additional physical tables; it does not waive the supper gate.
The verified Meadow Reach continuation has now earned Shelter, Provision,
Connection and Refuge. Two distinct expeditions returned and restored the
causeway. Its supper consumed eight actual meals and recorded eight distinct
residents completing their seated half-hour attendance; the completion tick
was 200,329. At tick 237,600 (Day 34), all eight residents were healthy, minimum
health remained 100, the starvation grace period had never been exceeded, and
food runway was 7 days 11:15. The beacon still awaited stone, so the final
ceremony, Continue action and a further full saved day remain unproven.
The unchanged resume source is `vegetarian-charter-main-lifecycle-source`,
canonical hash `347a9fe180693c0cbf7a0985b666918b53385423ad97a63a42407c3eb4489d8b`.

That snapshot also exposed abandoned personal activities: interrupted sleep
and failed meal reservations had remained in the shared queue. The scheduler
now cancels personal activities when released or blocked and reconciles old
unowned activities on its first work pass. On the real snapshot, active jobs
fell from 724 to 64 while all 4,990 history records and the complete material
ledger remained intact. Invariants and a canonical save round trip passed;
280 scheduler, expedition, Charter, care, defense and construction checks
passed. Current continuations exercise the fix through ordinary play.

A further 1,000 ticks from that same frozen Day 34 snapshot produced identical
canonical state before and after the final local lookup optimizations:
`182085ad25ce9dbc089ed2a50f5d69cfe16580790a0410e6b26a3dd4e26f2ec7`.
Measured normal simulation time fell from 27.66 to 15.61 seconds with the
combined production and hauling lookup changes. The instrumented
production phase fell from 12.14 to 2.09 seconds. Production's 37 checks include
multiple stations sharing a Maintain target and duplicate orders on one station;
newly queued work still affects later orders within the same pass.

Neither this document nor the scenario runner marks an incomplete Charter as
complete. Other sites/modes, all remaining long-run scenarios and cross-platform
replay remain separate gates.

## Quota stop and exact resume points

All four active campaign processes were stopped when weekly usage reached 9%
remaining. Their latest daily report, original starting snapshot and final
snapshot were copied unchanged to the following stable local paths after
checking each report's canonical hash against its snapshot payload checksum.
Every checkpoint had already passed the runner's encode/decode verification.
All retain complete accepted-command and policy-decision lineage. No campaign
has completed the final Charter ceremony, Continue action or subsequent full day.

| Resume report (relative to repository root) | Saved state | Canonical hash |
| --- | --- | --- |
| `reports/quota-stop-20261012-meadow-standard.json` | Day 36, tick 252000; eight residents; four stages; 191 portions | `23712e66f22eb3cb0a0f751e57bb1be2252637a5bc886de96161e372c2cf95cb` |
| `reports/quota-stop-20261012-pine-hearthside.json` | Day 35, tick 244800; eight residents; two stages; 76 portions | `0b602d782eb5b38434eb63fa18f186bd6a183c3950925bf10541729941932f68` |
| `reports/quota-stop-20261012-reed-standard.json` | Day 7, tick 43200; five residents; one stage; 48 portions | `40cab44857c6bb8b99263b2eccd42f216888a17bacb08d8dc8e2fa6126657c41` |
| `reports/quota-stop-20261012-pine-standard.json` | Day 10, tick 64800; six residents; one stage; 27 portions | `45b6b8ed9d6320b8fc700133e22b32cbc663b37e2281c5de5190820f25190479` |

Each report has matching `-initial.brackenward` and `-final.brackenward`
companions. All four checkpoints retain minimum health 100 and zero ticks
beyond the starvation grace period. `reports/quota-stop-20261012.json` records
the exact sources and stopped process identities. Meadow's beacon remains
blocked on stone (53 physical units against its 60-unit requirement); Pine
Hearthside still has material blockers for its kilns, smelter and beacon.
The two Standard campaigns
that stalled early remain useful reproductions of repeated, expensive path
searches toward an unreachable assigned bed; they are not successful full runs.
Resume only after the user authorizes more work, using `--resume` with one of
the reports above, its matching site/mode and an additional day count.


## 13 October continuation and completed Meadow Reach Charter

The new user instruction resumes implementation/polish to a 50% weekly-remaining
cutoff. Prior quota stops are historical. The saved Meadow/Pine campaigns exposed
a validator error on canceled raid-payment history after retry; the corrected
validator restores the original exact report hashes without modifying state.
The new shared-tile eating correction also lets waiting travelers eat while
another resident rests at the cart.

`reports/charter-verified-20261013-meadow.json` is a passing ordinary vegetarian
Charter through tick 316,800. Its matching initial/final snapshots verify. All
five stages were earned; the ceremony completed at tick 271,801 and Continue
settlement was used. The colony continued for over six more days, retaining
eight living residents, minimum health 100, zero starvation-grace exceedance,
204 portions and 9 days 05:45 stored runway. All 1,050 invariant checkpoints
passed; 859 public commands are retained. No meat/leather was consumed and
Husbandry was not researched. The lineage includes 3,908 zero-fullness
citizen-ticks within the grace period, so it does not certify zero hunger.
Final canonical hash:
`fc0c571da69ae1bd0694b6f529cab8227c9d91a71894c2f310b67c449728239b`.

Other current runs use `charter-verified-20261013-{pine-standard,reed,pine-hearthside}`.
The Reed source was copied with matching payload/report SHA-256 before its
old process was stopped; `needs-checkpoint-preservation.json` records the exact
source and frozen copy. These are still in-progress scenarios. The phone
performance report triggered separate periodic-save and reachability fixes;
none of this campaign evidence certifies physical-device smoothness or M7.


The preparation correction raises only selected Preparing/Ready travelers'
eating/rest triggers to the existing hard departure minimum of 500, using
normal physical needs tasks. It grants no supplies or need points. The three
new continuations use `charter-prepared-20261013-*`, from exact frozen sources
listed in `preparation-checkpoint-preservation.json`. Earlier `charter-verified-*`
processes were stopped after copying a complete matching daily checkpoint.

13 October Hearthside completion: `charter-planner-20261013-pine-hearthside`
passes the ordinary vegetarian Charter through tick 619,200 (Day 87), with
all five stages, ceremony ending at 581,101, Continue and more than five
subsequent days. Eight residents remain alive; minimum health 100; no
starvation-grace exceedance; 2,058 invariant checkpoints; exact saved-world
round trip. The lineage includes earlier real preparation delays, canceled
spoiled/season-closed packing and public stockpile expansion, not state grants.
Canonical `e89ab3b4364dfc1011c4adc478847f8ebd0f11cf6f8ece347a7d66d295d165c1`.
This mode/site certificate is separate from current-code seed sweeps and
physical-device gates. Standard Pine/Reed continuations remain active.

14 October bed/access continuation: `bed-access-checkpoint-preservation.json`
records the untouched Pine tick-439,200 report/snapshot (canonical
`06eda88adb558208d07e35565301712b605f7784d0a21bfdc31b8de5cd65111a`)
and Reed tick-453,600 daily report/snapshot (canonical
`eab397a89d5a29593a03c26ad7396fefa249f29add285be8ab62a80ac9d13a84`).
Schema-20 Pine loads through the explicit revision-only schema-21 migration;
the original envelope digest must still exactly match its source report.
`charter-access-20261014-*` continues these worlds with public bed assignment
and physical maintenance work. These continuations are in progress, with no
new complete-Charter claim. The interrupted initial Pine attempt had not
published a new daily checkpoint; its original verified input remains the
continuation source.

14 October Pine Standard completion: `charter-complete-20261014-pine-standard`
passes through tick 489,600 (Day 69), all five stages, ceremony completion at
440,401 and Continue with almost seven subsequent game days. Eight residents
remain alive, minimum health 100, zero zero-fullness or starvation-grace-
exceeded citizen-ticks, and 1,626 invariant checkpoints pass. The final
report, payload SHA and saved-world round trip match exactly. Canonical:
`910fb2328b22d2f878ec2ccb7e1c73452983b8f9d9ae99969dc1174601f164ad`.
The frozen daily input at tick 482,400 is recorded in
`stack-query-checkpoint-preservation.json`. No supplies, skills, needs or
construction progress were granted; bed assignment and doorway demolition
use real public commands/work. Historical reports/snapshots remain untouched.
Reed's ongoing ordinary run now also has all stages, ceremony and Continue;
its final later-day continuation still needs a completion report, with the
already recorded historical health/starvation limit retained.

14 October Reed Standard completion: `charter-access-20261014-reed` passes
through tick 583,200 (Day 82), all five stages, ceremony completion at 535,201,
and Continue with almost seven later days. Eight residents remain alive,
all currently at 100 health, and 1,938 invariant checkpoints pass. The original
report/payload SHA and final snapshot round trip agree. Canonical:
`4b93eb710af1c3e036029c17a8a051fcf7ee58fede772fe37d7bdcb3e4b7b31d`.
The lineage retains minimum health 64, 20,944 zero-fullness citizen-ticks and
4,965 beyond starvation grace from earlier runs; those counters did not
increase in the latest continuation. This is a completed vegetarian Charter,
not a zero-hunger or zero-damage certificate. No meat/leather was consumed,
Husbandry was not researched and the two trips used real supplies/people.

The M6 ordinary campaign set now includes all three Standard sites and Pine
Hearthside, with ceremony, Continue and later play. These local simulation
certificates remain separate from current-source Winter sweeps, M7 media,
accessibility/stress work, physical Android and human-comprehension gates.

14 October frozen first-Winter matrix: all 30 runs at exactly `88ee5e8` pass
through tick 239,400 with eight living residents, minimum health 100 and no hunger
or starvation-grace violations. A separate fail-closed audit checks exact source,
logs, report/snapshot pairs, unique combinations and process exits. Current schema-22
loading preserves all thirty old gameplay payloads exactly after removing only
declared cosmetics/header metadata; source files remain untouched. Full source,
harness and evidence digests are in [WINTER_MATRIX.md](WINTER_MATRIX.md). This is
separate from a repeated full campaign under later presentation code and from
physical/human release gates.


## Frozen v3 Charter sweep — 14 October 2026

The four-case seed-104729 sweep pinned
`a853f3b23df147618cf8d522ab1c0233377e533f` requested 96 ordinary days per case.
It finished with source unchanged: one settlement loss and three one-hour timeouts,
**zero completed 96-day certificates**. No failed case was retried unchanged.
The independent audit fails as expected because the requested final reports do not
exist for the timeouts and Pine Standard lost its population. Verified periodic
snapshots remain useful partial evidence; they are not substituted for endpoints.

| Site / mode | Result | Last verified tick | Living | Minimum health | Beyond-grace ticks | Ceremony / Continue |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| Pine Shelf / Standard | Settlement lost | 155,759 (final) | 0 | 4 | 51,592 | Incomplete |
| Meadow Reach / Standard | One-hour timeout | 612,000 (partial) | 8 | 5 | 28,796 | Complete at 399,901 / yes |
| Reed Bend / Standard | One-hour timeout | 640,800 (partial) | 8 | 100 | 0 | Complete at 262,801 / yes |
| Pine Shelf / Hearthside | One-hour timeout | 676,800 (partial) | 8 | 100 | 0 | Complete at 291,001 / yes |

All listed partial snapshots have exact report/envelope checksums, codec round
trips and no recorded invariant failure. Their accumulated invariant checks are
2,034 / 2,130 / 2,250 in table order for the three timeouts. All three partials
completed five Charter stages and continued for many ordinary days afterward.
The Pine loss exposed the planner's missed Stand down interval; that planner uses
public commands and was corrected in 0.7.14. Manual player drafting rules did not
change. The immutable loss, crisis checkpoint, raw logs and bounded outcomes remain
retained in ignored local reports.

A separate clean run pinned `977313e33b848b469dab31bd45e5ece7c546b837` uses the
corrected planner for Pine Standard. It also reaches the one-hour bound. Its final
verified periodic snapshot is tick 612,000, eight living residents, minimum health
100, no beyond-grace ticks, all five stages, ceremony completed at 373,501 and
Continue. Its source is unchanged and its snapshot is retained as the provenance
for later performance fixtures. It is still a partial result, not a 96-day pass.

Raw old-sweep directory: `reports/charter-release-v3-a853f3b/`. SHA-256 digests:
source manifest `36d4aff20011a517b18d148ff25b4fb27ef1733fb9dcb9b35278a3fa36e5368c`;
completion `a1423b77e2d0646f51c5238932691c6791623ec1e23eafc9754e8540b3a91324`;
failed audit `e7efacb0a358c036651116e309d1d77447d02ab4bc6acf880ef5407f54c22a1d`.
The frozen checkouts are archived after completion, preserving recoverable Git
snapshots; all report/checkpoint evidence resides outside those checkouts.

These runs use colony-v3. They neither certify the later food-recovery v4 gameplay
nor replace the older v2 certificates above. The fresh v4 Winter matrix remains a
separate running validation. Physical-device, human and performance release gates
remain open.


Current 0.7.28/content v6 pure-loading audit passes all four pinned v4 Charter
endpoints, including every acknowledged field, original byte and round trip.
No simulation advances during migration. Report charter-v4-current28-audit.json
SHA-256 0143f08a723251fffc8933b5720fd0aa5f6e52cd9e9b31e45af32a7f80608f3a.
The observed v4 health/starvation figures above remain v4 results. Fresh v6
Charter/ceremony/Continue runs remain pending.


## Ninety-six additional post-Charter days completed

All four generator-1/content-v6 origins above now continue another 96 days at
clean frozen `4042af1cdd665b235b6f1f83ea64afe7dac15a5d`. Each progresses from
693,000 to 1,384,200, preserving the exact source endpoint link, original initial
snapshot and complete command prefix. Every case adds 2,304 invariant checks
(4,608 across the whole 192-day history), keeps exactly eight residents without
replacements/departures, and records zero zero-fullness/grace-exceeded ticks.
All retain at least one food day and complete/continued Charter state. Original
twenty-file input evidence remains unchanged. The independent second audit
passes all four; this meets the additional-days gate rather than counting the
original mid-campaign ceremony as that continuation.

| Site / mode | Minimum health over whole history | Final food ticks | Final canonical hash |
| --- | ---: | ---: | --- |
| meadow_reach / Standard | 82 | 38,526 | `ab3dd2a9c349fe82eed3156b9eb9f03078ff307faa95a52747cca739e2ad2124` |
| pine_shelf / Standard | 87 | 41,198 | `620dd8dc9fa10b03c2ebc038fa2035a7f2cab1d550fd188fe58031d64bce9c7a` |
| reed_bend / Standard | 100 | 45,935 | `68059749a9c089f7224bd1fa0624337887594a56c9afd7a0d5649c34fd38a0a2` |
| pine_shelf / Hearthside | 100 | 49,386 | `810fb20eb3f9f2bde17cbbb65fafb7078da247742994e0a751d04e24a964f92c` |

Raw outputs: `post-charter-v6-4042af1/`. Source SHA-256
`fb374339f71ec80d9f2d1d269a047cdfe12d8158d25a1dfe5583404a7b5a5b17`,
completion `dc2a7a3707c11528fe27d1018b62c8e6644b28ed650e900079efdbf5ee5dc59e`,
audit `381e5649fbf9b5330e2ea9378c52cd1f2173434ef35199ed09dd1416ff4f04e4`.
These are retained generator-1 campaigns. Fresh generator-2 Winter/Charter and
ordinary twenty-resident seasonal evidence have separate pending scopes.
