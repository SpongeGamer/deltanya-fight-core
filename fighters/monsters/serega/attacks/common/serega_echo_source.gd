extends Node2D

const SHOT := preload("res://fighters/monsters/serega/attacks/common/serega_note.gd")
var attack
var velocity := Vector2(70.0, 52.0)
var age: float = 0.0
var fire_timer: float = 0.6
var polarity: float = 1.0
var body: Node2D

func _ready() -> void:
	var note = SHOT.new()
	note.visual = 3
	note.color = Color.WHITE
	note.radius = 6.0
	note.damage = 15
	note.life = 9.0
	note.bounds = 300.0
	add_child(note)
	body = note

func _physics_process(delta: float) -> void:
	age += delta
	position += velocity * delta
	# The marked note bounces inside the arena, leaving a second rhythm behind it.
	if position.x > 58.0 and velocity.x > 0.0:
		velocity.x = -velocity.x
	elif position.x < -58.0 and velocity.x < 0.0:
		velocity.x = -velocity.x
	if position.y > 58.0 and velocity.y > 0.0:
		velocity.y = -velocity.y
	elif position.y < -58.0 and velocity.y < 0.0:
		velocity.y = -velocity.y
	fire_timer -= delta
	if fire_timer <= 0.0 and is_instance_valid(attack):
		fire_timer = 0.8
		var at: Vector2 = attack.to_local(global_position)
		var direction: Vector2 = velocity.normalized().orthogonal() * polarity
		polarity = -polarity
		attack.burst(at, Color("d99de8"))
		for a in [-0.35, 0.0, 0.35]:
			var fragment = attack.shot(at, direction.rotated(a) * 92.0, Color("d8b7ff"), 12, 1, 3.5)
			fragment.spin = 4.0
	if age > 7.2:
		queue_free()
