extends SceneTree
## Repeated creation-query microbenchmark, not an ordinary campaign or frame gate.
func _initialize() -> void: call_deferred("run")

func clone_world(source: ColonyWorld) -> ColonyWorld:
	var result: ColonyWorld=ColonyWorld.new(source.definitions)
	for field in source.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=source.get(field)
		if value is Array: result.get(field).assign(value.duplicate(true))
		elif value is Dictionary: result.set(field,value.duplicate(true))
		else: result.set(field,value)
	result.record_indexes.clear();result.reset_job_queries();result.reset_stack_queries()
	result.navigation_dirty=true;result.reachability_dirty=true;result.rooms_dirty=true
	result.in_tick=true
	return result

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or not args[1].is_valid_int() or int(args[1])<1 or int(args[1])>2000:
		printerr("Usage: -- SNAPSHOT|fresh CALLS (1..2000; four alternating pairs)");quit(2);return
	var decoded: Dictionary
	if args[0]=="fresh":
		decoded={"world":ColonyTests.world()}
		var error: String=ColonyGeneration.configure(decoded.world,104729,"meadow_reach")
		if not error.is_empty(): printerr(error);quit(2);return
	else: decoded=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"): printerr(decoded);quit(2);return
	var rows: Array=[];var expected: String="";var exact: bool=true
	for round_index in range(4):
		for full in ([true,false] if round_index%2==0 else [false,true]):
			var world: ColonyWorld=clone_world(decoded.world)
			var start: int=Time.get_ticks_usec()
			for index in range(int(args[1])): CreationReadTests.create(world,full)
			var elapsed: int=Time.get_ticks_usec()-start
			var hash: String=world.canonical_hash()
			if expected.is_empty(): expected=hash
			exact=exact and hash==expected and world.invariant_errors().is_empty()
			rows.append({"round":round_index,"original":full,"microseconds":elapsed,"hash":hash})
	print(JSON.stringify({"scope":"Repeated creation calls at one fixed tick; includes first cold derived-view build, no intervening simulation work","reference_commit":"04500fb","snapshot":args[0],"snapshot_sha256":FileAccess.get_sha256(args[0]) if args[0]!="fresh" else "","calls_per_world":int(args[1]),"exact":exact,"rows":rows}))
	quit(0 if exact else 1)
