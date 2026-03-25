extends RefCounted
class_name InventoryItemIcons

## Central 32×/16× slices for hotbar icons — avoids stretching whole tile sheets into one slot.

const _MAPLE: Texture2D = preload("res://assets/tilesets/Maple Tree.png")
const _ROAD: Texture2D = preload("res://assets/tilesets/Road copiar.png")

const _POTATO_SEED: Texture2D = preload("res://assets/sprites/potato/Spring Crops_0001.png")
const _POTATO: Texture2D = preload("res://assets/sprites/potato/Spring Crops_0007.png")
const _FIBER: Texture2D = preload("res://assets/sprites/potato/Spring Crops_0005.png")
const _WATER_PROPS: Texture2D = preload("res://assets/tilesets/Water props.png")


static func _slice(tex: Texture2D, region: Rect2i) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = region
	return a


static func build_icon_map() -> Dictionary:
	# Maple Tree.png (160×48): five 32×48 growth stages left→right; use stump as “wood”.
	var wood_icon: AtlasTexture = _slice(_MAPLE, Rect2i(128, 0, 32, 48))
	# Road copiar.png (80×64): 16×16 grid of path/pebble tiles; one grey stone-like cell.
	var stone_icon: AtlasTexture = _slice(_ROAD, Rect2i(32, 16, 16, 16))
	var auto_water_icon: AtlasTexture = _slice(_WATER_PROPS, Rect2i(0, 0, 16, 16))

	return {
		"potato_seed": _POTATO_SEED,
		"potato": _POTATO,
		"wood": wood_icon,
		"stone": stone_icon,
		"fiber": _FIBER,
		"auto_waterer": auto_water_icon,
	}
