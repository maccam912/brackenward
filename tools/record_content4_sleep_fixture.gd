extends SceneTree
## Capture only from frozen fdadd7b / content v4 before correcting sleep eligibility.
const SOURCE: String="fdadd7b1762843351a0dd02c0367049359f7cf1f"
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
func run() -> void:
	var output: Array=[]
	if ColonyWorld.CONTENT_VERSION!="colony-v4" or OS.execute("git",["rev-parse","HEAD"],output,true)!=0 or str(output[0]).strip_edges()!=SOURCE or OS.execute("git",["diff","--exit-code","HEAD","--","src","data","project.godot"],[],true)!=0:
		printerr("Requires unmodified fdadd7b simulation/data in a frozen checkout; do not regenerate with corrected rules");quit(2);return
	if FileAccess.file_exists(DIRECTORY+"content4-preservation.json"): printerr("Evidence already exists; never overwrite it");quit(2);return
	for suffix in ["initial","7200","72000"]:
		var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(DIRECTORY+"content3-replay-"+suffix+".brackenward"));assert(decoded.has("world"))
		write_snapshot(decoded.world,"content4-replay-"+suffix+".brackenward","Reviewed replay checkpoint under v4 header, exact acknowledged gameplay fields")
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(DIRECTORY+"content3-hungry-cook.brackenward"));assert(decoded.has("world"))
	var world: ColonyWorld=decoded.world;world.session_id="content4-low-rest-cook";world.citizens[0].rest=200
	assert(world.invariant_errors().is_empty())
	write_snapshot(world,"content4-low-rest-cook.brackenward","Controlled hungry cook at rest 200, inherited extra grain/consumed meals; not ordinary balance evidence")
	var scratch: String="user://record-content4-%d" % Time.get_ticks_usec()
	var store: ColonyStore=ColonyStore.new();store.directory=scratch
	assert(store.save(world).is_empty())
	var initial_meals: int=world.ledger.produced.get("meal",0)
	for index in range(600):
		world.step()
		if index%120==119: assert(store.checkpoint(world).is_empty())
	assert(world.tick==2400 and world.invariant_errors().is_empty())
	write_snapshot(world,"content4-delta-final.brackenward","600 acknowledged v4 ticks of controlled low-rest case; never resimulate during migration")
	var delta: Dictionary={}
	for pair in [["snapshot-0000000001.brackenward","content4-delta-base.brackenward"],["journal-0000000001.frames","content4-delta.frames"]]:
		var path: String=DIRECTORY+pair[1];assert(not FileAccess.file_exists(path))
		var bytes: PackedByteArray=FileAccess.get_file_as_bytes(scratch.path_join(pair[0]));assert(not bytes.is_empty())
		var file: FileAccess=FileAccess.open(path,FileAccess.WRITE);assert(file!=null);file.store_buffer(bytes);file.close()
		assert(FileAccess.get_file_as_bytes(path)==bytes);delta[pair[1]]=FileAccess.get_sha256(path)
	delta["content4-delta-final.brackenward"]=FileAccess.get_sha256(DIRECTORY+"content4-delta-final.brackenward")
	var loaded: Dictionary=store.load_latest();assert(loaded.has("world") and loaded.world.canonical_hash()==world.canonical_hash())
	var manifest: Dictionary={"source_commit":SOURCE,"content":"colony-v4","schema":23,"catalog_hash":world.definitions.content_hash,"producer_sha256":FileAccess.get_sha256(get_script().resource_path),"scope":"Exact v4 acknowledgements; future feasible-sleep scheduling intentionally changes after this capture","snapshots":entries,"delta":delta,"controlled_final_tick":world.tick,"controlled_meals_produced":world.ledger.produced.get("meal",0)-initial_meals,"controlled_final_rest":world.citizens[0].rest,"controlled_final_activity":world.citizens[0].activity}
	var file: FileAccess=FileAccess.open(DIRECTORY+"content4-preservation.json",FileAccess.WRITE);assert(file!=null);file.store_string(JSON.stringify(manifest,"\t",true)+"\n");file.close()
	CampaignTests.remove_tree(scratch);print(JSON.stringify(manifest));quit(0)
