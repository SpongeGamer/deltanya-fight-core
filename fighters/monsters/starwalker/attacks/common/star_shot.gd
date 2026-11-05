extends Pellet
class_name StarwalkerShot
## Звезда с небольшим честным хитбоксом и коротким световым следом.

const TEX := preload("res://fighters/monsters/starwalker/starwalker_bullet.png")
var velocity := Vector2.ZERO
var curve := 0.0
var age := 0.0
var lifetime := 4.0
var tint := Color("fff3a6")
var _trail: Array[Vector2] = []

func _init() -> void:
	collision_layer = 2
	collision_mask = 1
	damage = 7
	graze_points = 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)
	var star := Sprite2D.new()
	star.texture = TEX
	star.modulate = tint
	add_child(star)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	age += delta
	velocity = velocity.rotated(curve * delta)
	position += velocity * delta
	if Engine.get_physics_frames() % 3 == 0:
		_trail.push_front(global_position)
		if _trail.size() > 5:
			_trail.pop_back()
	queue_redraw()
	if age >= lifetime or absf(position.x) > 180.0 or absf(position.y) > 180.0:
		queue_free()

func _draw() -> void:
	# Неброский ореол не меняет размер реального хитбокса.
	draw_circle(Vector2.ZERO, 8.0, Color(tint, 0.10))
	for i in _trail.size():
		var p := to_local(_trail[i])
		var alpha := 0.36 * (1.0 - float(i) / 5.0)
		draw_circle(p, maxf(1.0, 2.5 - i * 0.4), Color(tint, alpha))
