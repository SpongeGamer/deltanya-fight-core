extends Control

## Магазин в стиле Deltarune. Viewport 640×480.
## Вёрстка — в shop_menu.tscn, не трогать.
##
## Состояния:
##   MAIN  → LEFT: GreetingLabel   / RIGHT: Btn0-3 + Gold
##   BUY   → LEFT: Row0-4 (товары) / RIGHT: CommentLabel + DescPanel + Gold
##   SELL  → LEFT: Row0-4 (товары) / RIGHT: CommentLabel + DescPanel + Gold
##   TALK  → LEFT: Row0-4 (темы)   / RIGHT: CommentLabel + Gold

enum State { MAIN, BUY, SELL, TALK }
var state : State = State.MAIN
var shop  : ShopResource = null

const MAIN_LABELS := ["Купить", "Продать", "Поговорить", "Выход"]
var main_cursor := 0

var buy_list    : Array = []
var buy_cursor  := 0

# SELL — постраничная навигация как в складе
const SELL_PAGE_SIZE := 5        # столько строк в tscn (Row0-4)
var sell_list   : Array = []
var sell_page   := 0             # текущая страница
var sell_cursor := 0             # курсор внутри страницы (0..PAGE_SIZE-1)

var talk_list   : Array = []
var talk_page   := 0
var talk_cursor := 0  # курсор внутри страницы

# ── @onready ─────────────────────────────────────────────────────────────────
@onready var _greeting_lbl : RichTextLabel = $LeftPanel/GreetingLabel
@onready var _comment_lbl  : Label         = $RightPanel/CommentLabel
@onready var _gold_lbl     : Label         = $RightPanel/GoldLabel
@onready var _space_lbl    : Label         = $RightPanel/SpaceLabel
@onready var _desc_panel   : Panel         = $DescPanel
@onready var _desc_lbl     : Label         = $DescPanel/DescLabel

var _item_rows : Array[Dictionary] = []
var _btn_rows  : Array[Dictionary] = []

var _canvas_layer  : CanvasLayer     = null
var _player_node   : CharacterBody2D = null
var _ready_for_input := false

# ── Типизатор текста ──────────────────────────────────────────────────────────
# Запускается как фоновая корутина — НЕ блокирует ввод, НЕ скипается на Z.
var _typing_id     := 0          # инкрементируем при каждом новом комментарии
var _audio_player  : AudioStreamPlayer = null

# ─── _ready ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 128
	_canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_canvas_layer)
	var old_parent := get_parent()
	if old_parent:
		old_parent.remove_child(self)
	_canvas_layer.add_child(self)
	set_anchors_preset(Control.PRESET_FULL_RECT)

	for n in get_tree().get_nodes_in_group("player"):
		_player_node = n

	# AudioStreamPlayer для голоса продавца
	_audio_player = AudioStreamPlayer.new()
	_audio_player.max_polyphony = 4
	add_child(_audio_player)

	_setup_arrays()
	_enter_main()
	await get_tree().process_frame
	_ready_for_input = true

func _setup_arrays() -> void:
	_item_rows.clear()
	for i in SELL_PAGE_SIZE:
		var row := $LeftPanel.get_node("Row%d" % i)
		_item_rows.append({
			"heart": row.get_node("Heart") as TextureRect,
			"title": row.get_node("Title") as Label,
			"price": row.get_node("Price") as Label,
		})
	_btn_rows.clear()
	for i in 4:
		var row := $RightPanel.get_node("Btn%d" % i)
		_btn_rows.append({
			"heart": row.get_node("Heart") as TextureRect,
			"label": row.get_node("Label") as Label,
		})

# ─── _process ─────────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if _player_node != null and is_instance_valid(_player_node):
		_player_node.can_move = false

# ─── API ──────────────────────────────────────────────────────────────────────
func open_shop(p_shop: ShopResource) -> void:
	shop = p_shop

