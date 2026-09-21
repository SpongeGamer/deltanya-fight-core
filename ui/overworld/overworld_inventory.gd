extends Control

enum Tab { ITEM, STAT }
enum BottomAction { USE, INFO, DROP }
enum StatMode { BROWSE, EQUIP_SELECT }

var current_tab  := Tab.ITEM
var stat_mode    := StatMode.BROWSE

var selected_index := 0
var items_list: Array = []
var bottom_focused := false
var bottom_index   := 0
var show_long_desc := false
var char_select_mode := false   # выбор персонажа для использования предмета
var char_select_index := 0

var stat_char_index := 0
var stat_cursor     := 0
var equip_items:    Array = []
var equip_cursor    := 0

const CHAR_COLORS := {
	"anne": Color("#ff4444"),
	"kate": Color("#cc44ff"),
	"egor": Color("#ff8800"),
}

const HEART_TEX := preload("res://globals/global/res/heart.png")
const FONT      := preload("res://fonts/8bitoperator Cyrillic Extension.otf")
const ROW_HEIGHT := 32
const YELLOW := Color("#ffff00")
const GRAY   := Color(0.45, 0.45, 0.45)
const WHITE  := Color.WHITE

@onready var tab_buttons: Array[Button] = [
	$Left/Tabs/ItemBtn, $Left/Tabs/StatBtn
]
@onready var item_list_container: VBoxContainer = $Right/ItemScroll/ItemList
@onready var info_label:          RichTextLabel  = $InfoLabel
@onready var bottom_actions: Array[Label] = [
	$Right/BottomBar/Use, $Right/BottomBar/Info, $Right/BottomBar/Drop
]
@onready var char_name_label: Label = $Left/CharInfo/Name
@onready var hp_label:        Label = $Left/CharInfo/HP
@onready var money_label:     Label = $Left/CharInfo/Money
@onready var stat_panel: VBoxContainer = $Right/StatPanel

var _stat_char_label:  Label = null
var _char_select_panel : VBoxContainer = null
var _char_select_rows  : Array[Control] = []
var _stat_arrow_l:     Label = null
var _stat_arrow_r:     Label = null
var _stat_heart:       TextureRect = null
var _stat_hp:          Label = null
var _stat_atk:         Label = null
var _stat_def:         Label = null
var _stat_mag:         Label = null
var _equip_rows:       Array = []
var _equip_list_cont:  VBoxContainer = null
var _equip_scroll:     ScrollContainer = null

var player_node: CharacterBody2D = null

func _ready() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		player_node = node
	# Перезагружаем если characters пустой, невалидный или не совпадает с party по размеру
	var _needs_reload := Global.characters.is_empty()
	if not _needs_reload:
		if Global.characters.size() != Global.party.size():
			_needs_reload = true
		else:
			for _ch in Global.characters:
				if not is_instance_valid(_ch):
					_needs_reload = true
					break
	if _needs_reload:
		Global.load_party_characters(false)
	_build_stat_panel()
	_refresh_char_info()
	_switch_tab(Tab.ITEM)

func _get_party_name(key: String) -> String:
	return PartyData.get_display_name(key)

func _get_char_color(key: String) -> Color:
	return PartyData.get_color(key)

func _refresh_char_info() -> void:
	var key := Global.party[0] if !Global.party.is_empty() else "anne"
	char_name_label.text = _get_party_name(key)
	if not Global.characters.is_empty() and is_instance_valid(Global.characters[0]):
		var ch: Character = Global.characters[0]
		hp_label.text = "ХП  %d/ %d" % [ch.current_hp, ch.get_max_hp()]
	else:
		hp_label.text = "ХП  ??/ ??"
	money_label.text = "Р  %d" % Global.gold

func _make_row(label_text: String, color: Color = WHITE) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var heart := TextureRect.new()
	heart.name = "Heart"
	heart.texture = HEART_TEX
	heart.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	heart.custom_minimum_size = Vector2(ROW_HEIGHT, ROW_HEIGHT)
	heart.size = Vector2(ROW_HEIGHT, ROW_HEIGHT)
	heart.visible = false
	row.add_child(heart)

	var lbl := Label.new()
	lbl.name = "Title"
	lbl.text = label_text
	lbl.add_theme_font_override("font", FONT)
	lbl.add_theme_color_override("font_color", color)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(ROW_HEIGHT + 2, 0)
	lbl.size = Vector2(300, ROW_HEIGHT)
	row.add_child(lbl)

	return row

