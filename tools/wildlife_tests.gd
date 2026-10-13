class_name WildlifeTests
extends RefCounted

static func run(check: Callable) -> void:
	var world: ColonyWorld = ColonyTests.world()
	ColonyGeneration.configure(world,104729,"meadow_reach")
	check.call("ANIMAL/initial_six_four_two_four",["hare","deer","boar","marsh_goose"].map(func(k:String)->int:return world.wildlife_state.animals.filter(func(a:Dictionary)->bool:return a.definition==k).size())==[6,4,2,4])
	var bytes: PackedByteArray = ColonyCodec.encode(world)
	var decoded: Dictionary = ColonyCodec.decode(bytes)
	check.call("SAVE/wildlife_positions_and_streams_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	var initial: String = world.canonical_hash()
	for i in range(650): world.step(); decoded.world.step()
	check.call("ANIMAL/forage_moves_and_reloads_identically",initial!=world.canonical_hash() and world.canonical_hash()==decoded.world.canonical_hash() and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world = ColonyTests.world()
	var hare: Dictionary = ColonyWildlife.spawn(world,"hare",Vector2i(73,66))
	world.queue_command("hunt",{"target":hare.id,"solo":false,"citizen":3})
	for i in range(900): world.step()
	check.call("HUNT/armed_gatherer_kills_and_butchers_real_hare",hare.health==0 and world.ledger.produced.get("meat",0)==3 and world.ledger.produced.get("leather",0)==1 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="butcher" and j.state=="Complete"),str(world.wildlife_state))
	check.call("HUNT/yields_are_physical_and_conserved",world.invariant_errors().is_empty() and world.stacks.any(func(s:Dictionary)->bool:return s.item=="meat" and s.count>0),str(world.invariant_errors()))
	decoded = ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("SAVE/completed_hunt_and_carcass_roundtrip",decoded.has("world") and decoded.world.canonical_hash()==world.canonical_hash(),str(decoded.get("error","")))
	world = ColonyTests.world()
	var boar: Dictionary = ColonyWildlife.spawn(world,"boar",Vector2i(73,66))
	for c in world.citizens: c.preferences.Guard = 0
	world.queue_command("hunt",{"target":boar.id,"solo":false,"citizen":0})
	for i in range(120): world.step()
	check.call("HUNT/boar_waits_for_armed_guard",boar.health==90 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="hunt" and j.reason.contains("second armed")))
	for c in world.citizens: c.preferences.Guard = 1
	for i in range(1600): world.step()
	check.call("HUNT/two_armed_workers_complete_boar_hunt",boar.health==0 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="escort_hunt" and j.state=="Complete") and world.ledger.produced.get("meat",0)==10 and world.ledger.produced.get("leather",0)==3,str(world.jobs.filter(func(j:Dictionary)->bool:return j.kind in ["hunt","escort_hunt","butcher"])))
	world = ColonyTests.world(); boar = ColonyWildlife.spawn(world,"boar",Vector2i(73,66))
	world.queue_command("hunt",{"target":boar.id,"solo":true,"citizen":0}); world.step()
	check.call("HUNT/solo_override_creates_no_escort",world.jobs.any(func(j:Dictionary)->bool:return j.kind=="hunt") and not world.jobs.any(func(j:Dictionary)->bool:return j.kind=="escort_hunt"))
	var again: int = world.queue_command("hunt",{"target":boar.id,"solo":true,"citizen":0}); world.step()
	check.call("HUNT/duplicate_target_rejected",world.receipts[again].contains("already"))
	world = ColonyTests.world(); hare = ColonyWildlife.spawn(world,"hare",Vector2i(68,66))
	for c in world.citizens: c.preferences.Gathering = 0
	world.queue_command("hunt",{"target":hare.id,"solo":false,"citizen":0})
	for i in range(120): world.step()
	check.call("HUNT/gathering_off_never_attacks",hare.health==24)
	world = ColonyTests.world(); hare = ColonyWildlife.spawn(world,"hare",Vector2i(74,68))
	hare.health = 0; ColonyWildlife.kill(world,hare)
	check.call("HUNT/kill_alone_produces_no_instant_food",world.total("meat")==0 and world.wildlife_state.carcasses.size()==1 and world.jobs[-1].required==6000)
	var carcass: Dictionary = world.wildlife_state.carcasses[0]
	world.tick = carcass.expires; ColonyWeather.initialize(world); ColonyWildlife.advance(world)
	check.call("HUNT/carcass_two_day_spoil_cancels_work",carcass.spoiled and world.jobs[-1].state=="Canceled" and world.total("meat")==0)
	world = ColonyTests.world()
	var person: Dictionary = world.citizens[0]
	person.x=74; person.y=68; person.edge_x=74; person.edge_y=68
	boar = ColonyWildlife.spawn(world,"boar",Vector2i(75,68)); boar.attacker=person.id; boar.health=9
	var job: Dictionary = world._job("hunt","Gathering","Guard",boar.id,Vector2i(75,68),0)
	job.worker=person.id; job.state="Working"; person.job=job.id; person.health=41
	ColonyCombat.resolve(world)
	check.call("COMBAT/simultaneous_hit_survives_target_death",boar.health==0 and person.health==29)
	check.call("COMBAT/spear_damage_and_twenty_tick_cooldown",person.attack_ready==world.tick+20)
	world = ColonyTests.world(); person=world.citizens[0]; person.x=74;person.y=68;person.health=25
	boar=ColonyWildlife.spawn(world,"boar",Vector2i(75,68));boar.health=60;boar.attacker=person.id
	ColonyCombat.resolve(world)
	check.call("COMBAT/boar_downing_caps_and_records_real_cause",person.downed and person.health==13 and world.wildlife_state.injuries.has(person.injury_id))
	boar.cooldown=0; ColonyCombat.resolve(world)
	check.call("COMBAT/boar_never_attacks_downed_patient",person.health==13)
	check.call("COMBAT/bow_range_and_close_unarmed",ColonyCombat.weapon(world.citizens[2],2).range==6 and ColonyCombat.weapon(world.citizens[2],1).damage==5)
	world._structure("wood_wall",Vector2i(76,68),0)
	check.call("COMBAT/wall_blocks_bow_line_of_sight",not ColonyCombat.line_of_sight(world,Vector2i(74,68),Vector2i(78,68)))
	world = ColonyTests.world(); person=world.citizens[0];person.x=74;person.y=68;person.equipment.vest="vest"
	boar=ColonyWildlife.spawn(world,"boar",Vector2i(75,68));boar.health=60;boar.attacker=person.id
	ColonyCombat.resolve(world)
	check.call("COMBAT/vest_reduces_each_boar_hit_by_two",person.health==90)
	world=ColonyTests.world(); ColonyGeneration.configure(world,104729,"meadow_reach")
	for a in world.wildlife_state.animals: a.health=0
	world.tick=23400; ColonyWeather.initialize(world); ColonyWildlife.replenish(world)
	check.call("ANIMAL/fourth_day_replaces_only_two_nonboars",world.wildlife_state.animals.filter(func(a:Dictionary)->bool:return a.health>0).size()==2 and world.wildlife_state.animals.filter(func(a:Dictionary)->bool:return a.health>0 and a.definition=="boar").is_empty())
	var bad: Dictionary = world.payload().duplicate(true);bad.wildlife_state.animals[0].rng=0
	check.call("SAVE/rejects_zero_animal_rng",ColonyCodec.restore(bad).has("error"))
	var old: Dictionary = ColonyCodec.decode(FileAccess.get_file_as_bytes("res://tests/fixtures/m4-care.brackenward"))
	check.call("SAVE/v1_catalog_care_and_map_migrate",old.has("world") and old.world.citizens[2].health==27 and old.world.generator_version==0 and old.world.wildlife_state.animals.size()==16,str(old.get("error","")))
	world=ColonyTests.world(); hare=ColonyWildlife.spawn(world,"hare",Vector2i(74,68));hare.route=[Vector2i(75,68)]
	for i in range(6): ColonyWildlife._move(world,hare)
	check.call("ANIMAL/hare_has_exact_seven_tick_tile",hare.x==74)
	ColonyWildlife._move(world,hare)
	check.call("ANIMAL/seventh_tick_completes_one_tile",hare.x==75 and hare.progress==0 and hare.move_rem==0)
	world=ColonyTests.world(); world.queue_command("field",{"tiles":[Vector2i(74,68)],"crop":"turnip"});world.step()
	var field: Dictionary = world.fields[0];field.prepared=true;field.planted=true;field.yield_count=4
	hare=ColonyWildlife.spawn(world,"hare",Vector2i(74,68))
	ColonyWildlife.advance(world);ColonyWildlife.advance(world)
	check.call("ANIMAL/crop_bite_once_per_animal_per_day",field.yield_count==3 and field.reason.contains("Wildlife"))
	field.yield_count=1;hare.crop_day=-1
	var second_hare: Dictionary = ColonyWildlife.spawn(world,"hare",Vector2i(74,68))
	ColonyWildlife.advance(world)
	check.call("ANIMAL/same_tick_crop_exhaustion_visible_to_later_animals",field.yield_count==0 and hare.crop_day==world.tick/7200 and second_hare.crop_day== -1)
	field.yield_count=4;field.planted=false;hare.crop_day=-1
	ColonyWildlife.advance(world)
	check.call("ANIMAL/unplanted_crop_removed_from_next_tick_lookup",field.yield_count==4 and hare.crop_day== -1 and second_hare.crop_day== -1)
	field.planted=true
	ColonyWildlife.advance(world)
	check.call("ANIMAL/newly_planted_crop_available_without_stale_index",field.yield_count==2 and second_hare.crop_day==world.tick/7200)
	world._structure("pen_gate",Vector2i(75,68),0)
	check.call("ANIMAL/fence_gate_blocks_unhandled_wildlife",not ColonyWildlife.animal_walkable(world,Vector2i(75,68)))
	world=ColonyTests.world();boar=ColonyWildlife.spawn(world,"boar",Vector2i(74,68))
	world.queue_command("hunt",{"target":boar.id,"solo":false,"citizen":0});world.step()
	job=world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="hunt")[0]
	world.queue_command("cancel",{"target":job.id});world.step()
	check.call("HUNT/cancel_releases_escort_too",world.jobs.filter(func(j:Dictionary)->bool:return j.kind in ["hunt","escort_hunt"]).all(func(j:Dictionary)->bool:return j.state=="Canceled"))
	world=ColonyTests.world();boar=ColonyWildlife.spawn(world,"boar",Vector2i(54,54))
	for c in world.citizens: c.preferences.Guard=0
	world.queue_command("hunt",{"target":boar.id,"solo":false,"citizen":0})
	world.queue_command("gather",{"target":world.resources[0].id})
	for i in range(20): world.step()
	check.call("DANGER/ordinary_work_blocks_dangerous_hunt_area",world.resources[0].remaining==8 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="gather" and j.reason.contains("Unsafe route")))
	world=ColonyTests.world();boar=ColonyWildlife.spawn(world,"boar",Vector2i(66,66));boar.health=70;boar.attacker=1
	world._assign(world.citizens[0])
	job=world.find(world.jobs,world.citizens[0].job)
	check.call("DANGER/civilian_escapes_before_ordinary_work",job.kind=="escape" and ColonyDanger.safe(world,Vector2i(job.x,job.y)))
