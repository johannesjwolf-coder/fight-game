extends Node2D
## Static original artwork. Phase 1 intentionally contains no gameplay physics.

const INK := Color("ecf0fa")
const MUTED := Color("95a4c3")
const ORANGE := Color("ffad72")
var show_guides := true

func _ready() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var button := Button.new()
	button.text = "Raster umschalten"
	button.position = Vector2(904, 642)
	button.size = Vector2(200, 38)
	button.pressed.connect(func() -> void:
		show_guides = not show_guides
		queue_redraw())
	hud.add_child(button)
	button.grab_focus()
	get_viewport().size_changed.connect(queue_redraw)
	add_child(load("res://scripts/client/simulation_debug.gd").new())

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(48, 51), "FG / FIGHT GAME", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ORANGE)
	draw_string(font, Vector2(852, 49), "PHASE 02  /  GODOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, MUTED)
	draw_line(Vector2(48, 74), Vector2(1104, 74), Color("30394d"))
	draw_string(font, Vector2(48, 129), "Deine Arena. Deine Regeln.", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, INK)
	draw_string(font, Vector2(48, 159), "Das Fundament fuer einen eigenen Platform Fighter.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, MUTED)
	draw_rect(Rect2(48, 190, 1056, 412), Color("172239"))
	if show_guides:
		for x in range(48, 1105, 48):
			draw_line(Vector2(x, 190), Vector2(x, 602), Color("24334c"))
		for y in range(218, 603, 48):
			draw_line(Vector2(48, y), Vector2(1104, y), Color("24334c"))
	# Main platform plus two one-way-platform placeholders.
	for platform in [Rect2(240, 502, 672, 24), Rect2(296, 375, 176, 12), Rect2(680, 375, 176, 12)]:
		draw_rect(platform, Color("536d96"))
		draw_line(platform.position, platform.position + Vector2(platform.size.x, 0), Color("c4d7f4"), 3)
	draw_rect(Rect2(390, 448, 32, 54), ORANGE)
	draw_circle(Vector2(415, 462), 3, Color("172239"))
	draw_rect(Rect2(730, 434, 44, 68), Color("7bc9e9"))
	draw_circle(Vector2(737, 450), 3, Color("172239"))
	draw_string(font, Vector2(364, 555), "FUNKE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ORANGE)
	draw_string(font, Vector2(717, 555), "AMBOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("7bc9e9"))
	draw_string(font, Vector2(48, 639), "RENDER-VORSCHAU / Noch kein spielbarer Kampf", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
	draw_string(font, Vector2(48, 671), "Simulation + Replay bereit. Als Naechstes: Tastatur und Ground Movement.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, MUTED)
