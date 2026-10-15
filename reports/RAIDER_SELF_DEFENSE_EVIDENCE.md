# Raider self-defense during interception

The v6 candidate filter applied the twelve-tile goods boundary to an enemy's
in-range attacks. A controlled adjacent guard with clear sight dealt damage
while the raider could not retaliate 88 tiles from its chosen meal stack. The
same actual simultaneous combat produced the expected five damage when that
existing stack was nearby, or when no goods target was assigned. All three
controlled worlds passed invariants. Original probes remain in
`defense-self-defense-v56-probe/`; these edited-position unit setups are separate
from ordinary-play release evidence.

Content v7 removes that goods-distance restriction from in-range defense.
Goods still determine enemy movement. Existing melee/bow damage, armor, fog,
sight, cooldown, nearest/ID targeting, ceasefire, downed neutrality and retreat
rules remain. Twenty added checks cover the same far/near/no-target fight with
full saves, exact weapon/range cases, recent undrafted aggressors, uninvolved
civilians, walls, payment/grace/retreat, existing cooldowns, neutral patients,
target order and continued movement toward goods. Defense passes 81.

Six v6 acknowledgements were captured on unmodified e4003fb before the rule
change, with a producer that refuses later sources. They include the exact old
replay/foreign checkpoint bytes, an actual tick72000 endpoint, far/near combat,
and a 600-tick old journal. Full current loading preserves every saved field;
only content headers change. Old journals fold under their original headers and
retain untouched backups. An acknowledged unanswered strike stays at health100
on import, then the corrected enemy inflicts five on the next actual tick.
Replaying the old 600 ticks under new rules gives a different outcome and is
explicitly rejected as recovery. Thirteen added persistence checks pass;
persistence is 444. Schema23, envelope5 and generator revisions remain unchanged.

All old catalogs, goldens, inputs and foreign saves remain unchanged. V7 catalog
definitions exactly equal v6 except version. The new v7 replay uses the same
62-command input in a separate directory; both complete old/new checkpoints
match every gameplay field after only the two headers normalize. This trace
does not trigger the isolated interception bug. The new golden/foreign snapshot
passes a subsequent normal replay; record mode refuses to overwrite either.
The v6 preservation manifest/producer and old journal are independently audited.

Inspected initial maps keep their original v6 expectations. Native and independent
Python checks first validate exact original/current catalog hashes and definition
equivalence, then normalize only the two headers (plus the existing campaign-ID
and explicit Hearthside-preset exceptions). Full payload hashes remain compared.
Negative tests reject wrong headers, changed definitions and changed gameplay;
169 generation checks pass without regenerating any inspected golden.

A mutable-source Meadow104729 pilot passes both normal defense and physical
ransom, with all four residents at health100, no starvation/theft, real approach
movement, active-incident reloads and full save round trips. Its separate Python
audit also passes every unchanged initial/geometry/order/combat/payment gate.
It is in `defense-self-defense-v58-pilot/`; the full frozen v7 thirty-map matrix,
current long campaigns, platform CI and physical/human gates remain separate.
Earlier v6 matrix successes and cart-plan failures keep their source scopes.
