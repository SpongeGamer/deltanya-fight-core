extends Node2D

const ATTACK_FIELD := preload("res://fighters/monsters/nikita/attacks/common/attack_field.gd")
var _projectiles: Node2D
## Четыре задания: порядок виден с самого начала. Каждая отметка
## раскрывается в кольцо осколков мела; у мини есть дополнительное задание.

const PELLET := preload("res://pellets/generic_pellet/generic_pellet.tscn")
const GOLD := Color("f4d083")
const CHALK := Color("f9f2df")
var phase2_mode := false
var mini_extra := false
var _places: Array[Vector2] = []
var _current := -1
var _age := 0.0
var _burst_age := 99.0
var _burst_pos := Vector2.ZERO

func _ready() -> void:
	_projectiles = ATTACK_FIELD.make(self)
	_places = [Vector2(-35, -35), Vector2(35, -35), Vector2(35, 35), Vector2(-35, 35)]
	_places.shuffle()
	if mini_extra:
		_places.append(Vector2.ZERO)
	call_deferred("_run")

func get_duration() -> float:
	return 2.0 + (5 if mini_extra else 4) * 1.05 + 1.9

func _run() -> void:
	await _wait(2.0)
	for i in _places.size():
		_current = i
		_burst_age = 0.0
		_burst_pos = _places[i]
		_burst(_burst_pos, i == 4)
		Sounds.play("snd_impact", 0.35 if i == 4 else 0.55)
		await _wait(1.05)

func _wait(duration: float) -> Signal:
	var timer := Timer.new()
	timer.one_shot = true
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(timer)
	timer.timeout.connect(timer.queue_free)
	timer.start(duration)
	return timer.timeout

func _burst(pos: Vector2, small: bool) -> void:
	var offset := PI / 8.0 if _current % 2 == 0 else 0.0
	var count := 6 if small else 8
	for i in count:
		var d := Vector2.RIGHT.rotated(offset + TAU * i / count)
		var p := PELLET.instantiate() as GenericPellet
		p.position = pos + d * 6.0
		p.velocity = d * (48.0 if small else 60.0)
		p.life_time = 1.45
		p.damage = 6 if small else 8
		p.graze_points = 2
		p.time_points = 0.04
		p.get_node("Sprite").modulate = Color(1.0, 0.8, 0.52)
		p.body_entered.connect(p._on_body_entered)
		_projectiles.add_child(p)

func _process(delta: float) -> void:
	_age += delta
	_burst_age += delta
	queue_redraw()

func _draw() -> void:
	# Номера остаются видны до своего удара; пятый — отдельное задание мини.
	for i in _places.size():
		if i <= _current:
			continue
		var p := _places[i]
		var active := i == _current + 1
		var alpha := (0.75 if active else 0.4) * (0.85 + 0.15 * sin(_age * 5.0))
		var col := Color(GOLD if i != 4 else Color("ff967c"), alpha)
		draw_circle(p, 15.0, Color(col, 0.08))
		draw_arc(p, 15.0, 0.0, TAU, 32, col, 1.5)
		for k in 4:
			var v := Vector2.RIGHT.rotated(k * PI / 2)
			draw_line(p + v * 17, p + v * 20, col, 1.5)
		_draw_number(p, i + 1, col)
	if _burst_age < 0.45:
		var a := 1.0 - _burst_age / 0.45
		var radius := 5.0 + _burst_age * 80.0
		draw_arc(_burst_pos, radius, 0.0, TAU, 32, Color(CHALK, a * 0.8), 2.0)
		for i in 8:
			var d := Vector2.RIGHT.rotated(i * TAU / 8)
			draw_line(_burst_pos + d * radius, _burst_pos + d * (radius + 3), Color(GOLD, a), 1.0)

func _draw_number(p: Vector2, n: int, color: Color) -> void:
	# Пиксельные цифры не зависят от шрифта проекта.
	var patterns := {1: ["010", "110", "010", "010", "111"], 2: ["110", "001", "010", "100", "111"], 3: ["110", "001", "010", "001", "110"], 4: ["101", "101", "111", "001", "001"], 5: ["111", "100", "110", "001", "110"]}
	var rows: Array = patterns[n]
	for y in rows.size():
		for x in 3:
			if rows[y][x] == "1":
				draw_rect(Rect2(p + Vector2((x - 1.5) * 2, (y - 2.5) * 2), Vector2(2, 2)), color)
