extends Control

const FONT      := preload("res://fonts/8bitoperator Cyrillic Extension.otf")
const HEART_TEX := preload("res://globals/global/res/heart.png")

const YELLOW := Color("#ffff00")
const GRAY   := Color(0.45, 0.45, 0.45)
const WHITE  := Color.WHITE
const DIM    := Color(0.28, 0.28, 0.28)

# ─── Геометрия (рассчитана под 640×342) ─────────────────────────
const ROW_H    := 25
const COLS     := 2
const P_ROWS   := 4
const S_ROWS   := 6
const LABEL_W  := 88
const COL_W    := 262
const HEART_SZ := 24

const P_SLOTS   := COLS * P_ROWS   # 8
const S_PAGE_SZ := COLS * S_ROWS   # 12
const STOR_MAX  := 24

signal closed

enum Section { POCKET, STORAGE }

var _sec    : Section = Section.POCKET
var _p_cur  : int = 0
var _s_cur  : int = 0
var _s_page : int = 0

var _held     : Item    = null
var _held_sec : Section
var _held_abs : int

var _desc_lbl : Label
var _held_lbl : Label
var _page_lbl : Label
var _p_cells  : Array[Dictionary] = []
var _s_cells  : Array[Dictionary] = []

var _ready_for_input := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Vector2(640, 342)
	_ensure_storage()
	_build_ui()
	_refresh_all()
	await get_tree().process_frame
	_ready_for_input = true


func _ensure_storage() -> void:
	while Global.storage.size() < STOR_MAX:
		Global.storage.append(null)


# ══════════════════════════════  BUILD UI

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color        = Color(0, 0, 0, 0.88)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Описание предмета — узкая строка над панелью
	_desc_lbl = _make_lbl("", 18)
	_desc_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_desc_lbl.offset_left   = 12
	_desc_lbl.offset_top    = 9
	_desc_lbl.offset_right  = -12
	_desc_lbl.offset_bottom = -307
	add_child(_desc_lbl)

	# Главная панель 624×294 начиная с y=30
	var main := Panel.new()
	var sty  := StyleBoxFlat.new()
	sty.bg_color             = Color(0, 0, 0, 1)
	sty.border_color         = Color(1, 1, 1, 1)
	sty.border_width_left    = 2; sty.border_width_top    = 2
	sty.border_width_right   = 2; sty.border_width_bottom = 2
	sty.content_margin_left  = 6; sty.content_margin_top  = 6
	sty.content_margin_right = 6; sty.content_margin_bottom = 6
	main.add_theme_stylebox_override("panel", sty)
	main.position = Vector2(8, 30)
	main.size     = Vector2(624, 294)
	add_child(main)

	# ── КАРМАН ──────────────────────────────────────────────────
	var pkt_lbl := _make_lbl("КАРМАН", 17, GRAY)
	pkt_lbl.position           = Vector2(6, 6)
	pkt_lbl.size               = Vector2(LABEL_W - 4, P_ROWS * ROW_H)
	pkt_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main.add_child(pkt_lbl)

	_p_cells.clear()
	for i in P_SLOTS:
		_p_cells.append(_build_cell(main,
			LABEL_W + (i % COLS) * COL_W,
			6 + (i / COLS) * ROW_H
		))

	# Разделитель
	var sep := HSeparator.new()
	sep.position = Vector2(0, 110)
	sep.size     = Vector2(624, 2)
	main.add_child(sep)

	# ── СКЛАД ───────────────────────────────────────────────────
	var stor_lbl := _make_lbl("СКЛАД", 17, GRAY)
	stor_lbl.position           = Vector2(6, 116)
	stor_lbl.size               = Vector2(LABEL_W - 4, S_ROWS * ROW_H)
	stor_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main.add_child(stor_lbl)

	_s_cells.clear()
	for i in S_PAGE_SZ:
		_s_cells.append(_build_cell(main,
			LABEL_W + (i % COLS) * COL_W,
			116 + (i / COLS) * ROW_H
		))

	# ── Нижняя строка (y=270 внутри панели) ─────────────────────
	_page_lbl = _make_lbl("", 16, GRAY)
	_page_lbl.position = Vector2(6, 270)
	_page_lbl.size     = Vector2(100, 22)
	main.add_child(_page_lbl)

	_held_lbl = _make_lbl("", 16, YELLOW)
	_held_lbl.position = Vector2(10, 330)
	_held_lbl.size     = Vector2(360, 22)
	main.add_child(_held_lbl)

	var hint := _make_lbl(_build_hint_text(), 15, DIM)
	hint.position             = Vector2(-86, 272)
	hint.size                 = Vector2(606, 22)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	main.add_child(hint)


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


