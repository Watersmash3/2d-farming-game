extends AutomationMachine
class_name AutoWaterer

## Waters neighboring cells each day (range expands with upgrade level).

@onready var _visual: Node2D = $VisualRoot


func _ready() -> void:
	if _farming != null:
		global_position = _farming.get_cell_world_center(grid_cell)
	AutomationManager.register_machine(self, grid_cell)
	if _visual:
		_visual.modulate = Color(0.75, 0.9, 1.0, 1.0)
		for c: Node in _visual.get_children():
			if c is Sprite2D:
				(c as Sprite2D).texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func on_new_day(new_day: int, old_day: int) -> void:
	if _farming == null:
		return
	var targets := get_target_cells()
	var watered: Array[String] = []
	for c: Vector2i in targets:
		_farming.water(c)
		watered.append(str(c))
	if not watered.is_empty():
		print("[AutoWaterer] Day %d (was %d): lvl%d watered %s" % [new_day, old_day, upgrade_level, ", ".join(watered)])
		if _visual:
			var tw := create_tween()
			tw.tween_property(_visual, "modulate", Color(0.4, 0.95, 1.0, 1.0), 0.08)
			tw.tween_property(_visual, "modulate", Color(0.75, 0.9, 1.0, 1.0), 0.25)
