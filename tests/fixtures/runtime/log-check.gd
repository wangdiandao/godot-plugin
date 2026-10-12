extends SceneTree
const Common = preload("../../../shared/scripts/common.gd")
func _initialize() -> void:
	var json_line := 'GODOT_PLUGIN_RESULT:{"status":"passed","detail":"ERROR: expected failure"}'
	var actual := "ERROR: engine failure\nSCRIPT ERROR: parse failure\nSHADER ERROR: compile failure"
	var result := Common.report("log_parser")
	Common.check(result, "quoted_error_is_data", Common.log_errors(json_line).is_empty())
	Common.check(result, "real_errors_detected", Common.log_errors(actual).size() == 3)
	Common.finish(self, result)
