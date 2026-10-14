# Ordinary campaign evidence — 12 October 2026

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
