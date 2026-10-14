class_name ColonyAudioLibrary
extends RefCounted
static var streams: Dictionary = {}
const IDS: Array[String] = ["ui_select","ui_confirm","ui_cancel","ui_error","chop","cloth","book","door_open","door_close","footstep_0","footstep_1","footstep_2","footstep_3","footstep_4","music_day","music_night","music_tension","ambient_rain","ambient_river","ambient_wind","ambient_fire","cue_warning","cue_critical","cue_opportunity"]

static func stream(id: String) -> AudioStreamOggVorbis:
	assert(IDS.has(id))
	if not streams.has(id):
		var audio: AudioStreamOggVorbis = load("res://assets/exported/audio/%s.ogg" % id)
		audio.loop=id.begins_with("music_") or id.begins_with("ambient_")
		streams[id]=audio
	return streams[id]

static func theme_for(world: ColonyWorld) -> String:
	if world.defense_state.enemies.any(ColonyDefense.enemy_active): return "tension"
	var hour: int = (world.tick%7200)/300
	return "night" if hour<6 or hour>=18 else "day"
