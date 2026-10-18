extends SceneTree
## Capture ordinary adaptive public commands for the v13 replay. Never replace a fixture.
const OUTPUT: String="res://tests/fixtures/content13/campaign-replay-input.json"

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if FileAccess.file_exists(OUTPUT): printerr("Refusing to replace reviewed v13 input");quit(2);return
	var world: ColonyWorld=ColonyWorld.new(ColonyCatalog.load_data(),"colony-v13-pacing-replay")
	var error: String=ColonyGeneration.configure(world,104729,"meadow_reach",2)
	if not error.is_empty(): printerr(error);quit(1);return
	var policy: ColonyPolicy=ColonyPolicy.new("charter")
	while world.tick<72000:
		if world.tick%300==0: policy.plan(world)
		world.step()
		if world.tick%300==0 and not world.invariant_errors().is_empty(): printerr(world.invariant_errors());quit(1);return
	var commands: Array=[]
	for entry in world.command_trace:
		commands.append({"before_tick":entry.tick-1,"kind":entry.command.kind,"args":entry.command.args,"expected_receipt":world.receipts[entry.command.id]})
	var input: Dictionary={"version":1,"campaign_id":world.session_id,"seed":world.seed,"site":world.site_id,"mode":"Standard","start_tick":1800,"checkpoints":[7200,72000],"commands":commands}
	DirAccess.make_dir_recursive_absolute(OUTPUT.get_base_dir())
	var file: FileAccess=FileAccess.open(OUTPUT,FileAccess.WRITE);file.store_string(JSON.stringify(ColonyState.pack(input),"\t",true)+"\n");file.close()
	print("PACING_REPLAY_CAPTURE commands=%d researched=%s" % [commands.size(),str(world.researched)])
	quit()
