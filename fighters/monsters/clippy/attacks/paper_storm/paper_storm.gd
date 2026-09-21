extends Node2D
# PAPER_STORM — арена заполняется всплывающими минами.
# Попапы появляются волнами по 3-4 штуки в случайных точках.
# Между волнами пауза — успеть отойти от занятых зон.
# Мины живут ~2.2 сек и исчезают. На пике их 8-10 штук одновременно.

var wave_timer := 0.3
var wave_count := 0
const MAX_WAVES := 10
const WAVE_GAP  := 0.85

func _physics_process(delta: float) -> void:
	if wave_count >= MAX_WAVES:
		return
	wave_timer -= delta
	if wave_timer > 0.0:
		return
	wave_timer = WAVE_GAP
	_spawn_wave()
	wave_count += 1

func _spawn_wave() -> void:
	var count := 3 if wave_count < 5 else 4
	for i in count:
		var p := $BaseBullet.duplicate()
		p.visible  = true
		# Случайная точка внутри арены, отступ от краёв 12px
		p.position = Vector2(
			randf_range(-72.0, 72.0),
			randf_range(-72.0, 72.0)
		)
		add_child(p)
