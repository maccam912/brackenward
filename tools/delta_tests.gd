class_name DeltaTests
extends RefCounted

static func run(check: Callable) -> void:
	var before: Dictionary = {"tick":1800,"jobs":[{"id":1,"state":"Complete","inputs":{"wood":2}},{"id":2,"state":"Working","work":10}],"map":{1:{"amount":2},2:{"amount":3}},"obsolete":true,"tiles":[Vector2i(4,5)]}
	var after: Dictionary = before.duplicate(true)
	after.tick=1801;after.jobs[1].work=20;after.jobs.append({"id":3,"state":"Ready","work":0});after.map.erase(1);after.map[2].amount=4;after.map[3]={"amount":6};after.erase("obsolete");after.tiles.append(Vector2i(5,5))
	var patch: Dictionary = ColonyDelta.make(before,after)
	var result: Dictionary = ColonyDelta.restore(before,patch)
	check.call("SAVE/delta_exact_nested_changes_additions_and_removals",result.get("state")==after and before.tick==1800 and before.jobs.size()==2 and before.map[2].amount==3)
	check.call("SAVE/delta_retains_unchanged_record_prefix",patch.map.jobs.records.prefix==2 and patch.map.jobs.records.tail_ids==[3] and patch.map.jobs.records.changes.size()==2 and not patch.map.jobs.records.changes.has(1))
	result.state.jobs[0].inputs.wood=9
	check.call("SAVE/delta_result_cannot_mutate_source_or_patch",before.jobs[0].inputs.wood==2 and after.jobs[0].inputs.wood==2)
	after.jobs.reverse();after.jobs.remove_at(1)
	result=ColonyDelta.restore(before,ColonyDelta.make(before,after))
	check.call("SAVE/delta_reorders_and_removes_records_exactly",result.get("state")==after)
	check.call("SAVE/delta_noop_preserves_complete_state",ColonyDelta.make(before,before).is_empty() and ColonyDelta.restore(before,{}).state==before)
	var wide: Dictionary = {"value":9007199254740993,"negative":-9007199254740993}
	var wire: PackedByteArray = ColonyJournal.frame({"sequence":"1","kind":"tick","tick":1801,"delta":{"version":1,"base_tick":1800,"campaign_id":"integer-fixture","parent":"a".repeat(64),"patch":ColonyDelta.make({"value":0,"negative":0},wide)}})
	var read: Dictionary = ColonyJournal.read(wire)
	check.call("SAVE/delta_scalar_integers_never_round_through_json_floats",not read.has("error") and ColonyDelta.restore({"value":0,"negative":0},read.records[0].delta.patch).state==wide)
	check.call("SAVE/delta_integer_spelling_is_canonical",ColonyDelta.restore(before,{"map":{"tick":{"set_int":"01801"}},"erase":{}}).has("error") and ColonyDelta.restore(before,{"map":{"tick":{"set_int":"9223372036854775808"}},"erase":{}}).has("error"))
	for bad in [
		{"records":{"prefix":-1,"tail_ids":[],"changes":{}}},
		{"records":{"prefix":3,"tail_ids":[],"changes":{}}},
		{"records":{"prefix":1,"tail_ids":[1],"changes":{}}},
		{"records":{"prefix":0,"tail_ids":[9],"changes":{}}},
		{"records":{"prefix":0,"tail_ids":[3],"changes":{3:{"id":4}}}},
		{"records":{"prefix":2,"tail_ids":[],"changes":{3:{"id":3}}}}
	]:
		check.call("SAVE/delta_rejects_invalid_record_layout_%d" % bad.hash(),ColonyDelta.restore(before,{"map":{"jobs":bad},"erase":{}}).has("error"))
	check.call("SAVE/delta_rejects_unknown_operation",ColonyDelta.restore(before,{"arbitrary":true}).has("error"))
	check.call("SAVE/delta_rejects_nonboolean_or_missing_erasure",ColonyDelta.restore(before,{"map":{},"erase":{"tick":1}}).has("error") and ColonyDelta.restore(before,{"map":{},"erase":{"missing":true}}).has("error"))
	var world: ColonyWorld = ColonyTests.world()
	var base: Dictionary = world.payload().duplicate(true)
	world.queue_command("field",{"crop":"turnip","tiles":[Vector2i(80,80)]})
	for index in range(30): world.step()
	result=ColonyDelta.restore(base,ColonyDelta.make(base,world.payload()))
	var loaded: Dictionary = ColonyCodec.restore(result.state) if result.has("state") else result
	check.call("SAVE/delta_restores_real_public_command_and_ticks",loaded.has("world") and loaded.world.canonical_hash()==world.canonical_hash(),str(loaded.get("error","")))
