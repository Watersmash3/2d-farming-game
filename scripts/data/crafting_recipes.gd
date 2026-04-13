extends RefCounted
class_name CraftingRecipes

## Data-only craft definitions. TODO: migrate to Resource assets when the item economy grows.

const BLUEPRINT_AUTO_WATERER  := "auto_waterer"
const BLUEPRINT_AUTO_SEEDER   := "auto_seeder"
const BLUEPRINT_AUTO_HARVESTER := "auto_harvester"
const BLUEPRINT_AUTO_TILLER   := "auto_tiller"

# recipe_id -> { result_id, result_amount, ingredients: { item_id: count }, blueprint_id }
const RECIPES: Dictionary = {
	"auto_waterer": {
		"result_id":     "auto_waterer",
		"result_amount": 1,
		"ingredients":   {"wood": 10, "stone": 5, "fiber": 3},
		"blueprint_id":  BLUEPRINT_AUTO_WATERER,
	},
	"auto_seeder": {
		"result_id":     "auto_seeder",
		"result_amount": 1,
		"ingredients":   {"wood": 8, "fiber": 5},
		"blueprint_id":  BLUEPRINT_AUTO_SEEDER,
	},
	"auto_harvester": {
		"result_id":     "auto_harvester",
		"result_amount": 1,
		"ingredients":   {"wood": 8, "stone": 5, "fiber": 3},
		"blueprint_id":  BLUEPRINT_AUTO_HARVESTER,
	},
	"auto_tiller": {
		"result_id":     "auto_tiller",
		"result_amount": 1,
		"ingredients":   {"wood": 6, "stone": 8},
		"blueprint_id":  BLUEPRINT_AUTO_TILLER,
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
