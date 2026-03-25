extends Node

## Central blueprint / milestone flags. TODO: replace debug keys with quests, tech tree, or save data.

signal blueprint_unlocked(blueprint_id: String)

const HARVESTS_TO_UNLOCK_AUTO_WATERER: int = 3

var _blueprints_unlocked: Dictionary = {}  # blueprint_id -> bool
var _total_harvests: int = 0


func _ready() -> void:
	call_deferred("_connect_farming_harvests")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# TODO: remove or gate behind dev build flag for shipping
		if event.keycode == KEY_F9:
			unlock_blueprint(CraftingRecipes.BLUEPRINT_AUTO_WATERER, "debug_key_f9")


func _connect_farming_harvests() -> void:
	for n: Node in get_tree().get_nodes_in_group("farming_system"):
		if n.has_signal("crop_harvested"):
			n.crop_harvested.connect(_on_crop_harvested)


func _on_crop_harvested(_crop_id: String, _cell: Vector2i) -> void:
	_total_harvests += 1
	if _total_harvests >= HARVESTS_TO_UNLOCK_AUTO_WATERER:
		unlock_blueprint(CraftingRecipes.BLUEPRINT_AUTO_WATERER, "harvest_milestone_%d" % HARVESTS_TO_UNLOCK_AUTO_WATERER)


func is_blueprint_unlocked(blueprint_id: String) -> bool:
	return _blueprints_unlocked.get(blueprint_id, false) == true


func unlock_blueprint(blueprint_id: String, reason: String = "") -> void:
	if is_blueprint_unlocked(blueprint_id):
		return
	_blueprints_unlocked[blueprint_id] = true
	print("[Progression] Blueprint unlocked: %s (reason: %s)" % [blueprint_id, reason])
	blueprint_unlocked.emit(blueprint_id)


func list_unlocked_blueprints() -> Array[String]:
	var out: Array[String] = []
	for k: Variant in _blueprints_unlocked.keys():
		if _blueprints_unlocked[k] == true:
			out.append(str(k))
	return out
