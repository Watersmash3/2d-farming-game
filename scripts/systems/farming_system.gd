extends Node
class_name FarmingSystem

## Emitted after a successful mature harvest (before cell state is cleared).
signal crop_harvested(crop_id: String, cell: Vector2i)

# --- Assign in inspector (World.tscn)
@export var farm_tilemap_path: NodePath
@export var crops_layer_path: NodePath

@onready var farm_map: TileMapLayer = get_node(farm_tilemap_path)
@onready var crops_layer: Node2D = get_node(crops_layer_path)

# Atlas coordinates for farm tiles
@export var tile_source_id: int = 0
const ATLAS_TILLED := Vector2i(0, 0) # correlating to the base tiles grid
const ATLAS_WATERED := Vector2i(1, 0) # correlating to the base tiles grid

# Will be used in the future
const ATLAS_DIRT := Vector2i(2, 0) # correlating to the base tiles grid

# --- Crop visuals: assign one CropSpriteSheet resource per crop in the Inspector.
# Each resource holds the PNG + frame_width + frame_height. Frames are sliced at runtime.
@export var potato_sheet:     CropSpriteSheet
@export var carrot_sheet:     CropSpriteSheet
@export var strawberry_sheet: CropSpriteSheet
@export var tomato_sheet:     CropSpriteSheet
@export var corn_sheet:       CropSpriteSheet

# Built in _ready() — maps crop_id -> CropSpriteSheet
var _sheets: Dictionary = {}

# --- Crop definitions
var crop_defs := {
	"potato": {
		"growth_days": 6,
		"stages": 7,
		"seeds_returned_on_harvest": 2,
	},
	"carrot": {
		"growth_days": 4,
		"stages": 5,
		"seeds_returned_on_harvest": 1,
	},
	"strawberry": {
		"growth_days": 8,
		"stages": 6,
		"seeds_returned_on_harvest": 2,
	},
	"tomato": {
		"growth_days": 6,
		"stages": 6,
		"seeds_returned_on_harvest": 1,
	},
	"corn": {
		"growth_days": 10,
		"stages": 7,
		"seeds_returned_on_harvest": 1,
	},
}

## crop_id -> inventory item id consumed when planting (one per plant).
const SEED_ITEM_BY_CROP: Dictionary = {
	"potato":     "potato_seed",
	"carrot":     "carrot_seed",
	"strawberry": "strawberry_seed",
	"tomato":     "tomato_seed",
	"corn":       "corn_seed",
}

# --- Farm state (runtime)
# Key: Vector2i cell
# Value: Dictionary with keys:
# tilled: bool
# watered: bool
# crop_id: String
# age: int (days)
var farm_cells: Dictionary = {}

# Crop sprite lookup by cell so we can update visuals fast
var crop_sprites: Dictionary = {}

func _ready() -> void:
	add_to_group("farming_system")
	assert(farm_map != null, "FarmingSystem: farm_tilemap_path is not set or invalid.")
	assert(crops_layer != null, "FarmingSystem: crops_layer_path is not set or invalid.")
	TimeSystem.day_advanced.connect(_on_day_advanced)

	_sheets = {
		"potato":     potato_sheet,
		"carrot":     carrot_sheet,
		"strawberry": strawberry_sheet,
		"tomato":     tomato_sheet,
		"corn":       corn_sheet,
	}

	if potato_sheet == null:
		push_warning("FarmingSystem: potato_sheet is not set. Crops will not render.")

func till(cell: Vector2i) -> void:
	var d := _get_or_create_cell(cell)
	d["tilled"] = true
	d["watered"] = false
	# Do not destroy crop on till
	farm_cells[cell] = d
	_update_ground_visual(cell)

## Authoritative watering entry point for player tools and automation.
func water(cell: Vector2i) -> void:
	if not _is_tilled(cell): return
	var d := farm_cells[cell] as Dictionary
	d["watered"] = true
	_update_ground_visual(cell)

