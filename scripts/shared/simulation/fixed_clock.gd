extends RefCounted
## Integer accumulator. Caller supplies elapsed microseconds; never used inside step().
const TICKS_PER_SECOND := 60
const UNITS_PER_TICK := 1000000
const MAX_CATCH_UP := 8
var accumulator := 0
var dropped_ticks := 0

func advance(elapsed_us: int) -> int:
	if elapsed_us < 0:
		return 0
	# Clamp extreme stalls before multiplication. Discarded time is observable.
	var bounded := mini(elapsed_us, 10000000)
	dropped_ticks += (elapsed_us - bounded) * TICKS_PER_SECOND / UNITS_PER_TICK
	accumulator += bounded * TICKS_PER_SECOND
	var due: int = accumulator / UNITS_PER_TICK
	accumulator %= UNITS_PER_TICK
	var steps := mini(due, MAX_CATCH_UP)
	dropped_ticks += due - steps
	return steps

func reset() -> void:
	accumulator = 0
	dropped_ticks = 0
