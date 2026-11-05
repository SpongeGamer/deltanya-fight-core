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
		# Не ставим новую мину прямо на игрока.
		var soul := get_tree().get_first_node_in_group("soul") as Node2D
		var soul_pos := to_local(soul.global_position) if soul else Vector2.ZERO
		var best := Vector2.ZERO
		var best_distance := -1.0
		for attempt in 16:
			var candidate := Vector2(randf_range(-65.0, 65.0), randf_range(-65.0, 65.0))
			var distance := candidate.distance_to(soul_pos)
			if distance > best_distance:
				best = candidate
				best_distance = distance
			if distance >= 32.0:
				break
		p.position = best
		add_child(p)
