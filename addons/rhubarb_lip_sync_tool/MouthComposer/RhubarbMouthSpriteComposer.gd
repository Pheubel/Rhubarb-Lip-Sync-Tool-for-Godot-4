@tool
extends RhubarbMouthComposer
class_name RhubarbMouthSpriteComposer

const library_name_prefix := "RLS"

## The optional name for the animation library after baking has finished.[br]
## The name will always be prepended with [b]"RLS"[/b] seperated by an underscore, even if no name was given.[br]
## Setting the library name to "english" will result in naming it "RLS_english".
@export var output_library_name: String:
	set(new_name):
		if animation_player and animation_library:
			if animation_player.has_animation_library(get_full_library_name()):
				animation_player.rename_animation_library(get_full_library_name(), library_name_prefix + new_name)
		
		output_library_name = new_name
		update_configuration_warnings()

## The sprite that will be animated to the fitting mouth shapes.
var mouth_sprite_path: NodePath

## The animation player that will have the lip animations baked to.
@export var animation_player: AnimationPlayer:
	set(value):
		if animation_player != value:
			if animation_player and animation_player.has_animation_library(get_full_library_name()):
				animation_player.remove_animation_library(get_full_library_name())
			animation_player = value
			update_configuration_warnings()

## The animation library containing the lip sync animations.
var animation_library: AnimationLibrary

### The audio stream player that will play the audio stream. If left empty, it will to be included in the animation.
var audio_stream_player_path: NodePath

## A dictionary of input for creating an animation library with Rhubarb.[br]
## The keys are [b]animation_name[/b], [b]audio_stream[/b], [b]dialog_text[/b] and [b]mouth_library[/b].
var rhubarb_input: Array[Dictionary]

## The recognizer that will be used to recognize mouth shapes in the audio samples.
var recognizer: String = RhubarbUtilities.default_recognizer()

## The combined hash of all the components used to bake the library. Used to determine if the data in the animation library is stale.
var _bake_hash: int

func bake_animation_library() -> void:
	# make sure the input on the node are complete before starting a bake
	if !_validate_inputs([]):
		push_error("[Rhubarb Lip Sync Tool]: Failed baking! Not all inputs are set correctly.")
		return
	
	# if the library has been baked before, skip the baking and add the library to the animation player if missing.
	var current_hash := _calculate_hash()
	if _validate_hash(current_hash):
		if animation_player.has_animation_library(get_full_library_name()):
			push_warning("[Rhubarb Lip Sync Tool]: No changes found, aborting bake.")
		else:
			animation_player.add_animation_library(get_full_library_name(), animation_library)
			print("[Rhubarb Lip Sync Tool]: Wrote library '%s' to %s" % [get_full_library_name(), animation_player.get_path()])
			update_configuration_warnings()
		return
	
	animation_library = RhubarbInterface.bake_animation_library_from_nodes(rhubarb_input, recognizer, animation_player, get_mouth_sprite_node(), get_audio_player_node())
	_bake_hash = current_hash
	
	animation_player.add_animation_library(get_full_library_name(), animation_library)
	
	print("[Rhubarb Lip Sync Tool]: Wrote library '%s' to %s" % [get_full_library_name(), get_path_to(animation_player)])
	
	notify_property_list_changed()
	update_configuration_warnings()

func clear_animation_library() -> void:
	_bake_hash = 0
	if animation_player and animation_player.has_animation_library(get_full_library_name()):
		animation_player.remove_animation_library(get_full_library_name())
	animation_library = null
	
	notify_property_list_changed()
	update_configuration_warnings()

func get_full_library_name() -> String:
	var trimmed_name := output_library_name.rstrip(' ')
	if trimmed_name.is_empty():
		return library_name_prefix
	else:
		return library_name_prefix + '_' + output_library_name

func has_baked_library() -> bool:
	return animation_library != null 

func get_animation_library() -> AnimationLibrary:
	var current_hash := _calculate_hash()
	if _validate_hash(current_hash):
		return animation_library
	else:
		return null

func get_mouth_sprite_node() -> Node:
	if mouth_sprite_path.is_empty():
		return null
	
	return get_node(mouth_sprite_path)

func get_audio_player_node() -> Node:
	if audio_stream_player_path.is_empty():
		return null
	
	return get_node(audio_stream_player_path)

#region Inspector Properties

