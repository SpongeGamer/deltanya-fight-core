extends Node2D

# Мягкий ореол позади цветка; не создает освещение сцены или коллизии.
func _draw() -> void:
	for radius in [20.0, 14.0, 8.0]:
		draw_circle(Vector2(0, 1), radius, Color(0.48, 0.78, 1.0, 0.045))
