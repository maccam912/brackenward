extends SceneTree
## Owned-base allocation observation; never writes a save or advances simulation.
var failed: bool=false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2: printerr("Usage: -- SNAPSHOT NEW_REPORT");quit(2);return
	if FileAccess.file_exists(args[1]): printerr("Report already exists");quit(2);return
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"): printerr(decoded);quit(2);return
	var world: ColonyWorld=decoded.world;var canonical: String=world.canonical_hash()
	var source: Dictionary=fingerprint();var input_sha: String=FileAccess.get_sha256(args[0])
	var captured: Dictionary=ColonyCapture.new().capture(world,[])
	var frozen: ColonyWorld=ColonySaveQueue._world(captured,world.definitions)
	var reference: ColonyStore=ColonyStore.new()
	var owned: ColonySaveQueue.CapturedStore=ColonySaveQueue.CapturedStore.new();owned.owned_capture=captured
	var rows: Array=[]
	for pair in range(4):
		for method in (["copy","owned"] if pair%2==0 else ["owned","copy"]):
			var before: int=OS.get_static_memory_usage();var started: int=Time.get_ticks_usec()
			var retained: Dictionary=reference._retain_payload(frozen) if method=="copy" else owned._retain_payload(frozen)
			var elapsed: int=Time.get_ticks_usec()-started;var growth: int=OS.get_static_memory_usage()-before
			var exact: bool=retained==captured
			rows.append({"pair":pair,"method":method,"elapsed_us":elapsed,"retained_engine_heap_bytes":growth,"complete_payload_equal":exact,"same_capture":is_same(retained,captured)})
			failed=failed or not exact or (method=="owned" and not is_same(retained,captured))
			retained={}
	var unchanged: bool=source==fingerprint() and input_sha==FileAccess.get_sha256(args[0]) and world.canonical_hash()==canonical
	var result: Dictionary={"passed":not failed and unchanged,"source":source,"input_sha256":input_sha,"canonical_hash":canonical,"rows":rows,"unchanged":unchanged,"engine":Engine.get_version_info().string,"scope":"Headless retained-base CPU/allocation observation only; not a frame, whole-save peak, Android PSS or longevity certificate"}
	var file: FileAccess=FileAccess.open(args[1],FileAccess.WRITE)
	if file==null:printerr("Cannot create report");quit(2);return
	file.store_string(JSON.stringify(result,"\t",true));file.close()
	print(JSON.stringify(result));quit(0 if result.passed else 1)

func fingerprint() -> Dictionary:
	var result: Dictionary={}
	for path in ["src/persistence/colony_store.gd","src/persistence/colony_save_queue.gd","src/persistence/colony_capture.gd","tools/profile_save_base.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	return result
