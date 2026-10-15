class_name ImmutableJournalTests
extends RefCounted

static func run(check: Callable) -> void:
	var root: String="user://immutable-journal-tests-%d" % Time.get_ticks_usec()
	var world: ColonyWorld=ColonyTests.world()
	var store: ColonyStore=ColonyStore.new();store.directory=root.path_join("direct")
	var error: String=store.save(world);var first: Dictionary=store.journal_payload
	var old_name: String=first.citizens[0].name
	world.queue_command("rename",{"target":1,"text":"Changed after direct save"});world.step()
	check.call("SAVE/direct_mutable_world_still_gets_independent_durable_base",error.is_empty() and not first.is_read_only() and first.citizens[0].name==old_name and world.citizens[0].name!=old_name)
	store=ColonyStore.new();store.directory=root.path_join("async")
	var queue: ColonySaveQueue=ColonySaveQueue.new();queue.prime(world)
	var expected: String=world.canonical_hash()
	error=queue.start(store,world,true);var done: Dictionary=queue.poll(true)
	var capture: Dictionary=queue.capture_cache.previous
	check.call("SAVE/async_full_snapshot_retains_exact_owned_capture_by_identity",error.is_empty() and done.error.is_empty() and is_same(store.journal_payload,capture) and capture.is_read_only() and capture.citizens.is_read_only() and capture.citizens[0].is_read_only())
	check.call("SAVE/owned_full_snapshot_recovers_complete_canonical_state",AsyncSaveTests.load_saved(store).world.canonical_hash()==expected)
	first=capture;old_name=first.citizens[0].name
	world.queue_command("rename",{"target":1,"text":"Changed after owned save"});world.step()
	world.queue_command("food_policy",{"enabled":true})
	expected=world.canonical_hash();error=queue.start(store,world);done=queue.poll(true)
	capture=queue.capture_cache.previous
	check.call("SAVE/owned_checkpoint_shares_unchanged_history_and_keeps_prior_capture_frozen",error.is_empty() and done.error.is_empty() and is_same(store.journal_payload,capture) and not is_same(first,capture) and is_same(first.structures[0],capture.structures[0]) and first.citizens[0].name==old_name and capture.citizens[0].name!=old_name)
	var recovered: ColonyWorld=AsyncSaveTests.load_saved(store).world
	check.call("SAVE/owned_checkpoint_recovers_pending_command_without_early_progress",recovered.canonical_hash()==expected and recovered.pending_commands.size()==1 and not recovered.use_rations)
	world.step();recovered.step()
	check.call("SAVE/owned_checkpoint_pending_command_continues_once",world.canonical_hash()==recovered.canonical_hash() and world.use_rations)
	error=queue.start_preparation(world);var prepared: Dictionary=queue.poll_preparation(true)
	for index in range(3): world.step()
	expected=world.canonical_hash();error=queue.start(store,world,true) if error.is_empty() else error;done=queue.poll(true)
	capture=queue.capture_cache.previous
	check.call("SAVE/prepared_catchup_retains_current_owned_capture_and_recovers_exactly",error.is_empty() and prepared.error.is_empty() and done.error.is_empty() and is_same(store.journal_payload,capture) and store.snapshot_tick<world.tick and store.journal_tick==world.tick and AsyncSaveTests.load_saved(store).world.canonical_hash()==expected)
	# Replacing the mutable world and resetting the capture cache cannot mutate
	# the already acknowledged base held by the store.
	var old_base: Dictionary=store.journal_payload;var old_hash: String=JSON.stringify(ColonyState.pack(old_base),"",true).sha256_text()
	queue.prime(ColonyTests.world())
	check.call("SAVE/owned_base_survives_capture_cache_replacement",JSON.stringify(ColonyState.pack(old_base),"",true).sha256_text()==old_hash and not is_same(old_base,queue.capture_cache.previous))
	CampaignTests.remove_tree(root)
