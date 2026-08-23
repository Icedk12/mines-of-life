class_name ItemData extends Resource

@export var item_id : int
@export var item_name : String
@export var stack_size : int = 99
@export var icon : Texture2D          ## for the inventory UI
@export var block_id : int
@export var equipment_slot_mode : EquipmentSlotMode.Mode = EquipmentSlotMode.Mode.NONE

@export var stat_data : StatData
