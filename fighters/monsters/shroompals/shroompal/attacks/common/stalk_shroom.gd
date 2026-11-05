extends Node2D
class_name StalkShroom
## Гриб на ножке переменной высоты. Начало координат — у основания ножки,
## растёт вверх (для гриба с потолка узел переворачивается scale.y = -1).

const STEM_WIDTH := 7.0

var height := 0.0:
	set(value):
		height = maxf(value, 0.0)
		_update_shapes()
		queue_redraw()
var velocity := Vector2.ZERO
var hitbox: ShroomPellet
var glow := 0.0:
	set(value):
		glow = value
		queue_redraw()

var _stem_shape := RectangleShape2D.new()
var _cap_shape := RectangleShape2D.new()
var _stem_node := CollisionShape2D.new()
var _cap_node := CollisionShape2D.new()
var _sway := randf() * TAU


func _init() -> void:
	hitbox = ShroomPellet.new(null, 0.0)
	hitbox.fade_in = 0.0
	hitbox.life = 999.0
	hitbox.bounds = 99999.0
	hitbox.damage = 6
	_stem_node.shape = _stem_shape
	_cap_node.shape = _cap_shape
	hitbox.add_child(_stem_node)
	hitbox.add_child(_cap_node)
	add_child(hitbox)
	_update_shapes()


func _update_shapes() -> void:
	# Хитбокс чуть меньше картинки — так честнее.
	_stem_shape.size = Vector2(STEM_WIDTH - 2.0, maxf(height - 1.0, 1.0))
	_stem_node.position = Vector2(0, -height / 2.0)
	_cap_shape.size = Vector2(14.0, 5.0)
	_cap_node.position = Vector2(0, -height - 4.0)
	_stem_node.disabled = height < 1.0
	_cap_node.disabled = height < 1.0


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_sway += delta * 6.0


func _draw() -> void:
	if height < 1.0:
		return
	var h := roundf(height)
	var half := STEM_WIDTH / 2.0
	draw_rect(Rect2(-half, -h, STEM_WIDTH, h), ShroomAttack.COL_OUTLINE)
	draw_rect(Rect2(-half + 1, -h, STEM_WIDTH - 2, h), ShroomAttack.COL_BODY)
	draw_rect(Rect2(-half + 1, -h, 1, h), ShroomAttack.COL_BODY_LIGHT)
	# Кольцо-юбочка на ножке
	if h > 14.0:
		draw_rect(Rect2(-half - 1, -h + 6, STEM_WIDTH + 2, 2), ShroomAttack.COL_OUTLINE)
		draw_rect(Rect2(-half, -h + 6, STEM_WIDTH, 1), ShroomAttack.COL_BODY_LIGHT)
	var cap := ShroomAttack.TEX_CAP_TOP
	var wobble := roundf(sin(_sway) * 0.6)
	draw_texture(cap, Vector2(-cap.get_width() / 2.0 + wobble, -h - cap.get_height() + 2), Color(1.0 + glow, 1.0 + glow, 1.0 + glow))
