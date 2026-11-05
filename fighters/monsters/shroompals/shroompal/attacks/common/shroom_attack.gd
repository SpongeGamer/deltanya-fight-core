extends Node2D
class_name ShroomAttack
## Общая основа атак Шрумпа.
## * field — слой внутри коробки (обрезается по её границам);
## * over  — слой поверх, для того что торчит за пределы коробки;
## * атмосфера: мягкое свечение грибницы снизу и парящие споры;
## * восстановление размера коробки и цвета души при завершении.

const RES := "res://fighters/monsters/shroompals/shroompal/res/"
const TEX_SPORE := preload(RES + "spore.png")
const TEX_SPORE_WHITE := preload(RES + "spore_white.png")
const TEX_POD := preload(RES + "pod.png")
const TEX_MINI_CAT := preload(RES + "mini_cat.png")
const TEX_HANG_CAP := preload(RES + "hang_cap.png")
const TEX_CAP_TOP := preload(RES + "cap_top.png")
const TEX_PUFFBALL := preload(RES + "puffball.png")
const TEX_HALO := preload(RES + "halo.png")
const TEX_MOTE := preload(RES + "mote.png")
const TEX_SHROOMPAL := preload("res://fighters/monsters/shroompals/shroompal/shroompal_idle.png")

const COL_OUTLINE := Color("000316")
const COL_CAP := Color("052f47")
const COL_BODY := Color("3b6e7f")
const COL_BODY_LIGHT := Color("6098a6")
const COL_SPOT := Color("3cf1e2")
const COL_SPOT_LIGHT := Color("b8fff6")
const COL_GLOW := Color(0.24, 0.95, 0.89, 0.55)
const COL_STAND := Color("1fa3ff")
const COL_MOVE := Color("ffa12e")

const DEFAULT_BOX := Vector2(150.0, 150.0)

## Номер круга атак (0 — первое знакомство, дальше сложнее).
var difficulty := 0
## Насколько Шрумп «разомлел» от милосердия (0..1) — немного смягчает атаки.
var calm := 0.0

var soul: Soul
var cage: Node2D
var clip: Control
var field: Node2D
var over: Node2D

var _box_changed := false
var _soul_changed := false
var _floor_glow: Sprite2D
var _motes: CPUParticles2D


## Длительность хода для battle.gd. Переопределяется в атаках.
func get_duration() -> float:
	return 8.0


## Коэффициент темпа: растёт с кругами, падает с милосердием.
func pace() -> float:
	return clampf(1.0 + 0.12 * difficulty - 0.18 * calm, 0.8, 1.45)


func _ready() -> void:
	soul = get_tree().get_first_node_in_group("soul") as Soul
	cage = _find_cage()

	clip = Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	field = Node2D.new()
	clip.add_child(field)
	over = Node2D.new()
	add_child(over)

	_build_atmosphere()
	_update_clip()
	run()


## Сценарий атаки (корутина).
func run() -> void:
	pass


func _process(_delta: float) -> void:
	_update_clip()


func _exit_tree() -> void:
	if _box_changed and is_instance_valid(cage) and cage.is_inside_tree() and cage.has_method("resize"):
		cage.resize(DEFAULT_BOX, 0.35)
	if _soul_changed and is_instance_valid(soul) and soul.is_inside_tree() and not soul.is_queued_for_deletion():
		soul.assign_heart_properties(SoulType.RED)


# ── Коробка и душа ─────────────────────────────────────────────────────────────

func _find_cage() -> Node2D:
	var node := get_parent()
	while node != null:
		var found := node.get_node_or_null("SoulCage")
		if found:
			return found as Node2D
		node = node.get_parent()
	return null


## Внутренняя область коробки в локальных координатах атаки.
func box_rect() -> Rect2:
	if is_instance_valid(cage):
		var panel := cage.get_node_or_null("Panel") as Control
		if panel:
			var top_left := to_local(cage.to_global(panel.position))
			return Rect2(top_left, panel.size).grow(-4.0)
	return Rect2(-DEFAULT_BOX / 2.0, DEFAULT_BOX).grow(-4.0)


## Где может находиться центр души (с учётом её размера 16×16).
func soul_area() -> Rect2:
	return box_rect().grow(-8.0)


func soul_pos() -> Vector2:
	if is_instance_valid(soul):
		return to_local(soul.global_position)
	return Vector2.ZERO


