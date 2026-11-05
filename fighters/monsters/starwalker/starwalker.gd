extends Monster
class_name Starwalker
## Он — настоящий Старуолкер. Атаки сначала знакомят с правилами,
## затем повторяются по кругу, не полагаясь на случайную комбинацию.

const ATTACKS: Array[PackedScene] = [
	preload("res://fighters/monsters/starwalker/attacks/star_shower/star_shower.tscn"),
	preload("res://fighters/monsters/starwalker/attacks/wing_wave/wing_wave.tscn"),
	preload("res://fighters/monsters/starwalker/attacks/star_stream/star_stream.tscn"),
	preload("res://fighters/monsters/starwalker/attacks/star_drift/star_drift.tscn"),
	preload("res://fighters/monsters/starwalker/attacks/true_starwalker/true_starwalker.tscn"),
]
const TEX_IDLE := preload("res://fighters/monsters/starwalker/starwalker_idle.png")
const TEX_ATTACK := preload("res://fighters/monsters/starwalker/attacks/star_shower/res/starwalker_regular_attack.png")
const TEX_WING := preload("res://fighters/monsters/starwalker/attacks/wing_wave/res/starwalker_wing_attack.png")
const HINTS: Array[String] = [
	"  * Старуолкер смотрит на потолок. Там мерцают звезды.",
	"  * Старуолкер готовится взмахнуть крыльями.",
	"  * Старуолкер призывает поток звезд.",
	"  * Старуолкер прокладывает звездный путь.",
	"  * Настоящий Старуолкер должен как-то отличаться.",
]
const FRAME_SPEED := 0.15
var frame_timer := 0.0
var attack_index := 0
var _chicken_reaction := false

func do_animation(p_animation: Animations) -> Signal:
	match p_animation:
		Animations.HURT: $AnimationPlayer.play("hurt")
		Animations.SPARE: $AnimationPlayer.play("spare")
		Animations.FAINT: $AnimationPlayer.play("die")
	return $AnimationPlayer.animation_finished

func _physics_process(delta: float) -> void:
	if shake > 0.0 or hurting or dying or $AnimationPlayer.is_playing():
		return
	frame_timer += delta
	if frame_timer >= FRAME_SPEED:
		frame_timer = fmod(frame_timer, FRAME_SPEED)
		sprite.frame = (sprite.frame + 1) % sprite.hframes

func react_to_chicken() -> void:
	_chicken_reaction = true

func attack_pulse() -> void:
	if not is_instance_valid(sprite) or dying:
		return
	sprite.scale = Vector2(1.09, 0.92)
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func start_attack() -> float:
	attacks.clear()
	var index := attack_index
	attack_index = (attack_index + 1) % ATTACKS.size()
	sprite.texture = TEX_ATTACK if index == 0 else TEX_WING
	sprite.hframes = 2 if index == 0 else 5
	sprite.frame = 0
	var attack := ATTACKS[index].instantiate() as StarwalkerAttack
	attack.chicken_reaction = _chicken_reaction
	attack.caster = self
	_chicken_reaction = false
	attack.position = Global.CENTER
	get_parent().add_child(attack)
	attacks.append(attack)
	return attack.get_duration()

func end_attack() -> void:
	super()
	sprite.texture = TEX_IDLE
	sprite.hframes = 5
	sprite.frame = 0
	sprite.scale = Vector2.ONE

func get_idle_line() -> String:
	if _chicken_reaction:
		return "  * Старуолкер недоволен сравнением с курицей."
	return HINTS[attack_index] if randf() < 0.6 else super()
