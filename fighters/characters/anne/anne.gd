extends Character

const CAT_PROJECTILE := preload("res://fighters/projectiles/cat_projectile.tscn")

func do_animation(p_animation: Animations) -> Signal:
	# Проверка в родителе — мёртвый персонаж не меняет анимацию
	var parent_result = super(p_animation)
	if not alive and p_animation != Animations.FAINT and p_animation != Animations.REVIVE:
		return parent_result
	match p_animation:
		Animations.IDLE:
			$AnimatedSprite2D.play("idle")
		Animations.DAMAGED_IDLE:
			$AnimatedSprite2D.play("damaged_idle")
		Animations.DAMAGED:
			$AnimatedSprite2D.play("damaged")
		Animations.DAMAGED_DAMAGED:
			$AnimatedSprite2D.play("damaged_damaged")
		Animations.PREP_ATTACK:
			$AnimatedSprite2D.play("prep_attack")
		Animations.PREP_ACT:
			$AnimatedSprite2D.play("prep_act")
		Animations.PREP_ITEM:
			$AnimatedSprite2D.play("prep_act")
		Animations.PREP_SPARE:
			$AnimatedSprite2D.play("prep_act")
		Animations.ATTACK:
			$AnimatedSprite2D.play("attack")
		Animations.ACT:
			$AnimatedSprite2D.play("act")
		Animations.USE_ITEM:
			$AnimatedSprite2D.play("prep_act")
		Animations.DEFEND:
			$AnimatedSprite2D.play("defend")
		Animations.SPARE:
			$AnimatedSprite2D.play("act")
		Animations.FAINT:
			$AnimatedSprite2D.play("faint")
		Animations.REVIVE:
			$AnimatedSprite2D.play("idle")
		Animations.SPECIAL_CAT:
			$AnimatedSprite2D.play("special_cat")
	return $AnimatedSprite2D.animation_finished
