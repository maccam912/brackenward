class_name ColonySaveQueue
extends RefCounted
## One writer owns an immutable capture. Only poll() touches the live campaign.
var thread: Thread
var source_store: ColonyStore
var source_world: ColonyWorld
var captured_tick: int = 0
var original_sequence: int = 0
var writing_snapshot: bool = false
var retired_payloads: Array = []
var capture_cache: ColonyCapture = ColonyCapture.new()
var preparation_thread: Thread
var preparation_world_id: int = 0
var prepared: ColonyPreparedSnapshot

class CapturedStore extends ColonyStore:
	var owned_capture: Dictionary = {}
	func _retain_payload(world: RefCounted) -> Dictionary:
		# This writer receives only a fully owned, recursively read-only capture.
		# Its world never steps; retaining that same base avoids another complete
		# history copy after every journal append or snapshot rotation.
		assert(owned_capture.is_read_only() and owned_capture==world.payload())
		return owned_capture

	func _make_delta(before: Dictionary, world: ColonyWorld) -> Dictionary:
		assert(owned_capture.is_read_only() and owned_capture==world.payload())
		return ColonyDelta._make_owned(before,owned_capture)

class WorkRequest extends RefCounted:
	var writer: ColonyStore
	var captured: Dictionary = {}
	var trace: Array[Dictionary] = []
	var catalog: Dictionary = {}
	var full_snapshot: bool = false
	var retired: Array = []
	var prepared: ColonyPreparedSnapshot
	var enqueued_us: int = 0
	var captured_tick: int = 0
	var captured_speed: int = -1

func busy() -> bool:
	return thread!=null

func prime(world: ColonyWorld) -> void:
	assert(not busy())
	discard_preparation()
	# Loading/adopting a campaign is already paused. Build the first owned copy
	# here so its allocations cannot land on the first second of ordinary play.
	capture_cache=ColonyCapture.new();retired_payloads=[]
	capture_cache.capture(world,retired_payloads)
	retired_payloads=[]

func preparing() -> bool:
	return preparation_thread!=null

func ready(world: ColonyWorld) -> bool:
	return prepared!=null and preparation_world_id==world.get_instance_id()

func start_preparation(world: ColonyWorld, measured_speed: int = -1) -> String:
	if preparing() or prepared!=null: return "A full snapshot is already being prepared"
	var request: WorkRequest = WorkRequest.new()
	request.captured=capture_cache.capture(world,retired_payloads)
	request.catalog=world.definitions;request.retired=retired_payloads;retired_payloads=[]
	request.captured_tick=world.tick;request.captured_speed=measured_speed
	preparation_world_id=world.get_instance_id()
	preparation_thread=Thread.new()
	request.enqueued_us=Time.get_ticks_usec()
	var error: Error = preparation_thread.start(_prepare.bind(request))
	if error!=OK:
		preparation_thread=null;retired_payloads=request.retired
		return "Could not start snapshot preparation: "+error_string(error)
	return ""

func _prepare(request: WorkRequest) -> Dictionary:
	request.retired=[]
	var result: Dictionary = ColonyPreparedSnapshot.prepare(request.captured,request.catalog)
	request.captured={};request.catalog={}
	_worker_timing(request,result)
	return result

func poll_preparation(wait: bool = false) -> Dictionary:
	if preparation_thread==null or (not wait and preparation_thread.is_alive()): return {}
	var result: Dictionary = preparation_thread.wait_to_finish()
	preparation_thread=null
	if result.has("snapshot"): prepared=result.snapshot
	return {"error":result.get("error",""),"worker_us":result.worker_us,"tick":result.tick,"speed":result.speed}

func discard_preparation() -> Dictionary:
	var result: Dictionary=poll_preparation(true)
	if prepared!=null: retired_payloads.append(prepared)
	prepared=null;preparation_world_id=0
	return result