func _build_stat_panel() -> void:
	for ch in stat_panel.get_children():
		ch.queue_free()

	var name_row := HBoxContainer.new()
	name_row.custom_minimum_size = Vector2(0, 36)

	_stat_arrow_l = Label.new()
	_stat_arrow_l.add_theme_font_override("font", FONT)
	_stat_arrow_l.text = "◄ "
	_stat_arrow_l.visible = false
	name_row.add_child(_stat_arrow_l)

	_stat_heart = TextureRect.new()
	_stat_heart.texture = HEART_TEX
	_stat_heart.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_stat_heart.custom_minimum_size = Vector2(20, 32)
	name_row.add_child(_stat_heart)

	_stat_char_label = Label.new()
	_stat_char_label.add_theme_font_override("font", FONT)
	_stat_char_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stat_char_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_stat_char_label.text = "???"
	name_row.add_child(_stat_char_label)

	_stat_arrow_r = Label.new()
	_stat_arrow_r.add_theme_font_override("font", FONT)
	_stat_arrow_r.text = " ►"
	_stat_arrow_r.visible = false
	name_row.add_child(_stat_arrow_r)

	stat_panel.add_child(name_row)
	stat_panel.add_child(HSeparator.new())

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 8)
	stat_panel.add_child(cols)

	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 6)
	cols.add_child(left_col)

	var stats_header := Label.new()
	stats_header.add_theme_font_override("font", FONT)
	stats_header.add_theme_color_override("font_color", GRAY)
	stats_header.text = "СТАТЫ"
	stats_header.custom_minimum_size = Vector2(0, 32)
	stats_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	left_col.add_child(stats_header)

	_stat_hp  = _make_stat_label("ХП:  0/ 0")
	_stat_atk = _make_stat_label("АТК:  0")
	_stat_def = _make_stat_label("ЗЩТ:  0")
	_stat_mag = _make_stat_label("МАГ:  0")
	for lbl in [_stat_hp, _stat_atk, _stat_def, _stat_mag]:
		left_col.add_child(lbl)

	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 6)
	cols.add_child(right_col)

	var equip_header := Label.new()
	equip_header.add_theme_font_override("font", FONT)
	equip_header.add_theme_color_override("font_color", GRAY)
	equip_header.text = "ЭКИПИРОВАНО"
	equip_header.custom_minimum_size = Vector2(0, 32)
	equip_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	right_col.add_child(equip_header)

	_equip_rows.clear()
	var slot_names := ["Оружие", "Броня I", "Броня II"]
	for i in 3:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 28)

		var cursor_lbl := Label.new()
		cursor_lbl.name = "Cursor"
		cursor_lbl.add_theme_font_override("font", FONT)
		cursor_lbl.add_theme_color_override("font_color", YELLOW)
		cursor_lbl.text = "♥"
		cursor_lbl.custom_minimum_size = Vector2(16, 16)
		cursor_lbl.visible = false
		row.add_child(cursor_lbl)

		var item_lbl := Label.new()
		item_lbl.name = "Item"
		item_lbl.add_theme_font_override("font", FONT)
		item_lbl.add_theme_color_override("font_color", GRAY)
		item_lbl.text = slot_names[i]
		item_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		item_lbl.custom_minimum_size = Vector2(0, 28)
		row.add_child(item_lbl)

		right_col.add_child(row)
		_equip_rows.append(row)

	# FIX: SIZE_EXPAND_FILL чтобы контейнер не сжимался и текст не резался
	_equip_scroll = ScrollContainer.new()
	_equip_scroll.custom_minimum_size = Vector2(0, 90)
	_equip_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equip_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_equip_scroll.visible = false
	stat_panel.add_child(_equip_scroll)

	_equip_list_cont = VBoxContainer.new()
	_equip_list_cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equip_list_cont.add_theme_constant_override("separation", 2)
	_equip_scroll.add_child(_equip_list_cont)

