extends Node2D

var spawn_timer: float = 0.25
var notes_spawned: int = 0
var false_notes_spawned: int = 0  # сколько фальшивых уже на арене/было спавнено

const MAX_NOTES: int    = 24
const FALSE_CHANCE: float = 0.5

# ── настройки преследования ──────────────────────────────────────────────────
const MAX_FALSE_NOTES: int  = 3    # не более N фальшивых за всю атаку
const CHASE_DURATION: float = 1.8  # секунд активного преследования (потом летит прямо)


func _physics_process(delta: float) -> void:
	if notes_spawned >= MAX_NOTES:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(0.45, 0.85)
		_spawn_note()
		notes_spawned += 1


func _spawn_note() -> void:
	var bullet := $BaseBullet.duplicate() as NoteBullet
	bullet.visible = true

	var from_left: bool = randf() > 0.5
	bullet.position = Vector2(
		-82.0 if from_left else 82.0,
		randf_range(-52.0, 52.0)
	)
	bullet.direction = Vector2(
		1.0 if from_left else -1.0,
		randf_range(-0.12, 0.12)
	).normalized()
	bullet.velocity = randf_range(48.0, 68.0)

	# Фальшивая только если не исчерпан лимит
	var can_be_false: bool = false_notes_spawned < MAX_FALSE_NOTES
	bullet.is_false = can_be_false and randf() < FALSE_CHANCE
	if bullet.is_false:
		false_notes_spawned += 1
		bullet.chase_duration = CHASE_DURATION

	add_child(bullet)
