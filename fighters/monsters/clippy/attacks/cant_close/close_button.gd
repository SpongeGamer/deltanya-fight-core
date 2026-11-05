extends Pellet

# The button is harmless while it leaves the window and while overlapping Soul.
var velocity := Vector2.ZERO
var age := 0.0
var armed := false
var shape_node: CollisionShape2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	damage = 5
	body_entered.connect(_on_body_entered)
	shape_node = CollisionShape2D.new()
	var hit_shape := RectangleShape2D.new()
	hit_shape.size = Vector2(7, 7)
	shape_node.shape = hit_shape
	shape_node.disabled = true
	add_child(shape_node)

func _physics_process(delta: float) -> void:
	age += delta
	position += velocity * delta
	if not armed and age >= 0.24:
		var soul := get_tree().get_first_node_in_group("soul") as Node2D
		if not soul or global_position.distance_to(soul.global_position) > 19.0:
			armed = true
			shape_node.set_deferred("disabled", false)
			queue_redraw()
	if absf(position.x) > 84.0 or absf(position.y) > 84.0 or age > 3.0:
		queue_free()

func _draw() -> void:
	var c := Color("e85542") if armed else Color("a5736e")
	draw_rect(Rect2(-4, -4, 8, 8), Color("202c55"))
	draw_rect(Rect2(-3, -3, 6, 6), c)
	draw_line(Vector2(-2, -2), Vector2(2, 2), Color.WHITE, 1.0)
	draw_line(Vector2(2, -2), Vector2(-2, 2), Color.WHITE, 1.0)
