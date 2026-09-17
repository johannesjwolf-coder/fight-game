extends RefCounted
const InputFrame = preload("res://scripts/shared/simulation/input_frame.gd")
const MatchState = preload("res://scripts/shared/simulation/match_state.gd")
const Simulation = preload("res://scripts/shared/simulation/simulation.gd")
const FORMAT_VERSION := 1
const RULES_ID := "foundation-v1"
const MAX_FRAMES := 3600
const MAX_JSON_BYTES := 1024 * 1024
var initial_state = MatchState.new()
var frames: Array = []

func append(inputs: Array) -> bool:
	if frames.size() >= MAX_FRAMES or inputs.size() != 2:
		return false
	var encoded: Array = []
	for command in inputs:
		if not command is InputFrame or not command.is_valid(initial_state.tick + frames.size()):
			return false
		encoded.append(command.encode())
	frames.append(encoded)
	return true

func to_json() -> String:
	return JSON.stringify({"version": FORMAT_VERSION, "rules": RULES_ID, "initial": initial_state.canonical(), "frames": frames})

static func _integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

static func from_json(text: String) -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_JSON_BYTES:
		return {"ok": false, "error": "Replay too large"}
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {"ok": false, "error": "Malformed replay JSON"}
	var data: Variant = parser.data
	if not data is Dictionary or data.get("version") != FORMAT_VERSION or data.get("rules") != RULES_ID:
		return {"ok": false, "error": "Invalid replay version or rules"}
	var initial: Variant = data.get("initial")
	var rows: Variant = data.get("frames")
	if not initial is Array or initial.size() != 5 or not rows is Array or rows.size() > MAX_FRAMES:
		return {"ok": false, "error": "Invalid replay structure"}
	if initial[0] != MatchState.VERSION or not _integer(initial[1], 0, 10000000) or not _integer(initial[2], 0, 28800):
		return {"ok": false, "error": "Invalid initial state"}
	var replay = load("res://scripts/shared/replay/recording.gd").new()
	replay.initial_state.tick = int(initial[1])
	replay.initial_state.remaining_ticks = int(initial[2])
	var keys := ["x", "y", "vx", "vy", "held", "pressed"]
	for player in range(2):
		var fields: Variant = initial[player + 3]
		if not fields is Array or fields.size() != keys.size():
			return {"ok": false, "error": "Invalid fighter state"}
		for index in range(keys.size()):
			var limit := 1000000000 if index < 4 else InputFrame.ALL
			var minimum := -limit if index < 4 else 0
			if not _integer(fields[index], minimum, limit):
				return {"ok": false, "error": "Invalid fighter field"}
			replay.initial_state.fighters[player][keys[index]] = int(fields[index])
	for index in range(rows.size()):
		var row: Variant = rows[index]
		if not row is Array or row.size() != 2:
			return {"ok": false, "error": "Invalid input pair"}
		var commands: Array = []
		for fields in row:
			if not fields is Array or fields.size() != 3:
				return {"ok": false, "error": "Invalid input fields"}
			if not _integer(fields[0], 0, 10000000) or not _integer(fields[1], 0, 255) or not _integer(fields[2], 0, 255):
				return {"ok": false, "error": "Invalid input values"}
			commands.append(InputFrame.new(int(fields[0]), int(fields[1]), int(fields[2])))
		if not replay.append(commands):
			return {"ok": false, "error": "Non-sequential replay"}
	return {"ok": true, "recording": replay}

func commands_at(index: int) -> Array:
	var commands: Array = []
	for fields in frames[index]:
		commands.append(InputFrame.new(fields[0], fields[1], fields[2]))
	return commands

func replay() -> Dictionary:
	var state = initial_state.copy()
	var hashes: Array[String] = [state.state_hash()]
	var events: Array = []
	for index in range(frames.size()):
		var result := Simulation.step(state, commands_at(index))
		if not result.ok:
			return result
		state = result.state
		hashes.append(state.state_hash())
		events.append_array(result.events)
	return {"ok": true, "state": state, "hashes": hashes, "events": events}
