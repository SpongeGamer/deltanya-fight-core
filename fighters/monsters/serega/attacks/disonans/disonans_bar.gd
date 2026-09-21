extends Pellet
class_name DisonansBar
# Горизонтальная полоса для «Диссонанса».
# moving = false во время телеграфа (стоит на месте, показывает где дырка).
# moving = true  — летит.

var speed:  float = 82.0
var dir:    float = 1.0
var moving: bool  = false

var time: float = 0.0
const PULSE_FREQ: float = 3.0


func _ready() -> void:
	if !visible:
		return
	modulate = Color(0.2, 0.5, 1.0, 0.95)


func _physics_process(delta: float) -> void:
	if !visible:
		return
	time += delta

	if !moving:
		# Телеграф: слабо мигает чтобы игрок понял что скоро полетит
		var flicker: float = 0.75 + 0.2 * sin(time * 8.0)
		modulate.a = flicker
		return

	modulate.a = 0.95
	var t: float = (sin(time * PULSE_FREQ) + 1.0) * 0.5
	modulate = Color(lerpf(0.15, 0.75, t), lerpf(0.45, 0.1, t), 1.0, 0.95)

	position.x += speed * dir * delta

	if dir > 0.0 and position.x > 160.0:
		queue_free()
	elif dir < 0.0 and position.x < -160.0:
		queue_free()
