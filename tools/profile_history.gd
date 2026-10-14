extends SceneTree
## Paired complete-tick timing against the original positive-only lazy lookup.
## Lookup reference: 44fffb9. Reservation/index reference: 2f1a8fb.
## Alternate execution order and compare full state; UI never participates.
class OriginalFind extends ColonyWorld:
	func _init(catalog: Dictionary) -> void: super(catalog)
	func find(records: Array, id: int) -> Dictionary:
		if id == 0:
			return {}
		var table: String = ""
		for name in ["citizens","structures","resources","stacks","jobs","stores","fields"]:
			if is_same(records,get(name)):
				table = name
				break
		if not table.is_empty():
			var index: Dictionary = record_indexes.get(table,{})
			if index.has(id):
				return index[id]
			for record in records:
				if record.id == id:
					index[id] = record
					record_indexes[table] = index
					return record
			return {}
		for record in records:
			if record.id == id:
				return record
		return {}

class OriginalReservation extends ColonyWorld:
	func _init(catalog: Dictionary) -> void: super(catalog)
	func _find_history(records: Array, id: int, table: String) -> Dictionary:
		# These large runtime tables append immutable IDs; depleted/terminal
		# rows remain saved history. Build once, then scan only new rows. A complete
		# ID map also answers misses without rescanning every historical record.
		# Imports/generation clear record_indexes; replacement/shrink is detected.
		var key: String = "history_"+table
		var state: Dictionary = record_indexes.get(key,{})
		if state.is_empty() or not is_same(state.source,records) or state.scanned>records.size():
			state={"source":records,"scanned":0,"by_id":{}}
			record_indexes[key]=state
		if state.scanned<records.size():
			for index in range(state.scanned,records.size()):
				var record: Dictionary = records[index]
				if not state.by_id.has(record.id): state.by_id[record.id]=record
			state.scanned=records.size()
		return state.by_id.get(id,{})
	func _reservation_jobs() -> Array:
		# One resident's search can release owned work, but gaining ownership ends
		# that search. Shared dictionaries expose releases immediately; rebuilding
		# for the next resident retains original history order and conflict reasons.
		# Direct reservation/storage calls keep the full-history reference behavior.
		if not assigning_work: return jobs
		if not reservation_query_ready:
			reservation_query_jobs=jobs.filter(func(job:Dictionary)->bool:return job.worker>0)
			reservation_query_ready=true
		return reservation_query_jobs

var reference_mode: String = "lookup"

func _initialize() -> void: call_deferred("run")
func clone_world(source: ColonyWorld, original: bool) -> ColonyWorld:
	var result: ColonyWorld
	if not original: result=ColonyWorld.new(source.definitions)
	elif reference_mode=="reservation": result=OriginalReservation.new(source.definitions)
	else: result=OriginalFind.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=source.get(field)
		if value is Array: result.get(field).assign(value.duplicate(true))
		elif value is Dictionary: result.set(field,value.duplicate(true))
		else: result.set(field,value)
	result.record_indexes.clear();result.reset_job_queries();result.reset_stack_queries()
	result.navigation_dirty=true;result.reachability_dirty=true;result.rooms_dirty=true
	return result
func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size() not in [2,3] or not args[1].is_valid_int() or int(args[1])<1 or int(args[1])>7200:
		printerr("Usage: -- SNAPSHOT|fresh TICKS [lookup|reservation] (1..7200; four pairs)");quit(2);return
	if args.size()==3: reference_mode=args[2]
	if reference_mode not in ["lookup","reservation"]: quit(2);return
	var decoded: Dictionary
	if args[0]=="fresh":
		decoded={"world":ColonyTests.world()}
		var error: String=ColonyGeneration.configure(decoded.world,104729,"meadow_reach")
		if not error.is_empty(): printerr(error);quit(2);return
	else: decoded=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"): printerr(decoded);quit(2);return
	var rows: Array=[];var expected: String="";var exact: bool=true
	for round_index in range(4):
		for original in ([true,false] if round_index%2==0 else [false,true]):
			var world: ColonyWorld=clone_world(decoded.world,original)
			var start: int=Time.get_ticks_usec()
			for index in range(int(args[1])): world.step()
			var elapsed: int=Time.get_ticks_usec()-start
			var hash: String=world.canonical_hash()
			if expected.is_empty(): expected=hash
			exact=exact and hash==expected and world.invariant_errors().is_empty()
			rows.append({"round":round_index,"original":original,"microseconds":elapsed,"hash":hash})
			print(JSON.stringify(rows[-1]))
	print(JSON.stringify({"reference":reference_mode,"reference_commit":"2f1a8fb" if reference_mode=="reservation" else "44fffb9","snapshot":args[0],"snapshot_sha256":FileAccess.get_sha256(args[0]) if args[0]!="fresh" else "","ticks":int(args[1]),"exact":exact,"rows":rows}))
	quit(0 if exact else 1)
