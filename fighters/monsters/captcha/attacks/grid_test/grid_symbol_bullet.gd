extends Pellet
# GRID_SYMBOL_BULLET
# Стоит пока dropping = false (позиция устанавливается снаружи).
# После dropping = true — падает вниз с лёгким ускорением.

var label      := "?"
var dropping   := false
var drop_speed := 120.0
var _vel       := 0.0
const GRAVITY  := 50.0

func _ready() -> void:
	if !visible:
		return
	var lbl := get_node_or_null("Label")
	if lbl:
		lbl.text = label

func _physics_process(delta: float) -> void:
	if !visible or !dropping:
		return
	_vel       += GRAVITY * delta
	position.y += (drop_speed + _vel) * delta
	if position.y > 95.0:
		queue_free()
