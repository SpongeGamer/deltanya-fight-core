extends Node2D

const FIRST_SCENE := "res://scenes/overworld/house_scene.tscn"
const SAVE_SLOTS  := 3

const C_SLOT_FILL  := Color(0.06, 0.18, 0.18, 1.0)
const C_SLOT_SEL   := Color(0.10, 0.28, 0.28, 1.0)
const C_BORDER_SEL := Color(0.85, 0.85, 0.95, 1.0)
const C_BORDER_DIM := Color(0.25, 0.38, 0.38, 1.0)

const MIN_DB := -60.0
const VOL_STEP := 5

const CONTROL_ACTIONS := {
	"Вверх":       "up",
	"Вниз":        "down",
	"Влево":       "left",
	"Вправо":      "right",
	"Подтвердить": "confirm",
	"Отмена":      "cancel",
	"Инвентарь":   "inventory",
}

enum Screen { MAIN, SLOTS, SETTINGS, CONTROLS }
enum SlotMode { CONTINUE, NEW_GAME }

var _screen    := Screen.MAIN
var _slot_mode := SlotMode.CONTINUE
var _cursor    := 0
var _saves     : Array[Dictionary] = []
var _ready_for_input := false
var _waiting_for_key := ""

# ── Ноды ──────────────────────────────────────────────
@onready var _main_screen     : Control = $MainScreen
@onready var _slots_screen    : Control = $SlotsScreen
@onready var _settings_screen : Control = $SettingsScreen
@onready var _controls_screen : Control = $ControlsScreen
@onready var _heart           : Sprite2D = $Heart

@onready var _main_panels : Array[Panel] = [
	$MainScreen/Panels/Continue,
	$MainScreen/Panels/NewGame,
	$MainScreen/Panels/Settings,
	$MainScreen/Panels/Quit,
]

@onready var _slot_panels : Array[Panel] = [
	$SlotsScreen/Slots/Slot0,
	$SlotsScreen/Slots/Slot1,
	$SlotsScreen/Slots/Slot2,
]
@onready var _slot_name_labels : Array[Label] = [
	$SlotsScreen/Slots/Slot0/Top/Name,
	$SlotsScreen/Slots/Slot1/Top/Name,
	$SlotsScreen/Slots/Slot2/Top/Name,
]
@onready var _slot_time_labels : Array[Label] = [
	$SlotsScreen/Slots/Slot0/Top/Time,
	$SlotsScreen/Slots/Slot1/Top/Time,
	$SlotsScreen/Slots/Slot2/Top/Time,
]
@onready var _slot_loc_labels : Array[Label] = [
	$SlotsScreen/Slots/Slot0/Bot/Location,
	$SlotsScreen/Slots/Slot1/Bot/Location,
	$SlotsScreen/Slots/Slot2/Bot/Location,
]

# Settings panels (Master, Music, SFX, Controls, Fullscreen, Back)
@onready var _settings_panels : Array[Panel] = [
	$SettingsScreen/Panels/Master,
	$SettingsScreen/Panels/Music,
	$SettingsScreen/Panels/SFX,
	$SettingsScreen/Panels/Controls,
	$SettingsScreen/Panels/Fullscreen,
	$SettingsScreen/Panels/Back,
]
@onready var _val_master     : Label = $SettingsScreen/Panels/Master/Value
@onready var _val_music      : Label = $SettingsScreen/Panels/Music/Value
@onready var _val_sfx        : Label = $SettingsScreen/Panels/SFX/Value
@onready var _val_fullscreen : Label = $SettingsScreen/Panels/Fullscreen/Value

# Controls panels (one per action + Back)
@onready var _ctrl_panels : Array[Panel] = [
	$ControlsScreen/Panels/Up,
	$ControlsScreen/Panels/Down,
	$ControlsScreen/Panels/Left,
	$ControlsScreen/Panels/Right,
	$ControlsScreen/Panels/Confirm,
	$ControlsScreen/Panels/Cancel,
	$ControlsScreen/Panels/Inventory,
	$ControlsScreen/Panels/Back,
]
@onready var _ctrl_value_labels : Array[Label] = [
	$ControlsScreen/Panels/Up/Value,
	$ControlsScreen/Panels/Down/Value,
	$ControlsScreen/Panels/Left/Value,
	$ControlsScreen/Panels/Right/Value,
	$ControlsScreen/Panels/Confirm/Value,
	$ControlsScreen/Panels/Cancel/Value,
	$ControlsScreen/Panels/Inventory/Value,
	$ControlsScreen/Panels/Back/Value,
]

