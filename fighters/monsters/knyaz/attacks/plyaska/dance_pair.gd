extends Pellet
class_name DancePair

# is_leader = true  → этот снаряд управляет движением пары
# is_leader = false → позицию выставляет лидер, сам ничего не делает
var is_leader: bool = true

# ── параметры пары (только у лидера) ────────────────────────────────────────
var center: Vector2     = Vector2.ZERO
var orbit_radius: float = 22.0
var angle: float        = 0.0
var angular_speed: float= 2.8

var travel_dir: Vector2 = Vector2.ZERO
var travel_speed: float = 46.0

var lifetime: float     = 0.0
const MAX_LIFE: float   = 8.0

var bullet_b: Area2D    = null

const ARENA_X: float = 78.0
const ARENA_Y: float = 56.0


func _ready() -> void:
	if !visible:
		return
	if is_leader:
		# Золотой — яркий, читается на чёрном
		modulate = Color(1.0, 0.85, 0.05, 1.0)
	else:
		# Ярко-зелёный — контрастный, явно видно пару
		modulate = Color(0.05, 1.0, 0.4, 1.0)


func _physics_process(delta: float) -> void:
	if !visible or !is_leader:
		return

	lifetime += delta
	if lifetime >= MAX_LIFE:
		_remove_pair()
		return

	center += travel_dir * travel_speed * delta

	if center.x < -ARENA_X or center.x > ARENA_X:
		travel_dir.x = -travel_dir.x
		center.x = clamp(center.x, -ARENA_X, ARENA_X)
	if center.y < -ARENA_Y or center.y > ARENA_Y:
		travel_dir.y = -travel_dir.y
		center.y = clamp(center.y, -ARENA_Y, ARENA_Y)

	angle += angular_speed * delta

	var offset := Vector2(cos(angle), sin(angle)) * orbit_radius
	position = center + offset

	if bullet_b != null and is_instance_valid(bullet_b):
		bullet_b.position = center - offset


func _remove_pair() -> void:
	if bullet_b != null and is_instance_valid(bullet_b):
		bullet_b.queue_free()
	queue_free()
