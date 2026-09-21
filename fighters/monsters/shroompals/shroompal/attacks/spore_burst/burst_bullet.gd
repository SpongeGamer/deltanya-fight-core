extends Pellet

var direction := Vector2.RIGHT
var speed     := 25.0
var amplitude := 0.0
var phase     := 0.0

var _age    := 0.0
var _base_x := 0.0
var _base_y := 0.0

func _ready() -> void:
	if !visible:
		return
	_base_x = position.x
	_base_y = position.y

func _physics_process(delta: float) -> void:
	if !visible:
		return
	_age += delta
	position += direction * speed * delta
	# Синус-дрейф перпендикулярно направлению
	var perp := Vector2(-direction.y, direction.x)
	position += perp * sin(_age * 2.5 + phase) * amplitude * delta
	if absf(position.x) > 95.0 or absf(position.y) > 95.0:
		queue_free()
