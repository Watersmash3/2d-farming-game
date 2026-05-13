extends Area2D
class_name DoorPortal

@export_file("*.tscn") var destination_scene: String
@export var destination_spawn_name: String = "EntranceSpawn"
@export var requires_interact: bool = false

var _player_in_range: Node2D
var _is_transitioning: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not requires_interact:
		return
	if _player_in_range == null or _is_transitioning:
		return
	if Input.is_action_just_pressed("interact"):
		_transition()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_player_in_range = body
	if not requires_interact:
		_transition()


func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null


func _transition() -> void:
	if _is_transitioning:
		return
	if destination_scene.is_empty():
		push_warning("%s has no destination_scene set." % name)
		return

	_is_transitioning = true
	monitoring = false
	var ok := SceneTransition.change_scene(destination_scene, destination_spawn_name)
	if not ok:
		_is_transitioning = false
		monitoring = true


func reset_portal() -> void:
	_player_in_range = null
	_is_transitioning = false
	monitoring = true
