extends PanelContainer

signal slot_pressed(item_id: String)
signal slot_drop_requested(from_index: int, to_index: int)

@onready var icon: TextureRect = $Icon
@onready var count: Label = $Count
@onready var selected_outline: Control = $SelectedOutline if has_node("SelectedOutline") else null

var _item_id: String = ""
var _count: int = 0
var _slot_index: int = -1
var _is_selected: bool = false
var _style: StyleBoxFlat = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	count.add_theme_color_override("font_color", Color("#f3dfb2"))
	count.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	count.add_theme_constant_override("shadow_offset_x", 1)
	count.add_theme_constant_override("shadow_offset_y", 1)

	if selected_outline != null:
		selected_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_outline.visible = false

	_update_visual()


func set_slot(slot_index: int, tex: Texture2D, amount: int, item_id: String = "") -> void:
	_slot_index = slot_index
	_item_id = item_id
	_count = amount
	visible = true

	if amount <= 0 or item_id == "":
		_item_id = ""
		_count = 0
		icon.visible = false
		count.visible = false
		icon.texture = null
		count.text = ""
		_is_selected = false
		_update_visual()
		return

	icon.visible = tex != null
	count.visible = true
	icon.texture = tex
	count.text = "x%d" % amount

	_update_visual()


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_update_visual()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		if _item_id != "":
			slot_pressed.emit(_item_id)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if _item_id == "" or _slot_index < 0:
		return null

	var preview := Control.new()
	var preview_icon := TextureRect.new()
	preview_icon.texture = icon.texture
	preview_icon.custom_minimum_size = Vector2(40, 40)
	preview_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.add_child(preview_icon)
	set_drag_preview(preview)

	return {
		"from_index": _slot_index,
		"item_id": _item_id,
		"count": _count
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("from_index")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	if not data.has("from_index"):
		return

	var from_index: int = int(data["from_index"])
	slot_drop_requested.emit(from_index, _slot_index)

func _ensure_style() -> void:
	if _style == null:
		_style = StyleBoxFlat.new()
		add_theme_stylebox_override("panel", _style)

func _update_visual() -> void:
	_ensure_style()

	if _item_id == "":
		_style.bg_color = Color("#2b2118", 0.55)
	else:
		_style.bg_color = Color("#241b14", 0.82)

	if _is_selected:
		_style.border_color = Color("#e7c56a")
		_style.set_border_width_all(3)
	else:
		_style.border_color = Color("#8a6a45")
		_style.set_border_width_all(1)

	_style.corner_radius_top_left = 4
	_style.corner_radius_top_right = 4
	_style.corner_radius_bottom_left = 4
	_style.corner_radius_bottom_right = 4

	_style.content_margin_left = 4
	_style.content_margin_right = 4
	_style.content_margin_top = 4
	_style.content_margin_bottom = 4

	modulate = Color.WHITE

	if selected_outline != null:
		selected_outline.visible = false
