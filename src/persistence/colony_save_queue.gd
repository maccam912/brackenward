class_name ColonySaveQueue
extends RefCounted
## One writer owns an immutable capture. Only poll() touches the live campaign.
var thread: Thread
var source_store: ColonyStore
var source_world: ColonyWorld
var captured_tick: int = 0
var original_sequence: int = 0
var retired_payloads: Array = []
var capture_cache: ColonyCapture = ColonyCapture.new()

class WorkRequest extends RefCounted:
	var writer: ColonyStore
	var captured: Dictionary = {}
	var trace: Array[Dictionary] = []
	var catalog: Dictionary = {}
	var full_snapshot: bool = false
	var retired: Array = []

func busy() -> bool:
	return thread!=null

func prime(world: ColonyWorld) -> void:
	assert(not busy())
	# Loading/adopting a campaign is already paused. Build the first owned copy
	# here so its allocations cannot land on the first second of ordinary play.
	capture_cache=ColonyCapture.new();retired_payloads=[]
	capture_cache.capture(world,retired_payloads)
	retired_payloads=[]

func start(store: ColonyStore, world: ColonyWorld, full_snapshot: bool = false) -> String:
	if busy(): return "A verified save is already in progress"
	var request: WorkRequest = WorkRequest.new()
	request.captured=capture_cache.capture(world,retired_payloads)
	request.trace=world.command_trace.duplicate(true)
	request.catalog=world.definitions
	request.full_snapshot=full_snapshot
	request.retired=retired_payloads;retired_payloads=[]
	var writer: ColonyStore = ColonyStore.new()
	for field in ["directory","root_directory","slot","sequence","journal_tick","journal_sequence","journal_length","journal_digest","recovered","journal_payload","journal_parent_hash","journal_size_bound","snapshot_tick"]:
		writer.set(field,store.get(field))
	writer.verified_generations=store.verified_generations.duplicate()
	writer.verified_journals=store.verified_journals.duplicate()
	writer.rejected_journals=store.rejected_journals.duplicate()
	request.writer=writer
	source_store=store;source_world=world;captured_tick=world.tick;original_sequence=store.sequence
	thread=Thread.new()
	var error: Error = thread.start(_execute.bind(request))
	if error!=OK:
		thread=null;source_store=null;source_world=null
		retired_payloads=request.retired
		return "Could not start the save worker: "+error_string(error)
	return ""

func _execute(request: WorkRequest) -> Dictionary:
	# The Thread keeps its bound callable until poll() joins it. Bind only this
	# small holder and release the large owned trees on the worker itself.
	request.retired=[]
	var result: Dictionary = _write(request.writer,request.captured,request.trace,request.catalog,request.full_snapshot)
	request.captured={};request.trace=[];request.catalog={}
	return result

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
	if not source_store.journal_payload.is_empty() and not is_same(source_store.journal_payload,writer.journal_payload):
		retired_payloads.append(source_store.journal_payload)
	for field in ["sequence","journal_tick","journal_sequence","journal_length","journal_digest","recovered","journal_payload","journal_parent_hash","journal_size_bound","snapshot_tick"]:
		source_store.set(field,writer.get(field))
	source_store.verified_generations=writer.verified_generations
	source_store.verified_journals=writer.verified_journals
	source_store.rejected_journals=writer.rejected_journals
	if result.error.is_empty():
		# Commands accepted after capture remain in the live trace for the next
		# checkpoint; completing an older save cannot acknowledge newer progress.
		if not source_world.command_trace.is_empty(): retired_payloads.append(source_world.command_trace.duplicate())
		source_world.command_trace.assign(source_world.command_trace.filter(func(entry:Dictionary)->bool:return entry.tick>captured_tick))
	var completed: Dictionary = {"error":result.error,"world":source_world,"store":source_store,"tick":captured_tick,"snapshot":result.full_snapshot or writer.sequence!=original_sequence}
	source_store=null;source_world=null
	return completed
