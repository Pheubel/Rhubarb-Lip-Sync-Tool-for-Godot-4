@tool
extends RhubarbMouthComposer
class_name RhubarbMouthSpriteComposer

## The sprite that will be animated to the fitting mouth shapes.
@export_node_path("Sprite2D","Sprite3D") var mouth_sprite: NodePath:
	set(value):
		if mouth_sprite != value:
			mouth_sprite = value
			update_configuration_warnings()

## The animation library containing the lip sync animations.
var animation_library: AnimationLibrary

func bake_animation_library() -> void:
	# make sure the input on the node are complete before starting a bake
	if !validate_inputs():
		push_error("[Rhubarb Lip Sync Tool]: Failed baking! Not all inputs are set correctly.")
		return
	
	# if the library has been baked before, skip the baking and add the library to the animation player if missing.
	var current_hash := _calculate_hash()
	if _validate_hash(current_hash):
		if animation_player.has_animation_library(get_full_library_name()):
			push_warning("[Rhubarb Lip Sync Tool]: No changes found, aborting bake.")
		elif animation_player.has_animation_library(_baked_name):
			# TODO: add strategy option on how to handle these cases in editor settings
			animation_player.rename_animation_library(_baked_name, get_full_library_name())
			push_warning("[Rhubarb Lip Sync Tool]: Found valid library, renaming '%s' to '%s'." % [_baked_name, get_full_library_name()])
			_baked_name = get_full_library_name()
			
			update_configuration_warnings()
			EditorInterface.save_scene()
		else:
			animation_player.add_animation_library(get_full_library_name(), animation_library)
			print("[Rhubarb Lip Sync Tool]: Wrote library '%s' to %s" % [get_full_library_name(), animation_player.get_path()])
			
			update_configuration_warnings()
		return
	
	animation_library = RhubarbInterface.bake_animation_library_from_nodes(rhubarb_input, recognizer, animation_player, get_mouth_sprite_node(), get_audio_player_node())
	_bake_hash = current_hash
	_baked_name = get_full_library_name()
	
	animation_player.add_animation_library(get_full_library_name(), animation_library)
	
	print("[Rhubarb Lip Sync Tool]: Wrote library '%s' to %s" % [get_full_library_name(), get_path_to(animation_player)])
	
	notify_property_list_changed()
	update_configuration_warnings()
	EditorInterface.save_scene()

func clear_animation_library() -> void:
	_bake_hash = 0
	_baked_name = ""
	
	if animation_player and animation_player.has_animation_library(get_full_library_name()):
		animation_player.remove_animation_library(get_full_library_name())
	animation_library = null
	
	notify_property_list_changed()
	update_configuration_warnings()
	EditorInterface.mark_scene_as_unsaved()

func has_baked_library() -> bool:
	return animation_library != null 

func get_animation_library() -> AnimationLibrary:
	var current_hash := _calculate_hash()
	if _validate_hash(current_hash):
		return animation_library
	else:
		return null

func get_mouth_sprite_node() -> Node:
	if mouth_sprite.is_empty():
		return null
	
	return get_node(mouth_sprite)

#region Inspector Properties

func _get_property_list() -> Array[Dictionary]:
	#var properties := super._get_property_list()
	var properties : Array[Dictionary] = []
	
	properties.append({
		"name": "animation_library",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_STORAGE,
		"class_name": &"AnimationLibrary"
	})
	
	return properties

func _property_get_revert(property: StringName):
	if property == "mouth_sprite":
		return NodePath()
	
	return super._property_get_revert(property)

func _calculate_hash() -> int:
	var result := super._calculate_hash()
	
	result += hash(mouth_sprite)
	
	return result

func validate_inputs(output_messages: PackedStringArray = []) -> bool:
	var is_valid : bool = true
	
	var mouth_sprite := get_mouth_sprite_node()
	if !mouth_sprite:
		is_valid = false
		output_messages.append("Mouth Sprite has not been set.")
	else:
		var is_sprite_node := mouth_sprite is Sprite2D or mouth_sprite is Sprite3D
		if !is_sprite_node:
			is_valid = false
			output_messages.append("Node path '%s' does not actually go to a sprite node." % mouth_sprite)
	
	if !super.validate_inputs(output_messages):
		is_valid = false
	
	return is_valid

#endregion
