extends Node2D

@export var chicken_scenes: Array[PackedScene] = []
@export var cow_scenes: Array[PackedScene] = []

@export var spawn_chickens: int = 3
@export var spawn_cows: int = 3

# World area to spawn in
@export var spawn_area_position: Vector2 = Vector2(16, 16)
@export var spawn_area_size: Vector2 = Vector2(320, 320)

@export var min_distance_between_animals: float = 20.0

var _spawned_positions: Array[Vector2] = []

func _ready() -> void:
	randomize()

	_spawn_random_from_array(chicken_scenes, spawn_chickens)
	_spawn_random_from_array(cow_scenes, spawn_cows)

func _spawn_random_from_array(scene_array: Array[PackedScene], count: int) -> void:
	if scene_array.is_empty():
		return

	var valid_scenes: Array[PackedScene] = []
	for s in scene_array:
		if s != null:
			valid_scenes.append(s)

	if valid_scenes.is_empty():
		return

	for i in count:
		var chosen_scene: PackedScene = valid_scenes[randi() % valid_scenes.size()]
		_spawn_one(chosen_scene)

func _spawn_one(scene: PackedScene) -> void:
	var animal := scene.instantiate() as Node2D
	if animal == null:
		return

	var spawn_pos := _find_spawn_position()

	add_child(animal)
	animal.global_position = spawn_pos

	# If this animal uses shared animal.gd script, sync its home after placement
	if animal.has_method("set_home_position"):
		animal.call("set_home_position", spawn_pos)

func _find_spawn_position() -> Vector2:
	var tries := 30

	while tries > 0:
		tries -= 1
		var p := Vector2(
			randf_range(spawn_area_position.x, spawn_area_position.x + spawn_area_size.x),
			randf_range(spawn_area_position.y, spawn_area_position.y + spawn_area_size.y)
		)

		var too_close := false
		for existing in _spawned_positions:
			if existing.distance_to(p) < min_distance_between_animals:
				too_close = true
				break

		if not too_close:
			_spawned_positions.append(p)
			return p

	# Fallback if crowded
	var fallback := spawn_area_position + spawn_area_size * 0.5
	_spawned_positions.append(fallback)
	return fallback
