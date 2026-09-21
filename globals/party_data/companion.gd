extends CharacterBody2D
class_name Companion

@onready var _light_sprite: AnimatedSprite2D = $LightSprite
@onready var _dark_sprite: AnimatedSprite2D = $DarkSprite

@export var dark_frames: SpriteFrames = null
@export var party_key: String = ""
@export var move_speed: float = 125.0
@export var follow_distance: float = 35.0
@export var stop_distance: float = 20.0
@export var trail_frames: int = 40

var in_cutscene := false
var animated_sprite: AnimatedSprite2D
var following := false
var last_direction := Vector2.DOWN
var is_moving := false
var _idle_timer := 0.0
const IDLE_DELAY := 0.12

var position_history: Array = []
const HISTORY_SIZE := 200

# ── Новые переменные для плавной катсцены ────────────────────────────────────
var _cutscene_path: Array[Vector2] = []
var _cutscene_index: int = 0
signal cutscene_path_finished

func _ready() -> void:
	if party_key != "":
		add_to_group(party_key + "_body")

	if dark_frames != null:
		_dark_sprite.sprite_frames = dark_frames

	_apply_world(Global.is_dark_world)
	Global.dark_world_changed.connect(_apply_world)

	animated_sprite.play("idle_down")

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

# Обычное следование за игроком (оставлено без изменений)
func _physics_process(delta: float) -> void:
	position_history.append(global_position)
	if position_history.size() > HISTORY_SIZE:
		position_history.pop_front()

	if not following or in_cutscene:
		return

	var target_node := _get_follow_target()
	if not target_node:
		return

	var target_pos: Vector2 = target_node.global_position if not target_node.has_method("get_past_position") else target_node.get_past_position(trail_frames)

	var distance := global_position.distance_to(target_pos)

	if not is_moving:
		if distance > follow_distance:
			is_moving = true
	else:
		if distance < stop_distance:
			is_moving = false

	if is_moving:
		var direction := (target_pos - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
		last_direction = direction
		_idle_timer = 0.0
		_play_walk_animation(direction)
	else:
		velocity = Vector2.ZERO
		_idle_timer += delta
		if _idle_timer >= IDLE_DELAY:
			_play_idle_animation()
	z_index = int(global_position.y)

# ── ПЛАВНОЕ ДВИЖЕНИЕ ПО ТОЧКАМ В КАТЦЕНЕ (это главное изменение) ─────────────
func _process(delta: float) -> void:
	if not in_cutscene or _cutscene_path.is_empty():
		return

	if _cutscene_index >= _cutscene_path.size():
		_finish_cutscene_path()
		return

	var target := _cutscene_path[_cutscene_index]
	var direction := (target - global_position).normalized()
	var distance := global_position.distance_to(target)

	# Дошли до точки
	if distance < 2.0:
		_cutscene_index += 1
		if _cutscene_index >= _cutscene_path.size():
			_finish_cutscene_path()
			return
		# Сразу обновляем анимацию на следующую точку
		direction = (_cutscene_path[_cutscene_index] - global_position).normalized()
		last_direction = direction
		_play_walk_animation(direction)
		return

	# Плавное движение
	global_position = global_position.move_toward(target, move_speed * delta)
	last_direction = direction
	_play_walk_animation(direction)

func _finish_cutscene_path() -> void:
	# Финальный idle
	if _cutscene_path.size() > 0:
		var final_dir: Vector2 = (_cutscene_path.back() - global_position).normalized()
		if final_dir != Vector2.ZERO:
			last_direction = final_dir
	_play_idle_animation()

	in_cutscene = false
	set_process(false)
	set_physics_process(true)
	velocity = Vector2.ZERO
	cutscene_path_finished.emit()

# ── Запуск катсцены (вызывается из Helper) ───────────────────────────────────
func start_cutscene_path(path: Array[Vector2], final_direction: Vector2 = Vector2.ZERO) -> void:
	following = false
	in_cutscene = true
	set_physics_process(false)
	set_process(true)
	velocity = Vector2.ZERO

	_cutscene_path = path.duplicate()
	_cutscene_index = 0

	# Если путь пустой — сразу завершаем
	if _cutscene_path.is_empty():
		_finish_cutscene_path()
		return

	# Сразу включаем анимацию ходьбы в сторону первой точки
	var first_dir := (_cutscene_path[0] - global_position).normalized()
	last_direction = first_dir
	_play_walk_animation(first_dir)

# Остальные функции без изменений
func get_past_position(frames_ago: int) -> Vector2:
	if position_history.is_empty():
		return global_position
	var index = max(0, position_history.size() - frames_ago - 1)
	return position_history[index]

func start_following() -> void:
	following = true
	if party_key != "":
		Global.add_to_party(party_key)

func stop_following() -> void:
	following = false
	velocity = Vector2.ZERO
	_play_idle_animation()

func _get_follow_target() -> Node2D:
	var my_index := Global.party.find(party_key)
	if my_index <= 0:
		return get_tree().get_first_node_in_group("player")
	var prev_key := Global.party[my_index - 1]
	if prev_key == Global.party[0]:
		return get_tree().get_first_node_in_group("player")
	var nodes := get_tree().get_nodes_in_group(prev_key + "_body")
	return nodes[0] as Node2D if not nodes.is_empty() else get_tree().get_first_node_in_group("player")

func _play_walk_animation(direction: Vector2) -> void:
	if abs(direction.y) > abs(direction.x):
		animated_sprite.play("move_down" if direction.y > 0 else "move_up")
	else:
		animated_sprite.play("move_right" if direction.x > 0 else "move_left")

func _play_idle_animation() -> void:
	if abs(last_direction.y) > abs(last_direction.x):
		animated_sprite.play("idle_down" if last_direction.y > 0 else "idle_up")
	else:
		animated_sprite.play("idle_right" if last_direction.x > 0 else "idle_left")

func fanfare() -> void:
	Sounds.fanfare()

func cancel_rotation() -> void:
	$DarkSprite.rotation_degrees = 0

func add_to_party() -> void:
	if party_key != "":
		add_to_group(party_key + "_body")