func _get_property_list() -> Array[Dictionary]:
	var properties : Array[Dictionary] = []
	properties.append({
		"name": "mouth_sprite",
		"type": TYPE_NODE_PATH,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_NODE_PATH_VALID_TYPES,
		"hint_string": "Sprite2D,Sprite3D"
	})
	
	properties.append({
		"name": "audio_stream_player",
		"type": TYPE_NODE_PATH,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_NODE_PATH_VALID_TYPES,
		"hint_string": "AudioStreamPlayer,AudioStreamPlayer2D,AudioStreamPlayer3D"
	})
	
	properties.append({
		"name": "animation_library",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_STORAGE,
		"class_name": &"AnimationLibrary"
	})
	
	properties.append({
		"name": "_bake_hash",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_STORAGE
	})
	
	properties.append({
		"name": "recognizer",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(ProjectSettings.get_setting(RhubarbUtilities.known_recognizers_setting, ["pocketSphynx","phonetic"]))
	})
	
	properties.append({
		"name": "item_count",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_ARRAY | PROPERTY_USAGE_DEFAULT,
		"class_name": "rhubarb_input,rhubarb_input_",
		"hint": PROPERTY_HINT_NONE
	})
	
	for i in rhubarb_input.size():
		properties.append({
			"name": "rhubarb_input_%d/animation_name" % i,
			"type": TYPE_STRING
		})
		
		properties.append({
			"name": "rhubarb_input_%d/audio_stream" % i,
			"type": TYPE_OBJECT,
			"hint_string": "AudioStream",
			"class_name": &"AudioStream",
			"hint": PROPERTY_HINT_RESOURCE_TYPE
		})
		
		properties.append({
			"name": "rhubarb_input_%d/dialog_text" % i,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_MULTILINE_TEXT
		})
		
		properties.append({
			"name": "rhubarb_input_%d/mouth_library" % i,
			"type": TYPE_OBJECT,
			"hint_string": "MouthSpriteLibrary",
			"class_name": &"MouthSpriteLibrary",
			"hint": PROPERTY_HINT_RESOURCE_TYPE
		})
	
	return properties

func _get(property):
	if property == "item_count":
		return rhubarb_input.size()
	
	if property == "audio_stream_player":
		return audio_stream_player_path
	
	if property == "recognizer":
		return recognizer
	
	if property == "_bake_hash":
		return _bake_hash
	
	if property == "mouth_sprite":
		return mouth_sprite_path
	
	if property.begins_with("rhubarb_input_"):
		var parts = property.trim_prefix("rhubarb_input_").split("/")
		var i = parts[0].to_int()
		return rhubarb_input[i].get(parts[1])

func _set(property, value):
	if property == "audio_stream_player":
		if value is NodePath and !value.is_empty():
			audio_stream_player_path = value
		else:
			audio_stream_player_path = NodePath()
		update_configuration_warnings()
	
	if property == "mouth_sprite":
		if value is NodePath and !value.is_empty():
			mouth_sprite_path = value
		else:
			mouth_sprite_path = NodePath()
		update_configuration_warnings()
	
	if property == "recognizer":
		if value is String:
			recognizer = value
			update_configuration_warnings()
	
	if property == "_bake_hash":
		if value is int:
			_bake_hash = value
			update_configuration_warnings()
	
	if property == "item_count":
		var old_size := rhubarb_input.size()
		rhubarb_input.resize(value)
		for i in range(old_size, rhubarb_input.size()):
			rhubarb_input[i] = {
				"animation_name" = "",
				"audio_stream" = null,
				"dialog_text" = "",
				"mouth_library" = null
			}
		notify_property_list_changed()
		update_configuration_warnings()
	
	elif property.begins_with("rhubarb_input_"):
		var parts = property.trim_prefix("rhubarb_input_").split("/")
		var i = parts[0].to_int()
		
		if parts[1] == "animation_name":
			if value is String:
				rhubarb_input[i]["animation_name"] = value
		
		elif parts[1] == "audio_stream":
			if value is AudioStream:
				rhubarb_input[i]["audio_stream"] = value
			else:
				rhubarb_input[i]["audio_stream"] = null
			update_configuration_warnings()
		
		elif parts[1] == "dialog_text":
			if value is String:
				rhubarb_input[i]["dialog_text"] = value
		
		elif parts[1] == "mouth_library":
			if value is MouthSpriteLibrary:
				rhubarb_input[i]["mouth_library"] = value
			else:
				rhubarb_input[i]["mouth_library"] = null
			update_configuration_warnings()