func _make_stat_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_override("font", FONT)
	lbl.text = text
	lbl.custom_minimum_size = Vector2(0, 34)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return lbl

func _refresh_stat_panel() -> void:
	if Global.characters.is_empty():
		_stat_char_label.text = "???"
		_stat_arrow_l.visible = false
		_stat_arrow_r.visible = false
		_stat_hp.text  = "ХП:  ??/ ??"
		_stat_atk.text = "АТК:  ?"
		_stat_def.text = "ЗЩТ:  ?"
		_stat_mag.text = "МАГ:  ?"
		return

	stat_char_index = clampi(stat_char_index, 0, Global.characters.size() - 1)
	var ch: Character = Global.characters[stat_char_index]
	var key := Global.party[stat_char_index] if stat_char_index < Global.party.size() else ""

	_stat_char_label.text = _get_party_name(key)
	_stat_heart.modulate  = _get_char_color(key)
	_stat_arrow_l.visible = stat_char_index > 0
	_stat_arrow_r.visible = stat_char_index < Global.characters.size() - 1

	var base_atk: int = ch.base_fighter_stats.get(AbstractFighter.Stats.ATTACK,  AbstractFighter.FALLBACK_STATS[AbstractFighter.Stats.ATTACK])
	var base_def: int = ch.base_fighter_stats.get(AbstractFighter.Stats.DEFENSE, AbstractFighter.FALLBACK_STATS[AbstractFighter.Stats.DEFENSE])
	var base_mag: int = ch.base_fighter_stats.get(AbstractFighter.Stats.MAGIC,   AbstractFighter.FALLBACK_STATS[AbstractFighter.Stats.MAGIC])
	var tot_atk := ch.get_value_from_stat(AbstractFighter.Stats.ATTACK)
	var tot_def := ch.get_value_from_stat(AbstractFighter.Stats.DEFENSE)
	var tot_mag := ch.get_value_from_stat(AbstractFighter.Stats.MAGIC)

	_stat_hp.text  = "ХП:  %d/ %d" % [ch.current_hp, ch.get_max_hp()]
	_stat_atk.text = "АТК:  %d%s"  % [tot_atk, _bonus_str(tot_atk - base_atk)]
	_stat_def.text = "ЗЩТ:  %d%s"  % [tot_def, _bonus_str(tot_def - base_def)]
	_stat_mag.text = "МАГ:  %d%s"   % [tot_mag, _bonus_str(tot_mag - base_mag)]

	var equippables := [ch.weapon] + ch.armors
	var slot_names  := ["Оружие", "Броня I", "Броня II"]
	for i in _equip_rows.size():
		var item_lbl: Label  = _equip_rows[i].get_node("Item")
		var cursor:   Label  = _equip_rows[i].get_node("Cursor")
		var eq = equippables[i] if i < equippables.size() else null
		if eq != null:
			item_lbl.text = eq.name if eq.get("name") else "???"
			item_lbl.add_theme_color_override("font_color", WHITE)
		else:
			item_lbl.text = slot_names[i]
			item_lbl.add_theme_color_override("font_color", GRAY)
		cursor.visible = (stat_mode == StatMode.BROWSE) and (stat_cursor == i + 1)

func _bonus_str(bonus: int) -> String:
	if bonus > 0: return " (+%d)" % bonus
	if bonus < 0: return " (%d)" % bonus
	return ""

func _enter_equip_select(slot: int) -> void:
	stat_mode = StatMode.EQUIP_SELECT
	equip_cursor = 0
	equip_items.clear()
	var tab_filter: Item.InventoryTab = Item.InventoryTab.WEAPONS if slot == 1 else Item.InventoryTab.ARMORS
	var ch: Character = Global.characters[stat_char_index]
	for item in Global.items:
		if item == null or item.inventory_tab != tab_filter:
			continue
		if item is Equippable and item.category in ch.willNotEquip:
			continue
		equip_items.append(item)
	_equip_scroll.visible = true
	_refresh_equip_list()

