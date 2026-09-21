extends ItemUsePredicate
# Ретранслятор: тоглит флаг translator_active в Global.
# Не удаляется после использования — это переключатель.

func use_item(_user, _target) -> void:
	if Global.get_flag("translator_active"):
		Global.clear_flag("translator_active")
		Global.display_text.emit("  * Ретранслятор отключён.", false)
	else:
		Global.set_flag("translator_active")
		Global.display_text.emit("  * Ретранслятор включён.\n  * Теперь вы понимаете Шрумпов.", false)
