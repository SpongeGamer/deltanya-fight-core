extends Node2D

var time_til_wave := 0.8

func _physics_process(delta: float) -> void:
	time_til_wave -= delta
	if time_til_wave <= 0.0:
		time_til_wave = randf_range(0.8, 1.2)
		_spawn_wave()

func _spawn_wave() -> void:
	var bullets: int = 4
	
	for i in range(bullets):
		var t: float = float(i) / float(bullets - 1)
		var angle: float = lerp(-0.8, 0.8, t)
		
		var left := $BaseBullet.duplicate() as Pellet
		left.visible = true
		left.position = Vector2(-70.0, randf_range(-25.0, 25.0))
		left.direction = Vector2(1.0, angle).normalized()
		add_child(left)
		
		var right := $BaseBullet.duplicate() as Pellet
		right.visible = true
		right.position = Vector2(70.0, randf_range(-25.0, 25.0))
		right.direction = Vector2(-1.0, angle).normalized()
		add_child(right)
