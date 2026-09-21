extends Node2D
# «Диссонанс» — СБАЛАНСИРОВАННАЯ ВЕРСИЯ.
#
# Принцип Jevil "Spiral attack": игрок ВИДИТ где зазор ДО того как волна летит.
#
# Механика:
#   - Летит одна волна за раз (не 5 одновременно)
#   - Зазор GAP = 48px — достаточно чтобы пройти без пикселперфект
#   - Перед каждой волной 0.6 сек "телеграф" — полосы появляются у края
#     НО ЕЩЁ НЕ ДВИЖУТСЯ (можно увидеть где дырка и встать туда)
#   - Burst из 6 (не 8) снарядов только один раз, снаряды летят к центру
#     с заметным зазором между ними

const CAGE_NORMAL := Vector2(150.0, 150.0)
const CAGE_WIDE   := Vector2(165.0, 155.0)

const TOTAL_WAVES:     int   = 4
const WAVE_INTERVAL:   float = 2.0    # пауза между волнами (игрок переводит дух)
const TELEGRAPH_TIME:  float = 0.65   # секунд полосы стоят неподвижно (телеграф)
const GAP_HALF:        float = 24.0   # полуширина зазора (итого 48px)
const WAVE_SPEED:      float = 82.0   # все волны одной скорости — предсказуемо
const BARS_PER_SIDE:   int   = 4      # полос сверху и снизу от зазора
const BAR_SPACING:     float = 16.0

const BURST_COUNT:     int   = 6
const BURST_SPEED:     float = 88.0

var waves_fired:   int   = 0
var wave_timer:    float = 0.5
var burst_done:    bool  = false
var done:          bool  = false

# Телеграф-фаза
var telegraphing:  bool  = false
var telegraph_timer: float = 0.0
var pending_bars:  Array = []   # данные ожидающих полос

var soul_cage = null


func _ready() -> void:
	z_index = 5
	var soul := get_tree().get_first_node_in_group("soul") as Soul
	if soul:
		soul_cage = soul.get_parent().get_node_or_null("SoulCage")
	if soul_cage:
		soul_cage.resize(CAGE_WIDE)


func _physics_process(delta: float) -> void:
	if done:
		return

	# Телеграф-фаза: полосы видны но стоят
	if telegraphing:
		telegraph_timer -= delta
		if telegraph_timer <= 0.0:
			telegraphing = false
			# Теперь запускаем полосы
			for bar_node in pending_bars:
				if is_instance_valid(bar_node):
					bar_node.moving = true
			pending_bars.clear()
		return

	wave_timer -= delta
	if wave_timer > 0.0:
		return

	if waves_fired < TOTAL_WAVES:
		_prepare_wave()
		waves_fired += 1
		# Burst после 2й волны
		if waves_fired == 2 and not burst_done:
			burst_done = true
			# burst запустим через маленькую задержку чтобы не совпал с волной
			get_tree().create_timer(0.9).timeout.connect(_fire_burst)
		wave_timer = WAVE_INTERVAL
	else:
		done = true


func _prepare_wave() -> void:
	var gap_center: float = randf_range(-35.0, 35.0)
	var from_left:  bool  = randf() > 0.5
	var start_x:    float = -148.0 if from_left else 148.0

	pending_bars.clear()

	# Верхние полосы
	for i in BARS_PER_SIDE:
		var y_pos: float = (gap_center - GAP_HALF) - i * BAR_SPACING
		pending_bars.append(_spawn_bar_static(y_pos, start_x, from_left))

	# Нижние полосы
	for i in BARS_PER_SIDE:
		var y_pos: float = (gap_center + GAP_HALF) + i * BAR_SPACING
		pending_bars.append(_spawn_bar_static(y_pos, start_x, from_left))

	telegraphing     = true
	telegraph_timer  = TELEGRAPH_TIME


func _spawn_bar_static(y_pos: float, start_x: float, from_left: bool) -> Node:
	var bar := $BaseBar.duplicate() as DisonansBar
	bar.visible  = true
	bar.z_index  = 5
	bar.speed    = WAVE_SPEED
	bar.dir      = 1.0 if from_left else -1.0
	bar.moving   = false   # стоит на месте во время телеграфа
	bar.position = Vector2(start_x, y_pos)
	add_child(bar)
	return bar


func _fire_burst() -> void:
	# 6 снарядов с явными зазорами — летят к центру веером
	for i in BURST_COUNT:
		var bullet := $BaseBurst.duplicate() as DisonansBurst
		bullet.visible  = true
		bullet.z_index  = 5

		var angle: float = (TAU / BURST_COUNT) * i
		var radius: float = 100.0
		bullet.position  = Vector2(cos(angle), sin(angle)) * radius
		bullet.direction = -Vector2(cos(angle), sin(angle))  # к центру
		bullet.speed     = BURST_SPEED
		add_child(bullet)


func _exit_tree() -> void:
	if soul_cage != null and is_instance_valid(soul_cage):
		soul_cage.resize(CAGE_NORMAL)
