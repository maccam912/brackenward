class_name ColonyText
extends RefCounted
## English presentation messages. Never rewrite names, facts, saves or command IDs.
const SHEET_KEYS: Dictionary = {
	"Attempt unprepared?": "ui.sheet.attempt_unprepared",
	"Auto pauses": "ui.sheet.auto_pauses",
	"Brackenward restored": "ui.sheet.brackenward_restored",
	"Build": "ui.sheet.build",
	"Campaigns": "ui.sheet.campaigns",
	"Carcass": "ui.sheet.carcass",
	"Cart appearance": "ui.sheet.cart_appearance",
	"Charter": "ui.sheet.charter",
	"Choose key": "ui.sheet.choose_key",
	"Chronicle": "ui.sheet.chronicle",
	"Colony epilogue": "ui.sheet.colony_epilogue",
	"Colony mode": "ui.sheet.colony_mode",
	"Communal supper": "ui.sheet.communal_supper",
	"Confirm new colony": "ui.sheet.confirm_new_colony",
	"Confirm replacement": "ui.sheet.confirm_replacement",
	"Confirm snapshot replacement": "ui.sheet.confirm_snapshot_replacement",
	"Defending squad": "ui.sheet.defending_squad",
	"Defense": "ui.sheet.defense",
	"Delivery preview": "ui.sheet.delivery_preview",
	"Event details": "ui.sheet.event_details",
	"Event ledger": "ui.sheet.event_ledger",
	"Exchange preview": "ui.sheet.exchange_preview",
	"Expedition": "ui.sheet.expedition",
	"Expedition packing preview": "ui.sheet.expedition_packing_preview",
	"Fire and water": "ui.sheet.fire_and_water",
	"Food forecast": "ui.sheet.food_forecast",
	"Forest zone": "ui.sheet.forest_zone",
	"Generation problem": "ui.sheet.generation_problem",
	"Growing the valley": "ui.sheet.growing_the_valley",
	"Import campaign": "ui.sheet.import_campaign",
	"Incident forecast": "ui.sheet.incident_forecast",
	"Included report": "ui.sheet.included_report",
	"Injuries and care": "ui.sheet.injuries_and_care",
	"Journal": "ui.sheet.journal",
	"Keys": "ui.sheet.keys",
	"Lessons": "ui.sheet.lessons",
	"Livestock pen": "ui.sheet.livestock_pen",
	"Livestock pens": "ui.sheet.livestock_pens",
	"Map and seed": "ui.sheet.map_and_seed",
	"Menu": "ui.sheet.menu",
	"Name snapshot": "ui.sheet.name_snapshot",
	"Name this place": "ui.sheet.name_this_place",
	"Named snapshots": "ui.sheet.named_snapshots",
	"New colony": "ui.sheet.new_colony",
	"New colony with this seed": "ui.sheet.new_colony_with_this_seed",
	"Newcomer offers": "ui.sheet.newcomer_offers",
	"Offer supplies": "ui.sheet.offer_supplies",
	"People": "ui.sheet.people",
	"Performance report": "ui.sheet.performance_report",
	"Pin a moment": "ui.sheet.pin_a_moment",
	"Production policy": "ui.sheet.production_policy",
	"Recovery stopped": "ui.sheet.recovery_stopped",
	"Regional map": "ui.sheet.regional_map",
	"Remembered moments": "ui.sheet.remembered_moments",
	"Rename": "ui.sheet.rename",
	"Research": "ui.sheet.research",
	"Save problem": "ui.sheet.save_problem",
	"Select object": "ui.sheet.select_object",
	"Settings": "ui.sheet.settings",
	"Solo boar hunt": "ui.sheet.solo_boar_hunt",
	"Sound": "ui.sheet.sound",
	"Stand fast warning": "ui.sheet.stand_fast_warning",
	"Storage": "ui.sheet.storage",
	"Style": "ui.sheet.style",
	"Supply preview": "ui.sheet.supply_preview",
	"Unsubmitted building cell": "ui.sheet.unsubmitted_building_cell",
	"Valley": "ui.sheet.valley",
	"Valley and neighbors": "ui.sheet.valley_and_neighbors",
	"Visitor offers": "ui.sheet.visitor_offers",
	"Weather forecast": "ui.sheet.weather_forecast",
	"Welcome": "ui.sheet.welcome",
	"Welcome back": "ui.sheet.welcome_back",
	"Wildlife": "ui.sheet.wildlife",
	"Work": "ui.sheet.work",
	"Work order": "ui.sheet.work_order"
}
const PERFORMANCE_KEYS: Dictionary = {
	"frame_gap": "ui.performance.stage.frame_gap",
	"session": "ui.performance.stage.session",
	"simulation_batch": "ui.performance.stage.simulation_batch",
	"simulation_tick": "ui.performance.stage.simulation_tick",
	"map_update": "ui.performance.stage.map_update",
	"map_draw_commands": "ui.performance.stage.map_draw_commands",
	"audio_update": "ui.performance.stage.audio_update",
	"save_capture": "ui.performance.stage.save_capture",
	"snapshot_capture": "ui.performance.stage.snapshot_capture",
	"save_finish": "ui.performance.stage.save_finish",
	"save_worker": "ui.performance.stage.save_worker",
	"snapshot_worker": "ui.performance.stage.snapshot_worker",
	"save_explicit": "ui.performance.stage.save_explicit"
}
static var messages: Dictionary = {}

