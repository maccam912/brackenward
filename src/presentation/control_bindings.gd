class_name ControlBindings
extends RefCounted
const DEFAULTS: Dictionary = {"pause":[KEY_SPACE],"speed_1":[KEY_1],"speed_2":[KEY_2],"speed_4":[KEY_3],"build":[KEY_B],"work":[KEY_J],"people":[KEY_P],"valley":[KEY_V],"journal":[KEY_L],"pan_up":[KEY_W,KEY_UP],"pan_down":[KEY_S,KEY_DOWN],"pan_left":[KEY_A,KEY_LEFT],"pan_right":[KEY_D,KEY_RIGHT],"back":[KEY_ESCAPE]}
const LABELS: Dictionary = {"pause":"Pause / resume","speed_1":"Speed 1x","speed_2":"Speed 2x","speed_4":"Speed 4x","build":"Build","work":"Work","people":"People","valley":"Valley","journal":"Journal","pan_up":"Pan up","pan_down":"Pan down","pan_left":"Pan left","pan_right":"Pan right","back":"Close / cancel"}

static func valid(value: Variant) -> bool:
	if not value is Dictionary or not ColonyCodec._keys(value,DEFAULTS.keys()): return false
	var used: Dictionary = {}
	for action in value:
		if not value[action] is Array or value[action].size()<1 or value[action].size()>2: return false
		for code in value[action]:
			if (not code is int and not code is float) or code!=floor(code) or code<=0 or code>0x7fffffff or OS.find_keycode_from_string(OS.get_keycode_string(int(code)))!=int(code) or used.has(int(code)): return false
			used[int(code)]=true
	return true

static func action_for(bindings: Dictionary, code: int) -> String:
	for action in bindings:
		if bindings[action].has(code): return action
	return ""

static func rebind(bindings: Dictionary, action: String, code: int) -> Dictionary:
	if not DEFAULTS.has(action) or code<=0 or code>0x7fffffff or OS.find_keycode_from_string(OS.get_keycode_string(code))!=code: return {"error":"Choose a keyboard key or shortcut."}
	var owner: String = action_for(bindings,code)
	if not owner.is_empty() and owner!=action: return {"error":"%s is already used for %s. Choose another key or change that action first." % [OS.get_keycode_string(code),LABELS[owner]]}
	var result: Dictionary = bindings.duplicate(true);result[action]=[code]
	return {"bindings":result}

static func describe(codes: Array) -> String:
	var names: PackedStringArray = []
	for code in codes: names.append(OS.get_keycode_string(int(code)))
	return " / ".join(names)
