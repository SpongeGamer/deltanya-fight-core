extends Pellet

var age := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	damage = 4
	body_entered.connect(_on_body_entered)
	var hit := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	hit.shape = circle
	add_child(hit)

func _physics_process(delta: float) -> void:
	age += delta
	if age >= 0.65:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var alpha := minf(1.0, (0.65 - age) / 0.15)
	var navy := Color(0.04, 0.12, 0.36, alpha)
	var red := Color(0.86, 0.22, 0.19, alpha)
	var light := Color(1.0, 0.97, 0.9, alpha)
	draw_circle(Vector2.ZERO, 15.0, navy)
	draw_circle(Vector2.ZERO, 13.0, red)
	draw_line(Vector2(-6, -6), Vector2(6, 6), light, 3.0)
	draw_line(Vector2(6, -6), Vector2(-6, 6), light, 3.0)