static func catalog() -> Dictionary:
	if messages.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalogs/en_ui.json"))
		if not parsed is Dictionary: push_error("Invalid UI message catalog");return {}
		messages=parsed
	return messages

const WORK_CATEGORY_KEYS: Dictionary = {
	"Care": "ui.work.category.care",
	"Cooking": "ui.work.category.cooking",
	"Growing": "ui.work.category.growing",
	"Gathering": "ui.work.category.gathering",
	"Animals": "ui.work.category.animals",
	"Building": "ui.work.category.building",
	"Crafting": "ui.work.category.crafting",
	"Hauling": "ui.work.category.hauling",
	"Research": "ui.work.category.research",
	"Guard": "ui.work.category.guard"
}


const TRAIT_KEYS: Dictionary = {
	"Kind": "ui.trait.kind",
	"Homebody": "ui.trait.homebody",
	"Steady": "ui.trait.steady",
	"Sociable": "ui.trait.sociable",
	"Outdoorsy": "ui.trait.outdoorsy",
	"Restless": "ui.trait.restless",
	"Curious": "ui.trait.curious",
	"Private": "ui.trait.private"
}

const FOOD_TAG_KEYS: Dictionary = {
	"Vegetable": "ui.food_tag.vegetable",
	"Grain": "ui.food_tag.grain",
	"Berry": "ui.food_tag.berry",
	"Mushroom": "ui.food_tag.mushroom",
	"Meat": "ui.food_tag.meat",
	"Fish": "ui.food_tag.fish",
	"Milk": "ui.food_tag.milk",
	"Egg": "ui.food_tag.egg"
}

const SKILL_KEYS: Dictionary = {
	"Field": "ui.skill.field",
	"Build": "ui.skill.build",
	"Craft": "ui.skill.craft",
	"Cooking": "ui.skill.cooking",
	"Care": "ui.skill.care",
	"Study": "ui.skill.study",
	"Guard": "ui.skill.guard"
}

