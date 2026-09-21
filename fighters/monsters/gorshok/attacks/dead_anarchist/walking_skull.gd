extends Pellet
class_name WalkingSkull

enum Phase { RISING, WALKING }
var phase: Phase = Phase.RISING

var rise_from_y: float = 0.0
var rise_to_y:   float = 0.0
const RISE_DURATION: float = 0.7
var rise_t: float = 0.0

var walk_dir:   Vector2 = Vector2.ZERO
var soul_target: Node2D = null
const WALK_SPEED:    float = 36.0
const CHASE_STRENGTH: float = 1.4   # скорость поворота к игроку

var lifetime: float = 0.0
const MAX_LIFE: float = 9.0
const ARENA_X:  float = 108.0


func _ready() -> void:
	if !visible:
		return
	rise_from_y = position.y
	rise_to_y   = randf_range(10.0, 45.0)
	soul_target = get_tree().get_first_node_in_group("soul")
	if has_node("Sprite"):
		$Sprite.speed_scale = 0.0


func _physics_process(delta: float) -> void:
	if !visible:
		return
	lifetime += delta
	if lifetime >= MAX_LIFE:
		queue_free()
		return

	match phase:
		Phase.RISING:
			rise_t += delta / RISE_DURATION
			position.y = lerpf(rise_from_y, rise_to_y,
				ease(clamp(rise_t, 0.0, 1.0), -2.0))
			if rise_t >= 1.0:
				_start_walking()

		Phase.WALKING:
			# Постоянно поворачиваемся к игроку — медленно, как зомби
			if soul_target != null and is_instance_valid(soul_target):
				var to_soul := (soul_target.global_position - global_position).normalized()
				walk_dir = walk_dir.lerp(to_soul, delta * CHASE_STRENGTH).normalized()

			position += walk_dir * WALK_SPEED * delta

			# Разворачиваем спрайт
			if has_node("Sprite"):
				$Sprite.flip_h = walk_dir.x < 0

			# Отражаем от стен чтобы не застревал
			if position.x > ARENA_X or position.x < -ARENA_X:
				walk_dir.x = -walk_dir.x
				position.x = clamp(position.x, -ARENA_X, ARENA_X)


func _start_walking() -> void:
	phase = Phase.WALKING
	if soul_target != null:
		walk_dir = (soul_target.global_position \
			- get_parent().global_position - position).normalized()
	else:
		walk_dir = Vector2(1.0, 0.0)
	if has_node("Sprite"):
		$Sprite.flip_h  = walk_dir.x < 0
		$Sprite.speed_scale = 4.0
