extends Node2D

const SHOT := preload("res://fighters/monsters/serega/attacks/common/serega_note.gd")
const SCORE := preload("res://fighters/monsters/serega/res/torn_score.png")
const ORBIT := preload("res://fighters/monsters/serega/attacks/common/serega_orbit.gd")
const PAPER := preload("res://fighters/monsters/serega/attacks/common/serega_page.gd")
const PALE := Color("ffe7f7")
const PINK := Color("f68cbf")
const VIOLET := Color("b58ce8")
const RED := Color("ff708c")

var variation: int = 0
var caster: Node2D
var field: Node2D
var over: Node2D

func _ready() -> void:
	var clip := Control.new()
	clip.position = Vector2(-71, -71)
	clip.size = Vector2(142, 142)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	field = Node2D.new()
	field.position = -clip.position
	clip.add_child(field)
	var atmosphere := Atmosphere.new()
	field.add_child(atmosphere)
	over = Node2D.new()
	add_child(over)
	call_deferred("run")

func run() -> void:
	pass

func get_duration() -> float:
	return 14.0

func wait(seconds: float) -> Signal:
	var timer := Timer.new()
	timer.one_shot = true
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(timer)
	timer.timeout.connect(timer.queue_free)
	timer.start(maxf(seconds, 0.001))
	return timer.timeout

func shot(pos: Vector2, vel: Vector2, tint: Color = PALE, damage_value: int = 14, visual_type: int = 0, hit_radius: float = 4.0):
	var bullet = SHOT.new()
	bullet.position = pos
	bullet.velocity = vel
	bullet.color = tint
	bullet.damage = damage_value
	bullet.visual = visual_type
	bullet.radius = hit_radius
	field.add_child(bullet)
	return bullet

func soul_pos() -> Vector2:
	var soul := get_tree().get_first_node_in_group("soul") as Soul
	return to_local(soul.global_position) if is_instance_valid(soul) else Vector2.ZERO

func beat() -> void:
	if is_instance_valid(caster) and caster.has_method("attack_pulse"):
		caster.call("attack_pulse")

func burst(pos: Vector2, tint: Color = PINK) -> void:
	var fx := Burst.new()
	fx.position = pos
	fx.tint = tint
	field.add_child(fx)

# Keep the old helper available for existing attack scripts in the project.
func group(origin: Vector2, target: Vector2, mode: int = 0, dir: float = 1.0) -> void:
	var obj = ORBIT.new()
	obj.position = origin
	obj.target = target
	obj.mode = mode
	obj.spin_direction = dir
	obj.harder = variation > 0
	field.add_child(obj)

func page(origin: Vector2, velocity: Vector2, delay: float = 1.0) -> void:
	var obj = PAPER.new()
	obj.position = origin
	obj.velocity = velocity
	obj.split_after = delay
	obj.attack = self
	field.add_child(obj)

class Atmosphere extends Node2D:
	var t: float = 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		for i in 22:
			var x: float = fposmod(float(i * 47) + sin(t * 0.7 + i) * 5.0, 138.0) - 69.0
			var y: float = fposmod(float(i * 67) - t * float(4 + i % 4), 138.0) - 69.0
			var alpha: float = 0.14 + 0.14 * (0.5 + 0.5 * sin(t * 2.0 + i))
			draw_rect(Rect2(round(x), round(y), 2, 2), Color(0.82, 0.51, 0.80, alpha))

class Burst extends Node2D:
	var tint := Color.WHITE
	var age: float = 0.0
	func _process(delta: float) -> void:
		age += delta
		if age >= 0.5:
			queue_free()
		else:
			queue_redraw()
	func _draw() -> void:
		var alpha: float = 1.0 - age / 0.5
		for i in 8:
			var angle: float = TAU * float(i) / 8.0 + 0.2
			var p := (Vector2.from_angle(angle) * (4.0 + age * 40.0)).round()
			draw_rect(Rect2(p, Vector2(2, 2)), Color(tint, alpha))
