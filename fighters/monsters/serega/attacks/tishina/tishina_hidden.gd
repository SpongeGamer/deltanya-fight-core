extends Pellet
class_name TishinaHidden
# «Невидимый» снаряд для атаки «Тишина».
# Большую часть времени — полностью прозрачный (alpha = 0).
# Раз в ~1.2 секунды мигает на 0.12 секунды — предупреждение.
# После вызова reveal() становится полностью видимым и ускоряется.

var speed:       float   = 65.0
var direction:   Vector2 = Vector2.RIGHT

# Мигание
var blink_timer:    float = 0.0
const BLINK_INTERVAL: float = 1.15   # секунд между вспышками
const BLINK_DURATION: float = 0.12   # длительность вспышки

var blink_active:   bool  = false
var blink_elapsed:  float = 0.0

# Revealed-режим
var is_revealed:    bool  = false
const REVEAL_ACCEL: float = 180.0
const MAX_SPEED:    float = 230.0

var time:           float = 0.0


func _ready() -> void:
	if !visible:
		return
	# Полностью прозрачный
	modulate = Color(0.8, 0.0, 0.9, 0.0)
	# Начинаем первое мигание не сразу — стагерный старт
	blink_timer = randf_range(0.3, 1.0)


func _physics_process(delta: float) -> void:
	if !visible:
		return

	time += delta

	if is_revealed:
		# После reveal — видимый, ускоряется
		speed = min(speed + REVEAL_ACCEL * delta, MAX_SPEED)
		modulate.a = 1.0
	else:
		# Логика мигания
		if blink_active:
			blink_elapsed += delta
			# Плавный fade in/out вспышки
			var t: float = blink_elapsed / BLINK_DURATION
			var alpha: float
			if t < 0.5:
				alpha = t * 2.0
			else:
				alpha = (1.0 - t) * 2.0
			modulate.a = clampf(alpha, 0.0, 1.0)

			if blink_elapsed >= BLINK_DURATION:
				blink_active  = false
				blink_elapsed = 0.0
				modulate.a    = 0.0
				blink_timer   = randf_range(BLINK_INTERVAL - 0.2, BLINK_INTERVAL + 0.2)
		else:
			blink_timer -= delta
			if blink_timer <= 0.0:
				blink_active  = true
				blink_elapsed = 0.0

	position += direction * speed * delta

	if position.x > 130.0 or position.x < -130.0 \
	or position.y > 105.0 or position.y < -105.0:
		queue_free()


# Вызывается из tishina.gd при финальном вскрике
func reveal() -> void:
	is_revealed = true
	modulate    = Color(0.9, 0.1, 1.0, 1.0)   # яркий фиолетово-белый
	# Случайный импульс направления — снаряды «взрываются» в разные стороны
	direction = direction.rotated(randf_range(-0.5, 0.5))
