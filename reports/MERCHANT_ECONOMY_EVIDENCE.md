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
