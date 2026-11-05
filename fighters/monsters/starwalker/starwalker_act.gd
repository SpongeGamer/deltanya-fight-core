extends Act
## Обиделся, но не штрафует игрока: следующая атака начинается с паузы-шутки.
func do_act(p_from: Character, p_to: Monster):
	if p_to is Starwalker:
		(p_to as Starwalker).react_to_chicken()
	await super.do_act(p_from, p_to)
