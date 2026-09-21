extends Control

signal closed

const FONT := preload("res://fonts/8bitoperator Cyrillic Extension.otf")

enum CursorItem { SAVE, RETURN }

var _cursor: int = CursorItem.SAVE
var _ready_for_input := false
var _just_saved := false

@onready var _name_lbl: Label    = $Panel/Name
@onready var _lv_lbl: Label      = $Panel/LV
@onready var _time_lbl: Label    = $Panel/Time
@onready var _save_lbl: Label    = $Panel/Save
@onready var _return_lbl: Label  = $Panel/Return
@onready var _heart: TextureRect = $Panel/Heart

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_fonts()
	_refresh_header()
	_update_cursor()
	_ready_for_input = true

func _apply_fonts() -> void:
	for n in [_name_lbl, _lv_lbl, _time_lbl, _save_lbl, _return_lbl]:
		n.add_theme_font_override("font", FONT)

func _refresh_header() -> void:
	var p : Array = Global.party if Global.party != null else []
	var key : String = str(p[0]) if not p.is_empty() else "anne"
	_name_lbl.text = PartyData.get_display_name(key).to_upper()
	_lv_lbl.text   = "ЛВ  1"
	var t := int(Global.play_time_sec)
	_time_lbl.text = "%02d:%02d:%02d" % [t / 3600, (t % 3600) / 60, t % 60]
	_just_saved = false
	_update_cursor()

func _process(_delta: float) -> void:
	# Обновляем время в реальном времени пока меню открыто
	if _ready_for_input and not _just_saved:
		var t := int(Global.play_time_sec)
		_time_lbl.text = "%02d:%02d:%02d" % [t / 3600, (t % 3600) / 60, t % 60]

func _unhandled_key_input(event: InputEvent) -> void:
	if not _ready_for_input:
		return
	if not (event is InputEventKey and event.is_pressed()):
		return

	if event.is_action_pressed("cancel"):
		_close()
		return

	# Переключение left/right, как в горизонтальном меню
	if event.is_action_pressed("left") or event.is_action_pressed("right"):
		_cursor = CursorItem.RETURN if _cursor == CursorItem.SAVE else CursorItem.SAVE
		_update_cursor()
		Sounds.play("snd_menumove")
		return

	if event.is_action_pressed("confirm") or event.is_action_pressed("ui_accept"):
		match _cursor:
			CursorItem.SAVE:
				_do_save()
			CursorItem.RETURN:
				_close()

func _update_cursor() -> void:
	_save_lbl.text   = "* СОХРАНЕНО *" if _just_saved else "СОХРАНИТЬ"
	_return_lbl.text = "НАЗАД"
	_heart.position  = Vector2(10, 60) if _cursor == CursorItem.SAVE else Vector2(356, 60)

func _do_save() -> void:
	_ready_for_input = false
	var player := get_tree().get_first_node_in_group("player")
	if player:
		Global.save_game(get_tree().current_scene.scene_file_path, player.global_position)
	Sounds.play("snd_save")
	_just_saved = true
	_update_cursor()
	var t := int(Global.play_time_sec)
	_time_lbl.text = "%02d:%02d:%02d" % [t / 3600, (t % 3600) / 60, t % 60]
	# Небольшая пауза чтобы игрок увидел "* СОХРАНЕНО *", затем авто-закрытие
	await get_tree().create_timer(0.6).timeout
	_close()

func _close() -> void:
	Sounds.play("snd_select")
	closed.emit()
	queue_free()
