extends RefCounted
const InputFrame = preload("res://scripts/shared/simulation/input_frame.gd")

static func step(state, inputs: Array) -> Dictionary:
	if inputs.size() != 2:
		return {"ok": false, "error": "Exactly two input frames required"}
	for command in inputs:
		if not command is InputFrame or not command.is_valid(state.tick):
			return {"ok": false, "error": "Invalid input or tick mismatch"}
	var next = state.copy()
	var events: Array = []
	for index in range(2):
		var fighter: Dictionary = next.fighters[index]
		var command = inputs[index]
		var released: int = fighter.held & ~command.held
		fighter.held = command.held
		fighter.pressed = command.pressed
		# Minimal integrator, not a player controller. Movement rules arrive in phase 3.
		fighter.x += fighter.vx
		fighter.y += fighter.vy
		if command.pressed != 0 or released != 0:
			events.append({"tick": state.tick, "player": index, "pressed": command.pressed, "released": released})
	next.tick += 1
	next.remaining_ticks = maxi(0, next.remaining_ticks - 1)
	return {"ok": true, "state": next, "events": events}
