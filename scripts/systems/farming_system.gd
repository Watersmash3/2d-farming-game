extends Node
class_name FarmingSystem

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

# --- Crop visuals: stage textures
@export var potato_stage_textures: Array[Texture2D] = []

# --- Crop definitions
var crop_defs := {
	"potato": {
		"growth_days": 7,
		"stages": 7
	}
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
	assert(farm_map != null, "FarmingSystem: farm_tilemap_path is not set or invalid.")
	assert(crops_layer != null, "FarmingSystem: crops_layer_path is not set or invalid.")
	TimeSystem.day_advanced.connect(_on_day_advanced)

	if potato_stage_textures.size() == 0:
		push_warning("No potato_stage_textures set. Crop will not render stages.")

func till(cell: Vector2i) -> void:
	var d := _get_or_create_cell(cell)
	d["tilled"] = true
	d["watered"] = false
	# Do not destroy crop on till
	farm_cells[cell] = d
	_update_ground_visual(cell)

func water(cell: Vector2i) -> void:
	if not _is_tilled(cell): return
	var d := farm_cells[cell] as Dictionary
	d["watered"] = true
	_update_ground_visual(cell)

func plant(cell: Vector2i, crop_id: String) -> void:
	if not _is_tilled(cell): return
	if _has_crop(cell): return
	if not crop_defs.has(crop_id): return

	var d := farm_cells[cell] as Dictionary
	d["crop_id"] = crop_id
	d["age"] = 0

	_spawn_or_update_crop_sprite(cell)

func harvest(cell: Vector2i) -> bool:
	if not _has_crop(cell): return false
	if not _is_mature(cell): return false

	# TODO: Inventory
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
		crops_layer.add_child(sprite)
		crop_sprites[cell] = sprite

	# Position sprite at tile center
	sprite.global_position = _cell_to_world_center(cell)

	# Pick stage texture
	var tex := _get_crop_stage_texture(crop_id, age)
	if tex != null:
		sprite.texture = tex

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
	# For now just handle potato
	if crop_id != "potato":
		return null

	if potato_stage_textures.size() == 0:
		return null

	var growth_days: int = int(crop_defs[crop_id]["growth_days"])
	var stages: int = int(crop_defs[crop_id]["stages"])

	# Map age -> stage index [0..stages-1]
	# age 0 => stage 0, mature => last stage
	var stage_index := mini(age, stages - 1)

	stage_index = clamp(stage_index, 0, min(stages - 1, potato_stage_textures.size() - 1))
	return potato_stage_textures[stage_index]

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
