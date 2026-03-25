extends AutomationMachine
class_name AutoWaterer

## Waters the four orthogonal neighbors each day (after the farming midnight tick).

const NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if _farming != null:
		global_position = _farming.get_cell_world_center(grid_cell)
	AutomationManager.register_machine(self, grid_cell)
	if _sprite:
		_sprite.modulate = Color(0.75, 0.9, 1.0, 1.0)


func on_new_day(new_day: int, old_day: int) -> void:
	if _farming == null:
		return
	var watered: Array[String] = []
	for off: Vector2i in NEIGHBORS:
		var c: Vector2i = grid_cell + off
		_farming.water(c)
		watered.append(str(c))
	if not watered.is_empty():
		print("[AutoWaterer] Day %d (was %d): watered cells %s" % [new_day, old_day, ", ".join(watered)])
		if _sprite:
			var tw := create_tween()
			tw.tween_property(_sprite, "modulate", Color(0.4, 0.95, 1.0, 1.0), 0.08)
			tw.tween_property(_sprite, "modulate", Color(0.75, 0.9, 1.0, 1.0), 0.25)
