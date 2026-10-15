class_name LargeColonyTests
extends RefCounted
## Synthetic planning/acceptance fixtures, never ordinary-campaign certificates.
static func population(count: int) -> ColonyWorld:
	var world: ColonyWorld=ColonyTests.world();var template: Dictionary=world.citizens[0]
	for index in range(count-4):
		world.citizens.append(ColonyWorld.citizen_record(world._id(),"Fixture %d" % (index+5),Vector2i(60+index%8,66+index/8),template.skills.duplicate(),template.xp.duplicate(),template.traits.duplicate(),template.preferred,template.preferences.duplicate(),template.food_tag,""))
		world._record("produced","toolkit",1);world._record("produced","cloak",1)
	world.social_state=ColonySocial.initial_state(world.citizens,world.tick);world.equipment_state=ColonyEquipment.initial_state(world.citizens)
	return world

static func admissions_world() -> ColonyWorld:
	var world: ColonyWorld=population(8)
	for roll in world.structures:
		if roll.definition=="bedroll": roll.user=0
	for index in range(8):
		var bed: Dictionary=world._structure("bed",Vector2i(80+index%4*2,70+index/4*3),0)
		bed.user=world.citizens[index].id;world.citizens[index].bed=bed.id
	world._structure("bed",Vector2i(88,70),0)
	world._structure("table",Vector2i(74,63),0);world._structure("research_desk",Vector2i(78,64),0)
	var cart: Dictionary=ColonyTrade.cart(world)
	world._make_stack("meal",160,"store",cart.id,Vector2i(cart.x,cart.y),true)
	ColonyPopulation.offer(world)
	return world

static func without_queue(world: ColonyWorld) -> Dictionary:
	var result: Dictionary=world.payload().duplicate(true)
	result.erase("pending_commands");result.erase("next_command_id")
	return result

static func run(check: Callable) -> void:
	admissions(check);rooms(check);orders(check);windows(check)

static func admissions(check: Callable) -> void:
	var source: ColonyWorld=admissions_world()
	check.call("LARGE/admission_fixture_is_valid_and_has_real_bed_food_and_offer",source.invariant_errors().is_empty() and ColonyPopulation.acceptance(source,source.population_state.offers[0]).error.is_empty())
	var small: ColonyWorld=HearthReadTests.clone(source,false);var large: ColonyWorld=HearthReadTests.clone(source,false)
	var ordinary: ColonyPolicy=ColonyPolicy.new("first_winter");var expanded: LargeColonyPolicy=LargeColonyPolicy.new()
	for policy in [ordinary,expanded]:
		policy.initialized=true;policy.grow_origin=Vector2i(90,90)
		policy.lodge_origins.assign([Vector2i(10,20),Vector2i(20,20),Vector2i(40,20),Vector2i(50,20),Vector2i(60,20)])
	var baseline: Dictionary=without_queue(large)
	ordinary.plan(small);expanded.plan(large)
	check.call("LARGE/eight_person_policy_still_stops_at_eight",not small.pending_commands.any(func(c:Dictionary)->bool:return c.kind=="newcomer"))
	check.call("LARGE/twenty_policy_only_queues_eligible_ninth_admission",large.pending_commands.filter(func(c:Dictionary)->bool:return c.kind=="newcomer" and c.args.accept).size()==1 and large.citizens.size()==8 and without_queue(large)==baseline)
	large.step();small.step()
	check.call("LARGE/ninth_resident_arrives_only_through_ordinary_command",ColonyPopulation.living(large)==9 and ColonyPopulation.living(small)==8 and large.invariant_errors().is_empty())

