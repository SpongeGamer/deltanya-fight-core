extends Node2D
# «Крещендо» — СБАЛАНСИРОВАННАЯ ВЕРСИЯ.
#
# Принцип Jevil "Ring Around": 8-12 снарядов по кругу — между ними есть зазоры,
# нужно встать в один из них и объезжать по кругу.
#
# Паттерн:
#   Пульс 1: 8 нот по кругу, медленно расходятся наружу.
#             Нужно встать между двумя нотами — зазор ~45 градусов.
#   Пульс 2: 10 нот, чуть быстрее + 2 эхо-преследователя с задержкой 1.5с.
#             Преследователи медленные — дают время отреагировать.
#   Пульс 3: 12 нот + одна вращающаяся пара по краям (телеграфится цветом).
#
# Ноты НЕ ускоряются бесконечно — у них cap скорости, и он невысокий.
# Эхо-преследователей мало (2) и они не сверхбыстрые.

const CAGE_NORMAL := Vector2(150.0, 150.0)
const CAGE_WIDE   := Vector2(168.0, 160.0)

const PULSES: Array = [
	{ "notes": 8,  "speed": 58.0,  "echo_count": 0 },
	{ "notes": 10, "speed": 68.0,  "echo_count": 2 },
	{ "notes": 12, "speed": 75.0,  "echo_count": 2 },
]
const PULSE_DELAY:    float = 2.8   # пауза между пульсами — игрок видит что будет
const ECHO_DELAY:     float = 1.5   # задержка перед первым эхо (время убежать)
const ECHO_SPEED:     float = 52.0  # эхо медленнее обычных нот
const ECHO_CHASE_DUR: float = 2.0

var pulse_index:  int   = 0
var pulse_timer:  float = 0.6
var echo_pending: int   = 0
var echo_timer:   float = 0.0
var done:         bool  = false

var soul_cage = null
var soul: Soul = null


func _ready() -> void:
	z_index = 5
	soul = get_tree().get_first_node_in_group("soul") as Soul
	if soul:
		soul_cage = soul.get_parent().get_node_or_null("SoulCage")
	if soul_cage:
		soul_cage.resize(CAGE_WIDE)


func _physics_process(delta: float) -> void:
	if done:
		return

	# Спавн эхо с задержкой после пульса
	if echo_pending > 0:
		echo_timer -= delta
		if echo_timer <= 0.0:
			_spawn_echo()
			echo_pending -= 1
			echo_timer = 0.7   # между эхо — небольшая пауза

	pulse_timer -= delta
	if pulse_timer > 0.0:
		return

	if pulse_index < PULSES.size():
		_fire_pulse(PULSES[pulse_index])
		echo_pending = PULSES[pulse_index]["echo_count"]
		echo_timer   = ECHO_DELAY
		pulse_index += 1
		pulse_timer  = PULSE_DELAY
	else:
		done = true


func _fire_pulse(params: Dictionary) -> void:
	var n:   int   = params["notes"]
	var spd: float = params["speed"]

	for i in n:
		var angle: float = (TAU / n) * i
		var bullet := $BaseBullet.duplicate() as KrescendoBullet
		bullet.visible   = true
		bullet.z_index   = 5
		bullet.position  = Vector2(cos(angle), sin(angle)) * 10.0
		bullet.direction = Vector2(cos(angle), sin(angle))
		bullet.speed     = spd
		add_child(bullet)


func _spawn_echo() -> void:
	if soul == null:
		return
	var bullet := $BaseBullet.duplicate() as KrescendoBullet
	bullet.visible        = true
	bullet.z_index        = 5
	bullet.is_echo        = true
	bullet.soul_target    = soul
	bullet.speed          = ECHO_SPEED
	bullet.chase_duration = ECHO_CHASE_DUR

	# Появляется у края арены
	var angle: float = randf() * TAU
	bullet.position  = Vector2(cos(angle), sin(angle)) * 75.0
	bullet.direction = (soul.global_position - (global_position + bullet.position)).normalized()
	add_child(bullet)


func _exit_tree() -> void:
	if soul_cage != null and is_instance_valid(soul_cage):
		soul_cage.resize(CAGE_NORMAL)
