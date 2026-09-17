extends RefCounted
## Identical fixture runs in native server and browser exports. Never starts a match.
const InputFrame = preload("res://scripts/shared/simulation/input_frame.gd")
const Recording = preload("res://scripts/shared/replay/recording.gd")
const FixedClock = preload("res://scripts/shared/simulation/fixed_clock.gd")
const Simulation = preload("res://scripts/shared/simulation/simulation.gd")

static func fixture():
	var recording = Recording.new()
	recording.initial_state.fighters[0].vx = 125
	recording.initial_state.fighters[1].vy = -75
	for tick in range(120):
		var held := InputFrame.RIGHT if tick < 60 else InputFrame.LEFT
		var pressed := InputFrame.JUMP if tick == 10 else 0
		recording.append([InputFrame.new(tick, held, pressed), InputFrame.new(tick, 0, InputFrame.LIGHT if tick == 50 else 0)])
	return recording

static func run() -> Dictionary:
	var recording = fixture()
	var expected: Dictionary = recording.replay()
	var rates: Dictionary = {}
	for fps in [30, 60, 144]:
		var clock = FixedClock.new()
		var state = recording.initial_state.copy()
		var hashes: Array[String] = [state.state_hash()]
		for frame in range(fps * 2):
			var end_us: int = (frame + 1) * 1000000 / fps
			var start_us: int = frame * 1000000 / fps
			for unused in range(clock.advance(end_us - start_us)):
				state = Simulation.step(state, recording.commands_at(state.tick)).state
				hashes.append(state.state_hash())
		rates[str(fps)] = {"tick": state.tick, "hash": state.state_hash(), "trace_hash": JSON.stringify(hashes).sha256_text(), "dropped": clock.dropped_ticks}
	var ok: bool = expected.ok
	for value in rates.values():
		ok = ok and value.tick == 120 and value.hash == expected.state.state_hash() and value.dropped == 0
		ok = ok and value.trace_hash == JSON.stringify(expected.hashes).sha256_text()
	return {"ok": ok, "tick": expected.state.tick, "hash": expected.state.state_hash(), "trace_hash": JSON.stringify(expected.hashes).sha256_text(), "rates": rates}
