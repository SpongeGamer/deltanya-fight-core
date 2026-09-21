extends AnimatableBody2D

var speed: float = 45.0
const HALF_W: float = 20.0
const HALF_H: float = 4.0

func _ready() -> void:
	sync_to_physics = false
	collision_layer = 1
	collision_mask  = 0

func _physics_process(delta: float) -> void:
	position.y += speed * delta
	if position.y > 130.0:
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(-HALF_W, -HALF_H, HALF_W * 2.0, HALF_H * 2.0), Color(0.85, 0.85, 0.85))
	draw_rect(Rect2(-HALF_W, -HALF_H, HALF_W * 2.0, 2.0), Color(1.0, 1.0, 1.0))
	draw_rect(Rect2(-HALF_W, HALF_H - 2.0, HALF_W * 2.0, 2.0), Color(0.5, 0.5, 0.5))
