extends RefCounted
class_name InventoryItemIcons

## Central icon map for the hotbar. All new crop sheets are loaded at runtime
## (not preload) so missing imports never cause a parser error.

const _MAPLE:       Texture2D = preload("res://assets/tilesets/Maple Tree.png")
const _ROAD:        Texture2D = preload("res://assets/tilesets/Road copiar.png")
const _POTATO_SEED: Texture2D = preload("res://assets/sprites/potato/Spring Crops_0001.png")
const _POTATO:      Texture2D = preload("res://assets/sprites/potato/Spring Crops_0007.png")
const _FIBER:       Texture2D = preload("res://assets/sprites/potato/Spring Crops_0005.png")
const _WATER_PROPS: Texture2D = preload("res://assets/tilesets/Water props.png")


static func build_icon_map() -> Dictionary:
	# --- existing icons ---
	var wood_icon := AtlasTexture.new()
	wood_icon.atlas = _MAPLE
	wood_icon.region = Rect2(128, 0, 32, 48)

	var stone_icon := AtlasTexture.new()
	stone_icon.atlas = _ROAD
	stone_icon.region = Rect2(32, 16, 16, 16)

	var auto_water_icon := AtlasTexture.new()
	auto_water_icon.atlas = _WATER_PROPS
	auto_water_icon.region = Rect2(0, 0, 16, 16)

	# --- new crop sheets (runtime load — safe if not yet imported) ---
	# Icons use the first frame as the seed and the last frame as the harvest item.
	# frame_w assumes 16 px per stage; update if your sheets use a different size.
	var icon_map: Dictionary = {
		"potato_seed":  _POTATO_SEED,
		"potato":       _POTATO,
		"wood":         wood_icon,
		"stone":        stone_icon,
		"fiber":        _FIBER,
		"auto_waterer": auto_water_icon,
	}

	var crop_sheets: Dictionary = {
		"carrot":     "res://assets/sprites/Farm Crops/Spring/Carrot.png",
		"strawberry": "res://assets/sprites/Farm Crops/Spring/Strawberry.png",
		"tomato":     "res://assets/sprites/Farm Crops/Summer/Tomato.png",
		"corn":       "res://assets/sprites/Farm Crops/Summer/Corn.png",
	}

	for crop_id: String in crop_sheets:
		var path: String = crop_sheets[crop_id]
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if tex == null:
			continue

		var frame_w: int = 16
		var h: int = tex.get_height()
		var total_frames: int = tex.get_width() / frame_w

		var seed_icon := AtlasTexture.new()
		seed_icon.atlas = tex
		seed_icon.region = Rect2(0, 0, frame_w, h)

		var harvest_icon := AtlasTexture.new()
		harvest_icon.atlas = tex
		harvest_icon.region = Rect2((total_frames - 1) * frame_w, 0, frame_w, h)

		icon_map[crop_id + "_seed"] = seed_icon
		icon_map[crop_id]           = harvest_icon

	return icon_map
