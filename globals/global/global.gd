extends Node

enum {
	FIGHT, ACT, ITEM, SPARE, DEFEND
}

enum DefeatContext {
	FLEE, SPARED, SNOWGRAVED
}

const YELLOW := Color("#ffff00")
const GREEN := Color("#00ff00")
const CENTER := Vector2(308.0, 171.0)

const SAVE_PATH_FMT := "user://save_%d.json"

const CHARACTER_SCENES := {
	"anne":   "res://fighters/characters/anne/anne.tscn",
	"egor":   "res://fighters/characters/egor/egor.tscn",
	"kate":   "res://fighters/characters/kate/kate.tscn",
	"nikita": "res://fighters/characters/nikita/nikita.tscn",
}

const PARTY_NAMES := {
	"anne":   "Аня",
	"kate":   "Катя",
	"egor":   "Егор",
}

const SHRUMPS_TOTAL = 4

var tp := 0.0:
	set(p_tp):
		tp = minf(p_tp, 250.0)
		tp_changed.emit()

signal tp_changed
signal monster_killed(monster: Monster, context: DefeatContext)
signal text_finished
signal dark_world_changed(is_dark: bool)
signal display_text(p_text: String, p_requires_input: bool)

var tp_coefficient := 1
var displaying_text := false
var characters: Array[Character] = []
var monsters: Array[Monster] = []
var items: Array[Item] = []
var storage: Array[Item] = []   # склад — 24 слота
var heartColor : Color = SoulType.RED.color
var last_defeated_monster: String = ""
var just_returned_from_battle: bool = false
var battle_in_progress: bool = false

var is_dark_world: bool = false:
	set(value):
		if is_dark_world == value:
			return
		is_dark_world = value
		dark_world_changed.emit(value)

var party: Array[String] = ["anne"]

var player_return_position := Vector2.ZERO
var player_spawn_point := ""
var return_scene_path := "res://scenes/prefabs/test.tscn"
var location_name := ""
var play_time_sec := 0.0
var current_save_slot := 0   # активный слот (0–2)

var chapter := 2

var flags: Dictionary = {}
var gold := 0

var shrumps_killed: int = 0
var shrumps_spared: int = 0
signal monster_spared(monster: Monster)

var knyaz_defeated := false
var knyaz_cutscene_done := false

func set_flag(p_key: String, p_value: bool = true) -> void:
	flags[p_key] = p_value

func get_flag(p_key: String) -> bool:
	return flags.get(p_key, false)

func save_game(p_scene_path: String, p_player_position: Vector2) -> void:
	# Предметы: сохраняем resource_path; "" = пустой слот
	var items_data : Array = []
	for item in items:
		items_data.append(item.resource_path if item != null and item.resource_path != "" else "")
	# Склад
	var storage_data : Array = []
	for item in storage:
		storage_data.append(item.resource_path if item != null and item.resource_path != "" else "")
	# Экипировка персонажей через PartyData
	var equipment_data : Dictionary = PartyData.serialize_equipment()
	var data := {
		"scene": p_scene_path,
		"player_x": p_player_position.x,
		"player_y": p_player_position.y,
		"party": party,
		"flags": flags,
		"chapter": chapter,
		"location_name": location_name,
		"play_time_sec": int(play_time_sec),
		"items": items_data,
		"storage": storage_data,
		"equipment": equipment_data,
		"gold": gold,
		"is_dark_world": is_dark_world,
	}
	var path := SAVE_PATH_FMT % current_save_slot
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game() -> bool:
	var path := SAVE_PATH_FMT % current_save_slot
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if not data is Dictionary:
		return false
	var raw_party : Array = data.get("party", ["anne"])
	var typed_party : Array[String] = []
	for s in raw_party:
		typed_party.append(str(s))
	party = typed_party
	flags = data.get("flags", {})
	chapter = data.get("chapter", 1)
	location_name = data.get("location_name", "")
	play_time_sec = float(data.get("play_time_sec", 0))
	player_return_position = Vector2(
		data.get("player_x", 0.0),
		data.get("player_y", 0.0)
	)
	return_scene_path = data.get("scene", "res://scenes/prefabs/test.tscn")
	gold = int(data.get("gold", 0))
	is_dark_world = bool(data.get("is_dark_world", false))
	# Предметы
	items.clear()
	var raw_items : Array = data.get("items", [])
	for path_str in raw_items:
		if str(path_str) != "":
			var loaded = load(str(path_str))
			if loaded != null:
				# usePredicate нужна ссылка на свой item
				if loaded.get("usePredicate") != null and loaded.usePredicate.get("item") == null:
					loaded.usePredicate.item = loaded
			items.append(loaded)
		else:
			items.append(null)
	# Экипировка
	var eq_data = data.get("equipment", {})
	if eq_data is Dictionary:
		PartyData.deserialize_equipment(eq_data)
	# Склад
	storage.clear()
	var raw_storage : Array = data.get("storage", [])
	for path_str in raw_storage:
		if str(path_str) != "":
			var loaded_s = load(str(path_str))
			if loaded_s != null:
				if loaded_s.get("usePredicate") != null and loaded_s.usePredicate.get("item") == null:
					loaded_s.usePredicate.item = loaded_s
			storage.append(loaded_s)
		else:
			storage.append(null)
	while storage.size() < 24:
		storage.append(null)
	return true

