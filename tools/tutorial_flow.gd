extends SceneTree
## Bounded opening-session trace using generated terrain, real controls and public orders.
## Run: tools/godot.sh --headless --script tools/tutorial_flow.gd -- --site meadow_reach --seed 104729
var game: GameSession
var checks: int = 0
var failures: int = 0
var started: int = 0
var first_tick: int = 1800
var temporary: String
var site: String = "meadow_reach"
var seed_value: int = 104729
const TICK_LIMIT: int = 24000

func _initialize() -> void:
	call_deferred("run")

func check(label: String, passed: bool, detail: String = "") -> void:
	checks+=1
	if not passed: failures+=1
	print(("PASS " if passed else "FAIL ")+label+(": "+detail if not detail.is_empty() else ""))

func find_button(parent: Node, text: String) -> Button:
	if parent is Button and parent.text==text: return parent
	for child in parent.get_children():
		if child.is_queued_for_deletion(): continue
		var found: Button = find_button(child,text)
		if found!=null: return found
	return null

func press(parent: Node, text: String) -> bool:
	var button: Button = find_button(parent,text)
	if button==null or button.disabled:
		check("FLOW/control_"+text,false,"Missing or disabled control")
		return false
	button.pressed.emit()
	return true

func refresh() -> void:
	game._process(0.0)
	game._refresh_guidance()

func advance_until(predicate: Callable, maximum: int, label: String) -> bool:
	var end: int = mini(first_tick+TICK_LIMIT,game.world.tick+maximum)
	while not predicate.call() and game.world.tick<end and not game.world.care_state.ended:
		game.world.step()
		if game.world.tick%10==0: refresh()
		if game.world.tick%300==0:
			var errors: Array[String] = game.world.invariant_errors()
			if not errors.is_empty(): check(label,false,str(errors));return false
	refresh()
	var passed: bool = predicate.call()
	check(label,passed,"tick %d; active %s" % [game.world.tick,game._tutorial_state().active])
	return passed

func create_session() -> void:
	game=load("res://scenes/game.tscn").instantiate()
	game.store.root_directory=temporary
	game.store.select_slot(1)
	game.settings.path=temporary.path_join("settings.json")
	root.add_child(game)
	game.set_process(false)
	refresh()

