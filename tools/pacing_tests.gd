class_name PacingTests
extends RefCounted

static func movement(check: Callable) -> void:
	# A normal tile takes five logical ticks; rain takes 7.5 and snow six.
	for weather in ["clear","rain","snow"]:
		for injured in [false,true]:
			var world: ColonyWorld=ColonyTests.world()
			world.weather=weather
			var person: Dictionary=world.citizens[0]
			person.x=80;person.y=80;person.traits=["Kind","Private"];person.health=40 if injured else 100
			person.route=[Vector2i(81,80)];person.route_goal=[81,80]
			var distance: int=0
			for tick in range(3): world._walk(person,Vector2i(81,80))
			distance=person.progress
			var expected: int={"clear":6000,"rain":4000,"snow":5000}[weather]
			if injured: expected=expected*750/1000
			check.call("PACING/double_walking_retains_%s_injury_%s" % [weather,injured],distance==expected,str(distance))
			var decoded: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
			check.call("PACING/mid_edge_fraction_roundtrips_%s_injury_%s" % [weather,injured],decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
			if not decoded.has("world"): continue
			var twin: ColonyWorld=decoded.world
			for tick in range(10): world._walk(person,Vector2i(81,80));twin._walk(twin.citizens[0],Vector2i(81,80))
			check.call("PACING/mid_edge_save_continuation_%s_injury_%s" % [weather,injured],world.canonical_hash()==twin.canonical_hash() and person.x==81 and person.progress==0)

static func research(check: Callable) -> void:
	for project in ["storecraft","farming"]:
		var world: ColonyWorld=ColonyTests.world()
		world._structure("research_desk",Vector2i(74,63),0)
		for person in world.citizens: person.preferences.Research=0
		world.citizens[3].preferences.Research=3
		world.queue_command("research_select",{"definition":project})
		var start: int=world.tick
		while world.tick-start<21600 and not world.researched.has(project): world.step()
		var elapsed: int=world.tick-start
		check.call("PACING/one_starting_researcher_takes_two_to_three_days_"+project,world.researched.has(project) and elapsed>=14400 and elapsed<=21600 and world.citizens[3].health==100 and world.invariant_errors().is_empty(),"%.3f game days" % (float(elapsed)/7200.0))
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes("res://tests/fixtures/content12/campaign-replay-7200.brackenward")
	var original: Dictionary=ColonyState.unpack(JSON.parse_string(JSON.parse_string(bytes.get_string_from_utf8()).payload))
	var loaded: Dictionary=ColonyCodec.decode(bytes)
	check.call("PACING/v12_load_keeps_all_acknowledged_gameplay_fields",loaded.has("world") and SchemaCompatibility.normalize(loaded.world,original)==original,str(loaded.get("error","")))
	original.content_hash="0".repeat(64)
	check.call("PACING/v12_load_requires_exact_original_catalog",ColonyCodec.restore(original).get("error","").begins_with("Unknown released v12 catalog"))
	# A job saved under the former 240-point cost remains untouched on load.
	# Its next productive tick must extend the task before exceeding that limit.
	var world: ColonyWorld=ColonyTests.world()
	var desk: Dictionary=world._structure("research_desk",Vector2i(74,63),0)
	world.production_state.project="storecraft";world.production_state.progress.storecraft=239999
	var job: Dictionary=world._job("research","Research","Study",desk.id,Vector2i(desk.x,desk.y),240000)
	job.definition="storecraft";job.work=239999;job.worker=4;job.state="Working";world.citizens[3].job=job.id
	ColonyProduction.research_work(world,world.citizens[3],job)
	var continued: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("PACING/legacy_unfinished_task_extends_on_future_work_and_can_save",not world.researched.has("storecraft") and job.work>240000 and job.required==1440000 and continued.has("world") and continued.world.canonical_hash()==world.canonical_hash(),str(continued.get("error","")))
