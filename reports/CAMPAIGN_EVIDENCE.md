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
Neither this document nor the scenario runner marks an incomplete Charter as
complete. Other sites/modes, all remaining long-run scenarios and cross-platform
replay remain separate gates.
