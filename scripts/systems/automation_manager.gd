extends Node

## Tracks placed automation anchors and runs daily behavior after the farming day tick.
## Deferred connection: runs after FarmingSystem clears water / advances crops on the same signal.

var _machines: Array[AutomationMachine] = []
var _occupied_cells: Dictionary = {}  # Vector2i -> AutomationMachine


func _ready() -> void:
	TimeSystem.day_advanced.connect(_on_day_advanced, CONNECT_DEFERRED)


func _on_day_advanced(new_day: int, old_day: int) -> void:
	for m: AutomationMachine in _machines.duplicate():
		if is_instance_valid(m):
			m.on_new_day(new_day, old_day)


func register_machine(machine: AutomationMachine, cell: Vector2i) -> void:
	if _occupied_cells.has(cell):
		push_warning("AutomationManager: cell already occupied %s" % str(cell))
		return
	_machines.append(machine)
	_occupied_cells[cell] = machine


func unregister_machine(machine: AutomationMachine) -> void:
	_machines.erase(machine)
	var to_erase: Array[Vector2i] = []
	for c: Variant in _occupied_cells.keys():
		if _occupied_cells[c] == machine:
			to_erase.append(c)
	for c: Vector2i in to_erase:
		_occupied_cells.erase(c)


func has_machine_at(cell: Vector2i) -> bool:
	return _occupied_cells.has(cell)

## Returns the machine at the given cell, or null if none.
func get_machine_at(cell: Vector2i) -> AutomationMachine:
	if not _occupied_cells.has(cell):
		return null
	return _occupied_cells[cell] as AutomationMachine


func can_place_machine_at(cell: Vector2i, farming: FarmingSystem) -> bool:
	if farming == null:
		return false
	if not farming.is_valid_machine_cell(cell):
		return false
	if has_machine_at(cell):
		return false
	return true
