extends Node
## The same project has client and dedicated-server entry paths.

func _ready() -> void:
	var server_mode := OS.has_feature("dedicated_server") or "--server" in OS.get_cmdline_user_args()
	if server_mode:
		var server = load("res://scripts/server/server_root.gd").new()
		server.name = "Server"
		add_child(server)
	else:
		var client = load("res://scenes/client.tscn").instantiate()
		add_child(client)
