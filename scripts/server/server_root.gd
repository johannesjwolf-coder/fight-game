extends Node
## Lifecycle foundation only. No listening socket or matches before phase 14.

func _ready() -> void:
	print(JSON.stringify({"event": "server_boot", "phase": 2, "network_ready": false}))
