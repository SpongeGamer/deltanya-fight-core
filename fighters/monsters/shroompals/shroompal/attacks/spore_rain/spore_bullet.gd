extends Pellet
# SPORE_BULLET — падает вниз, виляет по X синусоидой.

var speed     := 75.0
var amplitude := 8.0
var frequency := 2.2
var phase     := 0.0

var _age    := 0.0
var _base_x := 0.0

func _ready() -> void:
	if !visible:
		return
	_base_x = position.x

func _physics_process(delta: float) -> void:
	if !visible:
		return
	_age       += delta
	position.y += speed * delta
	position.x  = _base_x + sin(_age * frequency + phase) * amplitude
	if position.y > 92.0:
		queue_free()
