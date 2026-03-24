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

	var outer := VBoxContainer.new()
	var row := HBoxContainer.new()
	outer.add_child(row)

	var title := Label.new()
	var disp: String = str(Items.DATA.get(result_id, {}).get("name", result_id))
	if not unlocked:
		disp += " [LOCKED]"
	title.text = disp
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var btn := Button.new()
	btn.text = "Craft"
	btn.disabled = not unlocked
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
	sub.text = "  " + " · ".join(parts)
	sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	outer.add_child(sub)

	return outer


func is_open() -> bool:
	return visible
