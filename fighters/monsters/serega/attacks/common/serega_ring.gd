extends Node2D
# The ring is a moving formation; its bullets orbit, contract and open again.
const SHOT := preload("res://fighters/monsters/serega/attacks/common/serega_note.gd")
var rotation_direction: float = 1.0
var age: float = 0.0
var pieces: Array[Node2D] = []
var slots: Array[int] = []
var missing: int = 0

func _ready() -> void:
	for i in 14:
		if i == missing or i == (missing + 1) % 14 or i == (missing + 2) % 14:
			continue
		var note = SHOT.new()
		note.visual = 6
		note.radius = 4.0
		note.damage = 14
		note.color = Color("f5c0df")
		note.life = 4.2
		note.bounds = 300.0
		var angle: float = TAU * float(i) / 14.0
		note.position = Vector2.from_angle(angle) * 110.0
		add_child(note)
		pieces.append(note)
		slots.append(i)

func _physics_process(delta: float) -> void:
	age += delta
	var r: float
	if age < 1.8:
		r = lerpf(110.0, 30.0, age / 1.8)
	else:
		r = lerpf(30.0, 118.0, clampf((age - 1.8) / 1.7, 0.0, 1.0))
	for i in pieces.size():
		if is_instance_valid(pieces[i]):
			var angle: float = TAU * float(slots[i]) / 14.0 + age * rotation_direction * 0.8
			pieces[i].position = Vector2.from_angle(angle) * r
	if age >= 3.6:
		queue_free()
