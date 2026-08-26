class_name CutsceneManager extends Node

signal cutscene_started
signal cutscene_ended

@export var running : bool = false
@export_category("Components")
@export var camera : Camera2D
@export_category("Cutscenes")
@export var cutscenes : Array[PackedScene]

var keyframes : Array[CameraKeyframe]

@onready var timer : Timer = $Timer

var current_tween : Tween
var current_keyframe : int = 0

func _ready() -> void:
	timer.timeout.connect(_advance_keyframe)
	camera.make_current()
	camera.enabled = true
	_parse_cutscene_tree()
	
	if running:
		print("Started cutscene")
		start()

func start() -> void:
	if keyframes.is_empty():
		print("Keyframes array is empty")
		return
	running = true
	current_keyframe = 0
	_advance_keyframe()
	cutscene_started.emit()

func _parse_cutscene_tree() -> void:
	for scene : PackedScene in cutscenes:
		var cutscene : Cutscene = scene.instantiate()
		cutscene.parse_cutscene()
		keyframes.append_array(cutscene.keyframes)

func _advance_keyframe() -> void:
	if current_keyframe >= keyframes.size():
		running = false
		cutscene_ended.emit()
		print("Cutscene ended")
		return
		
	if current_tween and current_tween.is_running():
		current_tween.kill()
		
	var key : CameraKeyframe = keyframes[current_keyframe]
	
	current_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	current_tween.tween_property(camera, "global_position", key.pos, key.duration)
	current_tween.tween_property(camera, "rotation", key.rot, key.duration)
	current_tween.tween_property(camera, "zoom", Vector2(key.zoom, key.zoom), key.duration)
	print("Tweened camera")
	
	current_keyframe += 1
	
	timer.start(key.still_time + key.duration)