func plant(cell: Vector2i, crop_id: String) -> void:
	if not _is_tilled(cell): return
	if _has_crop(cell): return
	if not crop_defs.has(crop_id): return

	if SEED_ITEM_BY_CROP.has(crop_id):
		var seed_id: String = str(SEED_ITEM_BY_CROP[crop_id])
		if not InventoryState.remove_item(seed_id, 1):
			return

	var d := farm_cells[cell] as Dictionary
	d["crop_id"] = crop_id
	d["age"] = 0

	_spawn_or_update_crop_sprite(cell)

func harvest(cell: Vector2i) -> bool:
	if not _has_crop(cell): return false
	if not _is_mature(cell): return false

	var harvested_id: String = str(farm_cells[cell].get("crop_id", ""))
	crop_harvested.emit(harvested_id, cell)

	# TODO: route through a pickup/reward service; kept minimal for this milestone.
	if Items.DATA.has(harvested_id):
		InventoryState.add_item(harvested_id, 1)

	var crop_meta: Dictionary = crop_defs.get(harvested_id, {}) as Dictionary
	var seed_return: int = int(crop_meta.get("seeds_returned_on_harvest", 0))
	if seed_return > 0 and SEED_ITEM_BY_CROP.has(harvested_id):
		var seed_item_id: String = str(SEED_ITEM_BY_CROP[harvested_id])
		InventoryState.add_item(seed_item_id, seed_return)

	var d := farm_cells[cell] as Dictionary
	d.erase("crop_id")
	d.erase("age")

	_remove_crop_sprite(cell)
	# ground stays tilled
	_update_ground_visual(cell)
	return true

func clear_water(cell: Vector2i) -> void:
	if not farm_cells.has(cell): return
	var d := farm_cells[cell] as Dictionary
	d["watered"] = false
	_update_ground_visual(cell)

# -------------------------
# Time integration
# -------------------------

func _on_day_advanced(_new_day: int, _old_day: int) -> void:
	for cell in farm_cells.keys():
		var d: Dictionary = farm_cells[cell]

		# Skip cells that aren't tilled
		if d.get("tilled", false) != true:
			continue

		if d.has("crop_id"):
			if d.get("watered", false) == true:
				d["age"] = int(d.get("age", 0)) + 1

			# water resets daily (common farming loop)
			d["watered"] = false
			farm_cells[cell] = d

			_spawn_or_update_crop_sprite(cell)
			_update_ground_visual(cell)
		else:
			# No crop: reset water too
			if d.get("watered", false) == true:
				d["watered"] = false
				farm_cells[cell] = d
				_update_ground_visual(cell)

# -------------------------
# Visuals
# -------------------------

func _update_ground_visual(cell: Vector2i) -> void:
	# If not tilled, clear tile from FarmTileMap
	if not _is_tilled(cell):
		_clear_farm_tile(cell)
		return

	# If watered, set watered tile; else tilled tile
	var watered: bool = farm_cells[cell].get("watered", false)
	if watered:
		_set_farm_tile(cell, ATLAS_WATERED)
	else:
		_set_farm_tile(cell, ATLAS_TILLED)

func _spawn_or_update_crop_sprite(cell: Vector2i) -> void:
	if not _has_crop(cell):
		_remove_crop_sprite(cell)
		return

	var crop_id: String = farm_cells[cell]["crop_id"]
	var age: int = int(farm_cells[cell].get("age", 0))

	var sprite: Sprite2D
	if crop_sprites.has(cell):
		sprite = crop_sprites[cell]
	else:
		sprite = Sprite2D.new()
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		crops_layer.add_child(sprite)
		crop_sprites[cell] = sprite

	# Position sprite pivot at tile center
	sprite.global_position = _cell_to_world_center(cell)

	# Pick stage texture
	var tex := _get_crop_stage_texture(crop_id, age)
	if tex != null:
		sprite.texture = tex
		# Bottom-anchor: shift the texture up so its bottom sits at the tile's
		# bottom edge rather than floating at tile center.
		# offset.y = (tile_h - tex_h) / 2  →  negative when sprite is taller than tile.
		var tile_h: float = float(farm_map.tile_set.tile_size.y)
		var sheet: CropSpriteSheet = _sheets.get(crop_id, null) as CropSpriteSheet
		var tex_h: float = float(sheet._resolved_height()) if sheet != null else float(tex.get_height())
		sprite.offset = Vector2(0.0, (tile_h - tex_h) / 2.0)

