class_name CameraKeyframe extends Resource

@export var pos : Vector2
@export var rot : float
@export var zoom : float = 1.0
@export var duration : float = 1.0
@export var still_time : float = 0.0 ## How much time passes before another keyframe begins
@export_group("Tweens")
@export var pos_tween : TweenInfo = TweenInfo.new()
@export var rot_tween : TweenInfo = TweenInfo.new()
@export var zoom_tween : TweenInfo = TweenInfo.new()
