extends Node2D

@export var move_speed: float = 18.0
@export var wander_radius: float = 32.0
@export var pause_time_min: float = 0.5
@export var pause_time_max: float = 1.5
@export var can_wander: bool = true
@export var use_directional_animations: bool = true

# If sprite faces left by default, keep this true.
# If it faces right by default, set false on animal scene.
@export var flip_when_moving_right: bool = true

var _home_position: Vector2
var _target_position: Vector2
var _is_waiting: bool = false
var _wait_timer: float = 0.0

var _last_facing: String = "side"   # "side", "up", "down"
var _last_horizontal_sign: int = -1 # -1 = left, 1 = right

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_home_position = global_position
	_target_position = global_position

	if anim and anim.sprite_frames:
		if anim.sprite_frames.has_animation("idle"):
			anim.play("idle")
		elif anim.sprite_frames.has_animation("walk_side"):
			anim.play("walk_side")

func _process(delta: float) -> void:
	if not can_wander:
		return

	if _is_waiting:
		_play_idle_animation()
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_is_waiting = false
			_pick_new_target()
		return

	var to_target := _target_position - global_position
	var dist := to_target.length()

	if dist <= 2.0:
		_is_waiting = true
		_wait_timer = randf_range(pause_time_min, pause_time_max)
		_play_idle_animation()
		return

	var dir := to_target / dist
	global_position += dir * move_speed * delta
	_update_animation_for_direction(dir)

func _pick_new_target() -> void:
	var offset := Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	_target_position = _home_position + offset
	
func set_home_position(new_home: Vector2) -> void:
	_home_position = new_home
	_target_position = new_home
	global_position = new_home
	_is_waiting = false
	_wait_timer = 0.0
	_pick_new_target()
	
func _update_animation_for_direction(dir: Vector2) -> void:
	if not anim or not anim.sprite_frames:
		return

	# Mostly horizontal movement
	if abs(dir.x) >= abs(dir.y):
		_last_facing = "side"

		if dir.x > 0.05:
			_last_horizontal_sign = 1
		elif dir.x < -0.05:
			_last_horizontal_sign = -1

		if anim.sprite_frames.has_animation("walk_side") and anim.animation != "walk_side":
			anim.play("walk_side")

		_apply_horizontal_flip(_last_horizontal_sign)
		return

	# Mostly vertical movement
	anim.flip_h = false

	if dir.y > 0.0:
		_last_facing = "down"
		if use_directional_animations and anim.sprite_frames.has_animation("walk_down"):
			if anim.animation != "walk_down":
				anim.play("walk_down")
		elif anim.sprite_frames.has_animation("walk_side") and anim.animation != "walk_side":
			anim.play("walk_side")
	else:
		_last_facing = "up"
		if use_directional_animations and anim.sprite_frames.has_animation("walk_up"):
			if anim.animation != "walk_up":
				anim.play("walk_up")
		elif anim.sprite_frames.has_animation("walk_side") and anim.animation != "walk_side":
			anim.play("walk_side")

func _play_idle_animation() -> void:
	if not anim or not anim.sprite_frames:
		return

	if anim.sprite_frames.has_animation("idle"):
		if anim.animation != "idle":
			anim.play("idle")

		# Keep left/right facing while idling
		if _last_facing == "side":
			_apply_horizontal_flip(_last_horizontal_sign)
		else:
			anim.flip_h = false
	else:
		# Fallback if no idle animation exists
		if anim.sprite_frames.has_animation("walk_side") and anim.animation != "walk_side":
			anim.play("walk_side")

		if _last_facing == "side":
			_apply_horizontal_flip(_last_horizontal_sign)
		else:
			anim.flip_h = false

func _apply_horizontal_flip(horizontal_sign: int) -> void:
	if horizontal_sign > 0:
		anim.flip_h = flip_when_moving_right
	else:
		anim.flip_h = not flip_when_moving_right
