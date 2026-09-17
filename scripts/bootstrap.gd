extends Node
## The same project has client and dedicated-server entry paths.

func _ready() -> void:
	var verify := "--verify-replay" in OS.get_cmdline_user_args()
	if OS.has_feature("web"):
		verify = str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('selftest')", true)) == "1"
	if verify:
		var result: Dictionary = load("res://scripts/diagnostics/replay_probe.gd").run()
		print("REPLAY_RESULT=" + JSON.stringify(result))
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.FG_PHASE2_RESULT = " + JSON.stringify(result), true)
		else:
			get_tree().quit(0 if result.ok else 1)
			return
	var server_mode := OS.has_feature("dedicated_server") or "--server" in OS.get_cmdline_user_args()
	if server_mode:
		var server = load("res://scripts/server/server_root.gd").new()
		server.name = "Server"
		add_child(server)
	else:
		var client = load("res://scenes/client.tscn").instantiate()
		add_child(client)
