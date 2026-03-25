extends Node2D
class_name AutomationMachine

## Base for placeable daily automation. TODO: add power/fuel hooks, save state, and machine upgrades.

var grid_cell: Vector2i = Vector2i.ZERO
var _farming: FarmingSystem


func setup(farming: FarmingSystem, cell: Vector2i) -> void:
	_farming = farming
	grid_cell = cell


func get_farming() -> FarmingSystem:
	return _farming


func on_new_day(_new_day: int, _old_day: int) -> void:
	push_warning("AutomationMachine: override on_new_day() in %s" % name)


func _exit_tree() -> void:
	AutomationManager.unregister_machine(self)
