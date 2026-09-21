extends Node2D
# CLIPBOARD_RAIN — три луча-сканера на разных высотах.
# Каждый луч движется туда-обратно, с каждым проходом быстрее.
# Луч широкий (покрывает ~1/3 высоты арены) — нужно держаться в узком проходе.
# Три луча на разных Y → проход между ними постоянно меняется.

# Три активных луча
var beams: Array = []
var speeds: Array[float] = [70.0, 85.0, 100.0]
var beam_ys: Array[float] = [-50.0, 0.0, 50.0]
var directions: Array[float] = [1.0, -1.0, 1.0]
var started := false

func _ready() -> void:
	# Небольшая пауза перед стартом
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree():
		return
	_spawn_all_beams()
	started = true

func _spawn_all_beams() -> void:
	for i in 3:
		var b := $BaseBullet.duplicate()
		b.visible   = true
		b.direction = directions[i]
		b.speed     = speeds[i]
		b.position  = Vector2(-78.0 * directions[i], beam_ys[i])
		add_child(b)
		beams.append(b)

func _physics_process(delta: float) -> void:
	if not started:
		return
	for i in beams.size():
		var b = beams[i]
		if not is_instance_valid(b):
			continue
		# Разворот на краях арены + ускорение
		if b.position.x > 78.0:
			b.direction = -1.0
			b.speed     = minf(b.speed + 12.0, 220.0)
		elif b.position.x < -78.0:
			b.direction = 1.0
			b.speed     = minf(b.speed + 12.0, 220.0)
