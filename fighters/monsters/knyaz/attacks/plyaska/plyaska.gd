extends Node2D
# «Пляска смерти» — атака Князя.

var spawn_timer: float  = 0.0
var wave: int           = 0
const MAX_WAVES: int    = 3
const PAIRS_PER_WAVE: int = 2     # 2 пары за раз — читаемо
var pairs_this_wave: int = 0

const WAVE_INTERVAL: float  = 2.0
const SPAWN_INTERVAL: float = 0.5

var done: bool = false


func _physics_process(delta: float) -> void:
	if done:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_pair()
		pairs_this_wave += 1

		if pairs_this_wave >= PAIRS_PER_WAVE:
			pairs_this_wave = 0
			wave += 1
			if wave >= MAX_WAVES:
				done = true
				return
			spawn_timer = WAVE_INTERVAL
		else:
			spawn_timer = SPAWN_INTERVAL


func _spawn_pair() -> void:
	var pair_a := $BaseBulletA.duplicate() as DancePair
	var pair_b := $BaseBulletB.duplicate() as DancePair

	pair_a.visible = true
	pair_b.visible = true

	# pair_b — ведомый: только получает позицию от лидера
	pair_b.is_leader = false

	# ── стартовая позиция центра пары у края арены ──────────────────────────
	var edge := randi() % 4
	var cx: float
	var cy: float
	match edge:
		0: cx = -65.0; cy = randf_range(-40.0, 40.0)
		1: cx =  65.0; cy = randf_range(-40.0, 40.0)
		2: cx = randf_range(-55.0, 55.0); cy = -45.0
		3: cx = randf_range(-55.0, 55.0); cy =  45.0

	var target := Vector2(randf_range(-30.0, 30.0), randf_range(-20.0, 20.0))
	var dir    := (target - Vector2(cx, cy)).normalized()

	var spin_sign: float = 1.0 if wave % 2 == 0 else -1.0
	var radius: float    = randf_range(20.0, 28.0)
	var speed: float     = randf_range(2.0, 2.8) * spin_sign
	var start_angle: float = randf_range(0.0, TAU)

	pair_a.center        = Vector2(cx, cy)
	pair_a.orbit_radius  = radius
	pair_a.angle         = start_angle
	pair_a.angular_speed = speed
	pair_a.travel_dir    = dir
	pair_a.travel_speed  = randf_range(32.0, 50.0)
	pair_a.bullet_b      = pair_b

	pair_a.position = Vector2(cx, cy) + Vector2(cos(start_angle), sin(start_angle)) * radius
	pair_b.position = Vector2(cx, cy) - Vector2(cos(start_angle), sin(start_angle)) * radius

	add_child(pair_a)
	add_child(pair_b)
