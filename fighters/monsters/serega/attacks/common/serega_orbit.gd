extends Node2D

const SHOT := preload("res://fighters/monsters/serega/attacks/common/serega_note.gd")
const RECORD := preload("res://fighters/monsters/serega/res/record.png")
var target := Vector2.ZERO
var mode: int = 0
var spin_direction: float = 1.0
var harder: bool = false
var age: float = 0.0
var speed: float = 70.0
var travel := Vector2.ZERO
var notes: Array[Node2D] = []
var hub: Sprite2D

func _ready() -> void:
	travel = (target - position).normalized()
	if travel.length_squared() < 0.01:
		travel = Vector2.RIGHT
	hub = Sprite2D.new()
	hub.texture = RECORD
	hub.modulate = Color(0.9, 0.8, 1.0, 0.9)
	add_child(hub)
	var amount: int = 6 if mode == 0 else 7
	for i in amount:
		var note = SHOT.new()
		note.visual = 0 if mode == 0 else 1
		note.radius = 4.0
		note.color = Color("f5b5e4") if i % 2 == 0 else Color("caa9ff")
		note.damage = 14
		note.life = 4.8
		note.bounds = 300.0
		add_child(note)
		notes.append(note)

func _physics_process(delta: float) -> void:
	age += delta
	position += travel * (speed + (8.0 if harder else 0.0)) * delta
	hub.rotation += spin_direction * delta * 1.8
	for i in notes.size():
		if not is_instance_valid(notes[i]):
			continue
		var phase: float = age * spin_direction * (2.6 if mode == 0 else 1.7)
		var offset := Vector2.ZERO
		if mode == 0:
			var angle: float = phase + TAU * float(i) / float(notes.size())
			var r: float = 25.0 + sin(age * 3.0) * 7.0
			offset = Vector2.from_angle(angle) * r
		else:
			var distance: float = (float(i) - 3.0) * 11.0
			offset = Vector2(distance, sin(age * 4.5 + float(i) * 0.65) * 8.0).rotated(phase)
		notes[i].position = offset
	if age > 4.0 or absf(position.x) > 180.0 or absf(position.y) > 180.0:
		queue_free()
