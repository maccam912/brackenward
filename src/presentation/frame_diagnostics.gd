class_name FrameDiagnostics
extends RefCounted
## Bounded, local presentation measurements. No files, world mutation or uploads.
const STAGES: Array[String] = ["frame_gap","session","simulation_batch","map_update","map_draw_commands","audio_update","save_capture","snapshot_capture","save_finish","save_explicit"]
const LIMITS_US: Array[int] = [4000,8000,16000,25000,33334,50000,100000,250000,500000,1000000]
const MAX_EVENTS: int = 32
const MAX_EXPORT_BYTES: int = 65536
var samples: Dictionary = {}
var slow_events: Array[Dictionary] = []
var counters: Dictionary = {"slow_storage_pauses":0,"speed_reductions":0,"backgrounds":0,"storage_alerts":0,"quiet_sleep_limits":0}
var previous_frame_us: int = 0
var tick: int = 0
var speed: int = 0
var foreground: bool = true

func frame(now_us: int, current_tick: int, current_speed: int) -> void:
	tick=current_tick;speed=current_speed
	if previous_frame_us>0 and now_us>=previous_frame_us: record("frame_gap",now_us-previous_frame_us)
	previous_frame_us=now_us

func break_frame_clock() -> void:
	previous_frame_us=0

func count(key: String) -> void:
	if counters.has(key): counters[key]+=1

func record(stage: String, microseconds: int, measured_tick: int = -1, measured_speed: int = -1) -> void:
	var at_speed: int = speed if measured_speed<0 else measured_speed
	if not foreground or stage not in STAGES or microseconds<0 or at_speed not in [0,1,2,4,12]: return
	var key: String = "%s:%d" % [stage,at_speed]
	if not samples.has(key): samples[key]={"stage":stage,"speed":at_speed,"count":0,"sum_us":0,"max_us":0,"over_50ms":0,"buckets":Array(LIMITS_US).map(func(_limit:int)->int:return 0)+[0]}
	var entry: Dictionary = samples[key]
	entry.count+=1;entry.sum_us+=microseconds;entry.max_us=maxi(entry.max_us,microseconds)
	var bucket: int = 0
	while bucket<LIMITS_US.size() and microseconds>LIMITS_US[bucket]: bucket+=1
	entry.buckets[bucket]+=1
	if microseconds>50000:
		entry.over_50ms+=1
		slow_events.append({"stage":stage,"speed":at_speed,"tick":str(tick if measured_tick<0 else measured_tick),"duration_ms":float(microseconds)/1000.0})
		if slow_events.size()>MAX_EVENTS: slow_events.pop_front()

func reset() -> void:
	samples.clear();slow_events.clear();previous_frame_us=0
	for key in counters: counters[key]=0

static func percentile_upper(entry: Dictionary, percentile: int) -> Variant:
	var target: int = ceili(float(entry.count)*percentile/100.0)
	var cumulative: int = 0
	for index in range(entry.buckets.size()):
		cumulative+=entry.buckets[index]
		if cumulative>=target: return float(LIMITS_US[index])/1000.0 if index<LIMITS_US.size() else null
	return null

func report(metadata: Dictionary) -> Dictionary:
	var timings: Array[Dictionary] = []
	var keys: Array = samples.keys();keys.sort()
	for key in keys:
		var entry: Dictionary = samples[key]
		timings.append({"stage":entry.stage,"speed":entry.speed,"count":entry.count,"mean_ms":float(entry.sum_us)/entry.count/1000.0,"max_ms":float(entry.max_us)/1000.0,"over_50ms":entry.over_50ms,"p95_bucket_upper_ms":percentile_upper(entry,95),"p99_bucket_upper_ms":percentile_upper(entry,99),"buckets":entry.buckets.duplicate()})
	return {"format":"brackenward-performance","version":1,"scope":"Local session CPU callbacks and wall-clock frame gaps; nested callbacks overlap; excludes GPU/audio-thread/PSS/battery certification","metadata":metadata.duplicate(true),"bucket_upper_ms":Array(LIMITS_US).map(func(value:int)->float:return float(value)/1000.0)+[null],"timings":timings,"slow_events":slow_events.duplicate(true),"counters":counters.duplicate(),"slow_event_limit":MAX_EVENTS}
