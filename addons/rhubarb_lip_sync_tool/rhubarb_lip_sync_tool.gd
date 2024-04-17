@tool
extends EditorPlugin

const rhubarb_settings_group := "Rhubarb"
const rhubarb_executable_path_setting: String = "Rhubarb/executable path"
const RhubarbExport := preload("res://addons/rhubarb_lip_sync_tool/RhubarbExport.gd")

var export_plugin: EditorExportPlugin

func _enter_tree() -> void:
	print("Rhubarb plugin entered tree")
	validate_editor_settings()
	
	export_plugin = RhubarbExport.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null

func _enable_plugin() -> void:
	# Initialization of the plugin goes here.
	var editor_settings := EditorInterface.get_editor_settings()
	
#region Executable Path Setting
	if !editor_settings.has_setting(rhubarb_executable_path_setting):
		editor_settings.set_setting(rhubarb_executable_path_setting, "")
	editor_settings.add_property_info(
		{
			name=rhubarb_executable_path_setting,
			type=TYPE_STRING,
			hint=PROPERTY_HINT_GLOBAL_FILE,
			hint_string="*; All Items"
		}
	)
	editor_settings.set_initial_value(rhubarb_executable_path_setting, "", false)
#endregion
	
	print("rhubal plugin enabled")

func _disable_plugin() -> void:
	var editor_settings := EditorInterface.get_editor_settings()
	
	editor_settings.erase(rhubarb_executable_path_setting)
	
	print("rhubal plugin disabled")

static func validate_editor_settings() -> bool:
	var is_valid: bool = true
	var editor_settings := EditorInterface.get_editor_settings()
	
	var executable_path := editor_settings.get_setting(rhubarb_executable_path_setting) as String
	
	if !FileAccess.file_exists(executable_path):
		is_valid = false
		push_error("[Rhubarb Lip Sync Tool]: Editor setting '%s' has not been set to a valid file path. Current value: '%s'" % [rhubarb_executable_path_setting, executable_path])
	
	return is_valid
