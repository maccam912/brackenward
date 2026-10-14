class_name StressFixture
extends RefCounted
## Synthetic release-load fixture, never ordinary-play/balance evidence.
## Uses real records, geometry and ledgers; no simulation override runs afterward.

static func make() -> Dictionary:
	var world: ColonyWorld = ColonyTests.world()
	world.session_id="synthetic-stress-v1"
	world.resources.clear();world.nature_state=ColonyNature.initial_state(world.tick)
	world.navigation_dirty=true;world.reachability_dirty=true;world.record_indexes.clear()
	world.weather="rain";ColonyWeather.initialize(world)
	world.researched.assign(world.definitions.research.keys())
	var template: Dictionary = world.citizens[0]
	for index in range(16):
		var person: Dictionary = ColonyWorld.citizen_record(world._id(),"Stress "+str(index+5),Vector2i(60+index%8,66+index/8),template.skills.duplicate(),template.xp.duplicate(),template.traits.duplicate(),template.preferred,template.preferences.duplicate(),template.food_tag,"")
		world.citizens.append(person)
		world._record("produced","toolkit",1);world._record("produced","cloak",1)
		var bed: Dictionary = world._structure("bed",Vector2i(48+index%8*2,60+index/8*3),0)
		bed.user=person.id;person.bed=bed.id
	world.social_state=ColonySocial.initial_state(world.citizens,world.tick)
	world.equipment_state=ColonyEquipment.initial_state(world.citizens)
	# 80 interior tiles minus two barns provide twelve usable animal places.
	for x in range(96,108):
		world._structure("fence",Vector2i(x,7),0);world._structure("fence",Vector2i(x,16),0)
	for y in range(8,16):
		world._structure("pen_gate" if y==12 else "fence",Vector2i(96,y),0);world._structure("fence",Vector2i(107,y),0)
	var barns: Array = [world._structure("barn",Vector2i(98,9),0),world._structure("barn",Vector2i(102,12),0)]
	var tiles: Array[Vector2i] = []
	for y in range(8,16):
		for x in range(97,107): tiles.append(Vector2i(x,y))
	var pen: Dictionary = {"id":world._id(),"tiles":tiles,"breeding":false,"next_birth":0,"reason":""}
	world.domestic_state.pens.append(pen)
	for index in range(12):
		var result: Dictionary = ColonyDomestic.acquire(world,"hen" if index%2==0 else "pack_goat",pen.id,tiles[index])
		if not result.has("animal"): return {"error":"Stress animals: "+result.get("error","")}
	for barn in barns: world._make_stack("grain",24,"animal_feed",barn.id,Vector2i(barn.x,barn.y),true)
	for index in range(32): ColonyWildlife.spawn(world,ColonyWildlife.REPLACEMENT_ORDER[index%4],Vector2i(42+index%8*2,24+index/8*2))
	# The complete count is 192; visible stages vary without changing crop rules.
	var field_tiles: Array[Vector2i] = []
	for y in range(82,90):
		for x in range(48,72): field_tiles.append(Vector2i(x,y))
	var field_error: String = ColonyAgriculture.designate(world,{"crop":"turnip","tiles":field_tiles})
	if field_error!="accepted": return {"error":"Stress crops: "+field_error}
	for index in range(world.fields.size()):
		var field: Dictionary = world.fields[index]
		var stage: int = index%5
		field.prepared=stage>0;field.planted=stage>0;field.growth=[0,0,100,1000,2000][stage];field.reason=""
		field.ripe_tick=world.tick if stage==4 else 0
	# Include every land structure kind before repeated props. Candidate placement
	# checks preserve footprints and waterways, with reserved fields/pen interiors.
	var kinds: Array = world.definitions.buildings.keys().filter(func(kind:String)->bool:return kind not in ["supply_cart","bridge","fishing_pier","barn"])
	var cursor: int = 0
	for y in range(4,120,4):
		for x in range(4,120,4):
			if world.structures.size()>=400: break
			var point: Vector2i = Vector2i(x,y)
			if Rect2i(94,5,16,14).has_point(point) or Rect2i(46,80,29,13).has_point(point): continue
			var kind: String = kinds[cursor%kinds.size()]
			if world.placement_error(kind,point,cursor%4)!="": continue
			world._structure(kind,point,cursor%4);cursor+=1
	if world.structures.size()!=400: return {"error":"Stress fixture cannot fit 400 structures"}
	# 256 executable construction targets, using actual material requirements.
	for y in range(2,126,2):
		for x in range(2,126,2):
			if world.jobs.size()>=256: break
			var point: Vector2i = Vector2i(x,y)
			if Rect2i(94,5,16,14).has_point(point) or Rect2i(46,80,29,13).has_point(point): continue
			if world.placement_error("wood_wall",point,0)!="": continue
			var definition: Dictionary = world.definitions.buildings.wood_wall
			var job: Dictionary = world._job("build","Building","Build",0,point,definition.work_milli)
			job.definition="wood_wall";job.inputs=definition.materials.duplicate()
	if world.jobs.size()!=256: return {"error":"Stress fixture cannot fit 256 targets"}
	var items: Array = ["wood","stone","fiber","grain","travel_ration","medicine","cloth","iron"]
	while world.stacks.size()<1000:
		var index: int = world.stacks.size()
		var item: String = items[index%items.size()]
		world._make_stack(item,world.definitions.items[item].stack_limit,"ground",0,Vector2i(60+index%16,70+index/16%8),true)
	# Eight stable neutral road visitors plus six active threats. This deliberately
	# exceeds the ordinary shared admission reservation and does not change it.
	for index in range(3):
		var raid: Dictionary = ColonyDefense.announce(world,8 if index<2 else 10)
		raid.due=world.tick;raid.arrival=world.tick;raid.state="Resolved" if index<2 else "Active";raid.acknowledged=true
		for kind in raid.party:
			var enemy: Dictionary = ColonyDefense.enemy_template()
			enemy.id=world._id();enemy.raid=raid.id;enemy.definition=kind;enemy.x=78+raid.actors.size();enemy.y=66+index
			enemy.health=10 if index<2 else world.definitions.enemies[kind].health
			enemy.state="Downed" if index<2 else "Active";enemy.recovery_at=world.tick+3600 if index<2 else 0
			world.defense_state.enemies.append(enemy);raid.actors.append(enemy.id)
	world.defense_state.alert_serial=1;world.danger_cache_tick=-1
	while world.chronicle_state.facts.size()<1000:
		world.emit_fact({"tick":world.tick,"actor":0,"job":0,"kind":"haul","text":"Synthetic stress fixture delivery record."})
	world.reset_job_queries();world.reset_stack_queries();world.record_indexes.clear()
	var errors: Array[String] = world.invariant_errors()
	if not errors.is_empty(): return {"error":str(errors)}
	var decoded: Dictionary = ColonyCodec.decode(ColonyCodec.encode(world))
	if not decoded.has("world"): return {"error":"Stress save validation: "+decoded.get("error","")}
	if decoded.world.canonical_hash()!=world.canonical_hash(): return {"error":"Stress save roundtrip mismatch"}
	return {"world":world,"counts":counts(world),"scope":"Synthetic overload fixture; eight neutral downed road visitors plus six hostiles exceed ordinary shared admission reservations. No ordinary-play/balance or physical-device certification."}

static func counts(world: ColonyWorld) -> Dictionary:
	return {"residents":ColonyPopulation.living(world),"domestic":world.domestic_state.animals.filter(func(a:Dictionary)->bool:return a.health>0).size(),"wildlife":world.wildlife_state.animals.filter(func(a:Dictionary)->bool:return a.health>0).size(),"hostiles":world.defense_state.enemies.filter(ColonyDefense.enemy_active).size(),"neutral_visitors":world.defense_state.enemies.filter(func(e:Dictionary)->bool:return e.state in ["Downed","Leaving"]).size(),"structures":world.structures.filter(func(s:Dictionary)->bool:return s.health>0).size(),"nonempty_stacks":world.nonempty_stacks().size(),"active_targets":world.unfinished_jobs().filter(func(j:Dictionary)->bool:return j.kind in ["build","craft","cook"]).size(),"crop_tiles":world.fields.size(),"chronicle":world.chronicle_state.facts.size(),"weather":world.weather}