# ── _ready ────────────────────────────────────────────
func _ready() -> void:
	_load_all_saves()
	_refresh_slot_labels()
	_slots_screen.visible    = false
	_settings_screen.visible = false
	_controls_screen.visible = false
	_refresh_settings_values()
	_refresh_ctrl_values()
	_update_cursor()

	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.5)
	tw.tween_callback(func(): _ready_for_input = true)

	Sounds.set_music("menu_music", 0.8)

# ── Сохранения ───────────────────────────────────────
func _save_path(i: int) -> String:
	return "user://save_%d.json" % i

func _load_all_saves() -> void:
	_saves.clear()
	for i in SAVE_SLOTS:
		if not FileAccess.file_exists(_save_path(i)):
			_saves.append({})
			continue
		var f := FileAccess.open(_save_path(i), FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text()) if f else null
		if f: f.close()
		_saves.append(d if d is Dictionary else {})

func _has(i: int) -> bool:
	return not _saves[i].is_empty()

func _refresh_slot_labels() -> void:
	for i in SAVE_SLOTS:
		if _has(i):
			var p : Array = _saves[i].get("party", ["anne"])
			_slot_name_labels[i].text = PartyData.get_display_name(p[0]).to_upper() if not p.is_empty() else "???"
			var t := int(_saves[i].get("play_time_sec", 0))
			_slot_time_labels[i].text = "%02d:%02d" % [t / 3600, (t % 3600) / 60]
			_slot_loc_labels[i].text  = _saves[i].get("location_name", "???")
		else:
			_slot_name_labels[i].text = "[ПУСТО]"
			_slot_time_labels[i].text = "--:--"
			_slot_loc_labels[i].text  = "———————————"

# ── Настройки — значения ─────────────────────────────
func _bus_pct(name: String) -> int:
	var bus := AudioServer.get_bus_index(name)
	if bus < 0: return 0
	var db := AudioServer.get_bus_volume_db(bus)
	if db <= MIN_DB: return 0
	return roundi(db_to_linear(db) * 100.0)

func _set_bus_pct(name: String, pct: int) -> void:
	var bus := AudioServer.get_bus_index(name)
	if bus < 0: return
	var db := MIN_DB if pct <= 0 else clampf(linear_to_db(pct / 100.0), MIN_DB, 0.0)
	AudioServer.set_bus_volume_db(bus, db)
	AudioServer.set_bus_mute(bus, pct == 0)

func _vol_str(name: String) -> String:
	return "◄ %d%% ►" % _bus_pct(name)

func _refresh_settings_values() -> void:
	_val_master.text     = _vol_str("Master")
	_val_music.text      = _vol_str("Music")
	_val_sfx.text        = _vol_str("SFX")
	_val_fullscreen.text = "◄ %s ►" % ("ВКЛ" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "ВЫКЛ")

func _refresh_ctrl_values() -> void:
	var actions := CONTROL_ACTIONS.values()
	for i in actions.size():
		_ctrl_value_labels[i].text = _get_key_label(actions[i])

func _get_key_label(action: String) -> String:
	if not InputMap.has_action(action): return "—"
	var events := InputMap.action_get_events(action)
	if events.is_empty(): return "—"
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

