extends Node2D
class_name StarwalkerAttack
## Общая сцена атак: обрезка по боевой рамке, честные предупреждения и звёзды.
const GOLD := Color("ffe375")
const WHITE := Color("fff9db")
const BLUE := Color("8197ca")
var field: Node2D
var over: Node2D
var chicken_reaction := false
var caster: Monster

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
	field.add_child(_Constellation.new())
	over = Node2D.new()
	add_child(over)
	call_deferred("_start")

func _start() -> void:
	if chicken_reaction:
		var gag := _ChickenGag.new()
		over.add_child(gag)
		Sounds.play("snd_impact", 0.25)
		await wait(0.85)
		if not is_inside_tree():
			return
		gag.queue_free()
	run()

func run() -> void:
	pass

func get_duration() -> float:
	return 9.0 + (0.85 if chicken_reaction else 0.0)

func wait(seconds: float) -> Signal:
	var timer := Timer.new()
	timer.one_shot = true
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(timer)
	timer.timeout.connect(timer.queue_free)
	timer.start(maxf(seconds, 0.001))
	return timer.timeout

func shoot(pos: Vector2, vel: Vector2, curvature := 0.0) -> StarwalkerShot:
	var shot := StarwalkerShot.new()
	shot.position = pos
	shot.velocity = vel
	shot.curve = curvature
	field.add_child(shot)
	return shot

func pulse() -> void:
	if is_instance_valid(caster) and caster.has_method("attack_pulse"):
		caster.call("attack_pulse")

func soul_pos() -> Vector2:
	var soul := get_tree().get_first_node_in_group("soul") as Soul
	return to_local(soul.global_position) if is_instance_valid(soul) else Vector2.ZERO

func warn_line(from: Vector2, to: Vector2, duration: float, color := GOLD) -> void:
	var warning := _Warning.new()
	warning.a = from
	warning.b = to
	warning.duration = duration
	warning.color = color
	field.add_child(warning)

class _Warning extends Node2D:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var duration := 0.7
	var age := 0.0
	var color := Color.WHITE
	func _process(delta: float) -> void:
		age += delta
		if age >= duration:
			queue_free()
			return
		queue_redraw()
	func _draw() -> void:
		var length := a.distance_to(b)
		var direction := (b - a).normalized()
		var alpha := 0.25 + 0.45 * age / duration
		for i in range(int(length / 8.0)):
			draw_line(a + direction * i * 8.0, a + direction * (i * 8.0 + 3.0), Color(color, alpha), 1.0)
		draw_circle(a, 3.0 + 2.0 * age / duration, Color(color, alpha))

class _ChickenGag extends Node2D:
	var age := 0.0
	func _process(delta: float) -> void:
		age += delta
		queue_redraw()
	func _draw() -> void:
		# Маленькое театральное «возмущение», не наносит урона.
		var alpha := clampf(minf(age * 8.0, (0.85 - age) * 5.0), 0.0, 1.0)
		var y := -12.0 - 12.0 * age
		draw_string(ThemeDB.fallback_font, Vector2(-9, y), "!?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(StarwalkerAttack.GOLD, alpha))
		for i in 4:
			var a := TAU * i / 4.0 + age
			var p := Vector2(cos(a) * 30.0, sin(a) * 15.0 + y)
			draw_line(p - Vector2(2, 2), p + Vector2(2, 2), Color(StarwalkerAttack.WHITE, alpha), 1.0)


class _Constellation extends Node2D:
	# Фоновая россыпь заметно слабее опасных звёзд.
	var points := [Vector2(-60, -44), Vector2(-38, -58), Vector2(-15, -36), Vector2(11, -55), Vector2(39, -42), Vector2(58, -59), Vector2(-55, 48), Vector2(-25, 57), Vector2(15, 47), Vector2(51, 58)]
	var age := 0.0
	func _process(delta: float) -> void:
		age += delta
		queue_redraw()
	func _draw() -> void:
		for i in points.size():
			var alpha := 0.10 + 0.06 * sin(age * 2.0 + i)
			draw_rect(Rect2(points[i], Vector2(1, 1)), Color(StarwalkerAttack.WHITE, alpha))
			if i < 5:
				draw_line(points[i], points[i + 1], Color(StarwalkerAttack.BLUE, 0.08), 1.0)
