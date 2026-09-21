extends Pellet

var vel := Vector2.ZERO

func _ready() -> void:
	if not visible:
		return

func _physics_process(delta: float) -> void:
	if not visible:
		return
	position += vel * delta
	if position.x > 90.0 or position.x < -90.0:
		queue_free()
