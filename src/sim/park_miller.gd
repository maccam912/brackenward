class_name ParkMiller
extends RefCounted

const MODULUS: int = 2147483647
var state: int = 1

func _init(initial_state: int = 1) -> void:
	assert(initial_state > 0 and initial_state < MODULUS)
	state = initial_state

func next() -> int:
	state = (state * 48271) % MODULUS
	return state

func bounded(n: int) -> int:
	assert(n > 0)
	return next() % n

static func derive(seed: int, generator_version: int, site: String, stream: String) -> int:
	var bytes: PackedByteArray = ("%d|%d|%s|%s" % [seed, generator_version, site, stream]).sha256_buffer()
	var value: int = (int(bytes[0]) << 24) | (int(bytes[1]) << 16) | (int(bytes[2]) << 8) | int(bytes[3])
	return 1 + value % (MODULUS - 1)
