# Ordinary merchant-economy evidence

The acceptance contract in DESIGN.md requires 24 ordinary days on all three
Standard sites and Pine Hearthside, two scheduled Riverward purchases totaling
sixteen cloth/eighty wood, real sewing and one Road Fellowship three-cloak
delivery. No cloth grants/local weaving, starting-equipment sales or scenario
shortcuts are allowed. Final eight-person food/needs, exact initial inspected
payload, public command provenance and actual receipts are independently checked.

## Original frozen attempt: retained failure

Source `b8a02345ca1fa52077b951711d08d0389b89a9aa` completes all four 24-day
cases with eight living residents, zero zero-fullness/grace ticks and at least
69,903 final food ticks. Each imports only eight cloth on the second Riverward
visit around tick 148000, sews four cloaks and completes no Road delivery.
The 24-day economy gate correctly fails all four; survival alone is insufficient.
No acceptance duration, quantities, reserve or receipt requirement was relaxed.

The early construction plan consumes the unreserved wood. Meadow's daily
available wood on days 6–9 is 0/0/1/2; Pine's is 1/0/6/0. The first Riverward
visit is missed because the forty-wood payment plus forty-wood retained reserve
cannot be funded. Without that cloth the earlier Road delivery is also missed.
This is a planner staffing/budget failure, not evidence of missing materials or
broken trade commands in the game.

Raw evidence remains in `merchant-release-gen2-v6-b8a0234/`, with daily and
initial/final saves, full public traces and original logs. Source SHA-256
`81e3f50c11f6758057050ae0080903454a5f6d157e9f7edcb83bf37798ffbc86`,
completion `d2e04a5a6a8e4dd1921b4ba86a048013e97b6219d0b766279cbc1394f0cce82b`.

The original independent observer fails separately on legal mixed ID encoding:
merchant records store string IDs while an exchange's merchant reference is a
JSON number. Its failed audit is retained unchanged (SHA-256
`f18a1b4a4cc910c405cdf494c3d5f53e36897d3a113c1ba30f34c5e90e10a7bc`).
The corrected observer normalizes reference lookup keys without changing any
snapshot value, receipt or expected outcome. A new read-only audit confirms all
four real policy failures, the inspected initial goldens, needs, conservation,
command provenance and unchanged original evidence bytes. Its separate file is
`merchant-policy-v51-preserved-failure-audit.json`, SHA-256
`ce443d10416f6afddec073ac30c0afc5bb726c9e9f23634fa08e8290ac66122a`.
Sixteen synthetic observer contract tests include this actual representation
boundary; they do not certify an ordinary campaign.

## Revised planner, outcome pending

The first newcomer becomes the dedicated gatherer through ordinary preference
commands. Four tree jobs and a 200-wood target support the existing construction
and purchase budgets. Food, research, actual arrival schedules, prices, payment
hauling, retained reserve and all original 24-day success conditions remain.
The bounded trade suite passes 41, including real payment/delivery receipts and
no duplicate orders after paused save recovery. A new full frozen four-case
run must earn a separate result; these targeted tests are not that result.


## Gatherer-only revision: retained failure and construction budget

Frozen `e8336e48f1dfeb9b532957f7172a996079aaca73` also finishes all four
24-day runs with eight survivors and zero starvation/grace ticks, but only one
cloth purchase and no delivery. Its corrected observer completes all four rows
without lookup errors and correctly fails the unchanged economy contract.
The extra gatherer improves wood: Meadow days 8/9/10 now have 36/58/78 and Pine
29/44/77, still below the eighty needed during the first merchant's stay.

Raw directory is `merchant-release-gen2-v6-e8336e4/`. Source SHA-256
`aa329ec2ac556e4837cf6859d82f12346e6772dbcf32ba28251f31632afbf1af`,
completion `d18f145b3a39c52e781871342e1e02da49e6393c4bb4e4f3b30e83b4f6cee096`,
audit `7dfa34e0f176e66b84fc6441645dc30600915f70a889dd83e9d4e90d01b712cf`.
No original files or false outcomes were replaced.

The next policy keeps those gathering assignments and postpones its optional
second lodge until the first cloth purchase is committed. The existing first
lodge and original bedrolls retain newcomer capacity. This changes the order of
ordinary construction, keeping the original price, reserve, 24-day duration,
material provenance, delivery and survival criteria. Trade 41 passes; another
full frozen run is required. A staffing change alone was not a claimed fix.
