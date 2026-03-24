extends Node
## Central blueprint unlock state and simple milestones (e.g. harvest count).
## TODO: Quest hooks, save/load, tech tree, per-save profile instead of singleton defaults.

signal blueprint_unlocked(blueprint_id: String)

const HARVESTS_TO_UNLOCK_AUTO_WATERER: int = 3

var _unlocked_blueprints: Dictionary = {} # String -> bool
var _total_harvests: int = 0


func _ready() -> void:
	call_deferred("_connect_farming_signals")


func _connect_farming_signals() -> void:
	var farming: Node = get_tree().get_first_node_in_group("farming_system")
	if farming == null:
		push_warning("ProgressionManager: no node in group 'farming_system'. Harvest milestone inactive.")
		return
	if farming.has_signal("crop_harvested"):
		farming.crop_harvested.connect(_on_crop_harvested)


func get_total_harvests() -> int:
	return _total_harvests


func is_blueprint_unlocked(blueprint_id: String) -> bool:
	return _unlocked_blueprints.get(blueprint_id, false) == true


func unlock_blueprint(blueprint_id: String) -> void:
	if is_blueprint_unlocked(blueprint_id):
		return
	_unlocked_blueprints[blueprint_id] = true
	print("ProgressionManager: blueprint unlocked — ", blueprint_id)
	blueprint_unlocked.emit(blueprint_id)


func _on_crop_harvested(_cell: Vector2i) -> void:
	_total_harvests += 1
	print("ProgressionManager: total harvests = ", _total_harvests)
	if _total_harvests >= HARVESTS_TO_UNLOCK_AUTO_WATERER:
		if not is_blueprint_unlocked(AutomationRecipes.BLUEPRINT_AUTO_WATERER):
			unlock_blueprint(AutomationRecipes.BLUEPRINT_AUTO_WATERER)
