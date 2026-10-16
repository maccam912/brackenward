extends SceneTree
## SAVE10: frozen player commands, canonical checkpoints and a foreign-host save.
## Current v9 replay keeps the historical generator-1 map and command input.
const GENERATOR_REVISION: int = 1
const INPUT: String = "res://tests/fixtures/content9/campaign-replay-input.json"
const GOLDEN: String = "res://tests/fixtures/content9/campaign-replay-golden.json"
const SAVED: String = "res://tests/fixtures/content9/campaign-replay-7200.brackenward"
var report_path: String = "res://reports/replay.json"
var record_golden: bool = false
var failure: String = ""
var output: Dictionary = {}

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = 0
	while index<args.size():
		if args[index]=="--record-golden" and not record_golden: record_golden=true;index+=1
		elif args[index]=="--report" and index+1<args.size(): report_path=args[index+1];index+=2
		else: printerr("Usage: -- [--record-golden] [--report PATH]");quit(2);return
	call_deferred("run")

func run() -> void:
	if record_golden and (FileAccess.file_exists(GOLDEN) or FileAccess.file_exists(SAVED)):_fail("Reviewed current replay files already exist; never overwrite them");return
	var started: int = Time.get_ticks_msec()
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(INPUT)
	var decoded: Variant = ColonyState.unpack(JSON.parse_string(bytes.get_string_from_utf8()))
	if not _input_valid(decoded): _fail("Replay input schema/order invalid");return
	var input: Dictionary = decoded
	var golden: Dictionary = {}
	if not record_golden:
		var parsed: Variant = ColonyState.unpack(JSON.parse_string(FileAccess.get_file_as_string(GOLDEN)))
		if not parsed is Dictionary or parsed.get("version")!=1 or parsed.get("input_sha256")!=_hash(bytes): _fail("Golden is missing or does not match the exact frozen input bytes");return
		golden=parsed
	var world: ColonyWorld = ColonyWorld.new(ColonyCatalog.load_data(),input.campaign_id)
	var error: String = ColonyGeneration.configure(world,input.seed,input.site,GENERATOR_REVISION)
	if not error.is_empty() or world.tick!=input.start_tick: _fail("Initial map failed: "+error);return
	var initial_hash: String = world.canonical_hash()
	if not record_golden and (golden.get("content_hash")!=world.definitions.content_hash or golden.get("schema_revision")!=world.schema_revision or golden.get("initial_hash")!=initial_hash): _fail("Initial canonical world/content differs from the reviewed golden");return
	var resumed: ColonyWorld
	var recorded_snapshot: PackedByteArray
	var cursor: int = 0
	var checkpoints: Array[Dictionary] = []
	var invariants_checked: int = 0
	while world.tick<input.checkpoints[-1]:
		var queued: Array[Dictionary] = []
		while cursor<input.commands.size() and input.commands[cursor].before_tick==world.tick:
			var command: Dictionary = input.commands[cursor]
			var id: int = world.queue_command(command.kind,command.args)
			if resumed!=null and resumed.queue_command(command.kind,command.args)!=id: _fail("Restored command sequence diverged");return
			queued.append({"id":id,"kind":command.kind,"expected":command.expected_receipt});cursor+=1
		world.step()
		if resumed!=null: resumed.step()
		for command in queued:
			if world.receipts.get(command.id)!=command.expected or (resumed!=null and resumed.receipts.get(command.id)!=command.expected):
				_write(report_path.get_basename()+"-failure.brackenward",ColonyCodec.encode(world))
				_fail("Command %d (%s) receipt differs at tick%d: expected %s, actual %s; failure snapshot retained" % [command.id,command.kind,world.tick,command.expected,world.receipts.get(command.id)])
				return
		if world.tick%300==0:
			invariants_checked+=1
			var problems: Array = world.invariant_errors()
			if resumed!=null: problems.append_array(resumed.invariant_errors())
			if not problems.is_empty(): _fail("Invariant failure at tick%d: %s" % [world.tick,problems]);return
		if world.tick%7200==0: print("REPLAY day %d: tick%d, commands%d" % [world.tick/7200,world.tick,cursor])
		if input.checkpoints.has(world.tick):
			var hash_value: String = world.canonical_hash()
			var snapshot: PackedByteArray = ColonyCodec.encode(world,"SAVE10 tick%d" % world.tick)
			var restored: Dictionary = ColonyCodec.decode(snapshot)
			if not restored.has("world") or restored.world.canonical_hash()!=hash_value: _fail("Snapshot round trip failed at tick%d: %s" % [world.tick,restored.get("error","hash mismatch")]);return
			if resumed!=null and resumed.canonical_hash()!=hash_value: _fail("Continuation from the cross-host save diverged at tick%d" % world.tick);return
			if not record_golden:
				var expected: Array = golden.get("checkpoints",[]).filter(func(c:Dictionary)->bool:return c.tick==world.tick)
				if expected.size()!=1 or expected[0].canonical_hash!=hash_value: _fail("Canonical golden mismatch at tick%d: %s" % [world.tick,hash_value]);return
			checkpoints.append({"tick":world.tick,"canonical_hash":hash_value,"snapshot_roundtrip":true})
			if not _write(report_path.get_basename()+"-%d.brackenward" % world.tick,snapshot): return
			if world.tick==input.checkpoints[0]:
				if record_golden:
					recorded_snapshot=snapshot
					# A later gameplay correction need not replace an earlier foreign
					# save whose canonical state is still exactly compatible.
					if FileAccess.file_exists(SAVED):
						var retained_bytes: PackedByteArray = FileAccess.get_file_as_bytes(SAVED)
						var retained: Dictionary = ColonyCodec.decode(retained_bytes)
						if retained.has("world") and retained.world.canonical_hash()==hash_value: recorded_snapshot=retained_bytes
				var foreign_bytes: PackedByteArray = recorded_snapshot if record_golden else FileAccess.get_file_as_bytes(SAVED)
				if not record_golden and _hash(foreign_bytes)!=golden.get("save_fixture_sha256"): _fail("Cross-host save fixture bytes changed");return
				var foreign: Dictionary = ColonyCodec.decode(foreign_bytes)
				if not foreign.has("world") or foreign.world.canonical_hash()!=hash_value: _fail("Cross-host save import changed the tick7200 world");return
				resumed=foreign.world
	if cursor!=input.commands.size(): _fail("Not every frozen command was executed");return
	output={"version":1,"passed":true,"engine":Engine.get_version_info().string,"platform":OS.get_name(),"architecture":"arm64" if OS.has_feature("arm64") else ("x86_64" if OS.has_feature("x86_64") else "unknown"),"input_sha256":_hash(bytes),"content_hash":world.definitions.content_hash,"schema_revision":world.schema_revision,"initial_hash":initial_hash,"checkpoints":checkpoints,"save_fixture_sha256":_hash(recorded_snapshot if record_golden else FileAccess.get_file_as_bytes(SAVED)),"commands_verified":cursor,"invariants_checked":invariants_checked,"elapsed_ms":Time.get_ticks_msec()-started,"cross_host_save_continuation":resumed.canonical_hash()==world.canonical_hash(),"scope":"Native source replay and save compatibility; exported-app/GPU/physical Android checks are separate."}
	if record_golden:
		if not _write(SAVED,recorded_snapshot): return
		var baseline: Dictionary = output.duplicate(true)
		for key in ["passed","elapsed_ms","invariants_checked","commands_verified","cross_host_save_continuation","scope"]: baseline.erase(key)
		if not _write(GOLDEN,JSON.stringify(ColonyState.pack(baseline),"\t",true).to_utf8_buffer()): return
	if not _write(report_path,JSON.stringify(ColonyState.pack(output),"\t",true).to_utf8_buffer()): return
	print("REPLAY PASS: %d commands; golden ticks7200/72000; save continuation; %d ms" % [cursor,output.elapsed_ms])
	quit(0)

