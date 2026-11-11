extends Node

## Сохраняемые настройки: громкость шин, полный экран, раскладка управления.
## Автолоад, регистрируется ПЕРВЫМ — до Global и Sounds, чтобы громкость
## применилась раньше первой мелодии.
##
## Файл: user://settings.cfg
##   %APPDATA%\Godot\app_userdata\Deltanyarune_1.0\settings.cfg

const PATH := "user://settings.cfg"
const MIN_DB := -60.0

## Master = 10%: на 100% музыка на старте звучит слишком громко.
## Это только значение по умолчанию при ПЕРВОМ запуске; дальше берётся из файла.
const DEFAULT_AUDIO := {
	"Master": 10,
	"Music": 100,
	"SFX": 100,
}
const DEFAULT_FULLSCREEN := false

var _cfg := ConfigFile.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_and_apply()


# ─── Файл ────────────────────────────────────────────────────────────────
func load_and_apply() -> void:
	_cfg = ConfigFile.new()
	if _cfg.load(PATH) != OK:
		# Первый запуск или битый файл — создаём с дефолтами.
		_write_defaults()
		save()
	_apply_audio()
	_apply_fullscreen()
	_apply_input()


func save() -> void:
	var err := _cfg.save(PATH)
	if err != OK:
		push_warning("Settings: не удалось сохранить " + PATH)


func _write_defaults() -> void:
	_cfg = ConfigFile.new()
	for bus_name: String in DEFAULT_AUDIO:
		_cfg.set_value("audio", bus_name, DEFAULT_AUDIO[bus_name])
	_cfg.set_value("display", "fullscreen", DEFAULT_FULLSCREEN)


## Сбрасывает громкость и полноэкранный режим. Раскладку управления
## не трогает: вернуть дефолтные клавиши можно только из редактора.
func reset_audio_and_display() -> void:
	for bus_name: String in DEFAULT_AUDIO:
		_cfg.set_value("audio", bus_name, DEFAULT_AUDIO[bus_name])
	_cfg.set_value("display", "fullscreen", DEFAULT_FULLSCREEN)
	_apply_audio()
	_apply_fullscreen()
	save()


# ─── Звук ────────────────────────────────────────────────────────────────
func get_bus_percent(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return 0
	var db := AudioServer.get_bus_volume_db(idx)
	if db <= MIN_DB:
		return 0
	return roundi(db_to_linear(db) * 100.0)


func set_bus_percent(bus_name: String, pct: int) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	pct = clampi(pct, 0, 100)
	var db := MIN_DB if pct <= 0 else clampf(linear_to_db(pct / 100.0), MIN_DB, 0.0)
	AudioServer.set_bus_volume_db(idx, db)
	AudioServer.set_bus_mute(idx, pct == 0)
	_cfg.set_value("audio", bus_name, pct)


func _apply_audio() -> void:
	for bus_name: String in DEFAULT_AUDIO:
		var pct := int(_cfg.get_value("audio", bus_name, DEFAULT_AUDIO[bus_name]))
		set_bus_percent(bus_name, pct)


# ─── Экран ───────────────────────────────────────────────────────────────
func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func set_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED
	)
	_cfg.set_value("display", "fullscreen", on)


func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())


func _apply_fullscreen() -> void:
	set_fullscreen(bool(_cfg.get_value("display", "fullscreen", DEFAULT_FULLSCREEN)))


# ─── Управление ──────────────────────────────────────────────────────────
## Перебиндить экшн и запомнить это. Сохранение на диск — отдельным save().
func rebind(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	var s := _event_to_string(event)
	if s == "":
		return
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	_cfg.set_value("input", action, s)


func _apply_input() -> void:
	if not _cfg.has_section("input"):
		return
	for action in _cfg.get_section_keys("input"):
		if not InputMap.has_action(action):
			continue
		var ev := _string_to_event(str(_cfg.get_value("input", action, "")))
		if ev == null:
			continue
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, ev)


static func _event_to_string(event: InputEvent) -> String:
	if event is InputEventKey:
		return "key:%d:%d" % [event.keycode, event.physical_keycode]
	if event is InputEventMouseButton:
		return "mouse:%d" % event.button_index
	return ""


static func _string_to_event(s: String) -> InputEvent:
	var p := s.split(":")
	if p.size() >= 3 and p[0] == "key":
		var ev := InputEventKey.new()
		ev.keycode = int(p[1])
		ev.physical_keycode = int(p[2])
		return ev
	if p.size() >= 2 and p[0] == "mouse":
		var mb := InputEventMouseButton.new()
		mb.button_index = int(p[1])
		return mb
	return null
