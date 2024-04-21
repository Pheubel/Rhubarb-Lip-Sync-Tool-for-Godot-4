@tool
extends EditorPlugin

const RhubarbExport := preload("res://addons/rhubarb_lip_sync_tool/RhubarbExport.gd")
const RhubarbMouthComposerInspector := preload("res://addons/rhubarb_lip_sync_tool/MouthComposer2D/RhubarbMouthComposerInspector.gd")

var export_plugin: EditorExportPlugin
var composer_inspector_plugin: EditorInspectorPlugin

func _enter_tree() -> void:
	print("Rhubarb plugin entered tree")
	
#region Editor Settings
	var editor_settings := EditorInterface.get_editor_settings()
	
	if !editor_settings.has_setting(RhubarbUtilities.executable_path_setting):
		editor_settings.set_setting(RhubarbUtilities.executable_path_setting, "")
	editor_settings.add_property_info(
		{
			name=RhubarbUtilities.executable_path_setting,
			type=TYPE_STRING,
			hint=PROPERTY_HINT_GLOBAL_FILE,
			hint_string="*.exe; Executable files"
		}
	)
	editor_settings.set_initial_value(RhubarbUtilities.executable_path_setting, "", false)
	
	if !editor_settings.has_setting(RhubarbUtilities.run_if_cached_setting):
		editor_settings.set_setting(RhubarbUtilities.run_if_cached_setting, false)
	editor_settings.add_property_info(
		{
			name=RhubarbUtilities.run_if_cached_setting,
			type=TYPE_BOOL
		}
	)
	editor_settings.set_initial_value(RhubarbUtilities.run_if_cached_setting, false, false)
#endregion
	
	if !ProjectSettings.has_setting(RhubarbUtilities.known_recognizers_setting):
		ProjectSettings.set_setting(RhubarbUtilities.known_recognizers_setting, PackedStringArray(["pocketSphinx", "phonetic"]))
	ProjectSettings.add_property_info({
		name=RhubarbUtilities.known_recognizers_setting,
		type=TYPE_PACKED_STRING_ARRAY,
		hint=PROPERTY_HINT_TYPE_STRING,
		hint_string= "String"
	})
	ProjectSettings.set_initial_value(RhubarbUtilities.known_recognizers_setting, PackedStringArray(["pocketSphinx", "phonetic"]))
	ProjectSettings.set_as_basic(RhubarbUtilities.known_recognizers_setting, true)
	
	ProjectSettings.save()
	
	RhubarbUtilities.validate_editor_settings()
	
	export_plugin = RhubarbExport.new()
	add_export_plugin(export_plugin)
	
	composer_inspector_plugin = RhubarbMouthComposerInspector.new()
	add_inspector_plugin(composer_inspector_plugin)
	
	add_autoload_singleton("RhubarbInterface", "res://addons/rhubarb_lip_sync_tool/RhubarbInterface.gd")
	
	RhubarbInterface.ensure_directories_exist()

func _exit_tree() -> void:
	remove_inspector_plugin(composer_inspector_plugin)
	remove_export_plugin(export_plugin)
	remove_autoload_singleton("RhubarbInterface")
	
	export_plugin = null

func _enable_plugin() -> void:
	print("rhubal plugin enabled")

func _disable_plugin() -> void:
	var editor_settings := EditorInterface.get_editor_settings()
	
	editor_settings.erase(RhubarbUtilities.executable_path_setting)
	
	print("rhubal plugin disabled")
