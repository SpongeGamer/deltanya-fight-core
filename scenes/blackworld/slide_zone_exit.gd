extends "res://scenes/prefabs/slide_zone.gd"

@export var fade_during_slide: bool = false
@export var fade_start_delay: float = 0.5
@export var fade_duration: float = 1.0
@export_file("*.tscn") var next_scene: String = ""
@export var next_spawn_point: String = "Spawnpoint"
@export var next_dark_world: bool = false

var _transition_started := false

func _on_slides_scheduled() -> void:
	if not fade_during_slide or next_scene.is_empty() or _transition_started:
		return
	_transition_started = true

	if fade_start_delay > 0.0:
		await get_tree().create_timer(fade_start_delay).timeout
	_fade_and_transition()

func _fade_and_transition() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	get_tree().current_scene.add_child(layer)
	var dark_rect := ColorRect.new()
	dark_rect.color = Color.BLACK
	dark_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dark_rect.modulate.a = 0.0
	layer.add_child(dark_rect)
	var tween := create_tween()
	tween.tween_property(dark_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished
	SceneTransition.travel(next_scene, next_spawn_point, next_dark_world, true, 2.0)

func _finish_slide() -> void:
	# The new scene owns movement once the transition starts.
	if not _transition_started:
		super._finish_slide()

func reset_zone() -> void:
	super.reset_zone()
	if auto_reset:
		_transition_started = false
