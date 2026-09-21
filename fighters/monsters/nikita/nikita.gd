extends Monster
class_name NikitaBoss

const ATTACK_FAHH   := preload("res://fighters/monsters/nikita/attacks/fahh/fahh.tscn")
const ATTACK_SLAM   := preload("res://fighters/monsters/nikita/attacks/slam/slam.tscn")
const ATTACK_KSYUHA := preload("res://fighters/monsters/nikita/attacks/ksyuha/ksyuha.tscn")
const MINI_NIKITA   := preload("res://fighters/monsters/nikita/mini_nikita/mini_nikita.tscn")

const PHASE2_THRESHOLD := 150

var attack_index     := 0
var phase2           := false
var _phase2_pending  := false   # HP упал — ждём своего хода атаки
var _mini_spawned    := false


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


func _set_attack_anim(anim_name: String, speed: float = 1.0) -> void:
	var asp := _asp()
	asp.speed_scale = speed
	if asp.sprite_frames.has_animation(anim_name):
		asp.play(anim_name)


# ── Вторая фаза ───────────────────────────────────────────────────────────────

func take_damage(p_character: Character, p_damage: int) -> void:
	super.take_damage(p_character, p_damage)
	# Ставим флаг — phase 2 активируется на СЛЕДУЮЩЕМ ХОДУ НИКИТЫ (в start_attack)
	if not dying and not phase2 and not _phase2_pending and current_hp <= PHASE2_THRESHOLD:
		_phase2_pending = true


func _run_phase2_transition() -> void:
	var asp := _asp()
	if asp.sprite_frames.has_animation("second_phase"):
		asp.play("second_phase")
		await asp.animation_finished
	_spawn_mini_nikita()
	asp.play("idle")
	asp.speed_scale = 1.0


func _spawn_mini_nikita() -> void:
	var mini: Monster = MINI_NIKITA.instantiate()
	get_parent().add_child(mini)
	mini.position = position + Vector2(0.0, 100.0)
	Global.monsters.append(mini)
	# Обновляем MonsterSelect — мини-Никита появляется в панели
	get_tree().call_group("monster_select_ui", "initialize_panels")


# ── Атаки ─────────────────────────────────────────────────────────────────────

func start_attack() -> float:
	attacks.clear()

	# Конец хода игрока — самое время активировать фазу 2
	if _phase2_pending:
		_phase2_pending = false
		phase2         = true
		_mini_spawned  = true
		_run_phase2_transition()   # корутина, не блокирует return
		return 6.0                 # времени должно хватить на анимацию + спавн

	match attack_index:
		0:
			_set_attack_anim("attack_fahh", 2.5)
			_launch_attack(ATTACK_FAHH, phase2)
			attack_index = 1
			return 13.0 if phase2 else 10.0
		1:
			_set_attack_anim("attack_slam", 0.6)
			_launch_attack(ATTACK_SLAM, false)  # большой Никита никогда не делает micro-трещины
			attack_index = 2
			return 14.0 if phase2 else 12.0
		_:
			_set_attack_anim("attack_ksyuha", 1.8)
			_launch_attack(ATTACK_KSYUHA, phase2)
			attack_index = 0
			return 8.0 if phase2 else 7.0

	return 8.0


func _launch_attack(scene: PackedScene, use_phase2: bool = false) -> void:
	var attack := scene.instantiate()
	if use_phase2 and attack.get("phase2_mode") != null:
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
