extends Node
## Minimal quantity-by-id inventory for crafting and placeable machines.
## TODO: Persist across sessions, item metadata, equipment slots, UI inventory panel.

signal inventory_changed

var _counts: Dictionary = {} # String -> int


func get_amount(item_id: String) -> int:
	return int(_counts.get(item_id, 0))


func set_amount(item_id: String, amount: int) -> void:
	if amount <= 0:
		_counts.erase(item_id)
	else:
		_counts[item_id] = amount
	inventory_changed.emit()


func add(item_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var n: int = get_amount(item_id)
	_counts[item_id] = n + amount
	inventory_changed.emit()


func try_remove(item_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	var n: int = get_amount(item_id)
	if n < amount:
		return false
	var left: int = n - amount
	if left <= 0:
		_counts.erase(item_id)
	else:
		_counts[item_id] = left
	inventory_changed.emit()
	return true


func can_afford(ingredients: Dictionary) -> bool:
	for k in ingredients.keys():
		var id: String = str(k)
		var need: int = int(ingredients[k])
		if get_amount(id) < need:
			return false
	return true


func try_consume(ingredients: Dictionary) -> bool:
	if not can_afford(ingredients):
		return false
	for k in ingredients.keys():
		var id: String = str(k)
		var need: int = int(ingredients[k])
		if not try_remove(id, need):
			push_error("PlayerInventory: consume inconsistency for %s" % id)
			return false
	return true
