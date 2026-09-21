extends Area2D

@export var cutscene_flag: String = "dust_cutscene_watched"

# Персонажи (уже в сцене)
@export var egor: Companion 
@export var nikita: Companion 

# Точки движения
@export var player_path: Array[Vector2] = []
@export var kate_path: Array[Vector2] = []
@export var egor_path: Array[Vector2] = []

# Анимации пыли
@export var dust_pile_1: AnimatedSprite2D = null
@export var dust_pile_2: AnimatedSprite2D = null

# Диалоги
@export var first_dialogue: Array[DE] = []
@export var second_dialogue: Array[DE] = []
@export var third_dialogue: Array[DE] = []
@export var post_battle_dialogue: Array[DE] = []

# Настройки камеры
@export var camera_pan_position: Vector2 = Vector2(1760, 1500)
@export var camera_pan_duration: float = 2.0

var _player = null
var _kate = null
var _has_triggered: bool = false

# ─── ДОБАВИТЬ ЭТО ─────────────────────────────────────────────────────────────
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Прячем персонажей если они видны
	if egor:
		egor.visible = false
	if nikita:
		nikita.visible = false
# ─────────────────────────────────────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _has_triggered:
		return
	if Global.get_flag(cutscene_flag):
		return
	
	_has_triggered = true
	_player = body
	_start_cutscene()

func _start_cutscene() -> void:
	print("Cutscene started!")  # Отладка
	
	# Блокируем игрока
	_player.can_move = false
	
	# Находим Катю
	var companions = get_tree().get_nodes_in_group("kate_body")
	for comp in companions:
		if comp.has_method("stop_following"):
			comp.stop_following()
			_kate = comp
			print("Kate found!")  # Отладка
	
	# Останавливаем следование камеры
	var camera = CameraController.instance
	camera.stop_follow()
	
	# Двигаем игрока к месту
	if player_path.size() > 0:
		print("Moving player, path size: ", player_path.size())
		_player.start_cutscene_path(player_path)
	
	# Катя идёт
	if _kate and kate_path.size() > 0:
		print("Moving Kate")
		_kate.start_cutscene_path(kate_path)
	
	await camera.pan_to(camera_pan_position, camera_pan_duration)
	
	# Диалог "Смотри, пыль!"
	await _launch_dialogue(first_dialogue)
	print("First dialogue finished")
	
	# Выпрыгивание Егора
	await _jump_out_egor()
	
	# Выпрыгивание Никиты
	await _jump_out_nikita()
	
	# Диалог после выпрыгивания
	await _launch_dialogue(second_dialogue)
	
	# Егор присоединяется к пати
	if egor:
		egor.start_following()
		Global.add_to_party("egor")
	
	# Диалог перед боем
	await _launch_dialogue(third_dialogue)
	
	# Возвращаем камеру к игроку
	await camera.pan_to_node(_player, 1.0, true)
	
	# Запускаем бой
	_start_nikita_battle()
	
	# После боя
	if _kate and _kate.has_method("start_following"):
		_kate.start_following()
	
	Global.set_flag(cutscene_flag, true)

func _jump_out_egor() -> void:
	if not egor:
		return
	
	egor.visible = true
	
	if dust_pile_1:
		Sounds.play("snd_noise")
		dust_pile_1.play("burst")
		await dust_pile_1.animation_finished
		dust_pile_1.visible = false
	
	if egor.has_method("_play_walk_animation"):
		egor._play_walk_animation(Vector2.DOWN)
	
	
	await get_tree().create_timer(0.3).timeout
	
	if egor_path.size() > 0:
		egor.start_cutscene_path(egor_path)
		await egor.cutscene_path_finished
	
	if egor.has_method("_play_idle_animation"):
		egor._play_idle_animation()

func _jump_out_nikita() -> void:
	if not nikita:
		return
	
	nikita.visible = true
	
	if dust_pile_2:
		Sounds.play("snd_noise")
		dust_pile_2.play("burst")
		await dust_pile_2.animation_finished
		dust_pile_2.visible = false
	
	if nikita.has_method("_play_walk_animation"):
		nikita._play_walk_animation(Vector2.DOWN)
	
	await get_tree().create_timer(0.3).timeout
	
	if nikita.has_method("_play_idle_animation"):
		nikita._play_idle_animation()

func _launch_dialogue(p_dialogue: Array[DE]) -> void:
	if p_dialogue.is_empty():
		return
	
	var DialogueScene := load("res://scenes/prefabs/dialogue_system.tscn") as PackedScene
	if DialogueScene == null:
		return
	
	var cl := CanvasLayer.new()
	cl.layer = 10
	get_tree().current_scene.add_child(cl)
	
	var dlg = DialogueScene.instantiate()
	dlg.dialogue = p_dialogue.duplicate()
	dlg.caller = self
	cl.add_child(dlg)
	
	await dlg.tree_exited

func _start_nikita_battle() -> void:
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/nikita/nikita.tscn").instantiate())
	Global.load_party_characters()
	
	# Запускаем бой и ЖДЁМ его окончания
	await _start_battle("res://scenes/battle/battle.tscn")
	
	# Бой закончился — запускаем пост-боевой диалог
	if post_battle_dialogue.size() > 0:
		await _launch_dialogue(post_battle_dialogue)
		

func _start_battle(battle_scene_path: String) -> void:
	if Global.battle_in_progress:
		return

	var overworld_music := Sounds.current_song
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		Global.player_return_position = player.global_position
		player.can_move = false

	Global.battle_in_progress = true

	PostProcessing.flash_to_black()
	await PostProcessing.fade_finished

	get_tree().current_scene.hide()

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 2
	get_tree().current_scene.add_child(canvas_layer)

	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_right = 640
	bg.offset_bottom = 480
	bg.z_index = 0
	canvas_layer.add_child(bg)

	var battle_scene = load(battle_scene_path).instantiate()
	battle_scene.add_to_group("battle")
	canvas_layer.add_child(battle_scene)

	PostProcessing.flash_from_black()
	await PostProcessing.fade_finished

	# Ждём завершения боя
	await battle_scene.tree_exited

	# Сохраняем ХП персонажей
	for i in Global.party.size():
		if i < Global.characters.size() and is_instance_valid(Global.characters[i]):
			PartyData.save_from_character(Global.party[i], Global.characters[i])

	Global.battle_in_progress = false
	canvas_layer.queue_free()
	get_tree().current_scene.show()

	if player:
		player.can_move = true
		player.global_position = Global.player_return_position

	PostProcessing.flash_from_black()
	await PostProcessing.fade_finished

	if overworld_music != "":
		Sounds.set_music(overworld_music, 0.8)

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
