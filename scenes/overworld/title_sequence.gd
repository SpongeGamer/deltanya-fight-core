extends CanvasLayer

signal title_sequence_finished

@onready var logo: Label = $Logo
@onready var text1: Label = $Text1
@onready var meme: TextureRect = $Meme
@onready var dark_rect: ColorRect = $DarkRect

@export var fade_time: float = 1.0
@export var show_time: float = 2.0
@export var pause_time: float = 0.5
@export var darken_time: float = 1.5

# TravelTrigger variables
@export_file("*.tscn") var target_scene: String = ""
@export var spawn_point: String = ""
@export var set_dark_world: bool = false

func _ready() -> void:
	logo.modulate.a = 0
	text1.modulate.a = 0
	meme.modulate.a = 0
	dark_rect.modulate.a = 0

func _add_party_members() -> void:
	if "kate" not in Global.party:
		Global.party.append("kate")
	if "egor" not in Global.party:
		Global.party.append("egor")
	# Подгружаем ноды персонажей чтобы PartyData подхватил новый состав
	Global.load_party_characters(false)

func remove_party_members() -> void:
	Global.party = ["anne"]

func _start() -> void:
	
	# Logo
	await _show_node(logo, "snd_intronoise")
	await get_tree().create_timer(pause_time).timeout
	
	# Text1
	await _show_node(text1, "snd_intronoise")
	await get_tree().create_timer(pause_time).timeout
	
	# Meme
	await _show_node(meme, "snd_intronoise")
	await get_tree().create_timer(show_time).timeout
	
	await _show_node(dark_rect)
	await get_tree().create_timer(show_time).timeout
	
	_travel()

func _show_node(node: CanvasItem, sound: String = "") -> void:
	if sound != "":
		Sounds.play(sound)
	var t := create_tween()
	t.tween_property(node, "modulate:a", 1.0, fade_time)
	await t.finished
	await get_tree().create_timer(show_time).timeout

func _travel() -> void:
	if target_scene == "":
		push_error("TravelTrigger: target_scene не задан!")
		return
	
	# Не трогаем Global.is_dark_world напрямую.
	# Передаём желаемое состояние в SceneTransition,
	# а там оно применится уже после fade_out.
	SceneTransition.travel(target_scene, spawn_point, set_dark_world)
