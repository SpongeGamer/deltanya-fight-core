extends Node2D
const SHOT := preload("res://fighters/monsters/serega/attacks/common/serega_note.gd")
var attack
var velocity := Vector2(0, 110)
var age: float = 0.0
var bounced: bool = false

func _ready() -> void:
	var key = SHOT.new()
	key.visual = 4
	key.radius = 5.0
	key.damage = 14
	key.life = 5.0
	key.bounds = 300.0
	add_child(key)

func _physics_process(delta: float) -> void:
	age += delta
	position += velocity * delta
	if not bounced and position.y >= 54.0:
		bounced = true
		velocity.y = -72.0
		if is_instance_valid(attack):
			var at: Vector2 = attack.to_local(global_position)
			attack.burst(at, Color("ffe7f7"))
			for a in [-0.65, 0.0, 0.65]:
				var n = attack.shot(at, Vector2(0, -82).rotated(a), Color("e7a9de"), 12, 1, 3.5)
				n.spin = 4.0
	if age > 4.5 or position.y < -130.0:
		queue_free()
