extends Resource
class_name Act

@export var title := ""
@export_multiline var text := "  * Ничего не произошло."
@export_range(0, 100) var spare_percent := 0

func do_act(p_from: Character, p_to: Monster):
	p_from.do_animation(Character.Animations.ACT) 
	Global.display_text.emit(text, true)
	await Global.text_finished
	if spare_percent != 0:
		p_to.increase_mercy(spare_percent / 100.0)
	p_from.do_animation(Character.Animations.IDLE)
	p_from.act_finished.emit()
