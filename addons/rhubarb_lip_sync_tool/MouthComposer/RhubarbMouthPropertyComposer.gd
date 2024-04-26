# TODO: look into this once node properties can be properly stored and selected, see https://github.com/godotengine/godot-proposals/issues/231

#@tool
#extends RhubarbMouthComposer
#class_name RhubarbMouthPropertyComposer
#
#var animated_properties: Array[Dictionary]
#
### The animation library containing the lip sync animations.
#var animation_library: AnimationLibrary
#
#func bake_animation_library() -> void:
	## make sure the input on the node are complete before starting a bake
	#if !validate_inputs():
		#push_error("[Rhubarb Lip Sync Tool]: Failed baking! Not all inputs are set correctly.")
		#return
	#
	## if the library has been baked before, skip the baking and add the library to the animation player if missing.
	#var current_hash := _calculate_hash()
	#if _validate_hash(current_hash):
		#if animation_player.has_animation_library(get_full_library_name()):
			#push_warning("[Rhubarb Lip Sync Tool]: No changes found, aborting bake.")
		#elif animation_player.has_animation_library(_baked_name):
			## TODO: add strategy option on how to handle these cases in editor settings
			#animation_player.rename_animation_library(_baked_name, get_full_library_name())
			#push_warning("[Rhubarb Lip Sync Tool]: Found valid library, renaming '%s' to '%s'." % [_baked_name, get_full_library_name()])
			#_baked_name = get_full_library_name()
			#
			#update_configuration_warnings()
			#EditorInterface.save_scene()
		#else:
			#animation_player.add_animation_library(get_full_library_name(), animation_library)
			#print("[Rhubarb Lip Sync Tool]: Wrote library '%s' to %s" % [get_full_library_name(), animation_player.get_path()])
			#
			#update_configuration_warnings()
		#return
	#
	#var transformed_animated_properties := animated_properties.duplicate()
	#
	#var animation_root := animation_player.get_node(animation_player.root_node)
	#for property in transformed_animated_properties:
		#var property_path := property["property_path"] as NodePath
		#print(property_path)
		#var node_path = NodePath(property_path.get_concatenated_names())
		#var property_node := get_node(node_path)
		#property["property_path"] = NodePath(str(animation_root.get_path_to(property_node)) + ':' + str(property_path.get_subname(0)))
	#
	#animation_library = RhubarbInterface.bake_animation_library(
		#rhubarb_input, 
		#recognizer, 
		#RhubarbInterface.mouth_properties_handler.bind(transformed_animated_properties),
		#RhubarbInterface.reset_properties_handler.bind(transformed_animated_properties),
		#audio_stream_player
	#)
	#
	#_bake_hash = current_hash
	#_baked_name = get_full_library_name()
	#
	#animation_player.add_animation_library(get_full_library_name(), animation_library)
	#
	#print("[Rhubarb Lip Sync Tool]: Wrote library '%s' to %s" % [get_full_library_name(), get_path_to(animation_player)])
	#
	#notify_property_list_changed()
	#update_configuration_warnings()
	#EditorInterface.save_scene()
#
#func clear_animation_library() -> void:
	#_bake_hash = 0
	#_baked_name = ""
	#
	#if animation_player and animation_player.has_animation_library(get_full_library_name()):
		#animation_player.remove_animation_library(get_full_library_name())
	#animation_library = null
	#
	#notify_property_list_changed()
	#update_configuration_warnings()
	#EditorInterface.mark_scene_as_unsaved()
#
#func has_baked_library() -> bool:
	#return animation_library != null
#
#func get_animation_library() -> AnimationLibrary:
	#var current_hash := _calculate_hash()
	#if _validate_hash(current_hash):
		#return animation_library
	#else:
		#return null
#
#func _calculate_hash() -> int:
	#var result := super._calculate_hash()
	#
	#for arg in animated_properties:
		#result += hash(arg["use_textures"])
		#result += hash(arg["property_path"])
	#
	#return result
#
#func validate_inputs(output_messages: PackedStringArray = []) -> bool:
	#var is_valid : bool = true
	#
	#if !super.validate_inputs(output_messages):
		#is_valid = false
	#
	## TODO: add validation code
	#
	#return is_valid
#
##region Inspector Properties
#
#func _get_property_list() -> Array[Dictionary]:
	#var properties : Array[Dictionary] = []
	#
	#properties.append({
		#"name": "animation_property_item_count",
		#"type": TYPE_INT,
		#"usage": PROPERTY_USAGE_ARRAY | PROPERTY_USAGE_DEFAULT,
		#"class_name": "animation_property,animation_property_",
		#"hint": PROPERTY_HINT_NONE
	#})
	#
	#for i in animated_properties.size():
		#properties.append({
			#"name": "animation_property_%d/property_path" % i,
			#"type": TYPE_NODE_PATH,
		#})
		#
		#properties.append({
			#"name": "animation_property_%d/use_textures" % i,
			#"type": TYPE_BOOL
		#})
	#
	#return properties
#
#func _get(property: StringName):
	#if property == "animation_property_item_count":
		#return animated_properties.size()
	#
	#if property.begins_with("animation_property_"):
		#var parts = property.trim_prefix("animation_property_").split("/")
		#var i = parts[0].to_int()
		#return animated_properties[i].get(parts[1])
	#
	#elif property.begins_with("animation_property_"):
		#var parts = property.trim_prefix("animation_property_").split("/")
		#var i = parts[0].to_int()
		#
		#if parts[1] == "use_textures":
			#return animated_properties[i]["use_textures"]
		#
		#elif parts[1] == "property_path":
			#return animated_properties[i]["property_path"]
#
#func _set(property, value):
	##printt("set", property, value)
	#
	#if property == "animation_property_item_count":
		#var old_size := animated_properties.size()
		#animated_properties.resize(value)
		#for i in range(old_size, animated_properties.size()):
			#animated_properties[i] = {
				#"property_path" = NodePath(),
				#"use_textures" = false
			#}
		#notify_property_list_changed()
		#update_configuration_warnings()
	#
	#elif property.begins_with("animation_property_"):
		#var parts = property.trim_prefix("animation_property_").split("/")
		#var i = parts[0].to_int()
		#
		#if parts[1] == "use_textures":
			#if value is bool:
				#animated_properties[i]["use_textures"] = value
		#
		#elif parts[1] == "property_path":
			#if value is String:
				#animated_properties[i]["property_path"] = NodePath(value)
#
##endregion
