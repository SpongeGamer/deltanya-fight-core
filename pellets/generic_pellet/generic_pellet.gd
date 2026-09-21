@tool
extends Pellet
class_name GenericPellet

@export var life_time := 2.0
@export var linear_acceleration := 0.0
@export var angular_velocity := 0.0

@export var rotate_sprite := false:
	set(p_rotate_sprite):
		rotate_sprite = p_rotate_sprite
		if !rotate_sprite and $Sprite:
			$Sprite.rotation = 0.0
@export_enum("Circle", "Diamond") var shape := 0:
	set(p_shape):
		shape = p_shape
		if get_node_or_null("Sprite") != null:
			$Sprite.region_rect.position.x = 16 * shape

var time := 0.0
var velocity := Vector2.ZERO

func _ready() -> void:
	if $Sprite:
		$Sprite.region_rect.position.x = 16 * shape

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	time += delta
	velocity += velocity.normalized() * linear_acceleration * delta
	velocity = velocity.rotated(deg_to_rad(angular_velocity) * delta)
	if time >= life_time:
		queue_free()
	if rotate_sprite:
		$Sprite.rotation = velocity.angle()
	position += velocity * delta