const ACTIVITY_KEYS: Dictionary = {
	"Idle": "ui.activity.idle",
	"Waiting for a communal supper seat": "ui.activity.waiting_for_a_communal_supper_seat",
	"Collecting a reserved supper meal": "ui.activity.collecting_a_reserved_supper_meal",
	"Carrying supper to the table": "ui.activity.carrying_supper_to_the_table",
	"Returning to the communal supper": "ui.activity.returning_to_the_communal_supper",
	"Eating communal supper": "ui.activity.eating_communal_supper",
	"Sitting at communal supper": "ui.activity.sitting_at_communal_supper",
	"Defending the rally": "ui.activity.defending_the_rally",
	"Moving to defend": "ui.activity.moving_to_defend",
	"Sheltering in the safest reachable place": "ui.activity.sheltering_in_the_safest_reachable_place",
	"Sheltering at the cart": "ui.activity.sheltering_at_the_cart",
	"Preparing: needs food to reach fullness 500": "ui.activity.preparing_needs_food_to_reach_fullness_500",
	"At the cart: waiting for Depart or Cancel": "ui.activity.at_the_cart_waiting_for_depart_or_cancel",
	"Died": "ui.activity.died",
	"Departed": "ui.activity.departed",
	"Hearthside recovery": "ui.activity.hearthside_recovery",
	"Downed: bleeding, needs care": "ui.activity.downed_bleeding_needs_care",
	"Downed: recovering": "ui.activity.downed_recovering",
	"Resting for treatment": "ui.activity.resting_for_treatment",
	"Hungry: gather berries or mushrooms and enable Cooking": "ui.activity.hungry_gather_berries_or_mushrooms_and_enable_cooking",
	"Pinned task unavailable: check its inputs and route": "ui.activity.pinned_task_unavailable_check_its_inputs_and_route",
	"Idle: designate resources or place a blueprint": "ui.activity.idle_designate_resources_or_place_a_blueprint",
	"Fetching supplies": "ui.activity.fetching_supplies",
	"Carrying supplies": "ui.activity.carrying_supplies",
	"Walking to the task": "ui.activity.walking_to_the_task",
	"Working": "ui.activity.working",
	"Sleeping on ground: assigned bed unreachable; clear access or reassign bed": "ui.activity.sleeping_on_ground_assigned_bed_unreachable_clear_access_or_reassign",
	"Sleeping": "ui.activity.sleeping",
	"Heading to bed": "ui.activity.heading_to_bed",
	"Eating": "ui.activity.eating",
	"Getting food": "ui.activity.getting_food",
	"Taking leisure": "ui.activity.taking_leisure",
	"Walking to rest": "ui.activity.walking_to_rest",
	"Gathering": "ui.activity.gathering",
	"Cooking meals": "ui.activity.cooking_meals",
	"Preparing soil": "ui.activity.preparing_soil",
	"Sowing": "ui.activity.sowing",
	"Harvesting": "ui.activity.harvesting",
	"Refueling hearth": "ui.activity.refueling_hearth",
	"Recovering: ordinary work resumes at 50 health": "ui.activity.recovering_ordinary_work_resumes_at_50_health",
	"Waiting for armed escort": "ui.activity.waiting_for_armed_escort",
	"Waiting for the armed hunter": "ui.activity.waiting_for_the_armed_hunter",
	"Escorting boar hunt": "ui.activity.escorting_boar_hunt",
	"Fetching water for fire (2 WU)": "ui.activity.fetching_water_for_fire_2_wu",
	"Carrying a water load in both hands": "ui.activity.carrying_a_water_load_in_both_hands",
	"Extinguishing fire (8 WU)": "ui.activity.extinguishing_fire_8_wu",
	"Carrying retained furniture materials": "ui.activity.carrying_retained_furniture_materials",
	"Preparing to move the supply cart": "ui.activity.preparing_to_move_the_supply_cart",
	"Meeting the partly moved cart": "ui.activity.meeting_the_partly_moved_cart",
	"Pushing the cart with its stored goods": "ui.activity.pushing_the_cart_with_its_stored_goods",
	"Unsafe route: already at the safest reachable tile; clear an exit or extinguish the fire": "ui.activity.unsafe_route_already_at_the_safest_reachable_tile_clear_an_exit_or_e",
	"Escaping danger": "ui.activity.escaping_danger",
	"Joining the household from the boundary": "ui.activity.joining_the_household_from_the_boundary",
	"Stepping clear of construction": "ui.activity.stepping_clear_of_construction"
}

static func trait_name(value: String) -> String:
	return _literal_name(value,TRAIT_KEYS)

static func food_tag_name(value: String) -> String:
	return _literal_name(value,FOOD_TAG_KEYS)

static func skill_name(value: String) -> String:
	return _literal_name(value,SKILL_KEYS)

static func activity_name(value: String) -> String:
	# Saved activity/reason text remains canonical. Translate only exact known
	# fixed phrases; composed descriptions and user braces remain literal.
	return _literal_name(value,ACTIVITY_KEYS)

