extends Node2D

# SLAM — удары кулаком, трещины в земле.
#
# Фаза 1 (phase2_mode = false):
#   5 волн, обычные трещины, 14 осколков на трещину (было 22 — чуть легче уворачиваться)
#
# Фаза 2 (phase2_mode = true):
#   7 волн, МИКРО-трещины: короткие, тонкие, их много за волну, 8 осколков каждая.
#   Арена покрывается сетью мелких угроз вместо нескольких широких.

var phase2_mode := false

const PELLET_SCENE := preload("res://pellets/generic_pellet/generic_pellet.tscn")

const AX := 65.0
const AY := 65.0

# ── Осколки ───────────────────────────────────────────────────────────────────
const _BASE_SHARDS     := 14     # фаза 1 (было 22)
const _P2_SHARDS       := 8      # фаза 2 — микро-трещина, меньше осколков
const SHARD_SPEED_MIN  := 60.0
const SHARD_SPEED_MAX  := 130.0
const SHARD_SPREAD     := 0.35
const _P2_SHARD_SPREAD := 0.55   # у микро-трещин чуть шире угол

# ── Геометрия трещин ──────────────────────────────────────────────────────────
const _BASE_STEPS  := 32    # обычная длинная трещина
const _MICRO_STEPS := 10    # короткая микро-трещина
const _BASE_WIDTH  := 3.5
const _MICRO_WIDTH := 1.8

# ── Тайминги ──────────────────────────────────────────────────────────────────
const TELEGRAPH_T    := 1.1
const _BASE_STAGGER  := 0.40
const _P2_STAGGER    := 0.22   # быстрее — много трещин надо разместить
const WAVE_PAUSE     := 0.9
const _BASE_WAVES    := 5
const _P2_WAVES      := 7

# ── Планы волн: фаза 1 (0=↑, 1=→, 2=↗) ──────────────────────────────────────
const WAVE_PLAN : Array[Array] = [
	[0, 1],
	[0, 0, 1],
	[1, 0, 1],
	[0, 2, 0],
	[2, 0, 1, 2],
]

# ── Планы волн: фаза 2 — больше трещин за волну ───────────────────────────────
const WAVE_PLAN_P2 : Array[Array] = [
	[0, 1, 0],
	[1, 0, 1, 0],
	[0, 2, 0, 1],
	[2, 0, 1, 0, 2],
	[0, 1, 2, 0, 1],
	[1, 0, 0, 2, 1, 0],
	[2, 1, 0, 2, 0, 1, 2],
]

var _wave := 0


func _ready() -> void:
	_run()


func _run() -> void:
	var total_waves : int   = _P2_WAVES      if phase2_mode else _BASE_WAVES
	var stagger     : float = _P2_STAGGER    if phase2_mode else _BASE_STAGGER
	var plan_array          = WAVE_PLAN_P2   if phase2_mode else WAVE_PLAN

	while _wave < total_waves:
		if not is_inside_tree():
			return

		var plan : Array = plan_array[_wave % plan_array.size()]

		for dir in plan:
			if not is_inside_tree():
				return
			_launch_crack(dir)
			await get_tree().create_timer(stagger).timeout

		await get_tree().create_timer(TELEGRAPH_T + 0.3 + WAVE_PAUSE).timeout
		_wave += 1


# ── Одна трещина ──────────────────────────────────────────────────────────────

func _launch_crack(direction: int) -> void:
	if not is_inside_tree():
		return

	Sounds.play("snd_impact", 0.6)
	if CameraController.instance:
		CameraController.instance.shake(8.0, 3.0)

	var path : Array[Vector2] = _build_crack(direction)
	var line := _draw_crack(path)
	add_child(line)

	await _blink_crack(line)

	if not is_inside_tree() or not is_instance_valid(line):
		return

	Sounds.play("snd_impact", 0.8)
	if CameraController.instance:
		var shake_amt : float = 14.0 if phase2_mode else 12.0
		CameraController.instance.shake(shake_amt, 4.0)
	_burst_shards(path, direction)

	line.default_color = Color.WHITE
	line.width = 5.0
	var tw := get_tree().create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.35)
	tw.finished.connect(line.queue_free)


func _blink_crack(line: Line2D) -> void:
	var t     := 0.0
	var blink := 0.0
	while t < TELEGRAPH_T and is_instance_valid(line):
		await get_tree().process_frame
		if not is_inside_tree():
			return
		var dt : float = get_process_delta_time()
		t     += dt
		blink += dt * 10.0
		var freq : float = 6.0 + (t / TELEGRAPH_T) * 10.0
		line.modulate.a = clampf(0.15 + sin(blink * freq * 0.1) * 0.85, 0.05, 1.0)


