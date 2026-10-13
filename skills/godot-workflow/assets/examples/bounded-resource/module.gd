extends Control
class Charges extends RefCounted:
	signal changed(value: int)
	var value := 2
	func consume() -> bool:
		if value <= 0:
			return false
		value -= 1
		changed.emit(value)
		return true
var service: Charges
var charges := 0
var accepted := 0
var rejected := 0
var hud: Label
var button: Button
func _ready() -> void:
	var column := VBoxContainer.new()
	add_child(column)
	hud = Label.new()
	column.add_child(hud)
	button = Button.new()
	button.text = "Use charge"
	column.add_child(button)
	button.pressed.connect(_use_charge)
func reset() -> void:
	if service != null and service.changed.is_connected(_display):
		service.changed.disconnect(_display)
	service = Charges.new()
	service.changed.connect(_display)
	accepted = 0
	rejected = 0
	_display(service.value)
func _display(value: int) -> void:
	charges = value
	hud.text = "Charges: " + str(value)
func _use_charge() -> void:
	if service.consume():
		accepted += 1
	else:
		rejected += 1
func _exit_tree() -> void:
	if service != null and service.changed.is_connected(_display):
		service.changed.disconnect(_display)
