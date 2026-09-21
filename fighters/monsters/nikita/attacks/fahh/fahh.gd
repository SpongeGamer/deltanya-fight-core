extends Node2D

# FAHH — крик Никиты.
# ORANGE: конус из случайной точки правой стены — нельзя прижаться к углу.
# BLUE:   плотный горизонтальный строй на высоте соула — покрывает всю арену.
#
# phase2_mode = true → больше пуль, выше скорость, лишняя синяя волна в конце.
# Устанавливается из NikitaBoss._launch_attack() ДО add_child, поэтому
# все константы ниже читаются уже с правильным значением в _ready()-эквиваленте
# (у этой ноды нет _ready; логика в _physics_process — тоже ок).

## Устанавливается NikitaBoss перед add_child на второй фазе.
var phase2_mode := false

# ── Базовые константы ────────────────────────────────────────────────────────
const _BASE_ORANGE  := 11
const _BASE_BLUE    := 8
const _BASE_WAVES   := 9
const _BASE_SPD_O   := 100.0
const _BASE_SPD_B   := 110.0

# ── Параметры второй фазы ────────────────────────────────────────────────────
const _P2_ORANGE    := 16   # шире конус
const _P2_BLUE      := 11   # больше «кирпичей»
const _P2_WAVES     := 12   # больше волн
const _P2_SPD_O     := 135.0
const _P2_SPD_B     := 145.0

const WAVE_DELAY    := 0.60
const CONE_ANGLE    := 0.9

const ORANGE := Color("#ff9a1f")
const BLUE   := Color("#3db6ff")

const PELLET_SCENE := preload("res://pellets/generic_pellet/generic_pellet.tscn")
const FAHH_SOUND   := "fah"

# Финальный план волн: читается в первом _physics_process после установки phase2_mode.
var _wave_plan : PackedInt32Array
var _wave  := 0
var _timer := 0.2
var _ready_done := false


func _physics_process(delta: float) -> void:
	# Инициализируем план при первом тике — phase2_mode уже установлен
	if not _ready_done:
		_ready_done = true
		var wc : int = _P2_WAVES if phase2_mode else _BASE_WAVES
		# 0 = orange, 1 = blue; синяя каждые 3 волны + доп. синяя в конце на фазе 2
		_wave_plan = PackedInt32Array()
		for i in wc:
			_wave_plan.append(1 if (i % 3 == 2) else 0)

	if _wave >= _wave_plan.size():
		return

	_timer -= delta
	if _timer > 0.0:
		return
	_timer = WAVE_DELAY

	Sounds.play(FAHH_SOUND, 0.75)
	if _wave_plan[_wave] == 0:
		_spawn_orange()
	else:
		_spawn_blue()
	_wave += 1


func _spawn_orange() -> void:
	var cnt   : int   = _P2_ORANGE if phase2_mode else _BASE_ORANGE
	var speed : float = _P2_SPD_O  if phase2_mode else _BASE_SPD_O

	var spawn := Vector2(70.0, randf_range(-55.0, 55.0))
	var soul: Node2D = get_parent().get_node_or_null("Soul")
	var aim  := soul.position if soul else Vector2(-70.0, 0.0)
	var base_dir := (aim - spawn).normalized()

	for i in cnt:
		var t   := float(i) / float(cnt - 1)
		var dir := base_dir.rotated(lerpf(-CONE_ANGLE, CONE_ANGLE, t))
		_spawn_pellet(spawn, dir * speed, Pellet.HitRule.ORANGE_MOVE, ORANGE)


func _spawn_blue() -> void:
	var cnt   : int   = _P2_BLUE if phase2_mode else _BASE_BLUE
	var speed : float = _P2_SPD_B if phase2_mode else _BASE_SPD_B

	for i in cnt:
		var t := float(i) / float(cnt - 1)
		var y := lerpf(-65.0, 65.0, t)
		_spawn_pellet(Vector2(70.0, y), Vector2(-speed, 0.0),
				Pellet.HitRule.BLUE_STAND, BLUE)


func _spawn_pellet(pos: Vector2, vel: Vector2, rule: Pellet.HitRule, color: Color) -> void:
	var p := _make_pellet()
	p.hit_rule = rule
	var spr := p.get_node_or_null("Sprite")
	if spr is Sprite2D:
		spr.modulate = color
	p.visible  = true
	p.position = pos
	p.velocity = vel
	add_child(p)


func _make_pellet() -> GenericPellet:
	var base := get_node_or_null("BasePellet")
	var p := (base.duplicate() if base != null else PELLET_SCENE.instantiate()) as GenericPellet
	if base == null:
		p.damage        = 7 if not phase2_mode else 9
		p.life_time     = 2.0
		p.rotate_sprite = true
		p.shape         = 1
		p.body_entered.connect(p._on_body_entered)
	return p
