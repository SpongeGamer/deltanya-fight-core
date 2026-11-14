extends Pellet
class_name StringBullet

var speed := 150.0
var dir := 1.0

func _ready() -> void:
	if visible:
		modulate = Color.WHITE

func _physics_process(delta: float) -> void:
	if not visible:
		return
	position.x += speed * dir * delta
	if (dir > 0 and position.x > 170.0) or (dir < 0 and position.x < -170.0):
		queue_free()
