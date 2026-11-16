extends Node2D

# Небольшие стайки около цветов, грибов, деревни и точки сохранения.
# Координаты локальные для сцены Грибного леса; коллизий у них нет.
const FIREFLY_SPOTS: Array[Vector2] = [
	Vector2(-1250, -85), Vector2(-735, 15), Vector2(-220, 75),
	Vector2(480, 55), Vector2(875, -60),
	Vector2(-1310, 410), Vector2(405, 405),
	Vector2(-1285, 820), Vector2(-580, 855), Vector2(850, 1070),
	Vector2(-865, 1300), Vector2(-2410, 1510), Vector2(-2160, 1660),
	Vector2(-1280, 1750), Vector2(300, 1750), Vector2(480, 2050),
	Vector2(20, 2130)
]

var _time: float = 0.0

func _ready() -> void:
	z_as_relative = false
	z_index = 3500
	var flowers := get_parent().get_node_or_null("MainInteractNodes/EchoFlowers")
	if flowers:
		for child in flowers.get_children():
			if child is AnimatedSprite2D:
				var glow := preload("res://scenes/last_floor/echo_flower_glow.gd").new()
				glow.z_as_relative = false
				glow.z_index = child.z_index - 1
				child.add_child(glow)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	for spot_index in FIREFLY_SPOTS.size():
		var origin: Vector2 = FIREFLY_SPOTS[spot_index]
		var warm: bool = spot_index == 11 or spot_index == 12
		for fly in 3:
			var phase: float = float(spot_index) * 1.83 + float(fly) * 2.39
			var x: float = sin(_time * (0.31 + fly * 0.035) + phase) * (13.0 + fly * 7.0)
			var y: float = cos(_time * (0.39 + fly * 0.025) + phase * 1.3) * (8.0 + fly * 3.0) - fly * 6.0
			var pos: Vector2 = (origin + Vector2(x, y)).round()
			var light: float = 0.5 + 0.5 * sin(_time * 2.1 + phase * 2.0)
			var glow: Color = Color(0.42, 0.88, 1.0, 0.10 + light * 0.12)
			var body: Color = Color(0.78, 1.0, 1.0, 0.6 + light * 0.35)
			if warm:
				glow = Color(1.0, 0.76, 0.35, 0.10 + light * 0.12)
				body = Color(1.0, 0.92, 0.62, 0.6 + light * 0.35)
			draw_rect(Rect2(pos - Vector2(2, 2), Vector2(5, 5)), glow)
			draw_rect(Rect2(pos, Vector2(2, 2)), body)
			# Крохотные крылышки отличают светлячков от обычных спор.
			if sin(_time * 8.0 + phase) > 0.0:
				draw_rect(Rect2(pos + Vector2(-1, -1), Vector2(1, 1)), body)
				draw_rect(Rect2(pos + Vector2(2, -1), Vector2(1, 1)), body)
