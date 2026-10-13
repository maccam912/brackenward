class_name DirectorTests
extends RefCounted

static func world() -> ColonyWorld:
	var result: ColonyWorld = ColonyTests.world()
	result.tick=52200;ColonyWeather.initialize(result)
	for entry in result.weather_state.days: entry.kind="clear";entry.mask=[]
	return result

static func run(check: Callable) -> void:
	var colony: ColonyWorld = world()
	var pressure: Dictionary = ColonyDirector.pressure(colony)
	check.call("DIRECTOR/healthy_three_day_colony_pressure_zero",pressure.score==0 and pressure.terms.is_empty())
	for stack in colony.stacks:
		if stack.item=="meal": colony._record("consumed","meal",stack.count);stack.count=0
	check.call("DIRECTOR/food_below_one_day_adds_fifty",ColonyDirector.pressure(colony).score==50 and ColonyDirector.gates(colony).contains("Pressure"))
	colony=world()
	for person in colony.citizens: person.morale=399
	colony.citizens[0].health=59;colony.citizens[1].health=59
	colony.citizens[2].downed=true;colony.citizens[2].health=10
	colony.fire_state.destroyed.append({"target":colony.structures[0].id,"tick":colony.tick-1})
	pressure=ColonyDirector.pressure(colony)
	check.call("DIRECTOR/public_components_cap_at_one_hundred",pressure.score==100 and pressure.terms.size()==4)
	colony=world();colony.director_state.recovery_until=colony.tick+1
	check.call("DIRECTOR/recovery_gate_visible",ColonyDirector.gates(colony).contains("recovering"))
	colony.director_state.recovery_until=0;colony.director_state.last_start=colony.tick-100
	check.call("DIRECTOR/seventy_two_hour_start_spacing",not ColonyDirector.start_allowed(colony,colony.tick+7200))
	colony=world();colony.weather_state.days[-1].kind="flood"
	check.call("DIRECTOR/shown_extreme_weather_reserves_major_spacing",not ColonyDirector.start_allowed(colony,colony.weather_state.days[-1].day*7200+1800))
	colony=world();colony.tick=1800;ColonyWeather.initialize(colony);ColonyDirector.consider(colony)
	check.call("DIRECTOR/no_major_before_day_eight",colony.director_state.major.is_empty())
	colony=world();ColonyDirector.consider(colony)
	var major: Dictionary = colony.director_state.major
	check.call("DIRECTOR/standard_raid_announced_exactly_one_day_ahead",not major.is_empty() and major.kind=="raid" and major.due==colony.tick+7200 and colony.defense_state.raids[0].budget==2 and colony.weather_state.reserved_major_days.has(major.due/7200))
	var saved: Dictionary = ColonyCodec.decode(ColonyCodec.encode(colony))
	check.call("SAVE/major_warning_and_weather_slot_roundtrip",saved.has("world") and saved.world.canonical_hash()==colony.canonical_hash(),str(saved.get("error","")))
	colony.defense_state.raids[0].state="Resolved";ColonyDirector.advance(colony)
	check.call("DIRECTOR/resolution_records_forty_eight_hour_recovery",colony.director_state.major.is_empty() and colony.director_state.history.size()==1 and colony.director_state.recovery_until==colony.tick+14400)
	colony=world();colony.care_state.mode="Hearthside";ColonyDirector.consider(colony)
	check.call("DIRECTOR/hearthside_never_schedules_human_raids",colony.director_state.major.is_empty() and colony.defense_state.raids.is_empty())
	colony=world();colony.care_state.mode="Hearthside"
	var station: Dictionary = colony._structure("charcoal_kiln",Vector2i(80,80),0)
	var wall: Dictionary = colony._structure("wood_wall",Vector2i(79,80),0)
	var job: Dictionary = colony._job("craft","Crafting","Craft",station.id,Vector2i(80,80),16000);job.state="Working";job.worker=1;colony.citizens[0].job=job.id
	check.call("FIRE/unsafe_operating_perimeter_is_concrete",ColonyFire.unsafe(colony,station).any(func(h:Dictionary)->bool:return h.kind=="structure" and h.target==wall.id))
	ColonyDirector.consider(colony);major=colony.director_state.major
	check.call("DIRECTOR/hearthside_overheat_has_twelve_hour_fixed_target",major.kind=="overheat" and major.target==station.id and major.due==colony.tick+3600)
	station.cooking=false;ColonyDirector.advance(colony)
	check.call("DIRECTOR/suspending_original_station_prevents_ignition",colony.director_state.major.is_empty() and ColonyFire.active(colony).is_empty() and colony.director_state.history[0].target==station.id)
	colony=world();colony.care_state.mode="Hearthside";station=colony._structure("charcoal_kiln",Vector2i(80,80),0);wall=colony._structure("wood_wall",Vector2i(79,80),0)
	job=colony._job("craft","Crafting","Craft",station.id,Vector2i(80,80),16000);job.state="Working";job.worker=1;colony.citizens[0].job=job.id
	ColonyDirector.consider(colony);major=colony.director_state.major;colony.tick=major.due;ColonyWeather.initialize(colony)
	for entry in colony.weather_state.days: entry.kind="clear";entry.mask=[]
	ColonyDirector.advance(colony)
	check.call("DIRECTOR/ignored_warning_ignites_announced_station",major.state=="Active" and ColonyFire.burning(colony,"structure",station.id) and colony.director_state.last_start==colony.tick)
	check.call("DIRECTOR/no_new_major_during_fire",ColonyDirector.gates(colony).contains("active"))
	ColonyFire.end(colony,ColonyFire.active(colony)[0],"Test extinguished");ColonyDirector.advance(colony)
	check.call("DIRECTOR/fire_resolution_uses_same_recovery_budget",colony.director_state.major.is_empty() and colony.director_state.recovery_until==colony.tick+14400)
	colony=world()
	check.call("DIRECTOR/raid_budget_uses_people_and_charter_only",ColonyDirector.budget(colony)==2)
	var rng_before: int = colony.director_state.rng
	for index in range(10): ColonyDirector.pressure(colony);ColonyDirector.gates(colony)
	check.call("DIRECTOR/reading_pressure_never_changes_streams",colony.director_state.rng==rng_before)
