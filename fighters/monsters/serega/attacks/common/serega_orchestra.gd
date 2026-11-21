extends Node2D
const RECORD := preload("res://fighters/monsters/serega/res/record.png")
var attack
var age: float = 0.0
var next_emitter: int = 0
var fire_timer: float = 0.9
var direction: float = 1.0
var emitters: Array[Sprite2D] = []

func _ready() -> void:
	for i in 5:
		var sprite := Sprite2D.new()
		sprite.texture = RECORD
		sprite.scale = Vector2(0.65, 0.65)
		sprite.modulate = Color("d8b9ea")
		add_child(sprite)
		emitters.append(sprite)

func _physics_process(delta: float) -> void:
	age += delta
	# Direction flips partway through the phrase; the beat continues in order.
	var rotation_angle: float = minf(age, 3.5) * direction * 0.55
	if age > 3.5:
		rotation_angle -= (age - 3.5) * direction * 0.55
	for i in emitters.size():
		var angle: float = TAU * float(i) / float(emitters.size()) + rotation_angle
		emitters[i].position = Vector2.from_angle(angle) * 78.0
		emitters[i].rotation = -rotation_angle
	fire_timer -= delta
	if fire_timer <= 0.0 and is_instance_valid(attack):
		fire_timer = 0.54
		var emitter: Sprite2D = emitters[next_emitter % emitters.size()]
		next_emitter += 1
		var at: Vector2 = attack.to_local(emitter.global_position)
		var direction_to_soul: Vector2 = (attack.soul_pos() - at).normalized()
		attack.burst(at, Color("f8b6e4"))
		attack.beat()
		for a in [-0.19, 0.0, 0.19]:
			var note = attack.shot(at, direction_to_soul.rotated(a) * 95.0, Color("f2c2ed"), 13, 1, 3.5)
			note.spin = 4.0
	if age > 8.5:
		queue_free()
