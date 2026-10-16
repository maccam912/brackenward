class_name HaulingPriorityTests
extends RefCounted

static func haul(world: ColonyWorld) -> Dictionary:
	var source: Dictionary = world._make_stack("stone",8,"ground",0,Vector2i(70,65),true)
	var job: Dictionary = world._job("haul","Hauling","",source.id,Vector2i(70,65),0)
	job.source=source.id;job.priority=3;job.created=world.tick-14400
	return job

static func floor_job(world: ColonyWorld, blocked: bool = false) -> Dictionary:
	var job: Dictionary = world._job("build","Building","Build",0,Vector2i(74,54),2000)
	job.definition="wood_floor";job.inputs={"iron":999} if blocked else {"wood":1};job.priority=1
	return job

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world();var person: Dictionary = world.citizens[0]
	check.call("HAUL/default_is_last_for_all_four_starting_residents",world.citizens.all(func(c:Dictionary)->bool:return c.preferences.Hauling==1))
	var independent: bool = true
	for preferred in ColonyPopulation.PREFERRED:
		var defaults: Dictionary = ColonyWorld.default_preferences(preferred)
		independent=independent and defaults.Hauling==1 and defaults[preferred]==3 and defaults.Research==(3 if preferred=="Research" else 1) and defaults.Guard==1
	person.preferences.Hauling=0
	check.call("HAUL/default_preferences_keep_specialties_and_independent_containers",independent and world.citizens[1].preferences.Hauling==1)
	world=ColonyTests.world();person=world.citizens[0]
	var carrying: Dictionary = haul(world);var building: Dictionary = floor_job(world)
	world._assign(person)
	check.call("HAUL/low_priority_other_work_beats_urgent_aged_last_hauling",person.job==building.id and carrying.worker==0 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();person=world.citizens[0];carrying=haul(world)
	var desk: Dictionary = world._structure("research_desk",Vector2i(74,65),0)
	world.production_state.project="storecraft"
	var research: Dictionary = world._job("research","Research","Study",desk.id,Vector2i(desk.x,desk.y),240000)
	research.definition="storecraft";research.priority=1
	world._assign(person)
	check.call("HAUL/even_other_last_work_precedes_fallback_hauling",person.preferences.Research==1 and person.job==research.id and carrying.worker==0)
	world=ColonyTests.world();person=world.citizens[0];carrying=haul(world);building=floor_job(world,true)
	world._assign(person)
	check.call("HAUL/blocked_other_work_allows_useful_fallback_instead_of_idle",person.job==carrying.id and building.state=="Blocked" and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();person=world.citizens[0];carrying=haul(world);world._assign(person)
	check.call("HAUL/no_other_work_starts_hauling",person.job==carrying.id)
	for preference in [0,2,3]:
		world=ColonyTests.world();person=world.citizens[0];person.preferences.Hauling=preference
		carrying=haul(world);building=floor_job(world)
		world._assign(person)
		check.call("HAUL/explicit_preference_%d_is_honored" % preference,person.job==(building.id if preference==0 else carrying.id))
	world=ColonyTests.world();person=world.citizens[0];carrying=haul(world);building=floor_job(world)
	person.pinned_job=carrying.id;world._assign(person)
	check.call("HAUL/explicit_pin_can_request_a_last_haul_next",person.job==carrying.id and building.worker==0)
	world=ColonyTests.world();person=world.citizens[0];person.preferences.Hauling=0
	building=floor_job(world);world._assign(person)
	check.call("HAUL/builder_fetches_own_inputs_even_when_hauling_off",person.job==building.id and building.state=="Fetching" and world.stacks.any(func(s:Dictionary)->bool:return s.reservations.get(building.id,0)>0))
	world=ColonyTests.world();person=world.citizens[0];carrying=haul(world);building=floor_job(world);carrying.emergency=true
	world._assign(person)
	check.call("HAUL/emergency_assignment_still_precedes_ordinary_work",person.job==carrying.id and building.worker==0)
	world=ColonyTests.world();world.tick=5400;person=world.citizens[0];carrying=haul(world);building=floor_job(world)
	world._assign(person)
	check.call("HAUL/aged_urgent_fallback_does_not_bypass_scheduled_leisure",world.find(world.jobs,person.job).get("kind")=="leisure" and carrying.worker==0 and building.worker==0)
	# Loaded preferences remain exact, including deliberate First/Off choices.
	var loaded: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/content8-work/held-load.brackenward"))
	check.call("HAUL/v8_load_preserves_its_saved_normal_hauling_preference",loaded.has("world") and loaded.world.citizens.all(func(c:Dictionary)->bool:return c.preferences.Hauling==2))
	world=ColonyTests.world();world.citizens[0].preferences.Hauling=3;world.citizens[1].preferences.Hauling=0
	loaded=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("HAUL/save_reload_retains_all_explicit_work_settings",loaded.has("world") and loaded.world.citizens.map(func(c:Dictionary)->Dictionary:return c.preferences)==world.citizens.map(func(c:Dictionary)->Dictionary:return c.preferences))
