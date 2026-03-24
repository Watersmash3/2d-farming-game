extends CanvasLayer
## Minimal automation crafting panel. Toggle from world input (e.g. C).
## TODO: Tabs, more recipes, icons, controller navigation.

@onready var _list: VBoxContainer = $Panel/Margin/VBox/Scroll/List
@onready var _status: Label = $Panel/Margin/VBox/Status


func _ready() -> void:
	hide()
	CraftingSystem.craft_succeeded.connect(_on_craft_ok)
	CraftingSystem.craft_failed.connect(_on_craft_fail)
	ProgressionManager.blueprint_unlocked.connect(_on_blueprint_unlocked)
	PlayerInventory.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed() -> void:
	if visible:
		refresh()


func _on_blueprint_unlocked(_id: String) -> void:
	if visible:
		refresh()


func toggle_visible() -> void:
	visible = not visible
	if visible:
		refresh()


func refresh() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	for rid: String in AutomationRecipes.all_recipe_ids():
		_list.add_child(_make_recipe_row(rid))
	_status.text = ""


func _make_recipe_row(recipe_id: String) -> Control:
	var recipe: Dictionary = AutomationRecipes.get_recipe(recipe_id)
	var bp: String = str(recipe.get("blueprint_id", ""))
	var unlocked: bool = ProgressionManager.is_blueprint_unlocked(bp)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	var display: String = str(recipe.get("display_name", recipe_id))
	if unlocked:
		title.text = display
	else:
		title.text = "%s (locked)" % display
	info.add_child(title)

	var ing := Label.new()
	ing.text = "Needs: %s" % AutomationRecipes.ingredient_lines(recipe)
	ing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(ing)

	var can_craft_now: bool = CraftingSystem.can_craft(recipe_id)

	var btn := Button.new()
	btn.text = "Craft"
	btn.disabled = not can_craft_now
	btn.pressed.connect(_on_craft_pressed.bind(recipe_id))
	if not unlocked:
		btn.tooltip_text = "Unlock blueprint first (harvest crops or debug key)."
	elif not PlayerInventory.can_afford(recipe.get("ingredients", {}) as Dictionary):
		btn.tooltip_text = "Not enough materials."

	row.add_child(info)
	row.add_child(btn)
	return row


func _on_craft_pressed(recipe_id: String) -> void:
	CraftingSystem.try_craft(recipe_id)


func _on_craft_ok(recipe_id: String) -> void:
	_status.text = "Crafted: %s" % recipe_id
	refresh()


func _on_craft_fail(recipe_id: String, reason: String) -> void:
	_status.text = "Could not craft %s (%s)" % [recipe_id, reason]
	refresh()
