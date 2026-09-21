extends Pellet
class_name DisonansBurst
# Диагональная «искра» для burst-фазы атаки «Диссонанс».
# Летит в заданном направлении, постепенно увеличиваясь.

var speed:     float   = 100.0
var direction: Vector2 = Vector2.DOWN

var time:      float = 0.0
const GROW_RATE: float = 0.6   # насколько растёт со временем
const BASE_SCALE: float = 0.8


func _ready() -> void:
	if !visible:
		return
	scale = Vector2.ONE * BASE_SCALE
	modulate = Color(0.95, 0.85, 0.1, 1.0)   # жёлто-золотой — «диссонирующий» акцент


func _physics_process(delta: float) -> void:
	if !visible:
		return

	time += delta
	position += direction * speed * delta

	# Вырастает и чуть вращается
	var s: float = BASE_SCALE + GROW_RATE * time
	scale = Vector2.ONE * s
	rotation += delta * 2.5

	if position.x > 130.0 or position.x < -130.0 \
	or position.y > 100.0 or position.y < -100.0:
		queue_free()
