extends Node2D

const ARMS := 8
const BULLETS_PER_WAVE := 3
const WAVE_COUNT := 3
const BULLET_GAP := 0.25     # Пауза между пулями внутри одной волны
const WAVE_DELAY := 1.2      # Реальный промежуток между волнами (тишина)
const PREVIEW_DUR := 1.4     #
const ARM_LEN := 88.0        

const ROT_AMPLITUDE := 1.4   
const ROT_FREQUENCY := 0.6   # Медленный маятник

var _lines : Array[Line2D] = []
var _dirs : Array[Vector2] = []
var _phase := 0              # 0=Preview, 1=Active
var _timer := 0.0
var _wave_timer := 0.0
var _current_wave := 0
var _bullets_fired_in_wave := 0

func _ready() -> void:
	for i in ARMS:
		var angle := (TAU / ARMS) * i
		var dir := Vector2.RIGHT.rotated(angle)
		_dirs.append(dir)
		
		var line := Line2D.new()
		line.width = 1.5
		line.default_color = Color(0.3, 1.0, 0.6, 0.6)
		line.points = PackedVector2Array([Vector2.ZERO, dir * ARM_LEN])
		add_child(line)
		_lines.append(line)

func _physics_process(delta: float) -> void:
	_timer += delta
	var current_rot = sin(_timer * ROT_FREQUENCY) * ROT_AMPLITUDE
	
	for i in ARMS:
		var base_angle = (TAU / ARMS) * i
		_dirs[i] = Vector2.RIGHT.rotated(base_angle + current_rot)
		_lines[i].points = PackedVector2Array([Vector2.ZERO, _dirs[i] * ARM_LEN])

	if _phase == 0:
		var a := 0.3 + sin(_timer * 10.0) * 0.7
		for line in _lines:
			line.modulate.a = a
		if _timer >= PREVIEW_DUR:
			for line in _lines: line.visible = false
			_phase = 1
			_timer = 0.0
			_wave_timer = 0.0
	elif _phase == 1:
		_process_logic(delta)

func _process_logic(delta: float) -> void:
	if _current_wave >= WAVE_COUNT:
		return

	_wave_timer += delta

	# Проверяем, идет ли сейчас стрельба или мы в паузе между волнами
	var time_for_one_wave = BULLETS_PER_WAVE * BULLET_GAP
	
	if _wave_timer < time_for_one_wave:
		# ФАЗА СТРЕЛЬБЫ
		var target_bullet_count = int(_wave_timer / BULLET_GAP) + 1
		if _bullets_fired_in_wave < target_bullet_count and _bullets_fired_in_wave < BULLETS_PER_WAVE:
			_fire_all_arms()
			_bullets_fired_in_wave += 1
	elif _wave_timer >= time_for_one_wave + WAVE_DELAY:
		# ФАЗА ПАУЗЫ ЗАКОНЧЕНА -> Переход к следующей волне
		_current_wave += 1
		_wave_timer = 0.0
		_bullets_fired_in_wave = 0

func _fire_all_arms() -> void:
	for i in ARMS:
		var p = $BaseBullet.duplicate()
		p.visible = true
		p.position = Vector2.ZERO
		p.direction = _dirs[i]
		p.speed = 80.0 # Медленно и понятно
		add_child(p)
