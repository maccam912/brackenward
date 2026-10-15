class_name DeltaMatchTests
extends RefCounted
## The unchanged allocating recovery path is the comparison oracle.

static func agrees(before: Dictionary, patch: Dictionary, after: Dictionary) -> bool:
	var restored: Dictionary=ColonyDelta.restore(before,patch)
	return ColonyDelta.matches(before,patch,after)==(restored.has("state") and restored.state==after)

static func run(check: Callable) -> void:
	var before: Dictionary={"tick":1800,"unchanged":{"items":[1,2,3]},"map":{1:{"count":2},2:{"count":3}},"jobs":[{"id":1,"state":"Complete","inputs":{"wood":2}},{"id":2,"state":"Working","work":10}],"erase":true}
	var after: Dictionary=before.duplicate(true);after.tick+=1;after.map.erase(1);after.map[3]={"count":9};after.jobs.reverse();after.jobs[0].work+=1;after.jobs.append({"id":3,"state":"Ready","work":0});after.erase("erase")
	var patch: Dictionary=ColonyDelta.make(before,after)
	var original: Dictionary=before.duplicate(true);var target: Dictionary=after.duplicate(true);var original_patch: Dictionary=patch.duplicate(true)
	ColonyCapture._freeze(before);ColonyCapture._freeze(after);ColonyCapture._freeze(patch)
	check.call("SAVE/read_only_delta_matches_nested_changes_reordering_and_erasure",ColonyDelta.matches(before,patch,after) and agrees(before,patch,after))
	check.call("SAVE/read_only_delta_leaves_all_owned_inputs_unchanged",before==original and after==target and patch==original_patch and before.is_read_only() and after.is_read_only() and patch.is_read_only())
	var wrong: Dictionary=target.duplicate(true);wrong.unchanged.items.append(4)
	check.call("SAVE/read_only_delta_rejects_changed_untouched_state",not ColonyDelta.matches(before,patch,wrong) and agrees(before,patch,wrong))
	wrong=target.duplicate(true);wrong.extra="not written"
	var missing: Dictionary=target.duplicate(true);missing.erase("unchanged")
	check.call("SAVE/read_only_delta_rejects_extra_and_missing_target_fields",not ColonyDelta.matches(before,patch,wrong) and not ColonyDelta.matches(before,patch,missing) and agrees(before,patch,wrong) and agrees(before,patch,missing))
	var exact: bool=true
	for bad in [{"map":{},"erase":{"tick":1}},{"map":{},"erase":{"missing":true}},{"map":{"tick":{"set_int":"1801"}},"erase":{"tick":true}},{"map":true,"erase":{}},{"map":{"tick":true},"erase":{}},{"unknown":true},{"set":null},{"set_int":"01801"},{"set_int":"+1"},{"set_int":"9223372036854775808"},{"set_int":"-9223372036854775809"}]:
		exact=exact and agrees(before,bad,target) and not ColonyDelta.matches(before,bad,target)
	check.call("SAVE/read_only_delta_preserves_malformed_map_set_and_integer_rejection",exact)
	exact=true
	for bad in [{"prefix":-1,"tail_ids":[],"changes":{}},{"prefix":3,"tail_ids":[],"changes":{}},{"prefix":1,"tail_ids":[1],"changes":{}},{"prefix":0,"tail_ids":[9],"changes":{}},{"prefix":0,"tail_ids":[3],"changes":{3:{"id":4}}},{"prefix":2,"tail_ids":[],"changes":{3:{"id":3}}},{"prefix":0,"tail_ids":[1.0],"changes":{}},{"prefix":0,"tail_ids":[],"changes":{"1":{"id":1}}},{"prefix":0,"tail_ids":[],"changes":{1:{"id":1.0}}}]:
		var broken: Dictionary={"map":{"jobs":{"records":bad}},"erase":{}}
		exact=exact and agrees(before,broken,target) and not ColonyDelta.matches(before,broken,target)
	check.call("SAVE/read_only_delta_preserves_all_record_identity_order_and_unused_update_rejections",exact)
	var duplicate_base: Dictionary={"jobs":[{"id":1},{"id":1}]}
	var noop_records: Dictionary={"map":{"jobs":{"records":{"prefix":2,"tail_ids":[],"changes":{}}}},"erase":{}}
	check.call("SAVE/read_only_delta_cannot_accept_duplicate_base_records",not ColonyDelta.matches(duplicate_base,noop_records,duplicate_base) and agrees(duplicate_base,noop_records,duplicate_base))
	exact=true
	for depth in [31,32,33,34]:
		var base: Dictionary={"value":1};var changed: Dictionary={"value":2}
		for index in range(depth):base={"nested":base};changed={"nested":changed}
		var nested: Dictionary=ColonyDelta.make(base,changed)
		exact=exact and agrees(base,nested,changed) and ColonyDelta.matches(base,nested,changed)==(depth<32)
	check.call("SAVE/read_only_delta_preserves_original_depth_boundary",exact)
	var integer_base: Dictionary={"value":0,"negative":0}
	var integers: Dictionary={"value":9007199254740993,"negative":-9007199254740993}
	var frame: PackedByteArray=ColonyJournal.frame({"sequence":"1","kind":"tick","tick":1801,"delta":{"version":1,"base_tick":1800,"campaign_id":"match-fixture","parent":"a".repeat(64),"patch":ColonyDelta.make(integer_base,integers)}})
	var read: Dictionary=ColonyJournal.read(frame)
	check.call("SAVE/read_only_delta_checks_actual_reparsed_wide_integer_frame",not read.has("error") and ColonyDelta.matches(integer_base,read.records[0].delta.patch,integers) and agrees(integer_base,read.records[0].delta.patch,integers))
	generated(check)
	immutable_corpus(check)

