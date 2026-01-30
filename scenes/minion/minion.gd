extends CharacterBody3D

@export var move_speed = 5.0
@export var rotation_speed = 1.0
@export var min_rotation_time = 0.0
@export var max_rotation_time = 1.0
@export var min_stop_time = 0.0
@export var max_stop_time = 5.0
@export var min_move_time = 2.0
@export var max_move_time = 6.0
var rotation_time
var rotating = false
var moving = true
var direction
var rng = RandomNumberGenerator.new()

func _physics_process(delta: float) -> void:
	var remaining_rotation_time = 0
	if rotating:
		rotation_time -= delta
		if rotation_time <= 0:
			rotation.y += (delta+rotation_time)*direction*rotation_speed
			remaining_rotation_time = -rotation_time
			rotating = false
	if not rotating:
		direction = [1, -1][rng.randi_range(0, 1)]
		rotating = true
		rotation_time = rng.randf_range(min_rotation_time, max_rotation_time)
	rotation.y += (delta-remaining_rotation_time)*direction*rotation_speed
	move_and_slide()
