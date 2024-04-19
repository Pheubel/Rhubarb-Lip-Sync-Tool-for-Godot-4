@tool
extends EditorPlugin
class_name RhubarbTool

#const RhubarbUtilities := preload("res://addons/rhubarb_lip_sync_tool/RhubarbUtilities.gd")
const RhubarbExport := preload("res://addons/rhubarb_lip_sync_tool/RhubarbExport.gd")

const FAILURE_CODE := -1

var export_plugin: EditorExportPlugin

func _enter_tree() -> void:
	print("Rhubarb plugin entered tree")
	
	var editor_settings := EditorInterface.get_editor_settings()
	
#region Executable Path Setting
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
#endregion
	
	RhubarbUtilities.validate_editor_settings()
	
	export_plugin = RhubarbExport.new()
	add_export_plugin(export_plugin)
	
	add_autoload_singleton("RhubarbInterface", "res://addons/rhubarb_lip_sync_tool/RhubarbInterface.gd")

func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	remove_autoload_singleton("RhubarbInterface")
	
	export_plugin = null

func _enable_plugin() -> void:
	print("rhubal plugin enabled")

func _disable_plugin() -> void:
	var editor_settings := EditorInterface.get_editor_settings()
	
	editor_settings.erase(RhubarbUtilities.executable_path_setting)
	
	print("rhubal plugin disabled")
