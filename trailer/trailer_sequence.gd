extends CanvasLayer

# =====================================================================
# ТРЕЙЛЕР DELTANYARUNE — trailer_sequence.gd
# =====================================================================

const FONT_PATH := "res://fonts/8bitoperator Cyrillic Extension.otf"

@export var anne_sprite: Sprite2D = null
@export var zzz_parent: Node2D = null

# Тексты для показа
@export var title_label: Label = null
@export var chapter_label: Label = null
@export var date_label: Label = null

# Настройки показа текстов
@export var fade_time: float = 1.0
@export var show_time: float = 2.0
@export var pause_time: float = 0.5

const T_SLEEP_BEFORE_TURN := 2.5
const T_AFTER_TURN_HOLD := 1.8
const T_EYES_FLICKER := 2.0

var _font: Font
var _darkness: ColorRect
var _eyes_root: Control
var _zzz_active := false
var _camera: Camera2D = null
var _effect_rect: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	
	_camera = get_viewport().get_camera_2d()
	if not _camera:
		_camera = Camera2D.new()
		_camera.zoom = Vector2(1, 1)
		add_child(_camera)
		_camera.make_current()
	
	# Скрываем тексты
	if title_label:
		title_label.modulate.a = 0
		title_label.z_index = 5000
	if chapter_label:
		chapter_label.modulate.a = 0
		chapter_label.z_index = 5000
	if date_label:
		date_label.modulate.a = 0
		date_label.z_index = 5000
	
	_build_layers()
	_setup_effect()
	call_deferred("_play_trailer")

func _setup_effect() -> void:
	var effect_layer = CanvasLayer.new()
	effect_layer.layer = 100
	add_child(effect_layer)
	
	_effect_rect = ColorRect.new()
	_effect_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_effect_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effect_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	effect_layer.add_child(_effect_rect)

func _apply_light_pulse() -> void:
	_effect_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	
	var tween := create_tween()
	tween.set_loops(2)
	tween.tween_property(_effect_rect, "color", Color(1.0, 1.0, 1.0, 0.5), 0.8)
	tween.tween_property(_effect_rect, "color", Color(1.0, 1.0, 1.0, 0.0), 0.8)
	
	_play_sound("snd_cymbal", 0.5)
	await tween.finished
	
	var tween2 := create_tween()
	tween2.tween_property(_effect_rect, "color", Color.BLACK, 2.0)
	await tween2.finished
	
	_effect_rect.visible = false

func _build_layers() -> void:
	var bg := _fullscreen_rect(Color.BLACK)
	bg.z_index = -10
	add_child(bg)
	
	_darkness = _fullscreen_rect(Color(0, 0, 0, 0))
	_darkness.z_index = 1000
	add_child(_darkness)
	
	_eyes_root = _build_eyes()
	_eyes_root.visible = false
	_eyes_root.z_index = 3000
	add_child(_eyes_root)

func _build_eyes() -> Control:
	var container := Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var eye_positions := [Vector2(260, 200), Vector2(360, 200)]
	
	for pos in eye_positions:
		var white := ColorRect.new()
		white.color = Color.WHITE
		white.size = Vector2(32, 24)
		white.position = pos
		container.add_child(white)
		
		var pupil := ColorRect.new()
		pupil.color = Color(0.3, 0.3, 0.4, 1.0)
		pupil.size = Vector2(12, 12)
		pupil.position = pos + Vector2(10, 6)
		container.add_child(pupil)
		
		var glint := ColorRect.new()
		glint.color = Color(0.8, 0.8, 0.9, 0.8)
		glint.size = Vector2(4, 4)
		glint.position = pos + Vector2(6, 4)
		container.add_child(glint)
	
	return container

func _animate_anne() -> void:
	if not anne_sprite:
		return
	
	anne_sprite.frame_coords.x = 0
	await get_tree().create_timer(T_SLEEP_BEFORE_TURN).timeout
	
	_play_sound("snd_noise")
	anne_sprite.frame_coords.x = 1
	await get_tree().create_timer(T_AFTER_TURN_HOLD).timeout
	
	_play_sound("snd_noise")
	anne_sprite.frame_coords.x = 0
	await get_tree().create_timer(0.8).timeout
	
	_play_sound("snd_noise")
	anne_sprite.frame_coords.x = 2
	await get_tree().create_timer(T_AFTER_TURN_HOLD).timeout

func _spawn_zzz_loop() -> void:
	_zzz_active = true
	while _zzz_active and is_inside_tree():
		_create_zzz()
		await get_tree().create_timer(randf_range(1.6, 2.0)).timeout

