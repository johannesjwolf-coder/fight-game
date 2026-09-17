extends CanvasLayer
const MatchState = preload("res://scripts/shared/simulation/match_state.gd")
const InputFrame = preload("res://scripts/shared/simulation/input_frame.gd")
const Simulation = preload("res://scripts/shared/simulation/simulation.gd")
const FixedClock = preload("res://scripts/shared/simulation/fixed_clock.gd")
const Recording = preload("res://scripts/shared/replay/recording.gd")
const Probe = preload("res://scripts/diagnostics/replay_probe.gd")
var state = MatchState.new()
var clock = FixedClock.new()
var recording = Recording.new()
var paused := false
var display_elapsed := 0.0
var notice := "Neutrale Inputs; Steuerung folgt in Phase 3"
var status: Label
var pause_button: Button

func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(64, 204)
	panel.size = Vector2(670, 112)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 14)
	box.add_child(status)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	pause_button = _button(buttons, "Pause", func() -> void:
		paused = not paused
		clock.reset()
		_refresh())
	_button(buttons, "+1 Tick", func() -> void:
		paused = true
		clock.reset()
		_tick()
		_refresh())
	_button(buttons, "Reset", func() -> void:
		state = MatchState.new()
		recording = Recording.new()
		clock.reset()
		notice = "Aufzeichnung zurueckgesetzt"
		_refresh())
	_button(buttons, "Replay pruefen", _verify_recording)
	_button(buttons, "30/60/144 Hz testen", func() -> void:
		var result: Dictionary = Probe.run()
		notice = "Fixture: PASS bei 30/60/144 Hz" if result.ok else "Fixture: FEHLER"
		_refresh())
	_refresh()

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _process(delta: float) -> void:
	if not paused:
		for unused in range(clock.advance(roundi(delta * 1000000.0))):
			_tick()
	display_elapsed += delta
	if display_elapsed >= 0.1:
		display_elapsed = 0.0
		_refresh()

func _tick() -> void:
	var commands := [InputFrame.new(state.tick), InputFrame.new(state.tick)]
	if not recording.append(commands):
		paused = true
		notice = "Aufzeichnung voll (3600 Ticks). Reset oder Replay pruefen."
		return
	state = Simulation.step(state, commands).state

func _verify_recording() -> void:
	paused = true
	clock.reset()
	var decoded: Dictionary = Recording.from_json(recording.to_json())
	if not decoded.ok:
		notice = "Replay ungueltig: " + decoded.error
	else:
		var replayed: Dictionary = decoded.recording.replay()
		notice = "Replay PASS: %d Ticks identisch" % state.tick if replayed.state.state_hash() == state.state_hash() else "Replay FEHLER"
	_refresh()

func _refresh() -> void:
	status.text = "SIM 60 Hz | Tick %d | Aufnahme %d/3600 | verworfen %d\nHash %s\n%s" % [state.tick, recording.frames.size(), clock.dropped_ticks, state.state_hash().left(20), notice]
	pause_button.text = "Weiter" if paused else "Pause"
