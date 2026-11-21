extends Node2D

# One moving phrase. The same gap is visible in both the drawing and hitboxes.
const SHOT := preload("res://fighters/monsters/serega/attacks/common/serega_note.gd")
const KEY_TEXTURE := preload("res://fighters/monsters/serega/res/key_large.png")

# 0: score from top/bottom, 1: vibrating string, 2: piano keys, 3: echo slash
var kind: int = 0
var side: int = 1
var gap: int = 4
var speed: float = 72.0
var age: float = 0.0
var pieces: Array[Node2D] = []
var slots: Array[int] = []
var color: Color = Color("edb8df")
var direction: Vector2 = Vector2.DOWN
var finish_after: float = 3.6
# Optional entry edge: top, right, bottom, left. -1 keeps the old behavior.
var entry_edge: int = -1
var lean: float = 0.0
var turn_amount: float = 0.0
var base_angle: float = 0.0

func _ready() -> void:
	var is_vertical: bool = kind != 0
	direction = Vector2(-float(side), 0) if is_vertical else Vector2(0, float(side))
	var spawn_x: float = 115.0 if kind == 3 else 91.0
	position = Vector2(float(side) * spawn_x, 0) if is_vertical else Vector2(0, -float(side) * 91.0)
	if entry_edge >= 0:
		var directions: Array[Vector2] = [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
		direction = directions[entry_edge % 4]
		position = -direction * 115.0
		var from_vertical: bool = entry_edge == 0 or entry_edge == 2
		if kind == 0:
			base_angle = 0.0 if from_vertical else PI / 2.0
		else:
			base_angle = PI / 2.0 if from_vertical else 0.0
		rotation = base_angle + lean
	for i in 11:
		if i >= gap and i < gap + 3:
			continue
		var p = SHOT.new()
		p.damage = 14 if kind != 3 else 15
		p.radius = 4.0 if kind != 2 else 5.0
		p.life = 5.0
		p.bounds = 500.0
		p.visual = 0 if kind == 0 else 1
		p.color = color
		add_child(p)
		if kind == 2:
			# The common pellet keeps its sprite in _sprite, not a named scene node.
			if p._sprite:
				p._sprite.texture = KEY_TEXTURE
				p._sprite.modulate = Color.WHITE
		pieces.append(p)
		slots.append(i)
	_update_positions()

func _physics_process(delta: float) -> void:
	age += delta
	if entry_edge >= 0:
		rotation = base_angle + lean + turn_amount * sin(age * 1.3)
	position += direction * speed * delta
	_update_positions()
	queue_redraw()
	if age >= finish_after:
		queue_free()

func _update_positions() -> void:
	for j in pieces.size():
		if not is_instance_valid(pieces[j]):
			continue
		var i: int = slots[j]
		var axis: float = -65.0 + float(i) * 13.0
		if kind == 0:
			pieces[j].position = Vector2(axis, sin(float(i) * 0.65 + age * 4.0) * 2.0)
		elif kind == 1:
			pieces[j].position = Vector2(sin(float(i) * 0.62 + age * 8.0) * 6.0, axis)
		elif kind == 2:
			# Keys enter and recede individually, rather than moving as a flat wall.
			var depth: float = sin(age * 3.4 + float(i) * 0.8) * (8.0 if i % 2 == 0 else 3.0)
			pieces[j].position = Vector2(depth, axis)
		else:
			pieces[j].position = Vector2(axis * 0.33 + sin(age * 4.0 + i * 0.3) * 2.0, axis)

func _draw() -> void:
	if kind == 0:
		for y in [-8.0, -4.0, 0.0, 4.0, 8.0]:
			draw_line(Vector2(-72, y), Vector2(72, y), Color(0.56, 0.34, 0.57, 0.24), 1.0)
	elif kind == 1 or kind == 3:
		# Segments stop at the gap: there is no invisible hitbox in the opening.
		for j in range(pieces.size() - 1):
			if slots[j + 1] != slots[j] + 1:
				continue
			if is_instance_valid(pieces[j]) and is_instance_valid(pieces[j + 1]):
				draw_line(pieces[j].position, pieces[j + 1].position, Color(color, 0.68), 2.0)
