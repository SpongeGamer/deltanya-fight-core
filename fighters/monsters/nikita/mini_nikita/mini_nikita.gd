extends Monster
class_name MiniNikita

const ATTACK_FAHH   := preload("res://fighters/monsters/nikita/attacks/fahh/fahh.tscn")
const ATTACK_MINI_SLAM := preload("res://fighters/monsters/nikita/attacks/mini_slam/mini_slam.tscn")
const ATTACK_KSYUHA := preload("res://fighters/monsters/nikita/attacks/ksyuha/ksyuha.tscn")

var attack_index := 0

func _ready() -> void:
	super()
	add_to_group("nikita_mini")
	_asp().play("idle")


func _asp() -> AnimatedSprite2D:
	return $AnimatedSprite2D


# ── Анимации ──────────────────────────────────────────────────────────────────

# A small pixel burst, deliberately separate from the hitbox and battle logic.
class PopEffect extends Node2D:
	var age := 0.0
	const DURATION := 0.42
	const COLORS := [Color("fff1d4"), Color("e9c7aa"), Color("ac7667"), Color("ffffff")]

	func _process(delta: float) -> void:
		age += delta
		queue_redraw()
		if age >= DURATION:
			queue_free()

	func _draw() -> void:
		var t := clampf(age / DURATION, 0.0, 1.0)
		for i in range(12):
			var angle := TAU * float(i) / 12.0
			var distance := 5.0 + t * (15.0 + float(i % 3) * 4.0)
			var point := (Vector2.RIGHT.rotated(angle) * distance).round()
			var color: Color = COLORS[i % COLORS.size()]
			color.a = 1.0 - t
			var size := 3.0 if i % 2 == 0 else 2.0
			draw_rect(Rect2(point - Vector2.ONE * size / 2.0, Vector2.ONE * size), color)
		if t < 0.55:
			draw_arc(Vector2.ZERO, 4.0 + 15.0 * t, 0.0, TAU, 16, Color(1.0, 0.9, 0.76, (0.55 - t) * 1.5), 1.0)

func do_animation(p_animation: Animations) -> Signal:
	var asp := _asp()
	match p_animation:
		Animations.HURT:
			asp.speed_scale = 1.0
			asp.play("damaged")
			shake_sprite(2.0)
			var timer := get_tree().create_timer(0.3)
			timer.timeout.connect(_finish_hurt_visual)
			return timer.timeout
		Animations.FAINT:
			shake = 0.0
			asp.position = Vector2.ZERO
			asp.play("faint")
			var original_scale := asp.scale
			var tween := create_tween()
			# Сначала видны все кадры падения, включая лежащего Мини-Никиту.
			tween.tween_property(asp, "position:y", 14.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_interval(1.55)
			tween.tween_property(asp, "scale", original_scale * Vector2(1.16, 0.8), 0.10)
			tween.tween_property(asp, "scale", original_scale * Vector2(1.22, 1.22), 0.12)
			tween.tween_callback(_pop)
			tween.tween_interval(PopEffect.DURATION)
			return tween.finished
	return super.do_animation(p_animation)

func _finish_hurt_visual() -> void:
	if not dying and is_instance_valid(_asp()):
		_asp().speed_scale = 1.0
		_asp().play("idle")

func _pop() -> void:
	_asp().hide()
	var effect := PopEffect.new()
	add_child(effect)
	effect.position = _asp().position
	Sounds.play("snd_noise", 0.5)


# ── Атаки ─────────────────────────────────────────────────────────────────────

func start_attack() -> float:
	attacks.clear()
	var scene: PackedScene
	match attack_index:
		0:
			_asp().play("idle")
			scene = ATTACK_FAHH
		1:
			_set_anim("attack_ksyuha", 1.8)
			scene = ATTACK_KSYUHA
		_:
			_set_anim("attack_slam", 1.0)
			scene = ATTACK_MINI_SLAM
	attack_index = (attack_index + 1) % 3
	var attack := _launch_attack(scene)
	return attack.call("get_duration") if attack.has_method("get_duration") else 6.0

func _set_anim(anim_name: String, speed: float) -> void:
	var asp := _asp()
	asp.speed_scale = speed
	if asp.sprite_frames.has_animation(anim_name):
		asp.play(anim_name)

func play_fah_salvo() -> void:
	if dying or hurting:
		return
	_asp().speed_scale = 1.0
	_asp().play("attack_fahh")
	_asp().frame = 1

func end_fah_salvo() -> void:
	if not dying and not hurting and _asp().animation == "attack_fahh":
		_asp().play("idle")

func _launch_attack(scene: PackedScene) -> Node2D:
	var attack := scene.instantiate() as Node2D
	if scene == ATTACK_FAHH:
		attack.set("caster", self)
	if attack.get("phase2_mode") != null:
		attack.set("phase2_mode", true)
	if attack.get("mini_variant") != null:
		attack.set("mini_variant", true)
	if attack.get("nikita_spawn_pos") != null:
		attack.set("nikita_spawn_pos", position - Global.CENTER)
	attack.position = Global.CENTER
	get_parent().add_child(attack)
	attacks.append(attack)
	return attack

func end_attack() -> void:
	super()
	_asp().play("idle")
	_asp().speed_scale = 1.0
