extends Pellet
# Синус-снаряд: летит горизонтально, Y колеблется синусоидально.
# Параметры задаются при спавне через exported vars.

var speed      := 130.0
var direction  := 1.0      # +1 = вправо, -1 = влево
var base_y     := 0.0      # Y-позиция центра синуса
var amplitude  := 18.0     # высота волны
var frequency  := 2.5     # частота (рад/сек)
var phase      := 0.0      # сдвиг фазы
var moving     := false
var age        := 0.1

func _ready() -> void:
	if !visible:
		return
	base_y  = position.y
	moving  = true

func _physics_process(delta: float) -> void:
	if !moving or !visible:
		return
	age += delta
	position.x += direction * speed * delta
	position.y  = base_y + sin(age * frequency + phase) * amplitude
	if absf(position.x) > 90.0:
		queue_free()
