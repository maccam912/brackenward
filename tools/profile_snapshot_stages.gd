extends SceneTree
## Instrument the full-tree e8336e4 reference; never write the input.
var mutex: Mutex=Mutex.new()
var stage: String="idle"
var entries: Dictionary={}

func _initialize() -> void:call_deferred("run")

func mark(value: String) -> void:
	mutex.lock();stage=value;entries[value]=OS.get_static_memory_usage();mutex.unlock()

func prepare(captured: Dictionary, catalog: Dictionary) -> Dictionary:
	mark("pack")
	var packed: Variant=ColonyState.pack(captured)
	mark("stringify")
	var text: String=JSON.stringify(packed,"",true);packed=null
	mark("envelope")
	var identity: ColonyWorld=ColonyWorld.new(catalog);identity.session_id=captured.session_id;identity.generator_version=captured.generator_version
	var bytes: PackedByteArray=ColonyCodec.wrap_payload(identity,text)
	if bytes.is_empty() or bytes.size()>ColonyCodec.MAX_BYTES:return {"error":"Envelope bound failed"}
	bytes=PackedByteArray();identity=null
	mark("parse")
	var parser: JSON=JSON.new()
	if parser.parse(text)!=OK:return {"error":"Payload parse failed"}
	mark("unpack")
	var data: Variant=ColonyPreparedSnapshot._unpack_owned_json(parser.data);parser=null
	if not data is Dictionary:return {"error":"Owned state decode failed"}
	mark("restore")
	var verified: Dictionary=ColonyCodec.restore(data)
	mark("compare")
	if not verified.has("world") or verified.world.payload()!=captured:return {"error":"Full restore/equality failed"}
	mark("complete")
	return {"text":text}

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or not FileAccess.file_exists(args[0]) or FileAccess.file_exists(args[1]):printerr("Usage: -- SNAPSHOT NEW_REPORT");quit(2);return
	var source: Dictionary=fingerprints();var input_sha: String=FileAccess.get_sha256(args[0])
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"):printerr(decoded);quit(2);return
	var world: ColonyWorld=decoded.world;var canonical: String=world.canonical_hash()
	var retired: Array=[];var captured: Dictionary=ColonyCapture.new().capture(world,retired)
	var control: Dictionary=ColonyPreparedSnapshot.prepare(captured,world.definitions)
	if not control.has("snapshot"):printerr(control);quit(2);return
	var expected: String=control.snapshot.text;control={}
	var rows: Array=[];var passed: bool=true
	for round_index in range(2):
		entries={};stage="starting"
		var baseline: int=OS.get_static_memory_usage();var peaks: Dictionary={};var samples: Dictionary={}
		var thread: Thread=Thread.new();var started: int=Time.get_ticks_usec()
		if thread.start(prepare.bind(captured,world.definitions))!=OK:printerr("Worker startup failed");quit(2);return
		while thread.is_alive():
			mutex.lock();var current: String=stage;mutex.unlock()
			peaks[current]=maxi(peaks.get(current,baseline),OS.get_static_memory_usage());samples[current]=samples.get(current,0)+1
			OS.delay_usec(1000)
		var result: Dictionary=thread.wait_to_finish();var exact: bool=result.get("text","")==expected and expected.sha256_text()==canonical
		var stages: Array=[]
		for name in entries:
			stages.append({"stage":name,"entry_growth_bytes":entries[name]-baseline,"sampled_peak_growth_bytes":peaks.get(name,entries[name])-baseline,"samples":samples.get(name,0)})
		rows.append({"round":round_index,"elapsed_us":Time.get_ticks_usec()-started,"baseline_engine_heap":baseline,"exact_full_text":exact,"stages":stages,"error":result.get("error","")})
		passed=passed and exact;result={};thread=null
	var unchanged: bool=source==fingerprints() and input_sha==FileAccess.get_sha256(args[0]) and world.canonical_hash()==canonical
	var report: Dictionary={"passed":passed and unchanged,"reference_commit":"e8336e4","scope":"Instrumented full-tree reference stages, two workers in sequence, sampled process engine heap at roughly 1 ms. The baseline includes the retained reference payload text. Explicit packed-tree lifetime and labels can affect timing. This is allocation diagnosis, not current bounded-stage attribution, the native thirty-minute peak proxy, Android PSS or device certification.","source":source,"input_sha256":input_sha,"canonical_hash":canonical,"unchanged":unchanged,"engine":Engine.get_version_info().string,"rows":rows}
	var file: FileAccess=FileAccess.open(args[1],FileAccess.WRITE)
	if file==null:printerr("Cannot create report");quit(2);return
	file.store_string(JSON.stringify(report,"\t",true));file.close();print(JSON.stringify(report));quit(0 if report.passed else 1)

func fingerprints() -> Dictionary:
	var result: Dictionary={}
	for path in ["project.godot","toolchain.lock.json","tools/profile_snapshot_stages.gd"]:result[path]=FileAccess.get_sha256("res://"+path)
	for folder in ["src","data/catalogs"]:collect("res://"+folder,result)
	return result

func collect(folder: String, result: Dictionary) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() in ["gd","json"]:result[folder.path_join(file)]=FileAccess.get_sha256(folder.path_join(file))
	for subdirectory in DirAccess.get_directories_at(folder):collect(folder.path_join(subdirectory),result)
