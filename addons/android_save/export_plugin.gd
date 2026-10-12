@tool
extends EditorPlugin

var exporter: SaveExport

func _enter_tree() -> void:
	exporter = SaveExport.new()
	add_export_plugin(exporter)

func _exit_tree() -> void:
	remove_export_plugin(exporter)

class SaveExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "BrackenwardSave"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray(["res://addons/android_save/brackenward-save-%s.aar" % ("debug" if debug else "release")])
