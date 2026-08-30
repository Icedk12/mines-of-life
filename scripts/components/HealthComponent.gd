class_name HealthComponent extends CharacterComponent

signal health_changed(current : float, max : float)
signal died(xp : float)

@export var xp_drop : float = 1.0
@export var stat_manager : StatManager
@export_group("Health & Other")
@export var max_health : float = 10.0
@export var on_death_components : Array[Component] = []

@export_group("Audio")
@export var audio_source : AudioSourceComponent ## optional — reuses the pooled voice system if wired
@export var damage_sounds : Array[AudioStream] = []
@export var death_sounds : Array[AudioStream] = []

@export_group("Visuals")
@export var sprite : Sprite2D
@export var is_player : bool = false

var _fallback_player : AudioStreamPlayer2D
var tween : Tween
var current_health : float

func _ready() -> void:
	current_health = max_health

func take_damage(damage : float, knockback_dir : Vector2 = Vector2.ZERO, knockback_force : float = 0.0) -> void:
	if current_health <= 0.0:
		return
	if stat_manager:
		current_health = max(current_health - damage / (stat_manager.final_stats.defense_modifier + stat_manager.final_stats.defense_offset), 0.0)
	else:
		current_health = max(current_health - damage, 0.0)
	health_changed.emit(current_health, max_health)

	if knockback_force > 0.0 and knockback_dir != Vector2.ZERO:
		var body := get_parent()
		if body.has_method("apply_knockback"):
			body.apply_knockback(knockback_dir + Vector2(0, 1), knockback_force)

	if current_health <= 0.0:
		_play_sound(death_sounds)
		_on_death()
	else:
		_play_sound(damage_sounds)
		_on_damaged()
	_overlay_tween(Color(1.0, 0.0, 0.0, 1.0))

func heal(amount : float) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	_overlay_tween(Color(0.467, 1.0, 0.0, 1.0))

func _on_damaged() -> void:
	for component in on_death_components:
		if component.has_method("on_damaged"):
			component.on_damaged()

func _on_death() -> void:
	died.emit(xp_drop * GameSettings.difficulty)
	for component in on_death_components:
		if component.has_method("on_death"):
			component.on_death()

func _play_sound(sounds : Array[AudioStream]) -> void:
	if sounds.is_empty():
		return

	if audio_source:
		audio_source.play_sound(sounds)
		return

	if not _fallback_player:
		_fallback_player = AudioStreamPlayer2D.new()
		add_child(_fallback_player)

	var body := get_parent()
	if body is Node2D:
		_fallback_player.global_position = body.global_position

	_fallback_player.stream = sounds[randi() % sounds.size()]
	_fallback_player.pitch_scale = randf_range(0.95, 1.05)
	_fallback_player.play()

func _overlay_tween(color : Color) -> void:
	if not sprite: return
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween().set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "self_modulate", color, 0.2)
	
	_return_from_tween()

func _return_from_tween() -> void:
	var col : Color = GameSettings.player_mod if is_player else Color(1, 1, 1)
	
	tween.tween_property(sprite, "self_modulate", col, 0.1)\
		.set_trans(Tween.TRANS_QUAD)
