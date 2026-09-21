extends CharacterBody2D

@onready var _light_sprite: AnimatedSprite2D = $LightSprite
@onready var _dark_sprite: AnimatedSprite2D = $DarkSprite

@export var dark_frames: SpriteFrames = null

const max_speed: int = 125
const acceleration: float = 22.5
const friction: float = 16.5

var can_move: bool = true
var last_direction: Vector2 = Vector2.DOWN

var position_history: Array = []
const HISTORY_SIZE: int = 150

const InventoryScene := preload("res://ui/overworld/overworld_inventory.tscn")
var inventory_open := false
var inventory_ref: Control = null

var animated_sprite: AnimatedSprite2D   # активный спрайт (меняется при смене мира)

# Катсцена — движение по точкам
var _cutscene_path: Array[Vector2] = []
var _cutscene_index: int = 0
signal cutscene_path_finished

func _ready() -> void:
	# Защита от дубликатов — если игрок уже есть в сцене, удаляем себя
	var existing = get_tree().get_first_node_in_group("player")
	if existing != null and existing != self:
		queue_free()
		return
	add_to_group("player")
	if dark_frames != null:
		_dark_sprite.sprite_frames = dark_frames
	_apply_world(Global.is_dark_world)
	Global.dark_world_changed.connect(_apply_world)
	CameraController.instance.start_follow(self, Vector2(0, -16))

## Переключает видимый спрайт и обновляет ссылку animated_sprite.
func _apply_world(is_dark: bool) -> void:
	if is_dark:
		animated_sprite = _dark_sprite
		_light_sprite.visible = false
		_dark_sprite.visible = true
	else:
		animated_sprite = _light_sprite
		_dark_sprite.visible = false
		_light_sprite.visible = true
	if animated_sprite.sprite_frames != null:
		_play_idle_animation()

func _unhandled_key_input(event: InputEvent) -> void:
	if Global.battle_in_progress:
		return
	
	if event.is_action_pressed("settings_menu"):
		if not Global.battle_in_progress and can_move:
			var settings := get_tree().get_first_node_in_group("settings_menu")
			if settings and settings.has_method("open"):
				settings.open()
		return

	if event.is_action_pressed("inventory"):
		if Global.battle_in_progress:
			return
		if inventory_open:
			if is_instance_valid(inventory_ref):
				inventory_ref._close()
		elif can_move:
			_open_inventory()
		return

func _open_inventory() -> void:
	inventory_open = true
	can_move = false
	var cl := CanvasLayer.new()
	cl.layer = 10
	get_tree().current_scene.add_child(cl)
	var inv := InventoryScene.instantiate()
	cl.add_child(inv)
	inventory_ref = inv
	inv.tree_exiting.connect(_on_inventory_closed)

func _on_inventory_closed() -> void:
	inventory_open = false
	can_move = true
	inventory_ref = null

func _physics_process(delta: float) -> void:
	position_history.append(global_position)
	if position_history.size() > HISTORY_SIZE:
		position_history.pop_front()
		
	if Global.battle_in_progress:
		velocity = Vector2.ZERO
		_play_idle_animation()
		return

	if !can_move:
		_play_idle_animation()
		return

	var input = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()

	if input:
		last_direction = input
		_play_walk_animation(input)
		animated_sprite.speed_scale = ((velocity / max_speed).distance_to(Vector2.ZERO) * 1.65) + 0.5
	else:
		_play_idle_animation()

	var lerp_weight = delta * (acceleration if input else friction)
	velocity = lerp(velocity, input * max_speed, lerp_weight)
	move_and_slide()
	z_index = int(global_position.y)

func get_past_position(frames_ago: int) -> Vector2:
	if position_history.is_empty():
		return global_position
	var index = max(0, position_history.size() - frames_ago - 1)
	return position_history[index]

func _play_walk_animation(input: Vector2) -> void:
	if abs(input.y) > abs(input.x):
		animated_sprite.play("move_down" if input.y > 0 else "move_up")
	else:
		animated_sprite.play("move_right" if input.x > 0 else "move_left")

func _play_idle_animation() -> void:
	if abs(last_direction.y) > abs(last_direction.x):
		animated_sprite.play("idle_down" if last_direction.y > 0 else "idle_up")
	else:
		animated_sprite.play("idle_right" if last_direction.x > 0 else "idle_left")

# ─── КАТСЦЕНА — ДВИЖЕНИЕ ПО ТОЧКАМ ────────────────────────────────────────────
func start_cutscene_path(path: Array[Vector2]) -> void:
	can_move = false
	_cutscene_path = path.duplicate()
	_cutscene_index = 0
	set_physics_process(false)
	set_process(true)

func _process(delta: float) -> void:
	if _cutscene_path.is_empty() or _cutscene_index >= _cutscene_path.size():
		if _cutscene_path.size() > 0:
			_play_idle_animation()
			can_move = false
			set_process(false)
			set_physics_process(true)
			cutscene_path_finished.emit()
		return
	
	var target := _cutscene_path[_cutscene_index]
	var direction := (target - global_position).normalized()
	var distance := global_position.distance_to(target)
	
	if distance < 2.0:
		_cutscene_index += 1
		return
	
	global_position = global_position.move_toward(target, max_speed * delta)
	_play_walk_animation(direction)

## Остановить катсцену (если нужно прервать)
func stop_cutscene_path() -> void:
	_cutscene_path.clear()
	_cutscene_index = 0
	set_process(false)
	set_physics_process(true)
	_play_idle_animation()

## Заморозить игрока (запретить движение).
## Вызывай перед запуском диалога или катсцены.
func freeze_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false
 
## Разморозить игрока (разрешить движение).
## Вызывай после окончания диалога или катсцены.
func unfreeze_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = true
