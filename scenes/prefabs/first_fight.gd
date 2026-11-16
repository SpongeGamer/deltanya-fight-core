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

# ─── ТОЧКИ ОСТАНОВКИ ──────────────────────────────────────────────────────────
const EGOR_STOP           := Vector2(1870, 1586)   # где Егор останавливается после прыжка
const NIKITA_STAND        := Vector2(1760, 1575)   # куда Никита медленно идёт в третьем диалоге
const NIKITA_SLOW_SPEED   := 40.0                  # «медленно, пока говорит»
const NIKITA_NORMAL_SPEED := 125.0                 # обычная скорость (move_speed по умолчанию)

var _player = null
var _kate = null
var _has_triggered: bool = false
var _dust_clock := 0.0
var _cutscene_active := false
signal nikita_joined(result: bool)

# ─── ДОБАВИТЬ ЭТО ─────────────────────────────────────────────────────────────
func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Прячем персонажей если они видны
	if egor:
		egor.visible = false
	if nikita:
		nikita.visible = false
# ─────────────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_dust_clock += delta
	for i in range(2):
		var dust: AnimatedSprite2D = [dust_pile_1, dust_pile_2][i]
		if is_instance_valid(dust) and dust.visible and not dust.is_playing():
			dust.rotation = deg_to_rad(0.8) * sin(_dust_clock * 1.8 + i * 1.4)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _has_triggered:
		return
	if Global.get_flag(cutscene_flag):
		return
	
	_has_triggered = true
	_player = body
	_start_cutscene()

func _start_cutscene() -> void:
	_cutscene_active = true
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
		Global.add_to_party("egor")
	
	# Егор смотрит на Никиту; Никита медленно идёт на своё место, пока идёт диалог.
	_stage_before_battle()
	await _launch_dialogue(third_dialogue)
	
	# Возвращаем Никите обычную скорость.
	if is_instance_valid(nikita):
		nikita.move_speed = NIKITA_NORMAL_SPEED
	
	# Возвращаем камеру к игроку
	await camera.pan_to_node(_player, 1.0, true)
	
	# Запускаем бой
	await _start_nikita_battle()
	if not is_inside_tree():
		return

	# Камера возвращается к отряду после разговора и присоединения Никиты.
	if is_instance_valid(_player):
		await CameraController.instance.pan_to_node(_player, 1.0, true)
	await _walk_party_into_formation()
	if not is_inside_tree():
		return
	# Возвращаем обычное следование только после послебоевого диалога.
	for companion in [_kate, egor, nikita]:
		if is_instance_valid(companion) and Global.party.has(companion.party_key):
			companion.start_following()
	_cutscene_active = false
	if is_instance_valid(_player):
		_player.can_move = true
	Global.set_flag(cutscene_flag, true)

func _jump_out_egor() -> void:
	if not egor:
		return
	
	egor.visible = true
	
	if dust_pile_1:
		Sounds.play("snd_noise")
		dust_pile_1.rotation = 0.0
		dust_pile_1.play("burst")
		await dust_pile_1.animation_finished
		dust_pile_1.visible = false
	
	if egor.has_method("_play_walk_animation"):
		egor._play_walk_animation(Vector2.DOWN)

	
	await get_tree().create_timer(0.3).timeout
	
	# Егор идёт до своей точки остановки
	var egor_stop: Array[Vector2] = [EGOR_STOP]
	egor.start_cutscene_path(egor_stop)
	await egor.cutscene_path_finished
	
	if egor.has_method("_play_idle_animation"):
		egor._play_idle_animation()

func _jump_out_nikita() -> void:
	if not nikita:
		return
	
	nikita.visible = true
	
	if dust_pile_2:
		Sounds.play("snd_noise")
		dust_pile_2.rotation = 0.0
		dust_pile_2.play("burst")
		await dust_pile_2.animation_finished
		dust_pile_2.visible = false
	
	if nikita.has_method("_play_walk_animation"):
		nikita._play_walk_animation(Vector2.DOWN)

	await get_tree().create_timer(0.3).timeout
	
	if nikita.has_method("_play_idle_animation"):
		nikita._play_idle_animation()

func _stage_before_battle() -> void:
	if is_instance_valid(egor):
		egor.last_direction = Vector2.LEFT
		egor._play_idle_animation()
	if is_instance_valid(nikita):
		# Никита медленно идёт в свою точку на платформе (за кадром, пока идёт диалог)
		nikita.move_speed = NIKITA_SLOW_SPEED
		var path: Array[Vector2] = [NIKITA_STAND]
		nikita.start_cutscene_path(path)

