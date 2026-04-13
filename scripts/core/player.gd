# Claude AI used throughout this file as tool to help 
# with cleaning, organization, and optimization of basic functions. 
extends CharacterBody2D
@export var speed := 180.0
@export var sprint_multiplier := 2.0
@export var max_stamina := 100.0
#Values per second 
@export var stamina_drain := 20.0   
@export var stamina_regen := 10.0   
#Value in seconds
@export var stamina_regen_delay := 1.0 
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var footsteps: Array[AudioStreamPlayer2D] = [
	$FootstepA, $FootstepB, $FootstepC, $FootstepD
]
@onready var tills: Array[AudioStreamPlayer2D] = [
	$TillA, $TillB, $TillC
]

var last_dir: Vector2 = Vector2.DOWN
var is_swinging: bool = false
var is_sprinting: bool = false
var facing_dir: Vector2 = Vector2.DOWN
var _last_footstep_index := -1
var _last_till_index := -1
var _footstep_cooldown := 0.0
var stamina: float = max_stamina
var _stamina_regen_timer := 0.0

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_footstep_cooldown -= delta

	if Input.is_action_just_pressed("interact"):
		if stamina > 0.0 and stamina > 0.35:
			is_swinging = true
			stamina = max(0.0, stamina - 0.35)
			_stamina_regen_timer = stamina_regen_delay
		

	is_sprinting = Input.is_action_pressed("ui_sprint") and input_dir.length() > 0.1 and stamina > 0.0

	if is_sprinting:
		stamina = max(0.0, stamina - stamina_drain * delta)
		_stamina_regen_timer = stamina_regen_delay
	else:
		if _stamina_regen_timer > 0.0:
			_stamina_regen_timer -= delta
		else:
			stamina = min(max_stamina, stamina + stamina_regen * delta)

	if is_swinging and stamina >= 0:
		velocity = Vector2.ZERO
		stamina = max(0.0, stamina - 0.35)
		if stamina <= 0:
			is_swinging = false
		_stamina_regen_timer = stamina_regen_delay
		

	elif is_sprinting:
		velocity = input_dir * speed * sprint_multiplier
	else:
		velocity = input_dir * speed

	move_and_slide()
	if input_dir.length() > 0.1:
		last_dir = input_dir.normalized()
	_update_animation(input_dir)

func _update_animation(input_dir: Vector2) -> void:
	var moving := input_dir.length() > 0.1
	var dir: Vector2
	if moving:
		dir = input_dir
	else:
		dir = last_dir
	var is_diag: bool = abs(dir.x) > 0.4 and abs(dir.y) > 0.4

	var want_flip_h := false
	var anim := ""
	var up: bool = dir.y < -0.1
	var down: bool = dir.y > 0.1
	var left: bool = dir.x < -0.1
	var right: bool = dir.x > 0.1

	if is_swinging:
		if not is_diag and up:
			anim = "hoe_swing_back"
		elif not is_diag and down:
			anim = "hoe_swing_front"
		else:
			anim = "hoe_swing"
			want_flip_h = dir.x < 0
	elif is_sprinting:
		if is_diag:
			anim = "sprint"
			want_flip_h = dir.x < 0
		elif up:
			anim = "sprint_up"
		elif down:
			anim = "sprint_down"
		elif right:
			anim = "sprint"
		elif left:
			anim = "sprint"
			want_flip_h = true
	elif is_diag:
		if moving:
			anim = "walk_angle"
		else:
			anim = "idle_angle"
		want_flip_h = dir.x < 0
	else:
		if up:
			if moving:
				anim = "walk_up"
			else:
				anim = "idle_back"
		elif down:
			if moving:
				anim = "walk_down"
			else:
				anim = "idle"
		elif right:
			if moving:
				anim = "walk_angle"
			else:
				anim = "idle_angle"
		elif left:
			want_flip_h = true
			if moving:
				anim = "walk_angle"
			else:
				anim = "idle_angle"

	sprite.flip_h = want_flip_h
	if sprite.animation != anim:
		sprite.play(anim)

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)

	# Starter seeds — more come from harvest. TODO: move to new-game / difficulty config.
	InventoryState.add_item("potato_seed", 10)
	InventoryState.add_item("carrot_seed", 5)
	InventoryState.add_item("strawberry_seed", 5)
	InventoryState.add_item("tomato_seed", 5)
	InventoryState.add_item("corn_seed", 5)
	# TODO: starter bundles should come from game config / new-game flow, not the player node.
	InventoryState.add_item("wood", 24)
	InventoryState.add_item("stone", 12)
	InventoryState.add_item("fiber", 6)

func _on_frame_changed() -> void:
	var walk_anims := ["walk_up", "walk_down", "walk_angle"]
	var sprint_anims := ["sprint_up", "sprint_down", "sprint"]
	if sprite.animation not in walk_anims and sprite.animation not in sprint_anims:
		return
	if _footstep_cooldown <= 0.0:
		_play_random_footstep()
		if sprite.animation in sprint_anims:
			_footstep_cooldown = 0.55
		else:
			_footstep_cooldown = 0.5

func _play_random_footstep() -> void:
	var index := randi() % footsteps.size()
	if index == _last_footstep_index:
		index = (index + 1) % footsteps.size()
	_last_footstep_index = index
	footsteps[index].pitch_scale = randf_range(0.9, 1.1)
	footsteps[index].play()

func _play_random_till() -> void:
	var index := randi() % tills.size()
	if index == _last_till_index:
		index = (index + 1) % tills.size()
	_last_till_index = index
	tills[index].pitch_scale = randf_range(0.9, 1.1)
	tills[index].play()

func _on_animation_finished() -> void:
	if sprite.animation in ["hoe_swing", "hoe_swing_back", "hoe_swing_front"]:
		_play_random_till()
		is_swinging = false
		var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		_update_animation(input_dir)

func get_facing_cell_offset() -> Vector2i:
	if abs(facing_dir.x) > abs(facing_dir.y):
		return Vector2i(1, 0) if facing_dir.x > 0 else Vector2i(-1, 0)
	else:
		return Vector2i(0, 1) if facing_dir.y > 0 else Vector2i(0, -1)
