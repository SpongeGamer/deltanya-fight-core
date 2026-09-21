extends Pellet
class_name TishinaGhost
# «Призрак» для атаки «Тишина».
# Медленно и неотступно преследует душу.
# Полупрозрачный, почти не заметный на тёмном фоне.
# Покачивается — движение плавное, не идеально точное.

var soul_target: Soul = null
var speed:       float = 38.0     # намеренно медленный

var life_timer:  float = 0.0
const LIFETIME:  float = 8.5      # исчезает через N секунд

# Колебание при преследовании
var wobble_time: float = 0.0
const WOBBLE_FREQ: float = 2.2
const WOBBLE_AMP:  float = 0.25   # радианы — небольшое покачивание

# Нарастающий альфа
const ALPHA_BASE:  float = 0.35
const ALPHA_PULSE: float = 0.12


func _ready() -> void:
	if !visible:
		return
	if soul_target == null:
		soul_target = get_tree().get_first_node_in_group("soul") as Soul
	# Белёсый с синим оттенком
	modulate = Color(0.7, 0.8, 1.0, ALPHA_BASE)
	scale    = Vector2.ONE * 1.4


func _physics_process(delta: float) -> void:
	if !visible:
		return

	life_timer   += delta
	wobble_time  += delta

	# Удаляемся в конце жизни
	if life_timer >= LIFETIME:
		modulate.a = lerpf(modulate.a, 0.0, delta * 3.0)
		if modulate.a < 0.02:
			queue_free()
		return

	# Медленно нарастает «заметность» — почти незаметный → чуть заметный
	var age_t: float = clampf(life_timer / 3.0, 0.0, 1.0)
	var pulse: float = ALPHA_BASE + ALPHA_PULSE * sin(wobble_time * 3.5)
	modulate.a = lerpf(ALPHA_BASE * 0.4, pulse, age_t)

	if soul_target == null:
		return

	# Направление к душе с покачиванием
	var to_soul  := (soul_target.global_position - global_position).normalized()
	var wobble   := to_soul.rotated(sin(wobble_time * WOBBLE_FREQ) * WOBBLE_AMP)
	position     += wobble * speed * delta

	# Медленно растёт
	var s: float = 1.4 + 0.3 * sin(wobble_time * 1.8)
	scale = Vector2.ONE * s

	if position.x > 130.0 or position.x < -130.0 \
	or position.y > 105.0 or position.y < -105.0:
		queue_free()
