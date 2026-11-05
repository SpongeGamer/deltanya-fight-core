extends Pellet
class_name ShroomPellet
## Универсальный снаряд Шрумпа: движение, покачивание, свечение и
## непрерывная проверка попадания (важно для синих/оранжевых правил).

static var _additive: CanvasItemMaterial

var velocity := Vector2.ZERO
var acceleration := Vector2.ZERO
var drag := 0.0
var life := 8.0
var sway_amp := 0.0
var sway_freq := 3.0
var sway_phase := 0.0
var spin := 0.0
var fade_in := 0.1
## Дистанция от центра атаки, после которой снаряд удаляется.
var bounds := 150.0
var age := 0.0

var sprite: Sprite2D
var halo: Sprite2D
var shape_node: CollisionShape2D

var harmful := true:
	set(value):
		harmful = value
		for child in get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", not value)

var _sway_offset := 0.0


static func additive() -> CanvasItemMaterial:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive


func _init(texture: Texture2D = null, radius := 3.0, glow_color := Color(0, 0, 0, 0)) -> void:
	collision_layer = 2
	collision_mask = 1
	damage = 5
	if glow_color.a > 0.0:
		halo = Sprite2D.new()
		halo.texture = ShroomAttack.TEX_HALO
		halo.material = additive()
		halo.modulate = glow_color
		add_child(halo)
	if texture:
		sprite = Sprite2D.new()
		sprite.texture = texture
		add_child(sprite)
	if radius > 0.0:
		shape_node = CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape_node.shape = circle
		add_child(shape_node)


func _ready() -> void:
	if fade_in > 0.0:
		modulate.a = 0.0


func _physics_process(delta: float) -> void:
	age += delta
	if fade_in > 0.0 and age <= fade_in + delta:
		modulate.a = clampf(age / fade_in, 0.0, 1.0)

	velocity += acceleration * delta
	if drag > 0.0:
		velocity *= maxf(0.0, 1.0 - drag * delta)
	position += velocity * delta

	if sway_amp != 0.0 and velocity != Vector2.ZERO:
		var side := velocity.normalized().orthogonal()
		var new_offset := sin(age * sway_freq + sway_phase) * sway_amp
		position += side * (new_offset - _sway_offset)
		_sway_offset = new_offset

	if spin != 0.0 and sprite:
		sprite.rotation += spin * delta

	if harmful:
		for body in get_overlapping_bodies():
			if body is Soul:
				_on_body_entered(body)

	if age >= life or position.length() > bounds:
		queue_free()


## Плавно погасить и удалить (без урона во время угасания).
func vanish(duration := 0.2) -> void:
	harmful = false
	velocity *= 0.3
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)
