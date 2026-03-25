extends Node

@onready var hotbar: HBoxContainer = $CanvasLayer/Control/HotBar
@onready var panel: Control = $CanvasLayer/Control/Panel

var icon_by_id: Dictionary = {}
## Parallel to hotbar slot index after refresh (which item id occupies each slot).
var _slot_item_ids: Array[String] = []


func _ready() -> void:
	icon_by_id = InventoryItemIcons.build_icon_map()

	panel.visible = false
	hotbar.visible = false

	for slot: Node in hotbar.get_children():
		if slot.has_signal("slot_pressed"):
			slot.slot_pressed.connect(_on_slot_pressed)

	InventoryState.inventory_changed.connect(refresh)
	InventoryState.selected_item_changed.connect(func(_id: String) -> void: _apply_slot_highlights())
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		hotbar.visible = !hotbar.visible
		get_viewport().set_input_as_handled()


func _on_slot_pressed(item_id: String) -> void:
	InventoryState.set_selected_item(item_id)


func refresh() -> void:
	var slots: Array = hotbar.get_children()

	for slot: Node in slots:
		if slot.has_method("set_slot"):
			slot.set_slot(null, 0, "")

	_slot_item_ids.clear()

	var items: Array[String] = []
	for id: Variant in InventoryState.inventory.keys():
		var item_key: String = str(id)
		var c: int = InventoryState.get_count(item_key)
		if c > 0 and icon_by_id.has(item_key):
			items.append(item_key)

	items.sort()

	var slot_i: int = 0
	for id: String in items:
		if slot_i >= slots.size():
			break
		var sl: Node = slots[slot_i]
		if sl.has_method("set_slot"):
			sl.set_slot(icon_by_id[id], InventoryState.get_count(id), id)
			_slot_item_ids.append(id)
		slot_i += 1

	_apply_slot_highlights()


func _apply_slot_highlights() -> void:
	var slots: Array = hotbar.get_children()
	var sel: String = InventoryState.selected_item_id
	for i: int in range(slots.size()):
		var sl: Node = slots[i]
		if not sl.has_method("set_selected"):
			continue
		var sid: String = _slot_item_ids[i] if i < _slot_item_ids.size() else ""
		sl.set_selected(sid != "" and sid == sel)