func _input_valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("version")!=1 or not value.get("campaign_id") is String or value.campaign_id.is_empty() or not value.get("seed") is int or value.seed<0 or value.seed>4294967295 or not ColonyGeneration.SITES.has(value.get("site")) or value.get("mode")!="Standard" or value.get("start_tick")!=1800 or value.get("checkpoints")!=[7200,72000] or not value.get("commands") is Array or value.commands.is_empty() or value.commands.size()>4096: return false
	var last_tick: int = value.start_tick
	for command in value.commands:
		if not command is Dictionary or not ColonyCodec._keys(command,["before_tick","kind","args","expected_receipt"]) or not command.before_tick is int or command.before_tick<last_tick or command.before_tick>=72000 or not command.kind is String or not command.args is Dictionary or not command.expected_receipt is String: return false
		last_tick=command.before_tick
	return true

func _hash(bytes: PackedByteArray) -> String:
	var context: HashingContext = HashingContext.new();context.start(HashingContext.HASH_SHA256);context.update(bytes)
	return context.finish().hex_encode()

func _write(path: String, bytes: PackedByteArray) -> bool:
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: _fail("Unable to create report directory");return false
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file==null: _fail("Unable to write "+path);return false
	file.store_buffer(bytes);file.flush()
	var error: Error = file.get_error();file.close()
	if error!=OK: _fail("Unable to finish writing "+path);return false
	return true

func _fail(reason: String) -> void:
	failure=reason;printerr("REPLAY FAIL: "+reason)
	quit(1)