func has_save() -> bool:
	for i in 3:
		if FileAccess.file_exists("user://save_%d.json" % i):
			return true
	return false

func tp_percent_to_absolute(p_percent: float) -> float:
	return p_percent / 100.0 * 250.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not get_tree().paused:
		play_time_sec += delta

func _unhandled_input(p_event: InputEvent) -> void:
	if p_event is InputEventKey and p_event.is_pressed():
		if p_event.is_action("toggle_fullscreen"):
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func get_opening_line() -> String:
	var lines := PackedStringArray()
	for monster: Monster in monsters:
		var line := monster.get_opening_line()
		if line != "":
			lines.append(line)
	if lines.is_empty():
		return "  * Враг атакует!" if monsters.size() == 1 else "  * Враги атакуют!"
	return lines[randi_range(0, lines.size() - 1)]

func get_idle_line() -> String:
	var lines := PackedStringArray()
	for monster: Monster in monsters:
		if monster == null:
			continue
		var line := monster.get_idle_line()
		if line != "":
			lines.append(line)
	if lines.is_empty():
		return "  * Бой продолжается..."
	return lines[randi_range(0, lines.size() - 1)]

func delete_monster(p_monster: Monster, p_context: DefeatContext) -> void:
	var monster_index := monsters.find(p_monster)
	if monster_index != -1:
		monsters[monster_index] = null
	monster_killed.emit(p_monster, p_context)

func delete_item(p_item: int) -> void:
	items[p_item] = null

const MAX_ITEMS := 8

func add_item(p_item: Item) -> bool:
	for i in items.size():
		if items[i] == null:
			items[i] = p_item
			return true
	if items.size() < MAX_ITEMS:
		items.append(p_item)
		return true
	return false

func load_party_characters(add_to_tree: bool = true) -> void:
	for ch in characters:
		if is_instance_valid(ch) and ch.is_inside_tree():
			ch.get_parent().remove_child(ch)
			ch.queue_free()
	characters.clear()

	# В бою участвуют только первые 3 из пати
	var battle_party := party.slice(0, min(party.size(), 3))
	for member_name in battle_party:
		if not CHARACTER_SCENES.has(member_name):
			push_error("Global: нет сцены для персонажа: " + member_name)
			continue
		var scene: PackedScene = load(CHARACTER_SCENES[member_name])
		if scene == null:
			push_error("Global: не удалось загрузить " + CHARACTER_SCENES[member_name])
			continue
		var ch: Character = scene.instantiate()
		PartyData.apply_to_character(member_name, ch)

		if add_to_tree:
			add_child(ch)            # видим в бою
		characters.append(ch)        # всегда держим ссылку в массиве


func add_to_party(member_name: String) -> void:
	if party.has(member_name):
		return
	if CHARACTER_SCENES.has(member_name):
		party.append(member_name)
		print("В пати добавлен: ", member_name)
	else:
		push_error("Global: персонаж " + member_name + " не найден в CHARACTER_SCENES!")

func wait_time(p_time: float) -> Signal:
	return get_tree().create_timer(p_time).timeout

func setHeartColor(color : Color) -> void:
	heartColor = color

func clear_flag(key: String) -> void:
	flags.erase(key)