func _remove_crop_sprite(cell: Vector2i) -> void:
	if not crop_sprites.has(cell):
		return
	var sprite: Sprite2D = crop_sprites[cell]
	if is_instance_valid(sprite):
		sprite.queue_free()
	crop_sprites.erase(cell)

# -------------------------
# Helpers
# -------------------------

func _get_or_create_cell(cell: Vector2i) -> Dictionary:
	if not farm_cells.has(cell):
		farm_cells[cell] = {"tilled": false, "watered": false}
	return farm_cells[cell]

func _is_tilled(cell: Vector2i) -> bool:
	return farm_cells.has(cell) and farm_cells[cell].get("tilled", false) == true

func _has_crop(cell: Vector2i) -> bool:
	return farm_cells.has(cell) and farm_cells[cell].has("crop_id")

func _is_mature(cell: Vector2i) -> bool:
	if not _has_crop(cell): return false
	var crop_id: String = farm_cells[cell]["crop_id"]
	var age: int = int(farm_cells[cell].get("age", 0))
	var growth_days: int = int(crop_defs[crop_id]["growth_days"])
	return age >= growth_days

func _get_crop_stage_texture(crop_id: String, age: int) -> Texture2D:
	if not _sheets.has(crop_id):
		return null
	var sheet: CropSpriteSheet = _sheets[crop_id] as CropSpriteSheet
	if sheet == null:
		return null
	if not crop_defs.has(crop_id):
		return null

	var stages: int = int(crop_defs[crop_id]["stages"])
	var total_frames: int = sheet.frame_count()
	var stage_index: int = clamp(mini(age, stages - 1), 0, total_frames - 1)
	return sheet.get_frame(stage_index)

func get_cell_world_center(cell: Vector2i) -> Vector2:
	return _cell_to_world_center(cell)


## Tilled farm tile with no crop; used for machine anchors.
func is_valid_machine_cell(cell: Vector2i) -> bool:
	return _is_tilled(cell) and not _has_crop(cell)

## Public read of tilled state; used by automation machines.
func is_cell_tilled(cell: Vector2i) -> bool:
	return _is_tilled(cell)

## Public read of crop presence; used by automation machines.
func cell_has_crop(cell: Vector2i) -> bool:
	return _has_crop(cell)

## Public read of crop maturity; used by AutoHarvester.
func is_cell_mature(cell: Vector2i) -> bool:
	return _is_mature(cell)

## Public read of watered state; used by AutoSeeder.
func is_cell_watered(cell: Vector2i) -> bool:
	return farm_cells.has(cell) and farm_cells[cell].get("watered", false) == true


func _cell_to_world_center(cell: Vector2i) -> Vector2:
	# Convert map cell to global position for tile center
	var local_center: Vector2 = farm_map.map_to_local(cell)
	return farm_map.to_global(local_center)

func _set_farm_tile(cell: Vector2i, atlas_coords: Vector2i) -> void:
	# set_cell(coords, source_id, atlas_coords, alternative_tile)
	# atlas_coords specifies which tile in the atlas to use
	# If you're using atlas coords, you’ll change this function (see note below).
	farm_map.set_cell(cell, tile_source_id, atlas_coords, 0)

func _clear_farm_tile(cell: Vector2i) -> void:
	farm_map.erase_cell(cell)
