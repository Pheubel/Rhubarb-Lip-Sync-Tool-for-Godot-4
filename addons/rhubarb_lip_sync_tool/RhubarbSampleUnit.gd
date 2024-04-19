extends Object
class_name RhubarbSampleUnit

const MouthShape := preload("res://addons/rhubarb_lip_sync_tool/MouthShape.gd").MouthShape

var sample_time: float
var mouth_shape: MouthShape

func _to_string() -> String:
	return "<%0.2f, %s>" % [sample_time, MouthShape.find_key(mouth_shape)]
