@tool
extends Node
class_name RhubarbInterfaceNode

const output_directory_path := "res://.godot/rhubarb/output"
const dialog_directory_path := "res://.godot/rhubarb/dialog"

func _enter_tree() -> void:
	print("Rhubarb Interface Node entered tree")

func _ready() -> void:
	#run_rhubarb("res://what-the-hell-meme-sound-effect.ogg")
	
	#var task := get_mouth_shape_data_async("res://what-the-hell-meme-sound-effect.ogg")
	#
	#print("started rubarb task")
	#
	#await task.task_completed
	#var data := task.get_result() as RhubarbData 
	#
	#print(data.samples)
	#
	pass

## Start Rhubarb to sample the audio file. Returns the path to the output file.
func run_rhubarb(input_file: String, dialog_file: String = "", recognizer: String = "pocketSphinx", output_format: String = "tsv") -> String:
	if !Engine.is_editor_hint():
		push_warning("[Rhubarb Lip Sync Tool]: Running Rhubarb outside the editor. This is unconventional.")
	
	if !RhubarbUtilities.validate_editor_settings():
		return ""
	
	if !FileAccess.file_exists(input_file):
		push_error("[Rhubarb Lip Sync Tool]: File '%s' does not exist." % input_file)
		return ""
	
	var output_path = _file_path_as_output_path(input_file, output_directory_path, output_format)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	
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

func bake_animation_library_from_nodes(animation_arguments: Array[Dictionary], recognizer: String, animation_player: AnimationPlayer, mouth_sprite: Node, audio_stream_player: Node = null) -> AnimationLibrary:
	var animation_root := animation_player.get_node(animation_player.root_node)
	var mouth_sprite_path: String
	var mouth_handler: Callable
	var reset_handler: Callable
	
	if mouth_sprite is Sprite2D or mouth_sprite is Sprite3D:
		mouth_sprite_path = animation_root.get_path_to(mouth_sprite)
		mouth_handler = mouth_sprite_handler.bind(mouth_sprite_path)
		reset_handler = reset_sprite_handler.bind(mouth_sprite_path)
	else:
		assert(false, "[Rhubarb Lip Sync Tool]: Node type for mouth sprite node is not supported.")
	
	var audio_stream_player_path := NodePath()
	if audio_stream_player:
		audio_stream_player_path = animation_root.get_path_to(audio_stream_player)
	
	return bake_animation_library(
		animation_arguments, 
		recognizer, 
		mouth_handler, 
		reset_handler,
		audio_stream_player_path
	)

