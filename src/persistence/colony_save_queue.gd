class_name ColonySaveQueue
extends RefCounted
## One writer owns an immutable capture. Only poll() touches the live campaign.
var thread: Thread
var source_store: ColonyStore
var source_world: ColonyWorld
var captured_tick: int = 0
var original_sequence: int = 0

func busy() -> bool:
	return thread!=null

func start(store: ColonyStore, world: ColonyWorld, full_snapshot: bool = false) -> String:
	if busy(): return "A verified save is already in progress"
	var captured: Dictionary = world.payload().duplicate(true)
	var trace: Array[Dictionary] = world.command_trace.duplicate(true)
	var writer: ColonyStore = ColonyStore.new()
	for field in ["directory","root_directory","slot","sequence","journal_tick","journal_sequence","journal_length","journal_digest","recovered"]:
		writer.set(field,store.get(field))
	writer.verified_generations=store.verified_generations.duplicate()
	source_store=store;source_world=world;captured_tick=world.tick;original_sequence=store.sequence
	thread=Thread.new()
	var error: Error = thread.start(_write.bind(writer,captured,trace,world.definitions,full_snapshot))
	if error!=OK:
		thread=null;source_store=null;source_world=null
		return "Could not start the save worker: "+error_string(error)
	return ""

func _write(writer: ColonyStore, captured: Dictionary, trace: Array[Dictionary], catalog: Dictionary, full_snapshot: bool) -> Dictionary:
	var frozen: ColonyWorld = ColonyWorld.new(catalog)
	for field in captured:
		if field in ["content","content_hash"]: continue
		if captured[field] is Array: frozen.get(field).assign(captured[field])
		else: frozen.set(field,captured[field])
	frozen.command_trace.assign(trace)
	var error: String = writer.save(frozen) if full_snapshot else writer.checkpoint(frozen)
	return {"error":error,"writer":writer,"full_snapshot":full_snapshot}

func poll(wait: bool = false) -> Dictionary:
	if thread==null or (not wait and thread.is_alive()): return {}
	var result: Dictionary = thread.wait_to_finish()
	thread=null
	var writer: ColonyStore = result.writer
	for field in ["sequence","journal_tick","journal_sequence","journal_length","journal_digest","recovered"]:
		source_store.set(field,writer.get(field))
	source_store.verified_generations=writer.verified_generations
	if result.error.is_empty():
		# Commands accepted after capture remain in the live trace for the next
		# checkpoint; completing an older save cannot acknowledge newer progress.
		source_world.command_trace.assign(source_world.command_trace.filter(func(entry:Dictionary)->bool:return entry.tick>captured_tick))
	var completed: Dictionary = {"error":result.error,"world":source_world,"store":source_store,"tick":captured_tick,"snapshot":result.full_snapshot or writer.sequence!=original_sequence}
	source_store=null;source_world=null
	return completed
