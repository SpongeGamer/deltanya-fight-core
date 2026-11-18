extends Node2D

# Декорации без коллизий: знакомый свет леса остается у входа,
# а у дальней двери он становится холоднее и реже.
const MUSHROOMS := preload("res://assets/VFX/shroom.png")
const DOOR := preload("res://assets/furniture/final_door.png")
const MUSHROOM_POSITIONS: Array[Vector2] = [
	Vector2(-43, 0), Vector2(43, -110), Vector2(-45, -205),
	Vector2(44, -320)
]
const FIREFLIES: Array[Vector2] = [
	Vector2(-32, -22), Vector2(34, -75), Vector2(-35, -164),
	Vector2(30, -260), Vector2(-33, -360), Vector2(28, -475)
]
var _time: float = 0.0

func _ready() -> void:
	z_index = -3000

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	# Изображения те же, что в грибном лесу; здесь они декоративные.
	for pos in MUSHROOM_POSITIONS:
		for radius in [20.0, 13.0, 7.0]:
			draw_circle(pos + Vector2(0, 5), radius, Color(0.35, 0.83, 1.0, 0.035))
		draw_texture_rect_region(MUSHROOMS, Rect2(pos - Vector2(10, 10), Vector2(19, 20)), Rect2(0, 0, 19, 20))

	for i in FIREFLIES.size():
		var phase: float = float(i) * 2.4
		var pos: Vector2 = (FIREFLIES[i] + Vector2(sin(_time * 0.35 + phase) * 5.0, cos(_time * 0.4 + phase) * 4.0)).round()
		var pulse: float = 0.5 + 0.5 * sin(_time * 1.8 + phase)
		draw_rect(Rect2(pos - Vector2(2, 2), Vector2(5, 5)), Color(0.38, 0.84, 1.0, 0.11 + pulse * 0.1))
		draw_rect(Rect2(pos, Vector2(2, 2)), Color(0.78, 1.0, 1.0, 0.65 + pulse * 0.3))

	# Дверь использует спрайт, который уже встречался в лесу.
	for radius in [54.0, 38.0, 24.0]:
		draw_circle(Vector2(0, -650), radius, Color(0.42, 0.55, 0.9, 0.025))
	draw_texture_rect_region(DOOR, Rect2(-30, -714, 60, 93), Rect2(0, 0, 40, 62))

	# Листок с нотами, который можно осмотреть: легкое покачивание на месте.
	var sway: float = round(sin(_time * 0.8) * 1.0)
	var paper := Vector2(-34 + sway, -409)
	draw_rect(Rect2(paper, Vector2(12, 15)), Color(0.12, 0.13, 0.22))
	draw_rect(Rect2(paper + Vector2(1, 1), Vector2(10, 12)), Color(0.72, 0.70, 0.70))
	for y in [4, 6, 8, 10]:
		draw_line(paper + Vector2(2, y), paper + Vector2(9, y), Color(0.30, 0.29, 0.36), 1.0)
	draw_rect(Rect2(paper + Vector2(6, 5), Vector2(2, 2)), Color(0.16, 0.17, 0.24))
