extends Pellet
class_name LetterBullet

var letter:   String = "А"
var speed:    float  = 75.0
var dir:      float  = 1.0   # 1.0 = вправо, -1.0 = влево
var base_y:   float  = 0.0

var use_wave:       bool  = true
var wave_amplitude: float = 22.0
var wave_frequency: float = 3.0
var wave_phase:     float = 0.0
var vertical_speed: float = 0.0

var time: float = 0.0
var letter_index: int = 0   # индекс буквы в слове — для волны пульсации

const ARENA_X:        float = 120.0
const DESPAWN_X:      float = 160.0
const BASE_SCALE:     float = 1.3    # начальный размер — читаемый
const PULSE_AMP:      float = 0.35   # амплитуда пульсации
const PULSE_FREQ:     float = 5.0    # частота пульсации
const PULSE_PHASE_STEP: float = 0.55 # сдвиг фазы между соседними буквами (волна)
const FONT_SIZE: int  = 18

static var font: Font = null


func _ready() -> void:
	if !visible:
		return
	if font == null:
		font = load("res://fonts/8bitoperator Cyrillic Extension.otf")
	queue_redraw()


func _draw() -> void:
	if font == null:
		return
	var str_size := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	draw_string(
		font,
		Vector2(-str_size.x / 2.0, str_size.y / 4.0),
		letter,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		FONT_SIZE,
		Color(1.0, 0.88, 1.0)
	)


func _physics_process(delta: float) -> void:
	if !visible:
		return

	time += delta
	position.x += speed * dir * delta

	if use_wave:
		# Каждая буква сдвинута по фазе — слово извивается волной
		position.y = base_y + wave_amplitude * sin(time * wave_frequency + wave_phase + letter_index * 0.6)
	else:
		position.y += vertical_speed * delta

	# Пульсирующий масштаб — волна проходит по буквам через phase_step
	var pulse: float = BASE_SCALE + PULSE_AMP * sin(time * PULSE_FREQ + letter_index * PULSE_PHASE_STEP)
	scale = Vector2.ONE * pulse

	# Направленный despawn — только с той стороны, куда летит
	if dir > 0 and position.x > DESPAWN_X:
		queue_free()
	elif dir < 0 and position.x < -DESPAWN_X:
		queue_free()
