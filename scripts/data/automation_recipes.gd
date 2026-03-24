extends RefCounted
class_name AutomationRecipes
## Data-only recipe / blueprint ids for automation crafting. UI and crafting read from here.
## TODO: More machines, tech tree links, alternative ingredients, MachineDefinition resources.

const BLUEPRINT_AUTO_WATERER := "auto_waterer"
const ITEM_AUTO_WATERER := "auto_waterer"

static func all_recipe_ids() -> Array[String]:
	return ["auto_waterer"]


static func get_recipe(recipe_id: String) -> Dictionary:
	match recipe_id:
		"auto_waterer":
			return {
				"id": "auto_waterer",
				"display_name": "Auto-Waterer",
				"blueprint_id": BLUEPRINT_AUTO_WATERER,
				"ingredients": {"wood": 10, "stone": 5, "fiber": 3},
				"output_item_id": ITEM_AUTO_WATERER,
				"output_amount": 1,
			}
		_:
			return {}


static func ingredient_lines(recipe: Dictionary) -> String:
	var parts: PackedStringArray = []
	var ing: Dictionary = recipe.get("ingredients", {}) as Dictionary
	for k in ing.keys():
		parts.append("%s x%d" % [str(k), int(ing[k])])
	return ", ".join(parts)
