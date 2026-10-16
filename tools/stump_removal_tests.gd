class_name StumpRemovalTests
extends RefCounted

static func run(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();var resource: Dictionary=world.resources[0]
	var rejected: int=world.queue_command("clear_stump",{"target":resource.id});world.step()
	check.call("FOREST/removal_rejects_mature_tree_without_destroying_it",world.receipts[rejected]!="accepted" and resource.remaining==8)
	world.queue_command("gather",{"target":resource.id})
	for index in range(600): world.step()
	var before: int=world.total("wood")
	var command: int=world.queue_command("clear_stump",{"target":resource.id})
	var loaded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/pending_stump_removal_roundtrips",loaded.has("world") and loaded.world.canonical_hash()==world.canonical_hash(),str(loaded.get("error","")))
	world.step()
	check.call("FOREST/stump_removal_is_queued_work_without_instant_erasure",world.receipts[command]=="accepted" and not ColonyNature.tree(world,resource.id).cleared and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="clear_stump" and j.required==4000 and j.state!="Complete"))
	check.call("FOREST/removal_blocks_conflicting_replant_until_it_finishes",world._command({"kind":"replant_tree","args":{"target":resource.id}})=="Tree work already marked")
	for index in range(600): world.step()
	check.call("FOREST/worker_removes_stump_without_wood_or_resource_history_loss",ColonyNature.tree(world,resource.id).cleared and world.find(world.resources,resource.id)==resource and world.total("wood")==before and world.invariant_errors().is_empty())
	loaded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/removed_stump_remains_removed_after_reload",loaded.has("world") and loaded.world.canonical_hash()==world.canonical_hash() and ColonyNature.tree(loaded.world,resource.id).cleared,str(loaded.get("error","")))
	world.queue_command("forest",{"tiles":[Vector2i(resource.x,resource.y)],"value":100});world.step()
	for index in range(100): world.step()
	check.call("FOREST/forest_never_replants_removed_tree_site",not world.unfinished_jobs().any(func(j:Dictionary)->bool:return j.kind=="plant_tree" and j.target==resource.id) and not ColonyNature.tree(world,resource.id).planted)
	world=ColonyTests.world();resource=world.resources[0];resource.remaining=0
	world._command({"kind":"replant_tree","args":{"target":resource.id}})
	world.queue_command("clear_stump",{"target":resource.id});world.step()
	check.call("FOREST/removal_replaces_pending_replant_order",world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="plant_tree").all(func(j:Dictionary)->bool:return j.state=="Canceled") and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="clear_stump"))
	var removal: Dictionary=world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="clear_stump")[0]
	world.queue_command("cancel",{"target":removal.id});world.step()
	check.call("FOREST/cancel_removal_leaves_stump_available_to_replant",not ColonyNature.tree(world,resource.id).cleared and world._command({"kind":"replant_tree","args":{"target":resource.id}})=="accepted")
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes("res://tests/fixtures/content9/campaign-replay-7200.brackenward")
	var original: Dictionary=ColonyState.unpack(JSON.parse_string(JSON.parse_string(bytes.get_string_from_utf8()).payload))
	loaded=ColonyCodec.decode(bytes)
	check.call("SAVE/v9_acknowledgement_keeps_every_existing_gameplay_field",loaded.has("world") and SchemaCompatibility.normalize(loaded.world,original)==original and loaded.world.nature_state.trees.values().all(func(state:Dictionary)->bool:return state.cleared==false),str(loaded.get("error","")))
