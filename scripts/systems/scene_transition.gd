extends Node

var game: Node


func change_scene(scene_path: String, spawn_name: String = "") -> bool:
	if game != null and game.has_method("change_map"):
		return game.change_map(scene_path, spawn_name)

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Could not change scene to %s. Error: %d" % [scene_path, err])
		return false
	return true
