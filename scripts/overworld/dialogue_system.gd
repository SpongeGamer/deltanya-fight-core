extends Control

const DialogueButtonPreload = preload("res://scenes/prefabs/dialogue_button.tscn")

@onready var DialogueLabel: RichTextLabel = $HBoxContainer/VBoxContainer/RichTextLabel
@onready var SpeakerPortrait: TextureRect = $HBoxContainer/SpeakerParent/Portrait
@onready var SpeakerName: Label = $HBoxContainer/VBoxContainer/SpeakerName

var dialogue: Array[DE]
var current_dialogue_item: int = 0
var next_item: bool = true

var player_node: CharacterBody2D
var caller: Node = null

const VOICE_DB_OFFSET := -10.0
const VOICE_MIN_DB := -24.0
const VOICE_MAX_DB := -2.0

func _ready() -> void:
	visible = false
	$HBoxContainer/VBoxContainer/button_container.visible = false
	
	for i in get_tree().get_nodes_in_group("player"):
		player_node = i

func _process(_delta: float) -> void:
	if current_dialogue_item == dialogue.size():
		if !player_node:
			for i in get_tree().get_nodes_in_group("player"):
				player_node = i
			return
		if !Global.battle_in_progress:
			player_node.can_move = true
		get_parent().queue_free()
		return
	
	if next_item:
		next_item = false
		var i = dialogue[current_dialogue_item]
		
		if i is DialogueFunction:
			if i.hide_dialogue_box:
				visible = false
			else:
				visible = true
			_function_resource(i)
		
		elif i is DialogueAddItem:
			if i.item != null:
				if i.item.usePredicate != null and i.item.usePredicate.item == null:
					i.item.usePredicate.item = i.item
				Global.add_item(i.item)
			current_dialogue_item += 1
			next_item = true
		
		elif i is DialogueRemoveItem:
			if i.item != null:
				for idx in Global.items.size():
					var it = Global.items[idx]
					if it != null and it.name == i.item.name:
						Global.delete_item(idx)
						break
			current_dialogue_item += 1
			next_item = true
		
		elif i is DialogueChoice:
			visible = true
			_choice_resource(i)
		
		elif i is DialogueText:
			visible = true
			_text_resource(i)
		
		else:
			printerr("Ты случайно добавил DE resource!")
			current_dialogue_item += 1
			next_item = true

# Резолвит target_path с учётом caller.
# Порядок: пустой путь → caller.get_parent(); иначе — сначала
# относительно caller, затем абсолютно от корня сцены.
func _resolve_target(target_path: NodePath) -> Node:
	if target_path == NodePath(""):
		if caller != null:
			return caller.get_parent()
		return null
	# Пробуем относительно caller (покрывает NodePath("..") и т.д.)
	if caller != null:
		var n := caller.get_node_or_null(target_path)
		if n:
			return n
	# Абсолютный путь от корня сцены
	return get_tree().current_scene.get_node_or_null(target_path)

func _function_resource(i: DialogueFunction) -> void:
	var target_node: Node = _resolve_target(i.target_path)

	if target_node == null:
		printerr("DialogueFunction: не удалось найти ноду по пути '", i.target_path, "'")
		current_dialogue_item += 1
		next_item = true
		return

	if target_node.has_method(i.function_name):
		if i.function_arguments.size() == 0:
			target_node.call(i.function_name)
		else:
			target_node.callv(i.function_name, i.function_arguments)
	else:
		printerr("DialogueFunction: метод '", i.function_name, "' не найден на ", target_node)
	
	if i.wait_for_signal_to_continue:
		var signal_name = i.wait_for_signal_to_continue
		if target_node.has_signal(signal_name):
			var signal_state = { "done": false}
			var callable = func(_args): signal_state.done = true
			target_node.connect(signal_name, callable, CONNECT_ONE_SHOT)
			while not signal_state.done:
				if not is_inside_tree(): 
					return # Выходим из функции, если объект удален
				await get_tree().process_frame
	
	current_dialogue_item += 1
	next_item = true
	
func _choice_resource(i: DialogueChoice) -> void:
	SpeakerName.text = i.speaker_name
	DialogueLabel.text = i.text
	DialogueLabel.visible_characters = -1
	
	if i.speaker_img:
		$HBoxContainer/SpeakerParent.visible = true
		SpeakerPortrait.texture = i.speaker_img
	else: 
		$HBoxContainer/SpeakerParent.visible = false
	
	$HBoxContainer/VBoxContainer/button_container.visible = true	
	
	for item in i.choice_text.size():
		var DialogueButtonVar = DialogueButtonPreload.instantiate()
		DialogueButtonVar.text = i.choice_text[item]
		
		var trigger: DE = i.choice_function_call[item] if item < i.choice_function_call.size() else null
		
		if trigger is DialogueFunction and trigger.target_path:
			var target_node = _resolve_target(trigger.target_path)
			if target_node:
				DialogueButtonVar.connect("pressed",
					Callable(target_node, trigger.function_name).bindv(trigger.function_arguments),
					CONNECT_ONE_SHOT)
				if trigger.hide_dialogue_box:
					DialogueButtonVar.connect("pressed", hide, CONNECT_ONE_SHOT)
			DialogueButtonVar.connect("pressed",
				_choice_button_pressed.bind(trigger),
				CONNECT_ONE_SHOT)
		else:
			DialogueButtonVar.connect("pressed", _choice_button_pressed.bind(trigger), CONNECT_ONE_SHOT)
			
		$HBoxContainer/VBoxContainer/button_container.add_child(DialogueButtonVar)
	$HBoxContainer/VBoxContainer/button_container.get_child(0).grab_focus()
			
