extends Node

signal inventory_changed
signal selected_item_changed(item_id: String)

var inventory: Dictionary = {}  # id -> count
var selected_item_id: String = ""
var max_slots := 24  # optional, simple cap (number of unique items)

func can_add(item_id: String, amount: int = 1) -> bool:
	if amount <= 0: return false
	# if item already exists, always can add
	if inventory.has(item_id): return true
	# new item would consume a slot
	return inventory.size() < max_slots

func add_item(item_id: String, amount: int = 1) -> bool:
	if not can_add(item_id, amount):
		return false
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	inventory_changed.emit()
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return int(inventory.get(item_id, 0)) >= amount

func remove_item(item_id: String, amount: int = 1) -> bool:
	if not has_item(item_id, amount): return false
	var new_amt := int(inventory[item_id]) - amount
	if new_amt <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = new_amt
	inventory_changed.emit()
	return true

func get_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


func set_selected_item(item_id: String) -> void:
	if selected_item_id == item_id:
		return
	selected_item_id = item_id
	selected_item_changed.emit(selected_item_id)
