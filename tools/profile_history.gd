extends SceneTree
## Paired complete-tick timing against the original positive-only lazy lookup.
## The reference is retained from 44fffb9; alternate order, compare full state.
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

func _initialize() -> void: call_deferred("run")
func clone_world(source: ColonyWorld, original: bool) -> ColonyWorld:
	var result: ColonyWorld = OriginalFind.new(source.definitions) if original else ColonyWorld.new(source.definitions)
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
	if args.size()!=2 or not args[1].is_valid_int() or int(args[1])<1 or int(args[1])>7200:
		printerr("Usage: -- SNAPSHOT TICKS (1..7200; four alternating pairs)");quit(2);return
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
	print(JSON.stringify({"snapshot":args[0],"snapshot_sha256":FileAccess.get_sha256(args[0]) if args[0]!="fresh" else "","ticks":int(args[1]),"exact":exact,"rows":rows}))
	quit(0 if exact else 1)
