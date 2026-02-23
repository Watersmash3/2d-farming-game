extends CharacterBody2D


@export var speed := 180.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_dir: Vector2 = Vector2.DOWN
var is_swinging: bool = false
var facing_dir: Vector2 = Vector2.DOWN

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if Input.is_action_just_pressed("interact"):
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
	var left: bool = dir.x < 0.1
	var right: bool = dir.x > 0.1

	if is_swinging:
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
				anim ="idle_angle"
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

func _on_animation_finished() -> void:
	if sprite.animation == "hoe_swing":
		is_swinging = false
