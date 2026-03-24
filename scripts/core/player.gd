extends CharacterBody2D
@export var speed := 180.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var footsteps: Array[AudioStreamPlayer2D] = [
	$FootstepA, $FootstepB, $FootstepC, $FootstepD
]
@onready var tills: Array[AudioStreamPlayer2D] = [
	$TillA, $TillB, $TillC
]

var last_dir: Vector2 = Vector2.DOWN
var is_swinging: bool = false
var facing_dir: Vector2 = Vector2.DOWN
var _last_footstep_index := -1
var _last_till_index := -1
var _footstep_cooldown := 0.0

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_footstep_cooldown -= _delta
	
	if Input.is_action_just_pressed("interact") and not is_swinging:
		is_swinging = true
	if is_swinging:
		velocity = Vector2.ZERO
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

func _on_frame_changed() -> void:
	var walk_anims := ["walk_up", "walk_down", "walk_angle"]
	

	if sprite.animation not in walk_anims:
		return
	if _footstep_cooldown <= 0.0:
		_play_random_footstep()
		_footstep_cooldown = 0.5
	

func _play_random_footstep() -> void:
	var index := randi() % footsteps.size()
	# Re-roll once if we got the same clip as last time
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
