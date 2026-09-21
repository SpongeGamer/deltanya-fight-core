extends Node2D

var time_til_bullet := 0.4

func _physics_process(delta: float) -> void:
	time_til_bullet -= delta
	if time_til_bullet < 0.0:
		time_til_bullet = randf_range(0.3, 0.5)
		var new_bullet: Pellet = $BaseBullet.duplicate()
		new_bullet.visible = true
		new_bullet.position = Vector2(randf_range(-55.0, 55.0), -62.0)
		add_child(new_bullet)
