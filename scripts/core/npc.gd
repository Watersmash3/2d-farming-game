#This file is based on and modified from this youtube video: https://www.youtube.com/watch?v=LMSbPkNgnWA
extends CharacterBody2D

@onready
var anim := $AnimatedSprite2D
@onready var footsteps: Array[AudioStreamPlayer2D] = [
	$FootstepA, $FootstepB, $FootstepC, $FootstepD
]
var _last_footstep_index := -1
var _footstep_cooldown := 0.0

const speed = 60
var current_state = IDLE

var dir = Vector2.RIGHT
var start_pos

var is_roaming = true
var is_chatting = false

var player
var player_in_chat_zone = false

enum {
	IDLE,
	NEW_DIR,
	MOVE
}

func _ready():
	randomize()
	start_pos = position
	
func _process(delta):
	_footstep_cooldown -= delta
	if current_state == 0 or current_state == 1:
		anim.play("idle")
	elif current_state == 2 and !is_chatting:
		if _footstep_cooldown <= 0.0:
			_play_random_footstep()
			_footstep_cooldown = 0.5
		if dir.x == -1:
			anim.play("walk_angle")
			anim.flip_h = true
		elif dir.x == 1:
			anim.play("walk_angle")
			anim.flip_h = false
		elif dir.y == -1:
			anim.play("walk_up")
		elif dir.y == 1:
			anim.play("walk_down")
	
	if is_roaming:
		match current_state:
			IDLE:
				velocity = Vector2.ZERO
				move_and_slide()
			NEW_DIR:
				velocity = Vector2.ZERO
				move_and_slide()
				dir = choose([Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN])
			MOVE:
				move(delta)
	if Input.is_action_just_pressed("npc_chat") and player_in_chat_zone:
		$Dialogue.start()
		$Dialogue/NinePatchRect2.visible = false
		is_roaming = false
		is_chatting = true
		anim.play("idle")
				
func choose(array):
	array.shuffle()
	return array.front()

func move(delta):
	if !is_chatting:
		velocity = dir * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		

func _play_random_footstep() -> void:
	var index := randi() % footsteps.size()
	if index == _last_footstep_index:
		index = (index + 1) % footsteps.size()
	_last_footstep_index = index
	footsteps[index].pitch_scale = randf_range(0.9, 1.1)
	footsteps[index].play()

func _on_chat_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		player_in_chat_zone = true
		if !is_chatting:
			$Dialogue/NinePatchRect2.visible = true
		else: 
			$Dialogue/NinePatchRect2.visible = false
		

func _on_chat_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_chat_zone = false;
		$Dialogue/NinePatchRect2.visible = false
		

func _on_timer_timeout() -> void:
	$Timer.wait_time = choose([0.5,1,1.5])
	current_state = choose([IDLE,NEW_DIR, MOVE])
	
	
func _on_dialogue_dialogue_finished() -> void:
	is_chatting = false
	is_roaming = true
