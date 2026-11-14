extends "res://fighters/monsters/knyaz/attacks/common/knyaz_stage.gd"

func get_duration() -> float:
	return 12.5

func _ready() -> void:
	super._ready()
	run()

func run() -> void:
	await pause_for(0.5)
	# Несколько музыкальных фраз без предупреждений у края.
	for wave in 6:
		var left := (wave + variation) % 2 == 0
		var center_y: float = [-20.0, 18.0, 0.0, -12.0, 21.0, -5.0][wave]
		if variation > 0:
			center_y = clampf(center_y + randf_range(-12, 12), -35, 35)
		for offset in [-27.0, -9.0, 9.0, 27.0]:
			_spawn_note(left, center_y + offset, false)
			await pause_for(0.11)
		# Фальшивая нота один раз берет прицел и летит прямо, без самонаводки.
		if wave == 1 or wave == 3 or wave == 5:
			var y := clampf(center_y + 30.0, -49.0, 49.0)
			await pause_for(0.4)
			_spawn_note(not left, y, true)
		await pause_for(0.65)

func _spawn_note(left: bool, y: float, false_note: bool) -> void:
	var bullet := $BaseBullet.duplicate() as NoteBullet
	bullet.visible = true
	bullet.position = Vector2(-85.0 if left else 85.0, y)
	bullet.direction = Vector2.RIGHT if left else Vector2.LEFT
	bullet.velocity = 110.4 if not false_note else 21.6
	bullet.is_false = false_note
	bullet.soul_target = soul
	field.add_child(bullet)
