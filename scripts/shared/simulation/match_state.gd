extends RefCounted
## Positions are integer subunits (1/1000 world unit), velocity subunits/tick.
## No Node, clock, rendering, input device or networking dependencies.
const VERSION := 1
var tick := 0
var remaining_ticks := 60 * 8 * 60
var fighters: Array[Dictionary] = [
	{"x": 406000, "y": 502000, "vx": 0, "vy": 0, "held": 0, "pressed": 0},
	{"x": 752000, "y": 502000, "vx": 0, "vy": 0, "held": 0, "pressed": 0},
]

func copy():
	var result = get_script().new()
	result.tick = tick
	result.remaining_ticks = remaining_ticks
	result.fighters = fighters.duplicate(true)
	return result

func canonical() -> Array:
	var values: Array = [VERSION, tick, remaining_ticks]
	for fighter in fighters:
		values.append([fighter.x, fighter.y, fighter.vx, fighter.vy, fighter.held, fighter.pressed])
	return values

func state_hash() -> String:
	# Integers and arrays only: independent of Dictionary key order and float formatting.
	return JSON.stringify(canonical()).sha256_text()
