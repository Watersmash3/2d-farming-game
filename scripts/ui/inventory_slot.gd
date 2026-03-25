extends PanelContainer

signal slot_pressed(item_id: String)

@onready var icon: TextureRect = $Icon
@onready var count: Label = $Count

var _item_id: String = ""


func set_slot(tex: Texture2D, amount: int, item_id: String = "") -> void:
	_item_id = item_id
	# Keep the slot box itself visible at all times
	visible = true

	if tex == null or amount <= 0:
		_item_id = ""
		icon.visible = false
		count.visible = false
		icon.texture = null
		count.text = ""
		return

	icon.visible = true
	count.visible = true
	icon.texture = tex
	count.text = "x%d" % amount


func set_selected(selected: bool) -> void:
	modulate = Color(1.2, 1.15, 0.85, 1.0) if selected else Color.WHITE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _item_id != "":
			slot_pressed.emit(_item_id)
			accept_event()