func _refresh_equip_list() -> void:
	for ch in _equip_list_cont.get_children():
		ch.queue_free()
	if equip_items.is_empty():
		var empty := Label.new()
		empty.add_theme_font_override("font", FONT)
		empty.add_theme_color_override("font_color", GRAY)
		empty.text = "(нет предметов)"
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(0, 32)
		empty.clip_text = false
		_equip_list_cont.add_child(empty)
		return
	_equip_list_cont.add_child(_make_row("(снять)", GRAY))
	for item in equip_items:
		_equip_list_cont.add_child(_make_row(item.name))
	_update_equip_cursor()

func _update_equip_cursor() -> void:
	for i in _equip_list_cont.get_children().size():
		var heart: TextureRect = _equip_list_cont.get_children()[i].get_node_or_null("Heart")
		if heart: heart.visible = (i == equip_cursor)

func _do_equip(slot: int) -> void:
	var ch: Character = Global.characters[stat_char_index]
	var key := Global.party[stat_char_index] if stat_char_index < Global.party.size() else ""
	
	if equip_cursor == 0:
		# Снимаем предмет и возвращаем в инвентарь
		var old_item = null
		if slot == 1:
			old_item = ch.weapon
			ch.weapon = null
		else:
			old_item = ch.armors[slot - 2] if slot - 2 < ch.armors.size() else null
			ch.swap_armor(slot - 2, null)
		
		# Возвращаем предмет в инвентарь
		if old_item != null:
			Global.add_item(old_item)
	else:
		var item = equip_items[equip_cursor - 1]
		if item is Equippable and item.category in ch.willNotEquip:
			Sounds.play("snd_menumove")
			return
		if item is Equippable:
			# 1. Удаляем предмет из инвентаря
			var idx := Global.items.find(item)
			if idx != -1:
				Global.delete_item(idx)
			
			# 2. Экипируем
			if slot == 1:
				ch.weapon = item
			else:
				ch.swap_armor(slot - 2, item)
		else:
			push_error("Предмет не является экипируемым: ", item.name)
			return
	
	# 3. Сохраняем состояние персонажа
	if key != "":
		PartyData.save_from_character(key, ch)
	
	# 4. Обновляем отображение
	_refresh_stat_panel()
	_refresh_items()  # обновляем список предметов
	_exit_equip_select()

func _exit_equip_select() -> void:
	stat_mode = StatMode.BROWSE
	_equip_scroll.visible = false
	_refresh_stat_panel()

func _switch_tab(tab: Tab) -> void:
	current_tab = tab
	for i in tab_buttons.size():
		var btn := tab_buttons[i]
		var active := (i == int(tab))
		btn.add_theme_color_override("font_color",         YELLOW if active else GRAY)
		btn.add_theme_color_override("font_hover_color",   YELLOW if active else GRAY)
		btn.add_theme_color_override("font_pressed_color", YELLOW if active else GRAY)
		var heart: TextureRect = btn.get_node_or_null("Heart")
		if heart: heart.visible = active

	$Right/ItemScroll.visible = (tab == Tab.ITEM)
	$Right/StatPanel.visible  = (tab == Tab.STAT)
	$InfoLabel.visible  = (tab == Tab.ITEM)
	$Right/Separator2.visible = (tab == Tab.ITEM)
	$Right/BottomBar.visible  = (tab == Tab.ITEM)

	if tab == Tab.ITEM:
		bottom_focused = false
		show_long_desc = false
		stat_cursor = 0
		_refresh_items()
	elif tab == Tab.STAT:
		stat_mode = StatMode.BROWSE
		stat_cursor = 0
		_refresh_stat_panel()

func _refresh_items() -> void:
	for ch in item_list_container.get_children():
		ch.queue_free()
	items_list.clear()
	show_long_desc = false

	for item in Global.items:
		if item != null:
			items_list.append(item)

	if items_list.is_empty():
		var empty := Label.new()
		empty.text = "(пусто)"
		empty.add_theme_font_override("font", FONT)
		empty.add_theme_color_override("font_color", GRAY)
		empty.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_list_container.add_child(empty)
		return

	for i in items_list.size():
		item_list_container.add_child(_make_row(items_list[i].name))
	_update_selection()

