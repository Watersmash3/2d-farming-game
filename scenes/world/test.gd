extends Node2D
## World controller: dev tools, farming mouse tools, crafting (C), Auto-Waterer placement (5).
## TODO: Dedicated input map actions, HUD hints, separate world controller scene.

@onready var farming: FarmingSystem = $FarmingSystem
@onready var farm_map: TileMapLayer = $FarmTileMap
@onready var automation: AutomationManager = $AutomationManager
@onready var crafting_menu: CanvasLayer = $CraftingMenu

var tool := 1
# 1 hoe, 2 water, 3 plant, 4 harvest
var place_machine_mode: bool = false
var _placement_preview: Polygon2D


func _ready() -> void:
	farming.add_to_group("farming_system")
	_demo_starting_resources()
	_setup_placement_preview()


func _demo_starting_resources() -> void:
	# Enough to craft after blueprint unlock. TODO: replace with world gen / shops / saves.
	PlayerInventory.add("wood", 30)
	PlayerInventory.add("stone", 20)
	PlayerInventory.add("fiber", 15)
	print(
		"World: demo materials (wood/stone/fiber). Unlock: harvest ",
		ProgressionManager.HARVESTS_TO_UNLOCK_AUTO_WATERER,
		" crops or press F9."
	)


func _setup_placement_preview() -> void:
	_placement_preview = Polygon2D.new()
	_placement_preview.polygon = PackedVector2Array([
		Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10),
	])
	_placement_preview.color = Color(0.3, 0.85, 1.0, 0.35)
	_placement_preview.visible = false
	add_child(_placement_preview)


func _process(_delta: float) -> void:
	if not place_machine_mode:
		return
	var cell := _mouse_to_cell()
	if farming.is_cell_tilled(cell) and not automation.is_cell_occupied(cell):
		_placement_preview.color = Color(0.3, 0.95, 0.4, 0.45)
	else:
		_placement_preview.color = Color(0.95, 0.3, 0.3, 0.4)
	_placement_preview.visible = true
	_placement_preview.global_position = farming.get_cell_world_center(cell)


func _mouse_to_cell() -> Vector2i:
	var mouse_world := get_global_mouse_position()
	return farm_map.local_to_map(farm_map.to_local(mouse_world))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			tool = 1
			_exit_place_mode()
		elif event.keycode == KEY_2:
			tool = 2
			_exit_place_mode()
		elif event.keycode == KEY_3:
			tool = 3
			_exit_place_mode()
		elif event.keycode == KEY_4:
			tool = 4
			_exit_place_mode()
		elif event.keycode == KEY_5:
			_toggle_place_mode()
		elif event.keycode == KEY_C:
			_exit_place_mode()
			if crafting_menu.has_method("toggle_visible"):
				crafting_menu.toggle_visible()
		elif event.keycode == KEY_F9:
			ProgressionManager.unlock_blueprint(AutomationRecipes.BLUEPRINT_AUTO_WATERER)
			print("Debug: blueprint unlock (F9) — ", AutomationRecipes.BLUEPRINT_AUTO_WATERER)
		elif event.keycode == KEY_ESCAPE:
			_exit_place_mode()
			if crafting_menu.visible:
				crafting_menu.hide()
		elif event.keycode == KEY_N:
			TimeSystem.advance_day()
			print("Advanced to day ", TimeSystem.time_tick.get_time_unit("day"))

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if crafting_menu.visible:
			return
		if place_machine_mode:
			_try_place_auto_waterer()
			return
		var cell := _mouse_to_cell()
		match tool:
			1:
				farming.till(cell)
			2:
				farming.water(cell)
			3:
				farming.plant(cell, "potato")
			4:
				farming.harvest(cell)


func _toggle_place_mode() -> void:
	if PlayerInventory.get_amount(AutomationRecipes.ITEM_AUTO_WATERER) < 1:
		print("Place mode: craft an Auto-Waterer first (C) and keep it in inventory.")
		place_machine_mode = false
		_placement_preview.visible = false
		return
	place_machine_mode = not place_machine_mode
	if not place_machine_mode:
		_placement_preview.visible = false
	print("Auto-Waterer placement: ", "ON" if place_machine_mode else "OFF")


func _exit_place_mode() -> void:
	place_machine_mode = false
	_placement_preview.visible = false


func _try_place_auto_waterer() -> void:
	var cell := _mouse_to_cell()
	if PlayerInventory.get_amount(AutomationRecipes.ITEM_AUTO_WATERER) < 1:
		print("Placement: no Auto-Waterer in inventory.")
		_exit_place_mode()
		return
	if not automation.try_place_auto_waterer(cell):
		return
	if not PlayerInventory.try_remove(AutomationRecipes.ITEM_AUTO_WATERER, 1):
		push_error("Placement: failed to consume item after place — check inventory logic.")
	_exit_place_mode()
	print("Placement: Auto-Waterer placed at ", cell, "; 1 item consumed.")
