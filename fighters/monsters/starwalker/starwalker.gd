extends Monster
class_name Starwalker

const STAR_SHOWER := preload("res://fighters/monsters/starwalker/attacks/star_shower/star_shower.tscn")
const WING_WAVE   := preload("res://fighters/monsters/starwalker/attacks/wing_wave/wing_wave.tscn")
const STAR_DRIFT := preload("res://fighters/monsters/starwalker/attacks/star_drift/star_drift.tscn")

const TEX_IDLE   := preload("res://fighters/monsters/starwalker/starwalker_idle.png")
const TEX_ATTACK := preload("res://fighters/monsters/starwalker/attacks/star_shower/res/starwalker_regular_attack.png")
const TEX_WING   := preload("res://fighters/monsters/starwalker/attacks/wing_wave/res/starwalker_wing_attack.png")

var frame_timer: float = 0.0
const FRAME_SPEED: float = 0.15

var attack_index: int = 0

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
	
	# Анимируем КАЖДУЮ текстуру (idle + все атаки)
	frame_timer += delta
	if frame_timer >= FRAME_SPEED:
		frame_timer = 0.0
		sprite.frame = (sprite.frame + 1) % sprite.hframes


func start_attack() -> float:
	attacks.clear()

	# Каждые ~3 атаки шанс комбо STAR_DRIFT + WING_WAVE
	var do_combo := attack_index == 2 and randf() < 0.5

	match attack_index:
		0:
			sprite.texture = TEX_ATTACK
			sprite.hframes = 2
			sprite.frame = 0
			instantiate_attack(STAR_SHOWER)
			attack_index = 1
			return 6.0

		1:
			sprite.texture = TEX_WING
			sprite.hframes = 5
			sprite.frame = 0
			instantiate_attack(WING_WAVE)
			attack_index = 2
			return 5.0

		2:
			sprite.texture = TEX_WING
			sprite.hframes = 5
			sprite.frame = 0
			instantiate_attack(STAR_DRIFT)
			if do_combo:
				instantiate_attack(STAR_SHOWER)
			attack_index = 0
			return 6.5 if do_combo else 5.5

	return 6.0


func end_attack() -> void:
	super()
	sprite.texture = TEX_IDLE
	sprite.hframes = 5
	sprite.frame = 0
