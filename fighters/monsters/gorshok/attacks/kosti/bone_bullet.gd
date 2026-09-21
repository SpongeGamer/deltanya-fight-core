extends Pellet
class_name BoneBullet

var vel:     Vector2 = Vector2.ZERO
var half_w:  float   = 5.0
var half_h:  float   = 22.0
var moving:  bool    = false

func _ready() -> void:
	if !visible:
		return
	moving = true

func setup(p_vel: Vector2, p_hw: float, p_hh: float) -> void:
	vel    = p_vel
	half_w = p_hw
	half_h = p_hh
	# Новая форма для каждой кости — duplicate() не копирует ресурсы глубоко
	var shape        := RectangleShape2D.new()
	shape.size        = Vector2(p_hw * 2.0, p_hh * 2.0)
	$CollisionShape2D.shape = shape
	queue_redraw()

func _physics_process(delta: float) -> void:
	if !moving or !visible:
		return
	position += vel * delta
	if absf(position.x) > 140.0 or absf(position.y) > 140.0:
		queue_free()