static func _literal_name(value: String, keys: Dictionary) -> String:
	var key: String=keys.get(value,"")
	return text(key) if not key.is_empty() else value

static func bed_description(world: ColonyWorld, person: Dictionary) -> String:
	var bed: Dictionary=world.find(world.structures,person.bed)
	if bed.is_empty() or bed.health<=0:return text("ui.person.bed.none",{"rate":ColonyRest.GROUND})
	return text("ui.person.bed.assigned",{"bed":ColonyChronicle.display_name(world,bed.id),"x":bed.x,"y":bed.y,"shelter":text("ui.person.bed.roofed" if world.roofed(Vector2i(bed.x,bed.y)) else "ui.person.bed.outdoors"),"rate":ColonyRest.recovery_rate(bed.definition)})

static func category_name(category: String) -> String:
	var key: String=WORK_CATEGORY_KEYS.get(category,"")
	return text(key) if not key.is_empty() else category

static func preference_name(value: int) -> String:
	return text(["ui.choice.off","ui.preference.last","ui.preference.normal","ui.preference.first"][value])

static func preference_row(category: String, value: int, pending: bool=false) -> String:
	return text("ui.work.preference_pending" if pending else "ui.work.preference",{"category":category_name(category),"preference":preference_name(value)})

static func shift_name(value: String) -> String:
	return text("ui.shift.night" if value=="Night shift" else "ui.shift.normal")

static func text(key: String, values: Dictionary = {}) -> String:
	var entry: Variant = catalog().get(key)
	if not entry is String:
		push_error("Missing UI text key: "+key);return key
	return format_template(entry,values)

static func plural(key: String, count: int, values: Dictionary = {}) -> String:
	var entry: Variant = catalog().get(key)
	if not entry is Dictionary or not entry.has("one") or not entry.has("other"):
		push_error("Missing UI plural key: "+key);return key
	var parameters: Dictionary = values.duplicate()
	parameters.count=count
	return format_template(entry.one if count==1 else entry.other,parameters)

static func format_template(template: String, values: Dictionary) -> String:
	# Substitute only tokens from the template. A user's braces in an inserted
	# name/note remain literal even when another parameter has the same name.
	var result: String = "";var cursor: int = 0
	while true:
		var opening: int = template.find("{",cursor)
		if opening<0: return result+template.substr(cursor)
		var closing: int = template.find("}",opening+1)
		if closing<0: push_error("Unclosed UI message parameter");return template
		var parameter: String = template.substr(opening+1,closing-opening-1)
		if not values.has(parameter): push_error("Missing UI message parameter: "+parameter);return template
		result+=template.substr(cursor,opening-cursor)+str(values[parameter])
		cursor=closing+1
	return result

static func food_runway(value: Dictionary) -> String:
	# Legacy quotes persist their original English label. Read its no-resident
	# marker without rewriting that saved contract; render quantities separately.
	if value.label=="No residents at home": return text("ui.forecast.no_residents")
	var ticks: int=value.ticks
	return text("ui.forecast.stored_runway",{"portions":plural("ui.forecast.portions",value.portions),"days":plural("ui.forecast.days",ticks/7200),"hour":"%02d" % ((ticks%7200)/300),"minute":"%02d" % (((ticks/75)*15)%60)})

static func sheet_key(identifier: String) -> String:
	# Call only for fixed navigation/shortcut IDs. User names and canonical facts
	# use show_sheet's literal-title path and are never looked up as message keys.
	return SHEET_KEYS.get(identifier,"")

static func speed_label(speed: int) -> String:
	return text("ui.clock.paused") if speed==0 else text("ui.clock.speed",{"speed":speed})

static func performance_timing(entry: Dictionary) -> String:
	var upper: String=">1000" if entry.p95_bucket_upper_ms==null else str(entry.p95_bucket_upper_ms)
	return text("ui.performance.timing",{"stage":text(PERFORMANCE_KEYS[entry.stage]),"speed":speed_label(entry.speed),"samples":plural("ui.performance.samples",entry.count),"max_ms":"%.1f" % entry.max_ms,"slow":entry.over_50ms,"upper_ms":upper})
