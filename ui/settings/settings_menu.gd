extends CanvasLayer

# ═══════════════════════════════════════════════════════
# Меню настроек в стиле игры.
# Вызов: get_tree().get_first_node_in_group("settings_menu").open()
#        или SceneTransition / OverworldParty — откуда удобно.
#
# Клавиши: move_up/down — курсор, move_left/right — значение,
#           confirm — подтвердить/войти, cancel — назад/закрыть.
# ═══════════════════════════════════════════════════════

const FONT_PATH    := "res://fonts/8bitoperator Cyrillic Extension.ttf"
const COLOR_BG     := Color(0.0,  0.0,  0.0, 1.0)
const COLOR_BORDER := Color(0.2, 0.125, 0.2, 1.0)
const COLOR_TEXT   := Color(1.0,  1.0,  1.0, 1.0)
const COLOR_DIM    := Color(0.55, 0.55, 0.55, 1.0)
const COLOR_HEART  := Color(1.0,  0.0,  0.0, 1.0)
const COLOR_VALUE  := Color(1.0,  1.0,  0.0, 1.0)   # жёлтый для значений
const COLOR_WAIT   := Color(1.0,  1.0,  0.0, 1.0)   # "..." ожидание клавиши
const FONT_SIZE    := 16
const VOL_STEP     := 5       # шаг громкости в %

# ─── Аудио ────────────────────────────────────────────
const MIN_DB := -60.0
const MAX_DB :=   0.0
var _bus_master := -1
var _bus_music  := -1
var _bus_sfx    := -1

# ─── Управление ───────────────────────────────────────
# Ключ = отображаемое имя, значение = имя экшна в InputMap
const CONTROL_ACTIONS := {
	"Вверх":       "up",
	"Вниз":        "down",
	"Влево":       "left",
	"Вправо":      "right",
	"Подтвердить": "confirm",
	"Отмена":      "cancel",
	"Инвентарь":   "inventory",
}
var _waiting_for_key := ""    # action_name ожидающий перехвата клавиши

# ─── Экраны ───────────────────────────────────────────
enum Screen { MAIN, CONTROLS }
var _screen := Screen.MAIN

# ─── Главное меню — индексы строк ─────────────────────
const ITEM_MASTER     := 0
const ITEM_MUSIC      := 1
const ITEM_SFX        := 2
const ITEM_CONTROLS   := 3
const ITEM_FULLSCREEN := 4
const ITEM_BACK       := 5
const MAIN_COUNT      := 6

var _main_cursor     := 0
var _controls_cursor := 0

# ─── UI ───────────────────────────────────────────────
var _main_panel   : PanelContainer
var _ctrl_panel   : PanelContainer

var _main_hearts  : Array[Label] = []
var _main_names   : Array[Label] = []
var _main_values  : Array[Label] = []

var _ctrl_hearts  : Array[Label] = []
var _ctrl_names   : Array[Label] = []
var _ctrl_values  : Array[Label] = []
var _ctrl_actions : Array[String] = []   # action_name в порядке строк

signal closed

# ══════════════════════════════════════════════════════
func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group("settings_menu")
	_build_ui()
	_init_audio_buses()

func _init_audio_buses() -> void:
	await get_tree().process_frame
	_bus_master = AudioServer.get_bus_index("Master")
	_bus_music  = AudioServer.get_bus_index("Music")
	_bus_sfx    = AudioServer.get_bus_index("SFX")

# ═══ Открыть / закрыть ════════════════════════════════
func open() -> void:
	get_tree().paused = true
	visible = true
	_screen = Screen.MAIN
	_main_cursor = 0
	_waiting_for_key = ""
	_main_panel.visible = true
	_ctrl_panel.visible = false
	_refresh_main_values()
	_update_main_cursor()

func close() -> void:
	get_tree().paused = false
	visible = false
	closed.emit()

# ═══ Ввод ═════════════════════════════════════════════
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# Режим перехвата для переназначения клавиши
	if _waiting_for_key != "":
		if (event is InputEventKey and event.pressed) or \
		   (event is InputEventMouseButton and event.pressed):
			_do_rebind(_waiting_for_key, event)
			get_viewport().set_input_as_handled()
		return

	if _screen == Screen.MAIN:
		_handle_main_input(event)
	else:
		_handle_controls_input(event)

