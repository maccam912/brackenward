# Overheating cancellation and ordinary recovery coverage

Current rules are preserved pending the user's cancellation-behavior preference.
No content, incident probabilities, warnings, saves or recovery results were
changed to address this finding.

The generator-2 Pine Standard 96-day campaign at clean frozen
`d8703815c43562b4ef8746446a4d0af3885da725` records an overheating announcement
at tick 484200, target 13611, due at 487800. It resolves without ignition at
484309, with the combined reason that the target stopped working or the
perimeter became safe. Its final state contains zero fires. The other three
fresh Charter endpoints also contain zero fires. These ordinary campaign
successes therefore do not certify recovery from an actual fire.

The code audit identifies a separate deterministic cancellation path:
`ColonyFire.operating` requires an actual craft job in Working state;
`ColonyDirector.advance` cancels an announced overheat whenever `unsafe` becomes
empty, which happens whenever that Working job ends or pauses. Enabled station
and recipe controls do not preserve a warning through normal batch transitions.
Industrial recipes require 16000/16000/20000 milli-WU. At the ordinary base rate
of 100 milli-WU/tick these are 160–200 ticks, far shorter than the 3600-tick
warning. The catalog has no twelve-hour industrial batch. The observed combined
reason alone does not prove which branch ended that particular Pine warning;
the code path itself proves normal batch gaps can cancel warnings.

The existing director fixture verifies ignition by keeping a synthetic craft job
Working and moving the clock directly to the due tick. It tests scheduler/fire
integration, not an actual twelve-hour ordinary crafting sequence. An ordinary
fire-recovery scenario needs that distinction retained.

The user has been asked whether a warning should persist through normal batch
and sleep breaks until explicit suspension or perimeter clearing, or retain
automatic cancellation. That decision affects incident balance and player
expectations. If changed, state the exact cancellation rules in DESIGN.md and
the warning UI, retain suspension/perimeter prevention and fixed targets, add
real batch-transition/reload regressions, and version any changed future rules
without rewriting old acknowledgments or replay expectations. Independently
continue localization, performance and remaining campaign gates in the meantime.
