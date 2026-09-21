extends Pellet
class_name NoteBullet

var velocity: float = 65.0
var direction: Vector2 = Vector2.RIGHT
var moving: bool = false

var is_false: bool = false
var soul_target: Soul = null

var life_timer: float = 0.0
const CHASE_AFTER: float = 1.0    # секунд до начала погони
var chase_duration: float = 1.8   # секунд активной погони (настраивается из ballada.gd)

const MAX_VELOCITY: float = 210.0


func _ready() -> void:
	if !visible:
		return
	moving = true

	if soul_target == null:
		soul_target = get_tree().get_first_node_in_group("soul") as Soul
	if soul_target == null:
		soul_target = get_tree().current_scene.get_node_or_null("Soul") as Soul
	if soul_target == null:
		push_warning("NoteBullet: Soul не найдена! Группа 'soul' пуста и нет ноды Soul в %s" \
			% get_tree().current_scene.name)

	if is_false:
		modulate = Color(0.972, 0.0, 0.162, 1.0)
	else:
		modulate = Color(0.0, 0.657, 0.995, 1.0)


func _physics_process(delta: float) -> void:
	if !moving or !visible:
		return

	life_timer += delta

	if is_false and soul_target != null:
		var chasing: bool = life_timer >= CHASE_AFTER \
			and life_timer <= CHASE_AFTER + chase_duration
		if chasing:
			var to_soul := (soul_target.global_position - global_position).normalized()
			direction = direction.lerp(to_soul, delta * 4.0).normalized()
			velocity  = min(velocity + 120.0 * delta, MAX_VELOCITY)

	position += direction * velocity * delta

	if position.x < -120.0 or position.x > 120.0 \
	or position.y < -90.0  or position.y > 90.0:
		queue_free()
