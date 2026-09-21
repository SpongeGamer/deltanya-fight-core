extends Pellet
class_name StringBullet

var speed: float = 80.0
var dir: float   = 1.0   # 1.0 = вправо, -1.0 = влево

func _ready() -> void:
	if !visible:
		return
	modulate = Color(0.84, 0.21, 0.86, 1.0)

func _physics_process(delta: float) -> void:
	if !visible:
		return
	position.x += speed * dir * delta
	# Порог — за пределами широкой клетки (280px → стены на ±138)
	if position.x > 170.0 or position.x < -170.0:
		queue_free()
