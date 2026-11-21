extends Pellet

const NOTE := preload("res://fighters/monsters/serega/res/dark_note.png")
const SHARD := preload("res://fighters/monsters/serega/res/shard.png")
const RECORD := preload("res://fighters/monsters/serega/res/record.png")
const MARKED := preload("res://fighters/monsters/serega/res/marked_note.png")
const KEY := preload("res://fighters/monsters/serega/res/key.png")
const PENDULUM := preload("res://fighters/monsters/serega/res/pendulum.png")
const RESONANCE := preload("res://fighters/monsters/serega/res/resonance.png")

var velocity := Vector2.ZERO
var color := Color.WHITE
var visual := 0 # note, shard, record, marked note
var radius := 4.0
var spin := 0.0
var curve := 0.0
var wave_amplitude := 0.0
var wave_frequency := 4.0
var wave_phase := 0.0
var held := false
var life := 5.0
var age := 0.0
var bounds := 210.0
var _wave_offset := 0.0
var _sprite: Sprite2D
var _trail: Array[Vector2] = []

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	graze_points = 2
	time_points = 0.01
	var hitbox := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	hitbox.shape = shape
	add_child(hitbox)
	_sprite = Sprite2D.new()
	match visual:
		1: _sprite.texture = SHARD
		2: _sprite.texture = RECORD
		3: _sprite.texture = MARKED
		4: _sprite.texture = KEY
		5: _sprite.texture = PENDULUM
		6: _sprite.texture = RESONANCE
		_: _sprite.texture = NOTE
	_sprite.modulate = color
	add_child(_sprite)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	age += delta
	if not held:
		velocity = velocity.rotated(curve * delta)
		position += velocity * delta
		if wave_amplitude != 0.0 and velocity.length_squared() > 0.01:
			var new_offset: float = sin(age * wave_frequency + wave_phase) * wave_amplitude
			position += velocity.normalized().orthogonal() * (new_offset - _wave_offset)
			_wave_offset = new_offset
	if _sprite:
		_sprite.rotation += spin * delta
	if Engine.get_physics_frames() % 3 == 0:
		_trail.push_front(global_position)
		if _trail.size() > 5:
			_trail.pop_back()
	for body in get_overlapping_bodies():
		_on_body_entered(body)
	queue_redraw()
	if age > life or absf(position.x) > bounds or absf(position.y) > bounds:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 4.0, Color(color, 0.12))
	for i in _trail.size():
		var p := to_local(_trail[i]).round()
		var opacity: float = 0.30 * (1.0 - float(i) / 5.0)
		draw_rect(Rect2(p - Vector2.ONE, Vector2(2, 2)), Color(color, opacity))
