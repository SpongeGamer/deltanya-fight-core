extends Node2D

const SCORE := preload("res://fighters/monsters/serega/res/torn_score.png")
var velocity := Vector2.ZERO
var split_after: float = 1.0
var attack
var age: float = 0.0
var _sprite: Sprite2D

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = SCORE
	add_child(_sprite)

func _physics_process(delta: float) -> void:
	age += delta
	position += velocity * delta
	_sprite.rotation = sin(age * 7.0) * 0.18
	if age < split_after:
		return
	if is_instance_valid(attack):
		var at: Vector2 = attack.to_local(global_position)
		var dir: Vector2 = (attack.soul_pos() - at).normalized()
		if dir.length_squared() < 0.01:
			dir = Vector2.DOWN
		attack.burst(at, Color("f68cbf"))
		attack.beat()
		for angle in [-0.7, -0.35, 0.0, 0.35, 0.7]:
			var fragment = attack.shot(at, dir.rotated(angle) * 110.0, Color("ffe7f7"), 13, 1, 3.5)
			fragment.spin = 5.0 if angle > 0.0 else -5.0
			fragment.life = 2.8
	queue_free()
