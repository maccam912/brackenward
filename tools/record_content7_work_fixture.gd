extends SceneTree
## Run once against the unmodified v7 simulator, before changing hunger rules.
const SOURCE: String = "f338b94f83285ac6501e04b0dd9fe12370256779"
const DIRECTORY: String = "res://tests/fixtures/content7-work/"
var entries: Array = []
func _initialize() -> void: call_deferred("run")
func write_bytes(name: String, bytes: PackedByteArray) -> void:
	assert(not FileAccess.file_exists(DIRECTORY+name))
	var file: FileAccess = FileAccess.open(DIRECTORY+name,FileAccess.WRITE)
	assert(file!=null);file.store_buffer(bytes);file.close()
func snapshot(world: ColonyWorld, name: String) -> void:
	write_bytes(name,ColonyCodec.encode(world))
	entries.append({"file":"content7-work/"+name,"sha256":FileAccess.get_sha256(DIRECTORY+name),"canonical_hash":world.canonical_hash()})
func run() -> void:
	var output: Array = []
	if ColonyWorld.CONTENT_VERSION!="colony-v7" or OS.execute("git",["rev-parse","HEAD"],output,true)!=0 or str(output[0]).strip_edges()!=SOURCE or OS.execute("git",["diff","--exit-code","HEAD","--","src","data","project.godot"],[],true)!=0:
		printerr("Requires unchanged frozen v7 simulator at "+SOURCE);quit(2);return
	if DirAccess.dir_exists_absolute(DIRECTORY): printerr("Never overwrite frozen evidence");quit(2);return
	assert(DirAccess.make_dir_recursive_absolute(DIRECTORY)==OK)
	var world: ColonyWorld = ColonyTests.world();world.session_id="v7-hunger-delivery"
	var person: Dictionary = world.citizens[0];person.x=70;person.y=65;person.fullness=300
	var source: Dictionary = world._make_stack("stone",8,"ground",0,Vector2i(70,65),true)
	var job: Dictionary = world._job("haul","Hauling","",source.id,Vector2i(70,65),0);job.source=source.id
	assert(world._reserve(job,person));person.job=job.id;world._work(person,job)
	assert(job.state=="Delivering" and world.invariant_errors().is_empty())
	snapshot(world,"held-load.brackenward")
	var scratch: String = "user://record-content7-%d" % Time.get_ticks_usec()
	var store: ColonyStore = ColonyStore.new();store.directory=scratch;assert(store.save(world).is_empty())
	for index in range(600):
		world.step()
		if index%120==119: assert(store.checkpoint(world).is_empty())
	snapshot(world,"delta-final.brackenward")
	var delta: Dictionary = {}
	for pair in [["snapshot-0000000001.brackenward","delta-base.brackenward"],["journal-0000000001.frames","delta.frames"]]:
		write_bytes(pair[1],FileAccess.get_file_as_bytes(scratch.path_join(pair[0])));delta["content7-work/"+pair[1]]=FileAccess.get_sha256(DIRECTORY+pair[1])
	delta["content7-work/delta-final.brackenward"]=FileAccess.get_sha256(DIRECTORY+"delta-final.brackenward")
	var path: String = "res://tests/fixtures/content7/campaign-replay-7200.brackenward"
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	entries.append({"file":"content7/campaign-replay-7200.brackenward","sha256":FileAccess.get_sha256(path),"canonical_hash":envelope.sha256})
	var manifest: Dictionary = {"source_commit":SOURCE,"content":"colony-v7","schema":23,"catalog_hash":world.definitions.content_hash,"producer_sha256":FileAccess.get_sha256(get_script().resource_path),"snapshots":entries,"delta":delta}
	var file: FileAccess = FileAccess.open(DIRECTORY+"preservation.json",FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t",true)+"\n");file.close()
	CampaignTests.remove_tree(scratch);print("Frozen v7 load and 600-tick acknowledgement fixtures recorded");quit(0)
