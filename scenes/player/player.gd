class_name Player extends CharacterBody3D

# destination is global
signal throw_mask(mask_type: Mask.TYPE, starting_pos: Vector3, destination_pos: Vector3)
signal new_masks_count(builders: int, destroyers: int)
signal command_minion(mask_type: Mask.TYPE, global_destination: Vector3)

const PLAYER_SPEED = 5.0
const CAMERA_SPEED = 2.2
const JUMP_VELOCITY = 0.0

const THROW_HEIGHT = 0.6

const ACTION_ANIMATION_LAST_TIME = 0.4

enum CONTROL_MODE {
	NONE,
	BUILDERS,
	DESTROYERS,
	VACUUM
}

var _current_mode: CONTROL_MODE = CONTROL_MODE.NONE

@onready var _pointer = $Pointer

@onready var _pickup_area: Area3D = $PickupArea

# model nodes
@onready var _animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var _model: Node3D = $Model
# camera nodes
@onready var _camera_root: Node3D = $CameraRoot
@onready var _camera: Camera3D = $CameraRoot/Camera3D
@onready var _ray_cast: RayCast3D = $CameraRoot/Camera3D/RayCast3D
# sounds
@onready var _throw_sound: AudioStreamPlayer3D = $Sounds/ThrowMask
@onready var _pickup_sound: AudioStreamPlayer3D = $Sounds/PickupMask

# Player values
var _num_build_masks: int = 5
var _num_destroy_masks: int = 5
func _set_build_masks(count: int) -> void:
	_num_build_masks = count
	new_masks_count.emit(_num_build_masks, _num_destroy_masks)
func _set_destroy_masks(count: int) -> void:
	_num_destroy_masks = count
	new_masks_count.emit(_num_build_masks, _num_destroy_masks)

var _time_since_last_throw := 10000000000.0
var _time_since_last_command := 10000000000.0

func _ready():
	_pickup_area.body_entered.connect(_pickup_area_entered)


func _physics_process(delta: float) -> void:
	if Globals.during_cutscene: return
	# update timers
	_time_since_last_throw += delta
	_time_since_last_command += delta

	_move_camera(delta)
	_move_player(delta)
	Globals.player_position = global_position
	_move_pointer(delta)
	_get_mode()
	_get_action()


func _throw_mask(mask: Mask.TYPE):
	_time_since_last_throw = 0.0

	# get throw direction for rotating model angle
	var direction = global_position.direction_to(_pointer.global_position)
	_model.rotation.y = atan2(direction.x, direction.z)

	# play throw animation
	if _animation_player.is_playing(): _animation_player.stop()
	_animation_player.play("attack-melee-right")

	# get source and destination positions
	var throw_dest = _pointer.global_position
	throw_dest.y = THROW_HEIGHT
	var source_dest = global_position
	source_dest.y = THROW_HEIGHT

	match mask:
		Mask.TYPE.BUILDER:
			if _num_build_masks > 0:
				# play throw sound
				_throw_sound.play()

				throw_mask.emit(mask, source_dest , throw_dest)
				_set_build_masks(_num_build_masks - 1)
		Mask.TYPE.DESTROYER:
			if _num_destroy_masks > 0:
				# play throw sound
				_throw_sound.play()

				throw_mask.emit(mask, source_dest , throw_dest)
				_set_destroy_masks(_num_destroy_masks - 1)

func _command_minion(mask: Mask.TYPE):
	_time_since_last_command = 0.0
	# get throw direction for rotating model angle
	var direction = global_position.direction_to(_pointer.global_position)
	_model.rotation.y = atan2(direction.x, direction.z)

	# play command animation
	if _animation_player.is_playing(): _animation_player.stop()
	_animation_player.play("interact-right")

	command_minion.emit(mask, _pointer.global_position)


## Sets player control mode
func _set_control_mode(mode: CONTROL_MODE) -> void:
	_current_mode = mode
	match mode:
		CONTROL_MODE.NONE:
			_pointer.set_mode_none()
		CONTROL_MODE.BUILDERS:
			_pointer.set_mode_builders()
		CONTROL_MODE.DESTROYERS:
			_pointer.set_mode_destroyers()
		CONTROL_MODE.VACUUM:
			_pointer.set_mode_vacuum()

