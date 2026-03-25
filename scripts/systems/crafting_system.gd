extends Node

## Autoload: Crafting. Applies recipe data + inventory + blueprint gates.

signal craft_succeeded(recipe_id: String, result_id: String, amount: int)
signal craft_failed(recipe_id: String, reason: String)


func try_craft(recipe_id: String) -> bool:
	var recipe: Dictionary = CraftingRecipes.get_recipe(recipe_id)
	if recipe.is_empty():
		craft_failed.emit(recipe_id, "unknown_recipe")
		return false

	var bp: String = str(recipe.get("blueprint_id", ""))
	if bp != "" and not ProgressionManager.is_blueprint_unlocked(bp):
		craft_failed.emit(recipe_id, "locked")
		print("[Crafting] Blocked (locked): %s" % recipe_id)
		return false

	var ingredients: Dictionary = recipe.get("ingredients", {}) as Dictionary
	for item_id: String in ingredients.keys():
		var need: int = int(ingredients[item_id])
		if not InventoryState.has_item(item_id, need):
			craft_failed.emit(recipe_id, "missing_materials")
			print("[Crafting] Blocked (materials): %s" % recipe_id)
			return false

	for item_id: String in ingredients.keys():
		var need: int = int(ingredients[item_id])
		InventoryState.remove_item(item_id, need)

	var result_id: String = str(recipe.get("result_id", ""))
	var result_amt: int = int(recipe.get("result_amount", 1))
	if result_id == "":
		craft_failed.emit(recipe_id, "bad_recipe")
		return false

	if not InventoryState.add_item(result_id, result_amt):
		# Refund ingredients (best-effort rollback)
		for item_id: String in ingredients.keys():
			InventoryState.add_item(item_id, int(ingredients[item_id]))
		craft_failed.emit(recipe_id, "inventory_full")
		return false

	print("[Crafting] Crafted %s x%d" % [result_id, result_amt])
	craft_succeeded.emit(recipe_id, result_id, result_amt)
	return true
