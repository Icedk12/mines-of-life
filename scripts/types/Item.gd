class_name ItemData extends Resource

@export var item_id : int = -1
@export var item_name : String
@export var stack_size : int = 99
@export var icon : Texture2D = preload("res://assets/items/Missingno.png")          ## for the inventory UI
@export var block_id : int = -1
@export var equipment_slot_mode : EquipmentSlotMode.Mode = EquipmentSlotMode.Mode.NONE

@export var stat_data : StatData
