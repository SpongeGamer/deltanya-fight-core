extends Pellet
# SYMBOL_BULLET — падает вниз, виляет по X синусоидой.
# label, speed, amplitude, frequency, phase задаются снаружи.

var label     := "?"
var speed     := 80.0
var amplitude := 12.0
var frequency := 2.5
var phase     := 0.0

var _age      := 0.0
var _base_x   := 0.0
var moving    := false

func _ready() -> void:
	if !visible:
		return
	_base_x = position.x
	moving  = true
	var lbl := get_node_or_null("Label")
	if lbl:
		lbl.text = label

func _physics_process(delta: float) -> void:
	if !moving or !visible:
		return
	_age       += delta
	position.y += speed * delta
	position.x  = _base_x + sin(_age * frequency + phase) * amplitude
	if position.y > 92.0:
		queue_free()