func start(store: ColonyStore, world: ColonyWorld, full_snapshot: bool = false, measured_speed: int = -1) -> String:
	if busy(): return "A verified save is already in progress"
	var request: WorkRequest = WorkRequest.new()
	request.captured=capture_cache.capture(world,retired_payloads)
	request.trace=world.command_trace.duplicate(true)
	request.catalog=world.definitions
	request.full_snapshot=full_snapshot
	if full_snapshot and ready(world): request.prepared=prepared;prepared=null
	request.retired=retired_payloads;retired_payloads=[]
	var writer: CapturedStore = CapturedStore.new()
	writer.owned_capture=request.captured
	for field in ["directory","root_directory","slot","sequence","journal_tick","journal_sequence","journal_length","journal_digest","recovered","journal_payload","journal_parent_hash","journal_size_bound","snapshot_tick","_journal_last_command_tick","_journal_command_digest","_journal_command_sequence"]:
		writer.set(field,store.get(field))
	writer.verified_generations=store.verified_generations.duplicate()
	writer.verified_journals=store.verified_journals.duplicate()
	writer.rejected_journals=store.rejected_journals.duplicate()
	request.writer=writer
	source_store=store;source_world=world;captured_tick=world.tick;original_sequence=store.sequence
	writing_snapshot=full_snapshot
	request.captured_tick=world.tick;request.captured_speed=measured_speed
	thread=Thread.new()
	request.enqueued_us=Time.get_ticks_usec()
	var error: Error = thread.start(_execute.bind(request))
	if error!=OK:
		thread=null;source_store=null;source_world=null;writing_snapshot=false
		retired_payloads=request.retired
		return "Could not start the save worker: "+error_string(error)
	return ""

func _execute(request: WorkRequest) -> Dictionary:
	# The Thread keeps its bound callable until poll() joins it. Bind only this
	# small holder and release the large owned trees on the worker itself.
	request.retired=[]
	var result: Dictionary = _write_prepared(request.writer,request.captured,request.trace,request.catalog,request.prepared) if request.prepared!=null else _write(request.writer,request.captured,request.trace,request.catalog,request.full_snapshot)
	request.captured={};request.trace=[];request.catalog={};request.prepared=null
	_worker_timing(request,result)
	return result

func _worker_timing(request: WorkRequest, result: Dictionary) -> void:
	# Wall latency includes thread scheduling, work and the cleanup above. It
	# excludes foreground capture and a later wait before poll() joins the worker.
	result.worker_us=Time.get_ticks_usec()-request.enqueued_us
	result.tick=request.captured_tick;result.speed=request.captured_speed

func _write_prepared(writer: ColonyStore, captured: Dictionary, trace: Array[Dictionary], catalog: Dictionary, snapshot: ColonyPreparedSnapshot) -> Dictionary:
	var frozen: ColonyWorld = _world(captured,catalog)
	frozen.command_trace.assign(trace)
	return {"error":writer.commit_prepared(frozen,snapshot),"writer":writer,"full_snapshot":true}

func _write(writer: ColonyStore, captured: Dictionary, trace: Array[Dictionary], catalog: Dictionary, full_snapshot: bool) -> Dictionary:
	var frozen: ColonyWorld = _world(captured,catalog)
	frozen.command_trace.assign(trace)
	var error: String = writer.save(frozen) if full_snapshot else writer.checkpoint(frozen)
	return {"error":error,"writer":writer,"full_snapshot":full_snapshot}

static func _world(captured: Dictionary, catalog: Dictionary) -> ColonyWorld:
	var frozen: ColonyWorld = ColonyWorld.new(catalog)
	for field in captured:
		if field in ["content","content_hash"]: continue
		if captured[field] is Array: frozen.get(field).assign(captured[field])
		else: frozen.set(field,captured[field])
	frozen.reset_stack_queries()
	return frozen

func poll(wait: bool = false) -> Dictionary:
	if thread==null or (not wait and thread.is_alive()): return {}
	var result: Dictionary = thread.wait_to_finish()
	thread=null;writing_snapshot=false
	var writer: ColonyStore = result.writer
	if not source_store.journal_payload.is_empty() and not is_same(source_store.journal_payload,writer.journal_payload):
		retired_payloads.append(source_store.journal_payload)
	for field in ["sequence","journal_tick","journal_sequence","journal_length","journal_digest","recovered","journal_payload","journal_parent_hash","journal_size_bound","snapshot_tick","_journal_last_command_tick","_journal_command_digest","_journal_command_sequence"]:
		source_store.set(field,writer.get(field))
	source_store.verified_generations=writer.verified_generations
	source_store.verified_journals=writer.verified_journals
	source_store.rejected_journals=writer.rejected_journals
	if result.error.is_empty():
		# Commands accepted after capture remain in the live trace for the next
		# checkpoint; completing an older save cannot acknowledge newer progress.
		if not source_world.command_trace.is_empty(): retired_payloads.append(source_world.command_trace.duplicate())
		source_world.command_trace.assign(source_world.command_trace.filter(func(entry:Dictionary)->bool:return entry.tick>captured_tick))
	var completed: Dictionary = {"error":result.error,"world":source_world,"store":source_store,"tick":captured_tick,"snapshot":result.full_snapshot or writer.sequence!=original_sequence,"worker_us":result.worker_us,"speed":result.speed}
	source_store=null;source_world=null
	return completed
