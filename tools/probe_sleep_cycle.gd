extends SceneTree
## Observe owned cook releases/reacquisitions; instrumentation never changes the rules.
class ObservedWorld extends ColonyWorld:
	var cook_releases: int=0
	var cook_reservations: int=0
	func _init(catalog: Dictionary) -> void: super(catalog)
	func _release(job: Dictionary, cancel: bool) -> void:
		if not cancel and job.get("kind")=="cook" and job.get("worker",0)>0: cook_releases+=1
		super(job,cancel)
	func _reserve(job: Dictionary, citizen: Dictionary, context: Dictionary = {}) -> bool:
		var result: bool=super(job,citizen,context)
		if result and job.kind=="cook": cook_reservations+=1
		return result
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=2 or not args[1].is_valid_int() or int(args[1])<1 or int(args[1])>1200: quit(2);return
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.has("world"): printerr(decoded);quit(2);return
	var world: ColonyWorld=decoded.world;var observed: ObservedWorld=ObservedWorld.new(world.definitions)
	for field in world.payload():
		if field in ["content","content_hash"]: continue
		var value: Variant=world.get(field)
		if value is Array: observed.get(field).assign(value.duplicate(true))
		elif value is Dictionary: observed.set(field,value.duplicate(true))
		else: observed.set(field,value)
	observed.record_indexes.clear();observed.reset_job_queries();observed.reset_stack_queries();observed.navigation_dirty=true;observed.reachability_dirty=true;observed.rooms_dirty=true
	var meals: int=world.ledger.produced.get("meal",0)
	var start_tick: int=world.tick
	for index in range(int(args[1])): world.step();observed.step()
	var exact: bool=world.canonical_hash()==observed.canonical_hash() and world.invariant_errors().is_empty()
	print(JSON.stringify({"scope":"Controlled observation from retained stress save, not ordinary-play or a release certificate","instrumentation_exact":exact,"source_content":world.CONTENT_VERSION,"start_tick":start_tick,"final_tick":world.tick,"input_sha256":FileAccess.get_sha256(args[0]),"cook_releases":observed.cook_releases,"cook_reservations":observed.cook_reservations,"meals_produced":world.ledger.produced.get("meal",0)-meals,"canonical_hash":world.canonical_hash(),"harness_sha256":FileAccess.get_sha256(get_script().resource_path)}))
	quit(0 if exact else 1)