# ─── Типизатор (фоновая корутина) ─────────────────────────────────────────────
# target_lbl — RichTextLabel или Label.
# dt         — DialogueText с text / text_sound / text_speed / pitch.
# НЕ блокирует ввод. НЕ скипается. Отменяется при следующем вызове _type_comment.
func _type_comment(target: Control, dt: DialogueText) -> void:
	_typing_id += 1
	var my_id := _typing_id
	_set_control_text(target, "")

	if dt == null:
		return

	var full_text : String  = dt.text               if dt.get("text")               != null else ""
	var speed     : float   = dt.text_speed         if dt.get("text_speed")         != null else 8.0
	var sound     : AudioStream = dt.text_sound     if dt.get("text_sound")         != null else null
	var vol_db    : float   = float(dt.text_volume_db) if dt.get("text_volume_db")  != null else -10.0
	var pitch_min : float   = dt.text_volume_pitch_min if dt.get("text_volume_pitch_min") != null else 0.85
	var pitch_max : float   = dt.text_volume_pitch_max if dt.get("text_volume_pitch_max") != null else 1.15

	const VOICE_DB_OFFSET := -10.0
	const VOICE_MIN_DB    := -24.0
	const VOICE_MAX_DB    :=  -2.0

	if sound:
		_audio_player.stream    = sound
		_audio_player.volume_db = clampf(vol_db + VOICE_DB_OFFSET, VOICE_MIN_DB, VOICE_MAX_DB)

	var char_timer := 0.0
	var idx        := 0
	# Удаляем BBCode-теги из полного текста для подсчёта символов
	# (в RichTextLabel text содержит BBCode, но visible_characters считает без тегов)
	var plain := _strip_bbcode(full_text)

	while idx < plain.length():
		if _typing_id != my_id or not is_inside_tree():
			return

		char_timer += get_process_delta_time()
		if char_timer >= 1.0 / speed or plain[idx] == " ":
			var c := plain[idx]
			idx += 1
			# Для RichTextLabel используем visible_characters
			if target is RichTextLabel:
				(target as RichTextLabel).text = full_text
				(target as RichTextLabel).visible_characters = idx
			else:
				_set_control_text(target, plain.left(idx))

			if c != " " and sound:
				_audio_player.pitch_scale = randf_range(pitch_min, pitch_max)
				_audio_player.play()
			char_timer = 0.0

		await get_tree().process_frame

	# Показываем весь текст по завершении
	if _typing_id == my_id:
		if target is RichTextLabel:
			(target as RichTextLabel).visible_characters = -1
		else:
			_set_control_text(target, plain)

func _set_control_text(c: Control, text: String) -> void:
	if c is RichTextLabel:
		(c as RichTextLabel).text = text
		(c as RichTextLabel).visible_characters = -1
	elif c is Label:
		(c as Label).text = text

func _strip_bbcode(s: String) -> String:
	var result := ""
	var inside := false
	for ch in s:
		if ch == "[": inside = true
		elif ch == "]": inside = false
		elif not inside: result += ch
	return result

func _random_dt(arr: Array) -> DialogueText:
	if arr.is_empty(): return null
	return arr[randi() % arr.size()] as DialogueText

# ─── Переключение видимости ───────────────────────────────────────────────────
func _show_main() -> void:
	_greeting_lbl.visible = true
	_comment_lbl.visible  = false
	_desc_panel.visible   = false
	for row in _item_rows:
		(row["heart"] as TextureRect).visible = false
		(row["title"] as Label).visible       = false
		(row["price"] as Label).visible       = false
	for row in _btn_rows:
		(row["heart"] as TextureRect).visible = false
		(row["label"] as Label).visible       = true

func _show_sub(show_desc: bool) -> void:
	_greeting_lbl.visible = false
	_comment_lbl.visible  = true
	_desc_panel.visible   = show_desc
	for row in _btn_rows:
		(row["heart"] as TextureRect).visible = false
		(row["label"] as Label).visible       = false

# ─── Заполнение строк ─────────────────────────────────────────────────────────
func _fill_rows(
		p_labels : Array,
		p_prices : Array = [],
		p_cursor : int   = -1,
		p_colors : Array = []) -> void:
	for i in _item_rows.size():
		var heart : TextureRect = _item_rows[i]["heart"]
		var title : Label       = _item_rows[i]["title"]
		var price : Label       = _item_rows[i]["price"]
		if i < p_labels.size():
			title.text    = str(p_labels[i])
			title.visible = true
			title.add_theme_color_override("font_color",
				p_colors[i] if i < p_colors.size() else Color.WHITE)
			price.text    = str(p_prices[i]) if i < p_prices.size() else ""
			price.visible = price.text != ""
			heart.visible  = (i == p_cursor)
			heart.modulate = Global.heartColor
		else:
			title.visible = false
			price.visible = false
			heart.visible = false

