extends Node

const Stats = AbstractFighter.Stats

# ─────────────────────────────────────────
# Базовые данные персонажей
# ─────────────────────────────────────────
const DEFAULT_DATA := {
	"anne": {
		"name": "Аня",
		"color": Color("#ff4444"),
		"stats": {
			Stats.MAX_HP: 90,
			Stats.ATTACK: 5,
			Stats.DEFENSE: 5,
			Stats.MAGIC: 5
		}
	},
	"kate": {
		"name": "Катя",
		"color": Color("#cc44ff"),
		"stats": {
			Stats.MAX_HP: 100,
			Stats.ATTACK: 3,
			Stats.DEFENSE: 4,
			Stats.MAGIC: 10
		}
	},
	"egor": {
		"name": "Егор",
		"color": Color("#ff8800"),
		"stats": {
			Stats.MAX_HP: 110,
			Stats.ATTACK: 5,
			Stats.DEFENSE: 8,
			Stats.MAGIC: 4
		}
	}
}

# ─────────────────────────────────────────
# Экипировка персонажей
# ─────────────────────────────────────────
var equipment := {}

func _ready() -> void:
	for key in DEFAULT_DATA:
		equipment[key] = {
			"weapon": null,
			"armors": [null, null],
			"hp": -1  # -1 = ещё не было боя, выставить max при первом применении
		}

# ─────────────────────────────────────────
# Чтение данных (С ПРОВЕРКАМИ)
# ─────────────────────────────────────────
func get_display_name(key: String) -> String:
	if key == null or key == "" or not DEFAULT_DATA.has(key):
		return "???"
	return DEFAULT_DATA[key]["name"]

func get_color(key: String) -> Color:
	if key == null or key == "" or not DEFAULT_DATA.has(key):
		return Color.WHITE
	return DEFAULT_DATA[key]["color"]

func get_stats(key: String) -> Dictionary:
	if key == null or key == "" or not DEFAULT_DATA.has(key):
		return {}
	return DEFAULT_DATA[key]["stats"].duplicate()

func get_weapon(key: String):
	if key == null or key == "" or not equipment.has(key):
		return null
	return equipment[key]["weapon"]

func get_armors(key: String) -> Array:
	if key == null or key == "" or not equipment.has(key):
		return [null, null]
	return equipment[key]["armors"]

# ─────────────────────────────────────────
# Изменение экипировки
# ─────────────────────────────────────────
func set_weapon(key: String, eq: Equippable) -> void:
	if key == null or key == "" or not equipment.has(key):
		return
	equipment[key]["weapon"] = eq

func set_armor(key: String, slot: int, eq: Equippable) -> void:
	if key == null or key == "" or not equipment.has(key):
		return
	if slot < 0 or slot >= equipment[key]["armors"].size():
		return
	equipment[key]["armors"][slot] = eq

# ─────────────────────────────────────────
# Применение данных к Character
# ─────────────────────────────────────────
func apply_to_character(key: String, ch: Character) -> void:
	if key == null or key == "" or not DEFAULT_DATA.has(key):
		return
	
	var data: Dictionary = DEFAULT_DATA[key]

	ch.title = data["name"]

	var raw_stats: Dictionary = data["stats"]
	var stats: Dictionary[AbstractFighter.Stats, int] = {}

	for s in raw_stats.keys():
		stats[s as AbstractFighter.Stats] = int(raw_stats[s])

	ch.base_fighter_stats = stats

	if equipment.has(key):
		ch.weapon = equipment[key]["weapon"]
		var armors: Array = equipment[key]["armors"]
		for i in armors.size():
			ch.swap_armor(i, armors[i])
		var saved_hp: int = equipment[key]["hp"]
		ch.current_hp = ch.get_max_hp() if saved_hp < 0 else saved_hp
	else:
		ch.current_hp = ch.get_max_hp()
	
	ch.alive = ch.current_hp > 0

# ─────────────────────────────────────────
# Сохранение данных из Character
# ─────────────────────────────────────────
func save_from_character(key: String, ch: Character) -> void:
	if key == null or key == "" or not equipment.has(key):
		return
	equipment[key]["weapon"] = ch.weapon
	equipment[key]["armors"] = ch.armors.duplicate()
	equipment[key]["hp"] = ch.current_hp

# ─────────────────────────────────────────
# Сериализация экипировки для файла сохранения
# ─────────────────────────────────────────
func serialize_equipment() -> Dictionary:
	var result := {}
	for key in equipment:
		var eq = equipment[key]
		var weapon_path : String = eq["weapon"].resource_path if eq["weapon"] != null else ""
		var armor_paths : Array = []
		for armor in eq["armors"]:
			armor_paths.append(armor.resource_path if armor != null else "")
		result[key] = {
			"weapon": weapon_path,
			"armors": armor_paths,
			"hp": eq["hp"],
		}
	return result

func deserialize_equipment(data: Dictionary) -> void:
	for key in data:
		if not equipment.has(key):
			continue
		var eq = data[key]
		# Оружие
		var wp : String = str(eq.get("weapon", ""))
		equipment[key]["weapon"] = load(wp) if wp != "" else null
		# Броня
		var raw_armors : Array = eq.get("armors", [])
		var armors : Array = [null, null]
		for i in min(raw_armors.size(), 2):
			var ap = str(raw_armors[i])
			armors[i] = load(ap) if ap != "" else null
		equipment[key]["armors"] = armors
		# HP
		equipment[key]["hp"] = int(eq.get("hp", -1))
