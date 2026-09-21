extends Node2D

var wave_timer := 0.2
var row := 0
const MAX_ROWS := 10

const ROWS_Y     := [-45.0, -15.0, 15.0, 45.0]
const DIRECTIONS := [1.0, -1.0, 1.0, -1.0]
const AMPLITUDES := [14.0, 20.0, 10.0, 22.0]
const PHASES     := [0.0, 1.1, 2.2, 0.6]

func _physics_process(delta: float) -> void:
	if row >= MAX_ROWS:
		return
	wave_timer -= delta
	if wave_timer > 0.0:
		return
	wave_timer = 0.78
	_spawn_row(row % ROWS_Y.size())
	row += 1

func _spawn_row(idx: int) -> void:
	var dir:       float = DIRECTIONS[idx]
	var start_x:   float = -82.0 if dir > 0.0 else 82.0
	var amplitude: float = AMPLITUDES[idx]
	var phase:     float = PHASES[idx]
	var row_y:     float = ROWS_Y[idx]

	var p := $BaseBullet.duplicate()
	p.visible   = true
	p.position  = Vector2(start_x, row_y)
	p.direction = dir
	p.amplitude = amplitude
	p.frequency = 3.0 + idx * 0.4
	p.phase     = phase
	p.speed     = 115.0
	add_child(p)
