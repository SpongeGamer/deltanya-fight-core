extends Node2D

const RINGS       := 4       # 4 кольца вместо 5
const PER_RING    := 8       # 8 снарядов вместо 12 — проходы стали намного шире
const RING_GAP    := 0.85    # Увеличили паузу между волнами (было 0.55)
const BASE_SPEED  := 35.0    # Начальная скорость ниже (было 55)
const SPEED_STEP  := 10.0    # Прирост скорости в два раза меньше (было 18)

var _ring_timer : float = 0.5
var _ring_index : int   = 0

func _physics_process(delta: float) -> void:
	if _ring_index >= RINGS: return
	_ring_timer -= delta
	if _ring_timer <= 0.0:
		_ring_timer = RING_GAP
		_spawn_ring(_ring_index)
		_ring_index += 1

func _spawn_ring(idx: int) -> void:
	var spd := BASE_SPEED + SPEED_STEP * idx
	# Каждое кольцо немного повернуто относительно предыдущего
	var rot_offset := (idx * PI / 4.0) 

	for i in PER_RING:
		var angle := (TAU / PER_RING) * i + rot_offset
		var p     := $BaseBullet.duplicate()
		p.visible   = true
		p.position  = Vector2.ZERO
		p.direction = Vector2(cos(angle), sin(angle))
		p.speed     = spd # Скорость нарастает плавно
		add_child(p)
