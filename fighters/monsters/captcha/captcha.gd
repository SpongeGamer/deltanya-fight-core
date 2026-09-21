extends Monster
class_name Captcha

const SYMBOL_RAIN   := preload("res://fighters/monsters/captcha/attacks/symbol_rain/symbol_rain.tscn")
const ORBIT_GLYPH   := preload("res://fighters/monsters/captcha/attacks/orbit_glyph/orbit_glyph.tscn")
const GRID_TEST     := preload("res://fighters/monsters/captcha/attacks/grid_test/grid_test.tscn")

const TEX_IDLE      := preload("res://fighters/monsters/captcha/captcha_idle.png")
const TEX_THINKING  := preload("res://fighters/monsters/captcha/captcha_thinking.png")
const TEX_ANGRY     := preload("res://fighters/monsters/captcha/captcha_angry.png")

var frame_timer : float = 0.0
const FRAME_SPEED   : float = 0.18

var attack_index : int = 0

# Флаг — игрок успешно прошёл хотя бы один тест (нужен для spare)
var tests_passed : int = 0


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
			# Symbol Rain — символы сыплются сверху волнами
			sprite.texture = TEX_THINKING
			sprite.hframes = 4
			sprite.frame   = 0
			instantiate_attack(SYMBOL_RAIN)
			attack_index   = 1
			return 9.0

		1:
			# Orbit Glyph — глифы вращаются, срываются к soul
			sprite.texture = TEX_ANGRY
			sprite.hframes = 4
			sprite.frame   = 0
			instantiate_attack(ORBIT_GLYPH)
			attack_index   = 2
			return 10.0

		2:
			# Grid Test — сетка «тикает», потом падает колоннами
			sprite.texture = TEX_THINKING
			sprite.hframes = 4
			sprite.frame   = 0
			instantiate_attack(GRID_TEST)
			attack_index   = 0
			return 9.0

	return 6.0


func end_attack() -> void:
	super()
	sprite.texture = TEX_IDLE
	sprite.hframes = 6
	sprite.frame   = 0


# Вызывается из GridTest когда игрок нашёл «безопасный коридор»
func on_test_passed() -> void:
	tests_passed += 1
