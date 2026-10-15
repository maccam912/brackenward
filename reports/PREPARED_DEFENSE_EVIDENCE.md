# Prepared defense and ransom release fixtures

This covers the specific 30-map raid-solution requirement in DESIGN.md §26.2.
It does not certify ordinary incident frequency, physical controls, or player
comprehension. The ordinary multi-season campaigns remain separate evidence.

## Protocol

`tools/defense_scenario.gd` creates a fresh generator-2 Standard colony with its
four original residents, starting weapons and supplies. It saves that complete
normal state, then calls `ColonyDefense.announce(world, 2)` once at tick 1800.
This announcement is the only prepared-fixture exception. The normal and
announced saves retain the exact changes for independent inspection: one raid,
one warning fact, its Chronicle entry, and the normal ID/RNG advancement.
No supplies, equipment, positions, terrain, weather, clocks, skills or combat
results are edited. Arrival retains the full 7200-tick warning.

Both solutions load the same exact announced snapshot:

| Branch | Public orders | Required outcome |
| --- | --- | --- |
| Defend | At tick 8700, Shelter and draft original residents 2, 3 and 4 at the supply cart, without Stand fast. Resident 1 shelters through the ordinary civilian system. | Normal boundary arrival at 9000; real movement, shelter and combat down at least one thief; retreat before the six-hour timer and with no theft or payment. All four survive and stand down. |
| Ransom | After actual arrival at 9000, offer the listed 16 wood; ordinary workers reserve and carry it to the announced meeting. | Real completed `raid_pay` job and exactly 16 wood traded out; no theft or injury; the same party retreats before the timer and the colony stands down. |

At tick 9120 each branch saves, fully decodes and resumes its active incident.
The defending party is still approaching; the ransom branch is held by the
normal payment ceasefire. This tests actual retained routes and incident clocks.
Every sixtieth tick checks invariants and records bounded actor observations.
Resolution retains transitions, enemy health, actual supplies, command receipts,
the full executed trace and a separately round-tripped final snapshot. A failed
or stopped simulation cannot pass from a report flag alone.

`tools/defense_sweep.py` runs ten fixed seeds at each of the three sites from one
clean, frozen checkout. Its second audit checks the raw snapshots and receipts,
the exact setup exception, all thirty independent map geometries, and the
eighteen applicable visually inspected initial goldens. It recomputes defense
and payment outcomes, requires thirty distinct normal map hashes, and retains a
SHA-256 manifest of every result/log/save. It never retries or overwrites a case.
The prototype CI job also runs the Meadow/104729 pair and its independent
raw-save audit, retaining every incident save/log. That single case cannot stand
in for the separate thirty-map release sweep.

The synthetic Python audit tests cover false successes such as timer/quota
escape, missing shelter, rejected/changed orders, incomplete delivery, extra
residents, swapped weapons, early arrival, changed warning history, resource
grants and missing evidence. Those tests are not thirty-map gameplay evidence.

## Current result

The draft harness and its 19 Python audit checks are prepared. The GDScript
parses. The exploratory Meadow/104729 pair and its independent raw-save audit
pass: both branches retain health 100; defense retreats at 10770 (only 30 ticks
before the six-hour limit), ransom pays physically at 10297. The final hashes are
`159e4914a1cc2e522ec92a97ee1a327fd9c600c8c67c23cf2961d386d9c16677`
and `4e098166641d140b53b282b55b6a9ea016183f8dc522dcb700919e6d14af601f`.
This mutable-source pilot is **not** a completed frozen 30-map result. Preserve
the first policy failure rather than changing the acceptance conditions to fit it.

Run and independently audit from the same frozen checkout, using a new empty
report directory:

```sh
python3 tools/defense_sweep.py --source /absolute/frozen/brackenward --report-dir /absolute/new/evidence --workers 2
python3 tools/defense_sweep.py --source /absolute/frozen/brackenward --report-dir /absolute/new/evidence --audit
```
