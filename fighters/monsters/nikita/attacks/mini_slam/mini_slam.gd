extends Node2D

const ATTACK_FIELD := preload("res://fighters/monsters/nikita/attacks/common/attack_field.gd")
var _projectiles: Node2D
## Мини делает большой замах, а удар выходит маленьким, но настоящим.
const PELLET := preload("res://pellets/generic_pellet/generic_pellet.tscn")
var _target := Vector2.ZERO
var _age := 0.0
var _warning := false
var _flash := 0.0

func _ready() -> void:
	_projectiles = ATTACK_FIELD.make(self)
	call_deferred("_run")

func get_duration() -> float:
	return 6.8

func _run() -> void:
	await _wait(0.5)
	for i in 3:
		var soul := get_tree().get_first_node_in_group("soul") as Soul
		var pos := to_local(soul.global_position) if is_instance_valid(soul) else Vector2.ZERO
		_target = pos.clamp(Vector2(-45, -45), Vector2(45, 45))
		_warning = true
		_age = 0.0
		await _wait(1.1)
		_warning = false
		_flash = 0.45
		Sounds.play("snd_impact", 0.3)
		for k in 6:
			var dir := Vector2.RIGHT.rotated(TAU * k / 6.0 + i * 0.25)
			var p := PELLET.instantiate() as GenericPellet
			p.position = _target + dir * 4.0
			p.velocity = dir * 48.0
			p.life_time = 1.1
			p.damage = 5
			p.graze_points = 2
			p.time_points = 0.04
			p.get_node("Sprite").modulate = Color("ffb884")
			p.body_entered.connect(p._on_body_entered)
			_projectiles.add_child(p)
		await _wait(0.65)

func _wait(duration: float) -> Signal:
	var timer := Timer.new()
	timer.one_shot = true
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(timer)
	timer.timeout.connect(timer.queue_free)
	timer.start(duration)
	return timer.timeout

func _process(delta: float) -> void:
	_age += delta
	_flash = maxf(0.0, _flash - delta)
	queue_redraw()

func _draw() -> void:
	if _warning:
		var t := clampf(_age / 1.1, 0.0, 1.0)
		var col := Color(1.0, 0.66, 0.4, 0.35 + 0.5 * t)
		draw_arc(_target, 19.0 - t * 9.0, 0, TAU, 32, col, 2.0)
		draw_line(_target - Vector2(5, 0), _target + Vector2(5, 0), col, 1.0)
		draw_line(_target - Vector2(0, 5), _target + Vector2(0, 5), col, 1.0)
	if _flash > 0.0:
		draw_arc(_target, 4.0 + (0.45 - _flash) * 55.0, 0, TAU, 24, Color(1.0, 0.8, 0.6, _flash * 2.0), 2.0)
