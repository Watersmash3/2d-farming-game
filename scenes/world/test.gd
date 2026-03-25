extends Node2D

const AUTO_WATERER_SCENE: PackedScene = preload("res://scenes/automation/AutoWaterer.tscn")

@onready var farming: FarmingSystem = $FarmingSystem
@onready var farm_map: TileMapLayer = $FarmTileMap
@onready var machines_root: Node2D = $Machines
@onready var placement_preview: Sprite2D = $PlacementPreview
@onready var crafting_menu: CanvasLayer = $CraftingMenu

var tool: int = 1
# 1 hoe, 2 water, 3 plant, 4 harvest

var machine_placement_active: bool = false


func _ready() -> void:
	placement_preview.visible = false
	placement_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(_delta: float) -> void:
	if not machine_placement_active:
		placement_preview.visible = false
		return
	var mouse_world: Vector2 = get_global_mouse_position()
	var cell: Vector2i = farm_map.local_to_map(farm_map.to_local(mouse_world))
	placement_preview.global_position = farming.get_cell_world_center(cell)
	var ok: bool = AutomationManager.can_place_machine_at(cell, farming)
	placement_preview.modulate = Color(0.35, 1.0, 0.45, 0.72) if ok else Color(1.0, 0.32, 0.32, 0.75)
	placement_preview.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			tool = 1
		elif event.keycode == KEY_2:
			tool = 2
		elif event.keycode == KEY_3:
			tool = 3
		elif event.keycode == KEY_4:
			tool = 4
		elif event.keycode == KEY_N:
			TimeSystem.advance_day()
			print("[Time] Advanced to day ", TimeSystem.time_tick.get_time_unit("day"))

	if event.is_action_pressed("place_machine"):
		_try_begin_machine_placement()

	if event.is_action_pressed("cancel_placement"):
		if machine_placement_active:
			machine_placement_active = false
			placement_preview.visible = false
			print("[Placement] Cancelled")

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if machine_placement_active:
			if _ui_is_blocking_mouse():
				return
			_try_confirm_machine_placement()
			return

		if _ui_is_blocking_mouse():
			return

		var mouse_world: Vector2 = get_global_mouse_position()
		var cell: Vector2i = farm_map.local_to_map(farm_map.to_local(mouse_world))

		match tool:
			1:
				farming.till(cell)
			2:
				farming.water(cell)
			3:
				farming.plant(cell, "potato")
			4:
				farming.harvest(cell)


func _try_begin_machine_placement() -> void:
	if InventoryState.get_count("auto_waterer") <= 0:
		print("[Placement] No Auto-Waterer in inventory")
		return
	var sel: String = InventoryState.selected_item_id
	if sel != "" and sel != "auto_waterer":
		print("[Placement] Select the Auto-Waterer in the hotbar (I), or clear selection")
		return
	machine_placement_active = true
	placement_preview.visible = true
	print("[Placement] Auto-Waterer mode — LMB valid tile, Esc / RMB cancel")


func _try_confirm_machine_placement() -> void:
	var mouse_world: Vector2 = get_global_mouse_position()
	var cell: Vector2i = farm_map.local_to_map(farm_map.to_local(mouse_world))
	if not AutomationManager.can_place_machine_at(cell, farming):
		print("[Placement] Invalid cell %s (need empty tilled tile, no machine)" % str(cell))
		return
	if not InventoryState.remove_item("auto_waterer", 1):
		machine_placement_active = false
		return
	var m: Node = AUTO_WATERER_SCENE.instantiate()
	if m is AutoWaterer:
		(m as AutoWaterer).setup(farming, cell)
	machines_root.add_child(m)
	print("[Placement] Placed Auto-Waterer at %s" % str(cell))
	machine_placement_active = false
	placement_preview.visible = false


func _ui_is_blocking_mouse() -> bool:
	# While crafting is open, ignore farm/placement LMB (UI buttons still receive clicks first).
	return crafting_menu != null and crafting_menu.visible
