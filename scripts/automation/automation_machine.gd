extends Node2D
class_name AutomationMachine

## Base for placeable daily automation.

var grid_cell: Vector2i = Vector2i.ZERO
var _farming: FarmingSystem

var upgrade_level: int = 0
const MAX_UPGRADE_LEVEL: int = 2

## Cost to upgrade from current level to the next (override per machine if needed).
func upgrade_cost() -> Dictionary:
	return {"stone": 5, "fiber": 3}

func can_upgrade() -> bool:
	return upgrade_level < MAX_UPGRADE_LEVEL

## Checks inventory, deducts cost, and increments upgrade_level.
## Returns true on success.
func try_upgrade() -> bool:
	if not can_upgrade():
		print("[Upgrade] %s is already at max level (%d)" % [name, MAX_UPGRADE_LEVEL])
		return false
	var cost := upgrade_cost()
	for item_id: String in cost:
		if not InventoryState.has_item(item_id, cost[item_id]):
			print("[Upgrade] Not enough %s (need %d)" % [item_id, cost[item_id]])
			return false
	for item_id: String in cost:
		InventoryState.remove_item(item_id, cost[item_id])
	upgrade_level += 1
	print("[Upgrade] %s upgraded to level %d" % [name, upgrade_level])
	return true

## Returns the set of cells this machine acts on, based on upgrade_level.
## Subclasses may override; default is orthogonal + diagonal expansion by level.
func get_target_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	match upgrade_level:
		0:
			# 4 orthogonal
			for off: Vector2i in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				cells.append(grid_cell + off)
		1:
			# 8 surrounding (Moore radius 1)
			for dx: int in [-1, 0, 1]:
				for dy: int in [-1, 0, 1]:
					if dx != 0 or dy != 0:
						cells.append(grid_cell + Vector2i(dx, dy))
		2:
			# Manhattan distance ≤ 2
			for dx: int in range(-2, 3):
				for dy: int in range(-2, 3):
					if (absi(dx) + absi(dy)) <= 2 and (dx != 0 or dy != 0):
						cells.append(grid_cell + Vector2i(dx, dy))
	return cells


func setup(farming: FarmingSystem, cell: Vector2i) -> void:
	_farming = farming
	grid_cell = cell


func get_farming() -> FarmingSystem:
	return _farming


func on_new_day(_new_day: int, _old_day: int) -> void:
	push_warning("AutomationMachine: override on_new_day() in %s" % name)


func _exit_tree() -> void:
	AutomationManager.unregister_machine(self)