func _handle_main_input(event: InputEvent) -> void:
	if event.is_action_pressed("up"):
		_main_cursor = wrapi(_main_cursor - 1, 0, MAIN_COUNT)
		_update_main_cursor()
		Sounds.play("snd_select")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("down"):
		_main_cursor = wrapi(_main_cursor + 1, 0, MAIN_COUNT)
		_update_main_cursor()
		Sounds.play("snd_select")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("left"):
		_adjust_item(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("right"):
		_adjust_item(+1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_confirm_main()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		close()
		get_viewport().set_input_as_handled()

func _handle_controls_input(event: InputEvent) -> void:
	var total := _ctrl_actions.size() + 1  # +1 — строка "Назад"
	if event.is_action_pressed("up"):
		_controls_cursor = wrapi(_controls_cursor - 1, 0, total)
		_update_controls_cursor()
		Sounds.play("snd_select")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("down"):
		_controls_cursor = wrapi(_controls_cursor + 1, 0, total)
		_update_controls_cursor()
		Sounds.play("snd_select")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_confirm_controls()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_go_back_to_main()
		get_viewport().set_input_as_handled()

# ═══ Действия главного меню ═══════════════════════════
func _adjust_item(dir: int) -> void:
	match _main_cursor:
		ITEM_MASTER:     _change_volume(_bus_master, dir)
		ITEM_MUSIC:      _change_volume(_bus_music,  dir)
		ITEM_SFX:        _change_volume(_bus_sfx,    dir)
		ITEM_FULLSCREEN: _toggle_fullscreen()
	_refresh_main_values()

func _confirm_main() -> void:
	match _main_cursor:
		ITEM_MASTER, ITEM_MUSIC, ITEM_SFX:
			_adjust_item(+1)
		ITEM_CONTROLS:
			_open_controls_screen()
		ITEM_FULLSCREEN:
			_toggle_fullscreen()
			_refresh_main_values()
		ITEM_BACK:
			close()

func _confirm_controls() -> void:
	if _controls_cursor >= _ctrl_actions.size():
		_go_back_to_main()
		return
	# Начинаем перехват клавиши
	_waiting_for_key = _ctrl_actions[_controls_cursor]
	_ctrl_values[_controls_cursor].text = "..."
	_ctrl_values[_controls_cursor].add_theme_color_override("font_color", COLOR_WAIT)

func _go_back_to_main() -> void:
	_screen = Screen.MAIN
	_ctrl_panel.visible = false
	_main_panel.visible = true
	_refresh_main_values()
	_update_main_cursor()

func _open_controls_screen() -> void:
	_screen = Screen.CONTROLS
	_controls_cursor = 0
	_main_panel.visible = false
	_ctrl_panel.visible = true
	_refresh_controls_values()
	_update_controls_cursor()

# ═══ Переназначение ═══════════════════════════════════
func _do_rebind(action_name: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event)
	_waiting_for_key = ""
	_refresh_controls_values()
	_update_controls_cursor()
	Sounds.play("snd_select")

func _get_key_label(action: String) -> String:
	if not InputMap.has_action(action):
		return "—"
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "—"
	var ev := events[0]
	if ev is InputEventKey:
		var kc : int = ev.keycode if ev.keycode != KEY_NONE else ev.physical_keycode
		return OS.get_keycode_string(kc)
	if ev is InputEventMouseButton:
		match ev.button_index:
			MOUSE_BUTTON_LEFT:   return "ЛКМ"
			MOUSE_BUTTON_RIGHT:  return "ПКМ"
			MOUSE_BUTTON_MIDDLE: return "СКМ"
	return "?"

# ═══ Громкость ════════════════════════════════════════
func _change_volume(bus: int, dir: int) -> void:
	if bus < 0:
		return
	var pct := _bus_to_pct(bus)
	pct = clampi(pct + dir * VOL_STEP, 0, 100)
	var db := pct_to_db(pct)
	AudioServer.set_bus_volume_db(bus, db)
	AudioServer.set_bus_mute(bus, pct == 0)
	Sounds.play("snd_select")

func _bus_to_pct(bus: int) -> int:
	var db := AudioServer.get_bus_volume_db(bus)
	if db <= MIN_DB:
		return 0
	return roundi(db_to_linear(db) * 100.0)

func pct_to_db(pct: int) -> float:
	if pct <= 0:
		return MIN_DB
	return clampf(linear_to_db(pct / 100.0), MIN_DB, MAX_DB)

func _vol_str(bus: int) -> String:
	if bus < 0:
		return "--%"
	return str(_bus_to_pct(bus)) + "%"

# ═══ Экран ════════════════════════════════════════════
func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Sounds.play("snd_select")

func _fullscreen_str() -> String:
	return "ВКЛ" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "ВЫКЛ"

# ═══ Обновление UI ════════════════════════════════════
func _refresh_main_values() -> void:
	_main_values[ITEM_MASTER].text     = "◄ " + _vol_str(_bus_master) + " ►"
	_main_values[ITEM_MUSIC].text      = "◄ " + _vol_str(_bus_music)  + " ►"
	_main_values[ITEM_SFX].text        = "◄ " + _vol_str(_bus_sfx)    + " ►"
	_main_values[ITEM_CONTROLS].text   = "►"
	_main_values[ITEM_FULLSCREEN].text = "◄ " + _fullscreen_str()     + " ►"
	_main_values[ITEM_BACK].text       = ""

func _update_main_cursor() -> void:
	for i in MAIN_COUNT:
		var sel := (i == _main_cursor)
		_main_hearts[i].visible = sel
		_main_names[i].add_theme_color_override("font_color", COLOR_TEXT if sel else COLOR_DIM)
		_main_values[i].add_theme_color_override("font_color", COLOR_VALUE if sel else COLOR_DIM)

func _refresh_controls_values() -> void:
	for i in _ctrl_actions.size():
		_ctrl_values[i].text = _get_key_label(_ctrl_actions[i])
		_ctrl_values[i].remove_theme_color_override("font_color")

func _update_controls_cursor() -> void:
	var count := _ctrl_actions.size()
	for i in count:
		var sel := (i == _controls_cursor)
		_ctrl_hearts[i].visible = sel
		_ctrl_names[i].add_theme_color_override("font_color", COLOR_TEXT if sel else COLOR_DIM)
		if _waiting_for_key != _ctrl_actions[i]:
			_ctrl_values[i].add_theme_color_override("font_color", COLOR_VALUE if sel else COLOR_DIM)
	# Строка "Назад"
	var back_sel := (_controls_cursor == count)
	_ctrl_hearts[count].visible = back_sel
	_ctrl_names[count].add_theme_color_override("font_color", COLOR_TEXT if back_sel else COLOR_DIM)

# ═══ Построение UI ════════════════════════════════════
func _load_font() -> Font:
	return load(FONT_PATH)

func _panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = COLOR_BG
	s.border_width_left   = 3
	s.border_width_top    = 3
	s.border_width_right  = 3
	s.border_width_bottom = 3
	s.border_color = COLOR_BORDER
	s.content_margin_left   = 24
	s.content_margin_top    = 18
	s.content_margin_right  = 24
	s.content_margin_bottom = 18
	return s

func _make_label(p_text: String, p_size := FONT_SIZE, p_color := COLOR_TEXT) -> Label:
	var l := Label.new()
	l.text = p_text
	l.add_theme_font_override("font", _load_font())
	l.add_theme_font_size_override("font_size", p_size)
	l.add_theme_color_override("font_color", p_color)
	return l

func _build_ui() -> void:
	# Затемнение фона
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_main_panel = _build_panel(
		"НАСТРОЙКИ",
		["Общая громкость", "Музыка", "Звуки", "Управление", "Полноэкранный", "Назад"],
		_main_hearts, _main_names, _main_values
	)
	add_child(_main_panel)

	# Строим список экшнов для экрана управления
	var ctrl_display_names : Array[String] = []
	for k: String in CONTROL_ACTIONS:
		ctrl_display_names.append(k)
		_ctrl_actions.append(CONTROL_ACTIONS[k])
	ctrl_display_names.append("Назад")   # последняя строка

	_ctrl_panel = _build_panel(
		"УПРАВЛЕНИЕ",
		ctrl_display_names,
		_ctrl_hearts, _ctrl_names, _ctrl_values
	)
	_ctrl_panel.visible = false
	add_child(_ctrl_panel)

	# У строк "значений" в панели управления — значения действий (кроме "Назад")
	for i in _ctrl_actions.size():
		_ctrl_values[i].text = _get_key_label(_ctrl_actions[i])
	# Строка "Назад" без значения
	_ctrl_values[_ctrl_actions.size()].text = ""

func _build_panel(
	title: String,
	item_names: Array[String],
	out_hearts: Array[Label],
	out_names:  Array[Label],
	out_values: Array[Label]
) -> PanelContainer:

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(360, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Заголовок
	var title_lbl := _make_label(title, FONT_SIZE + 8)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", COLOR_BORDER)
	vbox.add_child(sep)

	# Строки меню
	for i in item_names.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)

		# Сердечко
		var heart := _make_label("♥", FONT_SIZE, COLOR_HEART)
		heart.custom_minimum_size = Vector2(18, 0)
		heart.visible = (i == 0)
		row.add_child(heart)
		out_hearts.append(heart)

		# Имя пункта
		var name_lbl := _make_label(item_names[i])
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)
		out_names.append(name_lbl)

		# Значение
		var val_lbl := _make_label("")
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_color_override("font_color", COLOR_DIM)
		row.add_child(val_lbl)
		out_values.append(val_lbl)

	return panel
