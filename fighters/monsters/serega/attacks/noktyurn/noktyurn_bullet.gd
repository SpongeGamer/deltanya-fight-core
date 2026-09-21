extends Pellet
class_name NoktyurnBullet
# Падающая нота для атаки «Ноктюрн».
# Обычная нота падает вниз с небольшим сносом.
# Фальшивая (красная) после короткой задержки начинает преследовать душу.

var fall_speed:     float = 70.0
var drift:          float = 0.0       # горизонтальный снос px/s

var is_false:       bool  = false
var soul_target:    Soul  = null

var life_timer:     float = 0.0
const CHASE_AFTER:  float = 0.8       # секунд до начала погони
var chase_duration: float = 2.2       # секунд активного преследования

const MAX_SPEED:    float = 220.0
const ACCEL:        float = 130.0     # ускорение при погоне

# Визуальная пульсация (для фальшивых нот)
var pulse_timer:    float = 0.0
const PULSE_FREQ:   float = 8.0


func _ready() -> void:
	if !visible:
		return

	if soul_target == null:
		soul_target = get_tree().get_first_node_in_group("soul") as Soul

	if is_false:
		modulate = Color(0.97, 0.08, 0.18, 1.0)  # ярко-красная
	else:
		# Синие ноты с лёгким случайным оттенком
		modulate = Color(
			randf_range(0.0, 0.15),
			randf_range(0.55, 0.75),
			randf_range(0.9, 1.0),
			1.0
		)


func _physics_process(delta: float) -> void:
	if !visible:
		return

	life_timer   += delta
	pulse_timer  += delta

	var vel := Vector2(drift, fall_speed)

	if is_false and soul_target != null:
		var chasing: bool = life_timer >= CHASE_AFTER \
			and life_timer <= CHASE_AFTER + chase_duration
		if chasing:
			var to_soul := (soul_target.global_position - global_position).normalized()
			# Поворачиваем скоростной вектор в сторону души
			var current_dir := vel.normalized()
			current_dir = current_dir.lerp(to_soul, delta * 5.0).normalized()
			fall_speed = min(fall_speed + ACCEL * delta, MAX_SPEED)
			vel = current_dir * fall_speed

			# Пульсация размера при погоне
			var pulse: float = 1.0 + 0.25 * sin(pulse_timer * PULSE_FREQ)
			scale = Vector2.ONE * pulse
		else:
			scale = Vector2.ONE

	position += vel * delta

	# Деспавн за пределами арены
	if position.y > 100.0 or position.y < -110.0 \
	or position.x > 115.0 or position.x < -115.0:
		queue_free()