func resize_box(size: Vector2, duration := 0.45) -> void:
	if is_instance_valid(cage) and cage.has_method("resize"):
		_box_changed = true
		cage.resize(size, duration)
		if is_instance_valid(soul):
			# Душа не должна остаться за стенкой при сжатии коробки.
			var half := size / 2.0 - Vector2(10.0, 10.0)
			var target := soul_pos().clamp(-half, half)
			if target != soul_pos():
				var tween := soul.create_tween()
				tween.tween_property(soul, "global_position", to_global(target), duration * 0.8)


func set_soul_type(type: SoulType) -> void:
	if is_instance_valid(soul):
		_soul_changed = true
		soul.assign_heart_properties(type)


func _update_clip() -> void:
	var rect := box_rect()
	clip.position = rect.position
	clip.size = rect.size
	field.position = -rect.position
	if _floor_glow:
		_floor_glow.position = Vector2(rect.get_center().x, rect.end.y - 12.0)
		_floor_glow.scale = Vector2(rect.size.x / 64.0, 1.0)
	if _motes:
		_motes.position = rect.get_center()
		_motes.emission_rect_extents = rect.size / 2.0


# ── Атмосфера ──────────────────────────────────────────────────────────────────

func _build_atmosphere() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(COL_SPOT, 0.0))
	gradient.set_color(1, Color(COL_SPOT, 0.13))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 64
	tex.height = 24
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	_floor_glow = Sprite2D.new()
	_floor_glow.texture = tex
	_floor_glow.material = ShroomPellet.additive()
	field.add_child(_floor_glow)

	_motes = CPUParticles2D.new()
	_motes.texture = TEX_MOTE
	_motes.amount = 22
	_motes.lifetime = 4.5
	_motes.preprocess = 4.5
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.direction = Vector2(0, -1)
	_motes.spread = 25.0
	_motes.gravity = Vector2(0, -4)
	_motes.initial_velocity_min = 3.0
	_motes.initial_velocity_max = 9.0
	_motes.scale_amount_min = 0.5
	_motes.scale_amount_max = 1.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.add_point(0.3, Color(1, 1, 1, 0.55))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
	_motes.color_ramp = ramp
	_motes.material = ShroomPellet.additive()
	field.add_child(_motes)


# ── Утилиты ────────────────────────────────────────────────────────────────────

## Ожидание, которое безопасно обрывается вместе с атакой.
func wait(seconds: float) -> Signal:
	var timer := Timer.new()
	timer.one_shot = true
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(timer)
	timer.start(maxf(seconds, 0.001))
	timer.timeout.connect(timer.queue_free)
	return timer.timeout


func spore(pos: Vector2, vel: Vector2, glow := true) -> ShroomPellet:
	var p := ShroomPellet.new(TEX_SPORE, 3.0, COL_GLOW if glow else Color(0, 0, 0, 0))
	p.position = pos
	p.velocity = vel
	field.add_child(p)
	return p


func tinted_spore(pos: Vector2, vel: Vector2, color: Color) -> ShroomPellet:
	var p := ShroomPellet.new(TEX_SPORE_WHITE, 3.0, Color(color, 0.6))
	p.sprite.modulate = color.lightened(0.25)
	p.position = pos
	p.velocity = vel
	field.add_child(p)
	return p


## Неопасная вспышка частиц.
func puff(pos: Vector2, color := COL_SPOT, amount := 10, speed := 40.0, parent: Node = null) -> void:
	var fx := CPUParticles2D.new()
	fx.texture = TEX_MOTE
	fx.one_shot = true
	fx.explosiveness = 0.95
	fx.amount = amount
	fx.lifetime = 0.55
	fx.spread = 180.0
	fx.gravity = Vector2(0, 20)
	fx.initial_velocity_min = speed * 0.4
	fx.initial_velocity_max = speed
	fx.damping_min = 30.0
	fx.damping_max = 60.0
	fx.scale_amount_min = 0.5
	fx.scale_amount_max = 1.5
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color, 1.0))
	ramp.set_color(1, Color(color, 0.0))
	fx.color_ramp = ramp
	fx.material = ShroomPellet.additive()
	fx.position = pos
	(parent if parent else field).add_child(fx)
	fx.emitting = true
	fx.finished.connect(fx.queue_free)


func sfx(sound: String, volume := 0.6) -> void:
	Sounds.play(sound, volume)


func shake(time := 3.0, intensity := 2.0) -> void:
	if CameraController.instance and CameraController.instance.has_method("shake"):
		CameraController.instance.call("shake", time, intensity)