func _refresh_gold() -> void:
	_gold_lbl.text = "Г  %d" % Global.gold
	var used := 0
	for it in Global.items:
		if it != null: used += 1
	_space_lbl.text = "Место: %d" % (Global.MAX_ITEMS - used)

func _refresh_gold_with_page(page: int, total_pages: int) -> void:
	_gold_lbl.text = "Г  %d" % Global.gold
	var used := 0
	for it in Global.items:
		if it != null: used += 1
	var free := Global.MAX_ITEMS - used
	if total_pages > 1:
		_space_lbl.text = "Место: %d  [%d/%d]" % [free, page + 1, total_pages]
	else:
		_space_lbl.text = "Место: %d" % free

# ─── ГЛАВНОЕ МЕНЮ ─────────────────────────────────────────────────────────────
func _enter_main() -> void:
	state = State.MAIN; main_cursor = 0
	_show_main(); _rebuild_main_cursor()
	_refresh_gold()
	# Запускаем случайное приветствие в фоне
	var greetings : Array = shop.greetings if shop != null and shop.get("greetings") != null else []
	_type_comment(_greeting_lbl, _random_dt(greetings))

func _rebuild_main_cursor() -> void:
	for i in _btn_rows.size():
		var h : TextureRect = _btn_rows[i]["heart"]
		h.visible = (i == main_cursor); h.modulate = Global.heartColor

func _handle_main(event: InputEvent) -> void:
	if event.is_action("up"):
		main_cursor = maxi(0, main_cursor - 1)
		Sounds.play("snd_menumove"); _rebuild_main_cursor()
	elif event.is_action("down"):
		main_cursor = mini(MAIN_LABELS.size() - 1, main_cursor + 1)
		Sounds.play("snd_menumove"); _rebuild_main_cursor()
	elif event.is_action("confirm") or event.is_action("ui_accept"):
		Sounds.play("snd_select")
		match main_cursor:
			0: _enter_buy()
			1: _enter_sell()
			2: _enter_talk()
			3: _close()
	elif event.is_action("cancel"):
		_close()

# ─── КУПИТЬ ───────────────────────────────────────────────────────────────────
func _enter_buy() -> void:
	if shop == null or shop.stock.is_empty(): return
	state = State.BUY; buy_cursor = 0
	buy_list = shop.stock.duplicate()
	_show_sub(true)
	var comments : Array = shop.buy_comments if shop.get("buy_comments") != null else []
	_type_comment(_comment_lbl, _random_dt(comments))
	_rebuild_buy()

func _rebuild_buy() -> void:
	var labels : Array = []; var prices : Array = []; var colors : Array = []
	for item : Item in buy_list:
		var p : int = item.get("price") if item.get("price") != null else 0
		labels.append(item.name)
		prices.append("Г %d" % p)
		colors.append(Color.WHITE if Global.gold >= p else Color(0.45, 0.45, 0.45))
	_fill_rows(labels, prices, buy_cursor, colors)
	if not buy_list.is_empty() and buy_cursor < buy_list.size():
		_desc_lbl.text = buy_list[buy_cursor].get("short_description") \
			if buy_list[buy_cursor].get("short_description") != null else ""
	_refresh_gold()

func _handle_buy(event: InputEvent) -> void:
	if event.is_action("up"):
		buy_cursor = maxi(0, buy_cursor - 1); Sounds.play("snd_menumove"); _rebuild_buy()
	elif event.is_action("down"):
		buy_cursor = mini(buy_list.size() - 1, buy_cursor + 1); Sounds.play("snd_menumove"); _rebuild_buy()
	elif event.is_action("confirm") or event.is_action("ui_accept"): _confirm_buy()
	elif event.is_action("cancel"): Sounds.play("snd_menumove"); _enter_main()

func _confirm_buy() -> void:
	var item  : Item = buy_list[buy_cursor]
	var price : int  = item.get("price") if item.get("price") != null else 0
	if Global.gold < price:
		_desc_lbl.text = "Недостаточно\nзолота!"; Sounds.play("snd_menumove"); return
	if not Global.add_item(item):
		_desc_lbl.text = "Инвентарь\nполон!"; Sounds.play("snd_menumove"); return
	Global.gold -= price; Sounds.play("snd_power")
	_desc_lbl.text = "Куплено:\n%s" % item.name; _rebuild_buy()