func _property_can_revert(property: StringName):
	if property == "audio_stream_player":
		return true
	
	if property == "mouth_sprite":
		return true
	
	if property == "recognizer":
		return true
	
	if property.begins_with("rhubarb_input_"):
		var parts = property.trim_prefix("rhubarb_input_").split("/")
		if parts[1] == "animation_name":
			return true
		if parts[1] == "audio_stream":
			return true
		if parts[1] == "dialog_text":
			return true
		if parts[1] == "mouth_library":
			return true
	
	return true

func _property_get_revert(property: StringName):
	if property == "output_library_name":
		return ""
	
	if property == "audio_stream_player":
		return NodePath()
	
	if property == "mouth_sprite":
		return NodePath()
	
	if property == "recognizer":
		return RhubarbUtilities.default_recognizer()
	
	if property.begins_with("rhubarb_input_"):
		var parts = property.trim_prefix("rhubarb_input_").split("/")
		if parts[1] == "animation_name":
			return ""
		if parts[1] == "audio_stream":
			return null
		if parts[1] == "dialog_text":
			return ""
		if parts[1] == "mouth_library":
			return null

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	
	if _validate_inputs(warnings):
		if animation_library:
			if !animation_player.has_animation_library(get_full_library_name()):
				warnings.append("Cannot find animation library in the Animation Player, please bake again.")
			else: 
				var current_hash := _calculate_hash()
				if !_validate_hash(current_hash):
					warnings.append("Animation library contains stale data, please bake again.")
		else:
			warnings.append("Animation library has not been baked yet.")
	
	return warnings

func _validate_hash(hash: int) -> bool:
	return hash == _bake_hash

func _calculate_hash() -> int:
	var result: int = 0
	
	result += hash(mouth_sprite_path)
	result += hash(audio_stream_player_path)
	result += hash(recognizer)
	
	for input in rhubarb_input:
		result += hash(input.get("animation_name", ""))
		
		var audio_stream := input.get("audio_stream") as AudioStream
		if audio_stream:
			result += hash(audio_stream.get_rid())
		
		result += hash(input.get("dialog_text", ""))
		
		var mouth_library := input.get("mouth_library") as MouthSpriteLibrary
		if mouth_library:
			result += hash(mouth_library.get_rid())
	
	return result

func _validate_inputs(output_messages: PackedStringArray) -> bool:
	var is_valid : bool = true
	
	var mouth_sprite := get_mouth_sprite_node()
	if !mouth_sprite:
		is_valid = false
		output_messages.append("Mouth Sprite has not been set.")
	else:
		var is_sprite_node := mouth_sprite is Sprite2D or mouth_sprite is Sprite3D
		if !is_sprite_node:
			is_valid = false
			output_messages.append("Node path '%s' does not actually go to a sprite node." % mouth_sprite_path)
	
	if animation_player == null:
		is_valid = false
		output_messages.append("Animation Player has not been set.")
	
	if recognizer.is_empty():
		is_valid = false
		output_messages.append("No recognizer has been set.")
	
	var audio_player_node := get_audio_player_node()
	if audio_player_node:
		var is_audio_player_node = audio_player_node is AudioStreamPlayer or audio_player_node is AudioStreamPlayer2D or audio_player_node is AudioStreamPlayer3D
		if !is_audio_player_node:
			is_valid = false
			output_messages.append("Node path '%s' does not actually go to an audio stream player node." % audio_stream_player_path)
	
	elif !ProjectSettings.get_setting(RhubarbUtilities.known_recognizers_setting,[]).has(recognizer):
		is_valid = false
		output_messages.append("Recognizer '%s' is not known to the project." % recognizer)
	
	for index in rhubarb_input.size():
		var message: String = ""
		if !rhubarb_input[index].get("audio_stream"):
			is_valid = false
			message += "rhubarb_input[%d] has no audio stream set." % index
		
		if !rhubarb_input[index].get("mouth_library"):
			is_valid = false
			if !message.is_empty():
				message += '\n'
			message +="rhubarb_input[%d] has no mouth library set." % index
		
		if !message.is_empty():
			output_messages.append(message)
	
	return is_valid

#endregion
