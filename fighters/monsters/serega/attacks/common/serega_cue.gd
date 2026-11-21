extends Node2D
# Short silhouette / direction cue outside the soul box, never a hitbox.
var side: int = 1
var kind: int = 0
var portrait: Texture2D
var age: float = 0.0
var duration: float = 0.85
func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age > duration:
		queue_free()
func _draw() -> void:
	var alpha: float = sin(clampf(age / duration, 0.0, 1.0) * PI) * 0.75
	var x: float = float(side) * 83.0
	var c := Color(0.92, 0.56, 0.8, alpha)
	if kind == 0:
		# Guitar neck and strings.
		draw_rect(Rect2(x - 3, -46, 6, 92), Color(0.25, 0.16, 0.30, alpha))
		for y in [-36.0, -18.0, 0.0, 18.0, 36.0]:
			draw_line(Vector2(x - 5, y), Vector2(x + 5, y), c, 1.0)
	else:
		# The shadow uses Serega's actual battle frame rather than a generic figure.
		if portrait:
			# Keep the character upright even when the warning is on another edge.
			draw_set_transform(Vector2(x, 0), -rotation)
			draw_texture_rect(portrait, Rect2(-15.0, -35.0, 30.0, 66.0), false, Color(0.55, 0.37, 0.62, alpha))
			draw_set_transform(Vector2.ZERO)
		else:
			draw_circle(Vector2(x, -20), 6, c)
			draw_rect(Rect2(x - 4, -14, 8, 20), c)
