extends Node2D

# Маршрут кошки:
#  [ПОДХОД]  nikita_spawn_pos → правый край арены   (движется ВЛЕВО → flip = false)
#  [ROW 0]   право → лево                           (ВЛЕВО  → flip = false)
#  [СПУСК 1] вниз                                   (сохраняем flip)
#  [ROW 1]   лево → право                           (ВПРАВО → flip = true)
#  [СПУСК 2] вниз                                   (сохраняем flip)
#  [ROW 2]   право → лево                           (ВЛЕВО  → flip = false)

var phase2_mode      := false
var nikita_spawn_pos := Vector2(212.0, 0.0)

const AX    := 65.0
const AY    := 65.0

# Фаза 1: одна обычная кошка
const SPEED        := 100.0

# Фаза 2: 8 маленьких кошек
const SMALL_COUNT  := 8
const SMALL_SPEED  := 140.0
const SMALL_SCALE  := 0.5
const SMALL_DELAY  := 0.55   # секунд между каждым спавном

const ROW_Y            : Array[float] = [-50.0, 0.0, 50.0]
const APPROACH_STEPS   := 14
const POINTS_PER_ROW   := 30
const TRANSITION_STEPS := 6

var _cats:    Array[Node2D] = []
var _prev_xs: Array[float]  = []
var _paw_timer := 0.0
const INTRO_TIME := 0.8
const GROUP_PAUSE := 0.65


func get_duration() -> float:
	var points: Array = _build_full_path(0.0)
	var length := 0.0
	for i in range(1, points.size()):
		length += points[i - 1].distance_to(points[i])
	if phase2_mode:
		return INTRO_TIME + (SMALL_COUNT - 1) * SMALL_DELAY + GROUP_PAUSE + length / SMALL_SPEED + 0.9
	return INTRO_TIME + length / SPEED + 0.9

func _ready() -> void:
	await get_tree().process_frame
	var warning := _CatWarning.new()
	add_child(warning)
	await get_tree().create_timer(INTRO_TIME).timeout
	if not is_inside_tree():
		return
	if is_instance_valid(warning):
		warning.queue_free()
	if phase2_mode:
		_spawn_small_wave()
	else:
		Sounds.play("snd_ksuha")
		_fire_cat(0.0, 1.0, SPEED)


func _spawn_small_wave() -> void:
	for i in SMALL_COUNT:
		if i == 4:
			await get_tree().create_timer(GROUP_PAUSE).timeout
		if not is_inside_tree():
			return
		var sine_offset := (TAU / SMALL_COUNT) * i
		Sounds.play("snd_ksyuha_small")
		_fire_cat(sine_offset, SMALL_SCALE, SMALL_SPEED)
		await get_tree().create_timer(SMALL_DELAY).timeout


func _fire_cat(sine_offset: float, cat_scale: float, cat_speed: float) -> void:
	var p := $BaseBullet.duplicate() as Node2D
	p.visible = true
	p.scale   = Vector2(cat_scale, cat_scale)
	var path: Array[Vector2] = []
	path.assign(_build_full_path(sine_offset))
	p.set("path",  path)
	p.set("speed", cat_speed)
	add_child(p)
	_cats.append(p)
	_prev_xs.append(nikita_spawn_pos.x)


# ── Флип ──────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_paw_timer -= delta
	var make_paws := _paw_timer <= 0.0
	if make_paws:
		_paw_timer = 0.22
	for i in _cats.size():
		var cat := _cats[i]
		if not is_instance_valid(cat):
			continue
		if make_paws and absf(cat.position.x) < AX and absf(cat.position.y) < AY:
			var paw := _Paw.new()
			paw.position = cat.position
			add_child(paw)
		var cur_x := cat.position.x
		var dx    := cur_x - _prev_xs[i]
		if abs(dx) > 0.15:
			_apply_flip(cat, dx > 0.0)
		_prev_xs[i] = cur_x


func _apply_flip(cat: Node2D, flipped: bool) -> void:
	# Для маленьких котов: scale.x хранит знак флипа, но модуль = SMALL_SCALE
	var base_scale := cat.scale.y  # y не трогаем, берём как эталон размера
	if "flip_h" in cat:
		cat.set("flip_h", flipped)
		return
	for child in cat.get_children():
		if "flip_h" in child:
			child.set("flip_h", flipped)
			return
	# Fallback через scale.x, сохраняем абсолютный размер
	cat.scale.x = -base_scale if flipped else base_scale


# ── Маршрут ───────────────────────────────────────────────────────────────────

func _build_full_path(sine_offset: float) -> Array:
	var path: Array[Vector2] = []

	var arena_entry := Vector2(AX, ROW_Y[0])
	for i in range(1, APPROACH_STEPS + 1):
		path.append(nikita_spawn_pos.lerp(arena_entry, float(i) / APPROACH_STEPS))

	for row in 3:
		var y0       : float = ROW_Y[row]
		var go_right : bool  = (row % 2 == 1)
		var x_from   : float = AX  if not go_right else -AX
		var x_to     : float = -AX if not go_right else  AX

		for i in POINTS_PER_ROW:
			var t := float(i) / (POINTS_PER_ROW - 1)
			path.append(Vector2(
				lerpf(x_from, x_to, t),
				y0 + sin(t * TAU + sine_offset) * 6.0
			))

		if row < 2:
			var next_y : float = ROW_Y[row + 1]
			for j in TRANSITION_STEPS:
				var t := float(j + 1) / TRANSITION_STEPS
				path.append(Vector2(x_to, lerpf(y0, next_y, t)))

	return path


class _CatWarning extends Node2D:
	var age := 0.0
	func _process(delta: float) -> void:
		age += delta
		queue_redraw()
	func _draw() -> void:
		var alpha := 0.2 + 0.35 * minf(age / INTRO_TIME, 1.0)
		for row in 3:
			var y: float = ROW_Y[row]
			for i in 12:
				draw_line(Vector2(-60 + i * 10, y), Vector2(-56 + i * 10, y), Color(0.7, 0.88, 0.95, alpha), 1.0)
		var p := Vector2(62, ROW_Y[0])
		draw_line(p + Vector2(-8, -5), p, Color(0.8, 0.95, 1.0, alpha), 2.0)
		draw_line(p + Vector2(-8, 5), p, Color(0.8, 0.95, 1.0, alpha), 2.0)

class _Paw extends Node2D:
	var age := 0.0
	func _process(delta: float) -> void:
		age += delta
		if age > 0.6:
			queue_free()
			return
		queue_redraw()
	func _draw() -> void:
		var c := Color(0.65, 0.85, 0.95, 0.32 * (1.0 - age / 0.6))
		draw_circle(Vector2(0, 1), 2.0, c)
		draw_circle(Vector2(-2, -2), 1.0, c)
		draw_circle(Vector2(1, -3), 1.0, c)
		draw_circle(Vector2(3, -1), 1.0, c)
