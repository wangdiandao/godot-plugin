extends Node
@export var observed: int = 0
var service: RefCounted
var configured_before_ready: bool = false
var notifications: int = 0
func configure(dependency: RefCounted) -> bool:
	if dependency == null or not dependency.has_method("command") or not dependency.has_signal("changed"):
		return false
	if service != null and service != dependency and service.changed.is_connected(_on_changed):
		service.changed.disconnect(_on_changed)
	service = dependency
	if not service.changed.is_connected(_on_changed):
		service.changed.connect(_on_changed)
	observed = service.value
	return true
func _ready() -> void:
	configured_before_ready = service != null
func _exit_tree() -> void:
	if service != null and service.changed.is_connected(_on_changed):
		service.changed.disconnect(_on_changed)
func _on_changed(value: int) -> void:
	observed = value
	notifications += 1
