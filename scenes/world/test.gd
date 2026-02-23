extends Node2D

@onready var farming: FarmingSystem = $FarmingSystem
@onready var farm_map: TileMapLayer = $FarmTileMap

var tool := 1
# 1 hoe, 2 water, 3 plant, 4 harvest

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: tool = 1
		if event.keycode == KEY_2: tool = 2
		if event.keycode == KEY_3: tool = 3
		if event.keycode == KEY_4: tool = 4
		if event.keycode == KEY_SPACE:
			# Advance to next day
			TimeSystem.advance_day()
			print("Advanced to day ", TimeSystem.time_tick.get_time_unit("day"))

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_world := get_global_mouse_position()
		var cell := farm_map.local_to_map(farm_map.to_local(mouse_world))

		match tool:
			1: farming.till(cell)
			2: farming.water(cell)
			3: farming.plant(cell, "potato")
			4: farming.harvest(cell)
