class_name StressTests
extends RefCounted

static func run(check: Callable) -> void:
	var fixture: Dictionary = StressFixture.make()
	check.call("PERF/synthetic_release_fixture_validates",fixture.has("world"),str(fixture.get("error","")))
	if not fixture.has("world"): return
	var world: ColonyWorld = fixture.world
	var baseline: Dictionary=world.payload().duplicate(true)
	check.call("PERF/fixture_has_every_declared_load",fixture.counts=={"residents":20,"domestic":12,"wildlife":32,"hostiles":6,"neutral_visitors":8,"structures":400,"nonempty_stacks":1000,"active_targets":256,"crop_tiles":192,"chronicle":1000,"weather":"rain"},str(fixture.counts))
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	if not decoded.has("world"): return
	for index in range(12): world.step();decoded.world.step()
	check.call("PERF/full_fixture_continues_identically_after_save",world.canonical_hash()==decoded.world.canonical_hash() and world.tick==1812)
	check.call("PERF/full_fixture_has_live_work_without_ledger_errors",world.citizens.any(func(c:Dictionary)->bool:return c.job>0) and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var prepared: Dictionary=StressFixture.make(true)
	if not prepared.has("world"): check.call("PERF/prepared_fixture_only_queues_normal_policy_without_grants",false,str(prepared));return
	var ready: ColonyWorld=prepared.world
	var original_payload: Dictionary=baseline.duplicate(true);var prepared_payload: Dictionary=ready.payload().duplicate(true)
	for field in ["pending_commands","next_command_id"]: original_payload.erase(field);prepared_payload.erase(field)
	check.call("PERF/prepared_fixture_only_queues_normal_policy_without_grants",not world.use_rations and not ready.use_rations and prepared.counts==fixture.counts and original_payload==prepared_payload and ready.pending_commands.size()==1 and ready.pending_commands[0].kind=="food_policy" and ready.pending_commands[0].args=={"enabled":true})
	var roundtrip: Dictionary=ColonyCodec.decode(ColonyCodec.encode(ready))
	check.call("PERF/prepared_policy_is_durable_without_load_progress",roundtrip.has("world") and roundtrip.world.canonical_hash()==ready.canonical_hash() and roundtrip.world.tick==1800 and not roundtrip.world.use_rations)
	if not roundtrip.has("world"): return
	var policy_id: int=ready.pending_commands[0].id
	ready.step();roundtrip.world.step()
	check.call("PERF/prepared_policy_applies_on_first_ordinary_tick_with_real_food",ready.tick==1801 and ready.receipts.get(policy_id)=="accepted" and ready.use_rations and FoodForecast.calculate(ready).portions>24 and ready.canonical_hash()==roundtrip.world.canonical_hash() and ready.invariant_errors().is_empty())
