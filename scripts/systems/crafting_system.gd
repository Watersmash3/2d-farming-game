extends Node
## Uses ProgressionManager + PlayerInventory + AutomationRecipes to craft automation items.
## TODO: Crafting queues, stations, sound/VFX hooks.

signal craft_succeeded(recipe_id: String)
signal craft_failed(recipe_id: String, reason: String)


func can_craft(recipe_id: String) -> bool:
	var recipe: Dictionary = AutomationRecipes.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var bp: String = str(recipe.get("blueprint_id", ""))
	if not ProgressionManager.is_blueprint_unlocked(bp):
		return false
	var ingredients: Dictionary = recipe.get("ingredients", {}) as Dictionary
	return PlayerInventory.can_afford(ingredients)


func try_craft(recipe_id: String) -> bool:
	var recipe: Dictionary = AutomationRecipes.get_recipe(recipe_id)
	if recipe.is_empty():
		craft_failed.emit(recipe_id, "unknown_recipe")
		return false
	var bp: String = str(recipe.get("blueprint_id", ""))
	if not ProgressionManager.is_blueprint_unlocked(bp):
		craft_failed.emit(recipe_id, "locked")
		return false
	var ingredients: Dictionary = recipe.get("ingredients", {}) as Dictionary
	if not PlayerInventory.try_consume(ingredients):
		craft_failed.emit(recipe_id, "missing_materials")
		return false
	var out_id: String = str(recipe.get("output_item_id", ""))
	var out_amt: int = int(recipe.get("output_amount", 1))
	if out_id.is_empty():
		craft_failed.emit(recipe_id, "bad_output")
		return false
	PlayerInventory.add(out_id, out_amt)
	print("CraftingSystem: crafted ", recipe.get("display_name", recipe_id), " → ", out_id, " x", out_amt)
	craft_succeeded.emit(recipe_id)
	return true
