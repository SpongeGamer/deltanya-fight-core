extends Pellet
# Луч-сканер: широкий горизонтальный снаряд движется по арене слева направо.
# Не дублируется — один экземпляр, атака двигает его напрямую.
# Скорость задаётся снаружи.

var speed     := 90.0
var direction := 1.0   # +1 = вправо, -1 = влево
var moving    := false

func _ready() -> void:
	if !visible:
		return
	moving = true

func _physics_process(delta: float) -> void:
	if !moving or !visible:
		return
	position.x += direction * speed * delta
	# Луч сам по себе не умирает — атака управляет им
