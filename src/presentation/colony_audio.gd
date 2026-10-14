class_name ColonyAudio
extends Node
const ROOT_BUS: String = "Brackenward"
const MUSIC_BUS: String = "Brackenward Music"
const EFFECTS_BUS: String = "Brackenward Effects"
const UI_BUS: String = "Brackenward UI"
static var active_instances: int = 0
var world: ColonyWorld
var view: WorldView
var plan: ColonySoundPlan = ColonySoundPlan.new()
var voices: Array[AudioStreamPlayer] = []
var voice_serials: Array[int] = []
var music_players: Dictionary = {}
var volumes: Dictionary = {"master":0.8,"music":0.35,"effects":0.6,"ui":0.6}
var haptics: bool = false
var suspended: bool = false
var auto_hidden: bool = false
var music_clock: float = 0.0
var ambience_clock: float = 0.0
var observed_tick: int = -1
var alerts: Array = []
var people: Dictionary = {}
var opportunity_id: int = 0
var footsteps: int = 0
var water_points: Array[Vector2i] = []
var water_center: Vector2i = Vector2i(-1000,-1000)
var water_distance: int = 1000
var history: Array[Dictionary] = []
var clock_us: int = 0
var pending_playbacks: Array[WeakRef] = []

func _enter_tree() -> void:
	active_instances+=1

func _exit_tree() -> void:
	stop_all()
	for player in voices: player.stream=null
	for player in music_players.values(): player.stream=null
	active_instances-=1
	if active_instances==0:
		ColonyAudioLibrary.streams.clear()
		for name in [UI_BUS,EFFECTS_BUS,MUSIC_BUS,ROOT_BUS]:
			var index: int = AudioServer.get_bus_index(name)
			if index>0: AudioServer.remove_bus(index)

func _init() -> void:
	_bus(ROOT_BUS,"Master");_bus(MUSIC_BUS,ROOT_BUS);_bus(EFFECTS_BUS,ROOT_BUS);_bus(UI_BUS,ROOT_BUS)
	var root: int = AudioServer.get_bus_index(ROOT_BUS)
	if AudioServer.get_bus_effect_count(root)==0:
		var limiter: AudioEffectHardLimiter = AudioEffectHardLimiter.new();limiter.ceiling_db=-1.0
		AudioServer.add_bus_effect(root,limiter)
	for index in range(ColonySoundPlan.MAX_VOICES):
		var player: AudioStreamPlayer = AudioStreamPlayer.new();player.playback_type=AudioServer.PLAYBACK_TYPE_STREAM;player.max_polyphony=1
		add_child(player);voices.append(player);voice_serials.append(0)
	for theme in ["day","night","tension"]:
		var player: AudioStreamPlayer = AudioStreamPlayer.new();player.bus=MUSIC_BUS;player.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
		add_child(player);music_players[theme]=player

static func _bus(name: String, send: String) -> void:
	if AudioServer.get_bus_index(name)>=0: return
	AudioServer.add_bus();var index: int = AudioServer.bus_count-1
	AudioServer.set_bus_name(index,name);AudioServer.set_bus_send(index,send)

func bind_world(state: ColonyWorld, camera: WorldView) -> void:
	stop_all();world=state;view=camera;music_clock=0.0;water_points.clear();water_center=Vector2i(-1000,-1000)
	# Warm compressed resources while adopting the paused world, rather than
	# performing first-use file IO during a future work/footstep callback.
	for id in ColonyAudioLibrary.IDS: ColonyAudioLibrary.stream(id)
	for index in range(128*128):
		if (world.generator_version>0 and world.terrain_state.elevation[index]==0) or (world.generator_version==0 and index%128 in [32,33,34,35]): water_points.append(Vector2i(index%128,index/128))
	_baseline()
	clock_us=Time.get_ticks_usec()

func _baseline() -> void:
	observed_tick=world.tick;alerts=_alerts();people.clear();opportunity_id=0
	for person in world.citizens: people[person.id]=_person_state(person)
	for event in world.opportunity_state.offers: opportunity_id=maxi(opportunity_id,event.id)

func _alerts() -> Array:
	return [world.care_state.alert_serial,world.fire_state.alert_serial,world.defense_state.alert_serial,world.region_state.alert_serial]

func _person_state(person: Dictionary) -> Dictionary:
	var job: Dictionary = world.find(world.jobs,person.job)
	return {"point":Vector2i(person.x,person.y),"job":person.job,"work":int(job.get("work",0))/1000,"departure":person.departure_until}

