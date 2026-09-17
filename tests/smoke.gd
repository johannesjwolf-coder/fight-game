extends SceneTree
## Run after import: godot --headless --path . --script tests/smoke.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second")) != 60:
		_fail("Physics tick must be 60 Hz")
		return
	var scene := load("res://scenes/bootstrap.tscn") as PackedScene
	if scene == null:
		_fail("Bootstrap scene failed to load")
		return
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	var server_mode := "--server" in OS.get_cmdline_user_args()
	var expected := "Server" if server_mode else "Client"
	var forbidden := "Client" if server_mode else "Server"
	if not instance.has_node(expected) or instance.has_node(forbidden):
		_fail("Incorrect bootstrap path: " + expected)
		return
	if not server_mode:
		var client = instance.get_node("Client")
		var button = client.get_child(0).get_child(0)
		button.pressed.emit()
		if client.show_guides:
			_fail("Grid toggle did not update presentation")
			return
		var debug = client.get_child(1)
		debug.paused = true
		debug._tick()
		debug._verify_recording()
		if not debug.notice.begins_with("Replay PASS"):
			_fail("Debug replay verification failed")
			return
	instance.queue_free()
	await process_frame
	print("PASS: " + expected + " bootstrap, 60 Hz configuration and lifecycle")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
