extends Node2D
# SYMBOL_RAIN
# Символы капчи (цифры, буквы, искажённые знаки) сыплются сверху волнами.
# Каждый символ слегка виляет по горизонтали (синус), чтобы было сложнее читать.
# Под конец — финальная плотная волна «VERIFY».

const SYMBOLS := [
	"8","B","d","6","G","9","0","D","R","g",
	"W","m","@","#","%","&","?","!","3","E",
	"y","Y","4","A","q","Q","2","Z","S","5"
]
const VERIFY_CHARS := ["V","E","R","I","F","Y"]

var wave_timer  := 0.3
var wave_index  := 0
const MAX_WAVES := 11   # 9 обычных + 1 пауза + 1 VERIFY

func _physics_process(delta: float) -> void:
	if wave_index >= MAX_WAVES:
		return
	wave_timer -= delta
	if wave_timer > 0.0:
		return

	if wave_index < 9:
		wave_timer = 0.72
		_spawn_wave(wave_index)
	elif wave_index == 9:
		wave_timer = 0.5   # пауза перед финалом
	else:
		wave_timer = 99.0
		_spawn_verify_wave()

	wave_index += 1


func _spawn_wave(idx: int) -> void:
	# 3–5 символов в волне, случайные X-позиции
	var count := 3 + randi() % 3
	for i in count:
		var p := $BaseBullet.duplicate()
		p.visible   = true
		p.label     = SYMBOLS[randi() % SYMBOLS.size()]
		p.position  = Vector2(randf_range(-72.0, 72.0), -85.0)
		p.speed     = 75.0 + randf_range(-10.0, 20.0)
		p.amplitude = randf_range(6.0, 16.0)
		p.frequency = randf_range(1.8, 3.2)
		p.phase     = randf_range(0.0, TAU)
		add_child(p)


func _spawn_verify_wave() -> void:
	# «VERIFY» — 6 символов равномерно, быстро, без сдвига
	var spacing := 22.0
	var start_x := -(VERIFY_CHARS.size() - 1) * spacing * 0.5
	for i in VERIFY_CHARS.size():
		var p := $BaseBullet.duplicate()
		p.visible   = true
		p.label     = VERIFY_CHARS[i]
		p.position  = Vector2(start_x + i * spacing, -85.0)
		p.speed     = 120.0
		p.amplitude = 0.0   # летят прямо — финал должен читаться
		p.frequency = 0.0
		p.phase     = 0.0
		add_child(p)
