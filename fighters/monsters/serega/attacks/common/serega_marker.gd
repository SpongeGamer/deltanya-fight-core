extends Node2D
# A captured position becomes dangerous only after its visible symbol locks.
var attack
var age: float = 0.0
var fired: bool = false
var phase: float = 0.0

func _physics_process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= 0.9 and not fired:
		fired = true
		if is_instance_valid(attack):
			var at: Vector2 = attack.to_local(global_position)
			attack.burst(at, Color("f5a1d3"))
			for i in 6:
				var angle: float = TAU * float(i) / 6.0 + phase
				var dir := Vector2.from_angle(angle)
				attack.shot(at + dir * 9.0, dir * 100.0, Color("f7c5ec"), 14, 1, 3.5)
	if age >= 1.05:
		queue_free()

func _draw() -> void:
	var alpha: float = clampf(age / 0.35, 0.0, 1.0)
	var radius: float = lerpf(15.0, 7.0, clampf(age / 0.9, 0.0, 1.0))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 16, Color(1.0, 0.65, 0.9, alpha * 0.75), 1.0)
	draw_rect(Rect2(-1, -1, 3, 3), Color(1.0, 0.85, 0.95, alpha))
