extends Pellet

signal hit_soul

var rise_speed: float = 14.0

func _ready() -> void:
	collision_layer = 2
	collision_mask  = 1
	damage = 99

func _physics_process(delta: float) -> void:
	position.y -= rise_speed * delta

# Переопределяем Pellet — не queue_free, а сигнал + урон
func _on_body_entered(body: Node2D) -> void:
	if body is Soul:
		body.hurt(damage)
		hit_soul.emit()
