extends SceneTree
## Diagnose a retained ordinary scenario using only its recorded public commands.
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=4 or not args[2].is_valid_int():
		printerr("Usage: -- REPORT INITIAL_SNAPSHOT STOP_TICK OUTPUT_PREFIX");quit(2);return
	var input_sha: String=FileAccess.get_sha256(args[1]);var report_sha: String=FileAccess.get_sha256(args[0])
	var report: Variant=ColonyState.unpack(JSON.parse_string(FileAccess.get_file_as_string(args[0])))
	var decoded: Dictionary=ColonyCodec.decode(FileAccess.get_file_as_bytes(args[1]))
	if not report is Dictionary or not report.has("commands") or not decoded.has("world"): printerr("Invalid replay input");quit(2);return
	var world: ColonyWorld=decoded.world;var stop: int=int(args[2])
	if stop<=world.tick or stop>int(report.end_tick): printerr("Stop tick outside retained scenario");quit(2);return
	var checkpoints: Dictionary={}
	for sample in report.samples: checkpoints[sample.tick]=sample.canonical_hash
	var cursor: int=0;var verified: int=0;var failure: String=""
	var started: int=Time.get_ticks_msec()
	# The policy queues next-tick commands after each planning step, before the
	# daily snapshot. Preserve those pending commands in checkpoint comparisons.
	while true:
		while cursor<report.commands.size() and report.commands[cursor].tick==world.tick+1:
			var event: Dictionary=report.commands[cursor];var command: Dictionary=event.command
			world.queue_command(command.kind,command.args,command.id,command.session);cursor+=1
		if cursor<report.commands.size() and report.commands[cursor].tick<=world.tick:
			failure="Recorded command cursor fell behind";break
		if checkpoints.has(world.tick):
			if world.canonical_hash()!=checkpoints[world.tick]: failure="Canonical checkpoint differs at tick "+str(world.tick);break
			verified+=1
		if world.tick%7200==0: print("SCENARIO REPLAY tick ",world.tick," commands ",cursor)
		if world.tick>=stop: break
		world.step()
	var state_hash: String=world.canonical_hash();var people: Array=[]
	for person in world.citizens:
		var job: Dictionary=world.find(world.jobs,person.job)
		var food: Dictionary=world._food(person,job)
		people.append({"person":person.duplicate(true),"job":job.duplicate(true),"bed":world.find(world.structures,person.bed).duplicate(true),"feasible_food":food.duplicate(true)})
	var pure: bool=world.canonical_hash()==state_hash
	var unchanged: bool=input_sha==FileAccess.get_sha256(args[1]) and report_sha==FileAccess.get_sha256(args[0])
	var result: Dictionary={"scope":"Recorded-command diagnostic replay with strict original daily checkpoints; observation grants no progress or supplies","passed":failure.is_empty() and world.tick==stop and pure and unchanged and world.invariant_errors().is_empty(),"failure":failure,"tick":world.tick,"commands_applied":cursor,"checkpoints_verified":verified,"elapsed_ms":Time.get_ticks_msec()-started,"canonical_hash":state_hash,"invariants":world.invariant_errors(),"observation_pure":pure,"inputs_unchanged":unchanged,"initial_snapshot_sha256":input_sha,"report_sha256":report_sha,"harness_sha256":FileAccess.get_sha256(get_script().resource_path),"engine":Engine.get_version_info().string,"source_version":ProjectSettings.get_setting("application/config/version"),"people":people,"food":{"meal":world.available("meal"),"vegetable":world.available("vegetable"),"mushroom":world.available("mushroom")},"danger":ColonyDanger.sources(world),"weather":world.weather,"flooded":world.weather_state.flooded.size(),"region_trips":world.region_state.trips,"supper":world.charter_state.supper}
	var file: FileAccess=FileAccess.open(args[3]+".brackenward",FileAccess.WRITE);file.store_buffer(ColonyCodec.encode(world));file.close()
	file=FileAccess.open(args[3]+".json",FileAccess.WRITE);file.store_string(JSON.stringify(ColonyState.pack(result),"\t",true));file.close()
	print(JSON.stringify({"passed":result.passed,"failure":failure,"tick":world.tick,"checkpoints_verified":verified,"commands_applied":cursor}))
	quit(0 if result.passed else 1)
