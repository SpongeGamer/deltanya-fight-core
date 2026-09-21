extends Node2D

var spawn_timer := 0.0

func _physics_process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(0.08, 0.16)
		_spawn_star()

func _spawn_star() -> void:
	var bullet := $BaseBullet.duplicate() as StarBullet
	bullet.visible = true
	
	bullet.position = Vector2(80.0, randf_range(-30.0, 30.0))
	bullet.velocity = randf_range(80.0, 120.0)
	bullet.direction = Vector2(-1.0, randf_range(-0.15, 0.15)).normalized()
	
	add_child(bullet)
