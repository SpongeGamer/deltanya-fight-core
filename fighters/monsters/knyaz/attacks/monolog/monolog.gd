extends Node2D
# «Монолог» — атака Князя.
# Слова из его лексикона летят через арену буквами-снарядами.
# Буквы увеличиваются по мере пути. Волна или прямолинейный полёт.

const CAGE_NORMAL := Vector2(150.0, 150.0)
const CAGE_WIDE   := Vector2(260.0, 140.0)
const ARENA_X:      float = 120.0
const LETTER_SPACING: float = 13.0

const WORDS: Array[String] = [
	"Марионетки", "Идол", "Ром", "Джокер", "Рогатый", "Шут",
	"Король", "Утопленник", "Лесник", "Кукла", "Колдун",
	"Валет", "Дама", "Фокусник", "Осел", "Ведьма", "Фред", "Голова"
]

const MAX_WORDS:      int   = 7
const SPAWN_INTERVAL: float = 1.7

var soul_cage           = null
var word_queue: Array   = []
var last_word:  String  = ""
var words_spawned: int  = 0
var spawn_timer:  float = 0.4
var done:        bool   = false
var cleaned_up:  bool   = false


func _ready() -> void:
	z_index = 5
	var soul := get_tree().get_first_node_in_group("soul") as Soul
	if soul:
		soul_cage = soul.get_parent().get_node_or_null("SoulCage")
	if soul_cage:
		soul_cage.resize(CAGE_WIDE)
	_refill_queue()


func _physics_process(delta: float) -> void:
	if done:
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_word()
		words_spawned += 1
		spawn_timer = SPAWN_INTERVAL
		if words_spawned >= MAX_WORDS:
			done = true


func _refill_queue() -> void:
	var all: Array = WORDS.duplicate()
	all.shuffle()
	# Первый элемент не должен совпадать с последним использованным
	if not last_word.is_empty() and all[0] == last_word and all.size() > 1:
		var tmp = all[0]; all[0] = all[1]; all[1] = tmp
	word_queue = all


func _next_word() -> String:
	if word_queue.is_empty():
		_refill_queue()
	var w: String = word_queue.pop_front()
	last_word = w
	return w


func _spawn_word() -> void:
	var word    := _next_word()
	var dir     := 1.0 if randf() > 0.5 else -1.0
	var base_y  := randf_range(-45.0, 45.0)
	var use_wave := randf() > 0.35
	var wave_amp  := randf_range(18.0, 30.0)
	var wave_freq := randf_range(2.2, 4.2)
	var wave_phase := randf_range(0.0, TAU)
	var vert_spd   := randf_range(-40.0, 40.0)
	var spd        := randf_range(58.0, 92.0)

	var n := word.length()
	for i in n:
		var lb := $BaseLetter.duplicate() as LetterBullet
		lb.visible        = true
		lb.z_index        = 5
		lb.letter         = word[i]
		lb.speed          = spd
		lb.dir            = dir
		lb.base_y         = base_y
		lb.use_wave       = use_wave
		lb.wave_amplitude = wave_amp
		lb.wave_frequency = wave_freq
		lb.wave_phase     = wave_phase
		lb.vertical_speed = vert_spd
		lb.letter_index   = i

		# Правильный порядок букв для обоих направлений:
		# dir=1  (вправо): буква i=0 самая левая на экране → стартует дальше всех за левым краем
		#   x = -ARENA_X - (n-1-i) * SPACING   → буква 0 дальше, буква n-1 у края
		# dir=-1 (влево):  буква i=0 самая левая на экране → стартует у правого края
		#   x = +ARENA_X + i * SPACING          → буква 0 у края, буква n-1 дальше
		var x_pos: float
		if dir > 0:
			x_pos = -ARENA_X - (n - 1 - i) * LETTER_SPACING
		else:
			x_pos = ARENA_X + i * LETTER_SPACING
		lb.position = Vector2(x_pos, base_y)

		add_child(lb)


func _exit_tree() -> void:
	if cleaned_up:
		return
	cleaned_up = true
	if soul_cage != null and is_instance_valid(soul_cage):
		soul_cage.resize(CAGE_NORMAL)
