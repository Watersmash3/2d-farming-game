extends Node

@onready var hotbar: HBoxContainer = $CanvasLayer/Control/BottomBarArea/CenterContainer/HotBar
@onready var panel: Panel = $CanvasLayer/Control/BottomBarArea/Panel
@onready var panel_contents: VBoxContainer = $CanvasLayer/Control/BottomBarArea/Panel/VBoxContainer
@onready var inventory_grid: GridContainer = $CanvasLayer/Control/BottomBarArea/Panel/VBoxContainer/Grid
@onready var hotbar_background: Panel = $CanvasLayer/Control/BottomBarArea/CenterContainer/HotbarBackground

var icon_by_id: Dictionary = {}
const INVENTORY_PAD_X := 16.0
const INVENTORY_PAD_Y := 0.0

func _ready() -> void:
	icon_by_id = InventoryItemIcons.build_icon_map()

	panel.visible = false
	hotbar.visible = true

	_apply_wood_theme()

	_connect_slots()

	InventoryState.inventory_changed.connect(refresh)
	InventoryState.selected_item_changed.connect(func(_id: String) -> void:
		_apply_slot_highlights()
	)

	refresh()

	await get_tree().process_frame
	_update_panel_layout()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		panel.visible = !panel.visible

		await get_tree().process_frame
		_update_panel_layout()

		get_viewport().set_input_as_handled()


func _update_panel_layout() -> void:
	var contents_size: Vector2 = panel_contents.get_combined_minimum_size()

	# Inventory panel sizing
	panel.custom_minimum_size = contents_size + Vector2(INVENTORY_PAD_X * 2.0, INVENTORY_PAD_Y * 2.0)
	panel.size = panel.custom_minimum_size

	panel_contents.position = Vector2(INVENTORY_PAD_X, INVENTORY_PAD_Y)
	panel_contents.size = panel.size - Vector2(INVENTORY_PAD_X * 2.0, INVENTORY_PAD_Y * 2.0)

	# Center inventory above hotbar
	panel.position.x = hotbar.position.x + (hotbar.size.x - panel.size.x) / 2.0

	var gap := 6.0
	panel.position.y = hotbar.position.y - panel.size.y - gap

	# Make hotbar backing match inventory width
	var hotbar_bg_height := hotbar.size.y + 10.0

	hotbar_background.size = Vector2(panel.size.x, hotbar_bg_height)

	# Line hotbar backing up with inventory panel
	hotbar_background.position.x = panel.position.x
	hotbar_background.position.y = hotbar.position.y - 5.0


func _connect_slots() -> void:
	for slot: Node in hotbar.get_children():
		if slot.has_signal("slot_pressed") and not slot.slot_pressed.is_connected(_on_slot_pressed):
			slot.slot_pressed.connect(_on_slot_pressed)
		if slot.has_signal("slot_drop_requested") and not slot.slot_drop_requested.is_connected(_on_slot_drop_requested):
			slot.slot_drop_requested.connect(_on_slot_drop_requested)

	for slot: Node in inventory_grid.get_children():
		if slot.has_signal("slot_pressed") and not slot.slot_pressed.is_connected(_on_slot_pressed):
			slot.slot_pressed.connect(_on_slot_pressed)
		if slot.has_signal("slot_drop_requested") and not slot.slot_drop_requested.is_connected(_on_slot_drop_requested):
			slot.slot_drop_requested.connect(_on_slot_drop_requested)


func _all_slots() -> Array:
	var all: Array = []
	for slot: Node in hotbar.get_children():
		all.append(slot)
	for slot: Node in inventory_grid.get_children():
		all.append(slot)
	return all


func _on_slot_pressed(item_id: String) -> void:
	InventoryState.set_selected_item(item_id)


func _on_slot_drop_requested(from_index: int, to_index: int) -> void:
	InventoryState.move_slot(from_index, to_index)


func refresh() -> void:
	var ui_slots: Array = _all_slots()

	for i: int in range(ui_slots.size()):
		var slot: Node = ui_slots[i]
		var slot_data: Dictionary = InventoryState.get_slot(i)

		var item_id: String = str(slot_data.get("item_id", ""))
		var amount: int = int(slot_data.get("count", 0))
		var tex: Texture2D = null

		if item_id != "" and amount > 0 and icon_by_id.has(item_id):
			tex = icon_by_id[item_id]

		if slot.has_method("set_slot"):
			slot.set_slot(i, tex, amount, item_id)

	_apply_slot_highlights()
	call_deferred("_update_panel_layout")


func _apply_slot_highlights() -> void:
	var ui_slots: Array = _all_slots()
	var sel: String = InventoryState.selected_item_id

	for i: int in range(ui_slots.size()):
		var slot: Node = ui_slots[i]
		if not slot.has_method("set_selected"):
			continue

		var slot_data: Dictionary = InventoryState.get_slot(i)
		var item_id: String = str(slot_data.get("item_id", ""))

		slot.set_selected(item_id != "" and item_id == sel)

func _apply_wood_theme() -> void:
	var wood := StyleBoxFlat.new()
	wood.bg_color = Color("#4a2f1b", 0.94)
	wood.border_color = Color("#8b5a2b")
	wood.set_border_width_all(3)

	wood.corner_radius_top_left = 6
	wood.corner_radius_top_right = 6
	wood.corner_radius_bottom_left = 6
	wood.corner_radius_bottom_right = 6

	wood.content_margin_left = 8
	wood.content_margin_right = 8
	wood.content_margin_top = 3
	wood.content_margin_bottom = 3

	hotbar_background.add_theme_stylebox_override("panel", wood)

	var inv_wood := StyleBoxFlat.new()
	inv_wood.bg_color = Color("#4a2f1b", 0.94)
	inv_wood.border_color = Color("#8b5a2b")
	inv_wood.set_border_width_all(3)

	inv_wood.corner_radius_top_left = 6
	inv_wood.corner_radius_top_right = 6
	inv_wood.corner_radius_bottom_left = 6
	inv_wood.corner_radius_bottom_right = 6

	inv_wood.content_margin_left = 10
	inv_wood.content_margin_right = 10
	inv_wood.content_margin_top = 3
	inv_wood.content_margin_bottom = 3

	panel.add_theme_stylebox_override("panel", inv_wood)