func _update_selection() -> void:
	for i in item_list_container.get_children().size():
		var heart: TextureRect = item_list_container.get_children()[i].get_node_or_null("Heart")
		if heart:
			heart.visible = (i == selected_index) and !bottom_focused and !show_long_desc
	_update_bottom_bar()
	_update_info()

func _update_info() -> void:
	if show_long_desc: return
	if current_tab != Tab.ITEM or items_list.is_empty():
		info_label.text = ""
		return
	if selected_index < items_list.size():
		var item = items_list[selected_index]
		info_label.text = item.short_description if item.short_description != "" else ""

func _update_bottom_bar() -> void:
	var labels := ["ИСПЛ", "ИНФО", "БРОС"]
	for i in bottom_actions.size():
		var lbl := bottom_actions[i]
		if bottom_focused and i == bottom_index:
			lbl.add_theme_color_override("font_color", YELLOW)
			lbl.text = "♥" + labels[i]
		else:
			lbl.remove_theme_color_override("font_color")
			lbl.text = labels[i]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed():
		return

	if event.is_action("cancel") or event.is_action("inventory"):
		if char_select_mode:
			_exit_char_select(); Sounds.play("snd_menumove"); return
		if show_long_desc:
			show_long_desc = false; _update_selection(); return
		if bottom_focused:
			bottom_focused = false; _update_selection(); return
		if stat_mode == StatMode.EQUIP_SELECT:
			_exit_equip_select(); return
		if stat_cursor > 0:
			stat_cursor = 0; _refresh_stat_panel(); return
		_close()
		return

	# Навигация выбора персонажа
	if char_select_mode:
		var party_size := Global.party.size()
		if event.is_action("left"):
			char_select_index = wrapi(char_select_index - 1, 0, party_size)
			Sounds.play("snd_menumove"); _update_char_select_cursor(); return
		if event.is_action("right"):
			char_select_index = wrapi(char_select_index + 1, 0, party_size)
			Sounds.play("snd_menumove"); _update_char_select_cursor(); return
		if event.is_action("confirm") or event.is_action("ui_accept"):
			Sounds.play("snd_select")
			var item = items_list[selected_index]
			await _use_item_on(item, char_select_index)
			return
		return

	var can_switch_tab := !bottom_focused and !show_long_desc \
		and stat_mode != StatMode.EQUIP_SELECT \
		and current_tab == Tab.ITEM
	if can_switch_tab:
		if event.is_action("right"):
			_switch_tab(Tab.STAT)
			Sounds.play("snd_menumove"); return

	match current_tab:
		Tab.STAT: _handle_stat_input(event)
		Tab.ITEM: _handle_item_input(event)

func _handle_stat_input(event: InputEvent) -> void:
	if stat_mode == StatMode.EQUIP_SELECT:
		var list_size := equip_items.size() + 1
		if event.is_action("up"):
			equip_cursor = maxi(0, equip_cursor - 1)
			Sounds.play("snd_menumove"); _update_equip_cursor()
		elif event.is_action("down"):
			equip_cursor = mini(list_size - 1, equip_cursor + 1)
			Sounds.play("snd_menumove"); _update_equip_cursor()
		elif event.is_action("confirm") or event.is_action("ui_accept"):
			_do_equip(stat_cursor)
		return

	if stat_cursor == 0:
		if event.is_action("left"):
			if stat_char_index > 0:
				stat_char_index -= 1
				Sounds.play("snd_menumove"); _refresh_stat_panel()
			else:
				_switch_tab(Tab.ITEM)
				Sounds.play("snd_menumove")
		elif event.is_action("right"):
			if stat_char_index < Global.characters.size() - 1:
				stat_char_index += 1
				Sounds.play("snd_menumove"); _refresh_stat_panel()
		elif event.is_action("down"):
			stat_cursor = 1; Sounds.play("snd_menumove"); _refresh_stat_panel()
	else:
		if event.is_action("up"):
			stat_cursor = maxi(0, stat_cursor - 1)
			Sounds.play("snd_menumove"); _refresh_stat_panel()
		elif event.is_action("down"):
			stat_cursor = mini(3, stat_cursor + 1)
			Sounds.play("snd_menumove"); _refresh_stat_panel()
		elif event.is_action("confirm") or event.is_action("ui_accept"):
			_enter_equip_select(stat_cursor)

