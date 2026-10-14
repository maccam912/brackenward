extends SceneTree
## Read-only codec phase profiling, plus verified saves in an isolated directory.
var phases: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func timed(label: String, action: Callable) -> Variant:
	var start: int = Time.get_ticks_usec()
	var result: Variant = action.call()
	phases.append({"phase":label,"microseconds":Time.get_ticks_usec()-start})
	return result

func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()!=1: printerr("Usage: -- SNAPSHOT");quit(2);return
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(args[0])
	var decoded: Dictionary = timed("full_decode",func()->Dictionary:return ColonyCodec.decode(bytes))
	if not decoded.has("world"): printerr(decoded);quit(2);return
	var world: ColonyWorld = decoded.world
	var envelope: Dictionary = timed("envelope_json",func()->Dictionary:return JSON.parse_string(bytes.get_string_from_utf8()))
	var valid_digest: bool = timed("payload_sha256",func()->bool:return envelope.payload.sha256_text()==envelope.sha256)
	var parsed: Dictionary = timed("payload_json",func()->Dictionary:return JSON.parse_string(envelope.payload))
	var unpacked: Dictionary = timed("state_unpack",func()->Dictionary:return ColonyState.unpack(parsed))
	var probe: ColonyWorld = ColonyWorld.new(world.definitions)
	var validation: String = timed("schema_validation",func()->String:return ColonyCodec._validate(unpacked,probe))
	var problems: Array[String] = timed("world_invariants",world.invariant_errors)
	var copied: Dictionary = timed("immutable_capture",func()->Dictionary:return world.payload().duplicate(true))
	var encoded: PackedByteArray = timed("snapshot_encode",func()->PackedByteArray:return ColonyCodec.encode(world))
	var scratch: String = "user://persistence-profile-%d" % Time.get_ticks_usec()
	var store: ColonyStore = ColonyStore.new();store.directory=scratch
	var write_error: String = timed("verified_initial_save",func()->String:return store.save(world))
	world.step()
	var checkpoint_error: String = timed("verified_checkpoint",func()->String:return store.checkpoint(world))
	var recovered: Dictionary = timed("recover_checkpoint",store.load_latest)
	var exact: bool = recovered.has("world") and recovered.world.canonical_hash()==world.canonical_hash()
	print(JSON.stringify({"snapshot":args[0],"bytes":bytes.size(),"phases":phases,"digest_valid":valid_digest,"schema_error":validation,"invariant_errors":problems,"capture_tick":copied.tick,"encoded_bytes":encoded.size(),"write_error":write_error,"checkpoint_error":checkpoint_error,"exact_recovery":exact},"\t",true))
	CampaignTests.remove_tree(scratch)
	quit(0 if valid_digest and validation.is_empty() and problems.is_empty() and write_error.is_empty() and checkpoint_error.is_empty() and exact else 1)
