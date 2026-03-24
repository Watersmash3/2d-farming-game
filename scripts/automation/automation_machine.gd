extends Node2D
class_name AutomationMachine
## Base for placeable automation. Registered with AutomationManager; ticked after farming day roll.
## TODO: Power/fuel, upgrades, save/load instance state.

@export var grid_cell: Vector2i = Vector2i.ZERO


func on_daily_tick(farming: FarmingSystem, new_day: int) -> void:
	push_warning("AutomationMachine: override on_daily_tick (%s)" % name)