## Creates a library
func bake_animation_library(animation_arguments: Array[Dictionary], recognizer: String, mouth_handler: Callable, reset_handler: Callable, audio_stream_player_path := NodePath()) -> AnimationLibrary:
	var editor_settings := EditorInterface.get_editor_settings()
	var animation_library := AnimationLibrary.new()
	var run_if_cached := editor_settings.get_setting(RhubarbUtilities.run_if_cached_setting) as bool
	var animation_count := animation_arguments.size()
	
	print("[Rhubarb Lip Sync Tool]: Beginning baking animation library with %d animations." % animation_count)
	
	var reset_animation := Animation.new()
	
	reset_handler.call(reset_animation)
	
	animation_library.add_animation("RESET", reset_animation)
	
	for index: int in animation_count:
		var pretty_index : int = index + 1
		var arguments := animation_arguments[index]
		var audio_data: RhubarbData
		
		var animation_name := arguments.get("animation_name", "") as String
		animation_name = animation_name.rstrip(' ')
		if animation_name.is_empty():
			animation_name = "(%d)" % pretty_index
		else:
			animation_name = "(%d) %s" % [pretty_index, arguments.get("animation_name", "")]
		var dialog_text := arguments.get("dialog_text", "") as String
		var audio_stream := arguments.get("audio_stream", null) as AudioStream
		var audio_path: String 
		var mouth_library := arguments.get("mouth_library", null) as MouthLibraryResource
		
		if audio_stream:
			audio_path = audio_stream.resource_path
			if !FileAccess.file_exists(audio_path):
				push_error("[Rhubarb Lip Sync Tool]: Path '%s' is not a file path. Paths to packed scenes are not supported." % audio_path)
				continue
		else:
			push_error("[Rhubarb Lip Sync Tool]: No audio stream was passed to the animation arguments array at index %d." % index)
			continue
		
		if! mouth_library:
			push_error("[Rhubarb Lip Sync Tool]: No mouth library was passed to the animation arguments array at index %d." % index)
			continue
		
		var out_path := _file_path_as_output_path(audio_path, output_directory_path, "tsv")
		if !run_if_cached and FileAccess.file_exists(out_path):
			audio_data = RhubarbUtilities.parse_from_tsv(out_path)
		else:
			var dialog_path := ""
			if !dialog_text.is_empty():
				var dialog_file = create_dialog_file(dialog_text, audio_path)
				if dialog_file:
					dialog_path = dialog_file.get_path_absolute()
			
			# TODO: figure out how i'm going to async everything
			audio_data = get_mouth_shape_data(audio_path, dialog_path, recognizer)
		
		var animation := Animation.new()
		
		mouth_handler.call(animation, audio_data, mouth_library)
		
		# Only add audio track if a stream player was included as an argument
		if !audio_stream_player_path.is_empty():
			var audio_track_index := animation.add_track(Animation.TYPE_AUDIO)
			animation.track_set_path(audio_track_index, audio_stream_player_path)
			
			animation.audio_track_insert_key(audio_track_index, 0.0, audio_stream)
		
		animation.length = audio_data.samples[-1].sample_time
		
		var add_error := animation_library.add_animation(animation_name, animation)
		
		if !add_error:
			print("[Rhubarb Lip Sync Tool]: Finished baking animation %d out of %d: '%s'" % [pretty_index, animation_count, animation_name])
	
	print("[Rhubarb Lip Sync Tool]: Finished baking animation library.")
	
	return animation_library

#region Built in handlers
func reset_sprite_handler(reset_animation: Animation, mouth_path: NodePath) -> void:
	var mouth_texture_path = str(mouth_path) + ":texture"
	var reset_sprite_track_index := reset_animation.add_track(Animation.TYPE_VALUE)
	reset_animation.value_track_set_update_mode(reset_sprite_track_index, Animation.UPDATE_DISCRETE)
	reset_animation.track_set_path(reset_sprite_track_index, mouth_texture_path)

func mouth_sprite_handler(animation: Animation, audio_data: RhubarbData, mouth_library: MouthLibraryResource, mouth_path: NodePath) -> void:
	var mouth_texture_path = str(mouth_path) + ":texture"
	var sprite_track_index := animation.add_track(Animation.TYPE_VALUE)
	animation.value_track_set_update_mode(sprite_track_index, Animation.UPDATE_DISCRETE)
	animation.track_set_path(sprite_track_index, mouth_texture_path)
	
	for sample in audio_data.samples:
		animation.track_insert_key(
			sprite_track_index,
			sample.sample_time,
			RhubarbUtilities.get_mouth_texture(sample.mouth_shape, mouth_library),
			0
		)

func reset_property_handler(reset_animation: Animation, mouth_property: Dictionary) -> void:
	reset_properties_handler(reset_animation, [mouth_property])

func mouth_property_handler(animation: Animation, audio_data: RhubarbData, mouth_library: MouthLibraryResource, mouth_property: Dictionary) -> void:
	mouth_properties_handler(animation, audio_data, mouth_library, [mouth_property])

func reset_properties_handler(reset_animation: Animation, mouth_properties: Array[Dictionary]) -> void:
	for mouth_property in mouth_properties:
		var reset_sprite_track_index := reset_animation.add_track(mouth_property.get("animation_type", Animation.TYPE_VALUE))
		reset_animation.value_track_set_update_mode(reset_sprite_track_index, mouth_property.get("update_mode", Animation.UPDATE_DISCRETE))
		reset_animation.track_set_path(reset_sprite_track_index, mouth_property["property_path"])

