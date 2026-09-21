extends Resource
class_name ItemUsePredicate

var item : Item
@export var remove_after_use : bool = false

func use_item(user : Character, used_on : Character) -> void:
	display_use_text(user)
	await Global.text_finished
	
	Global.display_text.emit("  * Но ничего не произошло...", true)
	await Global.text_finished

func display_use_text(user : Character) -> void:
	Global.display_text.emit("  * " + user.title + " использует " + item.name + ".", true)
