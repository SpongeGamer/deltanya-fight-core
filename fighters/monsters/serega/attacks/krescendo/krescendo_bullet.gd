extends Pellet
class_name KrescendoBullet
# Снаряд для атаки «Крещендо».
# Обычный: летит по спиральному направлению, постепенно ускоряется.
# Эхо: сразу преследует душу, пульсирует ярче.

var speed:        float   = 80.0
var direction:    Vector2 = Vector2.RIGHT

var is_echo:      bool  = false
var soul_target:  Soul  = null
var chase_duration: float = 1.6

var life_timer:   float = 0.0
const ACCEL:      float = 40.0      # ускорение обычных нот
const MAX_SPEED:  float = 200.0

var time:         float = 0.0
const PULSE_FREQ: float = 6.0


func _ready() -> void:
	if !visible:
		return

	if soul_target == null:
		soul_target = get_tree().get_first_node_in_group("soul") as Soul

	if is_echo:
		modulate = Color(1.0, 0.45, 0.05, 1.0)   # оранжевый — «затухающий тон»
	else:
		# Зелёный — цвет нарастания
		modulate = Color(
			randf_range(0.0, 0.2),
			randf_range(0.75, 1.0),
			randf_range(0.3, 0.6),
			1.0
		)


func _physics_process(delta: float) -> void:
	if !visible:
		return

	life_timer += delta
	time       += delta

	if is_echo and soul_target != null:
		# Эхо преследует душу всё время своей жизни
		if life_timer <= chase_duration:
			var to_soul := (soul_target.global_position - global_position).normalized()
			direction = direction.lerp(to_soul, delta * 6.0).normalized()
			speed = min(speed + 60.0 * delta, MAX_SPEED)

		# Пульсация размера
		var pulse: float = 1.0 + 0.3 * sin(time * PULSE_FREQ)
		scale = Vector2.ONE * pulse
	else:
		# Обычная нота: постепенно ускоряется
		speed = min(speed + ACCEL * delta, MAX_SPEED)
		scale = Vector2.ONE

	position += direction * speed * delta

	if position.x > 125.0 or position.x < -125.0 \
	or position.y > 100.0 or position.y < -100.0:
		queue_free()
