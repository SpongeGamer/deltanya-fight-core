extends Monster
class_name Clippy

const PAPER_STORM := preload("res://fighters/monsters/clippy/attacks/paper_storm/paper_storm.tscn")
const POINT_ATTACK := preload("res://fighters/monsters/clippy/attacks/point_attack/point_attack.tscn")
const PREDICTION_LINE := preload("res://fighters/monsters/clippy/attacks/prediction_line/prediction_line.tscn")
const CLIPBOARD_RAIN := preload("res://fighters/monsters/clippy/attacks/clipboard_rain/clipboard_rain.tscn")

const TEX_IDLE       := preload("res://fighters/monsters/clippy/clippy_idle.png")
const TEX_POINT_LEFT := preload("res://fighters/monsters/clippy/clippy_point_left.png")
const TEX_HEADPHONES := preload("res://fighters/monsters/clippy/clippy_headphones.png")
const TEX_POINT_DOWN := preload("res://fighters/monsters/clippy/clippy_point_down.png")

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

	frame_timer += delta

	if frame_timer >= FRAME_SPEED:
		frame_timer = 0.0
		sprite.frame = (sprite.frame + 1) % sprite.hframes


func start_attack() -> float:
	attacks.clear()

	match attack_index:

		0:
			sprite.texture = TEX_POINT_DOWN
			sprite.hframes = 31
			sprite.frame = 0

			instantiate_attack(PAPER_STORM)

			attack_index = 1
			return 10.0


		1:
			sprite.texture = TEX_POINT_LEFT
			sprite.hframes = 30
			sprite.frame = 0

			instantiate_attack(POINT_ATTACK)

			attack_index = 2
			return 7.0


		2:
			sprite.texture = TEX_HEADPHONES
			sprite.hframes = 84
			sprite.frame = 0

			instantiate_attack(PREDICTION_LINE)

			attack_index = 3
			return 10.0


		3:
			sprite.texture = TEX_POINT_DOWN
			sprite.hframes = 31
			sprite.frame = 0

			instantiate_attack(CLIPBOARD_RAIN)

			attack_index = 0
			return 5.5

	return 6.0


func end_attack() -> void:
	super()

	sprite.texture = TEX_IDLE
	sprite.hframes = 33
	sprite.frame = 0
