extends Pellet
class_name StarBullet

var velocity: float = 100.0
var direction: Vector2 = Vector2.LEFT
var moving: bool = false

func _ready() -> void:
	if !visible:
		return
	moving = true


func _physics_process(delta: float) -> void:
	if !moving or !visible:
		return

	position += direction * velocity * delta

	# удаляем когда выходит за пределы поля
	if position.x < -100.0 or position.x > 100.0 or position.y < -80.0 or position.y > 80.0:
		queue_free()
