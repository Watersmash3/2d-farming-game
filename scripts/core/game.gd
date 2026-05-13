extends Node2D

@export_file("*.tscn") var starting_map_scene: String = "res://scenes/world/Town.tscn"
@export var starting_spawn_name: String = "TownStartSpawn"

@onready var map_container: Node2D = $WorldRoot/MapContainer
@onready var player: CharacterBody2D = $WorldRoot/Player
@onready var day_night_tint: CanvasModulate = $CanvasModulate

var _loaded_maps: Dictionary = {}
var _current_map: Node


func _ready() -> void:
	SceneTransition.game = self
	change_map(starting_map_scene, starting_spawn_name)


func change_map(scene_path: String, spawn_name: String = "") -> void:
	if scene_path.is_empty():
		push_warning("Cannot change to an empty map scene path.")
		return

	if _current_map != null:
		map_container.remove_child(_current_map)

	var map := _get_or_create_map(scene_path)
	if map == null:
		return

	_current_map = map
	if map.get_parent() == null:
		map_container.add_child(map)
	_reset_portals(map)
	_apply_map_lighting(map)

	await get_tree().process_frame
	_move_player_to_spawn(spawn_name)


func _get_or_create_map(scene_path: String) -> Node:
	if _loaded_maps.has(scene_path):
		return _loaded_maps[scene_path]

	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("Could not load map scene: %s" % scene_path)
		return null

	var map := packed_scene.instantiate()
	_loaded_maps[scene_path] = map
	return map


func _move_player_to_spawn(spawn_name: String) -> void:
	if spawn_name.is_empty() or _current_map == null:
		return

	var spawn := _current_map.find_child(spawn_name, true, false) as Node2D
	if spawn == null:
		push_warning("Could not find spawn '%s' in %s." % [spawn_name, _current_map.name])
		return

	player.global_position = spawn.global_position


func _reset_portals(root: Node) -> void:
	if root.has_method("reset_portal"):
		root.reset_portal()

	for child in root.get_children():
		_reset_portals(child)


func _apply_map_lighting(map: Node) -> void:
	if day_night_tint == null or not day_night_tint.has_method("set_day_night_enabled"):
		return

	var is_indoor := bool(map.get_meta("is_indoor", false))
	day_night_tint.set_day_night_enabled(not is_indoor)
