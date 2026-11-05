extends Pellet
# GLYPH_BULLET
# orbiting = true  → позиция управляется снаружи (orbit_glyph.gd)
# orbiting = false → полет по прямой до края арены

var orbiting   := true
var velocity   := 75.0
var direction  := Vector2.DOWN
var turn_speed := 2.0

func _ready() -> void:
	if !visible:
		return

func _physics_process(delta: float) -> void:
	if !visible:
		return
	if orbiting:
		return

	position += direction * velocity * delta

	if absf(position.x) > 95.0 or absf(position.y) > 95.0:
		queue_free()
