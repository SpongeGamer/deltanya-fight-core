extends ItemUsePredicate
# Однократная активация: перевод остается включенным после использования.

func use_item(_user, _target) -> void:
	Global.set_flag("translator_active")
	Global.set_flag("forest_translator_obtained")
	Global.display_text.emit("  * Ретранслятор включен.\n  * Теперь вы понимаете Шрумпов.", false)
