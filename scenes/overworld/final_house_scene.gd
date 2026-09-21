extends Node2D

@export var all_talked_dialogue : Array[DE] = []

const NPC_FLAGS := [
	"ZaharFinalSpeech",
	"DashaFinalSpeech1",
	"DashaFinalSpeech2",
	"MaxFinalSpeech",
	"NikitaFinalSpeech",
	"AlinaFinalSpeech",
	"KsuhaFinalSpeech",
	"EgorFinalSpeech",
]

const ALL_TALKED_FLAG := "final_house_all_talked"

var _exit_opened := false

func _ready() -> void:
	Global.is_dark_world = false
	Sounds.set_music("home", 0.2)
	_check_open_exit()

func _process(_delta: float) -> void:
	if _exit_opened:
		return
	_check_open_exit()

func _check_open_exit() -> void:
	for flag in NPC_FLAGS:
		if not Global.get_flag(flag):
			return

	_exit_opened = true

	if not Global.get_flag(ALL_TALKED_FLAG):
		Global.set_flag(ALL_TALKED_FLAG)
		_delayed_launch()

	var exit := get_node_or_null("FinalExit")
	if exit:
		exit.monitoring = true

func _delayed_launch() -> void:
	# Ждём пока закроется диалог с последним NPC
	await get_tree().create_timer(10.0).timeout
	_launch_dialogue(all_talked_dialogue)

func _launch_dialogue(p_dialogue: Array[DE]) -> void:
	if p_dialogue.is_empty():
		return
	var cl := CanvasLayer.new()
	cl.layer = 10
	get_tree().current_scene.add_child(cl)
	var dlg = load("res://scenes/prefabs/dialogue_system.tscn").instantiate()
	dlg.dialogue = p_dialogue.duplicate()
	dlg.caller   = self
	cl.add_child(dlg)

func open_final_speech() -> void:
	_fade_and_travel()

func _fade_and_travel() -> void:
	# Затухание музыки
	Sounds.fade_out_current(2)

	# Затемнение экрана
	var cl := CanvasLayer.new()
	cl.layer = 99
	add_child(cl)
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.modulate.a = 0.0
	rect.anchor_right  = 1.0
	rect.anchor_bottom = 1.0
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(rect)

	var fade := create_tween()
	fade.tween_property(rect, "modulate:a", 1.0, 1.8)
	await fade.finished

	get_tree().change_scene_to_file("res://scenes/overworld/final_speech.tscn")