static func rooms(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();world.researched.assign(world.definitions.research.keys())
	var policy: LargeColonyPolicy=LargeColonyPolicy.new()
	var origins: Array[Vector2i]=[Vector2i(80,80),Vector2i(90,80),Vector2i(100,80)]
	policy.grow_origin=origins[0];policy.extra_grow_origins.assign(origins.slice(1))
	for origin in origins:
		for y in range(6):
			for x in range(8):
				if x in [0,7] or y in [0,5]: world._structure("door" if Vector2i(x,y)==Vector2i(3,5) else "wood_wall",origin+Vector2i(x,y),0)
	var before: Dictionary=without_queue(world)
	policy._fields(world,"cavecap",72,true)
	var fields: Array=world.pending_commands.filter(func(c:Dictionary)->bool:return c.kind=="field")
	check.call("LARGE/three_real_roofed_rooms_queue_seventy_two_tiles_without_grants",fields.size()==3 and fields.all(func(c:Dictionary)->bool:return c.args.tiles.size()==24) and without_queue(world)==before)
	check.call("LARGE/extra_rooms_and_door_approaches_stay_reserved",policy._reserved_plan(origins[2]+Vector2i(1,1)) and policy._planned_approach(origins[2]+Vector2i(3,6)))
	world.step()
	check.call("LARGE/public_designation_creates_exact_actual_roofed_fields",world.fields.size()==72 and world.fields.all(func(f:Dictionary)->bool:return world.roofed(Vector2i(f.x,f.y))) and world.invariant_errors().is_empty())
	world=ColonyTests.world()
	for origin in origins: world.queue_command("build",{"definition":"door","x":origin.x+3,"y":origin.y+5,"rotation":0})
	world.step();var canonical: String=world.canonical_hash()
	var resumed: LargeColonyPolicy=LargeColonyPolicy.new();resumed.resume(world,[])
	check.call("LARGE/resume_recovers_first_and_extra_grow_rooms_without_world_progress",resumed.grow_origin==origins[0] and resumed.extra_grow_origins==origins.slice(1) and canonical==world.canonical_hash())

static func orders(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world();var cart: Dictionary=ColonyTrade.cart(world)
	for stack in world.stacks:
		if stack.item=="meal": world._record("consumed","meal",stack.count);stack.count=0
	world._make_stack("vegetable",8,"store",cart.id,Vector2i(cart.x,cart.y),true)
	var hearth: Dictionary=world.structures.filter(func(s:Dictionary)->bool:return s.definition=="hearth")[0]
	ColonyProduction.command(world,"recipe_order",{"target":hearth.id,"definition":"cook_meals","mode":"Maintain","value":8,"priority":2,"filters":["vegetable"]})
	ColonyProduction.create_jobs(world)
	var job: Dictionary=world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="craft")[0]
	var reserved: bool=world._reserve(job,world.citizens[0]);world.citizens[0].job=job.id
	check.call("LARGE/meal_upgrade_fixture_owns_real_reserved_inputs",reserved and world.stacks.any(func(s:Dictionary)->bool:return s.reservations.has(job.id)) and world.invariant_errors().is_empty())
	var policy: LargeColonyPolicy=LargeColonyPolicy.new();var before: Dictionary=without_queue(world)
	policy._orders(world,9)
	check.call("LARGE/meal_buffer_upgrade_queues_cancel_disable_and_replacement_only",world.pending_commands.map(func(c:Dictionary)->String:return c.kind)==["cancel","order_enabled","recipe_order"] and world.pending_commands[-1].args.value==48 and without_queue(world)==before)
	world.step()
	check.call("LARGE/replacement_releases_old_batch_and_preserves_usable_station",job.state=="Canceled" and not world.production_state.orders[0].enabled and world.production_state.orders[-1].quantity==48 and world.production_state.orders[-1].enabled and world.invariant_errors().is_empty())

static func windows(check: Callable) -> void:
	var world: ColonyWorld=population(20);var metrics: Dictionary=LargeColonyScenario.initial()
	for tick in [LargeColonyScenario.SUMMER_START-1,LargeColonyScenario.SUMMER_START,LargeColonyScenario.SUMMER_END-1,LargeColonyScenario.SUMMER_END]:
		world.tick=tick;LargeColonyScenario.observe(world,metrics)
	check.call("LARGE/summer_window_includes_exact_start_and_excludes_end",metrics.summer_home_ticks==2 and metrics.winter_home_ticks==0)
	for tick in [LargeColonyScenario.WINTER_START-1,LargeColonyScenario.WINTER_START,LargeColonyScenario.WINTER_END-1,LargeColonyScenario.WINTER_END]:
		world.tick=tick;LargeColonyScenario.observe(world,metrics)
	check.call("LARGE/winter_window_includes_exact_start_and_excludes_end",metrics.summer_home_ticks==2 and metrics.winter_home_ticks==2)
	world.tick=LargeColonyScenario.SUMMER_START;world.citizens[0].away=true;LargeColonyScenario.observe(world,metrics)
	check.call("LARGE/offsite_worker_cannot_count_as_full_home_coverage",metrics.summer_home_ticks==2)
	world.citizens[0].away=false;world.citizens[0].fullness=0;LargeColonyScenario.observe(world,metrics)
	check.call("LARGE/zero_fullness_is_counted_per_person_inside_target_season",metrics.summer_home_ticks==3 and metrics.summer_zero_fullness_ticks==1)
	world.citizens[0].fullness=750;world.tick=LargeColonyScenario.WINTER_END
	world._make_stack("meal",80,"store",ColonyTrade.cart(world).id,Vector2i(66,63),true)
	metrics=LargeColonyScenario.initial();metrics.summer_home_ticks=LargeColonyScenario.SEASON_TICKS;metrics.winter_home_ticks=LargeColonyScenario.SEASON_TICKS
	check.call("LARGE/complete_coverage_still_requires_food_living_population_and_no_grace_failure",LargeColonyScenario.passes(world,metrics,0) and not LargeColonyScenario.passes(world,metrics,1))
	metrics.summer_home_ticks-=1
	check.call("LARGE/one_missing_summer_tick_cannot_pass_release_contract",not LargeColonyScenario.passes(world,metrics,0))
