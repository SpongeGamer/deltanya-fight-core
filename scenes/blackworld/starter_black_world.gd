extends Node2D

@export var first_dialogue: Array[DE] = [] 

@onready var fall_scene: Node2D = $FallScene
@onready var dark_rect: ColorRect = $DarkRect

func _ready() -> void:
	Global.location_name = "Начало конца"
	
	# Проверяем, не видели ли мы уже эту катсцену
	if Global.get_flag("starter_cutscene_watched"):
		$DarkRect.visible = false
		$FallScene.visible = false
		Sounds.set_music("starter_black", 0.6)
		_unlock_player()
		return
	
	# Первый раз - показываем катсцену
	dark_rect.modulate.a = 1.0
	
	# Ждем полного завершения всей катсцены
	await _start_full_cutscene()
	
	# Сохраняем флаг что катсцена была показана
	Global.set_flag("starter_cutscene_watched", true)
	
	# Только после катсцены запускаем диалог
	Sounds.set_music("starter_black", 0.6)
	_launch_dialogue(first_dialogue)

func _start_full_cutscene() -> void:
	# 1. Падение
	await _start_fall_sequence()
	
	# 2. Анимация открытия глаз
	await _open_eyes_animation()
	
	

func _start_fall_sequence() -> void:
	fall_scene.start_fall()
	await fall_scene.fall_finished
	fall_scene.queue_free()
	# Не запускаем здесь анимацию глаз

func _open_eyes_animation() -> void:
	# Чуть приоткрыть (будто веки ещё тяжёлые)
	var tw1 := create_tween()
	tw1.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw1.tween_property(dark_rect, "modulate:a", 0.35, 0.6)
	await tw1.finished

	# Моргнуть — снова закрыть
	var tw2 := create_tween()
	tw2.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(dark_rect, "modulate:a", 0.9, 0.25)
	await tw2.finished

	# Небольшая пауза (веки снова тяжёлые)
	await get_tree().create_timer(0.3).timeout

	# Окончательно открыть глаза — медленно и плавно
	var tw3 := create_tween()
	tw3.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw3.tween_property(dark_rect, "modulate:a", 0.0, 2.2)
	await tw3.finished

func _launch_dialogue(p_dialogue: Array[DE]) -> void:
	if p_dialogue.is_empty():
		_unlock_player()  # Если диалога нет, просто разблокируем игрока
		return
	
	var DialogueScene := load("res://scenes/prefabs/dialogue_system.tscn") as PackedScene
	if DialogueScene == null:
		push_error("HelperNodeFirstRoom: не найден dialogue_system.tscn")
		_unlock_player()
		return
	
	var cl := CanvasLayer.new()
	cl.layer = 10
	get_tree().current_scene.add_child(cl)
	var dlg = DialogueScene.instantiate()
	dlg.dialogue = p_dialogue.duplicate()
	dlg.caller = self
	cl.add_child(dlg)
	
	# Ждем окончания диалога
	await dlg.tree_exited
	
	# После диалога разблокируем игрока
	_unlock_player()

func _unlock_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_can_move"):
		player.can_move = true
		print("Player unlocked after cutscene and dialogue")
