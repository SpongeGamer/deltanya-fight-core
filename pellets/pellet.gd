extends Area2D
class_name Pellet

signal justice_shotted(shot_direction : float)

enum HitRule {
	ANY,
	ORANGE_MOVE, # оранжевый: безопасно, если двигаешься (значит "иди")
	BLUE_STAND,  # синий: безопасно, если стоишь (значит "стой")
}

@export var damage := 1
## The amount of TP gained by grazing
@export var graze_points := 5
## How much the turn timer is reduced when grazing (in seconds)
@export var time_points := 5.0 / 30.0
##Whether the pellet is repelled by a shield.
@export var shield_repelled : bool = false
##Whether the pellet is destroyed by yellow soul bullets.
@export var anti_justice : bool = false
@export var hit_rule: HitRule = HitRule.ANY

var grazed := false

func _on_body_entered(body: Node2D) -> void:
	if body is Soul:
		var soul := body as Soul
		match hit_rule:
			HitRule.ANY:
				soul.hurt(damage)
			HitRule.ORANGE_MOVE:
				if not soul.is_moving():
					soul.hurt(damage)
			HitRule.BLUE_STAND:
				if soul.is_moving():
					soul.hurt(damage)
