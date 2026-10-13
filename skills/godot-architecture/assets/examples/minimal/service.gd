extends RefCounted
signal changed(value: int)
var value: int = 0
func command(amount: int) -> bool:
	if amount <= 0 or amount > 3:
		return false
	value += amount
	changed.emit(value)
	return true
