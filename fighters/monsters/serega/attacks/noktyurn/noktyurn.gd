extends Node2D
# «Ноктюрн» — атака Тёмного Серёги. СБАЛАНСИРОВАННАЯ ВЕРСИЯ.
#
# Паттерн: 3 волны нот сверху.
# Волна 1: 6 нот, медленно, широкие зазоры — учебная
# Волна 2: 8 нот, чуть быстрее, зазоры чуть уже
# Волна 3: 10 нот, быстрее, но ВСЕГДА есть минимум 2 гарантированных зазора
#
# Ключевой принцип: ноты спавнятся с фиксированным шагом по X,
# не в полностью случайных позициях — игрок видит паттерн и знает куда идти.
# Фальшивая нота (1 штука) появляется только в 3-й волне, даётся 1 секунда
# до начала погони — достаточно чтобы сдвинуться в сторону.

const CAGE_NORMAL := Vector2(150.0, 150.0)
const CAGE_WIDE   := Vector2(160.0, 155.0)

# Каждая волна: количество нот, скорость падения, интервал между нотами
const WAVE_DEFS: Array = [
	{ "count": 6,  "speed": 52.0,  "interval": 0.70, "has_false": false },
	{ "count": 8,  "speed": 65.0,  "interval": 0.55, "has_false": false },
	{ "count": 10, "speed": 78.0,  "interval": 0.45, "has_false": true  },
]
const PAUSE_BETWEEN_WAVES: float = 1.4

# Ноты распределяются по равномерной сетке с небольшим jitter'ом —
# гарантирует зазоры между ними
const ARENA_HALF_X: float = 62.0   # половина ширины арены где спавнятся ноты

var current_wave:    int   = 0
var notes_in_wave:   int   = 0
var spawn_timer:     float = 0.4
var pause_timer:     float = 0.0
var in_pause:        bool  = false
var done:            bool  = false
var false_spawned:   bool  = false

# Позиции X для текущей волны — вычисляются заранее
var wave_x_positions: Array[float] = []

var soul_cage = null


func _ready() -> void:
	z_index = 5
	var soul := get_tree().get_first_node_in_group("soul") as Soul
	if soul:
		soul_cage = soul.get_parent().get_node_or_null("SoulCage")
	if soul_cage:
		soul_cage.resize(CAGE_WIDE)
	_prepare_wave(0)


func _prepare_wave(wave_idx: int) -> void:
	# Делаем равномерную сетку X-позиций с небольшим случайным сдвигом
	# Это гарантирует что между нотами всегда есть проход
	var n: int = WAVE_DEFS[wave_idx]["count"]
	wave_x_positions.clear()
	var step: float = (ARENA_HALF_X * 2.0) / (n + 1)
	for i in n:
		var base_x: float = -ARENA_HALF_X + step * (i + 1)
		# Jitter не более 30% от шага — чтобы не слипались
		var jitter: float = randf_range(-step * 0.3, step * 0.3)
		wave_x_positions.append(base_x + jitter)
	# Перемешиваем порядок спавна чтобы не было скучного левой-правой
	wave_x_positions.shuffle()


func _physics_process(delta: float) -> void:
	if done:
		return

	if in_pause:
		pause_timer -= delta
		if pause_timer <= 0.0:
			in_pause = false
			current_wave += 1
			if current_wave >= WAVE_DEFS.size():
				done = true
				return
			false_spawned = false
			_prepare_wave(current_wave)
			notes_in_wave = 0
			spawn_timer = 0.2
		return

	var wave: Dictionary = WAVE_DEFS[current_wave]
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = wave["interval"]
		_spawn_note(wave)
		notes_in_wave += 1
		if notes_in_wave >= wave["count"]:
			in_pause = true
			pause_timer = PAUSE_BETWEEN_WAVES


func _spawn_note(wave: Dictionary) -> void:
	var bullet := $BaseBullet.duplicate() as NoktyurnBullet
	bullet.visible = true

	var x_pos: float = wave_x_positions[notes_in_wave % wave_x_positions.size()]
	bullet.position   = Vector2(x_pos, -82.0)
	bullet.fall_speed = wave["speed"] + randf_range(-5.0, 5.0)
	bullet.drift      = randf_range(-8.0, 8.0)  # минимальный снос

	# Одна фальшивая нота только в последней волне
	var can_false: bool = wave["has_false"] and not false_spawned
	# Спавним фальшивую на середине волны (не сразу)
	if can_false and notes_in_wave == wave["count"] / 2:
		bullet.is_false    = true
		bullet.chase_duration = 1.5   # преследует недолго
		false_spawned = true

	add_child(bullet)


func _exit_tree() -> void:
	if soul_cage != null and is_instance_valid(soul_cage):
		soul_cage.resize(CAGE_NORMAL)
