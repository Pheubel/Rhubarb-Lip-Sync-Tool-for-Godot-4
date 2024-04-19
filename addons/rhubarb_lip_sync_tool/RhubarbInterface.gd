@tool
extends Node
class_name RhubarbInterfaceNode

const output_directory_path := "res://.godot/rhubarb/output"
const dialog_directory_path := "res://.godot/rhubarb/dialog"

func _enter_tree() -> void:
	print("Rhubarb Interface Node entered tree")

func _ready() -> void:
	#run_rhubarb("res://what-the-hell-meme-sound-effect.ogg")
	
	var task := get_mouth_shape_data_async("res://what-the-hell-meme-sound-effect.ogg")
	
	print("started rubarb task")
	
	await task.task_completed
	var data := task.get_result() as RhubarbData 
	
	print(data.samples)
	
	pass

## Start Rhubarb to sample the audio file. Returns the path to the output file.
func run_rhubarb(input_file: String, dialog_file: String = "", recognizer: String = "pocketSphinx", output_format: String = "tsv") -> String:
	print("inside a run")
	
	if !Engine.is_editor_hint():
		push_warning("[Rhubarb Lip Sync Tool]: Running Rhubarb outside the editor. This can cause hanging.")
	
	if !RhubarbUtilities.validate_editor_settings():
		return ""
	
	if !FileAccess.file_exists(input_file):
		push_error("[Rhubarb Lip Sync Tool]: File '%s' does not exist." % input_file)
		return ""
	
	var output_path = output_directory_path.path_join("%s%s" % [input_file.get_file().trim_suffix(input_file.get_extension()), output_format])
	
	var editor_settings := EditorInterface.get_editor_settings()
	
	var executable_path := editor_settings.get_setting(RhubarbUtilities.executable_path_setting) as String
	
	var rhubarb_arguments := PackedStringArray()
	rhubarb_arguments.append_array([
		ProjectSettings.globalize_path(input_file),
		"--output", ProjectSettings.globalize_path(output_path),
		"--recognizer", recognizer,
		"--extendedShapes", "GHX",
		"--exportFormat", output_format
		##"--quiet"
	])
	
	if !dialog_file.is_empty():
		if !FileAccess.file_exists(dialog_file):
			push_error("[Rhubarb Lip Sync Tool]: Dialog file '%s' could not be found." % dialog_file)
			return ""
		
		rhubarb_arguments.append_array([
			"--dialogFile", ProjectSettings.globalize_path(dialog_file),
		])
	
	print("[Rhubarb Lip Sync Tool]: Begin analyzing on '%s' with arguments %s." % [input_file, rhubarb_arguments])
	
	_ensure_directories_exist()
	
	var result = OS.execute(
		executable_path,
		rhubarb_arguments,
	)
	
	print("[Rhubarb Lip Sync Tool]: Stopped execution.")
	print(result)
	
	if result:
		push_error("[Rhubarb Lip Sync Tool]: Failed to run Rhubarb to completion.")
		return ""
	
	print("[Rhubarb Lip Sync Tool]: Written to '%s'." % output_path)
	return output_path

## Retrieves the data from an audio file. If possible, use async version instead.
func get_mouth_shape_data(input_file: String, dialog_file: String = "", recognizer: String = "pocketSphinx") -> RhubarbData:
	var output_file = run_rhubarb(input_file, dialog_file, recognizer)
	
	if output_file.is_empty():
		return null
	
	return RhubarbUtilities.parse_from_tsv(output_file)

## internal function, do not call directly.
func _t_get_mouth_shape_data_async(input_file: String, dialog_file: String, recognizer: String, task: RhubarbTask) -> RhubarbData:
	var data := get_mouth_shape_data(input_file, dialog_file, recognizer)
	task._complete_task.call_deferred()
	return data

## Retrieves the data from an audio file on a different thread to not block interactions.
func get_mouth_shape_data_async(input_file: String, dialog_file: String = "", recognizer: String = "pocketSphinx") -> RhubarbTask:
	#TODO: make this better, as thread isn't as performant on Windows.
	# but since this is meant for the editor, it isn't critical.
	var thread := Thread.new()
	var task := RhubarbTask.new()
	
	task._thread = thread
	var error := thread.start(_t_get_mouth_shape_data_async.bind(input_file, dialog_file, recognizer, task))
	
	if error:
		push_error("[Rhubarb Lip Sync Tool]: Failed to start task. Error: %s" % error_string(error))
		return null
	
	return task

## Removes all files from the output and dialog directories
func clear_directory() -> void:
	_ensure_directories_exist()
	
	var output_dir := DirAccess.open(output_directory_path)
	if output_dir:
		output_dir.list_dir_begin()
		
		var next_item := output_dir.get_next()
		while !next_item.is_empty():
			if !output_dir.current_is_dir():
				output_dir.remove(next_item)
			
			next_item = output_dir.get_next()
	
	var dialog_dir := DirAccess.open(dialog_directory_path)
	if dialog_dir:
		dialog_dir.list_dir_begin()
		
		var next_item := dialog_dir.get_next()
		while !next_item.is_empty():
			if !dialog_dir.current_is_dir():
				dialog_dir.remove(next_item)
			
			next_item = dialog_dir.get_next()

func _ensure_directories_exist() -> void:
	if !DirAccess.dir_exists_absolute(output_directory_path):
		DirAccess.make_dir_recursive_absolute(output_directory_path)
	
	if !DirAccess.dir_exists_absolute(dialog_directory_path):
		DirAccess.make_dir_recursive_absolute(dialog_directory_path)
