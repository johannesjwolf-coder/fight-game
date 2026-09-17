extends SceneTree
const State = preload("res://scripts/shared/simulation/match_state.gd")
const InputFrame = preload("res://scripts/shared/simulation/input_frame.gd")
const Simulation = preload("res://scripts/shared/simulation/simulation.gd")
const Clock = preload("res://scripts/shared/simulation/fixed_clock.gd")
const Recording = preload("res://scripts/shared/replay/recording.gd")
const Probe = preload("res://scripts/diagnostics/replay_probe.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var state = State.new()
	var initial_hash: String = state.state_hash()
	var result := Simulation.step(state, [InputFrame.new(0, InputFrame.RIGHT, InputFrame.JUMP), InputFrame.new()])
	check(result.ok and result.state.tick == 1 and result.state.remaining_ticks == 28799, "Tick and timer")
	check(state.state_hash() == initial_hash, "step must not mutate input state")
	check(result.events.size() == 1 and result.events[0].pressed == InputFrame.JUMP, "Pressed edge event")
	var released := Simulation.step(result.state, [InputFrame.new(1), InputFrame.new(1)])
	check(released.events.size() == 1 and released.events[0].released == InputFrame.RIGHT, "Release event")
	check(not Simulation.step(state, [InputFrame.new(1), InputFrame.new()]).ok, "Reject wrong tick")
	check(not Simulation.step(state, [InputFrame.new(0, 256), InputFrame.new()]).ok, "Reject invalid mask")
	check(not Simulation.step(state, []).ok, "Reject missing player")
	state.remaining_ticks = 0
	check(Simulation.step(state, [InputFrame.new(), InputFrame.new()]).state.remaining_ticks == 0, "Timer does not underflow")
	var fixture = Probe.fixture()
	var expected: Dictionary = fixture.replay()
	check(expected.state.fighters[0].x == 421000 and expected.state.fighters[1].y == 493000, "Integer integration fixture")
	check(expected.hashes.size() == 121, "Every tick hashed")
	var decoded := Recording.from_json(fixture.to_json())
	check(decoded.ok, "Replay JSON round trip")
	if decoded.ok:
		check(decoded.recording.replay().hashes == expected.hashes, "Replay must match every tick, not only final state")
		check(decoded.recording.replay().events == expected.events, "Replay events repeat identically")
	var broken: Dictionary = JSON.parse_string(fixture.to_json())
	broken.frames[2][0][0] = 1
	check(not Recording.from_json(JSON.stringify(broken)).ok, "Reject reordered input")
	broken = JSON.parse_string(fixture.to_json())
	broken.initial[3][0] = 1.5
	check(not Recording.from_json(JSON.stringify(broken)).ok, "Reject fractional position")
	check(not Recording.from_json("{}").ok and not Recording.from_json("garbage").ok, "Reject malformed replay")
	check(Recording.from_json(Recording.new().to_json()).ok, "Empty recording is valid")
	var tail = Recording.new()
	tail.initial_state = fixture.initial_state.copy()
	for index in range(60):
		tail.initial_state = Simulation.step(tail.initial_state, fixture.commands_at(index)).state
	for index in range(60, 120):
		check(tail.append(fixture.commands_at(index)), "Snapshot continuation accepts correct tick")
	check(Recording.from_json(tail.to_json()).recording.replay().state.state_hash() == expected.state.state_hash(), "Resume from nonzero snapshot")
	var bounded = Recording.new()
	for tick in range(Recording.MAX_FRAMES):
		bounded.append([InputFrame.new(tick), InputFrame.new(tick)])
	check(not bounded.append([InputFrame.new(3600), InputFrame.new(3600)]), "Recording is bounded")
	var command = InputFrame.new(0, InputFrame.RIGHT)
	var saved = Recording.new()
	saved.append([command, InputFrame.new()])
	command.held = InputFrame.LEFT
	check(saved.commands_at(0)[0].held == InputFrame.RIGHT, "Recording owns a copy of input")
	var clone = expected.state.copy()
	clone.fighters[0].x += 1
	check(clone.state_hash() != expected.state.state_hash(), "Snapshot deep copy and hash sensitivity")
	var clock = Clock.new()
	check(clock.advance(-1) == 0, "Ignore negative delta")
	check(clock.advance(1000000) == 8 and clock.dropped_ticks == 52, "Bound catch-up and report discarded ticks")
	check(clock.advance(0) == 0, "Do not replay dropped backlog")
	clock.reset()
	check(clock.dropped_ticks == 0 and clock.accumulator == 0, "Clock reset")
	var probe := Probe.run()
	check(probe.ok, "Identical 30/60/144 Hz replay")
	print("REPLAY_RESULT=" + JSON.stringify(probe))
	print("Simulation checks: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