# Записываем присоединение, но до конца диалога никто не двигается.
func join_nikita_for_cutscene() -> void:
	if is_instance_valid(nikita):
		Global.add_to_party(nikita.party_key)
	# DialogueFunction подключается к сигналу после вызова этого метода.
	await get_tree().process_frame
	nikita_joined.emit(true)

# После всего разговора спутники по очереди обходят группу и встают за Аней.
func _walk_party_into_formation() -> void:
	if not is_instance_valid(_player):
		return
	var companions: Array = [_kate, egor, nikita]
	var upper_y: float = _player.global_position.y - 55.0
	for member in companions:
		if is_instance_valid(member):
			upper_y = minf(upper_y, member.global_position.y - 45.0)
	var slot: int = 1
	for member in companions:
		if not is_instance_valid(member) or not Global.party.has(member.party_key):
			continue
		var destination: Vector2 = _player.global_position + Vector2(29.0 * slot, 0.0)
		var path: Array[Vector2] = [
			Vector2(member.global_position.x, upper_y),
			Vector2(destination.x, upper_y),
			destination
		]
		member.start_cutscene_path(path)
		await member.cutscene_path_finished
		if not is_inside_tree():
			return
		if is_instance_valid(member):
			member.last_direction = Vector2.LEFT
			member._play_idle_animation()
			member.position_history.clear()
		slot += 1

func _launch_dialogue(p_dialogue: Array[DE]) -> void:
	# Локация могла быть уничтожена (например, после поражения) — дерева уже нет.
	if not is_inside_tree():
		return
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
	dlg.release_player_on_finish = false
	cl.add_child(dlg)
	
	await dlg.tree_exited

func _start_nikita_battle() -> void:
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/nikita/nikita.tscn").instantiate())
	Global.load_party_characters()
	
	# Запускаем бой и ЖДЁМ его окончания
	await _start_battle("res://scenes/battle/battle.tscn")
	
	# Бой закончился. При поражении сцена уже переключена на lost_screen,
	# а эта локация уничтожена — дерева больше нет, трогать его нельзя.
	if not is_inside_tree():
		return
	
	# Бой закончился — запускаем пост-боевой диалог
	if post_battle_dialogue.size() > 0:
		await _launch_dialogue(post_battle_dialogue)
		

func _start_battle(battle_scene_path: String) -> void:
	if Global.battle_in_progress:
		return

	var overworld_music := Sounds.current_song
	var player = get_tree().get_first_node_in_group("player")
	
	# Останавливаем катсценические пути и запоминаем кадр непосредственно перед боем.
	# Скрытая локация продолжает обрабатывать движение во время боя.
	var party_snapshot: Dictionary = {}
	if is_instance_valid(player):
		player.stop_cutscene_path()
		player.can_move = false
		Global.player_return_position = player.global_position
		party_snapshot[player] = [player.global_position, player.last_direction]
	for companion in [_kate, egor, nikita]:
		if not is_instance_valid(companion):
			continue
		if companion.in_cutscene:
			companion._finish_cutscene_path()
		companion.stop_following()
		companion.is_moving = false
		party_snapshot[companion] = [companion.global_position, companion.last_direction]
	var camera_position: Vector2 = CameraController.instance.global_position
	CameraController.instance.stop_follow()

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

	# Бой мог закончиться поражением: battle.gd переключил сцену на lost_screen,
	# и эта локация (вместе с этим узлом) уже уничтожена — обращаться к дереву нельзя.
	if not is_inside_tree():
		return

	# Сохраняем ХП персонажей
	for i in Global.party.size():
		if i < Global.characters.size() and is_instance_valid(Global.characters[i]):
			PartyData.save_from_character(Global.party[i], Global.characters[i])

	Global.battle_in_progress = false
	if is_instance_valid(canvas_layer):
		canvas_layer.queue_free()
	var current := get_tree().current_scene
	if current:
		current.show()

	if is_instance_valid(player):
		player.can_move = false
	_restore_party_after_battle(party_snapshot, camera_position)
	Global.player_return_position = Vector2.ZERO

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
	if _cutscene_active:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = true

# Возвращаем всех туда, где они стояли перед боем, без перестановки отряда.
func _restore_party_after_battle(party_snapshot: Dictionary, camera_position: Vector2) -> void:
	for actor in party_snapshot:
		if not is_instance_valid(actor):
			continue
		actor.global_position = party_snapshot[actor][0]
		actor.last_direction = party_snapshot[actor][1]
		actor.velocity = Vector2.ZERO
		actor.position_history.clear()
		actor._play_idle_animation()
		actor.z_index = int(actor.global_position.y)
	CameraController.instance.snap_to(camera_position)
