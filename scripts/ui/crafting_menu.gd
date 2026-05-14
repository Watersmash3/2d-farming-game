extends CanvasLayer

## Minimal automation crafting panel. TODO: tabs, categories, recipe discovery, and nicer layout.

@onready var _root: Control = $Root
@onready var _panel: PanelContainer = $Root/Panel
@onready var _recipe_list: VBoxContainer = $Root/Panel/Margin/VBox/Scroll/RecipeList
@onready var _status: Label = $Root/Panel/Margin/VBox/Status


func _ready() -> void:
	layer = 48
	visible = false
	_root.visible = false
	_apply_theme()
	ProgressionManager.blueprint_unlocked.connect(func(_id: String) -> void: refresh())
	Crafting.craft_succeeded.connect(_on_craft_succeeded)
	Crafting.craft_failed.connect(_on_craft_failed)
	InventoryState.inventory_changed.connect(refresh)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_crafting"):
		visible = !visible
		_root.visible = visible
		if visible:
			refresh()
		get_viewport().set_input_as_handled()


func _on_craft_succeeded(_recipe_id: String, result_id: String, amount: int) -> void:
	var nm: String = str(Items.DATA.get(result_id, {}).get("name", result_id))
	_status.text = "Crafted %s x%d" % [nm, amount]
	refresh()


func _on_craft_failed(recipe_id: String, reason: String) -> void:
	_status.text = "Cannot craft %s (%s)" % [recipe_id, reason]


func refresh() -> void:
	for c: Node in _recipe_list.get_children():
		c.queue_free()

	for recipe_id: String in CraftingRecipes.list_recipe_ids():
		_recipe_list.add_child(_make_recipe_row(recipe_id))


func _make_recipe_row(recipe_id: String) -> Control:
	var recipe: Dictionary = CraftingRecipes.get_recipe(recipe_id)
	var result_id: String = str(recipe.get("result_id", recipe_id))
	var bp: String = str(recipe.get("blueprint_id", ""))
	var unlocked: bool = bp.is_empty() or ProgressionManager.is_blueprint_unlocked(bp)

	var outer := PanelContainer.new()
	outer.add_theme_stylebox_override("panel", _make_recipe_style(unlocked))
	outer.mouse_filter = Control.MOUSE_FILTER_STOP

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	outer.add_child(margin)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 5)
	margin.add_child(body)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	body.add_child(row)

	var title := Label.new()
	var disp: String = str(Items.DATA.get(result_id, {}).get("name", result_id))
	if not unlocked:
		disp += " - Locked"
	title.text = disp
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color("#f3dfb2") if unlocked else Color("#b9aa91"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	row.add_child(title)

	var btn := Button.new()
	btn.text = "Craft"
	btn.disabled = not unlocked
	btn.custom_minimum_size = Vector2(84, 30)
	btn.focus_mode = Control.FOCUS_NONE
	_apply_button_theme(btn)
	btn.pressed.connect(func() -> void: Crafting.try_craft(recipe_id))
	row.add_child(btn)

	var ing: Dictionary = recipe.get("ingredients", {}) as Dictionary
	var parts: PackedStringArray = PackedStringArray()
	for mat_id: String in ing.keys():
		var need: int = int(ing[mat_id])
		var have: int = InventoryState.get_count(mat_id)
		var mat_name: String = str(Items.DATA.get(mat_id, {}).get("name", mat_id))
		parts.append("%s %d/%d" % [mat_name, have, need])
	var sub := Label.new()
	sub.text = "  " + " - ".join(parts)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_color_override("font_color", Color("#d8c7a8"))
	body.add_child(sub)

	return outer


func is_open() -> bool:
	return visible


func _apply_theme() -> void:
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#2b2118", 0.96)
	panel_style.border_color = Color("#8b5a2b")
	panel_style.set_border_width_all(3)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 0
	panel_style.content_margin_right = 0
	panel_style.content_margin_top = 0
	panel_style.content_margin_bottom = 0
	_panel.add_theme_stylebox_override("panel", panel_style)

	var title := $Root/Panel/Margin/VBox/Title as Label
	title.text = "Crafting - Automation"
	title.add_theme_color_override("font_color", Color("#f3dfb2"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)

	var hint := $Root/Panel/Margin/VBox/Hint as Label
	hint.add_theme_color_override("font_color", Color("#d8c7a8"))

	_status.add_theme_color_override("font_color", Color("#e7c56a"))


func _make_recipe_style(unlocked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#241b14", 0.88) if unlocked else Color("#1b1713", 0.82)
	style.border_color = Color("#8b5a2b") if unlocked else Color("#5f4a33")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _apply_button_theme(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_button_style(Color("#4a2f1b"), Color("#8b5a2b")))
	button.add_theme_stylebox_override("hover", _make_button_style(Color("#5b3a21"), Color("#e7c56a")))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color("#2f2118"), Color("#e7c56a")))
	button.add_theme_stylebox_override("disabled", _make_button_style(Color("#2a241d", 0.82), Color("#5f4a33")))
	button.add_theme_color_override("font_color", Color("#f3dfb2"))
	button.add_theme_color_override("font_hover_color", Color("#fff1c5"))
	button.add_theme_color_override("font_pressed_color", Color("#e7c56a"))
	button.add_theme_color_override("font_disabled_color", Color("#8c806d"))


func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
