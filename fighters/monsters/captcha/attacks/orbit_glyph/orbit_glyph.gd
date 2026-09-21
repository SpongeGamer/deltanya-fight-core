extends Node2D
# ORBIT_GLYPH
# 5 глифов вращаются по круговой орбите вокруг центра арены.
# Каждые EJECT_INTERVAL секунд один срывается и летит хомингом к soul.
# После срыва на его место через паузу спавнится новый орбитер.
# Скорость орбиты нарастает с каждым срывом.

const ORBIT_R     := 60.0
const COUNT       := 5
const EJECT_INTERVAL := 1.6
const MAX_EJECTIONS  := 7

var _orbiters    : Array  = []
var _angles      : Array  = []
var _angular_spd := 1.6   # рад/сек

var _eject_timer  := 1.0   # небольшая пауза перед первым срывом
var _eject_count  := 0
var _next_eject   := 0


func _ready() -> void:
	for i in COUNT:
		var angle := (TAU / COUNT) * i
		_spawn_orbiter(i, angle)


func _spawn_orbiter(slot: int, angle: float) -> void:
	while _orbiters.size() <= slot:
		_orbiters.append(null)
		_angles.append(0.0)

	var p := $BaseBullet.duplicate()
	p.visible  = true
	p.orbiting = true
	p.position = _orbit_pos(angle)
	add_child(p)
	_orbiters[slot]     = p
	_angles[slot]       = angle


func _orbit_pos(a: float) -> Vector2:
	return Vector2(cos(a) * ORBIT_R, sin(a) * ORBIT_R)


func _physics_process(delta: float) -> void:
	_angular_spd = min(_angular_spd + delta * 0.06, 3.2)

	for i in _orbiters.size():
		var p = _orbiters[i]
		if p == null or !is_instance_valid(p):
			continue
		if p.orbiting:
			_angles[i]  += _angular_spd * delta
			p.position   = _orbit_pos(_angles[i])

	if _eject_count >= MAX_EJECTIONS:
		return
	_eject_timer -= delta
	if _eject_timer > 0.0:
		return
	_eject_timer = EJECT_INTERVAL

	# Ищем живого орбитера
	for attempt in COUNT:
		var idx := (_next_eject + attempt) % COUNT
		var p   = _orbiters[idx]
		if p != null and is_instance_valid(p) and p.orbiting:
			_do_eject(idx)
			_next_eject = (idx + 1) % COUNT
			_eject_count += 1
			_angular_spd = min(_angular_spd + 0.2, 3.2)
			break


func _do_eject(idx: int) -> void:
	var p = _orbiters[idx]
	p.orbiting   = false
	p.turn_speed = 2.2
	p.velocity   = 100.0
	# Направление — от орбиты к soul (или к центру если soul не найден)
	var soul : Node2D = get_parent().get_node_or_null("Soul")
	var target := Vector2.ZERO
	if soul:
		target = soul.position
	p.direction = (target - p.position).normalized()
