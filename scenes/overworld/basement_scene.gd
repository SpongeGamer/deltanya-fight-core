extends Node2D

@export var basement_dialogue: Array[DE] = []

var _player: CharacterBody2D
var _dark_layer: CanvasLayer = null
var anne_eyes: AnimatedSprite2D = null
var kate_eyes: AnimatedSprite2D = null
var egor_eyes: AnimatedSprite2D = null

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player.can_move = false
	
	_dark_layer = _get_or_create_dark_layer()
	_dark_layer.visible = true
	
	_start_basement_sequence()

func _start_basement_sequence() -> void:
	Sounds.set_music("basement", 0.5)
	
	if not basement_dialogue.is_empty():
		await _launch_dialogue(basement_dialogue)

func _launch_dialogue(p_dialogue: Array[DE]) -> void:
	var DialogueScene := load("res://scenes/prefabs/dialogue_system.tscn") as PackedScene
	if DialogueScene == null:
		push_error("Basement: не найден dialogue_system.tscn")
		return
	var cl := CanvasLayer.new()
	cl.layer = 20
	add_child(cl)
	var dlg = DialogueScene.instantiate()
	dlg.dialogue = p_dialogue.duplicate()
	cl.add_child(dlg)
	await cl.tree_exited

func _get_or_create_dark_layer() -> CanvasLayer:
	for child in get_children():
		if child is CanvasLayer and child.name == "DarknessLayer":
			return child
	
	var layer := CanvasLayer.new()
	layer.name = "DarknessLayer"
	layer.layer = 9
	layer.visible = false
	
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.size = get_viewport().get_visible_rect().size
	
	layer.add_child(rect)
	add_child(layer)
	return layer

# ── Вспышка света ──────────────────────────────────────────────────────────────
func flashlight() -> void:
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 100
	add_child(flash_layer)
	
	var flash := ColorRect.new()
	flash.color = Color.WHITE
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	flash.modulate = Color(1, 1, 1, 0)
	flash_layer.add_child(flash)
	
	# Запускаем анимацию вспышки
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 1.0, 0.08)
	tween.tween_property(flash, "modulate:a", 0.0, 0.45)
	
	# Звуки стартуют ОДНОВРЕМЕННО с вспышкой (не ждём tween)
	_play_sounds_staggered()
	
	await tween.finished
	flash_layer.queue_free()

# Корутина со стаггером — запускается в фоне, не блокирует flashlight()
func _play_sounds_staggered() -> void:
	var sounds := ["snd_tensionhorn", "snd_rudebuster_hit", "snd_noise"]
	for sound in sounds:
		Sounds.play(sound)
		await get_tree().create_timer(0.18).timeout

# ── Глаза — вспомогательные ────────────────────────────────────────────────────
# Показывает все глаза (делает видимыми и запускает анимацию по умолчанию)
func _show_all_eyes() -> void:
	print("=== SHOWING EYES ===")
	
	var eyes_layer := CanvasLayer.new()
	eyes_layer.name = "EyesLayer"
	eyes_layer.layer = 15
	add_child(eyes_layer)
	
	for name in ["Anne_Eyes", "Kate_Eyes", "Egor_Eyes"]:
		var node = get_node_or_null(name)
		if node and node is AnimatedSprite2D:
			node.reparent(eyes_layer)
			node.visible = true
			node.z_index = 10
			node.modulate = Color.WHITE
			
			# Сохраняем ссылки
			if name == "Anne_Eyes":
				anne_eyes = node
			elif name == "Kate_Eyes":
				kate_eyes = node
			elif name == "Egor_Eyes":
				egor_eyes = node
			
			if not node.is_playing():
				node.play("idle")
			
			print(name, " → moved to EyesLayer and saved reference")
		else:
			print(name, " NOT FOUND!")

# ── Управление глазами ─────────────────────────────────────────────────────────
# Вызываются через DialogueFunction перед репликой нужного персонажа.
#
# Пример в редакторе:
#   DialogueFunction → target_path="."  function_name="set_anne_eyes"
#                      function_arguments=["surprised"]
#
# Имя анимации должно совпадать с именем в SpriteFrames ноды.

func set_anne_eyes(anim_name: String) -> void:
	if anne_eyes:
		anne_eyes.play(anim_name)
	else:
		push_warning("Anne_Eyes reference is null!")

func set_kate_eyes(anim_name: String) -> void:
	if kate_eyes:
		kate_eyes.play(anim_name)
	else:
		push_warning("Kate_Eyes reference is null!")

func set_egor_eyes(anim_name: String) -> void:
	if egor_eyes:
		egor_eyes.play(anim_name)
	else:
		push_warning("Egor_Eyes reference is null!")

# Плавное исчезновение глаз Егора
func hide_egor_eyes(duration: float = 0.4) -> void:
	if egor_eyes and egor_eyes.visible:
		var tween := create_tween()
		tween.tween_property(egor_eyes, "modulate:a", 0.0, duration)
		await tween.finished
		egor_eyes.visible = false  # полностью скрываем после анимации
		

# Плавное появление глаз Егора
func show_egor_eyes(duration: float = 0.4) -> void:
	if egor_eyes:
		egor_eyes.visible = true
		egor_eyes.modulate.a = 0.0  # начинаем с прозрачности
		
		var tween := create_tween()
		tween.tween_property(egor_eyes, "modulate:a", 1.0, duration)
		
func _add_party_members() -> void:
	if "kate" not in Global.party:
		Global.party.append("kate")
	if "egor" not in Global.party:
		Global.party.append("egor")
	# Подгружаем ноды персонажей чтобы PartyData подхватил новый состав
	Global.load_party_characters(false)

# Плавное исчезновение всех глаз
func hide_all_eyes(duration: float = 0.4) -> void:
	var tweens := []
	
	if anne_eyes and anne_eyes.visible:
		var tween := create_tween()
		tween.tween_property(anne_eyes, "modulate:a", 0.0, duration)
		tweens.append(tween)
	
	if kate_eyes and kate_eyes.visible:
		var tween := create_tween()
		tween.tween_property(kate_eyes, "modulate:a", 0.0, duration)
		tweens.append(tween)
	
	if egor_eyes and egor_eyes.visible:
		var tween := create_tween()
		tween.tween_property(egor_eyes, "modulate:a", 0.0, duration)
		tweens.append(tween)
	
	# Ждём завершения всех анимаций
	if not tweens.is_empty():
		await get_tree().create_timer(duration).timeout
	
	# Скрываем глаза полностью
	if anne_eyes:
		anne_eyes.visible = false
	if kate_eyes:
		kate_eyes.visible = false
	if egor_eyes:
		egor_eyes.visible = false