func _choice_button_pressed(trigger: DE) -> void:
	Global.text_finished.emit()
	for btn in $HBoxContainer/VBoxContainer/button_container.get_children():
		btn.disabled = true
	$HBoxContainer/VBoxContainer/button_container.visible = false
	for btn in $HBoxContainer/VBoxContainer/button_container.get_children():
		btn.queue_free()
	
	# Выполняем триггер выбора
	if trigger is DialogueAddItem:
		if trigger.item != null:
			if trigger.item.usePredicate != null and trigger.item.usePredicate.item == null:
				trigger.item.usePredicate.item = trigger.item
			Global.add_item(trigger.item)
	elif trigger is DialogueRemoveItem:
		if trigger.item != null:
			for idx in Global.items.size():
				var it = Global.items[idx]
				if it != null and it.name == trigger.item.name:
					Global.delete_item(idx)
					break
	elif trigger is DialogueFunction:
		if trigger.wait_for_signal_to_continue:
			var target_node = _resolve_target(trigger.target_path)
			var signal_name = trigger.wait_for_signal_to_continue
			if target_node and target_node.has_signal(signal_name):
				var signal_state = {"done": false}
				var callable = func(_args): signal_state.done = true
				target_node.connect(signal_name, callable, CONNECT_ONE_SHOT)
				while not signal_state.done:
					if not is_inside_tree(): 
						return
					await get_tree().process_frame
	
	current_dialogue_item += 1

	# Если триггер — displayable DE (текст, выбор и т.д.) — вставляем в очередь
	if trigger != null and not (trigger is DialogueFunction or trigger is DialogueAddItem or trigger is DialogueRemoveItem):
		dialogue.insert(current_dialogue_item, trigger)

	next_item = true

func _text_resource(i: DialogueText) -> void:
	SpeakerName.text = i.speaker_name
	
	$AudioStreamPlayer.stream = i.text_sound
	$AudioStreamPlayer.volume_db = clampf(float(i.text_volume_db) + VOICE_DB_OFFSET, VOICE_MIN_DB, VOICE_MAX_DB)
	
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera and i.camera_position != Vector2(999.999, 999.999):
		var camera_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)
		camera_tween.tween_property(camera, "global_position", i.camera_position, i.camera_transition_time)

	if !i.speaker_img:
		$HBoxContainer/SpeakerParent.visible = false
	else:
		$HBoxContainer/SpeakerParent.visible = true
		SpeakerPortrait.texture = i.speaker_img
	
	DialogueLabel.visible_characters = 0
	DialogueLabel.text = i.text
	var text_without_square_brackets: String = _text_without_square_brackets(i.text)
	var total_characters: int = text_without_square_brackets.length()
	var character_timer: float = 0.0
	
	while DialogueLabel.visible_characters < total_characters:
		if !is_inside_tree():
			return
		if Input.is_action_just_pressed("cancel") and not get_tree().paused:
			DialogueLabel.visible_characters = total_characters
			break
			
		character_timer += get_process_delta_time()
		if character_timer >= (1.0 / i.text_speed) or text_without_square_brackets[DialogueLabel.visible_characters] == " ":
			var character: String = text_without_square_brackets[DialogueLabel.visible_characters]
			DialogueLabel.visible_characters += 1
			if character != " ":
				$AudioStreamPlayer.pitch_scale = randf_range(i.text_volume_pitch_min, i.text_volume_pitch_max)
				$AudioStreamPlayer.play()
			character_timer = 0.0
			
		await get_tree().process_frame
	
	# Ждём нажатия кнопки
	while true:
		if !is_inside_tree():
			return
		await get_tree().process_frame
		if DialogueLabel.visible_characters == total_characters:
			if Input.is_action_just_pressed("ui_accept") and not get_tree().paused:
				Global.text_finished.emit()
				current_dialogue_item += 1
				next_item = true
				break

func _text_without_square_brackets(text: String) -> String:
	var result: String = ""
	var inside_bracket: bool = false
	
	for i in text:
		if i == "[":
			inside_bracket = true
			continue
			
		if i == "]":
			inside_bracket = false
			continue
		
		if !inside_bracket:
			result += i
	
	return result
