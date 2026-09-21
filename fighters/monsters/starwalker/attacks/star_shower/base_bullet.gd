extends Pellet
class_name BaseBullet

var velocity := 240.0
var moving := false
var delay := 0.0
var start_y := 0.0

func _ready() -> void:
	if !visible:
		return
	start_y = position.y
	if delay <= 0.0:
		moving = true
	

func _physics_process(delta: float) -> void:
	if !moving or !visible:
		if delay > 0.0:
			delay -= delta
			if delay <= 0.0:
				moving = true
				position.y = start_y  # сбрасываем на старт
		return
	
	position.y += velocity * delta
	if position.y >= 62.0:
		queue_free()
