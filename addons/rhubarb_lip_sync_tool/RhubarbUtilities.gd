class_name RhubarbUtilities

const MouthShape := preload("res://addons/rhubarb_lip_sync_tool/MouthShape.gd").MouthShape

const settings_group := "Rhubarb"
const known_recognizers_setting: String = "Rhubarb/known_recognizers"
const executable_path_setting: String = "Rhubarb/executable_path"
const run_if_cached_setting: String = "Rhubarb/run_if_cached"

## Validates the current settings to ensure they are set in a valid state.
static func validate_editor_settings() -> bool:
	var is_valid: bool = true
	var editor_settings := EditorInterface.get_editor_settings()
	
	var executable_path := editor_settings.get_setting(executable_path_setting) as String
	
	if !FileAccess.file_exists(executable_path):
		is_valid = false
		push_error("[Rhubarb Lip Sync Tool]: Editor setting '%s' has not been set to a valid file path. Current value: '%s'" % [executable_path_setting, executable_path])
	
	return is_valid

## Converts the shape returned by the Rhubarb sample to a mouth shape enumeration value.
static func mouth_shape_from_sample_shape(shape: String) -> MouthShape:
	assert(shape.length() == 1, "Expected a single character")
	
	match shape:
		'A':
			return MouthShape.MBP
		'B':
			return MouthShape.ETC
		'C':
			return MouthShape.E
		'D':
			return MouthShape.AI
		'E':
			return MouthShape.O
		'F':
			return MouthShape.U
		'G':
			return MouthShape.FV
		'H':
			return MouthShape.L
		'X':
			return MouthShape.REST
		_:
			push_error("Could not find shape for sample '%s', defaulting to MBP" % shape)
			return MouthShape.REST


static func parse_from_tsv(rhubarb_file: String) -> RhubarbData:
	assert(rhubarb_file.get_extension() == "tsv", "exected tsv file, but file is not a tsv file")
	
	var file := FileAccess.open(rhubarb_file, FileAccess.READ)
	if !file:
		push_error("[Rhubarb Lip Sync Tool]: Could not open '%s'. Error: %s" % [rhubarb_file, error_string(FileAccess.get_open_error())])
		return null
	
	var result := RhubarbData.new()
	result.samples = []
	while !file.eof_reached():
		var line := file.get_csv_line('\t')
		
		# skip empty lines
		if line.size() == 1 and line[0].is_empty():
			continue
		
		assert(line.size() == 2, "Expected a line size of 2, but got different size. line content: %s" % line)
		assert(line[0].is_valid_float())
		
		var sample := RhubarbSampleUnit.new()
		sample.sample_time = float(line[0])
		sample.mouth_shape = mouth_shape_from_sample_shape(line[1])
		
		result.samples.append(sample)
	
	return result

static func get_mouth_texture(mouth_shape: MouthShape, mouth_library: MouthLibraryResource) -> Texture2D:
	match mouth_shape:
		MouthShape.MBP:
			return mouth_library.mbp_shape
		MouthShape.ETC:
			return mouth_library.etc_shape
		MouthShape.E:
			return mouth_library.e_shape
		MouthShape.AI:
			return mouth_library.ai_shape
		MouthShape.O:
			return mouth_library.o_shape
		MouthShape.U:
			return mouth_library.u_shape
		MouthShape.FV:
			return mouth_library.fv_shape
		MouthShape.L:
			return mouth_library.l_shape
		_:
			return mouth_library.rest_shape

## Returns the first recognizer inside of the list of known recognizers. If none were found, an empty string is returned.
static func default_recognizer() -> String:
	var recognizers = ProjectSettings.get_setting(RhubarbUtilities.known_recognizers_setting, ["pocketSphynx","phonetic"])
	if recognizers.size() > 0:
		return recognizers[0]
	else:
		return ""
