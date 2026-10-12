class_name ColonyStore
extends PrototypeStore

func _init() -> void:
	directory = "user://m1"

func encode(world: RefCounted) -> PackedByteArray:
	return ColonyCodec.encode(world)

func decode(bytes: PackedByteArray) -> Dictionary:
	return ColonyCodec.decode(bytes)
