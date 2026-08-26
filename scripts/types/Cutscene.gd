class_name Cutscene extends Node

var keyframes : Array[CameraKeyframe]

func parse_cutscene() -> void:
	var children = get_children()
	for child : KeyframeMarker in children:
		var kf : CameraKeyframe = child.keyframe_settings.duplicate()
		kf.pos = child.global_position
		kf.rot = child.rotation
		keyframes.append(kf)
