extends Node

const BEER_ITEM := preload("res://holdables/items/beer.tres")

# Настраивается прямо в инспекторе
@export var dream_dialogue : Array[DE] = []
@export var first_dialogue  : Array[DE] = []   # запускается при 6+ флагах
@export var second_dialogue : Array[DE] = []   # запускается когда все прожаты

# Настройки пузырей
@export var bubble_count: int = 200
@export var bubble_duration: float = 8.0  # Сколько длится эффект пузырей

# Все флаги комнаты
const ROOM_FLAGS := [
	"wardrobe", "bed", "bed2", "tabletop",
	"tablebottom1", "tablebottom2", "dryingrack",
	"instruments", "balcony", "catstuff", "catbed"
]

const FIRST_THRESHOLD := 6
const FIRST_FLAG_KEY  := "first_room_dialogue1_done"
const SECOND_FLAG_KEY := "first_room_dialogue2_done"

var _bubble_texture: Texture2D
var _bubble_layer: CanvasLayer
var _bubble_emitters: Array[GPUParticles2D] = []

func _ready() -> void:
	_bubble_texture = load("res://assets/VFX/Bubble.png")
	Sounds.set_music("darkness", 0.5)
	_get_or_create_dark_layer()
	call_deferred("_launch_dialogue_deferred", dream_dialogue)

func _launch_dialogue_deferred(p_dialogue: Array[DE]) -> void:
	_launch_dialogue(p_dialogue)

# ── ПУЗЫРИ ───────────────────────────────────────────────────────────────────
func _start_bubbles() -> void:
	_bubble_layer = CanvasLayer.new()
	_bubble_layer.name = "BubbleLayer"
	_bubble_layer.layer = 9
	add_child(_bubble_layer)
	
	# Создаём несколько эмиттеров для полного покрытия
	for i in range(3):
		_create_bubble_emitter(i * 0.33)
	
	# Запускаем таймер на остановку пузырей
	get_tree().create_timer(bubble_duration).timeout.connect(_stop_bubbles)

func _create_bubble_emitter(offset_x: float) -> void:
	var particles := GPUParticles2D.new()
	particles.visible = true
	particles.z_index = 10
	particles.texture = _bubble_texture
	
	particles.amount = bubble_count / 3
	particles.lifetime = bubble_duration + 2.0
	particles.one_shot = true
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.spread = 10.0
	
	var screen_height = 480
	var needed_speed = screen_height / particles.lifetime
	material.initial_velocity_min = needed_speed * 0.9
	material.initial_velocity_max = needed_speed * 1.1
	material.gravity = Vector3(0, 0, 0)
	
	material.scale_min = 1.0
	material.scale_max = 4.0
	material.color = Color(1, 1, 1, 0.7)  # Немного прозрачные
	
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(320, 20, 0)
	
	particles.process_material = material
	particles.position = Vector2(320 + (offset_x - 0.33) * 100, 480)
	
	_bubble_layer.add_child(particles)
	_bubble_emitters.append(particles)
	particles.emitting = true

func _stop_bubbles() -> void:
	# Останавливаем эмиссию
	for emitter in _bubble_emitters:
		if is_instance_valid(emitter):
			emitter.emitting = false
	
	# Постепенно замедляем все пузыри
	var tween := create_tween()
	tween.set_parallel(true)
	
	for emitter in _bubble_emitters:
		if is_instance_valid(emitter):
			var material = emitter.process_material as ParticleProcessMaterial
			if material:
				# Замедляем скорость до нуля
				tween.tween_property(material, "initial_velocity_min", 0.0, 2.0)
				tween.tween_property(material, "initial_velocity_max", 0.0, 2.0)
	
	# Затухаем слой
	if is_instance_valid(_bubble_layer):
		var fade_tween := create_tween()
		fade_tween.tween_property(_bubble_layer, "modulate:a", 0.0, 2.5)
		await fade_tween.finished
		_bubble_layer.queue_free()

func stop_bubbles_early() -> void:
	"""Публичный метод для досрочной остановки пузырей"""
	_stop_bubbles()

# ── ПОДБОР ПИВА ───────────────────────────────────────────────────────────────
func pick_up_beer() -> void:
	var beer_sprite := get_tree().current_scene.get_node_or_null("FurnitureSprites/Beer")
	if beer_sprite:
		beer_sprite.visible = false
	Sounds.play("snd_item")
	Global.add_item(BEER_ITEM)

# ── ПРОВЕРКА ФЛАГОВ ──────────────────────────────────────────────────────────
func check_flags() -> void:
	var count := 0
	for flag in ROOM_FLAGS:
		if Global.get_flag(flag):
			count += 1

	if count >= ROOM_FLAGS.size() and not Global.get_flag(SECOND_FLAG_KEY):
		Global.set_flag(SECOND_FLAG_KEY)
		_launch_dialogue(second_dialogue)
		return

	if count >= FIRST_THRESHOLD and not Global.get_flag(FIRST_FLAG_KEY):
		Global.set_flag(FIRST_FLAG_KEY)
		_launch_dialogue(first_dialogue)

# ── ЗАПУСК ДИАЛОГА ────────────────────────────────────────────────────────────
func _launch_dialogue(p_dialogue: Array[DE]) -> void:
	if p_dialogue.is_empty():
		return
	var DialogueScene := load("res://scenes/prefabs/dialogue_system.tscn") as PackedScene
	if DialogueScene == null:
		push_error("HelperNodeFirstRoom: не найден dialogue_system.tscn")
		return
	var cl := CanvasLayer.new()
	cl.layer = 10
	get_tree().current_scene.add_child(cl)
	var dlg = DialogueScene.instantiate()
	dlg.dialogue = p_dialogue.duplicate()
	dlg.caller = self
	cl.add_child(dlg)
	
	# Если это dream_dialogue — после его завершения убираем темноту
	if p_dialogue == dream_dialogue:
		await dlg.tree_exited
		_fade_out_dark_layer(3.0)
		stop_bubbles_early()  # Останавливаем пузыри вместе с темнотой

# ── ТЁМНЫЙ ЭКРАН ──────────────────────────────────────────────────────────────
func _get_or_create_dark_layer() -> CanvasLayer:
	for child in get_children():
		if child is CanvasLayer and child.name == "DarknessLayer":
			return child
	
	var layer := CanvasLayer.new()
	layer.name = "DarknessLayer"
	layer.layer = 8
	layer.visible = true
	
	var rect := ColorRect.new()
	rect.name = "ColorRect"
	rect.color = Color.BLACK
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.modulate = Color(1, 1, 1, 0)
	
	layer.add_child(rect)
	add_child(layer)
	
	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, 0.01)
	
	return layer

func _fade_out_dark_layer(duration: float = 2.0, remove_after: bool = true) -> void:
	var layer: CanvasLayer = null
	
	for child in get_children():
		if child is CanvasLayer and child.name == "DarknessLayer":
			layer = child
			break
	
	if layer == null:
		return
	
	var rect := layer.find_child("ColorRect") as ColorRect
	if rect == null:
		if layer.get_child_count() > 0 and layer.get_child(0) is ColorRect:
			rect = layer.get_child(0) as ColorRect
		else:
			push_error("_fade_out_dark_layer: ColorRect не найден в DarknessLayer")
			return
	
	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	
	if remove_after:
		await tween.finished
		layer.queue_free()

# ── ПЕРЕХОД К ОБЫЧНОЙ МУЗЫКЕ ──────────────────────────────────────────────────
func chill_music() -> void:
	Sounds.set_music("home")
