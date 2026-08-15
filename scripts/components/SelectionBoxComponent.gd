class_name SelectionBoxComponent extends CharacterComponent

@export var mine_component : MineComponent
@export var sprite : Sprite2D

var selected_tile_global_pos : Vector2

func _physics_process(delta: float) -> void:
	if sprite.global_position == character.global_position:
		sprite.visible = false
	elif sprite.global_position.distance_to(character.global_position) >= mine_component.max_mining_distance + 4.5:
		sprite.visible = false
	else:
		sprite.visible = true
	sprite.global_position = selected_tile_global_pos
	
	
