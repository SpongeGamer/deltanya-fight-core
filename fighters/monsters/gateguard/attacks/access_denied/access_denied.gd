extends Node2D
# ACCESS DENIED
# Таблички появляются у края и на 0.25с ЗАМИРАЮТ — игрок видит паттерн и двигается.
# 3 знака из 5 рядов заняты, 2 свободны. Свободные ряды меняются каждую волну.
# Важно: знаки чередуют сторону. Смотришь откуда летит — идёшь в свободный ряд.

const ROW_YS    : Array[float] = [-56.0, -28.0, 0.0, 28.0, 56.0]
const SPEED     : float        = 95.0     # достаточно быстро чтобы надо было думать
const PAUSE_T   : float        = 0.3      # пауза "прочитай паттерн"
const MAX_WAVES : int          = 8

var wave_timer  : float = 0.4
var wave_index  : int   = 0
var _from_right : bool  = true

func _physics_process(delta: float) -> void:
	if wave_index >= MAX_WAVES:
		return
	wave_timer -= delta
	if wave_timer > 0.0:
		return
	# Следующая волна после того как текущая ушла + запас
	wave_timer = PAUSE_T + (160.0 / SPEED) + 0.3
	wave_index += 1
	_do_wave()

func _do_wave() -> void:
	# 2 случайных безопасных ряда — остальные 3 заняты
	var gaps : Array[int] = []
	while gaps.size() < 2:
		var idx : int = randi() % ROW_YS.size()
		if idx not in gaps:
			gaps.append(idx)

	var start_x : float = 72.0 if _from_right else -72.0
	var vel_x   : float = -SPEED if _from_right else SPEED
	_from_right = !_from_right

	var signs : Array[Node2D] = []
	for i in ROW_YS.size():
		if i in gaps:
			continue
		var b : Node2D = $BaseBullet.duplicate()
		b.visible  = true
		b.position = Vector2(start_x, ROW_YS[i])
		b.vel      = Vector2.ZERO   # пока стоит на месте
		var col := b.get_node_or_null("CollisionShape2D")
		if col:
			col.disabled = true   # пока не активен
		add_child(b)
		signs.append(b)

	_pause_then_fly(signs, vel_x)

func _pause_then_fly(signs: Array[Node2D], vel_x: float) -> void:
	# Замереть на PAUSE_T — игрок читает паттерн
	await get_tree().create_timer(PAUSE_T).timeout
	for s in signs:
		if not is_instance_valid(s):
			continue
		s.vel = Vector2(vel_x, 0.0)
		var col := s.get_node_or_null("CollisionShape2D")
		if col:
			col.disabled = false
