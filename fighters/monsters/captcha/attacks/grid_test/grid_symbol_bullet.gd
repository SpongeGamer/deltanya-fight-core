extends Pellet
# GRID_SYMBOL_BULLET
# Стоит пока dropping = false (позиция устанавливается снаружи).
# После dropping = true — падает вниз с лёгким ускорением.

var label      := "?"
var dropping   := false
var drop_speed := 120.0
var _vel       := 0.0
const GRAVITY  := 50.0
var _armed := false

func _ready() -> void:
	if !visible:
		return
	$CollisionShape2D.disabled = true
	var lbl := get_node_or_null("Label")
	if lbl:
		lbl.text = label

func _physics_process(delta: float) -> void:
	if !visible or !dropping:
		return
	if not _armed:
		_armed = true
		$CollisionShape2D.set_deferred("disabled", false)
	_vel       += GRAVITY * delta
	position.y += (drop_speed + _vel) * delta
	if position.y > 95.0:
		queue_free()
