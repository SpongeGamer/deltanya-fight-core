extends Pellet
# GLYPH_BULLET
# orbiting = true  → позиция управляется снаружи (orbit_glyph.gd)
# orbiting = false → хоминг к soul, как homing_cursor

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

	var soul : Node2D = get_parent().get_node_or_null("Soul")
	if soul:
		var to_soul    := (soul.global_position - global_position).normalized()
		var angle_diff := direction.angle_to(to_soul)
		var max_turn   := turn_speed * delta
		if absf(angle_diff) <= max_turn:
			direction = to_soul
		else:
			direction = direction.rotated(signf(angle_diff) * max_turn)

	position += direction * velocity * delta

	if absf(position.x) > 95.0 or absf(position.y) > 95.0:
		queue_free()
