extends RichTextLabel

var require_input := false

static func is_letter_or_number(p_char: String) -> bool:
	return p_char.unicode_at(0) > 32 and p_char != " "

func _physics_process(_delta: float) -> void:
	if Global.displaying_text and visible_ratio < 1.0:
		visible_characters += 1
		var c := text[visible_characters - 1]
		if is_letter_or_number(c):
			Sounds.play("snd_text")
		
		# Проверяем, закончился ли текст
		if visible_characters >= get_total_character_count():
			visible_ratio = 1.0
			if !require_input:
				Global.displaying_text = false
				Global.text_finished.emit()

func _text_without_square_brackets(p_text: String) -> String:
	var result := ""
	var inside := false
	for ch in p_text:
		if ch == "[":
			inside = true
		elif ch == "]":
			inside = false
		elif not inside:
			result += ch
	return result
	
func hide_text() -> void:
	visible_characters = 0
	Global.displaying_text = false

func show_text(p_text: String, p_requires_input: bool) -> void:
	text = p_text
	Global.displaying_text = true
	visible_characters = 0
	require_input = p_requires_input

func _ready() -> void:
	Global.display_text.connect(show_text)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action("confirm") and event.is_pressed():
		if visible_ratio >= 1.0 and require_input and Global.displaying_text:
			hide_text()
			Global.text_finished.emit()
