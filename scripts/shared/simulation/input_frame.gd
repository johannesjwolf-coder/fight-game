extends RefCounted
## One immutable-by-convention command per player and tick. Bit masks are portable.
const LEFT := 1
const RIGHT := 2
const UP := 4
const DOWN := 8
const JUMP := 16
const LIGHT := 32
const HEAVY := 64
const DODGE := 128
const ALL := 255

var tick: int
var held: int
var pressed: int

func _init(frame_tick: int = 0, held_mask: int = 0, pressed_mask: int = 0) -> void:
	tick = frame_tick
	held = held_mask
	pressed = pressed_mask

func is_valid(expected_tick: int) -> bool:
	return tick == expected_tick and held >= 0 and held <= ALL and pressed >= 0 and pressed <= ALL

func encode() -> Array:
	return [tick, held, pressed]
