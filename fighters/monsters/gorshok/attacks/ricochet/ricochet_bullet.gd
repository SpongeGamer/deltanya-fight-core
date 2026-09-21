extends Pellet
class_name RicochetBullet

var velocity: Vector2   = Vector2.ZERO
var bounce_count: int   = 0

const MAX_BOUNCES:      int   = 7
const SPEED_PER_BOUNCE: float = 1.18   # ×1.18 скорости на каждый отскок
const ARENA_X:          float = 70.0
const ARENA_Y:          float = 68.0


func _ready() -> void:
	if !visible:
		return
	modulate = Color(0.85, 0.95, 0.85, 1.0)   # бледно-зелёный — некромантия


func _physics_process(delta: float) -> void:
	if !visible:
		return

	position += velocity * delta

	# Отскок от стен
	var bounced := false
	if position.x > ARENA_X or position.x < -ARENA_X:
		velocity.x = -velocity.x
		position.x = clamp(position.x, -ARENA_X, ARENA_X)
		bounced = true
	if position.y > ARENA_Y or position.y < -ARENA_Y:
		velocity.y = -velocity.y
		position.y = clamp(position.y, -ARENA_Y, ARENA_Y)
		bounced = true

	if bounced:
		bounce_count += 1
		velocity *= SPEED_PER_BOUNCE   # ускоряемся с каждым отскоком
		if bounce_count >= MAX_BOUNCES:
			queue_free()
