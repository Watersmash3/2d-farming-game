extends Node2D

const AUTO_WATERER_SCENE:  PackedScene = preload("res://scenes/automation/AutoWaterer.tscn")
const AUTO_SEEDER_SCENE:   PackedScene = preload("res://scenes/automation/AutoSeeder.tscn")
const AUTO_HARVESTER_SCENE: PackedScene = preload("res://scenes/automation/AutoHarvester.tscn")
const AUTO_TILLER_SCENE:   PackedScene = preload("res://scenes/automation/AutoTiller.tscn")

# Maps placeable machine item IDs to their scenes
const MACHINE_SCENES: Dictionary = {
	"auto_waterer":  AUTO_WATERER_SCENE,
	"auto_seeder":   AUTO_SEEDER_SCENE,
	"auto_harvester": AUTO_HARVESTER_SCENE,
	"auto_tiller":   AUTO_TILLER_SCENE,
}

# Maps seed item IDs to crop IDs for the plant tool
const SEED_TO_CROP: Dictionary = {
	"potato_seed":     "potato",
	"carrot_seed":     "carrot",
	"strawberry_seed": "strawberry",
	"tomato_seed":     "tomato",
	"corn_seed":       "corn",
}

# Time speed presets (seconds per tick)
const TIME_SPEEDS: Array[float] = [0.5, 0.25, 0.1]
const TIME_SPEED_LABELS: Array[String] = ["Slow (0.5s)", "Normal (0.25s)", "Fast (0.1s)"]
var _time_speed_index: int = 1


func _seed_to_crop(item_id: String) -> String:
	return SEED_TO_CROP.get(item_id, "")


@onready var farming: FarmingSystem = $FarmingSystem
@onready var farm_map: TileMapLayer = $FarmTileMap
@onready var machines_root: Node2D = $Machines
@onready var placement_preview: Sprite2D = $PlacementPreview
@onready var crafting_menu: CanvasLayer = $CraftingMenu

var tool: int = 1
# 1 hoe, 2 water, 3 plant, 4 harvest

var machine_placement_active: bool = false
var _pending_machine_item: String = ""  # item id being placed


func _ready() -> void:
	placement_preview.visible = false
	placement_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Part 4: pause time when crafting menu opens
	crafting_menu.visibility_changed.connect(_on_menu_visibility_changed)
	# Start time flowing
	TimeSystem.set_paused(false)


func _on_menu_visibility_changed() -> void:
	TimeSystem.set_paused(crafting_menu.visible)


func _process(_delta: float) -> void:
	if not machine_placement_active:
		placement_preview.visible = false
		return
	var mouse_world: Vector2 = get_global_mouse_position()
	var cell: Vector2i = farm_map.local_to_map(farm_map.to_local(mouse_world))
	placement_preview.global_position = farming.get_cell_world_center(cell)
	var ok: bool = AutomationManager.can_place_machine_at(cell, farming)
	placement_preview.modulate = Color(0.35, 1.0, 0.45, 0.72) if ok else Color(1.0, 0.32, 0.32, 0.75)
	placement_preview.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: tool = 1
			KEY_2: tool = 2
			KEY_3: tool = 3
			KEY_4: tool = 4
			KEY_N:
				TimeSystem.advance_day()
				print("[Time] Advanced to day ", TimeSystem.get_current_day())
			KEY_T:
				_cycle_time_speed()
			KEY_U:
				_try_upgrade_machine_at_cursor()

	if event.is_action_pressed("place_machine"):
		_try_begin_machine_placement()

	if event.is_action_pressed("cancel_placement"):
		if machine_placement_active:
			machine_placement_active = false
			placement_preview.visible = false
			print("[Placement] Cancelled")

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if machine_placement_active:
			if _ui_is_blocking_mouse():
				return
			_try_confirm_machine_placement()
			return

		if _ui_is_blocking_mouse():
			return

		var mouse_world: Vector2 = get_global_mouse_position()
		var cell: Vector2i = farm_map.local_to_map(farm_map.to_local(mouse_world))

		match tool:
			1:
				farming.till(cell)
			2:
				farming.water(cell)
			3:
				var crop := _seed_to_crop(InventoryState.selected_item_id)
				if crop != "":
					farming.plant(cell, crop)
				else:
					print("[Plant] Select a seed in the hotbar (I) first.")
			4:
				farming.harvest(cell)


# ---------------------------------------------------------------------------
# Machine placement — works for any item in MACHINE_SCENES
# ---------------------------------------------------------------------------

func _try_begin_machine_placement() -> void:
	var sel: String = InventoryState.selected_item_id
	if sel == "" or not MACHINE_SCENES.has(sel):
		# Fall back: find the first machine item the player has
		for item_id: String in MACHINE_SCENES.keys():
			if InventoryState.get_count(item_id) > 0:
				sel = item_id
				break
	if sel == "" or not MACHINE_SCENES.has(sel) or InventoryState.get_count(sel) <= 0:
		print("[Placement] No placeable machine in inventory. Craft one first.")
		return
	_pending_machine_item = sel
	machine_placement_active = true
	placement_preview.visible = true
	print("[Placement] %s mode — LMB valid tile, Esc / RMB cancel" % sel)


func _try_confirm_machine_placement() -> void:
	var mouse_world: Vector2 = get_global_mouse_position()
	var cell: Vector2i = farm_map.local_to_map(farm_map.to_local(mouse_world))
	if not AutomationManager.can_place_machine_at(cell, farming):
		print("[Placement] Invalid cell %s (need empty tilled tile, no machine)" % str(cell))
		return
	if not InventoryState.remove_item(_pending_machine_item, 1):
		machine_placement_active = false
		return
	var scene: PackedScene = MACHINE_SCENES[_pending_machine_item] as PackedScene
	var m: Node = scene.instantiate()
	if m is AutomationMachine:
		(m as AutomationMachine).setup(farming, cell)
	machines_root.add_child(m)
	print("[Placement] Placed %s at %s" % [_pending_machine_item, str(cell)])
	machine_placement_active = false
	placement_preview.visible = false
	_pending_machine_item = ""


# ---------------------------------------------------------------------------
# Machine upgrade — press U while hovering a placed machine's cell
# ---------------------------------------------------------------------------

func _try_upgrade_machine_at_cursor() -> void:
	var mouse_world: Vector2 = get_global_mouse_position()
	var cell: Vector2i = farm_map.local_to_map(farm_map.to_local(mouse_world))
	var machine := AutomationManager.get_machine_at(cell)
	if machine == null:
		print("[Upgrade] No machine at cursor cell %s" % str(cell))
		return
	machine.try_upgrade()


# ---------------------------------------------------------------------------
# Time speed cycling — press T
# ---------------------------------------------------------------------------

func _cycle_time_speed() -> void:
	_time_speed_index = (_time_speed_index + 1) % TIME_SPEEDS.size()
	TimeSystem.set_tick_speed(TIME_SPEEDS[_time_speed_index])
	print("[Time] Speed: %s" % TIME_SPEED_LABELS[_time_speed_index])


func _ui_is_blocking_mouse() -> bool:
	# While crafting is open, ignore farm/placement LMB (UI buttons still receive clicks first).
	return crafting_menu != null and crafting_menu.visible
