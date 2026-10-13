@tool
extends EditorPlugin
var dock: EditorDock
func _enter_tree() -> void:
	add_to_group("recipe_editor_plugin")
	dock = EditorDock.new()
	dock.title = "Recipe"
	dock.layout_key = "godot_recipe_dock"
	dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL
	var label := Label.new()
	label.text = "Scene transaction recipe"
	dock.add_child(label)
	add_dock(dock)
	if "--self-test" in OS.get_cmdline_user_args() and not get_tree().root.has_meta("recipe_self_test"):
		get_tree().root.set_meta("recipe_self_test", true)
		call_deferred("_start_test")
func _start_test() -> void:
	var runner := load("res://example.gd").new() as Node
	get_tree().root.add_child(runner)
func _exit_tree() -> void:
	remove_from_group("recipe_editor_plugin")
	if is_instance_valid(dock):
		remove_dock(dock)
		dock.queue_free()
	dock = null
func add_marker(scene: Node) -> void:
	var marker := Marker3D.new()
	marker.name = "RecipeMarker"
	var history := get_undo_redo()
	history.create_action("Add recipe marker", UndoRedo.MERGE_DISABLE, scene)
	history.add_do_method(scene, "add_child", marker)
	history.add_do_property(marker, "owner", scene)
	history.add_do_reference(marker)
	history.add_undo_method(scene, "remove_child", marker)
	history.commit_action()
