extends Node
const Component = preload("res://component.gd")
const Service = preload("res://service.gd")
signal intent(amount: int)
var dependency: RefCounted
var child_ready_seen: bool = false
func _enter_tree() -> void:
	if dependency == null:
		dependency = Service.new()
	get_node("Observer").configure(dependency)
func _ready() -> void:
	child_ready_seen = get_node("Observer").configured_before_ready
func request(amount: int) -> bool:
	return dependency.command(amount)
func on_intent(amount: int) -> void:
	request(amount)
