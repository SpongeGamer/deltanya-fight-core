extends Monster
class_name MiniNikita

const ATTACK_FAHH   := preload("res://fighters/monsters/nikita/attacks/fahh/fahh.tscn")
const ATTACK_KSYUHA := preload("res://fighters/monsters/nikita/attacks/ksyuha/ksyuha.tscn")

var attack_index := 0


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

	match attack_index:
		0:  # FAHH
			_set_anim("attack_fahh", 2.0)
			_launch_attack(ATTACK_FAHH)
			attack_index = 1
			return 9.0

		1:  # KSYUHA
			_set_anim("attack_ksyuha", 1.8)
			_launch_attack(ATTACK_KSYUHA)
			attack_index = 2
			return 6.0

		2:  # FLY — просто анимация подлёта, снарядов нет
			_set_anim("attack_slam", 1.0)
			attack_index = 0
			# Возвращаем длину, достаточную для анимации.
			# Подбери под реальную длину анимации "fly".
			return 3.0

	return 5.0


func _set_anim(anim_name: String, speed: float) -> void:
	var asp := _asp()
	asp.speed_scale = speed
	if asp.sprite_frames.has_animation(anim_name):
		asp.play(anim_name)


func _launch_attack(scene: PackedScene) -> void:
	var attack := scene.instantiate()
	# Мини-Никита всегда использует уменьшенные версии: micro-трещины и мелкие Ксюхи
	if attack.get("phase2_mode") != null:
		attack.phase2_mode = true
	if attack.get("nikita_spawn_pos") != null:
		attack.nikita_spawn_pos = position - Global.CENTER
	get_parent().add_child(attack)
	attack.position = Global.CENTER
	attacks.append(attack)


func end_attack() -> void:
	super()
	_asp().play("idle")
	_asp().speed_scale = 1.0
