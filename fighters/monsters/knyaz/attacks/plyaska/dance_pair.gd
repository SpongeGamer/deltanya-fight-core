extends Pellet
class_name DancePair

var is_leader := true
var center := Vector2.ZERO
var orbit_radius := 16.0
var angle := 0.0
var angular_speed := 2.2
var travel_dir := Vector2.ZERO
var travel_speed := 30.0
var lifetime := 0.0
var bullet_b: Area2D

func _physics_process(delta: float) -> void:
	if not visible or not is_leader:
		return
	lifetime += delta
	if lifetime >= 3.8:
		if is_instance_valid(bullet_b):
			bullet_b.queue_free()
		queue_free()
		return
	center += travel_dir * travel_speed * delta
	if absf(center.x) > 55.0:
		travel_dir.x = -travel_dir.x
		center.x = clampf(center.x, -55.0, 55.0)
	if absf(center.y) > 50.0:
		travel_dir.y = -travel_dir.y
		center.y = clampf(center.y, -50.0, 50.0)
	angle += angular_speed * delta
	var offset := Vector2(cos(angle), sin(angle)) * orbit_radius
	position = center + offset
	if is_instance_valid(bullet_b):
		bullet_b.position = center - offset
	queue_redraw()

func _draw() -> void:
	if visible and is_leader and is_instance_valid(bullet_b):
		# Нить декоративная; столкновение есть только у самих масок.
		draw_line(Vector2.ZERO, bullet_b.position - position, Color(0.95, 0.74, 0.45, 0.25), 1.0)
