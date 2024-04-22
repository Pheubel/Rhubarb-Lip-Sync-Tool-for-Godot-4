extends EditorInspectorPlugin



func _can_handle(object: Object) -> bool:
	return object is RhubarbMouthComposer

func _parse_begin(object: Object) -> void:
	var mouth_composer := object as RhubarbMouthComposer
	
	var h_box := HBoxContainer.new()
	h_box.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	
	var bake_button := Button.new()
	bake_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bake_button.text = "Bake library"
	bake_button.pressed.connect(_on_bake_pressed.bind(mouth_composer))
	
	var clear_button := Button.new()
	clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_button.text = "Clear library"
	clear_button.disabled = !mouth_composer.has_baked_library()
	clear_button.pressed.connect(_on_clear_pressed.bind(mouth_composer))
	
	h_box.add_child(bake_button)
	h_box.add_child(clear_button)
	
	add_custom_control(h_box)

func _on_bake_pressed(mouth_composer: RhubarbMouthComposer) -> void:
	mouth_composer.bake_animation_library()

func _on_clear_pressed(mouth_composer: RhubarbMouthComposer) -> void:
	mouth_composer.clear_animation_library()
