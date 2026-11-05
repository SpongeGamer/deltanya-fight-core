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

func do_animation(p_animation: Animations) -> Signal:
	var asp := _asp()
	var anim_name := ""
	match p_animation:
		Animations.HURT:  anim_name = "hurt"
		Animations.SPARE: anim_name = "spare"
		Animations.FAINT: anim_name = "die"
	if not anim_name.is_empty() and asp.sprite_frames.has_animation(anim_name):
		asp.play(anim_name)
		return asp.animation_finished
	return super.do_animation(p_animation)


# ── Атаки ─────────────────────────────────────────────────────────────────────

func start_attack() -> float:
	attacks.clear()
	var scene: PackedScene
	match attack_index:
		0:
			_set_anim("attack_fahh", 2.0)
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

func _launch_attack(scene: PackedScene) -> Node2D:
	var attack := scene.instantiate() as Node2D
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
