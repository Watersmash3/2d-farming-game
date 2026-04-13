extends AutomationMachine
class_name AutoSeeder

## Plants seeds in tilled, watered, empty neighboring cells each day.
## Set preferred_crop_id in the Inspector (e.g. "potato").

@export var preferred_crop_id: String = "potato"

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
	return {"wood": 4, "fiber": 4}


func on_new_day(new_day: int, _old_day: int) -> void:
	if _farming == null or preferred_crop_id == "":
		return

	var seed_id: String = _farming.SEED_ITEM_BY_CROP.get(preferred_crop_id, "")
	if seed_id == "":
		return

	var seeded: int = 0
	for cell: Vector2i in get_target_cells():
		if not _farming.is_cell_tilled(cell):
			continue
		if _farming.cell_has_crop(cell):
			continue
		if not _farming.is_cell_watered(cell):
			continue
		if not InventoryState.has_item(seed_id, 1):
			break
		_farming.plant(cell, preferred_crop_id)
		seeded += 1

	if seeded > 0:
		print("[AutoSeeder] Day %d: planted %d %s" % [new_day, seeded, preferred_crop_id])
		if _visual:
			var tw := create_tween()
			tw.tween_property(_visual, "modulate", Color(0.6, 1.0, 0.5, 1.0), 0.08)
			tw.tween_property(_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