func apply_settings(levels: Dictionary, tactile: bool) -> void:
	volumes=levels.duplicate();haptics=tactile
	for channel in ["master","music","effects","ui"]:
		var name: String = {"master":ROOT_BUS,"music":MUSIC_BUS,"effects":EFFECTS_BUS,"ui":UI_BUS}[channel]
		var index: int = AudioServer.get_bus_index(name)
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.0001,volumes[channel])))
		AudioServer.set_bus_mute(index,volumes[channel]<=0)
	if volumes.master<=0 or volumes.effects<=0:
		for index in range(plan.slots.size()):
			if plan.slots[index].get("loop",false): plan.slots[index]={}
	_sync_voices();_sync_music()

func cue(id: String, priority: int = 2, repeat_key: String = "", gain: float = 0.7) -> bool:
	if suspended or not is_instance_valid(view) or not view.is_visible_in_tree(): return false
	if haptics and OS.has_feature("android") and id in ["ui_confirm","ui_error","cue_warning","cue_critical"]: Input.vibrate_handheld(45 if id=="cue_critical" else 20)
	var channel: String = "ui" if id.begins_with("ui_") else "effects"
	if volumes.master<=0 or volumes[channel]<=0: return false
	_step_clock()
	var stream: AudioStreamOggVorbis = ColonyAudioLibrary.stream(id)
	var index: int = plan.request(id,priority,stream.get_length(),false,repeat_key,gain)
	if index<0: return false
	history.append({"kind":id,"priority":priority,"time":plan.elapsed});if history.size()>32: history.pop_front()
	_sync_voices();return true

func observe() -> void:
	if suspended or not is_instance_valid(world) or not is_instance_valid(view) or not view.is_visible_in_tree() or world.tick==observed_tick: return
	var current: Array = _alerts()
	if current[0]>alerts[0] or current[1]>alerts[1] or current[2]>alerts[2]: cue("cue_critical",3,"",1.0)
	elif current[3]>alerts[3]: cue("cue_warning",2,"",0.9)
	alerts=current;observed_tick=world.tick
	for event in world.opportunity_state.offers:
		if event.id>opportunity_id and event.state=="Offered": cue("cue_opportunity")
		opportunity_id=maxi(opportunity_id,event.id)
	for person in world.citizens:
		var after: Dictionary = _person_state(person)
		var before: Dictionary = people.get(person.id,after)
		people[person.id]=after
		if person.death_recorded or person.departed or person.away or person.carried_by>0: continue
		if after.departure>0 and after.departure!=before.departure: cue("cue_warning",2,"",0.9)
		var visible_near: bool = nearby(after.point,12)
		if after.point!=before.point and visible_near:
			cue("footstep_%d" % (footsteps%5),2 if person.id==view.selected_id else 1,"footstep",0.35);footsteps+=1
			world._refresh_navigation()
			var old_door: int = world.door_tiles.get(before.point,0);var new_door: int = world.door_tiles.get(after.point,0)
			if old_door!=new_door:
				if old_door>0: cue("door_close",1,"door",0.45)
				if new_door>0: cue("door_open",1,"door",0.45)
		var job: Dictionary = world.find(world.jobs,person.job)
		if not visible_near or job.get("state")!="Working" or after.job!=before.job or after.work==before.work: continue
		var kind: String = ""
		if job.kind in ["gather","build","repair","demolish"]: kind="chop"
		elif job.kind=="research": kind="book"
		elif job.kind=="craft": kind="cloth"
		if not kind.is_empty(): cue(kind,2 if person.id==view.selected_id else 1,kind,0.45)

func nearby(point: Vector2i, distance: int) -> bool:
	var center: Vector2 = view.camera_center()
	return absf(point.x+0.5-center.x)+absf(point.y+0.5-center.y)<=distance and Rect2(Vector2.ZERO,view.size).has_point(view.tile_to_screen(Vector2(point)+Vector2.ONE*0.5))

func _step_clock() -> float:
	var now: int = Time.get_ticks_usec()
	var delta: float = maxf(0.0,float(now-clock_us)/1000000.0) if clock_us>0 else 0.0
	clock_us=now;plan.advance(delta);music_clock+=delta
	pending_playbacks=pending_playbacks.filter(func(reference:WeakRef)->bool:return reference.get_ref()!=null)
	return delta

func _process(_delta: float) -> void:
	if suspended or not is_instance_valid(world) or not is_instance_valid(view): return
	if not view.is_visible_in_tree():
		if not auto_hidden: stop_all();auto_hidden=true
		return
	if auto_hidden: auto_hidden=false;_baseline();clock_us=Time.get_ticks_usec()
	var delta: float = _step_clock()
	plan.music(ColonyAudioLibrary.theme_for(world))
	_sync_voices();_sync_music()
	ambience_clock+=delta
	if ambience_clock>=0.25: ambience_clock=0.0;_ambience()

