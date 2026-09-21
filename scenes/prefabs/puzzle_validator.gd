extends Area2D

## Настройки
@export var validator_id: String = "validator_1"
@export var switches: Array[Node2D] = []  # Перетащи сюда все переключатели
@export var required_states: Array[int] = []  # [0, 1, 2] - нужные позиции

## Что активировать при успехе
@export var target_object: AnimatedSprite2D = null
@export var target_animation: String = "activate"

## Анимация самого валидатора (рычажка)
@export var validator_animator: AnimatedSprite2D = null
@export var validator_animation: String = "push"  # анимация нажатия

## Дополнительные действия после решения
@export var extra_targets: Array[Node2D] = []  # другие объекты для анимации
@export var extra_animation: String = "activate"
@export var collision_to_disable: CollisionShape2D = null  # какую коллизию удалить

## Звуки
@export var success_sound: String = ""
@export var fail_sound: String = ""

var _player_in: bool = false
var _solved: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in = false

func _input(event: InputEvent) -> void:
	if _player_in and event.is_action_pressed("interact") and not _solved:
		_check_combination()

func _check_combination() -> void:
	# Получаем текущие состояния всех переключателей
	var current_states: Array[int] = []
	for switch in switches:
		if switch.has_method("get_state"):
			current_states.append(switch.get_state())
		else:
			push_error("PuzzleValidator: переключатель не имеет метода get_state")
			return
	
	# Проверяем совпадение
	var is_correct: bool = true
	for i in range(required_states.size()):
		if i >= current_states.size() or current_states[i] != required_states[i]:
			is_correct = false
			break
	
	if is_correct:
		_success()
	else:
		_fail()

func _success() -> void:
	_solved = true
	
	if success_sound:
		Sounds.play(success_sound)
	
	# 1. Анимация самого валидатора (рычажок опускается)
	if validator_animator and validator_animation:
		validator_animator.play(validator_animation)
		# Ждём окончания анимации если нужно
		await validator_animator.animation_finished
	
	# 2. Активируем целевой объект
	if target_object and target_animation:
		if target_object.has_method(target_animation):
			target_object.call(target_animation)
		elif target_object.has_method("play"):
			target_object.play(target_animation)
	
	# 3. Дополнительные объекты
	for obj in extra_targets:
		if obj and extra_animation:
			if obj.has_method(extra_animation):
				obj.call(extra_animation)
			elif obj.has_method("play"):
				obj.play(extra_animation)
	
	# 4. Удаляем коллизию (чтобы игрок мог пройти)
	if collision_to_disable:
		collision_to_disable.disabled = true
		# Или полностью удалить:
		# collision_to_disable.queue_free()
	
	# 5. Сохраняем
	if validator_id != "":
		Global.set_flag(validator_id)
	
	print("Puzzle solved!")

func _fail() -> void:
	if fail_sound:
		Sounds.play(fail_sound)
	
	# Сбрасываем все переключатели
	for switch in switches:
		if switch.has_method("reset_state"):
			switch.reset_state()
	
	print("Wrong combination! Switches reset.")
