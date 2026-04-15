extends AutomationMachine
class_name AutoHarvester

## Harvests mature crops in neighboring cells each day.

@onready var _visual: Node2D = $VisualRoot


func _ready() -> void:
	if _farming != null:
		global_position = _farming.get_cell_world_center(grid_cell)
	AutomationManager.register_machine(self, grid_cell)
	if _visual:
		for c: Node in _visual.get_children():
			if c is Sprite2D:
				(c as Sprite2D).texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func upgrade_cost() -> Dictionary:
	return {"stone": 5, "wood": 4}


func on_new_day(new_day: int, _old_day: int) -> void:
	if _farming == null:
		return

	var harvested: int = 0
	for cell: Vector2i in get_target_cells():
		if _farming.is_cell_mature(cell):
			_farming.harvest(cell)
			harvested += 1

	if harvested > 0:
		print("[AutoHarvester] Day %d: harvested %d crops" % [new_day, harvested])
		if _visual:
			var tw := create_tween()
			tw.tween_property(_visual, "modulate", Color(1.0, 0.9, 0.3, 1.0), 0.08)
			tw.tween_property(_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
