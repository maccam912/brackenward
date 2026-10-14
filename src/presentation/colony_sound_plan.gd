class_name ColonySoundPlan
extends RefCounted
## Presentation-only bounded voices and fades. No simulation clock or RNG writes.
const MAX_VOICES: int = 12
var elapsed: float = 0.0
var serial: int = 0
var slots: Array[Dictionary] = []
var repeats: Dictionary = {}
var target: String = ""
var weights: Dictionary = {"day":0.0,"night":0.0,"tension":0.0}
var fade_from: Dictionary = weights.duplicate()
var fade_started: float = 0.0
var fade_seconds: float = 4.0

func _init() -> void:
	for index in range(MAX_VOICES): slots.append({})

func advance(delta: float) -> void:
	elapsed+=maxf(0.0,delta)
	for index in range(slots.size()):
		if not slots[index].is_empty() and not slots[index].loop and elapsed>=slots[index].until: slots[index]={}
	if not target.is_empty():
		var fraction: float = clampf((elapsed-fade_started)/fade_seconds,0.0,1.0)
		for theme in weights: weights[theme]=lerpf(fade_from[theme],1.0 if theme==target else 0.0,fraction)

func music(theme: String) -> void:
	if theme==target: return
	assert(weights.has(theme))
	fade_from=weights.duplicate();fade_started=elapsed
	fade_seconds=8.0 if target=="tension" and theme!="tension" else 4.0
	target=theme

func request(kind: String, priority: int, duration: float, loop: bool = false, repeat_key: String = "", gain: float = 1.0) -> int:
	if not repeat_key.is_empty():
		var recent: Array = repeats.get(repeat_key,[]).filter(func(time:float)->bool:return elapsed-time<1.0)
		repeats[repeat_key]=recent
		if recent.size()>=3: return -1
	var chosen: int = -1
	for index in range(slots.size()):
		if slots[index].is_empty(): chosen=index;break
		if slots[index].priority>priority: continue
		if chosen<0 or slots[index].priority<slots[chosen].priority or (slots[index].priority==slots[chosen].priority and slots[index].serial<slots[chosen].serial): chosen=index
	if chosen<0: return -1
	if not repeat_key.is_empty(): repeats[repeat_key].append(elapsed)
	serial+=1
	slots[chosen]={"kind":kind,"priority":priority,"until":elapsed+duration,"loop":loop,"serial":serial,"gain":gain}
	return chosen

func loop_slot(kind: String) -> int:
	for index in range(slots.size()):
		if slots[index].get("loop",false) and slots[index].kind==kind: return index
	return -1

func reset() -> void:
	for index in range(slots.size()): slots[index]={}
	repeats.clear();elapsed=0.0;serial=0;target=""
	for theme in weights: weights[theme]=0.0
	fade_from=weights.duplicate();fade_started=0.0;fade_seconds=4.0
