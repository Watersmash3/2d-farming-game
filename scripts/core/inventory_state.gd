extends Node

signal inventory_changed
signal selected_item_changed(item_id: String)

const HOTBAR_SIZE: int = 8
const EXTRA_ROWS: int = 3
const COLUMNS: int = 8
const TOTAL_SLOTS: int = HOTBAR_SIZE + (EXTRA_ROWS * COLUMNS) # 32

var selected_item_id: String = ""

# Each slot is:
# {
#   "item_id": String,
#   "count": int
# }
var slots: Array[Dictionary] = []


func _ready() -> void:
	_ensure_slots()


func _ensure_slots() -> void:
	if slots.size() == TOTAL_SLOTS:
		return

	slots.clear()
	for i: int in range(TOTAL_SLOTS):
		slots.append(_make_empty_slot())


func _make_empty_slot() -> Dictionary:
	return {
		"item_id": "",
		"count": 0
	}


func is_valid_slot_index(index: int) -> bool:
	return index >= 0 and index < slots.size()


func get_slot(index: int) -> Dictionary:
	if not is_valid_slot_index(index):
		return _make_empty_slot()
	return slots[index]


func slot_is_empty(index: int) -> bool:
	if not is_valid_slot_index(index):
		return true
	return str(slots[index].get("item_id", "")) == "" or int(slots[index].get("count", 0)) <= 0


func get_count(item_id: String) -> int:
	var total: int = 0
	for slot: Dictionary in slots:
		if str(slot.get("item_id", "")) == item_id:
			total += int(slot.get("count", 0))
	return total


func has_item(item_id: String, amount: int = 1) -> bool:
	return get_count(item_id) >= amount


func can_add(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false

	# Can add if item already exists in any slot or if any empty slot exists.
	for slot: Dictionary in slots:
		if str(slot.get("item_id", "")) == item_id:
			return true
		if str(slot.get("item_id", "")) == "":
			return true

	return false


func add_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false

	_ensure_slots()

	# First try stacking into an existing slot.
	for i: int in range(slots.size()):
		if str(slots[i].get("item_id", "")) == item_id:
			slots[i]["count"] = int(slots[i]["count"]) + amount
			inventory_changed.emit()
			return true

	# Otherwise put in first empty slot.
	for i: int in range(slots.size()):
		if slot_is_empty(i):
			slots[i]["item_id"] = item_id
			slots[i]["count"] = amount
			inventory_changed.emit()
			return true

	return false


func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or not has_item(item_id, amount):
		return false

	var remaining: int = amount

	for i: int in range(slots.size()):
		if remaining <= 0:
			break

		if str(slots[i].get("item_id", "")) != item_id:
			continue

		var slot_count: int = int(slots[i].get("count", 0))
		var take: int = min(slot_count, remaining)
		slot_count -= take
		remaining -= take

		if slot_count <= 0:
			slots[i] = _make_empty_slot()
		else:
			slots[i]["count"] = slot_count

	# Clear selected item if it no longer exists.
	if selected_item_id != "" and get_count(selected_item_id) <= 0:
		selected_item_id = ""
		selected_item_changed.emit(selected_item_id)

	inventory_changed.emit()
	return true


func move_slot(from_index: int, to_index: int) -> bool:
	if not is_valid_slot_index(from_index) or not is_valid_slot_index(to_index):
		return false
	if from_index == to_index:
		return false
	if slot_is_empty(from_index):
		return false

	# If target is empty, move.
	if slot_is_empty(to_index):
		slots[to_index] = {
			"item_id": str(slots[from_index]["item_id"]),
			"count": int(slots[from_index]["count"])
		}
		slots[from_index] = _make_empty_slot()
		_fix_selected_item_after_move()
		inventory_changed.emit()
		return true

	# If same item, stack.
	if str(slots[from_index]["item_id"]) == str(slots[to_index]["item_id"]):
		slots[to_index]["count"] = int(slots[to_index]["count"]) + int(slots[from_index]["count"])
		slots[from_index] = _make_empty_slot()
		_fix_selected_item_after_move()
		inventory_changed.emit()
		return true

	# Otherwise swap.
	var temp: Dictionary = {
		"item_id": str(slots[to_index]["item_id"]),
		"count": int(slots[to_index]["count"])
	}
	slots[to_index] = {
		"item_id": str(slots[from_index]["item_id"]),
		"count": int(slots[from_index]["count"])
	}
	slots[from_index] = temp

	_fix_selected_item_after_move()
	inventory_changed.emit()
	return true


func _fix_selected_item_after_move() -> void:
	if selected_item_id == "":
		return

	if get_count(selected_item_id) <= 0:
		selected_item_id = ""
		selected_item_changed.emit(selected_item_id)


func set_selected_item(item_id: String) -> void:
	if selected_item_id == item_id:
		return
	selected_item_id = item_id
	selected_item_changed.emit(selected_item_id)
