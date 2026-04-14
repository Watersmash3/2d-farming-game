extends Node

@onready var hotbar: HBoxContainer = $CanvasLayer/Control/BottomBarArea/CenterContainer/HotBar
@onready var panel: Panel = $CanvasLayer/Control/BottomBarArea/Panel
@onready var panel_contents: VBoxContainer = $CanvasLayer/Control/BottomBarArea/Panel/VBoxContainer
@onready var inventory_grid: GridContainer = $CanvasLayer/Control/BottomBarArea/Panel/VBoxContainer/Grid

var icon_by_id: Dictionary = {}


func _ready() -> void:
	icon_by_id = InventoryItemIcons.build_icon_map()

	panel.visible = false
	hotbar.visible = true

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
	panel.custom_minimum_size = contents_size
	panel.size = contents_size

	# Center the inventory panel horizontally over the hotbar
	panel.position.x = hotbar.position.x + (hotbar.size.x - panel.size.x) / 2.0

	# Put the inventory panel above the hotbar with a small gap
	var gap := -10.0
	panel.position.y = hotbar.position.y - panel.size.y - gap


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
