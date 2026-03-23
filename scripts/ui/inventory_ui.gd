extends Node

@export var potato_seed_icon: Texture2D = preload("res://assets/sprites/potato/Spring Crops_0001.png")
@export var potato_icon: Texture2D = preload("res://assets/sprites/potato/Spring Crops_0007.png")

@onready var hotbar := $CanvasLayer/Control/HotBar
@onready var panel := $CanvasLayer/Control/Panel

var icon_by_id := {}

func _ready() -> void:
	icon_by_id = {
		"potato_seed": potato_seed_icon,
		"potato": potato_icon,
	}

	# Never show the panel
	panel.visible = false

	# Start with hotbar hidden or visible depending on what you want
	hotbar.visible = false

	InventoryState.inventory_changed.connect(refresh)
	refresh()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		hotbar.visible = !hotbar.visible

func refresh() -> void:
	var slots := hotbar.get_children()

	# Hide every slot first
	for slot in slots:
		if slot.has_method("set_slot"):
			slot.set_slot(null, 0)

	var items := []
	for id in InventoryState.inventory.keys():
		var c := InventoryState.get_count(id)
		if c > 0 and icon_by_id.has(id):
			items.append(id)

	items.sort()

	var slot_i := 0
	for id in items:
		if slot_i >= slots.size():
			break
		slots[slot_i].set_slot(icon_by_id[id], InventoryState.get_count(id))
		slot_i += 1