func run() -> void:
	started=Time.get_ticks_msec()
	root.size=Vector2i(960,600)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		if args.size()!=4 or args[0]!="--site" or not ColonyGeneration.SITES.has(args[1]) or args[2]!="--seed" or not args[3].is_valid_int() or int(args[3])<0 or int(args[3])>4294967295:
			printerr("Usage: -- --site SITE --seed UINT32");quit(2);return
		site=args[1];seed_value=int(args[3])
	temporary="user://tutorial-flow-%d-%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	var initial: ColonyWorld = ColonyWorld.new(ColonyCatalog.load_data(),"tutorial-flow-"+site+"-"+str(seed_value))
	var generation: String = ColonyGeneration.configure(initial,seed_value,site)
	check("FLOW/generated_site",generation.is_empty(),generation)
	var storage: ColonyStore = ColonyStore.new();storage.root_directory=temporary
	check("FLOW/initial_snapshot",storage.adopt(initial,1).is_empty())
	var settings: DeviceSettings = DeviceSettings.new();settings.path=temporary.path_join("settings.json")
	settings.values.text_scale=1.25;settings.values.left_handed=true
	check("FLOW/isolated_accessibility_settings",settings.save_local().is_empty())
	create_session()
	if not press(game.sheet_body,"Begin"): finish();return
	check("FLOW/begin_paused_without_world_changes",game.runner.speed==0 and game._tutorial_state().active=="follow" and game.world.canonical_hash()==initial.canonical_hash())
	if not press(game.guidance_actions,"Show me") or not press(game.inspector,"Follow"): finish();return
	check("FLOW/follow_button_advances_first_lesson",game.view.follow_id==1 and game._tutorial_state().active=="forage")
	press(game.inspector,"Close")
	if not press(game.guidance_actions,"Show me") or not press(game.placement_actions,"Confirm"): finish();return
	game.world.step();refresh()
	check("FLOW/forage_order_is_not_delivery",not game._tutorial_state().completed.has("forage") and game.world.jobs.any(func(j:Dictionary)->bool:return j.kind=="gather" and j.state not in ["Complete","Canceled"]))
	game.show_sheet("Menu");press(game.sheet_body,"Save colony")
	var saved_hash: String = game.world.canonical_hash()
	var saved_state: Dictionary = game._tutorial_state().duplicate(true)
	game.queue_free();await process_frame
	create_session()
	check("FLOW/mid_lesson_restart_preserves_world_and_evidence",game.world.canonical_hash()==saved_hash and game._tutorial_state()==saved_state and game.text_scale==1.25 and game.left_handed and game.runner.speed==0)
	press(game.sheet,"Close");press(game.speeds,"1x")
	if not advance_until(func()->bool:return game._tutorial_state().completed.has("forage"),6000,"FLOW/real_berry_delivery"): finish();return
	if not press(game.guidance_actions,"Show me"): finish();return
	check("FLOW/lodge_preview_shows_real_cost_and_order",game.placement_kind=="lodge" and game._preview_text().contains("W73 F8") and game._preview_text().contains("beds and door"))
	press(game.placement_actions,"Confirm");game.world.step();refresh()
	check("FLOW/lodge_confirmation_creates_editable_orders",game._tutorial_state().completed.has("lodge") and game.world.construction_state.groups.size()==1 and game.world.construction_state.groups[0].members.size()==28)
	# Ordinary support designation, visible resources only; no inventory or actor edits.
	var home: Dictionary = ColonyTrade.cart(game.world)
	var trees: Array = game.world.resources.filter(func(r:Dictionary)->bool:return r.definition=="tree" and r.remaining>0 and absi(r.x-home.x)+absi(r.y-home.y)<=24)
	trees.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ad: int = absi(a.x-home.x)+absi(a.y-home.y);var bd: int = absi(b.x-home.x)+absi(b.y-home.y)
		return ad<bd if ad!=bd else a.id<b.id)
	game.world.queue_command("gather_area",{"definition":"tree","tiles":trees.slice(0,10).map(func(r:Dictionary)->Vector2i:return Vector2i(r.x,r.y))})
	var berries: Array = game.world.resources.filter(func(r:Dictionary)->bool:return r.definition=="berry_bush" and r.remaining>0 and absi(r.x-home.x)+absi(r.y-home.y)<=24)
	berries.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.id<b.id)
	game.world.queue_command("gather_area",{"definition":"berry_bush","tiles":berries.slice(0,2).map(func(r:Dictionary)->Vector2i:return Vector2i(r.x,r.y))})
	if not press(game.guidance_actions,"Show me") or not press(game.sheet_body,"Make one batch"): finish();return
	press(game.speeds,"1x")
	if not advance_until(func()->bool:return game._tutorial_state().completed.has("cook"),6000,"FLOW/real_explicit_hearth_batch"): finish();return
	check("FLOW/hearth_batch_used_real_ingredients",game.world.jobs.any(func(j:Dictionary)->bool:return j.kind=="craft" and j.definition=="cook_meals" and j.state=="Complete") and game.world.ledger.consumed.get("berry",0)>=4 and game.world.ledger.produced.get("meal",0)>=26)
	if not press(game.guidance_actions,"Show me"): finish();return
	check("FLOW/field_preview_is_eight_real_tiles",game.placement_kind=="field" and game.view.preview_tiles().size()==8)
	press(game.placement_actions,"Confirm");press(game.speeds,"1x")
	if not advance_until(func()->bool:return game._tutorial_state().completed.has("field"),10000,"FLOW/eight_tiles_prepared_and_sown"): finish();return
	check("FLOW/field_completion_has_actual_work",game.world.jobs.filter(func(j:Dictionary)->bool:return j.kind=="sow" and j.state=="Complete").size()>=8)
	if not press(game.guidance_actions,"Show me"): finish();return
	check("FLOW/mira_work_inspector_shows_cooking_first",find_button(game.sheet_body,"Cooking: First")!=null)
	press(game.sheet,"Close")
	game.show_station(game.world.structures.filter(func(s:Dictionary)->bool:return s.health>0 and s.definition=="hearth")[0])
	press(game.sheet_body,"Make one batch");press(game.speeds,"1x")
	if not advance_until(func()->bool:return game._tutorial_state().completed.has("cooking_priority"),5000,"FLOW/mira_receives_real_cooking_assignment"): finish();return
	if not press(game.guidance_actions,"Show me") or not press(game.sheet_body,"Pin forecast on map"): finish();return
	refresh()
	check("FLOW/all_seven_lessons_completed_by_actual_actions",ColonyTutorial.OPENING.all(func(id:String)->bool:return game._tutorial_state().completed.has(id)) and game._tutorial_state().skipped.is_empty() and game._tutorial_state().active.is_empty() and game.guidance_forecast.visible)
	var original_id: String = game.world.session_id
	var original_progress: Dictionary = game._tutorial_state().duplicate(true)
	var original_tick: int = game.world.tick
	var original_hash: String = game.world.canonical_hash()
	game._accept_import(ColonyCodec.encode(game.world))
	press(game.sheet_body,"Import into campaign 2");refresh()
	check("FLOW/clone_preserves_world_and_isolates_tutorial",game.world.session_id!=original_id and game.world.tick==original_tick and game.world.seed==seed_value and not game._tutorial_state().enabled and not game._tutorial_state().forecast_pinned and game.settings.values.tutorials[original_id]==original_progress)
	var cloned_payload: Dictionary = game.world.payload().duplicate(true);cloned_payload.session_id=original_id
	check("FLOW/clone_preserves_all_authoritative_fields_except_session",JSON.stringify(ColonyState.pack(cloned_payload),"",true).sha256_text()==original_hash)
	check("FLOW/clone_preserves_device_accessibility",game.text_scale==1.25 and game.left_handed and game.runner.speed==0 and not game.awaiting_first_colony)
	check("FLOW/final_conservation",game.world.invariant_errors().is_empty(),str(game.world.invariant_errors()))
	finish()

func finish() -> void:
	if is_instance_valid(game):
		if failures>0:
			print(JSON.stringify({"seed":seed_value,"site":site,"tick":game.world.tick,"tutorial":game._tutorial_state(),"receipts":game.world.receipts,"active_jobs":game.world.jobs.filter(func(j:Dictionary)->bool:return j.state not in ["Complete","Canceled"]),"commands":game.world.command_trace}))
		game.queue_free()
	print("Discovered/run: %d; failures: %d; elapsed: %d ms; site: %s; seed: %d; max ticks: %d" % [checks,failures,Time.get_ticks_msec()-started,site,seed_value,TICK_LIMIT])
	quit(0 if failures==0 else 1)