func _build_hint_text() -> String:
	return "%s — взять/положить   %s — отмена/закрыть" % [
		_get_key_label("confirm"),
		_get_key_label("cancel")
	]


func _build_cell(parent: Control, x: float, y: float) -> Dictionary:
	var heart := TextureRect.new()
	heart.texture      = HEART_TEX
	heart.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	heart.custom_minimum_size = Vector2(HEART_SZ, ROW_H)
	heart.size     = Vector2(HEART_SZ, ROW_H)
	heart.visible  = false
	heart.position = Vector2(x, y)
	parent.add_child(heart)

	var lbl := _make_lbl("——", 18, DIM)
	lbl.position = Vector2(x + HEART_SZ + 2, y)
	lbl.size     = Vector2(COL_W - HEART_SZ - 6, ROW_H)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	parent.add_child(lbl)

	return {"heart": heart, "lbl": lbl}


func _make_lbl(text: String, font_size: int = 16, color: Color = WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


# ══════════════════════════════  REFRESH

func _refresh_all() -> void:
	_refresh_pocket()
	_refresh_storage()
	_refresh_cursor()
	_refresh_desc()
	_refresh_page_lbl()
	_refresh_held_lbl()

func _refresh_pocket() -> void:
	for i in P_SLOTS:
		_set_cell(_p_cells[i], _pocket_item(i))

func _refresh_storage() -> void:
	for i in S_PAGE_SZ:
		_set_cell(_s_cells[i], _storage_item(_s_page * S_PAGE_SZ + i))

func _set_cell(cell: Dictionary, item: Item) -> void:
	var lbl: Label = cell["lbl"]
	if item == null:
		lbl.text = "——"
		lbl.add_theme_color_override("font_color", DIM)
	else:
		lbl.text = item.name
		lbl.add_theme_color_override("font_color", WHITE)

func _refresh_cursor() -> void:
	for i in P_SLOTS:
		var h: TextureRect = _p_cells[i]["heart"]
		h.visible  = (_sec == Section.POCKET and _p_cur == i)
		h.modulate = Global.heartColor
	for i in S_PAGE_SZ:
		var h: TextureRect = _s_cells[i]["heart"]
		h.visible  = (_sec == Section.STORAGE and _s_cur == i)
		h.modulate = Global.heartColor

func _refresh_desc() -> void:
	if _held != null:
		var d := _held.short_description if _held.short_description != "" else ""
		_desc_lbl.text = _held.name + (": " + d if d != "" else "")
	else:
		var item := _cursor_item()
		_desc_lbl.text = item.short_description if item != null and item.short_description != "" else ""

func _refresh_page_lbl() -> void:
	var pages := ceili(float(STOR_MAX) / float(S_PAGE_SZ))
	_page_lbl.text = "Стр. %d/%d" % [_s_page + 1, pages]

func _refresh_held_lbl() -> void:
	_held_lbl.text = ("В руках: " + _held.name) if _held != null else ""


# ══════════════════════════════  ITEM ACCESS

func _pocket_item(idx: int) -> Item:
	if _held != null and _held_sec == Section.POCKET and _held_abs == idx:
		return null
	return Global.items[idx] if idx < Global.items.size() else null

func _storage_item(abs_idx: int) -> Item:
	if _held != null and _held_sec == Section.STORAGE and _held_abs == abs_idx:
		return null
	if abs_idx >= Global.storage.size():
		return null
	return Global.storage[abs_idx]

func _cursor_item() -> Item:
	if _sec == Section.POCKET:
		return _pocket_item(_p_cur)
	else:
		return _storage_item(_s_page * S_PAGE_SZ + _s_cur)


# ══════════════════════════════  INPUT

func _unhandled_key_input(event: InputEvent) -> void:
	if not _ready_for_input:
		return
	if not (event is InputEventKey and event.is_pressed()):
		return

	if event.is_action("cancel"):
		get_viewport().set_input_as_handled()
		if _held != null:
			_cancel_hold()
		else:
			_close()
		return

	if event.is_action("confirm"):
		get_viewport().set_input_as_handled()
		_do_confirm()
		return

	if _handle_move(event):
		get_viewport().set_input_as_handled()
		Sounds.play("snd_menumove")
		_refresh_all()


func _handle_move(event: InputEvent) -> bool:
	if _sec == Section.POCKET:
		if event.is_action("right") and _p_cur % COLS < COLS - 1:
			_p_cur += 1; return true
		if event.is_action("left") and _p_cur % COLS > 0:
			_p_cur -= 1; return true
		if event.is_action("up") and _p_cur >= COLS:
			_p_cur -= COLS; return true
		if event.is_action("down"):
			if _p_cur + COLS < P_SLOTS:
				_p_cur += COLS; return true
			else:
				_sec   = Section.STORAGE
				_s_cur = _p_cur % COLS
				return true
	else:
		if event.is_action("right") and _s_cur % COLS < COLS - 1:
			_s_cur += 1; return true
		if event.is_action("left") and _s_cur % COLS > 0:
			_s_cur -= 1; return true
		if event.is_action("down"):
			if _s_cur + COLS < S_PAGE_SZ:
				_s_cur += COLS; return true
			else:
				var max_pages := ceili(float(STOR_MAX) / float(S_PAGE_SZ))
				if _s_page + 1 < max_pages:
					_s_page += 1
					_s_cur   = _s_cur % COLS
					return true
		if event.is_action("up"):
			if _s_cur >= COLS:
				_s_cur -= COLS; return true
			elif _s_page > 0:
				_s_page -= 1
				_s_cur   = (S_PAGE_SZ - COLS) + (_s_cur % COLS)
				return true
			else:
				_sec   = Section.POCKET
				_p_cur = (P_ROWS - 1) * COLS + (_s_cur % COLS)
				return true
	return false


# ══════════════════════════════  ACTIONS

func _do_confirm() -> void:
	if _held == null:
		_pick_up()
	else:
		_place_down()

func _pick_up() -> void:
	var item := _cursor_item()
	if item == null:
		return
	if item.inventory_tab == Item.InventoryTab.KEY_ITEMS:
		Sounds.play("snd_select")
		return
	_held_sec = _sec
	_held_abs = _p_cur if _sec == Section.POCKET else _s_page * S_PAGE_SZ + _s_cur
	_held     = item
	Sounds.play("snd_select")
	_refresh_all()

func _place_down() -> void:
	var tgt_abs : int = _p_cur if _sec == Section.POCKET \
		else _s_page * S_PAGE_SZ + _s_cur

	if _sec == _held_sec and tgt_abs == _held_abs:
		_cancel_hold()
		return

	var swap_item: Item
	if _sec == Section.POCKET:
		swap_item = Global.items[tgt_abs] if tgt_abs < Global.items.size() else null
	else:
		swap_item = Global.storage[tgt_abs]

	if _sec == Section.POCKET:
		_write_pocket(tgt_abs, _held)
	else:
		Global.storage[tgt_abs] = _held

	if _held_sec == Section.POCKET:
		_write_pocket(_held_abs, swap_item)
	else:
		Global.storage[_held_abs] = swap_item

	_held = null
	Sounds.play("snd_select")
	_refresh_all()

func _write_pocket(idx: int, item: Item) -> void:
	while Global.items.size() <= idx:
		Global.items.append(null)
	Global.items[idx] = item

func _cancel_hold() -> void:
	_held = null
	Sounds.play("snd_select")
	_refresh_all()

func _close() -> void:
	set_process_unhandled_key_input(false)
	Sounds.play("snd_select")
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = true
	closed.emit()
	queue_free()