func _burst_shards(path: Array[Vector2], direction: int) -> void:
	var main_dir : Vector2
	match direction:
		0: main_dir = Vector2(0.0, -1.0)
		1: main_dir = Vector2(1.0, 0.0)
		_: main_dir = Vector2(1.0, -1.0).normalized()

	var perp   : Vector2 = Vector2(-main_dir.y, main_dir.x)
	var cnt    : int     = _P2_SHARDS   if phase2_mode else _BASE_SHARDS
	var spread : float   = _P2_SHARD_SPREAD if phase2_mode else SHARD_SPREAD

	for i in cnt:
		var t      : float   = float(i) / float(cnt - 1)
		var idx    : int     = int(t * (path.size() - 1))
		var origin : Vector2 = path[idx]

		for side in [-1.0, 1.0]:
			var angle : float   = randf_range(-spread, spread)
			var dir2  : Vector2 = (perp * side).rotated(angle).normalized()
			var speed : float   = randf_range(SHARD_SPEED_MIN, SHARD_SPEED_MAX)
			var p := _make_shard()
			p.visible  = true
			p.position = origin
			p.velocity = dir2 * speed
			add_child(p)


# ── Геометрия ─────────────────────────────────────────────────────────────────

func _build_crack(direction: int) -> Array[Vector2]:
	var path     : Array[Vector2] = []
	var main_dir : Vector2
	var start    : Vector2

	match direction:
		0:
			main_dir = Vector2(0.0, -1.0)
			start    = Vector2(randf_range(-AX * 0.75, AX * 0.75), AY)
		1:
			main_dir = Vector2(1.0, 0.0)
			start    = Vector2(-AX, randf_range(-AY * 0.75, AY * 0.75))
		_:
			start    = Vector2(randf_range(-AX, 0.0), randf_range(0.0, AY))
			main_dir = Vector2(1.0, -1.0).normalized()

	var perp : Vector2 = Vector2(-main_dir.y, main_dir.x)
	var pos  : Vector2 = start
	path.append(pos)

	var steps : int = _MICRO_STEPS if phase2_mode else _BASE_STEPS
	# Микро-трещины уже (меньше боковое отклонение)
	var side_range : float = 5.0 if phase2_mode else 11.0

	for _i in steps:
		var fwd  : float = randf_range(3.5, 8.0)
		var side : float = randf_range(-side_range, side_range)
		pos = pos + main_dir * fwd + perp * side
		pos.x = clampf(pos.x, -AX, AX)
		pos.y = clampf(pos.y, -AY, AY)
		path.append(pos)

	return path


func _draw_crack(path: Array[Vector2]) -> Line2D:
	var line := Line2D.new()
	line.joint_mode     = Line2D.LINE_JOINT_SHARP
	line.begin_cap_mode = Line2D.LINE_CAP_NONE
	line.end_cap_mode   = Line2D.LINE_CAP_NONE
	line.modulate.a     = 0.0
	line.width_curve    = _make_width_curve()

	if phase2_mode:
		line.width         = _MICRO_WIDTH
		line.default_color = Color(0.845, 0.267, 0.0, 1.0)   # яркий оранжево-красный
	else:
		line.width         = _BASE_WIDTH
		line.default_color = Color.WHITE

	var pts := PackedVector2Array()
	for p in path:
		pts.append(p)
	line.points = pts

	# Ветки: у обычных трещин 3, у микро — 1 (чтобы не мусорить)
	var branch_count : int = 1 if phase2_mode else 3
	var mid : int = path.size() / 2

	for branch_i in branch_count:
		var bi : int = clampi(mid + randi_range(-5, 5), 1, path.size() - 2)
		var branch := Line2D.new()
		branch.width         = 0.8 if phase2_mode else 1.2
		branch.joint_mode    = Line2D.LINE_JOINT_SHARP
		branch.default_color = line.default_color
		var along : Vector2 = (path[bi] - path[bi - 1]).normalized()
		var bperp : Vector2 = Vector2(-along.y, along.x)
		var bside : float   = 1.0 if branch_i % 2 == 0 else -1.0
		var blen  : int     = randi_range(2, 5) if phase2_mode else randi_range(4, 9)
		var bpts  := PackedVector2Array()
		bpts.append(path[bi])
		var bp := path[bi]
		for _j in blen:
			bp = bp + bperp * bside * randf_range(1.0, 3.0) + along * randf_range(1.0, 2.5)
			bpts.append(bp)
		branch.points = bpts
		line.add_child(branch)

	return line


func _make_width_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.4))
	c.add_point(Vector2(0.5, 1.0))
	c.add_point(Vector2(1.0, 0.2))
	return c


func _make_shard() -> GenericPellet:
	var p := PELLET_SCENE.instantiate() as GenericPellet
	p.damage              = 9 if phase2_mode else 8
	p.life_time           = 0.5
	p.rotate_sprite       = true
	p.shape               = 0
	p.linear_acceleration = -80.0
	p.body_entered.connect(p._on_body_entered)
	return p
