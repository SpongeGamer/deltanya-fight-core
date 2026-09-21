extends StaticBody2D

@onready var collision_shapes: Array[CollisionShape2D] = [
	$LeftWall, $RightWall, $TopWall, $BottomWall
]
var expanding := false
var contracting := false
var z_offset := 0
var outline_stylebox := preload("res://ui/battle/soul_cage/cage_outline.stylebox")

signal finished_animation

func expand() -> void:
	$Panel.visible = true
	expanding = true
	$Panel.scale = Vector2.ZERO
	$Panel.rotation_degrees = -180.0
	var tween := get_tree().create_tween().set_parallel(true)
	tween.tween_property($Panel, "scale", Vector2.ONE, 0.5)
	tween.tween_property($Panel, "rotation_degrees", 0.0, 0.5)
	tween.finished.connect(finish_expanding)
	z_offset = 0

func contract() -> void:
	contracting = true
	var tween := get_tree().create_tween().set_parallel(true)
	tween.tween_property($Panel, "scale", Vector2.ZERO, 0.5)
	tween.tween_property($Panel, "rotation_degrees", -180.0, 0.5)
	tween.finished.connect(finish_contracting)
	z_offset = 0

func finish_expanding() -> void:
	expanding = false
	for wall: CollisionShape2D in collision_shapes:
		wall.disabled = false

func finish_contracting() -> void:
	contracting = false
	for wall: CollisionShape2D in collision_shapes:
		wall.disabled = true

# ── Плавное изменение размера коробки ──────────────────────────────────────
func resize(new_size: Vector2, duration: float = 0.45) -> void:
	var half := new_size / 2.0
	var tween := get_tree().create_tween().set_parallel(true)
	# Двигаем Panel (Control с anchor=center)
	tween.tween_property($Panel, "offset_left",   -half.x, duration)
	tween.tween_property($Panel, "offset_top",    -half.y, duration)
	tween.tween_property($Panel, "offset_right",   half.x, duration)
	tween.tween_property($Panel, "offset_bottom",  half.y, duration)
	tween.tween_property($Panel, "pivot_offset",   half,   duration)
	tween.tween_property($Panel, "custom_minimum_size", new_size, duration)
	# Двигаем стены (немного внутрь от края — на 2px, как в оригинале)
	tween.tween_property($LeftWall,   "position", Vector2(-(half.x - 2.0), 0.0), duration)
	tween.tween_property($RightWall,  "position", Vector2( (half.x - 2.0), 0.0), duration)
	tween.tween_property($TopWall,    "position", Vector2(0.0, -(half.y - 2.0)), duration)
	tween.tween_property($BottomWall, "position", Vector2(0.0,  (half.y - 2.0)), duration)
	# Обновляем длину стен (чтобы коллизия перекрывала новый размер)
	var shape_h := (collision_shapes[0].shape as RectangleShape2D).duplicate()
	shape_h.size = Vector2(4.0, new_size.y)
	$LeftWall.shape  = shape_h
	$RightWall.shape = shape_h.duplicate()
	var shape_v := (collision_shapes[2].shape as RectangleShape2D).duplicate()
	shape_v.size = Vector2(4.0, new_size.x)
	$TopWall.shape    = shape_v
	$BottomWall.shape = shape_v.duplicate()

func _process(delta: float) -> void:
	if expanding or contracting:
		var new_panel: Panel = $Panel.duplicate()
		new_panel.add_theme_stylebox_override("panel", outline_stylebox)
		new_panel.z_index = z_offset
		z_offset += 1
		$Copies.add_child(new_panel)
	if $Copies.get_child_count() != 0:
		var children := $Copies.get_child_count()
		for child: Panel in $Copies.get_children():
			child.modulate.a -= 5.0 * delta
			if child.modulate.a <= 0.0:
				child.queue_free()
				children -= 1
		if children <= 0:
			finished_animation.emit()
