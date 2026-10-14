class_name StressTests
extends RefCounted

static func run(check: Callable) -> void:
	var fixture: Dictionary = StressFixture.make()
	check.call("PERF/synthetic_release_fixture_validates",fixture.has("world"),str(fixture.get("error","")))
	if not fixture.has("world"): return
	var world: ColonyWorld = fixture.world
	check.call("PERF/fixture_has_every_declared_load",fixture.counts=={"residents":20,"domestic":12,"wildlife":32,"hostiles":6,"neutral_visitors":8,"structures":400,"nonempty_stacks":1000,"active_targets":256,"crop_tiles":192,"chronicle":1000,"weather":"rain"},str(fixture.counts))
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	if not decoded.has("world"): return
	for index in range(12): world.step();decoded.world.step()
	check.call("PERF/full_fixture_continues_identically_after_save",world.canonical_hash()==decoded.world.canonical_hash() and world.tick==1812)
	check.call("PERF/full_fixture_has_live_work_without_ledger_errors",world.citizens.any(func(c:Dictionary)->bool:return c.job>0) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
