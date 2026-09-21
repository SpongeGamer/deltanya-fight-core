extends Node2D
# «Рикошет» — атака Горшка.
# Черепа-снаряды отскакивают от стен, набирая скорость.

const SPAWN_COUNT:    int   = 5     # снарядов за атаку
const SPAWN_INTERVAL: float = 0.7   # секунд между спавнами
const BASE_SPEED:     float = 75.0
const SPEED_VARIANCE: float = 25.0  # ±рандом к скорости

var spawned:      int   = 0
var spawn_timer:  float = 0.2       # первый снаряд чуть сразу
var done:         bool  = false


func _physics_process(delta: float) -> void:
	if done:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_bullet()
		spawned += 1
		spawn_timer = SPAWN_INTERVAL
		if spawned >= SPAWN_COUNT:
			done = true


func _spawn_bullet() -> void:
	var bullet := $BaseBullet.duplicate() as RicochetBullet
	bullet.visible = true

	# Спавним у края арены в случайной точке
	var edge := randi() % 4
	match edge:
		0: bullet.position = Vector2(randf_range(-65.0, 65.0), -65.0)   # сверху
		1: bullet.position = Vector2(randf_range(-65.0, 65.0),  65.0)   # снизу
		2: bullet.position = Vector2(-65.0, randf_range(-60.0, 60.0))   # слева
		3: bullet.position = Vector2( 65.0, randf_range(-60.0, 60.0))   # справа

	# Направление — в сторону центра с небольшим случайным сдвигом
	var to_center := (-bullet.position).normalized()
	var spread    := Vector2(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4))
	var speed     := BASE_SPEED + randf_range(-SPEED_VARIANCE, SPEED_VARIANCE)
	bullet.velocity = (to_center + spread).normalized() * speed

	add_child(bullet)
