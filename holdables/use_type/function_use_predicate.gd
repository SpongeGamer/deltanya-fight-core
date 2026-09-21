extends ItemUsePredicate
class_name FunctionUsePredicate

@export var callable : Callable = func(user : Character, used_on : Character): return

func use_item(user : Character, used_on : Character) -> void:
	display_use_text(user)
	await Global.text_finished
	await callable.call(user, used_on)