# ─── ПРОДАТЬ (с постраничной навигацией) ─────────────────────────────────────
func _enter_sell() -> void:
	sell_list.clear()
	for item in Global.items:
		if item != null and not item.get("is_key_item"):
			sell_list.append(item)
	if sell_list.is_empty(): return
	state = State.SELL; sell_page = 0; sell_cursor = 0
	_show_sub(true)
	var comments : Array = shop.sell_comments if shop != null and shop.get("sell_comments") != null else []
	_type_comment(_comment_lbl, _random_dt(comments))
	_rebuild_sell()

func _sell_total_pages() -> int:
	return ceili(float(sell_list.size()) / float(SELL_PAGE_SIZE))

func _sell_global_cursor() -> int:
	return sell_page * SELL_PAGE_SIZE + sell_cursor

func _rebuild_sell() -> void:
	var base  := sell_page * SELL_PAGE_SIZE
	var labels : Array = []; var prices : Array = []
	for i in SELL_PAGE_SIZE:
		var idx := base + i
		if idx >= sell_list.size(): break
		var item : Item = sell_list[idx]
		var sp : int = item.get("sell_price") if item.get("sell_price") != null else 0
		labels.append(item.name)
		prices.append("Г %d" % sp)
	_fill_rows(labels, prices, sell_cursor)
	var global_cur := _sell_global_cursor()
	if global_cur < sell_list.size():
		var item : Item = sell_list[global_cur]
		_desc_lbl.text = item.get("short_description") \
			if item.get("short_description") != null else ""
	_refresh_gold_with_page(sell_page, _sell_total_pages())

func _handle_sell(event: InputEvent) -> void:
	var page_items := mini(SELL_PAGE_SIZE, sell_list.size() - sell_page * SELL_PAGE_SIZE)

	if event.is_action("up"):
		if sell_cursor > 0:
			sell_cursor -= 1
		elif sell_page > 0:
			sell_page  -= 1
			# Перейти на последний элемент предыдущей страницы
			var prev_page_items := mini(SELL_PAGE_SIZE, sell_list.size() - sell_page * SELL_PAGE_SIZE)
			sell_cursor = prev_page_items - 1
		Sounds.play("snd_menumove"); _rebuild_sell()

	elif event.is_action("down"):
		if sell_cursor < page_items - 1:
			sell_cursor += 1
		elif sell_page < _sell_total_pages() - 1:
			sell_page  += 1
			sell_cursor = 0
		Sounds.play("snd_menumove"); _rebuild_sell()

	elif event.is_action("confirm") or event.is_action("ui_accept"):
		_confirm_sell()
	elif event.is_action("cancel"):
		Sounds.play("snd_menumove"); _enter_main()

func _confirm_sell() -> void:
	var global_cur := _sell_global_cursor()
	if global_cur >= sell_list.size(): return
	var item : Item = sell_list[global_cur]
	var sp   : int  = item.get("sell_price") if item.get("sell_price") != null else 0
	var idx  := Global.items.find(item)
	if idx != -1: Global.delete_item(idx)
	Global.gold += sp; Sounds.play("snd_power")
	# Сохраняем позицию: после удаления не выходим за пределы
	_enter_sell()   # пересобирает sell_list
	if sell_list.is_empty():
		_enter_main(); return
	# Восстанавливаем позицию
	var total_pages := _sell_total_pages()
	sell_page   = mini(sell_page, total_pages - 1)
	var page_items := mini(SELL_PAGE_SIZE, sell_list.size() - sell_page * SELL_PAGE_SIZE)
	sell_cursor = mini(sell_cursor, page_items - 1)
	_rebuild_sell()

# ─── ПОГОВОРИТЬ ───────────────────────────────────────────────────────────────
func _enter_talk() -> void:
	if shop == null: return
	talk_list.clear()
	var topics : Array = shop.talk_topics if shop.get("talk_topics") != null else []
	for t in topics: talk_list.append(t)
	state = State.TALK; talk_page = 0; talk_cursor = 0
	_show_sub(false)
	var comments : Array = shop.talk_comments if shop.get("talk_comments") != null else []
	var dt := _random_dt(comments)
	if dt == null:
		var greetings : Array = shop.greetings if shop.get("greetings") != null else []
		dt = _random_dt(greetings)
	_type_comment(_comment_lbl, dt)
	_rebuild_talk()

func _talk_total_pages() -> int:
	# "Назад" считается отдельным элементом после всех тем
	return ceili(float(talk_list.size() + 1) / float(SELL_PAGE_SIZE))