func mouth_properties_handler(animation: Animation, audio_data: RhubarbData, mouth_library: MouthLibraryResource, mouth_properties: Array[Dictionary]) -> void:
	for mouth_property in mouth_properties:
		var sprite_track_index := animation.add_track(mouth_property.get("animation_type", Animation.TYPE_VALUE))
		animation.value_track_set_update_mode(sprite_track_index, mouth_property.get("update_mode", Animation.UPDATE_DISCRETE))
		animation.track_set_path(sprite_track_index, mouth_property["property_path"])
		var use_texture_mode := mouth_property.get("use_textures", true) as bool
				
		for sample in audio_data.samples:
			var key_value: Variant
			
			if use_texture_mode:
				key_value = RhubarbUtilities.get_mouth_texture(sample.mouth_shape, mouth_library)
			else:
				key_value = sample.mouth_shape
			
			animation.track_insert_key(
				sprite_track_index,
				sample.sample_time,
				key_value,
				0
			)
#endregion

func create_dialog_file(dialog: String, output_file_name: String) -> FileAccess:
	var dialog_path := _file_path_as_output_path(output_file_name, output_directory_path, "txt")
	
	DirAccess.make_dir_recursive_absolute(dialog_path.get_base_dir())
	
	var dialog_file := FileAccess.open(dialog_path, FileAccess.WRITE)
	if dialog_file:
		dialog_file.store_string(dialog)
	else:
		push_error("[Rhubarb Lip Sync Tool]: Failed to write to '%s'. Error: %s" % [dialog_path, error_string(FileAccess.get_open_error())])
	
	return dialog_file

## Removes all files from the output and dialog directories
func remove_directories() -> void:
	var directory_stack : Array[DirAccess] = []
	var directories_to_remove := PackedStringArray()
	
	directory_stack.push_back(DirAccess.open(output_directory_path))
	while !directory_stack.is_empty():
		var output_dir := directory_stack.pop_back() as DirAccess
		if !output_dir:
			continue
		
		for file in output_dir.get_files():
			output_dir.remove(file)
		
		for directory in output_dir.get_directories():
			directory_stack.push_back(output_dir.open(directory))
			directories_to_remove.append(output_dir.get_current_dir().path_join(directory))
		
		output_dir.list_dir_end()
	
	directory_stack.push_back(DirAccess.open(dialog_directory_path))
	while !directory_stack.is_empty():
		var dialog_dir := directory_stack.pop_back() as DirAccess
		if !dialog_dir:
			continue
		
		for file in dialog_dir.get_files():
			dialog_dir.remove(file)
		
		for directory in dialog_dir.get_directories():
			directory_stack.push_back(dialog_dir.open(directory))
			directories_to_remove.append(dialog_dir.get_current_dir().path_join(directory))
		
		dialog_dir.list_dir_end()
	
	for index in directories_to_remove.size():
		DirAccess.remove_absolute(directories_to_remove[-index - 1])

func _file_path_as_output_path(input_path:String, output_directory: String, output_format: String) -> String:
	return output_directory.path_join(input_path.trim_prefix("res://").trim_suffix(input_path.get_extension()) + output_format)

func ensure_directories_exist() -> void:
	if !DirAccess.dir_exists_absolute(output_directory_path):
		DirAccess.make_dir_recursive_absolute(output_directory_path)
	
	if !DirAccess.dir_exists_absolute(dialog_directory_path):
		DirAccess.make_dir_recursive_absolute(dialog_directory_path)
	
	#for recognizer: String in ProjectSettings.get_setting(RhubarbUtilities.known_recognizers_setting,[]):
		#var recognizer_output_directory_path := output_directory_path.path_join(recognizer)
		#if !DirAccess.dir_exists_absolute(recognizer_output_directory_path):
			#DirAccess.make_dir_recursive_absolute(recognizer_output_directory_path)
		#
		#var recognizer_dialog_directory_path := dialog_directory_path.path_join(recognizer)
		#if !DirAccess.dir_exists_absolute(recognizer_dialog_directory_path):
			#DirAccess.make_dir_recursive_absolute(recognizer_dialog_directory_path)
