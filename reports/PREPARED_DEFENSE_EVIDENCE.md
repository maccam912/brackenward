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
| Defend | At tick 8700, Shelter and draft original residents 2, 3 and 4 at the midpoint of the announced boundary-to-cart approach, without Stand fast. Resident 1 shelters at the cart through the ordinary civilian system. | Normal boundary arrival at 9000; real movement, shelter and combat down at least one thief; retreat before the six-hour timer and with no theft or payment. All four survive and stand down. |
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

The interception audit also uses independent BFS distances and terrain/solid/
bridge rules: the recorded approach must be a contiguous shortest route and the
issued rally its midpoint. A teleport, invented bridge, detour, blocked tile or
cart rally cannot stand in for that plan.

The synthetic Python audit tests cover false successes such as timer/quota
escape, missing shelter, rejected/changed orders, incomplete delivery, extra
residents, swapped weapons, early arrival, changed warning history, resource
grants and missing evidence. Those tests are not thirty-map gameplay evidence.

## Frozen first attempt: cart defense fails 9 of 30

Clean source `a23033150de2bc6eb2c1581df6c84cce9c43f210` completed
all thirty distinct maps/entries. The original cart-rally plan passes **21/30**
armed defenses; exact physical ransom delivery passes **30/30**. All sixty
branches keep all four residents at health 100, with no zero-fullness ticks or
theft and accepted public commands. All initial geometry and eighteen inspected
goldens verify; the independent second audit retains the overall Fail result.

Every failed defense first retreats at tick 10800, the six-hour timer, with no
enemy downed at that point. Reed/max-seed later downs one while the party is
already retreating; this cannot satisfy the before-timer gate. No acceptance
condition, combat rule, damage, supplies or clock is changed to make that pass.
Raw evidence remains `defense-release-gen2-v6-a230331/`, with source/completion/
audit hashes and all thirty endpoint hashes in
[prepared-defense-v54-evidence.json](prepared-defense-v54-evidence.json).

The revised plan above intercepts the advertised approach. Its Pine/0 pilot
(previously a timer failure) and independent route/raw-save audit now pass:
defense retreats at 9958 with all four residents at health 100; ransom commits
at 10317. This mutable-source pilot alone did not certify thirty maps; the complete
frozen result follows below. The 25 Python audit checks pass, including six
independent route counterexamples.

## Revised frozen result: all thirty paired solutions pass

Clean unchanged source `6685958cc27e85dd0a5ab6ef836e939ed160a2b6`
passes **30/30 defense and 30/30 ransom** cases, including a separate second
audit. All thirty maps and entries are distinct. Every branch retains the four
original residents at health 100, no zero-fullness ticks, no theft, accepted
orders, active-incident reload and exact final snapshot/roundtrip. Defenses first
retreat at ticks 9366–10176, before the 10800 limit; physical ransom commits at
10297–10442. All normal geometry, eighteen inspected initial goldens and thirty
real shortest-route midpoint rallies independently verify. No combat rule,
clock, supplies, damage, equipment or actor position was edited for the new plan.

Raw evidence remains `defense-release-gen2-v6-6685958/`; the complete original
artifact manifest is unchanged. Source/completion/audit hashes and every endpoint
are tracked in [prepared-defense-v55-evidence.json](prepared-defense-v55-evidence.json).
The first frozen 21/30 cart-plan failure above is preserved separately.

Run and independently audit from the same frozen checkout, using a new empty
report directory:

```sh
python3 tools/defense_sweep.py --source /absolute/frozen/brackenward --report-dir /absolute/new/evidence --workers 2
python3 tools/defense_sweep.py --source /absolute/frozen/brackenward --report-dir /absolute/new/evidence --audit
```