func _create_zzz() -> void:
	if not zzz_parent:
		return
	
	var size := randi_range(100, 160)
	# Спавн выше и с разбросом по горизонтали
	var start_x := randf_range(-250, -250)   # От левого плеча до правого
	var start_y := randf_range(-250, -250)   # Выше (голова/шея)
	
	# Три слоя для объёмной буквы
	var layers = []
	for col in [Color(0.05,0.02,0.1), Color(0.5,0.5,0.6), Color(0.95,0.95,1.0)]:
		var lbl = Label.new()
		lbl.text = "Z"
		if _font:
			lbl.add_theme_font_override("font", _font)
		lbl.add_theme_font_size_override("font_size", size)
		lbl.add_theme_color_override("font_color", col)
		lbl.add_theme_constant_override("outline_size", 4)
		lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.2))
		lbl.position = Vector2(start_x, start_y)
		lbl.scale = Vector2(0.4, 0.4)
		zzz_parent.add_child(lbl)
		layers.append(lbl)
	
	# Разные траектории для каждой буквы
	var travel_y := randf_range(-120, -200)
	var travel_x := randf_range(-80, 80)
	var duration := randf_range(1.2, 1.8)
	var rotation := randf_range(-20, 20)
	
	for lbl in layers:
		# Появление с увеличением
		var t1 = create_tween()
		t1.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)
		
		# Полёт
		var t2 = create_tween()
		t2.set_parallel(true)
		t2.tween_property(lbl, "position:x", lbl.position.x + travel_x, duration).set_ease(Tween.EASE_OUT)
		t2.tween_property(lbl, "position:y", lbl.position.y + travel_y, duration).set_ease(Tween.EASE_OUT)
		t2.tween_property(lbl, "rotation_degrees", rotation, duration).set_ease(Tween.EASE_OUT)
		
		# Затухание
		var t3 = create_tween()
		t3.tween_interval(duration - 0.5)
		t3.tween_property(lbl, "modulate:a", 0.0, 0.5)
		
		t2.finished.connect(lbl.queue_free)
		
		
func _play_trailer() -> void:
	_play_sound("snd_intronoise", 0.5)
	_spawn_zzz_loop()
	await _animate_anne()
	_zzz_active = false
	
	await _apply_light_pulse()
	
	if anne_sprite:
		anne_sprite.visible = false
	var bed := get_node_or_null("BedSprite")
	if bed:
		bed.visible = false
	
	await get_tree().create_timer(20.0).timeout
	
	_eyes_root.visible = true
	_eyes_root.modulate.a = 0.0
	
	_play_sound("snd_eyeflash", 0.5)
	var eye_in := create_tween()
	eye_in.tween_property(_eyes_root, "modulate:a", 1.0, 0.5)
	await eye_in.finished
	
	await _flicker_eyes(T_EYES_FLICKER)
	
	var eye_out := create_tween()
	eye_out.tween_property(_eyes_root, "modulate:a", 0.0, 0.3)
	await eye_out.finished
	_eyes_root.visible = false
	
	await get_tree().create_timer(0.5).timeout
	
	if title_label:
		await _show_node(title_label, "snd_intronoise")
		await get_tree().create_timer(pause_time).timeout
	
	if chapter_label:
		await _show_node(chapter_label, "snd_intronoise")
		await get_tree().create_timer(pause_time).timeout
	
	if date_label:
		await _show_node(date_label, "snd_intronoise")
		await get_tree().create_timer(pause_time).timeout

func _flicker_eyes(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		var pause := randf_range(0.08, 0.45)
		elapsed += pause
		var tw := create_tween()
		tw.tween_property(_eyes_root, "modulate:a", randf_range(0.25, 0.7), 0.06)
		tw.tween_property(_eyes_root, "modulate:a", 1.0, randf_range(0.06, 0.18))
		await tw.finished
		await get_tree().create_timer(pause).timeout

func _fullscreen_rect(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	return r

func _play_sound(sound: String, volume := 1.0) -> void:
	var player := AudioStreamPlayer.new()
	var stream_path := "res://globals/sounds/sound_effects/" + sound + ".ogg"
	if not ResourceLoader.exists(stream_path):
		stream_path = "res://globals/sounds/sound_effects/" + sound + ".wav"
	if ResourceLoader.exists(stream_path):
		player.stream = load(stream_path)
		player.volume_db = linear_to_db(volume)
		add_child(player)
		player.play()
		player.finished.connect(player.queue_free)

func _show_node(node: CanvasItem, sound: String = "") -> void:
	if sound != "":
		_play_sound(sound)
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", 1.0, fade_time)
	await tw.finished