func _handle_item_input(event: InputEvent) -> void:
	if show_long_desc:
		if event.is_action("confirm") or event.is_action("ui_accept"):
			show_long_desc = false; _update_selection()
		return
	if items_list.is_empty(): return

	if bottom_focused:
		if event.is_action("left"):
			bottom_index = wrapi(bottom_index - 1, 0, 3)
			Sounds.play("snd_menumove"); _update_bottom_bar()
		elif event.is_action("right"):
			bottom_index = wrapi(bottom_index + 1, 0, 3)
			Sounds.play("snd_menumove"); _update_bottom_bar()
		elif event.is_action("confirm") or event.is_action("ui_accept"):
			_do_bottom_action()
	else:
		if event.is_action("up"):
			selected_index = maxi(0, selected_index - 1)
			Sounds.play("snd_menumove"); _update_selection()
		elif event.is_action("down"):
			selected_index = mini(items_list.size() - 1, selected_index + 1)
			Sounds.play("snd_menumove"); _update_selection()
		elif event.is_action("confirm") or event.is_action("ui_accept"):
			bottom_focused = true; bottom_index = 0
			_update_bottom_bar(); _update_selection()

func _do_bottom_action() -> void:
	var item = items_list[selected_index]
	match bottom_index:
		BottomAction.USE:
			if item.usePredicate != null and not Global.characters.is_empty():
				# Если в пати больше одного — выбираем кому применить
				if Global.party.size() > 1:
					_enter_char_select()
				else:
					await _use_item_on(item, 0)
		BottomAction.INFO:
			var long_desc: String = str(item.long_description) if item.get("long_description") else ""
			var short_desc: String = item.short_description if item.short_description != "" else ""
			var text: String = long_desc if long_desc != "" else short_desc
			if text != "":
				info_label.text = text
				show_long_desc = true
				bottom_focused = false
				for i in item_list_container.get_children().size():
					var h: TextureRect = item_list_container.get_children()[i].get_node_or_null("Heart")
					if h: h.visible = false
				_update_bottom_bar()
			else:
				bottom_focused = false; _update_selection()
		BottomAction.DROP:
			var idx := Global.items.find(item)
			if idx != -1: Global.delete_item(idx)
			bottom_focused = false
			selected_index = maxi(0, selected_index - 1)
			_refresh_items()

func _enter_char_select() -> void:
	char_select_mode   = true
	char_select_index  = 0
	bottom_focused     = false
	# Скрываем список предметов и нижний бар
	$Right/ItemScroll.visible  = false
	$InfoLabel.visible   = false
	$Right/Separator2.visible  = false
	$Right/BottomBar.visible   = false
	# Строим панель выбора персонажа
	_build_char_select_panel()


func _build_char_select_panel() -> void:
	if _char_select_panel != null:
		_char_select_panel.queue_free()
	_char_select_panel = VBoxContainer.new()
	_char_select_panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_char_select_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_char_select_panel.add_theme_constant_override("separation", 6)
	$Right.add_child(_char_select_panel)
	_char_select_rows.clear()

	# Отступ сверху
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	_char_select_panel.add_child(spacer)
	# Заголовок
	var title := Label.new()
	title.text = "КОМУ ПРИМЕНИТЬ?"
	title.add_theme_font_override("font", FONT)
	title.add_theme_color_override("font_color", WHITE)
	title.add_theme_font_size_override("font_size", 19)
	title.custom_minimum_size = Vector2(0, 26)
	_char_select_panel.add_child(title)
	_char_select_panel.add_child(HSeparator.new())

	for i in Global.party.size():
		if i >= Global.characters.size():
			break
		var ch := Global.characters[i]
		var key := Global.party[i]
		var full_hp := is_instance_valid(ch) and ch.current_hp >= ch.get_max_hp()
		var row := _make_char_select_row(key, ch, full_hp)
		_char_select_panel.add_child(row)
		_char_select_rows.append(row)

	_update_char_select_cursor()


