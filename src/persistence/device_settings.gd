class_name DeviceSettings
extends RefCounted
## Device-wide UI preferences. Imported campaigns never replace this record.
var path: String = "user://device-settings.json"
var values: Dictionary = {"schema_version":1,"text_scale":1.0,"left_handed":false,"last_slot":1,
	"cameras":[[68.0,63.0,32.0],[68.0,63.0,32.0],[68.0,63.0,32.0],[68.0,63.0,32.0],[68.0,63.0,32.0]]}

func load_local() -> void:
	if not FileAccess.file_exists(path):
		return
	var handle: FileAccess = FileAccess.open(path,FileAccess.READ)
	if handle == null or handle.get_length() > 16384:
		return
	var parser: JSON = JSON.new()
	if parser.parse(handle.get_as_text()) != OK or not _valid(parser.data):
		return
	values = parser.data
	values.schema_version = int(values.schema_version)
	values.last_slot = int(values.last_slot)

func _valid(data: Variant) -> bool:
	if not data is Dictionary or not ColonyCodec._keys(data,values.keys()) or data.schema_version != 1 or not data.left_handed is bool or data.text_scale not in [1.0,1.25,1.5] or not data.last_slot is float and not data.last_slot is int:
		return false
	if data.last_slot != floor(data.last_slot) or data.last_slot < 1 or data.last_slot > 5 or not data.cameras is Array or data.cameras.size() != 5:
		return false
	for camera: Variant in data.cameras:
		if not camera is Array or camera.size() != 3:
			return false
		for value in camera:
			if not value is float and not value is int:
				return false
		if camera[0] < 0 or camera[0] > 128 or camera[1] < 0 or camera[1] > 128 or camera[2] < 16 or camera[2] > 64:
			return false
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
