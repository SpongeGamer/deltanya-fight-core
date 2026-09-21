extends Resource
class_name ShopTalkTopic

## Одна тема в меню "Поговорить".
## label   — текст кнопки (например "О тебе", "О мире")
## dialogue — массив DE, запускается при выборе темы

@export var label   : String    = ""
@export var dialogue: Array[DE] = []
