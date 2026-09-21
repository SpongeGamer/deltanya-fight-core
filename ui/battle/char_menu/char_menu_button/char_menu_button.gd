@tool
extends Sprite2D
class_name CharMenuButton

const ORANGE := Color("#ff7f27")
const YELLOW := Color("#ffff00")
const FLASH := Color("#e0d5c0")

var tween: Tween

@export_range(0, 5) var sprite := 0:
	set(p_sprite):
		sprite = p_sprite
		region_rect.position.x = 31 * sprite
		$Title.region_rect.position.x = 31 * sprite
@export var selected := false:
	set(p_selected):
		selected = p_selected
		if selected and activated:
			self_modulate = YELLOW
			$Title.modulate = YELLOW
		else:
			self_modulate = ORANGE
			$Title.modulate = Color.TRANSPARENT
var activated := false:
	set(p_activated):
		activated = p_activated

@export var flashing := false:
	set(p_flashing):
		flashing = p_flashing
		flash_amount = 0.0
		if flashing:
			$AnimationPlayer.play("flash")
		else:
			$AnimationPlayer.stop()
@export var flash_amount := 0.0:
	set(p_flash_amount):
		flash_amount = p_flash_amount
		if selected:
			self_modulate = YELLOW.lerp(FLASH, flash_amount)
			$Title.modulate = YELLOW.lerp(FLASH, flash_amount)
		elif activated:
			self_modulate = ORANGE.lerp(FLASH, flash_amount)
			$Title.modulate = Color.TRANSPARENT.lerp(FLASH, flash_amount)
		else:
			self_modulate = ORANGE
			$Title.modulate = Color.TRANSPARENT
