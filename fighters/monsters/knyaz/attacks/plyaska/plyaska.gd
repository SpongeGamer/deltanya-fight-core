extends "res://fighters/monsters/knyaz/attacks/common/knyaz_stage.gd"

const MASK_GOLD := preload("res://fighters/monsters/knyaz/attacks/common/mask_gold.png")
const MASK_RED := preload("res://fighters/monsters/knyaz/attacks/common/mask_red.png")

func get_duration() -> float:
	return 14.0

func _ready() -> void:
	super._ready()
	run()

func run() -> void:
	await pause_for(0.5)
	for wave in 6:
		var left := (wave + variation) % 2 == 0
		var center := Vector2(-53.0 if left else 53.0, [-27.0, 25.0, 0.0, -24.0, 23.0, 0.0][wave])
		var angle := PI / 2.0
		var offset := Vector2(cos(angle), sin(angle)) * 18.0
		warn(center + offset, 0.7)
		warn(center - offset, 0.7)
		await pause_for(0.7)
		_spawn_pair(center, angle, wave)
		await pause_for(1.0)

func _spawn_pair(center: Vector2, angle: float, wave: int) -> void:
	var a := $BaseBulletA.duplicate() as DancePair
	var b := $BaseBulletB.duplicate() as DancePair
	a.visible = true
	b.visible = true
	b.is_leader = false
	a.center = center
	a.orbit_radius = 18.0
	a.angle = angle
	a.angular_speed = 3.36 if wave % 2 == 0 else -3.36
	a.travel_dir = (Vector2.ZERO - center).normalized()
	a.travel_speed = 45.6
	a.bullet_b = b
	var offset := Vector2(cos(angle), sin(angle)) * a.orbit_radius
	a.position = center + offset
	b.position = center - offset
	for pair in [a, b]:
		var sprite := pair.get_node("Sprite") as Sprite2D
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2(1.6, 1.6)
		var hitbox := pair.get_node("CollisionShape2D") as CollisionShape2D
		hitbox.scale = Vector2(1.3, 1.3)
		sprite.position = Vector2.ZERO
		sprite.texture = MASK_GOLD if pair == a else MASK_RED
	field.add_child(a)
	field.add_child(b)
