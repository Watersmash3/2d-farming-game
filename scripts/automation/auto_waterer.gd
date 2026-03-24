extends AutomationMachine
class_name AutoWaterer
## Waters the four orthogonally adjacent farm cells each day (after the farming day tick clears water).
## TODO: Radius upgrades, different patterns via exported resource.

const _ORTHO_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]


func _ready() -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-7, -7), Vector2(7, -7), Vector2(7, 7), Vector2(-7, 7),
	])
	poly.color = Color(0.25, 0.55, 0.95, 0.92)
	add_child(poly)


func on_daily_tick(farming: FarmingSystem, new_day: int) -> void:
	var parts: PackedStringArray = []
	for off: Vector2i in _ORTHO_OFFSETS:
		var target: Vector2i = grid_cell + off
		farming.water(target)
		parts.append(str(target))
	print("AutoWaterer: day ", new_day, " watered cells: ", " ".join(parts))
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.25, 1.25, 1.25, 1.0), 0.07)
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)