func _sync_voices() -> void:
	var critical: bool = plan.slots.any(func(slot:Dictionary)->bool:return slot.get("priority",0)==3)
	for index in range(voices.size()):
		var slot: Dictionary = plan.slots[index]
		var player: AudioStreamPlayer = voices[index]
		if slot.is_empty():
			if player.playing: _stop_player(player)
			voice_serials[index]=0;continue
		var gain: float = slot.gain*(0.35 if critical and slot.priority<3 else 1.0)
		var decibels: float = linear_to_db(maxf(gain,0.0001))
		if not is_equal_approx(player.volume_db,decibels): player.volume_db=decibels
		if voice_serials[index]==slot.serial: continue
		_stop_player(player);player.stream=ColonyAudioLibrary.stream(slot.kind)
		player.bus=UI_BUS if slot.kind.begins_with("ui_") else EFFECTS_BUS
		player.play(fmod(music_clock,player.stream.get_length()) if slot.loop else 0.0)
		voice_serials[index]=slot.serial

func _sync_music() -> void:
	var duck: float = 0.65 if plan.slots.any(func(slot:Dictionary)->bool:return slot.get("priority",0)==3) else 1.0
	for theme in music_players:
		var player: AudioStreamPlayer = music_players[theme]
		var weight: float = plan.weights[theme]
		if suspended or volumes.master<=0 or volumes.music<=0 or weight<=0.0001:
			if player.playing: _stop_player(player)
			continue
		var decibels: float = linear_to_db(maxf(weight*duck,0.0001))
		if not is_equal_approx(player.volume_db,decibels): player.volume_db=decibels
		if not player.playing:
			player.stream=ColonyAudioLibrary.stream("music_"+theme)
			player.play(fmod(music_clock,90.0))

func _ambience() -> void:
	if volumes.master<=0 or volumes.effects<=0: return
	var wanted: Dictionary = {"ambient_wind":0.10}
	if world.weather in ["rain","flood"]: wanted["ambient_rain"]=0.25
	if world.weather in ["drought","cold_snap","snow"]: wanted.ambient_wind=0.18
	var center: Vector2i = Vector2i(view.camera_center())
	if center!=water_center:
		water_center=center;water_distance=1000
		for point in water_points: water_distance=mini(water_distance,absi(center.x-point.x)+absi(center.y-point.y))
	if water_distance<=8: wanted["ambient_river"]=0.23*(1.0-float(water_distance)/12.0)
	var near_fire: bool = world.structures.any(func(s:Dictionary)->bool:return s.health>0 and s.definition=="hearth" and s.fuel>0 and nearby(Vector2i(s.x,s.y),8))
	if not near_fire:
		for fire in world.fire_state.fires:
			if fire.done: continue
			var points: Array = ColonyFire.footprint(world,fire)
			if not points.is_empty() and nearby(points[0],8): near_fire=true;break
	if near_fire: wanted["ambient_fire"]=0.18
	for index in range(plan.slots.size()):
		var slot: Dictionary = plan.slots[index]
		if slot.get("loop",false) and not wanted.has(slot.kind): plan.slots[index]={}
	for kind in wanted:
		var index: int = plan.loop_slot(kind)
		if index>=0: plan.slots[index].gain=wanted[kind]
		else: plan.request(kind,0,12.0,true,"",wanted[kind])
	_sync_voices()

func stop_all() -> void:
	plan.reset()
	for player in voices: _stop_player(player)
	for player in music_players.values(): _stop_player(player)
	voice_serials.fill(0);ambience_clock=0.0

func _stop_player(player: AudioStreamPlayer) -> void:
	if player.has_stream_playback(): pending_playbacks.append(weakref(player.get_stream_playback()))
	player.stop();player.stream=null

func drain() -> bool:
	# Godot releases stopped streaming playbacks during subsequent server
	# updates. Observe their weak lifetimes instead of guessing a sleep time.
	suspend()
	var deadline: int = Time.get_ticks_msec()+1000
	while true:
		pending_playbacks=pending_playbacks.filter(func(reference:WeakRef)->bool:return reference.get_ref()!=null)
		if pending_playbacks.is_empty(): return true
		if Time.get_ticks_msec()>=deadline: return false
		await get_tree().process_frame
	return false

func suspend() -> void:
	suspended=true;stop_all();set_process(false)

func resume() -> void:
	if is_instance_valid(world): _baseline()
	clock_us=Time.get_ticks_usec();suspended=false;set_process(true)
