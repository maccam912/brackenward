extends SceneTree
## Paired CPU-only resource membership refresh; no frame/GPU/device certification.
func _initialize() -> void: call_deferred("run")

func source_evidence() -> Dictionary:
	var files: Dictionary={}
	for path in ["project.godot","src/presentation/colony_environment.gd","src/presentation/world_view.gd","src/presentation/environment_resource_row.gd","tools/environment_read_tests.gd","tools/profile_resources.gd"]:
		files[path]=FileAccess.get_sha256("res://"+path)
	return {"files":files.size(),"sha256":JSON.stringify(files,"",true).sha256_text(),"scope":"Exact resource refresh, view, row, oracle, project and executed harness bytes"}

func run() -> void:
	var evidence: Dictionary=source_evidence()
	var world: ColonyWorld=ColonyTests.world()
	var error: String=ColonyGeneration.configure(world,104729,"meadow_reach")
	if not error.is_empty(): printerr(error);quit(2);return
	var baseline: String=world.canonical_hash()
	var fast: WorldView=EnvironmentReadTests.make_view(self,world,false)
	var original: WorldView=EnvironmentReadTests.make_view(self,world,true)
	fast._process(0);original._process(0)
	var results: Array=[];var exact: bool=true
	for round_index in range(4):
		for full in ([true,false] if round_index%2==0 else [false,true]):
			var view: WorldView=original if full else fast
			var chunks: Rect2i=view.environment.visible_chunks()
			var started: int=Time.get_ticks_usec()
			for iteration in range(100): view.environment._refresh_resources(chunks)
			var elapsed: int=Time.get_ticks_usec()-started
			exact=exact and EnvironmentReadTests.rows(fast)==EnvironmentReadTests.rows(original) and world.canonical_hash()==baseline
			results.append({"round":round_index,"original":full,"iterations":100,"microseconds":elapsed})
			print(JSON.stringify(results[-1]))
	var unchanged: bool=evidence==source_evidence()
	print(JSON.stringify({"scope":"CPU-only refresh of unchanged visible resources, four alternating pairs; no simulation ticks, GPU, frame-rate or physical certification","reference_commit":"603c1d0","source_evidence":evidence,"source_unchanged":unchanged,"exact":exact and unchanged,"canonical_hash":baseline,"seed":world.seed,"engine":Engine.get_version_info().string,"host":OS.get_name(),"viewport":[480,320],"tile_size":fast.tile_size,"resources":world.resources.size(),"rows":fast.environment.resource_rows.size(),"results":results}))
	fast.get_parent().queue_free();original.get_parent().queue_free();await process_frame
	quit(0 if exact and unchanged else 1)
