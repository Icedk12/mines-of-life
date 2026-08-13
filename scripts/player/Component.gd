class_name Component extends Node

@export var player : Player ## Mutually exclusive with isPlayerChild. (Retard proof)
@export var is_player_child : bool = false ## Tick when the component is the child of a player, it will then automatically assign it to the player internal variable.

func _ready() -> void:
	if not player == null:
		# If player does exist
		is_player_child = false
	
	if is_player_child:
		_is_player_child()

func _is_player_child() -> void:
	player = get_parent() as Player
