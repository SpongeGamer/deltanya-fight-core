extends Monster
class_name GateGuard

const BARRIER_SLAM  := preload("res://fighters/monsters/gateguard/attacks/barrier_slam/barrier_slam.tscn")
const ACCESS_DENIED := preload("res://fighters/monsters/gateguard/attacks/access_denied/access_denied.tscn")
const PATROL_ZONE   := preload("res://fighters/monsters/gateguard/attacks/patrol_zone/patrol_zone.tscn")

#const TEX_IDLE      := preload("res://fighters/monsters/gate_guard/gate_guard_idle.png")
#const TEX_ALERT     := preload("res://fighters/monsters/gate_guard/gate_guard_alert.png")
#const TEX_SLAM      := preload("res://fighters/monsters/gate_guard/gate_guard_slam.png")

var attack_index : int = 0

func do_animation(p_animation: Animations) -> Signal:
	match p_animation:
		Animations.HURT:
			$AnimationPlayer.play("hurt")
		Animations.SPARE:
			$AnimationPlayer.play("spare")
		Animations.FAINT:
			$AnimationPlayer.play("die")
	return $AnimationPlayer.animation_finished


func start_attack() -> float:
	attacks.clear()

	match attack_index:

		0:
			# Barrier Slam — шлагбаум опускается несколько раз
			#sprite.texture = TEX_SLAM
			instantiate_attack(BARRIER_SLAM)
			attack_index = 1
			return 8.0

		1:
			# Access Denied — таблички летят с двух сторон, нужно найти зазор
			#sprite.texture = TEX_ALERT
			instantiate_attack(ACCESS_DENIED)
			attack_index = 2
			return 9.0

		2:
			# Patrol Zone — луч сканирует арену, надо держаться за ним
			#sprite.texture = TEX_ALERT
			instantiate_attack(PATROL_ZONE)
			attack_index = 0
			return 8.0

	return 6.0


func end_attack() -> void:
	super()
	#sprite.texture = TEX_IDLE
