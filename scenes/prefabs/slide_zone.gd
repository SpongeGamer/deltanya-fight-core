extends Area2D

@export var slide_duration: float = 1.5
@export var slide_distance: float = 200.0
@export var slide_sound: String = "snd_noise"
@export var slide_animation_name: String = "slide"
@export var auto_reset: bool = false
@export var gathering_point: Node2D = null
@export var companions_slide: bool = true
@export var companions_delay: float = 0.1
@export var target_after_slide: Node2D = null
@export var target_animation: String = "activate"
@export var disable_collision_after: bool = true

var _player_in := false
var _player = null
var _companions: Array = []
var _is_sliding := false
var _has_triggered := false
var _original_player_last_direction := Vector2.DOWN
var _sliders_total := 0
var _sliders_started := 0
var _sliders_completed := 0

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _has_triggered:
		_player_in = true
		_player = body
		_trigger_slide()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in = false

func _trigger_slide() -> void:
	if _is_sliding or _has_triggered or not is_instance_valid(_player):
		return
	_has_triggered = true
	_is_sliding = true
	_original_player_last_direction = _player.last_direction
	_companions.clear()
	if companions_slide:
		_find_companions()
	_player.can_move = false
	_player.velocity = Vector2.ZERO
	for companion in _companions:
		companion.stop_following()
	if slide_sound != "":
		Sounds.play(slide_sound)

	_sliders_total = 1 + _companions.size()
	_sliders_started = 0
	_sliders_completed = 0
	_slide_character(_player, 0.0)
	# Each path is awaited independently: no companion's signal can be missed.
	for i in range(_companions.size()):
		_slide_companion(_companions[i], companions_delay * (i + 1))
	_on_slides_scheduled()
	var tree := get_tree()
	while is_inside_tree() and _sliders_completed < _sliders_total:
		await tree.process_frame
	if is_inside_tree():
		_finish_slide()

# Overridden by the exit slide to start its transition once everyone is sliding.
func _on_slides_scheduled() -> void:
	pass

func _find_companions() -> void:
	for member in Global.party:
		for node in get_tree().get_nodes_in_group(member + "_body"):
			if node != _player and node is Companion and not _companions.has(node):
				_companions.append(node)

func _slide_companion(companion: Companion, delay: float) -> void:
	if not is_instance_valid(companion):
		_sliders_started += 1
		_sliders_completed += 1
		return
	if is_instance_valid(gathering_point):
		var path: Array[Vector2] = [gathering_point.global_position]
		companion.start_cutscene_path(path)
		await companion.cutscene_path_finished
	await _slide_character(companion, delay)

func _slide_character(character: Node2D, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if not is_instance_valid(character):
		_sliders_started += 1
		_sliders_completed += 1
		return
	# Normal movement continuously selects the idle/walk animation. Suspend it
	# while the tween owns the character, so the slide pose stays visible.
	var was_processing := character.is_physics_processing()
	character.set_physics_process(false)
	var sprite: AnimatedSprite2D = character.animated_sprite
	if is_instance_valid(sprite) and sprite.sprite_frames and not slide_animation_name.is_empty() and sprite.sprite_frames.has_animation(slide_animation_name):
		sprite.speed_scale = 1.0
		sprite.play(slide_animation_name)
	_sliders_started += 1
	var end_pos := character.global_position + Vector2(0, slide_distance)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(character, "global_position", end_pos, slide_duration)
	await tween.finished
	if is_instance_valid(character):
		character.z_index = int(character.global_position.y)
		character.set_physics_process(was_processing)
		character._play_idle_animation()
	_sliders_completed += 1

func _finish_slide() -> void:
	if is_instance_valid(_player):
		_player.last_direction = _original_player_last_direction
		_player.position_history.clear()
		_player._play_idle_animation()
		_player.can_move = true
	for companion in _companions:
		if is_instance_valid(companion):
			companion.position_history.clear()
			companion.is_moving = false
			companion.start_following()
	if is_instance_valid(target_after_slide) and target_animation != "":
		if target_after_slide.has_method(target_animation):
			target_after_slide.call(target_animation)
		elif target_after_slide.has_method("play"):
			target_after_slide.play(target_animation)
	if disable_collision_after:
		$CollisionShape2D.set_deferred("disabled", true)
	_is_sliding = false

func reset_zone() -> void:
	if auto_reset:
		_has_triggered = false
		_is_sliding = false
		if disable_collision_after:
			$CollisionShape2D.set_deferred("disabled", false)
