extends CharacterBody2D


@export var SPEED := 180.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_dir: Vector2 = Vector2.DOWN

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	velocity = input_dir * SPEED
	move_and_slide()

	if input_dir.length() > 0.1:
		last_dir = input_dir.normalized()

	_update_animation(input_dir)

func _update_animation(input_dir: Vector2) -> void:
	var moving := input_dir.length() > 0.1
	var dir
	if moving:
		dir = input_dir
	else:
		dir = last_dir

	var is_diag: bool = abs(dir.x) > 0.4 and abs(dir.y) > 0.4
	
	var want_flip_h := false
	var anim := ""

	if is_diag:
		if moving:
			anim = "walk_angle"
		else:
			anim = "idle_angle"
		want_flip_h = dir.x < 0
	else:
		if dir.y < 0:
			if moving:
				anim = "walk_up"
			else:
				anim = "idle_back"
		else:
			if moving:
				anim = "walk_down"
			else:
				anim = "idle"

		want_flip_h = false

	sprite.flip_h = want_flip_h

	if sprite.animation != anim:
		sprite.play(anim)
	elif not moving:
		pass
