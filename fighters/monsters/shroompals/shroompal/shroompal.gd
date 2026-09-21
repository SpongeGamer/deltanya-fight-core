extends Monster
class_name ShroomPal

const SPORE_RAIN    := preload("res://fighters/monsters/shroompals/shroompal/attacks/spore_rain/spore_rain.tscn")
const MYCELIUM_WEB  := preload("res://fighters/monsters/shroompals/shroompal/attacks/mycelium_web/mycelium_web.tscn")
const SPORE_BURST := preload("res://fighters/monsters/shroompals/shroompal/attacks/spore_burst/spore_burst.tscn")
const PULSE_RINGS := preload("res://fighters/monsters/shroompals/shroompal/attacks/pulse_rings/pulse_rings.tscn")

const TEX_IDLE      := preload("res://fighters/monsters/shroompals/shroompal/shroompal_idle.png")
const TEX_ATTACK    := preload("res://fighters/monsters/shroompals/shroompal/shroompal_idle.png")

var frame_timer : float = 0.0
const FRAME_SPEED   : float = 0.18
var attack_index    : int   = 0


func do_animation(p_animation: Animations) -> Signal:
	match p_animation:
		Animations.HURT:
			$AnimationPlayer.play("hurt")
		Animations.SPARE:
			$AnimationPlayer.play("spare")
		Animations.FAINT:
			$AnimationPlayer.play("die")
	return $AnimationPlayer.animation_finished


func _physics_process(delta: float) -> void:
	if shake > 0.0 or hurting or dying:
		return
	frame_timer += delta
	if frame_timer >= FRAME_SPEED:
		frame_timer = 0.0
		sprite.frame = (sprite.frame + 1) % sprite.hframes


func start_attack() -> float:
	attacks.clear()
	match attack_index:
		0:
			sprite.texture = TEX_ATTACK
			sprite.hframes = 1
			sprite.frame   = 0
			instantiate_attack(SPORE_RAIN)
			attack_index   = 1
			return 8.0
		1:
			sprite.texture = TEX_ATTACK
			sprite.hframes = 1
			sprite.frame   = 0
			instantiate_attack(MYCELIUM_WEB)
			attack_index   = 2
			return 12.0
		2:
			sprite.texture = TEX_ATTACK
			sprite.hframes = 1
			sprite.frame   = 0
			instantiate_attack(PULSE_RINGS)
			attack_index   = 3
			return 8.0
		3:
			sprite.texture = TEX_ATTACK
			sprite.hframes = 1
			sprite.frame   = 0
			instantiate_attack(SPORE_BURST)
			attack_index   = 0
			return 8.0
			
	return 6.0


func end_attack() -> void:
	super()
	sprite.texture = TEX_IDLE
	sprite.hframes = 1
	sprite.frame   = 0
