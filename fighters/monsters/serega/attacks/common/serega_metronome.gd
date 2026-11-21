extends Node2D
const SHOT := preload("res://fighters/monsters/serega/attacks/common/serega_note.gd")
var attack
var age: float = 0.0
var last_side: int = 0
var bob: Node2D
var bob_position := Vector2(0, -100)

func _ready() -> void:
	var note = SHOT.new()
	note.visual = 5
	note.radius = 7.0
	note.damage = 15
	note.life = 9.0
	note.bounds = 300.0
	note.position = bob_position
	add_child(note)
	bob = note

func _physics_process(delta: float) -> void:
	age += delta
	var entrance: float = clampf(age / 1.0, 0.0, 1.0)
	var swing: float = sin(age * 2.35)
	bob_position = Vector2(swing * 62.0, lerpf(-100.0, -24.0 + absf(swing) * 17.0, entrance))
	bob.position = bob_position
	var side: int = 1 if swing > 0.8 else (-1 if swing < -0.8 else 0)
	if side != 0 and side != last_side:
		last_side = side
		if is_instance_valid(attack) and age > 1.1:
			var at: Vector2 = attack.to_local(bob.global_position)
			attack.burst(at, Color("f6b6dd"))
			for a in [-0.35, 0.0, 0.35]:
				var note = attack.shot(at, Vector2(0, 100).rotated(a), Color("e6b7f5"), 12, 1, 3.5)
				note.spin = 4.0
	queue_redraw()
	if age > 8.0:
		queue_free()

func _draw() -> void:
	draw_line(Vector2(0, -86), bob_position, Color(0.75, 0.55, 0.78, 0.55), 1.0)
