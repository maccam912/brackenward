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
