extends Pellet
# Хоминг-курсор: медленно поворачивается в сторону соула.
# Не телепортируется — поворот ограничен turn_speed.
# Можно уклониться резким движением в сторону.

var velocity   := 85.0
var direction  := Vector2.DOWN
var turn_speed := 1.8   # радиан/сек — чем больше, тем "умнее"
var moving     := false

func _ready() -> void:
	if !visible:
		return
	moving = true

func _physics_process(delta: float) -> void:
	if !moving or !visible:
		return

	# Ищем Soul в родительской сцене (battle)
	var soul: Node2D = get_parent().get_node_or_null("Soul")
	if soul:
		var to_soul := (soul.global_position - global_position).normalized()
		# Плавный поворот к соулу
		var angle_diff := direction.angle_to(to_soul)
		var max_turn   := turn_speed * delta
		if absf(angle_diff) <= max_turn:
			direction = to_soul
		else:
			direction = direction.rotated(signf(angle_diff) * max_turn)

	position += direction * velocity * delta

	if absf(position.x) > 90.0 or absf(position.y) > 90.0:
		queue_free()
