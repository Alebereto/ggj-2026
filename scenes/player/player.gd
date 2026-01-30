extends CharacterBody3D

const SPEED = 5.0
const CAMERA_SPEED = 2.2
const JUMP_VELOCITY = 4.5

@onready var _animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var _model: Node3D = $Model
@onready var _camera: Camera3D = $CameraRoot/Camera3D
@onready var _camera_root: Node3D = $CameraRoot

@export var _num_build_masks: int = 10
@export var _num_destroy_masks: int = 10

var _input_dir: Vector2
var _camera_direction: int

func _physics_process(delta: float) -> void:
	_get_inputs()
	_move_camera(delta)
	_move(delta)

func _get_inputs() -> void:
	_input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_camera_direction = 0
	if Input.is_action_pressed("camera_rotate_right"): _camera_direction += 1
	if Input.is_action_pressed("camera_rotate_left"): _camera_direction -= 1


func _move_camera(delta: float) -> void:
	_camera_root.rotate_y(CAMERA_SPEED * delta * _camera_direction)

func _move(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction := Vector3.ZERO
	if _camera != null and _input_dir != Vector2.ZERO:
		# Get camera's forward and right vectors, flattened to the horizontal plane
		var camera_right = _camera.global_transform.basis.x.slide(Vector3.UP).normalized()
		var camera_forward = _camera.global_transform.basis.z.slide(Vector3.UP).normalized()
		
		# Combine input with camera vectors to get movement direction
		direction = camera_right * _input_dir.x + camera_forward * _input_dir.y
		direction = direction.normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if direction:
		var vec = Vector3(velocity.x, 0, velocity.z).normalized()
		_model.rotation.y = atan2(vec.x, vec.z)
	
	if velocity.length() > 2.0:
		_animation_player.play("walk")
	move_and_slide()


