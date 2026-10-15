class_name LargeColonyScenario
extends RefCounted
## Full twenty-resident summer and prepared winter after natural recruitment.
## Day 64 is the earliest sixteenth four-day offer; use year three's full seasons.
const SUMMER_START: int=72*7200
const SUMMER_END: int=80*7200
const WINTER_START: int=88*7200
const WINTER_END: int=96*7200
const SEASON_TICKS: int=8*7200

static func initial(previous: Dictionary = {}) -> Dictionary:
	return {"summer_home_ticks":previous.get("summer_home_ticks",0),"winter_home_ticks":previous.get("winter_home_ticks",0),"summer_zero_fullness_ticks":previous.get("summer_zero_fullness_ticks",0),"winter_zero_fullness_ticks":previous.get("winter_zero_fullness_ticks",0),"summer_minimum_health":previous.get("summer_minimum_health",100),"winter_minimum_health":previous.get("winter_minimum_health",100)}

static func observe(world: ColonyWorld, metrics: Dictionary) -> void:
	var season: String="summer" if world.tick>=SUMMER_START and world.tick<SUMMER_END else ("winter" if world.tick>=WINTER_START and world.tick<WINTER_END else "")
	if season.is_empty(): return
	var living: Array=world.citizens.filter(func(p:Dictionary)->bool:return not p.death_recorded and not p.departed)
	if living.size()==20 and living.all(func(p:Dictionary)->bool:return not p.away): metrics[season+"_home_ticks"]+=1
	for person in living:
		metrics[season+"_minimum_health"]=mini(metrics[season+"_minimum_health"],person.health)
		if person.fullness==0: metrics[season+"_zero_fullness_ticks"]+=1

static func passes(world: ColonyWorld, metrics: Dictionary, grace_ticks: int) -> bool:
	return world.tick>=WINTER_END and metrics.summer_home_ticks==SEASON_TICKS and metrics.winter_home_ticks==SEASON_TICKS and metrics.summer_zero_fullness_ticks==0 and metrics.winter_zero_fullness_ticks==0 and grace_ticks==0 and ColonyPopulation.living(world)==20 and world.citizens.all(func(p:Dictionary)->bool:return not p.death_recorded and not p.departed) and FoodForecast.calculate(world).ticks>=7200
