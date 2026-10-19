class_name WheelbarrowTests
extends RefCounted

static func equip(world: ColonyWorld, person: Dictionary) -> void:
	person.equipment.transport="wheelbarrow"
	world._record("produced","wheelbarrow",1)

static func hauling(world: ColonyWorld, count: int = 100, item: String = "stone") -> Dictionary:
	var source: Dictionary=world._make_stack(item,count,"ground",0,Vector2i(74,63),true)
	var job: Dictionary=world._job("haul","Hauling","",source.id,Vector2i(source.x,source.y),0)
	job.source=source.id
	return job

static func reserved(world: ColonyWorld, job: Dictionary) -> int:
	var total: int=0
	for stack in world.stacks: total+=stack.reservations.get(job.id,0)
	return total

static func run(check: Callable) -> void:
	var world: ColonyWorld=ColonyTests.world()
	var bench: Dictionary=world._structure("workbench",Vector2i(70,59),0)
	var args: Dictionary={"target":bench.id,"definition":"make_wheelbarrow","mode":"Repeat","value":1,"priority":3,"filters":[]}
	check.call("BARROW/early_project_has_no_prerequisites",world.definitions.research.wheelbarrows.prerequisites.is_empty() and world.definitions.research.wheelbarrows.points==1440 and ColonyProduction.command(world,"research_select",{"definition":"wheelbarrows"})=="accepted")
	check.call("BARROW/recipe_requires_real_research",ColonyProduction.command(world,"recipe_order",args)!="accepted" and world.production_state.orders.is_empty())
	world._structure("research_desk",Vector2i(74,63),0)
	for resident in world.citizens: resident.preferences.Research=0
	world.citizens[3].preferences.Research=3
	for tick in range(21600):
		world.step()
		if world.researched.has("wheelbarrows"): break
	check.call("BARROW/real_starting_researcher_unlocks_wooden_recipe",world.researched.has("wheelbarrows") and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="research" and j.state=="Complete"),str(world.tick))
	var before: int=world.total("wood")
	check.call("BARROW/wood_only_recipe_available_after_research",ColonyProduction.command(world,"recipe_order",args)=="accepted" and world.definitions.recipes.make_wheelbarrow.materials=={"wood":6})
	for tick in range(2400):
		world.step()
		if world.citizens.any(func(c:Dictionary)->bool:return c.equipment.transport=="wheelbarrow"): break
	check.call("BARROW/crafted_once_and_physically_auto_equipped",world.total("wheelbarrow")==1 and world.citizens.filter(func(c:Dictionary)->bool:return c.equipment.transport=="wheelbarrow").size()==1 and world.total("wood")==before-6 and world.jobs.any(func(j:Dictionary)->bool:return j.kind=="equip" and j.definition=="transport" and j.state=="Complete") and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var researched_save: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("BARROW/research_recipe_and_owned_gear_save_together",researched_save.has("world") and researched_save.world.canonical_hash()==world.canonical_hash(),str(researched_save.get("error","")))
	world=ColonyTests.world()
	var person: Dictionary=world.citizens[0]
	check.call("BARROW/ordinary_capacity_stays_eight",world.carry_capacity(person)==8)
	equip(world,person)
	check.call("BARROW/equipped_capacity_is_tenfold",world.carry_capacity(person)==80 and world.citizens.slice(1).all(func(c:Dictionary)->bool:return world.carry_capacity(c)==8))
	var job: Dictionary=hauling(world)
	check.call("BARROW/reserves_eighty_for_storage",world._reserve(job,person) and reserved(world,job)==80)
	person.job=job.id
	for tick in range(1000):
		world._work(person,job)
		if job.state=="Delivering": break
	check.call("BARROW/picks_up_eighty_and_reserves_storage_space",world.stacks.filter(func(s:Dictionary)->bool:return s.location=="carry" and s.owner==person.id).reduce(func(total:int,s:Dictionary)->int:return total+s.count,0)==80 and world._storage_context().occupied[world.stores[0].id]>=80 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	var copy: Dictionary=ColonyCodec.decode(ColonyCodec.encode(world))
	check.call("BARROW/loaded_save_roundtrip",copy.has("world") and copy.world.canonical_hash()==world.canonical_hash(),str(copy.get("error","")))
	if copy.has("world"):
		for tick in range(1000):
			world._work(person,job);copy.world._work(copy.world.citizens[0],copy.world.find(copy.world.jobs,job.id))
			if job.state=="Complete": break
		check.call("BARROW/loaded_save_continues_exact_delivery",job.state=="Complete" and world.canonical_hash()==copy.world.canonical_hash() and world.stacks.any(func(s:Dictionary)->bool:return s.location=="store" and s.item=="stone" and s.count>0) and world.total("stone")==130 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	for item in ["stone","wood","berry","toolkit"]:
		world=ColonyTests.world();person=world.citizens[0];equip(world,person);job=hauling(world,100,item)
		check.call("BARROW/tenfold_general_items_"+item,world._reserve(job,person) and reserved(world,job)==80)
	world=ColonyTests.world();person=world.citizens[0];job=hauling(world)
	check.call("BARROW/unowned_wheelbarrow_grants_no_bonus",world._make_stack("wheelbarrow",1,"ground",0,Vector2i(70,59),true).count==1 and world._reserve(job,person) and world.find(world.stacks,job.source).reservations[job.id]==8)
	for space in [5,50]:
		world=ColonyTests.world();person=world.citizens[0];equip(world,person)
		if space==5: world.stores[0].capacity=world._storage_context().occupied[world.stores[0].id]+5
		else:
			world.stores.clear();world.stores.append({"id":world._id(),"tiles":[Vector2i(68,63)],"filters":["stone"],"priority":3,"capacity":50})
		job=hauling(world)
		check.call("BARROW/partial_destination_reserves_"+str(space),world._reserve(job,person) and reserved(world,job)==space)
	world=ColonyTests.world();person=world.citizens[0];equip(world,person);job=hauling(world)
	world._reserve(job,person);person.job=job.id
	for tick in range(1000):
		world._work(person,job)
		if job.state=="Delivering": break
	world._release(job,true)
	check.call("BARROW/cancel_returns_entire_large_load",world.stacks.any(func(s:Dictionary)->bool:return s.location=="ground" and s.item=="stone" and s.count>0) and world.total("stone")==130 and world.invariant_errors().is_empty(),str(world.invariant_errors()))
	world=ColonyTests.world();person=world.citizens[0];equip(world,person)
	job=world._job("build","Building","Build",0,Vector2i(74,63),1000);job.definition="wood_wall";job.inputs={"wood":60,"stone":20}
	world._make_stack("wood",60,"ground",0,Vector2i(70,63),true);world._make_stack("stone",20,"ground",0,Vector2i(70,63),true)
	world._reserve(job,person);person.job=job.id
	for tick in range(1000):
		world._work(person,job)
		if job.state=="Delivering": break
	var carried: int=0
	for stack in world.stacks:
		if stack.location=="carry" and stack.owner==person.id: carried+=stack.count
	check.call("BARROW/construction_fetches_mixed_items_with_shared_capacity",carried==80 and world.invariant_errors().is_empty(),str([carried,world.invariant_errors()]))
	var bad: Dictionary=world.payload().duplicate(true);bad.citizens[0].equipment.transport=""
	check.call("BARROW/rejects_large_load_without_equipped_barrow",ColonyCodec.restore(bad).has("error"))
	bad=world.payload().duplicate(true);bad.citizens[0].equipment.transport="toolkit"
	check.call("BARROW/rejects_invalid_transport_gear",ColonyCodec.restore(bad).has("error"))
	world=ColonyTests.world();person=world.citizens[1];equip(world,person)
	for resident in world.citizens: resident.preferences.Building=0
	person.preferences.Building=3
	var furniture: Dictionary=world._structure("workbench",Vector2i(74,54),0)
	world.queue_command("move_furniture",{"target":furniture.id,"x":84,"y":64,"rotation":0})
	var largest: int=0
	for tick in range(1500):
		world.step()
		var load_units: int=0
		for stack in world.stacks:
			if stack.location=="carry" and stack.owner==person.id: load_units+=stack.count
		largest=maxi(largest,load_units)
		if furniture.x==84: break
	check.call("BARROW/furniture_materials_share_the_larger_load",furniture.x==84 and largest==16 and world.invariant_errors().is_empty(),str([largest,world.invariant_errors()]))
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes("res://tests/fixtures/content13/campaign-replay-7200.brackenward")
	var legacy: Dictionary=ColonyCodec.decode(bytes)
	var original: Dictionary=ColonyState.unpack(JSON.parse_string(JSON.parse_string(bytes.get_string_from_utf8()).payload))
	check.call("BARROW/legacy_save_adds_empty_transport_without_changing_acknowledgements",legacy.has("world") and SchemaCompatibility.normalize(legacy.world,original)==original and legacy.world.citizens.all(func(c:Dictionary)->bool:return c.equipment.transport.is_empty() and legacy.world.carry_capacity(c)==8),str(legacy.get("error","")))

static func ui(game: GameSession, check: Callable) -> void:
	game.world=ColonyTests.world();game.runner=SimRunner.new(game.world);game.view.world=game.world;game.submitted_command=0
	game.show_research()
	var project: Node=game.sheet_body.find_child("Research_wheelbarrows",true,false)
	check.call("BARROW/UI_early_research_explains_eighty_item_capacity",project!=null and project.find_children("*","Label",true,false).any(func(n:Node)->bool:return n.text.contains("80 items instead of 8")) and project.find_children("*","Button",true,false).any(func(n:Node)->bool:return n.text=="Study Wheelbarrows"))
	var bench: Dictionary=game.world._structure("workbench",Vector2i(74,54),0)
	game.show_station(bench)
	var recipe: Node=game.sheet_body.get_node("Recipe_make_wheelbarrow")
	check.call("BARROW/UI_recipe_is_locked_before_research",recipe.find_children("*","Label",true,false).any(func(n:Node)->bool:return n.text=="Requires Wheelbarrows research.") and not recipe.find_children("*","Button",true,false).any(func(n:Node)->bool:return n.text=="Make one batch"))
	game.world.researched.append("wheelbarrows");game.show_station(bench)
	recipe=game.sheet_body.get_node("Recipe_make_wheelbarrow")
	check.call("BARROW/UI_recipe_shows_real_materials_and_icon",recipe.find_children("*","Label",true,false).any(func(n:Node)->bool:return n.text.contains("wood") and n.text.contains("6") and n.text.contains("14 WU")) and recipe.find_children("*","TextureRect",true,false).any(func(n:Node)->bool:return n.texture.atlas==EnvironmentArt.WHEELBARROW))
	for node in recipe.find_children("*","Button",true,false):
		if node.text=="Make one batch": node.pressed.emit();break
	check.call("BARROW/UI_crafting_submits_one_real_recipe_order",game.world.pending_commands.size()==1 and game.world.pending_commands[0].kind=="recipe_order" and game.world.pending_commands[0].args.definition=="make_wheelbarrow")
	game.world.pending_commands.clear();game.submitted_command=0;game.world._make_stack("wheelbarrow",1,"ground",0,Vector2i(70,63),true);game.show_equipment(1)
	check.call("BARROW/UI_equipment_explains_current_capacity",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("capacity: 8 items")))
	for node in game.sheet_body.get_children():
		if node is Button and node.text=="Equip Wheelbarrow": node.pressed.emit();break
	check.call("BARROW/UI_can_assign_a_specific_wheelbarrow",game.world.pending_commands.size()==1 and game.world.pending_commands[0].kind=="equip" and game.world.pending_commands[0].args.slot=="transport")
	game.world.pending_commands.clear();game.submitted_command=0;equip(game.world,game.world.citizens[0]);game.show_equipment(1)
	check.call("BARROW/UI_equipped_capacity_and_slot_are_visible",game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text.contains("capacity: 80 items")) and game.sheet_body.get_children().any(func(n:Node)->bool:return n is Label and n.text=="Transport: Wheelbarrow"))
	var job: Dictionary=hauling(game.world);game.world._reserve(job,game.world.citizens[0]);game.world.citizens[0].job=job.id
	check.call("BARROW/UI_barrow_visible_on_real_supply_trip",game.view.wheelbarrow_visible(game.world.citizens[0]))
	game.world._release(job,true)
	check.call("BARROW/UI_no_barrow_during_other_activities",not game.view.wheelbarrow_visible(game.world.citizens[0]))

	game.world=ColonyTests.world();game.runner=SimRunner.new(game.world);game.view.world=game.world;game.submitted_command=0
