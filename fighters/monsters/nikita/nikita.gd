extends Monster
class_name NikitaBoss

const ATTACK_FAHH   := preload("res://fighters/monsters/nikita/attacks/fahh/fahh.tscn")
const ATTACK_SLAM   := preload("res://fighters/monsters/nikita/attacks/slam/slam.tscn")
const ATTACK_KSYUHA := preload("res://fighters/monsters/nikita/attacks/ksyuha/ksyuha.tscn")
const ATTACK_LESSON := preload("res://fighters/monsters/nikita/attacks/lesson/lesson.tscn")
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
	match p_animation:
		Animations.HURT:
			asp.speed_scale = 3.0
			asp.play("damaged")
			shake_sprite(3.0)
			var timer := get_tree().create_timer(0.5)
			timer.timeout.connect(_finish_hurt_visual)
			return timer.timeout
		Animations.FAINT:
			shake = 0.0
			asp.position = Vector2.ZERO
			asp.speed_scale = 1.0
			asp.play("idle")
			# Незаметный шаг при уходе, без растягивания спрайта.
			var steps := create_tween().set_loops(4)
			steps.tween_property(asp, "position:y", -2.0, 0.14)
			steps.tween_property(asp, "position:y", 0.0, 0.14)
			var tween := create_tween()
			tween.tween_property(asp, "position:x", 235.0, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			return tween.finished
	return super.do_animation(p_animation)

func _finish_hurt_visual() -> void:
	if not is_instance_valid(_asp()):
		return
	_asp().speed_scale = 1.0
	if not dying:
		_asp().play("damaged_idle" if phase2 else "idle")

func play_fah_salvo() -> void:
	if dying or hurting:
		return
	var asp := _asp()
	asp.speed_scale = 1.0
	asp.play("attack_fahh")
	asp.frame = 1

func end_fah_salvo() -> void:
	if not dying and not hurting and _asp().animation == "attack_fahh":
		_asp().play("idle")


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

func _mini_alive() -> bool:
	for monster in Global.monsters:
		if is_instance_valid(monster) and monster.is_in_group("nikita_mini") and not monster.dying:
			return true
	return false

func start_attack() -> float:
	attacks.clear()
	if _phase2_pending:
		_phase2_pending = false
		phase2 = true
		_mini_spawned = true
		_run_phase2_transition()
		return 6.0

	var scene: PackedScene
	var use_phase2 := phase2
	match attack_index:
		0:
			_asp().play("idle")
			scene = ATTACK_FAHH
		1:
			_set_attack_anim("attack_slam", 0.6)
			scene = ATTACK_SLAM
			use_phase2 = false # Большой Никита сохраняет обычные трещины.
		2:
			_set_attack_anim("attack_ksyuha", 1.8)
			scene = ATTACK_KSYUHA
		_:
			_set_attack_anim("attack_slam", 0.8)
			scene = ATTACK_LESSON
	attack_index = (attack_index + 1) % 4
	var attack := _launch_attack(scene, use_phase2)
	return attack.call("get_duration") if attack.has_method("get_duration") else 10.0

func _launch_attack(scene: PackedScene, use_phase2: bool = false) -> Node2D:
	var attack := scene.instantiate() as Node2D
	if scene == ATTACK_FAHH:
		attack.set("caster", self)
	if attack.get("phase2_mode") != null:
		attack.set("phase2_mode", use_phase2)
	if attack.get("nikita_spawn_pos") != null:
		attack.set("nikita_spawn_pos", position - Global.CENTER)
	if attack.get("echo_enabled") != null:
		attack.set("echo_enabled", use_phase2 and _mini_alive())
	if attack.get("mini_extra") != null:
		attack.set("mini_extra", use_phase2 and _mini_alive())
	attack.position = Global.CENTER
	get_parent().add_child(attack)
	attacks.append(attack)
	return attack

func end_attack() -> void:
	super()
	_asp().play("idle")
	_asp().speed_scale = 1.0