static func generated(check: Callable) -> void:
	var rng: ParkMiller=ParkMiller.new(61453);var exact: bool=true
	for index in range(80):
		var before: Dictionary={"tick":1800,"jobs":[],"map":{},"tiles":[Vector2i(4,5)],"stable":{"flag":true,"list":[1,2,3]}}
		for id in range(1,9):before.jobs.append({"id":id,"amount":rng.next()%100,"inputs":{"wood":id}});before.map[id]={"count":id}
		var after: Dictionary=before.duplicate(true);after.tick+=index+1
		for change in range(1+rng.next()%8):
			var id: int=1+rng.next()%8;after.map.erase(id)
			if not after.jobs.is_empty():after.jobs.remove_at(rng.next()%after.jobs.size())
			if rng.next()%2==0:after.jobs.append({"id":10+change,"amount":rng.next()%100,"inputs":{"wood":change}})
		if index%2==0:after.jobs.reverse()
		if index%3==0:after.stable.list.append(index)
		if index%4==0:after.erase("tiles")
		var patch: Dictionary=ColonyDelta.make(before,after);var b: Dictionary=before.duplicate(true);var a: Dictionary=after.duplicate(true);var p: Dictionary=patch.duplicate(true)
		ColonyCapture._freeze(before);ColonyCapture._freeze(after);ColonyCapture._freeze(patch)
		exact=exact and ColonyDelta.matches(before,patch,after) and agrees(before,patch,after) and before==b and after==a and patch==p
		var wrong: Dictionary=a.duplicate(true);wrong.tick+=1
		exact=exact and not ColonyDelta.matches(before,patch,wrong) and agrees(before,patch,wrong)
	check.call("SAVE/read_only_delta_agrees_with_reconstruction_on_80_frozen_generated_cases",exact)

static func immutable_corpus(check: Callable) -> void:
	var exact: bool=true;var count: int=0
	for name in DirAccess.get_files_at("res://tests/fixtures"):
		if not name.ends_with(".brackenward"):continue
		count+=1;var path: String="res://tests/fixtures/"+name;var sha: String=FileAccess.get_sha256(path)
		var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(path))
		if not decoded.has("world"):exact=false;continue
		var world: ColonyWorld=decoded.world;var hash_before: String=world.canonical_hash()
		var base: Dictionary=ColonyCapture.new().capture(world,[]);var target: Dictionary=base.duplicate(true)
		target.tick+=1;target.citizens[0].rest=maxi(0,target.citizens[0].rest-1)
		var patch: Dictionary=ColonyDelta.make(base,target)
		exact=exact and ColonyDelta.matches(base,patch,target) and agrees(base,patch,target) and world.canonical_hash()==hash_before and FileAccess.get_sha256(path)==sha
	check.call("SAVE/read_only_delta_matches_32_immutable_save_states_without_changing_inputs",exact and count==32)
