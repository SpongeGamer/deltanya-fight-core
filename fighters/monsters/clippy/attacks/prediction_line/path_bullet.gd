extends Pellet
# Пуля которая движется строго по заданному массиву точек.
# path и speed задаются снаружи перед add_child.

var path: Array[Vector2] = []
var speed := 80.0  # пикселей в секунду вдоль пути

var _dist := 0.0   # пройденное расстояние вдоль пути
var _total := 0.0  # полная длина пути

func _ready() -> void:
	if path.is_empty() or !visible:
		return
	# Считаем полную длину пути
	for i in range(1, path.size()):
		_total += path[i].distance_to(path[i - 1])
	position = path[0]

func _physics_process(delta: float) -> void:
	if path.is_empty() or !visible:
		return
	_dist += speed * delta
	if _dist >= _total:
		queue_free()
		return
	# Находим позицию на пути по пройденному расстоянию
	var walked := 0.0
	for i in range(1, path.size()):
		var seg_len := path[i].distance_to(path[i - 1])
		if walked + seg_len >= _dist:
			var t := (_dist - walked) / seg_len
			position = path[i - 1].lerp(path[i], t)
			return
		walked += seg_len
