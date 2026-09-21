extends Pellet
class_name WingBullet

var velocity := 200.0
var direction := Vector2.ZERO
var moving := false

func _ready() -> void:
	if !visible:
		return
	moving = true

func _physics_process(delta: float) -> void:
	if !moving or !visible:
		return
	
	position += direction * velocity * delta
	
	if absf(position.x) > 100.0 or absf(position.y) > 100.0:
		queue_free()
