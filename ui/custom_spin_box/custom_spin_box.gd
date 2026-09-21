extends CenterContainer
class_name CustomSpinBox

@export var options: PackedStringArray = ["NONE"]
var option := 0:
	set(p_option):
		option = wrapi(p_option, 0, options.size())
		if $HBox/Label:
			$HBox/Label.text = options[option]

func _ready() -> void:
	option = option

func _input(p_event: InputEvent) -> void:
	if has_focus() and p_event is InputEventKey and p_event.is_pressed():
		if p_event.is_action_pressed("left"):
			option -= 1
			Sounds.play("snd_select")
		elif p_event.is_action_pressed("right"):
			option += 1
			Sounds.play("snd_select")
