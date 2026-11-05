extends Pellet

const ICON := preload("res://fighters/monsters/captcha/attacks/orbit_glyph/glyph.png")
var velocity := Vector2.ZERO
var age := 0.0
var armed := false
var hit_shape: CollisionShape2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	damage = 9
	body_entered.connect(_on_body_entered)
	hit_shape = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	hit_shape.shape = shape
	hit_shape.disabled = true
	add_child(hit_shape)

func _physics_process(delta: float) -> void:
	age += delta
	position += velocity * delta
	if not armed and age >= 0.24:
		var soul := get_tree().get_first_node_in_group("soul") as Node2D
		if not soul or global_position.distance_to(soul.global_position) > 18.0:
			armed = true
			hit_shape.set_deferred("disabled", false)
			queue_redraw()
	if absf(position.x) > 88.0 or absf(position.y) > 88.0 or age > 3.0:
		queue_free()

func _draw() -> void:
	var color := Color(1, 1, 1, 1.0 if armed else 0.55)
	draw_texture_rect(ICON, Rect2(-8, -8, 16, 16), false, color)