func _make_char_select_row(key: String, ch: Character, full_hp: bool) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(0, 38)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Курсор-сердце
	var heart := TextureRect.new()
	heart.name = "Heart"
	heart.texture = HEART_TEX
	heart.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	heart.custom_minimum_size = Vector2(32, 32)
	heart.size     = Vector2(32, 32)
	heart.visible  = false
	heart.position = Vector2(0, 3)
	row.add_child(heart)

	# Имя
	var name_lbl := Label.new()
	name_lbl.name = "Name"
	name_lbl.add_theme_font_override("font", FONT)
	var char_color := _get_char_color(key) if not full_hp else GRAY
	name_lbl.add_theme_color_override("font_color", char_color)
	name_lbl.text     = _get_party_name(key)
	name_lbl.position = Vector2(34, 0)
	name_lbl.size     = Vector2(90, 38)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_lbl)

	# HP текст
	var hp_lbl := Label.new()
	hp_lbl.name = "HP"
	hp_lbl.add_theme_font_override("font", FONT)
	hp_lbl.add_theme_color_override("font_color", YELLOW if full_hp else WHITE)
	if is_instance_valid(ch):
		hp_lbl.text = "ХП %d/%d" % [ch.current_hp, ch.get_max_hp()] if not full_hp else "МАКС"
	hp_lbl.position = Vector2(130, 0)
	hp_lbl.size     = Vector2(120, 38)
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(hp_lbl)

	# HP полоска
	if is_instance_valid(ch):
		var bar_bg := ColorRect.new()
		bar_bg.color    = Color(0.3, 0.0, 0.0)
		bar_bg.position = Vector2(258, 14)
		bar_bg.size     = Vector2(180, 10)
		row.add_child(bar_bg)
		var bar := ColorRect.new()
		bar.name    = "Bar"
		var ratio := clampf(float(ch.current_hp) / float(ch.get_max_hp()), 0.0, 1.0)
		bar.color    = _get_char_color(key) if not full_hp else GRAY
		bar.position = Vector2(258, 14)
		bar.size     = Vector2(180.0 * ratio, 10)
		row.add_child(bar)

	return row


func _update_char_select_cursor() -> void:
	for i in _char_select_rows.size():
		var heart := _char_select_rows[i].get_node_or_null("Heart") as TextureRect
		if heart:
			heart.visible  = (i == char_select_index)
			heart.modulate = Global.heartColor


func _exit_char_select() -> void:
	char_select_mode = false
	if _char_select_panel != null:
		_char_select_panel.queue_free()
		_char_select_panel = null
	_char_select_rows.clear()
	$Right/ItemScroll.visible  = (current_tab == Tab.ITEM)
	$Right/InfoLabel.visible   = (current_tab == Tab.ITEM)
	$Right/Separator2.visible  = (current_tab == Tab.ITEM)
	$Right/BottomBar.visible   = (current_tab == Tab.ITEM)
	_update_info()


func _use_item_on(item: Item, char_idx: int) -> void:
	var ch_idx := clampi(char_idx, 0, Global.characters.size() - 1)
	if not is_instance_valid(Global.characters[ch_idx]):
		Global.load_party_characters(false)
		ch_idx = 0
	var ch : Character = Global.characters[ch_idx]

	# Блокируем если HP полное и предмет лечебный
	if item.usePredicate is HealUsePredicate and ch.current_hp >= ch.get_max_hp():
		Sounds.play("snd_menumove")
		return

	# Применяем эффект напрямую без create_text (персонаж вне дерева)
	if item.usePredicate is HealUsePredicate:
		var pred := item.usePredicate as HealUsePredicate
		var new_hp := mini(ch.current_hp + pred.amount, ch.get_max_hp())
		ch.current_hp = new_hp
		PartyData.save_from_character(Global.party[ch_idx] if ch_idx < Global.party.size() else "", ch)
		Sounds.play("snd_power")
	else:
		await item.usePredicate.use_item(ch, ch)

	if item.usePredicate.remove_after_use:
		var idx := Global.items.find(item)
		if idx != -1: Global.delete_item(idx)
	_exit_char_select()
	_refresh_char_info()
	bottom_focused = false
	selected_index = mini(selected_index, maxi(0, items_list.size() - 2))
	_refresh_items()


func _close() -> void:
	Sounds.play("snd_select")
	get_parent().queue_free()
