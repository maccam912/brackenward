class_name DeviceSettings
extends RefCounted
## Device-wide UI preferences. Imported campaigns never replace this record.
const VERSION: int = 5
var path: String = "user://device-settings.json"
var values: Dictionary = defaults()

static func defaults() -> Dictionary:
	return {"schema_version":VERSION,"text_scale":1.0,"left_handed":false,"last_slot":1,"tutorials":{},
		"cameras":[[68.0,63.0,32.0],[68.0,63.0,32.0],[68.0,63.0,32.0],[68.0,63.0,32.0],[68.0,63.0,32.0]],
		"reduced_motion":false,"high_contrast":false,"inspector_pause":false,"quality":"Balanced",
		"auto_pauses":SimRunner.default_auto_pauses(),
		"bindings":ControlBindings.DEFAULTS.duplicate(true),"audio":audio_defaults(),"haptics":false}

static func audio_defaults() -> Dictionary:
	return {"master":0.8,"music":0.35,"effects":0.6,"ui":0.6}

func load_local() -> void:
	if not FileAccess.file_exists(path):
		return
	var handle: FileAccess = FileAccess.open(path,FileAccess.READ)
	if handle == null or handle.get_length() > 1024*1024:
		return
	var parser: JSON = JSON.new()
	if parser.parse(handle.get_as_text()) != OK:
		return
	var candidate: Variant = parser.data
	if candidate is Dictionary and candidate.get("schema_version")==1 and ColonyCodec._keys(candidate,["schema_version","text_scale","left_handed","last_slot","cameras"]):
		candidate=candidate.duplicate(true);candidate.schema_version=2;candidate["tutorials"]={}
	if candidate is Dictionary and candidate.get("schema_version")==2 and ColonyCodec._keys(candidate,["schema_version","text_scale","left_handed","last_slot","cameras","tutorials"]):
		candidate=candidate.duplicate(true);candidate.schema_version=3
		candidate["reduced_motion"]=false;candidate["high_contrast"]=false;candidate["inspector_pause"]=false;candidate["quality"]="Balanced"
		candidate["auto_pauses"]=SimRunner.default_auto_pauses();candidate["bindings"]=ControlBindings.DEFAULTS.duplicate(true)
	if candidate is Dictionary and candidate.get("schema_version")==3 and ColonyCodec._keys(candidate,["schema_version","text_scale","left_handed","last_slot","cameras","tutorials","reduced_motion","high_contrast","inspector_pause","quality","auto_pauses","bindings"]):
		candidate=candidate.duplicate(true);candidate.schema_version=4;candidate["audio"]=audio_defaults();candidate["haptics"]=false
	if candidate is Dictionary and candidate.get("schema_version")==4 and ColonyCodec._keys(candidate,defaults().keys()):
		candidate=candidate.duplicate(true);candidate.schema_version=5
	if not _valid(candidate): return
	values = candidate
	values.schema_version = int(values.schema_version)
	values.last_slot = int(values.last_slot)
	for state in values.tutorials.values(): state.version=int(state.version)
	for action in values.bindings: values.bindings[action]=values.bindings[action].map(func(code:Variant)->int:return int(code))

func _valid(data: Variant) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,defaults().keys()) or data.schema_version != VERSION or not data.left_handed is bool or data.text_scale not in [1.0,1.25,1.5] or not data.last_slot is float and not data.last_slot is int:
		return false
	for key in ["reduced_motion","high_contrast","inspector_pause","haptics"]:
		if not data[key] is bool: return false
	if data.quality not in ["Battery","Balanced","Smooth"] or not ControlBindings.valid(data.bindings): return false
	if not data.auto_pauses is Dictionary or not ColonyCodec._keys(data.auto_pauses,defaults().auto_pauses.keys()) or not data.auto_pauses.values().all(func(v:Variant)->bool:return v is bool): return false
	if not data.audio is Dictionary or not ColonyCodec._keys(data.audio,audio_defaults().keys()): return false
	for level in data.audio.values():
		if (not level is float and not level is int) or not is_finite(float(level)) or level<0 or level>1: return false
	if data.last_slot != floor(data.last_slot) or data.last_slot < 1 or data.last_slot > 5 or not data.cameras is Array or data.cameras.size() != 5:
		return false
	for camera: Variant in data.cameras:
		if not camera is Array or camera.size() != 3:
			return false
		for value in camera:
			if (not value is float and not value is int) or not is_finite(float(value)):
				return false
		if camera[0] < 0 or camera[0] > 128 or camera[1] < 0 or camera[1] > 128 or camera[2] < WorldView.MIN_TILE_SIZE or camera[2] > WorldView.MAX_TILE_SIZE:
			return false
	if not data.tutorials is Dictionary or data.tutorials.size()>1024: return false
	for campaign_id in data.tutorials:
		if not campaign_id is String or campaign_id.is_empty() or campaign_id.length()>80 or not ColonyTutorial.valid(data.tutorials[campaign_id]): return false
	return true

func save_local() -> String:
	var bytes: PackedByteArray = JSON.stringify(values,"",true).to_utf8_buffer()
	var error: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		return "Could not create device-settings directory"
	var handle: FileAccess = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if handle == null:
		return "Could not save device preferences"
	handle.store_buffer(bytes)
	handle.flush()
	error = handle.get_error()
	handle.close()
	var parser: JSON = JSON.new()
	if error != OK or parser.parse(FileAccess.get_file_as_string(path+".tmp")) != OK or not _valid(parser.data):
		return "Device preferences did not verify"
	error = DirAccess.rename_absolute(path+".tmp",path)
	return "" if error == OK else "Could not finalize device preferences"
