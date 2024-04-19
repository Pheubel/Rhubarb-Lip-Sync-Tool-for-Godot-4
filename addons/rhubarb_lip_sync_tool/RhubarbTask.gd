extends RefCounted
class_name RhubarbTask

signal task_completed
signal _task_completed_internal

var _result: Variant
var _thread: Thread
var _is_completed: bool

func _on_task_completed() -> void:
	_is_completed = true
	_result = _thread.wait_to_finish()
	
	task_completed.emit()

func get_result():
	if !_is_completed:
		push_error("Atempting to get result before task has completed")
		return
	
	return _result

func _complete_task():
	_task_completed_internal.emit()
