extends RefCounted
class_name CraftingRecipes

## Data-only craft definitions. TODO: migrate to Resource assets when the item economy grows.

const BLUEPRINT_AUTO_WATERER := "auto_waterer"

# recipe_id -> { result_id, result_amount, ingredients: { item_id: count }, blueprint_id }
const RECIPES: Dictionary = {
	"auto_waterer": {
		"result_id": "auto_waterer",
		"result_amount": 1,
		"ingredients": {"wood": 10, "stone": 5, "fiber": 3},
		"blueprint_id": BLUEPRINT_AUTO_WATERER,
	},
}


static func list_recipe_ids() -> Array[String]:
	var out: Array[String] = []
	for k: Variant in RECIPES.keys():
		out.append(str(k))
	return out


static func get_recipe(recipe_id: String) -> Dictionary:
	if not RECIPES.has(recipe_id):
		return {}
	return RECIPES[recipe_id] as Dictionary