# ── Ввод ─────────────────────────────────────────────
func _unhandled_key_input(event: InputEvent) -> void:
	if not _ready_for_input: return

	# Перехват клавиши для переназначения
	if _waiting_for_key != "":
		if (event is InputEventKey and event.pressed) or \
		   (event is InputEventMouseButton and event.pressed):
			InputMap.action_erase_events(_waiting_for_key)
			InputMap.action_add_event(_waiting_for_key, event)
			_waiting_for_key = ""
			_refresh_ctrl_values()
			_update_cursor()
			Sounds.play("snd_select")
			get_viewport().set_input_as_handled()
		return

	var count := _get_count()
	if event.is_action_pressed("up"):
		_cursor = wrapi(_cursor - 1, 0, count)
		_update_cursor(); Sounds.play("snd_menumove")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("down"):
		_cursor = wrapi(_cursor + 1, 0, count)
		_update_cursor(); Sounds.play("snd_menumove")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("left"):
		_adjust(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("right"):
		_adjust(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_back()
		get_viewport().set_input_as_handled()

func _get_count() -> int:
	match _screen:
		Screen.MAIN:     return _main_panels.size()
		Screen.SLOTS:    return SAVE_SLOTS
		Screen.SETTINGS: return _settings_panels.size()
		Screen.CONTROLS: return _ctrl_panels.size()
	return 1

func _adjust(dir: int) -> void:
	if _screen == Screen.SETTINGS:
		match _cursor:
			0: _set_bus_pct("Master", clampi(_bus_pct("Master") + dir * VOL_STEP, 0, 100)); Sounds.play("snd_menumove")
			1: _set_bus_pct("Music",  clampi(_bus_pct("Music")  + dir * VOL_STEP, 0, 100)); Sounds.play("snd_menumove")
			2: _set_bus_pct("SFX",    clampi(_bus_pct("SFX")    + dir * VOL_STEP, 0, 100)); Sounds.play("snd_menumove")
			4: _toggle_fullscreen()
		_refresh_settings_values()

func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Sounds.play("snd_select")

func _confirm() -> void:
	match _screen:
		Screen.MAIN:
			match _cursor:
				0: _go_to(Screen.SLOTS,    SlotMode.CONTINUE)
				1: _go_to(Screen.SLOTS,    SlotMode.NEW_GAME)
				2: _go_to(Screen.SETTINGS)
				3: get_tree().quit()
		Screen.SLOTS:
			_confirm_slot(_cursor)
		Screen.SETTINGS:
			match _cursor:
				0, 1, 2: _adjust(1)
				3: _go_to(Screen.CONTROLS)
				4: _toggle_fullscreen(); _refresh_settings_values()
				5: _back()
		Screen.CONTROLS:
			if _cursor < CONTROL_ACTIONS.size():
				_waiting_for_key = CONTROL_ACTIONS.values()[_cursor]
				_ctrl_value_labels[_cursor].text = "..."
				Sounds.play("snd_select")
			else:
				_back()

func _back() -> void:
	match _screen:
		Screen.SLOTS:    _go_to(Screen.MAIN)
		Screen.SETTINGS: _go_to(Screen.MAIN)
		Screen.CONTROLS: _go_to(Screen.SETTINGS)

func _go_to(screen: Screen, slot_mode: SlotMode = SlotMode.CONTINUE) -> void:
	Sounds.play("snd_select")
	_main_screen.visible     = (screen == Screen.MAIN)
	_slots_screen.visible    = (screen == Screen.SLOTS)
	_settings_screen.visible = (screen == Screen.SETTINGS)
	_controls_screen.visible = (screen == Screen.CONTROLS)
	_screen    = screen
	_slot_mode = slot_mode
	_cursor    = 0
	_update_cursor()

func _confirm_slot(i: int) -> void:
	_ready_for_input = false
	Sounds.play("snd_select")
	if _slot_mode == SlotMode.CONTINUE:
		if not _has(i): _ready_for_input = true; return
		_load_and_travel(i)
	else:
		_start_new(i)

func _load_and_travel(i: int) -> void:
	Global.current_save_slot = i
	Global.load_game()
	
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): 
		SceneTransition.travel(
			Global.return_scene_path, 
			"",                        # spawn_point (не нужен, т.к. используем saved position)
			Global.is_dark_world,      # set_dark_world
			true                       # spawn_player
		)
	)

func _start_new(i: int) -> void:
	Global.current_save_slot  = i
	Global.party              = ["anne"]
	Global.flags              = {}
	Global.chapter            = 2
	Global.player_spawn_point = ""
	Global.player_return_position = Vector2.ZERO  # Важно сбросить
	Global.location_name      = ""
	Global.play_time_sec      = 0.0
	Global.gold               = 0
	Global.is_dark_world      = false
	Global.items.clear()
	
	for ch in Global.characters:
		if is_instance_valid(ch) and ch.is_inside_tree():
			ch.queue_free()
	Global.characters.clear()
	PartyData._ready()
	
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): 
		SceneTransition.travel(FIRST_SCENE, "", false, true)
	)

# ── Курсор ───────────────────────────────────────────
func _update_cursor() -> void:
	var panels : Array[Panel]
	match _screen:
		Screen.MAIN:     panels = _main_panels
		Screen.SLOTS:    panels = _slot_panels
		Screen.SETTINGS: panels = _settings_panels
		Screen.CONTROLS: panels = _ctrl_panels

	for i in panels.size():
		_style_panel(panels[i], i == _cursor)

	if _heart and _cursor < panels.size():
		var p := panels[_cursor]
		_heart.position = p.global_position + Vector2(-18.0, p.size.y / 2.0)

func _style_panel(panel: Panel, sel: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color            = C_SLOT_SEL  if sel else C_SLOT_FILL
	s.border_width_left   = 2
	s.border_width_top    = 2
	s.border_width_right  = 2
	s.border_width_bottom = 2
	s.border_color        = C_BORDER_SEL if sel else C_BORDER_DIM
	s.content_margin_left   = 14
	s.content_margin_top    = 8
	s.content_margin_right  = 14
	s.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", s)
