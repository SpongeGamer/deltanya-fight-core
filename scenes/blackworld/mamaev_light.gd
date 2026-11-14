@tool
extends Node2D
## Move this light in the 2D editor; its glow is visible there too.

@export_range(0.0, 0.1, 0.001) var brightness := 0.014:
	set(value):
		brightness = value
		queue_redraw()
@export_range(1.0, 3.0, 0.1) var radius_scale := 1.0:
	set(value):
		radius_scale = value
		queue_redraw()
@export var insects := false:
	set(value):
		insects = value
		queue_redraw()

var _time := 0.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()

func _draw() -> void:
	var phase := float(hash(name) % 100) * 0.1
	var pulse := 0.9 if Engine.is_editor_hint() else 0.8 + 0.2 * sin(_time * 1.5 + phase)
	for radius in [24.0, 18.0, 12.0, 7.0]:
		draw_circle(Vector2.ZERO, radius * radius_scale, Color(1.0, 0.58, 0.23, brightness * pulse))
	if insects and not Engine.is_editor_hint():
		for i in 3:
			var insect_phase := phase + i * 2.1
			var radius := 8.0 + i * 4.0
			var pos := Vector2(sin(_time * 0.65 + insect_phase) * radius, 6.0 + cos(_time * 0.87 + insect_phase * 1.3) * radius * 0.65).round()
			var blink := clampf((sin(_time * 2.0 + insect_phase) + 0.6) * 0.55, 0.05, 0.8)
			draw_rect(Rect2(pos, Vector2(2, 2)), Color(1.0, 0.78, 0.35, blink))
