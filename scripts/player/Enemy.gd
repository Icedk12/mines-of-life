class_name Enemy extends CharacterBody2D

enum MovementMode { GROUND, FLYING }

@export_group("Components")
@export var sprite_modifier_component : SpriteModifierComponent
@export var health_component : HealthComponent

@export_group("Character")
@export var attack_knockback_force : float = 90.0
@export var movement_mode : MovementMode = MovementMode.GROUND
@export var move_speed : float = 40.0
@export var contact_damage : float = 1.0
@export var attack_range : float = 12.0
@export var attack_cooldown : float = 1.0

@export_group("Ground")
@export var gravity_multiplier : float = 1.0
@export var jump_velocity : float = 130.0
@export var max_jump_tile_height : int = 2 ## tiles the pathfinder is allowed to route "up"

@export_group("Pathfinding")
@export var repath_interval : float = 0.4
@export var path_search_padding_tiles : int = 6 ## extra tiles around the enemy/player bounding box

@export_group("Visuals")
@export var death_particles : GPUParticles2D

var is_alive : bool = true

var player : Player
var level_generator : LevelGenerator

var _knockback_velocity : Vector2 = Vector2.ZERO
var _knockback_timer : float = 0.0

var _path : PackedVector2Array = []
var _path_index : int = 0
var _repath_timer : float = 0.0
var _attack_timer : float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	if health_component:
		health_component.died.connect(_on_died)

func setup(_player: Player, _level_generator: LevelGenerator) -> void:
	player = _player
	level_generator = _level_generator

func _physics_process(delta: float) -> void:
	_attack_timer = max(_attack_timer - delta, 0.0)
	if not player or not level_generator or not level_generator.tilemap:
		return

	if movement_mode == MovementMode.GROUND:
		_apply_gravity(delta)
	
	if not is_alive: 
		_apply_gravity(delta)
	
	if _knockback_timer > 0.0:
		_knockback_timer -= delta
		velocity.x = _knockback_velocity.x
		if movement_mode == MovementMode.FLYING:
			velocity.y = _knockback_velocity.y
		move_and_slide()
		return 

	var dist := global_position.distance_to(player.global_position)
	if dist <= attack_range:
		velocity.x = 0.0
		if movement_mode == MovementMode.FLYING:
			velocity.y = 0.0
		move_and_slide()
		if _attack_timer <= 0.0:
			_attack_player()
		return

	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = repath_interval
		_recalculate_path()

	sprite_modifier_component._sprite_sin_offset(delta, true)

	_follow_path(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + get_gravity().y * gravity_multiplier * delta, 400.0)
	elif velocity.y > 0:
		velocity.y = 0.0

func _attack_player() -> void:
	if not is_alive: return
	_attack_timer = attack_cooldown
	var attack_dir : Vector2 = global_position.direction_to(player.global_position)
	if sprite_modifier_component:
		sprite_modifier_component._squash()
	if player.health_component:
		player.health_component.take_damage(contact_damage, attack_dir, attack_knockback_force)

func get_health_component() -> HealthComponent:
	return health_component

func _on_died(xp : float = 0.0) -> void:
	is_alive = false
	
	collision_layer = 0
	collision_mask = 0
	
	sprite_modifier_component.sprite.hide()
	sprite_modifier_component._flatten()
	
	death_particles.emitting = true

	await death_particles.finished
	queue_free()

func _recalculate_path() -> void:
	if not is_alive: return
	var tilemap := level_generator.tilemap
	var start_tile := tilemap.local_to_map(tilemap.to_local(global_position))
	var goal_tile := tilemap.local_to_map(tilemap.to_local(player.global_position))

	_path = TilePathfinder.find_path(
		tilemap, start_tile, goal_tile,
		path_search_padding_tiles,
		movement_mode == MovementMode.FLYING,
		max_jump_tile_height
	)
	_path_index = 0

func _follow_path(delta: float) -> void:
	if not is_alive: return
	if _path.is_empty() or _path_index >= _path.size():
		velocity.x = 0.0
		return

	var target : Vector2 = _path[_path_index]
	if global_position.distance_to(target) < 6.0:
		_path_index += 1
		return

	var dir := (target - global_position)

	if movement_mode == MovementMode.FLYING:
		velocity = dir.normalized() * move_speed
	else:
		velocity.x = sign(dir.x) * move_speed
		if dir.y < -4.0 and is_on_floor():
			velocity.y = -jump_velocity
