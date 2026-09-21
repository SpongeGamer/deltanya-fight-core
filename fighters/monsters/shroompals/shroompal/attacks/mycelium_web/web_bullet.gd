extends Pellet

var direction := Vector2.RIGHT
var speed     := 95.0

func _physics_process(delta: float) -> void:
	if !visible:
		return
	position += direction * speed * delta
	if absf(position.x) > 95.0 or absf(position.y) > 95.0:
		queue_free()