func _talk_global_cursor() -> int:
	return talk_page * SELL_PAGE_SIZE + talk_cursor

func _rebuild_talk() -> void:
	var base   := talk_page * SELL_PAGE_SIZE
	var labels : Array = []; var colors : Array = []
	for i in SELL_PAGE_SIZE:
		var global_i := base + i
		if global_i < talk_list.size():
			var t = talk_list[global_i]
			labels.append((t as ShopTalkTopic).label if t is ShopTalkTopic else str(t))
			colors.append(Color.WHITE)
		elif global_i == talk_list.size():
			# "Назад" — первый элемент после всех тем
			labels.append("Назад")
			colors.append(Color(0.45, 0.45, 0.45))
		else:
			break
	_fill_rows(labels, [], talk_cursor, colors)
	_refresh_gold_with_page(talk_page, _talk_total_pages())

func _handle_talk(event: InputEvent) -> void:
	# Сколько элементов на текущей странице (темы + возможно "Назад")
	var base       := talk_page * SELL_PAGE_SIZE
	var page_items := 0
	for i in SELL_PAGE_SIZE:
		if base + i <= talk_list.size():  # <= потому что "Назад" = индекс talk_list.size()
			page_items += 1
		else:
			break

	if event.is_action("up"):
		if talk_cursor > 0:
			talk_cursor -= 1
		elif talk_page > 0:
			talk_page  -= 1
			var prev_items := 0
			var prev_base  := talk_page * SELL_PAGE_SIZE
			for i in SELL_PAGE_SIZE:
				if prev_base + i <= talk_list.size(): prev_items += 1
				else: break
			talk_cursor = prev_items - 1
		Sounds.play("snd_menumove"); _rebuild_talk()

	elif event.is_action("down"):
		if talk_cursor < page_items - 1:
			talk_cursor += 1
		elif talk_page < _talk_total_pages() - 1:
			talk_page  += 1
			talk_cursor = 0
		Sounds.play("snd_menumove"); _rebuild_talk()

	elif event.is_action("confirm") or event.is_action("ui_accept"):
		var global_cur := _talk_global_cursor()
		if global_cur == talk_list.size():
			Sounds.play("snd_select"); _enter_main()
		else:
			Sounds.play("snd_select"); _open_talk_topic(global_cur)
	elif event.is_action("cancel"):
		Sounds.play("snd_menumove"); _enter_main()

func _open_talk_topic(index: int) -> void:
	var topic = talk_list[index]
	if not (topic is ShopTalkTopic): return
	var dlg_arr : Array = topic.dialogue if topic.get("dialogue") != null else []
	if dlg_arr.is_empty(): return
	var DialogueScene : PackedScene = load("res://scenes/prefabs/dialogue_system.tscn")
	if DialogueScene == null: push_error("ShopMenu: не найден dialogue_system.tscn"); return
	_ready_for_input = false
	var cl := CanvasLayer.new()
	cl.layer = 200; cl.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(cl)
	var dlg = DialogueScene.instantiate()
	dlg.dialogue = dlg_arr.duplicate(); dlg.caller = self
	cl.add_child(dlg)
	await cl.tree_exited
	# После диалога — новый случайный комментарий
	var comments : Array = shop.talk_comments if shop.get("talk_comments") != null else []
	var dt := _random_dt(comments)
	if dt == null:
		var greetings : Array = shop.greetings if shop.get("greetings") != null else []
		dt = _random_dt(greetings)
	_type_comment(_comment_lbl, dt)
	_ready_for_input = true

# ─── ЗАКРЫТИЕ ─────────────────────────────────────────────────────────────────
func _close() -> void:
	_ready_for_input = false
	_typing_id += 1   # отменяем любую активную корутину типизатора
	Sounds.play("snd_select")
	if _player_node: _player_node.can_move = true
	if is_instance_valid(_canvas_layer): _canvas_layer.queue_free()
	else: queue_free()

# ─── ВВОД ─────────────────────────────────────────────────────────────────────
func _unhandled_key_input(event: InputEvent) -> void:
	if not _ready_for_input: return
	if not (event is InputEventKey and event.is_pressed()): return
	get_viewport().set_input_as_handled()
	match state:
		State.MAIN: _handle_main(event)
		State.BUY:  _handle_buy(event)
		State.SELL: _handle_sell(event)
		State.TALK: _handle_talk(event)