## Player picks up mask
func recieve_mask(mask: Mask) -> void:
	_pickup_sound.play(0.26)
	if not mask: return
	match mask.type:
		Mask.TYPE.BUILDER:
			_set_build_masks(_num_build_masks+1)
		Mask.TYPE.DESTROYER:
			_set_destroy_masks(_num_destroy_masks+1)
	mask.self_destruct()


## ====== Inputs =============

## move camera by current camera directoin
func _move_camera(delta: float) -> void:
	var camera_direction = 0
	if Input.is_action_pressed("camera_rotate_right"): camera_direction += 1
	if Input.is_action_pressed("camera_rotate_left"): camera_direction -= 1
	_camera_root.rotate_y(CAMERA_SPEED * delta * camera_direction)

## move player
func _move_player(delta: float) -> void:
	# Get movement vector
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction := Vector3.ZERO
	if _camera != null and input_dir != Vector2.ZERO:
		# Get camera's forward and right vectors, flattened to the horizontal plane
		var camera_right = _camera.global_transform.basis.x.slide(Vector3.UP).normalized()
		var camera_forward = _camera.global_transform.basis.z.slide(Vector3.UP).normalized()
		
		# Combine input with camera vectors to get movement direction
		direction = camera_right * input_dir.x + camera_forward * input_dir.y
		direction = direction.normalized()

	if direction:
		velocity.x = direction.x * PLAYER_SPEED
		velocity.z = direction.z * PLAYER_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, PLAYER_SPEED)
		velocity.z = move_toward(velocity.z, 0, PLAYER_SPEED)

	if _time_since_last_throw > ACTION_ANIMATION_LAST_TIME and _time_since_last_command > ACTION_ANIMATION_LAST_TIME:

		# rotate player model to walk direction
		if direction:
			_model.rotation.y = atan2(direction.x, direction.z)
		
		# play walk animation
		if velocity.length() > 2.0:
			_animation_player.play("walk")

	move_and_slide()

## Raycast on mouse position
func _mouse_cast():
	var mouse_pos = get_viewport().get_mouse_position() # mouse position on screen
	var world_normal = _camera.project_ray_normal(mouse_pos)
	_ray_cast.target_position = _camera.to_local(global_position + world_normal * 1000)
	
	if _ray_cast.is_colliding():
		return _ray_cast.get_collision_point()
	return null

## Get input and set pointer position
func _move_pointer(_delta: float) -> void:
	# Get input
	var mouse_pos = _mouse_cast()

	if mouse_pos != null:
		_pointer.global_position = mouse_pos

## Get input for player mode
func _get_mode() -> void:
	if Input.is_action_just_pressed("mode_vacuum"): _set_control_mode(CONTROL_MODE.VACUUM)
	elif Input.is_action_just_pressed("mode_builders"): _set_control_mode(CONTROL_MODE.BUILDERS)
	elif Input.is_action_just_pressed("mode_destroyers"): _set_control_mode(CONTROL_MODE.DESTROYERS)
	elif Input.is_action_just_pressed("mode_none"): _set_control_mode(CONTROL_MODE.NONE)

## Get input for player action
func _get_action():
	if Input.is_action_just_pressed("throw_mask"):
		match _current_mode:
			CONTROL_MODE.BUILDERS:
				_throw_mask(Mask.TYPE.BUILDER)
			CONTROL_MODE.DESTROYERS:
				_throw_mask(Mask.TYPE.DESTROYER)
	if Input.is_action_just_pressed("command_minion"):
		match _current_mode:
			CONTROL_MODE.BUILDERS:
				_command_minion(Mask.TYPE.BUILDER)
			CONTROL_MODE.DESTROYERS:
				_command_minion(Mask.TYPE.DESTROYER)
	# if in vacuum mode and holding click, look for minions in zone
	if _current_mode == CONTROL_MODE.VACUUM:
		# if currently vacuuming
		if Input.is_action_pressed("throw_mask"):
			var bodies: Array = _pointer.get_objects_in_zone()
			for body in bodies:
				if body is Minion: body.get_sucked()
				elif body is Mask: body.get_sucked()
		if Input.is_action_just_released("throw_mask"):
			_pointer.vacuum_released()

# Signals ===================

func _pickup_area_entered(body) -> void:
	if body is Mask:
		if body.can_player_pickup(): recieve_mask(body)
