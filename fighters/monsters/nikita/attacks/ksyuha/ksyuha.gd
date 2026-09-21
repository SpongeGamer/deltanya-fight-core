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


func _ready() -> void:
	await get_tree().process_frame
	if phase2_mode:
		_spawn_small_wave()
	else:
		Sounds.play("snd_ksuha")
		_fire_cat(0.0, 1.0, SPEED)


func _spawn_small_wave() -> void:
	for i in SMALL_COUNT:
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

func _process(_delta: float) -> void:
	for i in _cats.size():
		var cat := _cats[i]
		if not is_instance_valid(cat):
			continue
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
