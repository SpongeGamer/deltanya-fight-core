extends Node2D

const ATTACK_FIELD := preload("res://fighters/monsters/nikita/attacks/common/attack_field.gd")
var _projectiles: Node2D
## FAHH: оранжевый веер и синяя волна с небольшими цветными вспышками.
## Промежуток между залпами дает предыдущей волне пройти через арену.

var phase2_mode := false
var echo_enabled := false
var mini_variant := false
var caster: Node2D
var _intervals: Array[float] = []
var _wave_kinds: Array[Pellet.HitRule] = []

const PELLET_SCENE := preload("res://pellets/generic_pellet/generic_pellet.tscn")
const COLOR_PELLET := preload("res://fighters/monsters/nikita/attacks/fahh/fahh_pellet.gd")
const ORANGE := Color("ff9a1f")
const BLUE := Color("3db6ff")
const WARN_TIME := 0.72
const MIN_INTERVAL := 1.20
const MAX_INTERVAL := 1.34

var _wave := 0
var _total_waves := 12
var _timer := WARN_TIME
var _warning := true
var _kind := Pellet.HitRule.ORANGE_MOVE
var _spawn := Vector2.ZERO
var _aim := Vector2.ZERO
var _echo_pending := false

func _ready() -> void:
	_projectiles = ATTACK_FIELD.make(self)
	_total_waves = 10 if mini_variant else (14 if phase2_mode else 12)
	for i in range(_total_waves):
		if i > 0:
			_intervals.append(randf_range(MIN_INTERVAL, MAX_INTERVAL))
		# Не более двух одинаковых залпов подряд; оба цвета встречаются с начала.
		var blue := randf() < 0.4
		if i == 1:
			blue = _wave_kinds[0] == Pellet.HitRule.ORANGE_MOVE
		elif i >= 2 and _wave_kinds[i - 1] == _wave_kinds[i - 2]:
			blue = _wave_kinds[i - 1] == Pellet.HitRule.ORANGE_MOVE
		_wave_kinds.append(Pellet.HitRule.BLUE_STAND if blue else Pellet.HitRule.ORANGE_MOVE)
	_prepare_wave()

func get_duration() -> float:
	var duration := WARN_TIME + (3.2 if echo_enabled else 2.1)
	for interval in _intervals:
		duration += interval
	return duration

func _prepare_wave() -> void:
	_kind = _wave_kinds[_wave]
	_spawn = Vector2(80.0, randf_range(-55.0, 55.0))
	var soul := get_tree().get_first_node_in_group("soul") as Soul
	_aim = to_local(soul.global_position) if is_instance_valid(soul) else Vector2(-50.0, 0.0)
	_warning = true
	_timer = WARN_TIME
	queue_redraw()

func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		if _warning:
			queue_redraw()
		return
	if _warning:
		_warning = false
		if is_instance_valid(caster) and caster.has_method("play_fah_salvo"):
			caster.play_fah_salvo()
		Sounds.play("fah", 0.75)
		if _kind == Pellet.HitRule.ORANGE_MOVE:
			_spawn_orange()
		else:
			_spawn_blue(false)
		_wave += 1
		if _wave >= _total_waves:
			if is_instance_valid(caster) and caster.has_method("end_fah_salvo"):
				get_tree().create_timer(1.0).timeout.connect(caster.end_fah_salvo)
			if echo_enabled and _mini_alive():
				_echo_pending = true
				_timer = 1.0
			else:
				set_physics_process(false)
		else:
			_timer = _intervals[_wave - 1] - WARN_TIME
		queue_redraw()
	elif _echo_pending:
		_echo_pending = false
		if _mini_alive():
			for monster in Global.monsters:
				if is_instance_valid(monster) and monster.is_in_group("nikita_mini") and not monster.dying:
					monster.play_fah_salvo()
					get_tree().create_timer(1.0).timeout.connect(monster.end_fah_salvo)
			Sounds.play("fah", 0.4)
			_spawn_blue(true)
		set_physics_process(false)
	elif _wave < _total_waves:
		_prepare_wave()

func _mini_alive() -> bool:
	for monster in Global.monsters:
		if is_instance_valid(monster) and monster.is_in_group("nikita_mini") and not monster.dying:
			return true
	return false

func _spawn_orange() -> void:
	var count := 16 if phase2_mode else 11
	var speed := 145.0 if phase2_mode else 110.0
	var base_dir := (_aim - _spawn).normalized()
	for i in count:
		var t := float(i) / float(count - 1)
		_spawn_pellet(_spawn, base_dir.rotated(lerpf(-0.9, 0.9, t)) * speed, Pellet.HitRule.ORANGE_MOVE, ORANGE, i % 3 == 1)

func _spawn_blue(echo: bool) -> void:
	var count := 8 if echo else (11 if phase2_mode else 8)
	var speed := 110.0 if echo else (145.0 if phase2_mode else 110.0)
	for i in count:
		# Все снаряды одной волны идут ровным фронтом, без случайного зигзага.
		var y := lerpf(-62.0, 62.0, float(i) / float(count - 1))
		_spawn_pellet(Vector2(80.0, y), Vector2(-speed, 0), Pellet.HitRule.BLUE_STAND, BLUE, i % 3 == 1)

func _spawn_pellet(pos: Vector2, vel: Vector2, rule: Pellet.HitRule, color: Color, round_shape := false) -> void:
	var p := PELLET_SCENE.instantiate() as GenericPellet
	p.set_script(COLOR_PELLET)
	p.damage = 8 if not phase2_mode else 9
	p.graze_points = 1
	p.time_points = 0.1
	p.life_time = 2.2
	p.rotate_sprite = not round_shape
	p.shape = 0 if round_shape else 1
	p.hit_rule = rule
	p.position = pos
	p.velocity = vel
	var spr := p.get_node("Sprite") as Sprite2D
	spr.modulate = color
	spr.scale = Vector2.ONE * (0.55 if round_shape else 0.72)
	p.body_entered.connect(p._on_body_entered)
	_projectiles.add_child(p)

func _draw() -> void:
	if not _warning and not _echo_pending:
		return
	var color := ORANGE if _kind == Pellet.HitRule.ORANGE_MOVE and not _echo_pending else BLUE
	var progress := 1.0 - clampf(_timer / WARN_TIME, 0.0, 1.0) if _warning else 0.65
	var y := clampf(_spawn.y, -58.0, 58.0) if color == ORANGE else 0.0
	var alpha := 0.35 + 0.5 * progress
	# Только маленькие искры у края: без стенок и направляющих.
	draw_circle(Vector2(65, y), 2.0 + progress, Color(color, alpha))
	draw_circle(Vector2(60, y - 5), 1.2, Color(color, alpha * 0.7))
	draw_circle(Vector2(60, y + 5), 1.2, Color(color, alpha * 0.7))
