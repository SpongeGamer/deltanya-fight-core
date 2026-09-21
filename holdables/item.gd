extends Resource
class_name Item

enum InventoryTab{
	ITEMS,
	KEY_ITEMS,
	ARMORS,
	WEAPONS
}

@export var name := "Equippable"
@export var short_description := ""
@export_multiline var long_description := "An item that can be equipped."
@export var price: int = 0
@export var sell_price : int = 0
@export var inventory_tab : InventoryTab
@export var light_world_form : LightWorldForm
@export var usePredicate : ItemUsePredicate
@export var is_key_item: bool = false
