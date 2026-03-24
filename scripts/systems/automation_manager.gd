extends Node
class_name AutomationManager
## Tracks placed machines and runs their daily behavior after FarmingSystem handles day rollover.
## Node order: place this node after FarmingSystem so day_advanced fires farming first, then automation.

@export var farming_path: NodePath
@export var machines_root_path: NodePath
@export var auto_waterer_scene: PackedScene

var _farming: FarmingSystem
var _machines_root: Node2D
var _machines_by_cell: Dictionary = {} # Vector2i -> AutomationMachine


func _ready() -> void:
	_farming = get_node(farming_path) as FarmingSystem
	_machines_root = get_node(machines_root_path) as Node2D
	assert(_farming != null, "AutomationManager: invalid farming_path")
	assert(_machines_root != null, "AutomationManager: invalid machines_root_path")
	TimeSystem.day_advanced.connect(_on_day_advanced)


func is_cell_occupied(cell: Vector2i) -> bool:
	return _machines_by_cell.has(cell)


func _on_day_advanced(new_day: int, _old_day: int) -> void:
	for cell: Vector2i in _machines_by_cell.keys():
		var m: AutomationMachine = _machines_by_cell[cell] as AutomationMachine
		if m != null and is_instance_valid(m):
			m.on_daily_tick(_farming, new_day)


func try_place_auto_waterer(cell: Vector2i) -> bool:
	if is_cell_occupied(cell):
		print("AutomationManager: placement blocked — machine already at ", cell)
		return false
	if not _farming.is_cell_tilled(cell):
		print("AutomationManager: placement blocked — untilled cell ", cell)
		return false
	if auto_waterer_scene == null:
		push_error("AutomationManager: auto_waterer_scene not assigned")
		return false
	var node: Node = auto_waterer_scene.instantiate()
	var inst: AutoWaterer = node as AutoWaterer
	if inst == null:
		push_error("AutomationManager: scene root must be AutoWaterer")
		node.queue_free()
		return false
	inst.grid_cell = cell
	_machines_root.add_child(inst)
	inst.global_position = _farming.get_cell_world_center(cell)
	register_machine(inst)
	print("AutomationManager: placed Auto-Waterer at grid ", cell)
	return true


func register_machine(machine: AutomationMachine) -> void:
	var cell: Vector2i = machine.grid_cell
	_machines_by_cell[cell] = machine
	if not machine.tree_exiting.is_connected(_on_machine_tree_exiting):
		machine.tree_exiting.connect(_on_machine_tree_exiting.bind(cell))


func _on_machine_tree_exiting(cell: Vector2i) -> void:
	_machines_by_cell.erase(cell)
