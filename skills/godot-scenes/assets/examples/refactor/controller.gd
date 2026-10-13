extends Node2D
@export var target_path: NodePath
var activations := 0
func activate() -> void:
	var target := get_node_or_null(target_path) as Node2D
	if target == null:
		return
	activations += 1
	target.hide()
