extends SceneTree
## Frozen content-v5 acknowledgements, captured before changing rest pacing.
const SOURCE: String="245f9359d8220ed17a94f544b7a79f85052c7d86"
const DIRECTORY: String="res://tests/fixtures/"
var entries: Array=[]
func _initialize() -> void: call_deferred("run")
func write_snapshot(world: ColonyWorld, name: String, role: String) -> void:
	var path: String=DIRECTORY+name
	assert(not FileAccess.file_exists(path))
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE);assert(file!=null)
	var bytes: PackedByteArray=ColonyCodec.encode(world);file.store_buffer(bytes);file.close()
	assert(FileAccess.get_file_as_bytes(path)==bytes)
	entries.append({"file":name,"sha256":FileAccess.get_sha256(path),"canonical_hash":world.canonical_hash(),"role":role})
func sleepers(rests: Array, working: bool) -> ColonyWorld:
	var world: ColonyWorld=ColonyTests.world();world.session_id="content5-sleep-"+("rested" if working else "mixed");world.tick=6900
	var beds: Array=world.structures.filter(func(b:Dictionary)->bool:return b.definition in ["bed","bedroll"])
	assert(beds.size()>=4)
	for index in range(4):
		var person: Dictionary=world.citizens[index];var bed: Dictionary=beds[index]
		person.bed=bed.id;person.x=bed.x;person.y=bed.y;person.edge_x=bed.x;person.edge_y=bed.y;person.progress=0;person.fullness=1000;person.rest=rests[index]
		if working:
			var job: Dictionary=world._job("sleep","","",bed.id,Vector2i(bed.x,bed.y),0)
			job.worker=person.id;job.state="Working";job.work_x=bed.x;job.work_y=bed.y;person.job=job.id;person.activity="Sleeping"
	assert(world.invariant_errors().is_empty())
	return world
func run() -> void:
	var output: Array=[]
	if ColonyWorld.CONTENT_VERSION!="colony-v5" or OS.execute("git",["rev-parse","HEAD"],output,true)!=0 or str(output[0]).strip_edges()!=SOURCE or OS.execute("git",["diff","--exit-code","HEAD","--","src","data","project.godot"],[],true)!=0:
		printerr("Requires unmodified frozen 245f935 / content v5; never regenerate under future rest rules");quit(2);return
	if FileAccess.file_exists(DIRECTORY+"content5-preservation.json"): printerr("Evidence already exists; never overwrite it");quit(2);return
	for suffix in ["initial","7200","72000"]:
		var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(DIRECTORY+"content4-replay-"+suffix+".brackenward"));assert(decoded.has("world"))
		write_snapshot(decoded.world,"content5-replay-"+suffix+".brackenward","Reviewed acknowledgement under v5 header; exact fields, not a fresh campaign run")
	var world: ColonyWorld=sleepers([1000,1000,1000,1000],true)
	write_snapshot(world,"content5-rested-sleepers.brackenward","Controlled fully rested sleepers at 23:00 in assigned bedrolls; not balance evidence")
	write_snapshot(sleepers([150,450,750,1000],false),"content5-mixed-tiredness.brackenward","Controlled varying rest at 23:00, no assigned jobs; not balance evidence")
	var scratch: String="user://record-content5-%d" % Time.get_ticks_usec()
	var store: ColonyStore=ColonyStore.new();store.directory=scratch
	assert(store.save(world).is_empty())
	for index in range(600):
		world.step()
		if index%120==119: assert(store.checkpoint(world).is_empty())
	assert(world.tick==7500 and world.invariant_errors().is_empty())
	write_snapshot(world,"content5-delta-final.brackenward","600 acknowledged v5 ticks of fully rested night sleepers; retain exact original state")
	var delta: Dictionary={}
	for pair in [["snapshot-0000000001.brackenward","content5-delta-base.brackenward"],["journal-0000000001.frames","content5-delta.frames"]]:
		var path: String=DIRECTORY+pair[1];assert(not FileAccess.file_exists(path))
		var bytes: PackedByteArray=FileAccess.get_file_as_bytes(scratch.path_join(pair[0]));assert(not bytes.is_empty())
		var file: FileAccess=FileAccess.open(path,FileAccess.WRITE);assert(file!=null);file.store_buffer(bytes);file.close()
		assert(FileAccess.get_file_as_bytes(path)==bytes);delta[pair[1]]=FileAccess.get_sha256(path)
	delta["content5-delta-final.brackenward"]=FileAccess.get_sha256(DIRECTORY+"content5-delta-final.brackenward")
	var loaded: Dictionary=store.load_latest();assert(loaded.has("world") and loaded.world.canonical_hash()==world.canonical_hash())
	var manifest: Dictionary={"source_commit":SOURCE,"content":"colony-v5","schema":23,"catalog_hash":world.definitions.content_hash,"producer_sha256":FileAccess.get_sha256(get_script().resource_path),"scope":"Exact v5 acknowledgements; future independent sleep/rest pacing changes after capture","snapshots":entries,"delta":delta,"controlled_final_tick":world.tick,"controlled_final_rest":world.citizens.map(func(p:Dictionary)->int:return p.rest),"controlled_final_activities":world.citizens.map(func(p:Dictionary)->String:return p.activity)}
	var file: FileAccess=FileAccess.open(DIRECTORY+"content5-preservation.json",FileAccess.WRITE);assert(file!=null);file.store_string(JSON.stringify(manifest,"\t",true)+"\n");file.close()
	CampaignTests.remove_tree(scratch);print(JSON.stringify(manifest));quit(0)
