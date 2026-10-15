class_name OwnedDeltaTests
extends RefCounted

static func packed(value: Dictionary) -> String:
	return JSON.stringify(ColonyState.pack(value),"",false)

static func twin(before: Dictionary, after: Dictionary) -> bool:
	var owned: Dictionary=after.duplicate(true);ColonyCapture._freeze(owned)
	var left: String=packed(before);var right: String=packed(owned)
	var original: Dictionary=OwnedDeltaReference.make(before,owned)
	var borrowed: Dictionary=ColonyDelta._make_owned(before,owned)
	return packed(original)==packed(borrowed) and packed(original)==packed(ColonyDelta.make(before,owned)) and ColonyDelta.matches(before,borrowed,owned) and ColonyDelta.restore(before,borrowed).get("state")==owned and OwnedDeltaReference.restore(before,borrowed).get("state")==owned and left==packed(before) and right==packed(owned)

static func run(check: Callable) -> void:
	var before: Dictionary={"jobs":[{"id":1,"work":1},{"id":2,"work":10}],"plain":[{"memo":"old"}],"map":{1:{"quantity":2}},"obsolete":true,"tick":1800}
	var after: Dictionary={"jobs":[{"id":2,"work":20},{"id":1,"work":1},{"id":3,"work":0}],"plain":[{"memo":"old"},{"memo":"literal {speed}"}],"map":{2:{"quantity":3}},"tick":1801}
	var exact: bool=twin(before,after) and twin(before,before) and twin(before,{}) and twin({},after)
	for value in [[],{},[Vector2i(3,4)],{1:{"id":7,"values":[true,false]}},9223372036854775807,-9223372036854775807]:exact=twin({"value":[1]},{"value":value}) and exact
	check.call("SAVE/owned_delta_matches_complete_2446783_reference_for_records_maps_reorder_empty_and_wide_values",exact)
	var owned: Dictionary=after.duplicate(true);ColonyCapture._freeze(owned)
	var borrowed: Dictionary=ColonyDelta._make_owned(before,owned)
	var independent: Dictionary=ColonyDelta.make(before,after)
	exact=is_same(borrowed.map.jobs.records.changes[2],owned.jobs[0]) and borrowed.map.jobs.records.changes[2].is_read_only() and is_same(borrowed.map.plain.set,owned.plain) and owned.plain.is_read_only() and not is_same(independent.map.jobs.records.changes[2],after.jobs[0]) and not is_same(independent.map.plain.set,after.plain)
	after.jobs[0].work=99;after.plain.append({"memo":"later"})
	check.call("SAVE/owned_delta_borrows_only_frozen_capture_values_while_public_mutable_patch_stays_independent",exact and independent.map.jobs.records.changes[2].work==20 and independent.map.plain.set.size()==2 and owned.jobs[0].work==20 and owned.plain.size()==2)
	var patch_before: String=packed(borrowed);var source_before: String=packed(before);var owned_before: String=packed(owned)
	var restored: Dictionary=ColonyDelta.restore(before,borrowed)
	restored.state.jobs[0].work=88;restored.state.plain[1].memo="restored only"
	check.call("SAVE/reconstructing_borrowed_patch_still_returns_independent_mutable_state",packed(before)==source_before and packed(owned)==owned_before and packed(borrowed)==patch_before and restored.state.jobs[0].work==88 and owned.jobs[0].work==20)
	var world: ColonyWorld=ColonyTests.world();var base: Dictionary=ColonyCapture.new().capture(world,[])
	world.queue_command("rename",{"target":1,"text":"Mira Reed"});world.step()
	world.queue_command("food_policy",{"enabled":true})
	var captured: Dictionary=ColonyCapture.new().capture(world,[])
	var writer: ColonySaveQueue.CapturedStore=ColonySaveQueue.CapturedStore.new();writer.owned_capture=captured
	var direct: ColonyStore=ColonyStore.new();borrowed=writer._make_delta(base,world);independent=direct._make_delta(base,world)
	exact=packed(borrowed)==packed(OwnedDeltaReference.make(base,captured)) and packed(borrowed)==packed(independent) and is_same(borrowed.map.citizens.records.changes[1],captured.citizens[0]) and not is_same(independent.map.citizens.records.changes[1],world.citizens[0])
	var loaded: Dictionary=ColonyCodec.restore(ColonyDelta.restore(base,borrowed).state)
	if loaded.has("world"):
		for tick in range(120):world.step();loaded.world.step()
		exact=exact and world.payload()==loaded.world.payload() and world.invariant_errors().is_empty() and captured.tick==1801 and captured.pending_commands.size()==1
	else:exact=false
	check.call("SAVE/captured_writer_uses_frozen_patch_but_direct_caller_copies_and_real_future_state_stays_exact",exact)
