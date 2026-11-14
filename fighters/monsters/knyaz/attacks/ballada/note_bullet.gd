extends Pellet
class_name NoteBullet

const NOTE := preload("res://fighters/monsters/knyaz/attacks/ballada/res/note_theater.png")

var velocity := 110.4
var direction := Vector2.RIGHT
var is_false := false
var soul_target: Soul
var life_timer := 0.0
var aimed := false

func _ready() -> void:
	if not visible:
		return
	var sprite := $Sprite as Sprite2D
	sprite.scale = Vector2(1.9, 1.9)
	var hitbox := $CollisionShape2D as CollisionShape2D
	hitbox.scale = Vector2(1.25, 1.25)
	# Обычные ноты не синие: у них нет правила «стой».
	if is_false:
		modulate = Color(1.0, 0.37, 0.25)
	else:
		($Sprite as Sprite2D).texture = NOTE
		modulate = Color.WHITE

func _physics_process(delta: float) -> void:
	if not visible:
		return
	life_timer += delta
	if is_false and not aimed:
		modulate.a = 0.65 + 0.35 * abs(sin(life_timer * 12.0))
		if life_timer >= 0.7:
			aimed = true
			modulate.a = 1.0
			if is_instance_valid(soul_target):
				direction = (soul_target.global_position - global_position).normalized()
			velocity = 174.0
	position += direction * velocity * delta
	if absf(position.x) > 125.0 or absf(position.y) > 100.0:
		queue_free()
