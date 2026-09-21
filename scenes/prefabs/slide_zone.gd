extends Area2D

## Настройки скольжения
@export var slide_duration: float = 1.5
@export var slide_distance: float = 200.0
@export var slide_sound: String = "snd_noise"
@export var slide_animation_name: String = "slide"
@export var auto_reset: bool = false

## Точка сбора перед скольжением (куда компаньоны должны подойти)
@export var gathering_point: Node2D = null

## Настройки компаньонов
@export var companions_slide: bool = true
@export var companions_delay: float = 0.1

## Дополнительные действия
@export var target_after_slide: Node2D = null
@export var target_animation: String = "activate"
@export var disable_collision_after: bool = true

var _player_in: bool = false
var _player = null
var _companions: Array = []
var _is_sliding: bool = false
var _original_player_speed: float = 0.0
var _has_triggered: bool = false
var _original_player_last_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	body_entered.connect(_on_body_entered)
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
	if _is_sliding or _has_triggered:
		return
	
	_has_triggered = true
	_is_sliding = true
	
	# Сохраняем направление игрока
	if "last_direction" in _player:
		_original_player_last_direction = _player.last_direction
	
	# Находим всех компаньонов
	if companions_slide:
		_find_companions()
	
	# Сохраняем оригинальную скорость игрока
	if _player.has_method("get_move_speed"):
		_original_player_speed = _player.get_move_speed()
	elif "move_speed" in _player:
		_original_player_speed = _player.move_speed
	else:
		_original_player_speed = 125.0
	
	# Отключаем управление у игрока
	_player.can_move = false
	
	# Отключаем следование у компаньонов
	for companion in _companions:
		if companion.has_method("stop_following"):
			companion.stop_following()
		if companion.has_method("set_can_move"):
			companion.can_move = false
	
	# Проигрываем звук
	if slide_sound != "":
		Sounds.play(slide_sound)
	
	# ЗАПУСКАЕМ СКОЛЬЖЕНИЕ ИГРОКА СРАЗУ
	_slide_character(_player, 0.0)
	
	# ЗАПУСКАЕМ КОМПАНЬОНОВ: сначала идут к точке, потом скользят
	if gathering_point:
		_send_companions_to_gathering_point_and_slide()
	else:
		# Если точки нет — скользят сразу с задержкой
		for i in range(_companions.size()):
			var companion = _companions[i]
			var delay = companions_delay * (i + 1)
			_slide_character(companion, delay)
	
	# Ждём окончания скольжения игрока
	await get_tree().create_timer(slide_duration).timeout
	
	_finish_slide()

func _send_companions_to_gathering_point_and_slide() -> void:
	if not gathering_point:
		return
	
	var target_pos: Vector2 = gathering_point.global_position
	
	# Отправляем каждого компаньона к точке
	for companion in _companions:
		if companion.has_method("start_cutscene_path"):
			var path: Array[Vector2] = [target_pos]
			companion.start_cutscene_path(path)
	
	# Ждём пока все компаньоны дойдут до точки
	for companion in _companions:
		if companion.has_signal("cutscene_path_finished"):
			await companion.cutscene_path_finished
	
	print("All companions reached gathering point")
	
	# Теперь все у точки — запускаем скольжение компаньонов с задержкой
	for i in range(_companions.size()):
		var companion = _companions[i]
		var delay = companions_delay * (i + 1)
		_slide_character(companion, delay)

func _find_companions() -> void:
	_companions.clear()
	
	for member in Global.party:
		var nodes = get_tree().get_nodes_in_group(member + "_body")
		for node in nodes:
			if node != _player and node is Node2D:
				_companions.append(node)
	
	print("Found companions: ", _companions.size())

func _slide_character(character, delay: float) -> void:
	if character == null:
		return
	
	var end_pos: Vector2 = Vector2(character.global_position.x, character.global_position.y + slide_distance)
	
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(character, "global_position", end_pos, slide_duration)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	
	# Запускаем анимацию скольжения
	if slide_animation_name != "" and "animated_sprite" in character:
		var sprite = character.animated_sprite
		if sprite and sprite is AnimatedSprite2D:
			# ПРОСТО ПЫТАЕМСЯ ЗАПУСТИТЬ — если анимации нет, будет ошибка в логе
			sprite.play(slide_animation_name)
			print("Trying to play animation '", slide_animation_name, "' on: ", character.name)
			
			# Проверяем какая анимация сейчас играет
			print("Current animation: ", sprite.animation)

func _finish_slide() -> void:
	# Включаем управление игроку
	if _player:
		_player.can_move = true
	
	# Возвращаем скорость игроку
	if _original_player_speed != 0.0:
		if _player.has_method("set_move_speed"):
			_player.set_move_speed(_original_player_speed)
		elif "move_speed" in _player:
			_player.move_speed = _original_player_speed
	
	# Возвращаем анимацию игроку
	if _player and _player.has_method("_play_idle_animation"):
		_player.last_direction = _original_player_last_direction
		_player._play_idle_animation()
	
	# Возвращаем следование компаньонам
	for companion in _companions:
		if companion.has_method("start_following"):
			companion.start_following()
		if companion.has_method("set_can_move"):
			companion.can_move = true
		if companion.has_method("_play_idle_animation"):
			companion._play_idle_animation()
	
	# Активируем целевой объект
	if target_after_slide and target_animation != "":
		if target_after_slide.has_method(target_animation):
			target_after_slide.call(target_animation)
		elif target_after_slide.has_method("play"):
			target_after_slide.play(target_animation)
	
	if disable_collision_after:
		$CollisionShape2D.disabled = true
	
	_is_sliding = false
	
	print("Slide finished")

func reset_zone() -> void:
	if auto_reset:
		_has_triggered = false
		_is_sliding = false
		if disable_collision_after and $CollisionShape2D.disabled:
			$CollisionShape2D.disabled = false
