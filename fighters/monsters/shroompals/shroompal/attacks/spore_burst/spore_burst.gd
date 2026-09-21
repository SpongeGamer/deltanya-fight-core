extends Node2D

const DRIFT_COUNT  := 5      # Меньше мусора на экране
const BURST_COUNT  := 12     # 12 пуль вместо 24 — теперь между ними огромные дыры
const CHARGE_DUR   := 3.0    # Чуть больше времени на подготовку

var _phase     := 0          
var _timer     := 0.0
var _drifters  : Array = []
var _burst_done := false

func _ready() -> void:
	for i in DRIFT_COUNT:
		var p      := $BaseBullet.duplicate()
		p.visible   = true
		var angle  := randf_range(0.0, TAU)
		# Уменьшили радиус спавна, чтобы споры были видны
		p.position  = Vector2(cos(angle), sin(angle)) * 60.0 
		p.direction = Vector2(cos(angle + PI), sin(angle + PI))
		p.speed     = 20.0   # Очень медленный дрейф
		add_child(p)
		_drifters.append(p)

func _physics_process(delta: float) -> void:
	if _burst_done: return
	_timer += delta

	if _phase == 0:
		# ЗА ПОЛСЕКУНДЫ ДО ВЗРЫВА: споры замирают и мигают
		if _timer >= CHARGE_DUR - 0.5:
			for p in _drifters: 
				if is_instance_valid(p): p.speed = 0.0 
		
		if _timer >= CHARGE_DUR:
			_phase = 1
			_do_burst()

func _do_burst() -> void:
	_burst_done = true
	for p in _drifters:
		if is_instance_valid(p): p.queue_free()

	for i in BURST_COUNT:
		var angle := (TAU / BURST_COUNT) * i
		var p     := $BaseBullet.duplicate()
		p.visible   = true
		p.position  = Vector2.ZERO
		p.direction = Vector2(cos(angle), sin(angle))
		# Снизили скорость со 105 до 65 — теперь это реально объехать
		p.speed     = 65.0   
		add_child(p)
