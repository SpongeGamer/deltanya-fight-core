extends ItemUsePredicate
class_name HealUsePredicate

@export var amount : int

func use_item(user : Character, used_on : Character) -> void:
	display_use_text(user)
	await Global.text_finished
	
	Global.display_text.emit("  * " + used_on.title + " восстановил " + str(amount) + " HP!", true)
	await Global.text_finished
	
	used_on.heal(amount)
	await user.get_tree().create_timer(0.2).timeout
