extends AutomationMachine
class_name AutoTiller

## Tills untilled neighboring cells each day.

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
	return {"stone": 6, "wood": 3}


func on_new_day(new_day: int, _old_day: int) -> void:
	if _farming == null:
		return

	var tilled: int = 0
	for cell: Vector2i in get_target_cells():
		if not _farming.is_cell_tilled(cell):
			_farming.till(cell)
			tilled += 1

	if tilled > 0:
		print("[AutoTiller] Day %d: tilled %d cells" % [new_day, tilled])
		if _visual:
			var tw := create_tween()
			tw.tween_property(_visual, "modulate", Color(0.8, 0.6, 0.3, 1.0), 0.08)
			tw.tween_property(_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
