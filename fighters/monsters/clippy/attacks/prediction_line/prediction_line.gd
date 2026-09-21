extends Node2D
# PREDICTION_LINE — три кривые: горизонтальная, вертикальная и диагональная.
# Сначала все три мигают (с задержкой появления), потом пули по каждой.

const POINTS      := 80
const BULLETS     := 12
const BULLET_GAP  := 0.18
const PREVIEW_GAP := 0.55   # задержка между появлением каждой линии
const PREVIEW_DUR := 1.6    # сколько все вместе висят перед стрельбой

var _lines: Array[Line2D]   = []
var _paths: Array           = []  # Array[Array[Vector2]]
var _shots: Array[int]      = [0, 0, 0]
var _phase  := 0
var _timer  := 0.0
var _blink  := 0.0

func _ready() -> void:
	# Линия 1 — горизонтальная синусоида (как раньше)
	var dir1 := 1.0 if randf() > 0.5 else -1.0
	_add_line(
		_build_horizontal(dir1, randf_range(-30.0, 30.0), randf_range(12.0, 22.0), randf_range(1.5, 2.5)),
		Color(1.0, 1.0, 0.3, 0.9)
	)
	# Линия 2 — вертикальная (сверху вниз)
	_add_line(
		_build_vertical(randf_range(-55.0, 55.0), randf_range(8.0, 18.0), randf_range(1.5, 2.5)),
		Color(1.0, 0.5, 0.2, 0.9)
	)
	# Линия 3 — диагональная (угол ~35-55°)
	var dir3 := 1.0 if randf() > 0.5 else -1.0
	_add_line(
		_build_diagonal(dir3, randf_range(30.0, 55.0), randf_range(8.0, 16.0), randf_range(1.5, 2.5)),
		Color(0.4, 1.0, 0.8, 0.9)
	)
	# Сначала показываем только первую линию
	_lines[1].visible = false
	_lines[2].visible = false

func _build_horizontal(dir: float, base_y: float, amp: float, freq: float) -> Array:
	var path := []
	for i in POINTS:
		var t := float(i) / float(POINTS - 1)
		var x: float = dir * lerp(-80.0, 80.0, t)
		path.append(Vector2(x, base_y + sin(t * TAU * freq) * amp))
	return path

func _build_vertical(base_x: float, amp: float, freq: float) -> Array:
	var path := []
	for i in POINTS:
		var t := float(i) / float(POINTS - 1)
		var y: float = lerp(-75.0, 75.0, t)
		path.append(Vector2(base_x + sin(t * TAU * freq) * amp, y))
	return path

func _build_diagonal(dir: float, angle_deg: float, amp: float, freq: float) -> Array:
	var path := []
	var angle := deg_to_rad(angle_deg) * dir
	for i in POINTS:
		var t := float(i) / float(POINTS - 1)
		var dist: float = lerp(-110.0, 110.0, t)
		var base := Vector2(cos(angle), sin(angle)) * dist
		var perp  := Vector2(-sin(angle), cos(angle))
		path.append(base + perp * sin(t * TAU * freq) * amp)
	return path

func _add_line(path: Array, color: Color) -> void:
	_paths.append(path)
	var line := Line2D.new()
	line.width = 1.8
	line.default_color = color
	var pts := PackedVector2Array()
	for p in path:
		pts.append(p)
	line.points = pts
	add_child(line)
	_lines.append(line)

func _physics_process(delta: float) -> void:
	match _phase:
		0:  # появление линий с задержкой + мигание
			_timer += delta
			_blink += delta * 7.0
			var blink_a := 0.45 + sin(_blink) * 0.55
			# Показываем вторую и третью линию по таймеру
			if _timer >= PREVIEW_GAP:
				_lines[1].visible = true
			if _timer >= PREVIEW_GAP * 2.0:
				_lines[2].visible = true
			for line in _lines:
				if line.visible:
					line.modulate.a = blink_a
			if _timer >= PREVIEW_GAP * 2.0 + PREVIEW_DUR:
				for line in _lines:
					line.visible = false
				_phase = 1
				_timer = 0.0

		1:  # стреляем по всем трём с небольшим смещением
			_timer += delta
			for li in 3:
				var offset := li * BULLET_GAP * 2.5
				var idx := _shots[li]
				if idx < BULLETS and _timer >= offset + BULLET_GAP * idx:
					_fire(li)
					_shots[li] += 1

func _fire(line_idx: int) -> void:
	var p := $BaseBullet.duplicate()
	p.visible = true
	var typed_path: Array[Vector2] = []
	typed_path.assign(_paths[line_idx])
	p.path = typed_path
	p.speed = 75.0
	add_child(p)
