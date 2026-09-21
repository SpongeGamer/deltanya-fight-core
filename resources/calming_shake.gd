# calming_shake.gd
extends RichTextEffect
class_name CalmingShakeEffect

var bbcode = "calm_shake"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	# Параметры из тега:
	# max_level - максимальная сила тряски в начале
	# duration - за сколько секунд успокоиться
	# connected - трясутся ли буквы вместе (1) или каждая сама (0)
	
	var max_level = char_fx.env.get("max", 10.0)
	var duration = char_fx.env.get("dur", 2.0)
	var connected = char_fx.env.get("conn", 1.0)
	
	# Прошедшее время с начала эффекта
	var elapsed = char_fx.elapsed_time
	
	# Если время вышло — эффекта нет
	if elapsed >= duration:
		return true
	
	# Затухание силы тряски: от 1.0 до 0.0
	var fade = 1.0 - (elapsed / duration)
	var current_level = max_level * fade
	
	# Генерация смещения
	var offset_x: float
	var offset_y: float
	
	if connected == 1.0:
		# Все буквы трясутся одинаково (зависит только от времени)
		var seed_val = elapsed * 20.0
		offset_x = sin(seed_val) * current_level
		offset_y = cos(seed_val * 1.3) * current_level
	else:
		# Каждая буква сама по себе — используем relative_index
		var seed_val = char_fx.relative_index * 2.0 + elapsed * 20.0
		offset_x = sin(seed_val) * current_level
		offset_y = cos(seed_val * 1.7) * current_level
	
	char_fx.offset = Vector2(offset_x, offset_y)
	
	return true
